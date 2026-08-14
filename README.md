# curriculo_pandoc

Gerador de currículos com pandoc

![Ilustração de modelo e output](./exemplo.png)

## Dependências

- pandoc
- weasyprint

## Preparação

```sh
git clone https://github.com/sup4man12/curriculo_pandoc.git
cd curriculo_pandoc
chmod +x gencurriculo.sh
```

## Como usar

Edite o arquivo **curriculo.md** e gere o pdf com o seguinte comando:

```sh
./gencurriculo.sh
```

O projeto usa somente o tema principal, localizado em **css/curriculo.css**.
O HTML intermediário usa o template **templates/curriculo.html** para manter o PDF livre do CSS padrão do Pandoc.

O currículo gerado ficará localizado no diretório **output** com o formato:

```txt
curriculo_primeiro_segundo.pdf
```

O nome é puxado das duas primeiras palavras do primeiro título H1 (`#`) do arquivo **curriculo.md** e convertido para minúsculas. Por exemplo, `# Pablo Moura` gera **output/curriculo_pablo_moura.pdf**.

## Estrutura de arquivos

```
curriculo/
├── css/
│   ├── base.css
│   ├── curriculo.css
│   └── fonts/
├── curriculo.md
├── gencurriculo.sh
├── templates/
│   └── curriculo.html
└── output/
    └── curriculo_primeiro_segundo.pdf
```
