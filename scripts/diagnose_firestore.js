const admin = require('firebase-admin');

// Inicializar Firebase Admin
const serviceAccount = require('../firebase-key.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function diagnose() {
    console.log('🔍 Diagnóstico da estrutura de funcionários...\n');

    // Buscar primeiros 10 funcionários
    const snapshot = await db.collection('funcionarios').limit(10).get();

    console.log(`📊 Total de funcionários: ${snapshot.size}\n`);
    console.log('Primeiros 10 registros:\n');

    snapshot.forEach(doc => {
        const data = doc.data();
        console.log(`📄 Document ID: "${doc.id}"`);
        console.log(`   - chapa: "${data.chapa || 'N/A'}"`);
        console.log(`   - id: "${data.id || 'N/A'}"`);
        console.log(`   - nome: "${data.nome || 'N/A'}"`);
        console.log(`   - funcao: "${data.funcao || 'N/A'}"`);
        console.log('');
    });

    // Buscar especificamente por uma CHAPA do CSV
    console.log('\n🔎 Testando busca por CHAPA "2711" (primeira do CSV):\n');

    // Tentar como doc ID
    const byId = await db.collection('funcionarios').doc('2711').get();
    console.log(`   Como Document ID: ${byId.exists ? '✅ ENCONTRADO' : '❌ NÃO ENCONTRADO'}`);

    // Tentar como campo
    const byField = await db.collection('funcionarios').where('chapa', '==', '2711').get();
    console.log(`   Como campo 'chapa': ${byField.size > 0 ? `✅ ENCONTRADO (${byField.size} docs)` : '❌ NÃO ENCONTRADO'}`);

    if (byField.size > 0) {
        byField.forEach(doc => {
            console.log(`      → Document ID: "${doc.id}"`);
        });
    }
}

diagnose()
    .then(() => {
        console.log('\n✅ Diagnóstico concluído!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Erro:', error);
        process.exit(1);
    });
