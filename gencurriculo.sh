#!/bin/bash

set -e

mkdir -p ./output

CSS_FILE="./css/curriculo.css"
MD_FILE="./curriculo.md"
TEMPLATE_FILE="./templates/curriculo.html"

if [ "$#" -gt 0 ]; then
    echo "Erro: este projeto possui somente o tema principal (curriculo)."
    echo "Use: ./gencurriculo.sh"
    exit 1
fi

if [ ! -f "$CSS_FILE" ]; then
    echo "Erro: tema principal não encontrado em $CSS_FILE"
    exit 1
fi

if [ ! -f "$MD_FILE" ]; then
    echo "Erro: arquivo $MD_FILE não encontrado"
    exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Erro: template $TEMPLATE_FILE não encontrado"
    exit 1
fi

H1=$(sed -n 's/^# \{1,\}//p' "$MD_FILE" | head -n 1)

if [ -z "$H1" ]; then
    echo "Erro: nenhum título H1 encontrado em $MD_FILE"
    exit 1
fi

PERSON_NAME=$(printf '%s\n' "$H1" | awk 'NF >= 2 { print tolower($1) "_" tolower($2) }')

if [ -z "$PERSON_NAME" ]; then
    echo "Erro: o H1 precisa conter pelo menos duas palavras"
    exit 1
fi

OUTPUT_FILE="./output/curriculo_${PERSON_NAME}.pdf"

echo "Gerando currículo com o tema principal..."
pandoc "$MD_FILE" -o "$OUTPUT_FILE" -s --template "$TEMPLATE_FILE" --pdf-engine weasyprint -c "$CSS_FILE"

echo "Currículo gerado com sucesso: $OUTPUT_FILE"
