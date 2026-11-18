<#
.SYNOPSIS
    Gera um currículo em PDF a partir de Markdown (versão Windows do gencurriculo.sh).

.DESCRIPTION
    Converte curriculo.md em HTML com o pandoc e o HTML em PDF com o weasyprint,
    usando um dos temas da pasta css/. Por padrão reduz a fonte até o currículo
    caber em uma página A4.

.EXAMPLE
    .\gencurriculo.ps1
.EXAMPLE
    .\gencurriculo.ps1 -Tema moderno
.EXAMPLE
    .\gencurriculo.ps1 -Entrada ingles.md -Saida output\resume.pdf
.EXAMPLE
    .\gencurriculo.ps1 -Todos
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Tema = 'curriculo',
    [string]$Entrada = 'curriculo.md',
    [string]$Saida = '',
    [string]$Diretorio = 'output',
    [switch]$Todos,
    [switch]$Listar,
    [switch]$Multipagina,
    [double]$FonteMinima = 8.5,
    [switch]$Html,
    [switch]$Abrir,
    [switch]$Ajuda
)

$ErrorActionPreference = 'Stop'
$Inv = [System.Globalization.CultureInfo]::InvariantCulture
$Passo = 0.25

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CssDir = Join-Path $ScriptDir 'css'
$TemplateFile = Join-Path $ScriptDir 'templates\curriculo.html'

function Erro([string]$msg) { Write-Host "Erro: $msg" -ForegroundColor Red; exit 1 }
function Aviso([string]$msg) { Write-Host "Aviso: $msg" -ForegroundColor Yellow }
function Info([string]$msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok([string]$msg) { Write-Host "OK: $msg" -ForegroundColor Green }

function Get-Temas {
    Get-ChildItem -Path $CssDir -Filter '*.css' | Where-Object { $_.BaseName -ne 'base' } | Sort-Object BaseName
}

function Show-Temas {
    Write-Host 'Temas disponíveis:'
    foreach ($css in Get-Temas) {
        $primeira = Get-Content -Path $css.FullName -TotalCount 1 -Encoding UTF8
        $desc = ''
        if ($primeira -match '^/\*\s*Tema:\s*\S+\s*[—-]*\s*(.*?)\s*\*/') { $desc = $Matches[1] }
        Write-Host ('  {0,-12} {1}' -f $css.BaseName, $desc)
    }
}

if ($Ajuda) { Get-Help $MyInvocation.MyCommand.Path -Detailed; exit 0 }
if ($Listar) { Show-Temas; exit 0 }

foreach ($dep in 'pandoc', 'weasyprint') {
    if (-not (Get-Command $dep -ErrorAction SilentlyContinue)) {
        Erro "'$dep' não encontrado no PATH. Instale-o ou use o Docker (veja o README)."
    }
}
if (-not (Test-Path $Entrada -PathType Leaf)) { Erro "arquivo de entrada '$Entrada' não encontrado" }
if (-not (Test-Path $TemplateFile -PathType Leaf)) { Erro "template '$TemplateFile' não encontrado" }

if ($Todos) {
    if ($Saida) { Erro '-Saida não pode ser usado junto com -Todos' }
    $Temas = @(Get-Temas | ForEach-Object { $_.BaseName })
} else {
    if (-not (Test-Path (Join-Path $CssDir "$Tema.css"))) { Show-Temas; Erro "tema '$Tema' não encontrado" }
    $Temas = @($Tema)
}

# --- Nome da pessoa: primeiro H1 fora do YAML, de comentários e de código ---
$H1 = $null
$yaml = $false; $codigo = $false; $comentario = $false; $n = 0
foreach ($linha in Get-Content -Path $Entrada -Encoding UTF8) {
    $n++
    if ($n -eq 1 -and $linha -match '^---\s*$') { $yaml = $true; continue }
    if ($yaml) { if ($linha -match '^(---|\.\.\.)\s*$') { $yaml = $false }; continue }
    if ($linha -match '^(```|~~~)') { $codigo = -not $codigo; continue }
    if ($codigo) { continue }
    if ($linha -match '<!--') { $comentario = $true }
    if ($comentario) { if ($linha -match '-->') { $comentario = $false }; continue }
    if ($linha -match '^#\s+(.+?)\s*#*\s*$') { $H1 = $Matches[1]; break }
}
if (-not $H1) { Erro "nenhum título H1 (linha começando com '# ') encontrado em $Entrada" }

# "José Antônio da Silva" -> "jose_antonio"
$semAcento = -join ($H1.Normalize([Text.NormalizationForm]::FormD).ToCharArray() |
    Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 'NonSpacingMark' })
$palavras = @(($semAcento.ToLowerInvariant() -replace '[^a-z0-9 ]', '').Split(' ', [StringSplitOptions]::RemoveEmptyEntries))
if ($palavras.Count -eq 0) { Erro "não foi possível gerar o nome do arquivo a partir de '$H1'; use -Saida" }
$NomeSlug = ($palavras | Select-Object -First 2) -join '_'

# --- Utilitários --------------------------------------------------------------
$TmpDir = Join-Path ([IO.Path]::GetTempPath()) ("curriculo_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $TmpDir | Out-Null

$SuportaTags = (& weasyprint --help 2>&1 | Out-String) -match '--pdf-tags'

function Invoke-Weasyprint([string]$HtmlIn, [string]$PdfOut, [string]$Extra = '', [switch]$SemCompressao) {
    $argsW = @('-q')
    if ($SuportaTags) { $argsW += '--pdf-tags' }
    if ($Extra) { $argsW += @('-s', $Extra) }
    if ($SemCompressao) { $argsW += '--uncompressed-pdf' }
    & weasyprint @argsW $HtmlIn $PdfOut
    if ($LASTEXITCODE -ne 0) { Erro "weasyprint falhou ao gerar $PdfOut" }
}

# Gera um PDF de teste sem compressão e conta os objetos /Type /Page.
function Get-Paginas([string]$HtmlIn, [string]$Extra = '') {
    $teste = Join-Path $TmpDir 'teste.pdf'
    Invoke-Weasyprint $HtmlIn $teste $Extra -SemCompressao
    $bytes = [IO.File]::ReadAllText($teste, [Text.Encoding]::GetEncoding(28591))
    $qtd = ([regex]::Matches($bytes, '/Type\s*/Page(?!s)')).Count
    if ($qtd -lt 1) { return 1 } else { return $qtd }
}

function Get-FonteBase([string]$Css) {
    $m = Select-String -Path $Css -Pattern '^html\s*\{\s*font-size:\s*([0-9.]+)pt' | Select-Object -Last 1
    if ($m) { return [double]::Parse($m.Matches[0].Groups[1].Value, $Inv) } else { return 10.5 }
}

function Format-Pt([double]$v) { return $v.ToString('0.##', $Inv) }

function New-Curriculo([string]$NomeTema) {
    $css = Join-Path $CssDir "$NomeTema.css"
    if ($Saida) { $pdf = $Saida }
    elseif ($Todos) { $pdf = Join-Path $Diretorio "curriculo_${NomeSlug}_$NomeTema.pdf" }
    else { $pdf = Join-Path $Diretorio "curriculo_$NomeSlug.pdf" }
    $pastaPdf = Split-Path -Parent $pdf
    if ($pastaPdf) { New-Item -ItemType Directory -Force -Path $pastaPdf | Out-Null }

    $htmlTmp = Join-Path $TmpDir "$NomeTema.html"
    Info "Gerando '$pdf' (tema: $NomeTema)"

    # O CSS é passado como URL file:/// para o weasyprint encontrar no Windows.
    $cssUrl = ([Uri]::new((Resolve-Path $css).Path)).AbsoluteUri
    & pandoc $Entrada --from markdown --to html5 --standalone `
        --template $TemplateFile --css $cssUrl `
        --metadata "pagetitle=$H1 – Currículo" --variable "nome=$H1" `
        --output $htmlTmp
    if ($LASTEXITCODE -ne 0) { Erro 'pandoc falhou' }

    $extra = ''; $ajuste = ''
    $paginas = Get-Paginas $htmlTmp

    if (-not $Multipagina -and $paginas -gt 1) {
        $base = Get-FonteBase $css
        $ajusteCss = Join-Path $TmpDir "ajuste_$NomeTema.css"
        $hi = [int][math]::Floor(($base - $FonteMinima) / $Passo + 1e-9)
        $lo = 1; $melhor = 0

        $cabe = {
            param([int]$k)
            $t = Format-Pt ($base - $k * $Passo)
            [IO.File]::WriteAllText($ajusteCss, "html { font-size: ${t}pt !important; }`n")
            return ((Get-Paginas $htmlTmp $ajusteCss) -eq 1)
        }

        if ($hi -ge 1 -and (& $cabe $hi)) {
            $melhor = $hi; $hi--
            while ($lo -le $hi) {
                $meio = [int][math]::Floor(($lo + $hi) / 2)
                if (& $cabe $meio) { $melhor = $meio; $hi = $meio - 1 } else { $lo = $meio + 1 }
            }
            $tamanho = Format-Pt ($base - $melhor * $Passo)
            $ajuste = "html { font-size: ${tamanho}pt !important; }"
            [IO.File]::WriteAllText($ajusteCss, "$ajuste`n")
            $extra = $ajusteCss
            $paginas = 1
            Ok "ajustado para 1 página (fonte $(Format-Pt $base)pt -> ${tamanho}pt)"
        } else {
            Aviso "não coube em 1 página nem com fonte $(Format-Pt $FonteMinima)pt; gerado com $paginas páginas."
            Aviso "dicas: enxugue o texto, use o tema 'compacto' ou -FonteMinima 8 (ou -Multipagina)"
        }
    }

    Invoke-Weasyprint $htmlTmp $pdf $extra

    if ($Html) {
        $destino = [IO.Path]::ChangeExtension($pdf, '.html')
        $conteudo = [IO.File]::ReadAllText($htmlTmp, [Text.Encoding]::UTF8)
        if ($ajuste) { $conteudo = $conteudo.Replace('</head>', "  <style>$ajuste</style>`n</head>") }
        [IO.File]::WriteAllText($destino, $conteudo, (New-Object Text.UTF8Encoding $false))
        Ok "HTML salvo em $destino"
    }

    $s = if ($paginas -gt 1) { 's' } else { '' }
    Ok "Currículo gerado: $pdf ($paginas página$s)"
    if ($Abrir) { Invoke-Item $pdf }
}

try {
    foreach ($t in $Temas) { New-Curriculo $t }
} finally {
    Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
}
