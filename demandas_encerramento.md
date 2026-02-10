# Planejamento: Encerramento de Ciclo e Adequação de Documentos

Este documento organiza as demandas pendentes para a aba "Encerramento de Ciclo", focando na correção do Anexo XII e na lógica de múltiplos documentos conforme o estágio do funcionário no triênio.

## Ordem Sugerida de Implementação

### 1. Adequação Visual Crítica do Anexo XII (Prioridade: Alta)
O documento atual está funcionalmente correto (cálculos), mas visualmente fora do padrão do sistema e incompleto juridicamente.
- [ ] **Padronização do Cabeçalho:** Remover o título simples e implementar o cabeçalho oficial padrão (idêntico aos Anexos I-VI), contendo logotipos, nome da empresa e identificação do período.
- [ ] **Bloco de Validação da Comissão:** Inserir o componente de "Validação da Comissão" no rodapé (já existente no `PdfService`), que inclui:
    - Assinatura digital do Presidente.
    - QR Code de autenticação.
    - Metadados (Data, Localização, Dispositivo).
- [ ] **Assinatura do Funcionário:** Adicionar campo de linha para assinatura manual do empregado (Ciente), pois este documento será impresso e arquivado fisicamente.

### 2. Lógica de Estágio do Ciclo (Prioridade: Média)
O sistema não deve gerar o "Termo de Conclusão" (Anexo XII) para quem ainda está no meio do triênio.
- [ ] **Identificação do Estágio:** Implementar lógica para determinar em qual ano do triênio o funcionário está, baseado no `currentTrienniumStart` e no `Ano de Referência` selecionado.
    - **Ano 1:** Início do Ciclo.
    - **Ano 2:** Meio do Ciclo.
    - **Ano 3:** Fim do Ciclo (Elegível para Anexo XII).
- [ ] **Seleção Dinâmica de Documento:**
    - Se **Ano 1**: Gerar **Anexo X** (Termo Parcial - 1º Período).
    - Se **Ano 2**: Gerar **Anexo XI** (Termo Parcial - 2º Período).
    - Se **Ano 3**: Gerar **Anexo XII** (Termo de Conclusão Final).

### 3. Implementação dos Anexos Parciais (Prioridade: Média)
Criar os layouts para os documentos intermediários mencionados ("os outros dois anexos").
- [ ] **Criar Anexo X (Ano 1):** Layout simplificado focando na nota do primeiro ano e ciência parciais.
- [ ] **Criar Anexo XI (Ano 2):** Layout acumulando notas do Ano 1 e Ano 2.
- [ ] **Integração na Tela:** Ajustar o botão "Gerar Docs" para chamar a função correta (`generateAnexoX`, `generateAnexoXI` ou `generateAnexoXII`) dependendo do funcionário selecionado.

---

## Próximos Passos Imediatos
Recomendo começarmos pelo item **1. Adequação Visual Crítica do Anexo XII**. 
Como o código do `PdfService` já contém os componentes reutilizáveis (Headers, Assinaturas Digitais), essa é uma correção rápida que traz o documento para o nível profissional exigido ("wow factor") e resolve a insatisfação visual imediata.
