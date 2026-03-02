# Osório no Buraco 🕳️

Mapeamento colaborativo de buracos em Osório/RS. Os moradores podem reportar buracos pelo WhatsApp, e o mapa é atualizado manualmente.

## Como publicar no GitHub Pages

1. Acesse o repositório no GitHub: `https://github.com/henriqueboaventura/osorionoburaco`

2. Vá em **Settings** > **Pages** (na barra lateral esquerda)

3. Em **Source**, selecione **Deploy from a branch**

4. Em **Branch**, selecione `main` e a pasta `/ (root)`, depois clique em **Save**

5. Aguarde alguns segundos e o site estará disponível em:
   `https://henriqueboaventura.github.io/osorionoburaco/`

> O arquivo `.nojekyll` já está na raiz do projeto, o que é necessário para o GitHub Pages servir corretamente os arquivos estáticos.

## Como rodar localmente

O site usa `fetch()` para carregar o `data.json`, então **não funciona abrindo o `index.html` diretamente no navegador** (bloqueio de CORS). É necessário um servidor HTTP local.

**Com Python** (sem instalar nada, se tiver Python 3):

```bash
python3 -m http.server 8080
```

**Com Node.js:**

```bash
npx serve .
```

Depois acesse `http://localhost:8080` (ou a porta indicada) no navegador.

## Como adicionar um novo buraco

### 1. Adicionar a foto

Coloque a foto do buraco na pasta `photos/`. Use o padrão de nome já adotado:

```
photos/buraco-AAAAMMDDHHMMSS-xxxxxx.jpg
```

Exemplo: `photos/buraco-20260302143000-ab1cd2.jpg`

### 2. Editar o `data.json`

Abra o arquivo `data.json` e adicione uma nova entrada no final do array, seguindo este modelo:

```json
{
    "id": 99,
    "lat": -29.8900,
    "lng": -50.2500,
    "address": "Rua Exemplo, 123 - Bairro",
    "photo": "photos/buraco-20260302143000-ab1cd2.jpg",
    "reporter": "Nome de quem reportou",
    "reportedDate": "2026-03-02",
    "fixed": false,
    "fixedDate": null
}
```

**Campos:**

| Campo          | Descrição                                                      |
|----------------|----------------------------------------------------------------|
| `id`           | Número único sequencial (incrementar o último)                 |
| `lat` / `lng`  | Coordenadas GPS (use Google Maps para obter: clique com botão direito > "O que há aqui?") |
| `address`      | Endereço legível com rua e bairro                              |
| `photo`        | Caminho relativo para a foto em `photos/`                      |
| `reporter`     | Nome de quem enviou o buraco                                   |
| `reportedDate` | Data no formato `AAAA-MM-DD`                                   |
| `fixed`        | `false` se ainda não foi consertado, `true` se foi            |
| `fixedDate`    | `null` se não consertado, ou a data `"AAAA-MM-DD"` do conserto |

### 3. Publicar as mudanças

```bash
git add photos/buraco-20260302143000-ab1cd2.jpg data.json
git commit -m "new hole"
git push
```

O GitHub Pages atualiza o site automaticamente em alguns segundos após o push.

## Marcar um buraco como consertado

No `data.json`, encontre o buraco pelo `id` e altere:

```json
"fixed": true,
"fixedDate": "2026-03-02"
```

Depois faça o commit e push normalmente.

## Estrutura do projeto

```
osorionoburaco/
├── index.html       # Página principal
├── app.js           # Lógica do mapa e interações
├── styles.css       # Estilos visuais
├── data.json        # Dados dos buracos
├── favicon.svg      # Ícone do site
├── .nojekyll        # Necessário para o GitHub Pages
└── photos/          # Fotos dos buracos
```
