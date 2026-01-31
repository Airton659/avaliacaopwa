const admin = require('firebase-admin');

// Inicializar Firebase Admin
const serviceAccount = require('../firebase-key.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkEvaluations() {
    console.log('🔍 Verificando avaliações importadas...\n');

    // Buscar primeiras 5 avaliações
    const snapshot = await db.collection('evaluations')
        .where('obs', '==', 'Importado via CSV (Histórico)')
        .limit(5)
        .get();

    console.log(`📊 Total encontrado: ${snapshot.size}\n`);

    snapshot.forEach(doc => {
        const data = doc.data();
        console.log(`📄 Document ID: "${doc.id}"`);
        console.log(`   Campos salvos:`);
        Object.keys(data).forEach(key => {
            const value = data[key];
            const display = typeof value === 'object' ? JSON.stringify(value).substring(0, 50) : value;
            console.log(`   - ${key}: ${display}`);
        });
        console.log('');
    });
}

checkEvaluations()
    .then(() => {
        console.log('\n✅ Verificação concluída!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Erro:', error);
        process.exit(1);
    });
