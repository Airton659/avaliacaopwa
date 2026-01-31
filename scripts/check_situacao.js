const admin = require('firebase-admin');

// Inicializar Firebase Admin
const serviceAccount = require('../firebase-key.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkSituacao() {
    console.log('🔍 Verificando valores de "situacao"...\n');

    const snapshot = await db.collection('funcionarios').limit(100).get();

    const situacoes = {};
    const examples = {};

    snapshot.forEach(doc => {
        const data = doc.data();
        const situacao = data.situacao || 'NULL';

        if (!situacoes[situacao]) {
            situacoes[situacao] = 0;
            examples[situacao] = [];
        }

        situacoes[situacao]++;

        if (examples[situacao].length < 3) {
            examples[situacao].push({
                chapa: doc.id,
                nome: data.nome
            });
        }
    });

    console.log('📊 Valores de "situacao" encontrados:\n');
    Object.keys(situacoes).sort((a, b) => situacoes[b] - situacoes[a]).forEach(sit => {
        console.log(`   "${sit}": ${situacoes[sit]} funcionários`);
        examples[sit].forEach(emp => {
            console.log(`      - ${emp.chapa} (${emp.nome})`);
        });
        console.log('');
    });
}

checkSituacao()
    .then(() => {
        console.log('\n✅ Verificação concluída!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Erro:', error);
        process.exit(1);
    });
