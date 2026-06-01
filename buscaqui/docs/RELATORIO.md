# Relatório Técnico — BusCaqui

Sistema de gestão, chamada automatizada/manual e monitoramento em tempo real
para **transporte escolar**. Aplicativo móvel (Android/iOS) e web, construído com
Flutter + Supabase, arquitetura limpa e acessibilidade WCAG 2.1 nível AA desde o
primeiro dia.

> Status: app funcional com as 11 telas previstas + tracking, banco de dados
> provisionado, notificações push e pipeline de CI/CD. Validado rodando no
> navegador (Chrome) e com `flutter analyze` sem problemas.

---

## 1. Tecnologias utilizadas

### 1.1 Visão geral da stack

| Camada | Tecnologia | Papel no projeto |
|---|---|---|
| Linguagem/UI | **Dart + Flutter 3.24** | App multiplataforma (Android, iOS, Web) |
| Estado | **Riverpod 2** | Injeção de dependência e gerência de estado reativo |
| Navegação | **go_router 14** | Rotas declarativas + *redirect* por autenticação |
| Programação funcional | **fpdart** | `Either<Failure, T>` para tratamento de erros |
| Igualdade de valor | **equatable** | Entidades/estados comparáveis |
| Backend (BaaS) | **Supabase** | Postgres, Auth, Realtime, Storage, Edge Functions |
| Mapas | **google_maps_flutter** | Mapa do monitoramento em tempo real |
| Localização | **geolocator** | GPS do motorista (compartilhamento de posição) |
| QR Code | **qr_flutter** (gerar) / **mobile_scanner** (ler) | Check-in por QR |
| Push | **Firebase Cloud Messaging** + **flutter_local_notifications** | Notificações de faltas/ocorrências |
| Gráficos | **fl_chart** | Dashboard de assiduidade |
| Datas/i18n | **intl** | Formatação pt-BR |
| Configuração | **flutter_dotenv** | Segredos via `.env` |
| Compartilhar | **share_plus** | Compartilhar código da van |
| Versionamento | **Git + GitHub** | Repositório e Pull Requests |
| CI/CD | **Azure DevOps Pipelines** | Build/analyze/test + APK |
| IDE | **VS Code** | Desenvolvimento |

### 1.2 Funcionalidades de cada tecnologia, vantagens e desvantagens

**Flutter / Dart**
- *Funções:* um único código-fonte compila para Android, iOS e Web; *hot reload*;
  rico conjunto de widgets Material 3.
- *Vantagens:* produtividade alta, UI consistente entre plataformas, ótimo suporte
  a acessibilidade (widget `Semantics`).
- *Desvantagens:* APIs mudam entre versões (ex.: `Color.withValues` só existe no
  3.27+; `CardTheme` virou `CardThemeData`); o build **web em modo debug (DDC)**
  é sensível a cache.

**Riverpod**
- *Funções:* provedores (`Provider`, `FutureProvider`, `StreamProvider`,
  `AsyncNotifier`) para estado e DI testável.
- *Vantagens:* desacopla camadas, recarrega telas automaticamente, fácil de mockar.
- *Desvantagens:* curva de aprendizado; em *Notifiers* "family" o lint reclama do
  nome do parâmetro de `build` (resolvido no `analysis_options`).

**go_router**
- *Funções:* rotas nomeadas, *deep links*, `redirect` global.
- *Vantagens:* centraliza a navegação e o controle de acesso (público × autenticado).
- *Desvantagens:* integrar o `refreshListenable` ao Riverpod exige uma "ponte"
  (`ChangeNotifier`) escrita à mão.

**Supabase (Postgres + Auth + Realtime + Storage + Edge Functions)**
- *Funções:* banco relacional gerenciado, autenticação pronta, *streams* em tempo
  real, armazenamento de arquivos e funções serverless (Deno).
- *Vantagens:* elimina a necessidade de backend próprio; **RLS** (Row Level
  Security) garante isolamento de dados por perfil direto no banco; SQL puro.
- *Desvantagens:* o RLS é poderoso, mas **policies que se referenciam entre
  tabelas podem gerar recursão infinita** (enfrentamos isso — ver §5); o cadastro
  via GoTrue "ofusca" e-mails já existentes, exigindo tratamento no cliente.

**google_maps_flutter / geolocator**
- *Funções:* mapa nativo + marcadores; leitura de GPS com filtro por distância.
- *Vantagens:* experiência nativa de mapa; *stream* de posição em background.
- *Desvantagens:* exigem **chave de API** e **configuração nativa** (Manifest /
  AppDelegate / Info.plist) e permissões de localização; no Web precisam de chave
  específica.

**qr_flutter / mobile_scanner**
- *Funções:* gerar e ler QR Codes pela câmera.
- *Vantagens:* leitura rápida; API simples.
- *Desvantagens:* a câmera exige permissão nativa; *scanner* precisa de proteção
  contra leitura dupla (resolvido com trava de estado).

**Firebase Cloud Messaging + flutter_local_notifications**
- *Funções:* push em segundo plano e exibição em primeiro plano.
- *Vantagens:* notificações confiáveis multiplataforma.
- *Desvantagens:* depende de `flutterfire configure` e arquivos nativos
  (`google-services.json`/plist); **não funciona no Web sem configuração extra**
  (tratamos isso de forma resiliente — o app não quebra sem push).

**fl_chart**
- *Funções:* gráficos de barras/linha.
- *Vantagens:* flexível e bonito.
- *Desvantagens:* é puramente visual (não acessível por padrão — adicionamos
  resumo textual via `Semantics`); a escala automática gera rótulos fracionários
  em contagens inteiras.

**Azure DevOps Pipelines**
- *Funções:* CI/CD (build, análise, testes, artefatos).
- *Vantagens:* integra Boards/Repos/Pipelines; *secret variables* para segredos.
- *Desvantagens:* configuração inicial (service connection, YAML) tem curva.

---

## 2. Parte técnica

### 2.1 Arquitetura — Clean Architecture

O código segue **Clean Architecture**, separando cada *feature* em três camadas
com dependência unidirecional `presentation → domain ← data`:

```
lib/
├─ core/            # transversal: config, tema, rotas, erros, widgets, push
└─ features/<feature>/
   ├─ domain/       # entidades puras, contratos (repositories), use cases
   ├─ data/         # models (json↔entidade), datasources (Supabase), repos impl
   └─ presentation/ # páginas, widgets e providers (Riverpod)
```

Features: `auth`, `connections`, `attendance`, `tracking`, `alerts`, `dashboard`.

- **domain** não conhece Flutter nem Supabase (Dart puro) — é testável e estável.
- **data** implementa os contratos do domínio e traduz exceções em `Failure`.
- **presentation** só fala com o domínio via *use cases*/providers.

### 2.2 Banco de dados (PostgreSQL/Supabase)

Modelo com **7 tabelas principais** + tabela de tokens de push, todas com chave
primária UUID, chaves estrangeiras e **RLS habilitado**:

| Tabela | Conteúdo |
|---|---|
| `usuarios` | perfil (extensão de `auth.users`): nome, e-mail, telefone, tipo, foto |
| `responsaveis` | dados do responsável pelo aluno |
| `conexoes` | rotas/vans do motorista (código + payload do QR) |
| `passageiros` | aluno vinculado a um responsável e a uma conexão |
| `presencas` | registro de chamada (status + origem + horário) |
| `localizacoes` | posições da van (Realtime ativo) |
| `alertas` | avisos enviados aos responsáveis |
| `fcm_tokens` | tokens de dispositivo para push |

**Tipos enumerados:** `tipo_usuario` (motorista/responsavel/passageiro),
`presenca_status` (presente/ausente/justificado), `presenca_origem`
(manual/qrcode/codigo).

**Automação no banco (triggers):**
- `handle_new_user` — cria o perfil em `usuarios` automaticamente no cadastro.
- `gen_connection_code` — gera código alfanumérico e payload do QR ao criar conexão.
- `notify_absence` — cria um alerta quando uma presença é marcada como "ausente".
- `on_alerta_push` — dispara a Edge Function de push (via `pg_net`) ao criar alerta.

**Funções RPC `SECURITY DEFINER`** (executam com privilégio para contornar o RLS
de forma controlada):
- `join_connection` — passageiro entra na van pelo código.
- `refresh_connection_token` — motorista regenera o token/QR.
- `register_presence` — check-in do próprio passageiro por QR/código.
- `auth_*_ids` — funções auxiliares que **quebram a recursão de RLS** (ver §5).

**Segurança (RLS):** cada perfil só enxerga o que lhe pertence — motorista vê suas
conexões/passageiros/presenças; responsável e passageiro veem apenas os seus
dados. Verificado com o *Security Advisor* do Supabase.

### 2.3 Construção do app

- **Inicialização (`main.dart`):** carrega `.env` → inicializa Supabase (Auth PKCE
  + Realtime) → formatação pt-BR → `ProviderScope` (Riverpod) → `MaterialApp.router`.
- **Autenticação:** Supabase Auth (e-mail/senha + OAuth Google/Apple). O roteador
  observa o estado de login e redireciona automaticamente.
- **Tempo real:** `localizacoes` e `alertas` usam `.stream()` do Supabase Realtime.
- **Tratamento de erros:** todo acesso a dados retorna `Either<Failure, T>`, com
  mensagens em português claras e descritivas.

### 2.4 CI/CD

`azure-pipelines.yml` com dois estágios: **Quality** (instala Flutter com cache,
`pub get`, formatação, `analyze`, `test`) e **BuildAndroid** (gera o APK de
release como artefato). Segredos entram via *secret variables*.

---

## 3. Funcionalidades do app (11 telas + tracking)

| # | Tela | O que faz |
|---|---|---|
| 1 | **Splash/Login inicial** | Logo, "Criar conta" e "Já tenho conta"; auto-redireciona se já logado |
| 2 | **Cadastro** | Nome/e-mail/celular/senha + perfil + OAuth Google/Apple |
| 3 | **Login** | E-mail/senha, "esqueci minha senha", atalho para cadastro |
| 4 | **Informações do passageiro** | Vínculo aluno ↔ responsável |
| 5 | **Minhas Conexões** | Lista de vans em cards; "Ver Localização"; **sair da conta** |
| 6 | **Entrar em conexão** | Passageiro digita o código da van |
| 7 | **Gerador de QR** | Motorista gera QR + token; compartilhar e atualizar token |
| 8 | **Leitor de QR** | Câmera (mobile_scanner) + entrada manual; feedback imediato |
| 9 | **Chamada manual** | Lista com foto/nome/status; presente/ausente; filtros e tags de origem |
| 10 | **Alertas** | Feed em tempo real de avisos; marcar como lido; badge de não lidos |
| 11 | **Dashboard** | Indicadores (presenças/faltas/assiduidade) + gráficos de frequência |
| + | **Monitoramento (mapa)** | Posição da van em tempo real; motorista compartilha o GPS |

**Perfis e regras de negócio:**
- **Motorista:** cria conexões, compartilha código/QR, faz chamada, vê dashboard,
  compartilha localização.
- **Responsável:** vincula o passageiro, acompanha o mapa, recebe alertas/push.
- **Passageiro/Aluno:** entra na van por código, faz check-in por QR.

---

## 4. Cores e layout

### 4.1 Paleta
- **Laranja de segurança `#F5A623`** — cor de marca, usada em **superfícies e
  preenchimentos** (botões, avatar, splash).
- **Preto suave `#212121`** — texto principal (evita fadiga vs. preto puro).
- **Branco / cinza claro `#F4F5F7`** — fundos.
- **Estados semânticos:** verde `#1B7A3D` (presente), vermelho `#C62828`
  (ausente), âmbar `#9A6700` (justificado), azul `#1A5FB4` (info).
- **Dark mode** nativo, seguindo a preferência do sistema.

### 4.2 Decisão crítica de contraste (WCAG AA)
O laranja `#F5A623` tem contraste de apenas **~1,9:1 contra o branco** — reprova no
nível AA para texto. Por isso:
- O laranja **só preenche superfícies**, nunca é cor de texto fino.
- Texto **sobre** o laranja usa o preto suave (`#212121`, contraste ~8:1).
- Para texto/links laranja sobre fundo claro criamos um tom escurecido
  (`#A8650A`, contraste ~4,6:1, aprovado em AA).

### 4.3 Princípios de layout e acessibilidade
- **Material 3** com tema claro/escuro.
- **Alvos de toque ≥ 48 dp** (botões, inputs, ícones).
- **Escala de texto dinâmica** respeitada (com *clamp* para não quebrar o layout).
- **`Semantics`** em botões, campos, cards e gráficos (compatível com
  TalkBack/VoiceOver).
- **Status nunca por cor apenas** — sempre ícone + rótulo (ex.: "✓ Presente").
- **Feedback claro** — mensagens descritivas e anúncio por leitor de tela
  (`SemanticsService.announce`).

---

## 5. Desafios enfrentados (configuração e uso)

| Desafio | Causa | Solução |
|---|---|---|
| **Recursão infinita de RLS** (`infinite recursion detected in policy for relation "passageiros"`) | Policies de `passageiros` e `conexoes` se referenciavam mutuamente | Funções `SECURITY DEFINER` (`auth_*_ids`) que leem sem acionar o RLS |
| **"Falha ao comunicar com o servidor" no cadastro** | E-mail já existente → GoTrue devolve usuário sem sessão; código fazia `currentUser!` (nulo) | Detecção de e-mail duplicado/sem sessão + uso do objeto `User` |
| **Erro `GoTrueClient` no Web** | Cache/service worker do build *debug* (DDC) na mesma porta | Rodar em **modo release** (dart2js) e/ou porta nova + `Ctrl+Shift+R` |
| **Layout da Splash quebrando** | `Spacer` (flex) dentro de `SingleChildScrollView` (altura infinita) | Padrão `LayoutBuilder + IntrinsicHeight` |
| **Faltavam plataformas** (`Missing index.html`) | Projeto criado arquivo a arquivo, sem `android/ios/web` | `flutter create .` (sem sobrescrever o `lib/`) |
| **Porta ocupada** ao reiniciar o servidor | Processo `flutter run` órfão segurando a porta | Encerrar o processo da porta e reiniciar |
| **Compatibilidade de versões do Flutter** | `withValues`/`CardThemeData` só em 3.27+ | Fixar **Flutter 3.24** e usar APIs compatíveis |
| **Espaço em disco (~15 GB)** | Android SDK + emulador são pesados | Testar primeiro no **Web** (Chrome) |

---

## 6. Próximos passos

**Configuração (sem código):**
1. `flutterfire configure` + arquivos nativos (FCM) para push real em dispositivo.
2. Chave do **Google Maps** (web + Android/iOS) e permissões de câmera/localização
   (ver `docs/NATIVE_SETUP.md`).
3. Definir os *secrets* da Edge Function no Supabase (`FIREBASE_SERVICE_ACCOUNT`,
   `EDGE_SHARED_SECRET`) e `app.edge_secret` no banco.
4. Configurar o pipeline no Azure DevOps (`docs/AZURE_DEVOPS.md`).

**Funcionalidades:**
5. **Upload de foto de perfil** (Supabase Storage) — já há dependência (`image_picker`).
6. **Justificativa de faltas** pelo responsável (status `justificado` + anexo).
7. Edição/gerenciamento de passageiros e múltiplos filhos por responsável.
8. Tela de **perfil/configurações** (trocar senha, tema, notificações).
9. Histórico de rotas e *replay* do trajeto no mapa.

**Qualidade e UX:**
10. Eixo Y dos gráficos com **apenas inteiros** + estado "sem dados de frequência".
11. **Testes** de widget e de integração (hoje há testes de domínio).
12. Internacionalização completa (arquivos ARB) além do pt-BR.
13. *Build* de release assinado para publicar nas lojas (Play Store / App Store).

---

*Documento gerado para o Projeto Integrador III — BusCaqui.*
