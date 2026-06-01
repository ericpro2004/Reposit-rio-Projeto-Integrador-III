# BusCaqui 🚐

Sistema de gestão, chamada automatizada/manual e monitoramento em tempo real
para transporte escolar. Flutter + Supabase, Clean Architecture e Riverpod,
com acessibilidade WCAG 2.1 nível AA desde o dia 1.

## Stack
- **Frontend:** Flutter / Dart (Android + iOS)
- **Estado:** Riverpod
- **Arquitetura:** Clean Architecture (data / domain / presentation por feature)
- **Backend:** Supabase (Postgres, Auth, Realtime, Storage)
- **Mapas:** google_maps_flutter + geolocator
- **QR:** qr_flutter (geração) + mobile_scanner (leitura)
- **Push:** Firebase Cloud Messaging (via Edge Functions/triggers)
- **CI/CD:** Git/GitHub + Azure DevOps (Boards, Repos, Pipelines)

## Setup rápido
1. `cp .env.example .env` e preencha as chaves (Supabase + Google Maps).
2. No Supabase SQL Editor, rode `supabase/schema.sql`.
3. `flutter pub get`
4. `flutter run`

## Estrutura de pastas (Clean Architecture)

```
lib/
├─ main.dart                      # bootstrap: dotenv → Supabase → ProviderScope
├─ core/                          # transversal a todas as features
│  ├─ config/                     # env, supabase_config
│  ├─ constants/                  # app_colors (paleta AA)
│  ├─ theme/                      # app_theme (light/dark acessível)
│  ├─ router/                     # go_router + rotas + placeholders
│  ├─ error/                      # failures e exceptions
│  ├─ usecase/                    # contrato base de UseCase
│  ├─ network/                    # checagem de conectividade
│  └─ widgets/                    # componentes acessíveis (AppButton, etc.)
└─ features/
   ├─ auth/                       # Telas 1, 2, 3, 4
   │  ├─ data/        (datasources, models, repositories impl)
   │  ├─ domain/      (entities, repositories abstract, usecases)
   │  └─ presentation/(pages, widgets, providers)
   ├─ connections/                # Telas 5, 6, 7 (conexões + QR gerador)
   ├─ attendance/                 # Telas 8, 9 (scanner + chamada manual)
   ├─ tracking/                   # mapa em tempo real (Realtime)
   ├─ alerts/                     # Tela 10
   └─ dashboard/                  # Tela 11 (assiduidade)
```

Cada feature segue rigorosamente as 3 camadas:

| Camada | Responsabilidade | Não pode |
|---|---|---|
| **domain** | Entidades puras, contratos de repositório, casos de uso. Sem Flutter/Supabase. | Importar `data` ou `presentation`. |
| **data** | Models (json↔entity), datasources (Supabase) e implementação dos repositórios. | Importar `presentation`. |
| **presentation** | Widgets, páginas e providers Riverpod. | Acessar datasource direto (passa por usecase). |

Fluxo de dependência: `presentation → domain ← data`.
