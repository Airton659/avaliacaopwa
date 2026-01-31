const admin = require('firebase-admin');

// Inicializar Firebase Admin
const serviceAccount = require('../firebase-key.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkTrienniumData() {
    console.log('🔍 Verificando dados de triênio...\n');

    // Buscar funcionários com currentTrienniumStart
    const withTriennium = await db.collection('funcionarios')
        .where('currentTrienniumStart', '!=', null)
        .limit(10)
        .get();

    console.log(`📊 Funcionários com currentTrienniumStart: ${withTriennium.size}\n`);

    withTriennium.forEach(doc => {
        const data = doc.data();
        console.log(`📄 CHAPA: ${doc.id}`);
        console.log(`   - currentTrienniumStart: ${data.currentTrienniumStart}`);
        console.log(`   - nome: ${data.nome}`);
        console.log('');
    });

    // Contar total
    const allEmployees = await db.collection('funcionarios').get();
    let countWithTriennium = 0;
    let countWithout = 0;

    allEmployees.forEach(doc => {
        const data = doc.data();
        if (data.currentTrienniumStart) {
            countWithTriennium++;
        } else {
            countWithout++;
        }
    });

    console.log(`\n📈 Resumo:`);
    console.log(`   - Total de funcionários: ${allEmployees.size}`);
    console.log(`   - Com currentTrienniumStart: ${countWithTriennium}`);
    console.log(`   - Sem currentTrienniumStart: ${countWithout}`);
}

checkTrienniumData()
    .then(() => {
        console.log('\n✅ Verificação concluída!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Erro:', error);
        process.exit(1);
    });
