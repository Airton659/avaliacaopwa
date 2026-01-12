const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function criarSuperAdmin() {
  try {
    const superAdminRef = db.collection('comissao').doc('03308');

    await superAdminRef.set({
      matricula: '03308',
      senha: '1234', // Senha padrão - pode ser alterada depois
      ativo: true,
      isSuperAdmin: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log('✅ Super Admin criado com sucesso!');
    console.log('Matrícula: 03308');
    console.log('Senha: 1234');
    console.log('');
    console.log('IMPORTANTE: Altere a senha após o primeiro login!');

    process.exit(0);
  } catch (error) {
    console.error('❌ Erro ao criar super admin:', error);
    process.exit(1);
  }
}

criarSuperAdmin();
