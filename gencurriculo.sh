#!/bin/bash

TEMPLATE=${1:-curriculo}

mkdir -p ./output

if [ "$TEMPLATE" = "all" ]; then
    TEMPLATES=("curriculo" "clean" "modern" "classic" "dark")
    echo "Gerando currículos com todos os templates..."
    echo ""
    
    for TEMPLATE_NAME in "${TEMPLATES[@]}"; do
        CSS_FILE="./css/${TEMPLATE_NAME}.css"
        
        if [ ! -f "$CSS_FILE" ]; then
            echo "⚠ Aviso: Template '$TEMPLATE_NAME' não encontrado, pulando..."
            continue
        fi
        
        echo "Gerando currículo com template: $TEMPLATE_NAME"
        pandoc ./curriculo.md -o ./output/curriculo-${TEMPLATE_NAME}.pdf -s --pdf-engine weasyprint -c "$CSS_FILE"
        
        if [ $? -eq 0 ]; then
            echo "✓ Currículo gerado com sucesso: ./output/curriculo-${TEMPLATE_NAME}.pdf"
        else
            echo "✗ Erro ao gerar currículo com template: $TEMPLATE_NAME"
        fi
        echo ""
    done
    
    echo "Processo concluído!"
    exit 0
fi

CSS_FILE="./css/${TEMPLATE}.css"

if [ ! -f "$CSS_FILE" ]; then
    echo "Erro: Template '$TEMPLATE' não encontrado!"
    echo "Templates disponíveis: curriculo, clean, modern, classic, dark"
    echo "Use 'all' para gerar todos os temas de uma vez"
    exit 1
fi

echo "Gerando currículo com template: $TEMPLATE"
pandoc ./curriculo.md -o ./output/curriculo-${TEMPLATE}.pdf -s --pdf-engine weasyprint -c "$CSS_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Currículo gerado com sucesso: ./output/curriculo-${TEMPLATE}.pdf"
else
    echo "✗ Erro ao gerar currículo"
    exit 1
fi
