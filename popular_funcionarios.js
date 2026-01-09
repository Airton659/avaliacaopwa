// Script para popular funcionários de teste no Firestore
// Execute: node popular_funcionarios.js

const admin = require('firebase-admin');
const serviceAccount = require('./firebase-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const funcionarios = [
  {
    chapa: '001',
    nome: 'João da Silva',
    data_admissao: '15/03/2018',
    funcao: 'Auxiliar Administrativo',
    nivel: 'I',
    nomenivel: 'Nível I',
    grau: 'A',
    nomefaixa: 'Faixa A',
    escolaridade: 'Ensino Médio Completo',
    isManager: false,
    active: true,
  },
  {
    chapa: '002',
    nome: 'Maria Santos',
    data_admissao: '20/06/2019',
    funcao: 'Assistente Financeiro',
    nivel: 'II',
    nomenivel: 'Nível II',
    grau: 'B',
    nomefaixa: 'Faixa B',
    escolaridade: 'Superior Completo - Ciências Contábeis',
    isManager: false,
    active: true,
  },
  {
    chapa: '003',
    nome: 'Pedro Oliveira',
    data_admissao: '10/01/2020',
    funcao: 'Analista de RH',
    nivel: 'III',
    nomenivel: 'Nível III',
    grau: 'C',
    nomefaixa: 'Faixa C',
    escolaridade: 'Superior Completo - Psicologia',
    isManager: false,
    active: true,
  },
  {
    chapa: '004',
    nome: 'Ana Costa',
    data_admissao: '05/09/2015',
    funcao: 'Gerente de Projetos',
    nivel: 'IV',
    nomenivel: 'Nível IV',
    grau: 'D',
    nomefaixa: 'Faixa D',
    escolaridade: 'Pós-Graduação - MBA em Gestão de Projetos',
    isManager: true,
    active: true,
  },
  {
    chapa: '005',
    nome: 'Carlos Souza',
    data_admissao: '12/02/2012',
    funcao: 'Diretor Administrativo',
    nivel: 'V',
    nomenivel: 'Nível V',
    grau: 'E',
    nomefaixa: 'Faixa E',
    escolaridade: 'Mestrado em Administração Pública',
    isManager: true,
    active: true,
  },
  {
    chapa: '006',
    nome: 'Juliana Mendes',
    data_admissao: '08/11/2016',
    funcao: 'Coordenadora de TI',
    nivel: 'IV',
    nomenivel: 'Nível IV',
    grau: 'D',
    nomefaixa: 'Faixa D',
    escolaridade: 'Superior Completo - Sistemas de Informação',
    isManager: true,
    active: true,
  },
  {
    chapa: '007',
    nome: 'Roberto Lima',
    data_admissao: '25/04/2021',
    funcao: 'Técnico em Informática',
    nivel: 'II',
    nomenivel: 'Nível II',
    grau: 'B',
    nomefaixa: 'Faixa B',
    escolaridade: 'Técnico em Informática',
    isManager: false,
    active: true,
  },
  {
    chapa: '008',
    nome: 'Fernanda Alves',
    data_admissao: '18/07/2020',
    funcao: 'Secretária Executiva',
    nivel: 'II',
    nomenivel: 'Nível II',
    grau: 'A',
    nomefaixa: 'Faixa A',
    escolaridade: 'Superior Cursando - Administração',
    isManager: false,
    active: true,
  },
];

async function popularFuncionarios() {
  console.log('Iniciando população de funcionários...');

  const batch = db.batch();

  funcionarios.forEach((func) => {
    const docRef = db.collection('employees').doc(func.chapa);
    batch.set(docRef, func);
  });

  await batch.commit();

  console.log('✅ Funcionários populados com sucesso!');
  console.log(`   - ${funcionarios.length} funcionários criados`);
  console.log('\nFuncionários:');
  funcionarios.forEach(f => {
    console.log(`   - ${f.chapa}: ${f.nome} (${f.funcao})${f.isManager ? ' - GESTOR' : ''}`);
  });

  process.exit(0);
}

popularFuncionarios().catch(console.error);
