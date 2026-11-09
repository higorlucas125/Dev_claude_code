#!/usr/bin/env bash
# Calcula a próxima versão do app a partir das tags v* e do gradle.properties.
#
#  - Se VERSION_NAME no gradle.properties for maior que a última tag, usa ele
#    (é assim que você controla bumps de major/minor: edite VERSION_NAME na develop).
#  - Senão, incrementa o patch da última tag (0.1.0 -> 0.1.1).
#  - VERSION_CODE = maior valor entre o gradle.properties e (quantidade de tags + 1).
#
# Escreve version=, tag= e code= em $GITHUB_OUTPUT (ou na saída padrão).
# Requer o histórico de tags (actions/checkout com fetch-depth: 0).
set -euo pipefail

prop() { grep -E "^$1=" gradle.properties | cut -d'=' -f2 | tr -d '[:space:]'; }

base=$(prop VERSION_NAME)
base_code=$(prop VERSION_CODE)
ultima=$(git tag -l 'v*' --sort=-v:refname | head -n1 | sed 's/^v//')
qtd_tags=$(git tag -l 'v*' | wc -l | tr -d ' ')

if [ -z "$ultima" ]; then
  versao="$base"
elif [ "$base" != "$ultima" ] && [ "$(printf '%s\n%s\n' "$base" "$ultima" | sort -V | tail -n1)" = "$base" ]; then
  versao="$base"
else
  IFS='.' read -r major minor patch <<< "$ultima"
  versao="$major.$minor.$((patch + 1))"
fi

codigo=$((qtd_tags + 1))
if [ "$base_code" -gt "$codigo" ]; then
  codigo="$base_code"
fi

saida="${GITHUB_OUTPUT:-/dev/stdout}"
{
  echo "version=$versao"
  echo "tag=v$versao"
  echo "code=$codigo"
} >> "$saida"
