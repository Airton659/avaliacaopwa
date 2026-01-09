// Script para popular as perguntas no Firestore
// Execute: node popular_perguntas.js

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-key.json'); // Você precisa baixar a chave do Firebase Console

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const perguntasOperacionais = [
  // I.1 - Discrição
  { ordem: 1, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.1 - Discrição', pergunta: 'comportamento discreto em suas relações de trabalho', ativo: true },
  { ordem: 2, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.1 - Discrição', pergunta: 'discrição em relação a fatos ocorridos no setor de trabalho', ativo: true },
  { ordem: 3, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.1 - Discrição', pergunta: 'atitude respeitosa em relação à chefia, a colegas e ao público', ativo: true },
  { ordem: 4, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.1 - Discrição', pergunta: 'guarda responsável de documentos e informações sigilosos', ativo: true },

  // I.2 - Assiduidade
  { ordem: 5, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.2 - Assiduidade', pergunta: 'assiduidade ao trabalho (frequência mínima de 95%)', ativo: true },
  { ordem: 6, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.2 - Assiduidade', pergunta: 'pontualidade no cumprimento de horários', ativo: true },
  { ordem: 7, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.2 - Assiduidade', pergunta: 'permanência regular no local de trabalho', ativo: true },
  { ordem: 8, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.2 - Assiduidade', pergunta: 'atenção no exercício das funções', ativo: true },

  // I.3 - Disciplina
  { ordem: 9, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.3 - Disciplina', pergunta: 'presteza no cumprimento de ordens', ativo: true },
  { ordem: 10, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.3 - Disciplina', pergunta: 'administração do tempo e cumprimento de prazos', ativo: true },
  { ordem: 11, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.3 - Disciplina', pergunta: 'uso adequado de equipamentos e instalações', ativo: true },
  { ordem: 12, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.3 - Disciplina', pergunta: 'adaptação a trabalhos em equipe', ativo: true },
  { ordem: 13, tipo: 'OPERACIONAL', secao: 'I - Fatores comportamentais', subsecao: 'I.3 - Disciplina', pergunta: 'comportamento equilibrado no ambiente de trabalho', ativo: true },

  // II - Fatores operacionais / Produtividade
  { ordem: 14, tipo: 'OPERACIONAL', secao: 'II - Fatores operacionais / Produtividade', subsecao: '', pergunta: 'qualidade e exatidão na execução de tarefas', ativo: true },
  { ordem: 15, tipo: 'OPERACIONAL', secao: 'II - Fatores operacionais / Produtividade', subsecao: '', pergunta: 'aptidão para as funções do Emprego Público', ativo: true },
  { ordem: 16, tipo: 'OPERACIONAL', secao: 'II - Fatores operacionais / Produtividade', subsecao: '', pergunta: 'iniciativa e comportamento produtivo', ativo: true },
  { ordem: 17, tipo: 'OPERACIONAL', secao: 'II - Fatores operacionais / Produtividade', subsecao: '', pergunta: 'aproveitamento/racionalização de recursos e processos de trabalho', ativo: true },
  { ordem: 18, tipo: 'OPERACIONAL', secao: 'II - Fatores operacionais / Produtividade', subsecao: '', pergunta: 'volume de produção no trabalho sob sua responsabilidade', ativo: true },
  { ordem: 19, tipo: 'OPERACIONAL', secao: 'II - Fatores operacionais / Produtividade', subsecao: '', pergunta: 'aproveitamento de oportunidades de capacitação', ativo: true },
  { ordem: 20, tipo: 'OPERACIONAL', secao: 'II - Fatores operacionais / Produtividade', subsecao: '', pergunta: 'capacidade para auxiliar outros empregados públicos', ativo: true },
];

const perguntasGerenciais = [
  // III.1 - Decisão
  { ordem: 1, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.1 - Decisão', pergunta: 'discernimento na análise de situações de trabalho', ativo: true },
  { ordem: 2, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.1 - Decisão', pergunta: 'prontidão e acerto na tomada de decisões', ativo: true },
  { ordem: 3, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.1 - Decisão', pergunta: 'equilíbrio frente a situações inesperadas', ativo: true },

  // III.2 - Liderança
  { ordem: 4, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.2 - Liderança', pergunta: 'segurança e independência nos relacionamentos de trabalho', ativo: true },
  { ordem: 5, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.2 - Liderança', pergunta: 'diálogo com superiores e subordinados, e delegação de responsabilidades', ativo: true },
  { ordem: 6, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.2 - Liderança', pergunta: 'colaboração e imparcialidade nas relações com superiores e/ou subordinados', ativo: true },
  { ordem: 7, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.2 - Liderança', pergunta: 'exercício de influência positiva sobre o grupo', ativo: true },

  // III.3 - Gestão
  { ordem: 8, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.3 - Gestão', pergunta: 'acompanhamento da execução de tarefas pelos empregados públicos sob sua chefia', ativo: true },
  { ordem: 9, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.3 - Gestão', pergunta: 'incentivo à produção e fornecimento de informação e orientação a seus subordinados', ativo: true },
  { ordem: 10, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.3 - Gestão', pergunta: 'acionamento de mecanismos da administração para capacitação profissional própria e de seus subordinados', ativo: true },
  { ordem: 11, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.3 - Gestão', pergunta: 'acionamento de procedimentos de segurança do trabalho', ativo: true },

  // III.4 - Planejamento do trabalho
  { ordem: 12, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.4 - Planejamento do trabalho', pergunta: 'organização de roteiros racionais e planejamento de tarefas de acordo com o fluxo das demandas', ativo: true },
  { ordem: 13, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.4 - Planejamento do trabalho', pergunta: 'análise de itinerários e procedimentos, por mensuração de espaço, distâncias e tempo de execução de tarefas', ativo: true },
  { ordem: 14, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.4 - Planejamento do trabalho', pergunta: 'estabelecimento de ritmo constante para realização de tarefas e consecução de resultados dentro das metas pré-estabelecidas', ativo: true },
  { ordem: 15, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.4 - Planejamento do trabalho', pergunta: 'exigência de ordem e higiene nos locais de trabalho', ativo: true },

  // III.5 - Conhecimento técnico das funções
  { ordem: 16, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.5 - Conhecimento técnico das funções', pergunta: 'domínio de conhecimentos na sua área de atuação', ativo: true },
  { ordem: 17, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.5 - Conhecimento técnico das funções', pergunta: 'conhecimento e visão global da estrutura e do funcionamento da organização', ativo: true },
  { ordem: 18, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.5 - Conhecimento técnico das funções', pergunta: 'habilidade no trato do público em geral', ativo: true },
  { ordem: 19, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.5 - Conhecimento técnico das funções', pergunta: 'interpretação e cumprimento de normas e regulamentos', ativo: true },
  { ordem: 20, tipo: 'GERENCIAL', secao: 'III - Fatores gerenciais da tarefa', subsecao: 'III.5 - Conhecimento técnico das funções', pergunta: 'observância de prioridades e do interesse público em relação ao trabalho sob sua responsabilidade', ativo: true },
];

async function popularPerguntas() {
  console.log('Iniciando população de perguntas...');

  const batch = db.batch();

  // Adicionar perguntas operacionais
  perguntasOperacionais.forEach((pergunta, index) => {
    const docRef = db.collection('questions').doc(`OP_${index + 1}`);
    batch.set(docRef, pergunta);
  });

  // Adicionar perguntas gerenciais
  perguntasGerenciais.forEach((pergunta, index) => {
    const docRef = db.collection('questions').doc(`GER_${index + 1}`);
    batch.set(docRef, pergunta);
  });

  await batch.commit();

  console.log('✅ Perguntas populadas com sucesso!');
  console.log(`   - ${perguntasOperacionais.length} perguntas operacionais`);
  console.log(`   - ${perguntasGerenciais.length} perguntas gerenciais`);

  process.exit(0);
}

popularPerguntas().catch(console.error);
