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

Exemplo de ciclo:

```bash
# nova funcionalidade
git checkout develop && git pull
git checkout -b feature/lista-de-compras
# ... commits ...
git push -u origin feature/lista-de-compras

# o Pipeline de feature roda o build e abre o PR para develop sozinho;
# depois do merge, o Pipeline de release abre o PR release/<versão> -> main
```

## GitHub Actions — fluxo automático

```
push em feature/* | bug/* | fix/* | hotfix/*
  └─ Pipeline de feature: lint + testes + build
       └─ passou → abre PR para develop
            └─ CI + Política de branches rodam de novo no PR
                 └─ merge na develop
                      └─ Pipeline de release: lint + testes + build
                           └─ passou → cria/atualiza release/<versão> e abre PR para main
                                └─ CI + Política de branches no PR
                                     └─ merge na main
                                          └─ Release: APK/AAB + tag v<versão> + GitHub Release
```

| Workflow | Arquivo | Quando roda |
|---|---|---|
| Pipeline de feature | `feature-pipeline.yml` | push em `feature/*`, `bug/*`, `fix/*`, `hotfix/*` |
| CI | `ci.yml` | PR para `develop` ou `main` |
| Política de branches | `branch-policy.yml` | PR para `develop` ou `main` |
| Pipeline de release | `release-pipeline.yml` | push (merge) na `develop` |
| Release | `release.yml` | push (merge) na `main` |

Os passos de build ficam na action local `.github/actions/build-android`.

### Versão

A versão é calculada por `.github/scripts/proxima-versao.sh`:
- se `VERSION_NAME` no `gradle.properties` for maior que a última tag, ela é usada. Para um bump de major/minor, edite `VERSION_NAME` (ex.: `0.2.0`) numa `feature/*` ou `fix/*`;
- senão, sobe o patch da última tag (`v0.1.0` → `0.1.1`);
- `VERSION_CODE` é calculado automaticamente e sempre cresce.

Merges novos na develop antes da release sair atualizam a mesma `release/<versão>` e o mesmo PR.

### Configuração necessária no GitHub (uma vez)

1. **Token para os PRs automáticos.** PRs e pushes feitos com o `GITHUB_TOKEN` padrão *não disparam* outros workflows, então o CI não rodaria nos PRs automáticos. Crie um token *fine-grained* (*Settings da conta → Developer settings → Personal access tokens*) só para este repositório, com permissão de **Contents: Read and write**, **Pull requests: Read and write** e **Workflows: Read and write**, e salve como secret **`PR_TOKEN`** em *Settings → Secrets and variables → Actions*.
2. **Permitir que o Actions crie PRs** (necessário só se usar sem `PR_TOKEN`): *Settings → Actions → General → Workflow permissions* → marque *Allow GitHub Actions to create and approve pull requests*.
3. **Rulesets:** *Settings → Rules → Rulesets → New ruleset → Import a ruleset*, importando `.github/rulesets/protecao-main.json` e `.github/rulesets/protecao-develop.json`.
4. *(Opcional)* *Settings → General → Automatically delete head branches*, para apagar as branches depois do merge.

### Assinatura da release

Sem configuração, a release sai assinada com a chave de debug (serve para testes, não para a Play Store). Para assinar de verdade, cadastre em *Settings → Secrets and variables → Actions*:

| Secret                       | Conteúdo                                   |
|------------------------------|--------------------------------------------|
| `ANDROID_KEYSTORE_BASE64`    | o arquivo `.jks` em base64 (`base64 -w0 release.jks`) |
| `ANDROID_KEYSTORE_PASSWORD`  | senha da keystore                          |
| `ANDROID_KEY_ALIAS`          | alias da chave                             |
| `ANDROID_KEY_PASSWORD`       | senha da chave                             |
