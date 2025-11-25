# Templates de CSS para Currículo

Este projeto contém vários templates de CSS para personalizar a aparência do seu currículo em PDF.

## Como usar

Use o script `curriculo.sh` com o nome do template desejado:

```bash
./curriculo.sh clean      # Template minimalista
./curriculo.sh modern     # Template moderno e colorido
./curriculo.sh classic    # Template clássico profissional
./curriculo.sh dark       # Template dark mode
./curriculo.sh sidebar    # Template com sidebar
./curriculo.sh curriculo  # Template padrão (original)
```

## Templates disponíveis

### 1. `curriculo.css` (Padrão)
- **Estilo**: Moderno e compacto
- **Cores**: Azul (#3a6ea5) com fundo claro
- **Características**: Design limpo, espaçamento otimizado para impressão
- **Ideal para**: Uso geral, impressão em papel

### 2. `clean.css` (Minimalista)
- **Estilo**: Ultra minimalista e elegante
- **Cores**: Tons de cinza e preto, sem cores vibrantes
- **Características**: 
  - Tipografia leve (font-weight: 300)
  - Espaçamento generoso
  - Bordas sutis
- **Ideal para**: Profissionais que preferem simplicidade e elegância

### 3. `modern.css` (Moderno e Colorido)
- **Estilo**: Vibrante e contemporâneo
- **Cores**: Gradientes roxo/azul (#6366f1, #8b5cf6), rosa (#ec4899)
- **Características**:
  - Gradientes em títulos
  - Cards com fundo colorido
  - Bordas arredondadas
  - Sombras sutis
- **Ideal para**: Profissionais de tecnologia, design, marketing

### 4. `classic.css` (Clássico Profissional)
- **Estilo**: Tradicional e formal
- **Cores**: Azul marinho (#1a365d), cinza profissional
- **Características**:
  - Fonte serifada (Times New Roman)
  - Bordas duplas
  - Texto justificado
  - Layout centrado para título
- **Ideal para**: Setores tradicionais, jurídico, financeiro, acadêmico

### 5. `dark.css` (Dark Mode)
- **Estilo**: Tema escuro moderno
- **Cores**: Fundo escuro (#1a1a1a), azul claro (#4a9eff)
- **Características**:
  - Fundo escuro com texto claro
  - Cards com fundo cinza escuro
  - Destaques em azul
  - Visual moderno e tech
- **Ideal para**: Desenvolvedores, profissionais de TI, impressão em tela

### 6. `sidebar.css` (Com Sidebar)
- **Estilo**: Layout com barra lateral
- **Cores**: Sidebar escura (#2c3e50), conteúdo claro
- **Características**:
  - Layout de duas colunas (30% sidebar, 70% conteúdo)
  - Sidebar com fundo escuro
  - Separação visual clara
  - **Nota**: Requer estrutura HTML específica para funcionar completamente
- **Ideal para**: Currículos com muitas informações, design diferenciado

## Personalização

Todos os templates usam variáveis CSS (`:root`) que podem ser facilmente modificadas:

- Cores principais
- Espaçamentos
- Tamanhos de fonte
- Bordas e sombras

Edite o arquivo CSS do template desejado para personalizar ainda mais.

## Requisitos

- Pandoc
- WeasyPrint (PDF engine)
- Fonte NerdFont (opcional, para ícones)

## Estrutura de arquivos

```
curriculo/
├── css/
│   ├── curriculo.css  (padrão)
│   ├── clean.css
│   ├── modern.css
│   ├── classic.css
│   ├── dark.css
│   └── sidebar.css
├── curriculo.md
├── curriculo.sh
└── output/
    └── curriculo-*.pdf
```
