const admin = require('firebase-admin');

// Inicializar Firebase Admin
const serviceAccount = require('../firebase-key.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkConfig() {
    console.log('🔍 Procurando configurações...\n');

    // Tentar config/general
    const configGeneral = await db.collection('config').doc('general').get();
    console.log(`📄 config/general: ${configGeneral.exists ? '✅ EXISTE' : '❌ NÃO EXISTE'}`);
    if (configGeneral.exists) {
        console.log('   Dados:', JSON.stringify(configGeneral.data(), null, 2));
    }

    // Tentar comissao/config
    const comissaoConfig = await db.collection('comissao').doc('config').get();
    console.log(`📄 comissao/config: ${comissaoConfig.exists ? '✅ EXISTE' : '❌ NÃO EXISTE'}`);
    if (comissaoConfig.exists) {
        console.log('   Dados:', JSON.stringify(comissaoConfig.data(), null, 2));
    }

    // Listar todas as coleções
    console.log('\n📚 Coleções disponíveis:');
    const collections = await db.listCollections();
    collections.forEach(col => {
        console.log(`   - ${col.id}`);
    });

    // Se não existe, criar
    if (!configGeneral.exists) {
        console.log('\n🔧 Criando config/general com currentCycle = 2026...');
        await db.collection('config').doc('general').set({
            currentCycle: '2026',
            createdAt: new Date().toISOString(),
            createdBy: 'import_script'
        });
        console.log('✅ Criado!');
    }
}

checkConfig()
    .then(() => {
        console.log('\n✅ Verificação concluída!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Erro:', error);
        process.exit(1);
    });
