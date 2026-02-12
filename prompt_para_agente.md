# Solicitação de Ajuste - Lógica de Ocorrência Disciplinar e Filtros

## Objetivo Geral
Refatorar o fluxo de "Ocorrência Disciplinar" para impedir que o próprio funcionário a sinalize, transferindo a responsabilidade para o Gestor e criando um fluxo de validação física pela Comissão.

## Detalhamento das Alterações

### 1. Autoavaliação (Funcionário)
- **Remover**: Retirar a opção/checkbox "Ocorrência Disciplinar" do modal inicial ou do formulário de autoavaliação. O funcionário não deve ter controle sobre isso.

### 2. Avaliação do Gestor
- **Adicionar**: Incluir a opção "Ocorrência Disciplinar" (Checkbox/Switch) ao **final** do formulário de avaliação do gestor.
- **Regra de Status**:
    - Se o Gestor marcar **"Sim"**: O status da avaliação deve ser salvo como `aguardando_comissao` (pendente), e **não** `concluida`.
    - Se marcar **"Não"**: Segue o fluxo normal de conclusão.

### 3. Gestão Visual e Filtros (Todas as Telas de Lista)
Aplicar as seguintes melhorias na **Central de Impressão**, **Dashboard do Gestor** e **Encerramento de Ciclo**:

- **Filtro de Status**: Adicionar filtro para listar avaliações por status (ex: `Aguardando Comissão`, `Concluída`, etc.).
- **Indicador Visual**: Exibir um ícone de alerta (ex: bandeira vermelha) ao lado do funcionário que estiver com status `aguardando_comissao`.
- **Interatividade**:
    - Ao clicar neste ícone de alerta em qualquer tela (Gestor ou Central de Impressão), o sistema deve **redirecionar** o usuário para a tela de **Encerramento de Ciclo**.
    - O redirecionamento deve aplicar automaticamente o **filtro pela matrícula** do funcionário em questão, para facilitar a localização imediata.

### 4. Encerramento de Ciclo (Comissão)
- **Ação de Validação**:
    - Na tela de Encerramento de Ciclo, permitir que a Comissão visualize os itens pendentes (`aguardando_comissao`).
    - Disponibilizar um botão ou ação clara para **"Confirmar Entrega de Prova Física"**.
- **Comportamento**:
    - Ao confirmar a entrega física, o sistema deve alterar o status da avaliação de `aguardando_comissao` para `concluida`.
    - Isso libera a nota e o encerramento do ciclo para aquele funcionário.
