const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Inicializar Firebase Admin
const serviceAccount = require('../firebase-key.json');
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Configurações
const CSV_PATH = path.join(__dirname, '..', '23-24-25.csv');
const TRIENNIUM_START_YEAR = 2026; // Iniciando ciclo este ano

async function importCSV2() {
    console.log('🔥 Iniciando importação do segundo CSV (23-24-25)...\n');

    // Ler arquivo CSV
    const csvContent = fs.readFileSync(CSV_PATH, 'latin1');
    const lines = csvContent.split('\n').filter(line => line.trim());

    if (lines.length === 0) {
        console.error('❌ Arquivo CSV vazio!');
        return;
    }

    // Parse header
    const header = lines[0].toUpperCase().split(';');
    const chapaIdx = header.indexOf('CHAPA');
    const nota23Idx = header.findIndex(h => h.includes('2023') || h.includes('NOTA_2023'));
    const nota24Idx = header.findIndex(h => h.includes('2024') || h.includes('NOTA_2024'));
    const nota25Idx = header.findIndex(h => h.includes('2025') || h.includes('NOTA_2025'));

    if (chapaIdx === -1) {
        console.error('❌ Coluna CHAPA não encontrada no CSV!');
        return;
    }

    console.log(`📋 Colunas detectadas:`);
    console.log(`   - CHAPA: índice ${chapaIdx}`);
    console.log(`   - NOTA_2023: índice ${nota23Idx}`);
    console.log(`   - NOTA_2024: índice ${nota24Idx}`);
    console.log(`   - NOTA_2025: índice ${nota25Idx}\n`);

    // Buscar todos os funcionários válidos
    const employeesSnapshot = await db.collection('funcionarios').get();
    const employeeMap = {};
    employeesSnapshot.forEach(doc => {
        employeeMap[doc.id] = doc.data();
    });

    console.log(`👥 ${Object.keys(employeeMap).length} funcionários encontrados no Firebase\n`);

    // Processar linhas
    let processedCount = 0;
    let skippedCount = 0;
    const batch = db.batch();
    let batchCount = 0;

    for (let i = 1; i < lines.length; i++) {
        const row = lines[i].split(';');
        if (row.length <= chapaIdx) continue;

        // Normalizar CHAPA: adicionar zeros à esquerda para 5 dígitos
        let chapa = row[chapaIdx].trim();
        if (!chapa) continue;

        chapa = chapa.padStart(5, '0');

        if (!employeeMap[chapa]) {
            console.log(`⚠️  Linha ${i + 1}: CHAPA "${chapa}" não encontrada no Firebase - ignorando`);
            skippedCount++;
            continue;
        }

        const empData = employeeMap[chapa];

        // 1. Atualizar currentTrienniumStart do funcionário
        const empRef = db.collection('funcionarios').doc(chapa);
        batch.update(empRef, { currentTrienniumStart: TRIENNIUM_START_YEAR });

        // 2. Processar NOTA_2023
        if (nota23Idx !== -1 && row.length > nota23Idx) {
            const val = row[nota23Idx].trim();
            if (val) {
                addEvaluationToBatch(batch, chapa, 2023, val, empData);
            }
        }

        // 3. Processar NOTA_2024
        if (nota24Idx !== -1 && row.length > nota24Idx) {
            const val = row[nota24Idx].trim();
            if (val) {
                addEvaluationToBatch(batch, chapa, 2024, val, empData);
            }
        }

        // 4. Processar NOTA_2025
        if (nota25Idx !== -1 && row.length > nota25Idx) {
            const val = row[nota25Idx].trim();
            if (val) {
                addEvaluationToBatch(batch, chapa, 2025, val, empData);
            }
        }

        processedCount++;
        batchCount++;

        // Commit batch a cada 400 operações
        if (batchCount >= 400) {
            console.log(`💾 Salvando batch de ${batchCount} operações...`);
            await batch.commit();
            batchCount = 0;
        }
    }

    // Commit final
    if (batchCount > 0) {
        console.log(`💾 Salvando batch final de ${batchCount} operações...`);
        await batch.commit();
    }

    console.log('\n✅ Importação concluída!');
    console.log(`   - ${processedCount} funcionários processados`);
    console.log(`   - ${skippedCount} linhas ignoradas (CHAPA não encontrada)`);
}

function addEvaluationToBatch(batch, chapa, year, rawValue, empData) {
    const employeeSnapshot = {
        id: empData.id || empData.chapa || chapa,
        nome: empData.nome || '',
        funcao: empData.funcao || ''
    };

    const docId = `${year}_${chapa}_FINAL_OPERACIONAL`;
    const ref = db.collection('evaluations').doc(docId);

    let manualScore = null;
    let specialStatus = null;

    // Parse: tentar converter para número
    const cleanVal = rawValue.replace(',', '.');
    const score = parseFloat(cleanVal);

    if (!isNaN(score)) {
        manualScore = score;
    } else {
        specialStatus = rawValue; // "LSV", etc.
    }

    const evaluation = {
        id: docId,
        year: year,
        type: 'FINAL_OPERACIONAL',
        answers: {},
        employeeSnapshot: employeeSnapshot,
        manualScore: manualScore,
        specialStatus: specialStatus,
        obs: 'Importado via CSV (Histórico 23-24-25)',
        createdAt: new Date().toISOString()
    };

    batch.set(ref, evaluation, { merge: true });

    const displayValue = manualScore !== null ? `nota ${manualScore}` : `status "${specialStatus}"`;
    console.log(`   ✓ ${chapa} - ${year}: ${displayValue}`);
}

// Executar
importCSV2()
    .then(() => {
        console.log('\n🎉 Script finalizado com sucesso!');
        process.exit(0);
    })
    .catch(error => {
        console.error('\n❌ Erro durante importação:', error);
        process.exit(1);
    });
