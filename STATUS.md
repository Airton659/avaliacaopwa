# STATUS DO PROJETO SAD - Sistema de Avaliação de Desempenho

## OBJETIVO
Criar um PWA em Flutter para avaliação de desempenho dos funcionários da EDI (Empresa de Desenvolvimento de Itabira), otimizado para tablets em modo quiosque.

## DEPLOY
- URL: https://avaliacao-itaurb.web.app
- Firebase Project: sad-edi
- Hosting Site: avaliacao-itaurb

---

## ✅ JÁ FEITO

### 1. Tela de Login
- [x] Login com senha única (config/general/adminPassword)
- [x] Senha padrão: "1234"
- Arquivo: `lib/screens/login_screen.dart`

### 2. Dashboard Principal
- [x] 3 cards gigantes: Autoavaliação, Avaliação do Gestor, Central de Impressão
- [x] Responsividade para landscape e portrait
- [x] Menu de configurações (Gestão de Equipes, Gerenciar Perguntas, Sincronizar Planilha)
- [x] Botão de sair
- Arquivo: `lib/screens/dashboard_screen.dart`

### 3. Gestão de Equipes
- [x] Interface de 2 colunas
- [x] Coluna esquerda: Funcionários sem gestor
- [x] Coluna direita: Gestores com suas equipes
- [x] Drag & drop para atribuir funcionários a gestores
- [x] Promover/rebaixar gestores
- [x] Remover funcionários da equipe
- Arquivo: `lib/screens/gestao_equipes_screen.dart`

### 4. Tela de Seleção - Autoavaliação
- [x] Lista todos funcionários ativos
- [x] Busca por nome ou chapa
- [x] Badge "Concluído" para quem já fez autoavaliação
- [x] Modal de senha antes de abrir formulário
- [x] Redireciona para formulário correto (operacional ou gerencial)
- Arquivo: `lib/screens/autoavaliacao_screen.dart`

### 5. Formulário de Avaliação ⚠️ PERGUNTAS DINÂMICAS
- [x] Cabeçalho com informações do funcionário
- [x] Barra de progresso
- [x] **CARREGA PERGUNTAS DO FIRESTORE (collection: questions)**
- [x] Fallback com perguntas padrão se Firestore estiver vazio
- [x] Filtra por tipo (OPERACIONAL ou GERENCIAL) e ativo=true
- [x] Agrupa por seção e subseção automaticamente
- [x] Perguntas do Anexo I (Operacional) - 20 perguntas
  - I.1 - Discrição (4 perguntas)
  - I.2 - Assiduidade (4 perguntas)
  - I.3 - Disciplina (5 perguntas)
  - II - Fatores operacionais/Produtividade (7 perguntas)
- [x] Perguntas do Anexo IV (Gerencial) - 20 perguntas
  - III.1 - Decisão (3 perguntas)
  - III.2 - Liderança (4 perguntas)
  - III.3 - Gestão (4 perguntas)
  - III.4 - Planejamento (4 perguntas)
  - III.5 - Conhecimento técnico (5 perguntas)
- [x] Escala visual de 1 a 5 com cores (vermelho, laranja, amarelo, verde claro, verde)
- [x] Campo de observações (opcional)
- [x] Validação: só pode finalizar se todas as perguntas respondidas
- [x] Salvar no Firestore (collection: evaluations)
- [x] EmployeeSnapshot para dados históricos
- [x] Confirmação ao sair sem salvar
- [x] Loading state enquanto carrega perguntas
- Arquivo: `lib/screens/formulario_avaliacao_screen.dart`
- **Script para popular perguntas:** `popular_perguntas.js`

### 6. Firebase
- [x] Firestore configurado
- [x] Collections: config, employees, evaluations, questions
- [x] Regras de segurança (modo desenvolvimento)

---

## ❌ FALTA FAZER

### 1. Tela de Seleção - Avaliação do Gestor
- [ ] Similar à autoavaliacao_screen.dart
- [ ] Mostrar apenas subordinados do gestor logado
- [ ] Badge "Concluído" para quem já foi avaliado pelo gestor
- [ ] Modal de senha antes de abrir formulário
- Criar arquivo: `lib/screens/avaliacao_gestor_screen.dart`

### 2. Loop de Avaliação da Equipe (Gestor avalia todos)
- [ ] Tela que permite gestor avaliar toda sua equipe sequencialmente
- [ ] Após finalizar uma avaliação, vai automaticamente para próximo subordinado
- [ ] Mostra progresso: "Avaliando 3 de 10"
- [ ] Opção de pular funcionário
- [ ] Só sai ao terminar todos ou com senha
- Criar arquivo: `lib/screens/loop_avaliacao_gestor_screen.dart`

### 3. Central de Impressão
- [ ] Filtros: ano, tipo de avaliação, nome/chapa
- [ ] Listar todas avaliações
- [ ] Botão "Gerar PDF" para cada avaliação
- [ ] Geração de PDFs (Anexos I-VI)
  - Anexo I: Autoavaliação Operacional
  - Anexo II: Avaliação Gestor Operacional
  - Anexo III: Consolidado Operacional (média das duas)
  - Anexo IV: Autoavaliação Gerencial
  - Anexo V: Avaliação Gestor Gerencial
  - Anexo VI: Consolidado Gerencial (média das duas)
- Arquivo atual: `lib/screens/central_impressao_screen.dart` (placeholder)

### 4. Tela de Gerenciar Perguntas
- [ ] CRUD de perguntas
- [ ] Separar por tipo: Operacional e Gerencial
- [ ] Separar por seção
- [ ] Ativar/desativar perguntas
- [ ] Reordenar perguntas
- Arquivo atual: `lib/screens/config_menu_screen.dart` (placeholder)

### 5. Sincronização com Google Sheets
- [ ] Importar funcionários da planilha
- [ ] Botão no menu de configurações (Dashboard)
- [ ] Diálogo de confirmação
- [ ] Atualizar dados sem perder isManager e managerId

### 6. Sistema de Login Definitivo
- [ ] Login por MATRÍCULA em vez de senha única
- [ ] Gestão de comissão (muda a cada 4 anos)
- [ ] Membros da comissão têm acesso total
- [ ] Funcionários comuns só acessam autoavaliação

---

## ESTRUTURA DO FIRESTORE

### Collection: config
- **doc: general**
  - adminPassword: "1234"
  - currentCycle: "2024/2025"

### Collection: questions
- **doc: {ID}** (ex: OP_1, GER_1)
  - ordem: number
  - tipo: "OPERACIONAL" | "GERENCIAL"
  - secao: string (ex: "I - Fatores comportamentais")
  - subsecao: string (ex: "I.1 - Discrição")
  - pergunta: string
  - ativo: boolean

### Collection: employees
- **doc: {chapa}**
  - chapa: string
  - nome: string
  - funcao: string
  - nivel: string
  - grau: string
  - isManager: boolean
  - managerId: string | null
  - active: boolean

### Collection: evaluations
- **doc: {ano}_{chapa}_AUTO** (autoavaliação)
  - chapa: string
  - ciclo: "2024/2025"
  - ano: "2024"
  - tipo: "AUTO_OPERACIONAL" | "AUTO_GERENCIAL"
  - isAutoavaliacao: true
  - isGerencial: boolean
  - respostas: {q0: 5, q1: 4, q2: 3, ...}
  - observacoes: string
  - media: number
  - totalPerguntas: number
  - employeeSnapshot: {chapa, nome, funcao, nivel, grau, isManager}
  - createdAt: timestamp
  - updatedAt: timestamp

- **doc: {ano}_{chapa}_GESTOR** (avaliação do gestor)
  - (mesma estrutura, mas tipo: "GESTOR_OPERACIONAL" ou "GESTOR_GERENCIAL")

---

## PRÓXIMOS PASSOS (EM ORDEM)

1. **Deploy atual** (formulário de avaliação pronto)
2. **Criar avaliacao_gestor_screen.dart** (seleção de subordinados)
3. **Criar loop_avaliacao_gestor_screen.dart** (avaliar equipe inteira)
4. **Implementar Central de Impressão** (listagem + filtros)
5. **Implementar geração de PDFs** (Anexos I-VI)
6. **Implementar sincronização Google Sheets**
7. **Ajustar sistema de login** (matrícula + comissão)

---

## COMANDOS ÚTEIS

```bash
# Build
flutter build web --release

# Deploy
firebase deploy --only hosting:avaliacao-itaurb

# Run local
flutter run -d chrome
```

---

## NOTAS IMPORTANTES

- Senha atual: "1234" (config/general/adminPassword no Firestore)
- Firestore está em modo desenvolvimento (read/write aberto)
- Todos os formulários usam as perguntas dos documentos Word em `avaliacoes/`
- EmployeeSnapshot garante dados históricos corretos nos PDFs
- Sistema calcula média automaticamente ao salvar avaliação
