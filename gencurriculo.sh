#!/usr/bin/env bash
#
# gencurriculo.sh — gera um currículo em PDF a partir de Markdown
# usando pandoc (Markdown -> HTML) e weasyprint (HTML + CSS -> PDF).
#
# Uso rápido:   ./gencurriculo.sh
# Ajuda:        ./gencurriculo.sh --ajuda

set -euo pipefail

# --- Caminhos do projeto (independem do diretório atual) --------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSS_DIR="$SCRIPT_DIR/css"
TEMPLATE_FILE="$SCRIPT_DIR/templates/curriculo.html"

# --- Padrões (podem vir de variáveis de ambiente) ---------------------------
TEMA="${CURRICULO_TEMA:-curriculo}"
ENTRADA="${CURRICULO_ENTRADA:-curriculo.md}"
SAIDA_DIR="${CURRICULO_SAIDA:-output}"
SAIDA_ARQ=""
AJUSTAR=1               # reduz a fonte até caber em 1 página
FONTE_MINIMA="8.5"      # em pt; abaixo disso fica ilegível
PASSO="0.25"            # redução por tentativa, em pt
GERAR_HTML=0
VERIFICAR_ATS=0
TODOS=0
ABRIR=0

# --- Saída colorida só em terminal ------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_ERR=$'\e[31m'; C_OK=$'\e[32m'; C_AV=$'\e[33m'; C_INFO=$'\e[36m'; C_RST=$'\e[0m'
else
    C_ERR=""; C_OK=""; C_AV=""; C_INFO=""; C_RST=""
fi

erro()  { printf '%sErro:%s %s\n' "$C_ERR" "$C_RST" "$*" >&2; exit 1; }
aviso() { printf '%sAviso:%s %s\n' "$C_AV" "$C_RST" "$*" >&2; }
info()  { printf '%s==>%s %s\n' "$C_INFO" "$C_RST" "$*"; }
ok()    { printf '%s✔%s %s\n' "$C_OK" "$C_RST" "$*"; }

uso() {
    cat <<EOF
Uso: $(basename "$0") [opções] [tema]

Gera output/curriculo_<nome>_<sobrenome>.pdf a partir de curriculo.md.

Opções:
  -t, --tema NOME        Tema (CSS) a usar. Padrão: curriculo
  -T, --todos            Gera um PDF para cada tema (sufixo _<tema> no nome)
  -l, --listar           Lista os temas disponíveis
  -i, --entrada ARQ      Arquivo Markdown de entrada. Padrão: curriculo.md
  -o, --saida ARQ        Caminho do PDF gerado (ignora o nome automático)
  -d, --diretorio DIR    Diretório de saída. Padrão: output
      --multipagina      Não tenta encaixar o currículo em uma página
      --fonte-minima PT  Menor fonte aceita ao encaixar. Padrão: $FONTE_MINIMA
      --html             Salva também o HTML intermediário (para depurar no navegador)
      --ats              Mostra o texto extraído do PDF, como um ATS o leria
  -a, --abrir            Abre o PDF ao final
  -h, --ajuda            Mostra esta ajuda

Variáveis de ambiente: CURRICULO_TEMA, CURRICULO_ENTRADA, CURRICULO_SAIDA, NO_COLOR.

Exemplos:
  $(basename "$0")                         # tema padrão, 1 página
  $(basename "$0") -t moderno --ats        # outro tema + checagem ATS
  $(basename "$0") -i ingles.md -o output/resume.pdf
  $(basename "$0") --todos                 # compara todos os temas
EOF
}

listar_temas() {
    local css nome desc
    for css in "$CSS_DIR"/*.css; do
        nome="$(basename "$css" .css)"
        [ "$nome" = "base" ] && continue
        desc="$(sed -n '1s|^/\* *Tema: *[^ ]* *[—-]* *\(.*[^ ]\) *\*/.*$|\1|p' "$css")"
        printf '  %-12s %s\n' "$nome" "$desc"
    done
}

# --- Argumentos -------------------------------------------------------------
precisa_valor() { [ "$#" -ge 2 ] && [ -n "$2" ] || erro "a opção $1 precisa de um valor"; }

while [ "$#" -gt 0 ]; do
    case "$1" in
        -t|--tema)        precisa_valor "$@"; TEMA="$2"; shift 2 ;;
        -T|--todos)       TODOS=1; shift ;;
        -l|--listar)      echo "Temas disponíveis:"; listar_temas; exit 0 ;;
        -i|--entrada)     precisa_valor "$@"; ENTRADA="$2"; shift 2 ;;
        -o|--saida)       precisa_valor "$@"; SAIDA_ARQ="$2"; shift 2 ;;
        -d|--diretorio)   precisa_valor "$@"; SAIDA_DIR="$2"; shift 2 ;;
        --multipagina)    AJUSTAR=0; shift ;;
        --fonte-minima)   precisa_valor "$@"; FONTE_MINIMA="$2"; shift 2 ;;
        --html)           GERAR_HTML=1; shift ;;
        --ats)            VERIFICAR_ATS=1; shift ;;
        -a|--abrir)       ABRIR=1; shift ;;
        -h|--ajuda|--help) uso; exit 0 ;;
        -*)               erro "opção desconhecida: $1 (veja --ajuda)" ;;
        *)                TEMA="$1"; shift ;;   # compatível com: ./gencurriculo.sh moderno
    esac
done

[[ "$FONTE_MINIMA" =~ ^[0-9]+([.][0-9]+)?$ ]] || erro "--fonte-minima deve ser um número (ex.: 8.5)"

# --- Dependências -----------------------------------------------------------
for dep in pandoc weasyprint; do
    command -v "$dep" >/dev/null 2>&1 || erro "'$dep' não encontrado. Instale-o ou use o Docker (veja o README)."
done

[ -f "$ENTRADA" ]       || erro "arquivo de entrada '$ENTRADA' não encontrado"
[ -f "$TEMPLATE_FILE" ] || erro "template '$TEMPLATE_FILE' não encontrado"

if [ "$TODOS" -eq 1 ]; then
    [ -z "$SAIDA_ARQ" ] || erro "--saida não pode ser usado junto com --todos"
    TEMAS=()
    for css in "$CSS_DIR"/*.css; do
        n="$(basename "$css" .css)"; [ "$n" = "base" ] || TEMAS+=("$n")
    done
else
    [ -f "$CSS_DIR/$TEMA.css" ] || { echo "Temas disponíveis:" >&2; listar_temas >&2; erro "tema '$TEMA' não encontrado"; }
    TEMAS=("$TEMA")
fi

# --- Nome da pessoa (primeiro H1, fora do YAML, de comentários e de código) --
H1="$(awk '
    NR == 1 && /^---[[:space:]]*$/ { yaml = 1; next }
    yaml && /^(---|\.\.\.)[[:space:]]*$/ { yaml = 0; next }
    yaml { next }
    /^(```|~~~)/ { codigo = !codigo; next }
    codigo { next }
    /<!--/ { comentario = 1 }
    comentario { if (/-->/) comentario = 0; next }
    /^#[[:space:]]+/ { sub(/^#[[:space:]]+/, ""); sub(/[[:space:]]+#*[[:space:]]*$/, ""); print; exit }
' "$ENTRADA")"

[ -n "$H1" ] || erro "nenhum título H1 (linha começando com '# ') encontrado em $ENTRADA"

# "José Antônio da Silva" -> "jose_antonio" (sem acentos, só [a-z0-9])
slug() {
    printf '%s' "$1" \
        | sed -E 's/á|à|â|ã|ä|Á|À|Â|Ã|Ä/a/g; s/é|è|ê|ë|É|È|Ê|Ë/e/g; s/í|ì|î|ï|Í|Ì|Î|Ï/i/g;
                  s/ó|ò|ô|õ|ö|Ó|Ò|Ô|Õ|Ö/o/g; s/ú|ù|û|ü|Ú|Ù|Û|Ü/u/g; s/ç|Ç/c/g; s/ñ|Ñ/n/g' \
        | tr '[:upper:]' '[:lower:]' \
        | sed -E 's/[^a-z0-9 ]+//g' \
        | awk '{ out = $1; if (NF >= 2) out = out "_" $2; print out }'
}

NOME_SLUG="$(slug "$H1")"
[ -n "$NOME_SLUG" ] || erro "não foi possível gerar o nome do arquivo a partir de '$H1'; use --saida"

# --- Utilitários ------------------------------------------------------------
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT


# Comparação/aritmética de ponto flutuante sem depender do bc.
calc() { awk "BEGIN { printf \"%.2f\", $1 }"; }
menor_que() { awk "BEGIN { exit !($1 < $2) }"; }

# Lê o font-size base do tema (linha "html { font-size: 10.5pt; }").
fonte_base() {
    local v
    v="$(sed -n 's/^html *{ *font-size: *\([0-9.]*\)pt.*/\1/p' "$1" | tail -n 1)"
    echo "${v:-10.5}"
}

SUPORTA_TAGS=0
weasyprint --help 2>/dev/null | grep -q -- '--pdf-tags' && SUPORTA_TAGS=1

renderizar() { # $1=html $2=pdf $3=css-extra(opcional) [$4...=opções extras]
    local html="$1" pdf="$2" extra="${3:-}" args=(-q)
    shift 3 2>/dev/null || shift $#
    [ "$SUPORTA_TAGS" -eq 1 ] && args+=(--pdf-tags)   # PDF com estrutura (títulos, listas)
    [ -n "$extra" ] && args+=(-s "$extra")
    weasyprint "${args[@]}" "$@" "$html" "$pdf"
}

# Renderiza um PDF de teste e devolve o número de páginas.
# Usa o pdfinfo (poppler) se existir; senão gera o teste sem compressão e
# conta os objetos /Type /Page diretamente no arquivo.
TEM_PDFINFO=0
command -v pdfinfo >/dev/null 2>&1 && TEM_PDFINFO=1

paginas_com() { # $1=html $2=css-extra(opcional)
    local teste="$TMP_DIR/teste.pdf" n
    if [ "$TEM_PDFINFO" -eq 1 ]; then
        renderizar "$1" "$teste" "${2:-}"
        n="$(pdfinfo "$teste" 2>/dev/null | awk '/^Pages:/ { print $2 }')"
    else
        renderizar "$1" "$teste" "${2:-}" --uncompressed-pdf
        n="$(LC_ALL=C grep -ac '/Type */Page[^s]' "$teste" || true)"
    fi
    echo "${n:-1}"
}

abrir_arquivo() {
    if command -v xdg-open >/dev/null 2>&1; then xdg-open "$1" >/dev/null 2>&1 &
    elif command -v open >/dev/null 2>&1; then open "$1"
    else aviso "não sei abrir arquivos neste sistema: $1"; fi
}

verificar_ats() {
    local pdf="$1" txt="$TMP_DIR/ats.txt"
    if ! command -v pdftotext >/dev/null 2>&1; then
        aviso "--ats precisa do 'pdftotext' (pacote poppler / poppler-utils)"
        return
    fi
    pdftotext -enc UTF-8 "$pdf" "$txt"
    info "Texto extraído (como um ATS leria):"
    echo "----------------------------------------------------------------------"
    cat "$txt"
    echo "----------------------------------------------------------------------"
    local problemas=0
    if grep -qP '[\x{E000}-\x{F8FF}]' "$txt" 2>/dev/null; then
        aviso "há ícones (caracteres da Private Use Area) no texto; o ATS os lerá como lixo."
        problemas=1
    fi
    if grep -qP '[\x{FB00}-\x{FB06}]' "$txt" 2>/dev/null; then
        aviso "há ligaduras (ﬁ, ﬂ) no texto; algumas palavras podem não ser reconhecidas."
        problemas=1
    fi
    if ! grep -qiE '@[a-z0-9.-]+\.[a-z]{2,}' "$txt"; then
        aviso "nenhum e-mail encontrado no texto extraído."
        problemas=1
    fi
    for secao in "Experiência" "Formação|Educação" "Habilidades|Competências"; do
        grep -qiE "^($secao)" "$txt" || { aviso "seção '${secao%%|*}' não encontrada (ATS espera títulos padrão)."; problemas=1; }
    done
    [ "$problemas" -eq 0 ] && ok "nenhum problema de ATS encontrado"
    return 0
}

# --- Geração ----------------------------------------------------------------
mkdir -p "$SAIDA_DIR"

gerar() {
    local tema="$1" css="$CSS_DIR/$1.css" pdf html base tamanho paginas ajuste=""
    if [ -n "$SAIDA_ARQ" ]; then
        pdf="$SAIDA_ARQ"; mkdir -p "$(dirname "$pdf")"
    elif [ "$TODOS" -eq 1 ]; then
        pdf="$SAIDA_DIR/curriculo_${NOME_SLUG}_${tema}.pdf"
    else
        pdf="$SAIDA_DIR/curriculo_${NOME_SLUG}.pdf"
    fi
    html="$TMP_DIR/$tema.html"

    info "Gerando '$pdf' (tema: $tema)"

    # O CSS é referenciado por caminho absoluto: o HTML funciona em qualquer pasta.
    pandoc "$ENTRADA" \
        --from markdown \
        --to html5 \
        --standalone \
        --template "$TEMPLATE_FILE" \
        --css "$css" \
        --metadata pagetitle="$H1 – Currículo" \
        --variable nome="$H1" \
        --output "$html"

    # Primeiro sem ajuste; se passar de 1 página, procura a maior fonte que caiba.
    local extra="" ajuste_css="$TMP_DIR/ajuste_$tema.css"
    paginas="$(paginas_com "$html")"

    if [ "$AJUSTAR" -eq 1 ] && [ "$paginas" -gt 1 ]; then
        # Busca binária pelo MAIOR tamanho de fonte (em passos de $PASSO pt,
        # entre a fonte base do tema e $FONTE_MINIMA) que cabe em 1 página.
        # Como tudo no CSS é em rem/em, espaçamentos encolhem junto.
        base="$(fonte_base "$css")"
        local lo=1 hi meio melhor=""
        hi="$(awk "BEGIN { print int(($base - $FONTE_MINIMA) / $PASSO + 1e-9) }")"

        cabe() { # $1 = passos abaixo da base; sucesso se couber em 1 página
            printf 'html { font-size: %spt !important; }\n' "$(calc "$base - $1 * $PASSO")" > "$ajuste_css"
            [ "$(paginas_com "$html" "$ajuste_css")" -eq 1 ]
        }

        if [ "$hi" -ge 1 ] && cabe "$hi"; then
            melhor="$hi"; hi=$((hi - 1))
            while [ "$lo" -le "$hi" ]; do
                meio=$(((lo + hi) / 2))
                if cabe "$meio"; then melhor="$meio"; hi=$((meio - 1)); else lo=$((meio + 1)); fi
            done
            tamanho="$(calc "$base - $melhor * $PASSO")"
            ajuste="html { font-size: ${tamanho}pt !important; }"
            printf '%s\n' "$ajuste" > "$ajuste_css"
            extra="$ajuste_css"
            paginas=1
            ok "ajustado para 1 página (fonte ${base}pt → ${tamanho}pt)"
        else
            aviso "não coube em 1 página nem com fonte ${FONTE_MINIMA}pt; gerado com $paginas páginas."
            aviso "dicas: enxugue o texto, use o tema 'compacto' ou --fonte-minima 8 (ou --multipagina)"
        fi
    fi

    renderizar "$html" "$pdf" "$extra"

    if [ "$GERAR_HTML" -eq 1 ]; then
        local destino="${pdf%.pdf}.html"
        # Leva o ajuste de fonte para o HTML, para ficar igual ao PDF.
        awk -v estilo="$ajuste" '/<\/head>/ && estilo != "" { print "  <style>" estilo "</style>" } { print }' \
            "$html" > "$destino"
        ok "HTML salvo em $destino"
    fi

    ok "Currículo gerado: $pdf ($paginas página$([ "$paginas" -gt 1 ] && echo s))"

    [ "$VERIFICAR_ATS" -eq 1 ] && verificar_ats "$pdf"
    [ "$ABRIR" -eq 1 ] && abrir_arquivo "$pdf"
    return 0
}

for t in "${TEMAS[@]}"; do
    gerar "$t"
done
