const admin = require('firebase-admin');

// Inicializar Firebase Admin
const serviceAccount = require('../firebase-key.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function simulateCentralCiclos() {
    console.log('🔍 Simulando lógica da Central de Ciclos...\n');

    const currentCycleYear = 2026; // Do config/general
    console.log(`📅 Ciclo Atual: ${currentCycleYear}\n`);

    const snapshot = await db.collection('funcionarios').get();

    let total1 = 0;
    let total2 = 0;
    let total3 = 0;
    let totalExpired = 0;
    let totalNull = 0;
    let totalInactive = 0;

    const year3Examples = [];

    snapshot.forEach(doc => {
        const data = doc.data();

        // Filtro de situação
        if (data.situacao !== 'Ativo') {
            totalInactive++;
            return;
        }

        const start = data.currentTrienniumStart;
        if (!start) {
            totalNull++;
            return;
        }

        const delta = currentCycleYear - start;

        if (delta === 0) total1++;
        if (delta === 1) total2++;
        if (delta === 2) {
            total3++;
            if (year3Examples.length < 5) {
                year3Examples.push({
                    chapa: doc.id,
                    nome: data.nome,
                    situacao: data.situacao,
                    start: start,
                    delta: delta
                });
            }
        }
        if (delta > 2) totalExpired++;
    });

    console.log('📊 Contadores:');
    console.log(`   - Ano 1 (Início): ${total1}`);
    console.log(`   - Ano 2 (Meio): ${total2}`);
    console.log(`   - Ano 3 (Final): ${total3}`);
    console.log(`   - Renovação: ${totalExpired}`);
    console.log(`   - Sem triênio: ${totalNull}`);
    console.log(`   - Inativos (ignorados): ${totalInactive}`);

    if (year3Examples.length > 0) {
        console.log('\n📋 Exemplos de Ano 3:');
        year3Examples.forEach(emp => {
            console.log(`   - ${emp.chapa} (${emp.nome})`);
            console.log(`     situacao: "${emp.situacao}", start: ${emp.start}, delta: ${emp.delta}`);
        });
    }
}

simulateCentralCiclos()
    .then(() => {
        console.log('\n✅ Simulação concluída!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Erro:', error);
        process.exit(1);
    });
