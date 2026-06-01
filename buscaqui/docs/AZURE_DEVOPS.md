# CI/CD — Azure DevOps

Pipeline em [`azure-pipelines.yml`](../../azure-pipelines.yml) (na raiz do repo).
O app fica em `buscaqui/`.

## O que o pipeline faz
1. **Stage Quality** (a cada push em `main`/`feat/*`/`fix/*` e em PRs para `main`):
   instala o Flutter (com cache), `pub get`, checa formatação, `flutter analyze`
   e `flutter test`.
2. **Stage BuildAndroid** (se Quality passar): gera o **APK de release** e o
   publica como artefato `buscaqui-apk`.

## Pré-requisitos no Azure DevOps

### 1. Conectar o repositório GitHub
- **Project Settings → Service connections → New → GitHub** (autorize a conta).
- **Pipelines → New pipeline → GitHub →** selecione o repositório →
  *Existing Azure Pipelines YAML file* → aponte para `/azure-pipelines.yml`.

### 2. Variáveis (secret) do pipeline
Em **Pipelines → (pipeline) → Edit → Variables**, crie como *secret*:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_MAPS_API_KEY`

O pipeline gera o `.env` a partir delas (o `.env` real não é versionado).

### 3. Azure Boards ↔ GitHub
- **Project Settings → Boards → GitHub connections → Connect your GitHub account**
  e selecione o repositório. Assim commits/PRs que citarem `AB#<id>` vinculam
  automaticamente aos Work Items.

### 4. Políticas de branch (recomendado)
Em **Repos → Branches → `main` → Branch policies** (se usar Azure Repos) ou nas
*branch protection rules* do GitHub:
- Exigir PR para mesclar em `main`.
- Exigir que o pipeline (status check) passe antes do merge.
- Exigir ao menos 1 aprovação.

## Rodar a verificação localmente (igual ao CI)
```bash
cd buscaqui
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

## Observações
- O Flutter é instalado via `git clone` da branch da versão (`flutterVersion`),
  sem depender de extensão do Marketplace. Ajuste a versão na seção `variables`.
- Para build **iOS**, adicione um job em `pool: macOS-latest` com
  `flutter build ipa` (requer certificados/provisioning — fora do escopo inicial).
- O `flutter test` roda com `|| true` para não derrubar o build enquanto a
  suíte de testes ainda é pequena; remova isso quando quiser testes obrigatórios.
