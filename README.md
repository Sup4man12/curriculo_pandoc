# curriculo_pandoc

gerador de de cúrriculos com pandoc

## Depedências

- pandoc
- weasyprint

## Preparação

```sh
git clone https://github.com/sup4man12/curriculo_pandoc.git
chmod +x curriculo.sh
```

## Como usar

edite o arquivo **curriculo.md** e gere o pdf com o seguinte comando:

```sh
./curriculo.sh

## Também é possível passar algum tema como parametro.
## Temas dísponiveis: dark, clean, dark, modern e curriculo(padrão)
./curriculo.sh clean

## Ou ainda, gerar todos
./curriculo.sh all
```

Os cúrriculos ficaram localizados no diretório **output**
