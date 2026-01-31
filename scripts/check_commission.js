const admin = require('firebase-admin');

// Inicializar Firebase Admin
const serviceAccount = require('../firebase-key.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkCommission() {
    console.log('🔍 Verificando dados da comissão...\n');

    const commissionDoc = await db.collection('comissao').doc('config').get();

    if (!commissionDoc.exists) {
        console.log('❌ Documento de comissão não encontrado!');
        return;
    }

    const data = commissionDoc.data();
    console.log('📄 Configuração da Comissão:');
    console.log(`   - currentCycle: ${data.currentCycle || 'N/A'}`);
    console.log(`   - Outros campos:`, JSON.stringify(data, null, 2));
}

checkCommission()
    .then(() => {
        console.log('\n✅ Verificação concluída!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Erro:', error);
        process.exit(1);
    });
