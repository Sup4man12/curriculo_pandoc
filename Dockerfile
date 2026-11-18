# Imagem com tudo o que o gerador precisa (pandoc, weasyprint, fontes).
#
# Construir:  docker build -t curriculo-pandoc .
# Usar:       docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/dados" curriculo-pandoc [opções]
#
# O diretório montado em /dados deve conter o curriculo.md; o PDF é salvo
# em /dados/output. Temas e template ficam dentro da imagem (/app).
FROM debian:trixie-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        pandoc \
        weasyprint \
        poppler-utils \
        fonts-liberation \
        fonts-crosextra-carlito \
        fonts-dejavu-core \
        locales \
    && sed -i 's/^# *\(pt_BR.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=pt_BR.UTF-8 \
    LC_ALL=pt_BR.UTF-8 \
    HOME=/tmp \
    XDG_CACHE_HOME=/tmp/.cache

WORKDIR /app
COPY css/ ./css/
COPY templates/ ./templates/
COPY gencurriculo.sh ./
RUN chmod +x gencurriculo.sh

WORKDIR /dados
ENTRYPOINT ["/app/gencurriculo.sh"]
