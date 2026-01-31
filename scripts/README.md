# Scripts de Importação

## Importar CSV Histórico

### Pré-requisitos
```bash
npm install firebase-admin
```

### Como usar

1. Certifique-se de que o arquivo `serviceAccountKey.json` está na raiz do projeto
2. Coloque o arquivo CSV na raiz do projeto
3. Execute:

```bash
node scripts/import_csv.js
```

### O que o script faz

- Lê o arquivo `2024-2025-2026.csv`
- Para cada funcionário válido:
  - Atualiza `currentTrienniumStart` para 2024
  - Cria avaliações para 2024 e 2025 com:
    - `manualScore` (se for número)
    - `specialStatus` (se for texto como "Afastamento")
- Mostra progresso detalhado no console
- Ignora CHAPAs que não existem no Firebase

### Formato esperado do CSV

```csv
CHAPA;NOTA_2024;NOTA_2025
2711;98,5;95
2724;95,5;Licença s/vencimento
2730;Afastamento Previdenciário;Afastamento Previdenciário
```
