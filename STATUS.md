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
- [x] Interface de 2 colunas (desktop) / 2 abas (mobile)
- [x] Coluna esquerda: Funcionários sem gestor
- [x] Coluna direita: Gestores com suas equipes
- [x] Modal com checkboxes para atribuir funcionários (substitui drag & drop)
- [x] Campo de busca no modal
- [x] Campo de busca global na tela
- [x] Filtro dinâmico por situação
- [x] Exibição de situação do funcionário
- [x] Filtra apenas funcionários disponíveis (sem gestor ou do gestor atual)
- [x] Promover/rebaixar gestores
- [x] Remover funcionários da equipe
- [x] Responsivo para mobile
- Arquivo: `lib/screens/gestao_equipes_screen.dart`

### 4. Tela de Seleção - Autoavaliação
- [x] Lista todos funcionários ativos
- [x] Busca por nome ou chapa
- [x] Filtro dinâmico por situação
- [x] Exibição de situação do funcionário
- [x] Badge "Concluído" para quem já fez autoavaliação
- [x] Modal de senha antes de abrir formulário
- [x] Redireciona para formulário correto (operacional ou gerencial)
- Arquivo: `lib/screens/autoavaliacao_screen.dart`

### 5. Formulário de Avaliação ⚠️ PERGUNTAS DINÂMICAS
- [x] Cabeçalho com informações do funcionário
- [x] Exibição de situação do funcionário
- [x] Formatação de data de admissão (dd/MM/yyyy)
- [x] Barra de progresso
- [x] **Indicador de progresso "Avaliando X de Y" (quando em loop de gestor)**
- [x] Botão para limpar todas respostas
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
- [x] Confirmação ao sair sem salvar (retorna false para cancelar loop)
- [x] Loading state enquanto carrega perguntas
- [x] Retorna true/false para controle do loop de avaliações
- Arquivo: `lib/screens/formulario_avaliacao_screen.dart`
- **Script para popular perguntas:** `popular_perguntas.js`

### 6. Firebase
- [x] Firestore configurado
- [x] Collections: config, funcionarios, evaluations, questions
- [x] Regras de segurança (modo desenvolvimento)
- [x] Helper de situações (SituacaoHelper) com 23 códigos de situação

---

## ❌ FALTA FAZER

### 1. Tela de Avaliação do Gestor ✅ COMPLETO
- [x] Lista TODOS os gestores (isManager = true)
- [x] Busca por nome
- [x] Filtro dinâmico por situação
- [x] Exibição de situação do gestor
- [x] Mostra quantidade de subordinados
- [x] Modal de senha do administrador antes de iniciar
- [x] Loop automático de avaliação de subordinados
- [x] Mostra progresso: "Avaliando 3 de 10" no AppBar
- [x] Cancela loop se usuário sair no meio
- [x] Diálogo de conclusão ao terminar todas avaliações
- [x] Permite gestores serem subordinados de outros gestores
- Arquivo: `lib/screens/avaliacao_gestor_screen.dart`

### 2. Central de Impressão
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

### 3. Tela de Gerenciar Perguntas ✅ COMPLETO
- [x] CRUD de perguntas (adicionar novas)
- [x] Separar por tipo: Operacional e Gerencial (botões de seleção)
- [x] Separar por seção e subseção (agrupamento automático)
- [x] Ativar/desativar perguntas (botão de olho)
- [x] Dropdowns para seção e subseção com opções pré-definidas
- [x] Ordem calculada automaticamente (última ordem + 1)
- [x] Campo de busca para filtrar perguntas
- [x] Visualização organizada em cards expansíveis
- [x] Perguntas inativas não aparecem nos formulários
- [x] **NÃO permite editar ou excluir** (mantém histórico intacto)
- [ ] ~~Reordenar perguntas~~ (não necessário por enquanto - ordem automática funciona)
- Arquivo: `lib/screens/config_menu_screen.dart`

### 4. Importação de Funcionários ✅ COMPLETO
- [x] Script Python sincroniza funcionários do SQL Server para Firestore
- [x] Collection: `funcionarios` (migrado de `employees`)
- [x] Campos: ativo, chapa, data_admissao, escolaridade, faixa, funcao, last_sync, nivel, nome, salario, situacao
- [x] Filtro dinâmico por situação nas telas (busca e filtros)
- [x] Desativação automática de funcionários não encontrados no SQL
- [x] Formatação de data de admissão (dd/MM/yyyy)
- [x] Exibição de situação do funcionário em todas as telas
- Script: `C:\scripts\funcionarios\sincronizador.py`

### 5. Sistema de Login Definitivo
- [ ] Login por MATRÍCULA em vez de senha única
- [ ] Gestão de comissão (muda a cada 4 anos)
- [ ] Membros da comissão têm acesso total
- [ ] Funcionários comuns só acessam autoavaliação

---

## 🆕 NOVIDADES IMPLEMENTADAS

### Sistema de Situação de Funcionários
- **Helper criado**: `lib/utils/situacao_helper.dart`
- **23 códigos de situação** implementados (A=Ativo, C=Contrato Suspenso, D=Demitido, etc.)
- **Filtro dinâmico**: Mostra apenas situações existentes nos funcionários ativos
- **Exibição**: Todas as telas mostram situação completa (ex: "A - Ativo")
- **Busca**: Funciona em conjunto com filtro de situação
- **Telas atualizadas**:
  - Autoavaliação: busca + filtro dinâmico + exibição
  - Avaliação do Gestor: busca + filtro dinâmico + exibição
  - Gestão de Equipes: busca + filtro dinâmico + exibição (mobile e desktop)
  - Formulário de Avaliação: exibição de situação e data formatada

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

### Collection: funcionarios
- **doc: {chapa}**
  - chapa: string
  - nome: string
  - funcao: string
  - nivel: string
  - grau: string (faixa salarial)
  - escolaridade: string
  - situacao: string (A, C, D, E, F, etc.)
  - data_admissao: Timestamp
  - salario: number
  - ativo: boolean
  - isManager: boolean
  - managerId: string | null
  - last_sync: Timestamp

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

1. ✅ ~~Deploy atual (formulário de avaliação pronto)~~
2. ✅ ~~Criar avaliacao_gestor_screen.dart (seleção + loop automático)~~
3. ✅ ~~Melhorar gestão de equipes (modal em vez de drag & drop)~~
4. ✅ ~~Implementar CRUD de perguntas (gerenciar perguntas do Firestore)~~
5. ✅ ~~Implementar importação de funcionários (script Python + filtros dinâmicos)~~
6. **ATUAL: Implementar Central de Impressão** (listagem + filtros)
7. **Implementar geração de PDFs** (Anexos I-VI)
8. **Ajustar sistema de login** (matrícula + comissão)

---

## COMANDOS ÚTEIS

```bash
# Build (COM ÍCONES - importante para não perder os icons do Material)
flutter build web --no-tree-shake-icons --release

# Deploy
firebase deploy --only hosting

# Run local
flutter run -d chrome

# Clean
flutter clean
```

---

## NOTAS IMPORTANTES

- Senha atual: "1234" (config/general/adminPassword no Firestore)
- Firestore está em modo desenvolvimento (read/write aberto)
- Todos os formulários usam as perguntas dos documentos Word em `avaliacoes/`
- EmployeeSnapshot garante dados históricos corretos nos PDFs
- Sistema calcula média automaticamente ao salvar avaliação
- **IMPORTANTE**: Sempre usar `--no-tree-shake-icons` no build para não perder os ícones do Material
- Headers de cache adicionados no index.html para evitar problemas de cache no navegador
- Gestores podem ser subordinados de outros gestores (hierarquia flexível)
- **Perguntas dinâmicas**: Sistema carrega perguntas do Firestore, permitindo adicionar/desativar sem rebuild
- **Ordem automática**: Perguntas são adicionadas ao final da subseção automaticamente
- **Índices necessários no Firestore**:
  - `questions`: tipo (Asc) + ordem (Asc)
  - `questions`: tipo (Asc) + secao (Asc) + subsecao (Asc)
