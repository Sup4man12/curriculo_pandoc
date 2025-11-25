# curriculo_pandoc

Gerador de currículos com pandoc

## Dependências

- pandoc
- weasyprint

## Preparação

```sh
git clone https://github.com/sup4man12/curriculo_pandoc.git
chmod +x curriculo.sh
```

## Como usar

Edite o arquivo **curriculo.md** e gere o pdf com o seguinte comando:

```sh
./curriculo.sh

## Também é possível passar algum tema como parâmetro.
## Temas disponíveis: dark, clean, dark, modern e curriculo(padrão)
./curriculo.sh clean

## Ou ainda, gerar todos
./curriculo.sh all
```

Os currículos ficaram localizados no diretório **output**
