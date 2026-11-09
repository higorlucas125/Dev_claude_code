# Dev_claude_code — Finanças

App Android de organização financeira (Kotlin + Jetpack Compose + Gradle), desenvolvido com o Claude Code.

## Requisitos

- Android Studio (versão recente, com Android SDK 36)
- JDK 17 (o embutido no Android Studio serve)

Abra a pasta raiz no Android Studio e aguarde o Gradle sincronizar.

```bash
./gradlew assembleDebug        # gera o APK de debug
./gradlew testDebugUnitTest    # roda os testes unitários
./gradlew lintDebug            # roda o lint
```

## Estrutura

```
.
├── app/                         # módulo do aplicativo
│   └── src/
│       ├── main/java/br/com/higorlucas/financas/
│       └── test/                # testes unitários
├── gradle/libs.versions.toml    # catálogo de versões das dependências
├── gradle.properties            # VERSION_NAME / VERSION_CODE do app
└── .github/workflows/           # CI e release
```

## Fluxo de branches (Gitflow)

| Branch       | Criada a partir de | PR para   | Uso                                   |
|--------------|--------------------|-----------|---------------------------------------|
| `main`       | —                  | —         | Código em produção; cada merge gera release |
| `develop`    | `main`             | —         | Integração                            |
| `feature/*`  | `develop`          | `develop` | Novas funcionalidades                 |
| `bug/*`      | `develop`          | `develop` | Correção de bug                       |
| `fix/*`      | `develop`          | `develop` | Ajustes e correções pequenas          |
| `hotfix/*`   | `develop`          | `develop` | Correção urgente (sai na próxima release) |
| `release/*`  | `develop`          | `main`    | Preparação de versão (bump, ajustes)  |

### Regras aplicadas no GitHub

- **`main` só recebe PR de `release/*`**, e **`develop` só recebe PR de `feature/*`, `bug/*`, `fix/*` ou `hotfix/*`**. O workflow `.github/workflows/branch-policy.yml` (check **Validar branch de origem**) reprova qualquer outra combinação.
- Os rulesets **Proteção main** e **Proteção develop** ficam em `.github/rulesets/`. Para ativar: *Settings → Rules → Rulesets → New ruleset → Import a ruleset* e selecione cada JSON. Eles exigem PR para qualquer mudança, exigem os checks **Validar branch de origem** e **Lint, testes e build** passando e bloqueiam force push e exclusão da branch.
- Depois que uma `release/*` entra na `main`, a `develop` não recebe o bump de versão automaticamente: faça o mesmo ajuste de `VERSION_NAME`/`VERSION_CODE` em uma `fix/*` para a `develop`.

Exemplo de ciclo:

```bash
# nova funcionalidade
git checkout develop && git pull
git checkout -b feature/lista-de-compras
# ... commits ...
git push -u origin feature/lista-de-compras   # abra PR para develop

# preparar versão
git checkout develop && git pull
git checkout -b release/0.2.0
# edite VERSION_NAME=0.2.0 e incremente VERSION_CODE em gradle.properties
git commit -am "chore: versão 0.2.0"
git push -u origin release/0.2.0              # abra PR para main
# depois do merge na main, leve o bump de versão para a develop via fix/*
```

## GitHub Actions

- **CI** (`.github/workflows/ci.yml`): em push para `develop`, `feature/*`, `release/*`, `hotfix/*` e em PRs para `main`/`develop`. Roda lint, testes unitários e gera o APK de debug (disponível nos artefatos do workflow).
- **Release** (`.github/workflows/release.yml`): em push na `main`. Lê `VERSION_NAME` do `gradle.properties`, gera APK e AAB de release e cria a tag `v<versão>` com a GitHub Release. Se a tag já existir, o workflow não faz nada, então lembre de subir a versão na branch `release/*` ou `hotfix/*`.

### Assinatura da release

Sem configuração, a release sai assinada com a chave de debug (serve para testes, não para a Play Store). Para assinar de verdade, cadastre em *Settings → Secrets and variables → Actions*:

| Secret                       | Conteúdo                                   |
|------------------------------|--------------------------------------------|
| `ANDROID_KEYSTORE_BASE64`    | o arquivo `.jks` em base64 (`base64 -w0 release.jks`) |
| `ANDROID_KEYSTORE_PASSWORD`  | senha da keystore                          |
| `ANDROID_KEY_ALIAS`          | alias da chave                             |
| `ANDROID_KEY_PASSWORD`       | senha da chave                             |

### Proteção de branches (recomendado)

Em *Settings → Branches*, proteja `main` e `develop`: exija PR e o check **CI / Lint, testes e build** passando antes do merge.
