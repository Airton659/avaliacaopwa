const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const serviceAccount = require('../firebase-key.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const CSV_PATH = path.join(__dirname, '..', '25-26-27.csv');
const TRIENNIUM_START_YEAR = 2025;

async function importCSV() {
  console.log('🔥 Iniciando importação CSV (25-26-27)...\n');
  const csvContent = fs.readFileSync(CSV_PATH, 'latin1');
  const lines = csvContent.split('\n').filter(line => line.trim());
  if (lines.length === 0) { console.error('❌ Arquivo CSV vazio!'); return; }

  const header = lines[0].toUpperCase().split(';');
  const chapaIdx = header.indexOf('CHAPA');
  const nota25Idx = header.findIndex(h => h.includes('2025') || h.includes('NOTA'));
  if (chapaIdx === -1) { console.error('❌ Coluna CHAPA não encontrada!'); return; }

  console.log('📋 CHAPA:', chapaIdx, 'NOTA_2025:', nota25Idx, '\n');

  const employeesSnapshot = await db.collection('funcionarios').get();
  const employeeMap = {};
  employeesSnapshot.forEach(doc => { employeeMap[doc.id] = doc.data(); });
  console.log('👥', Object.keys(employeeMap).length, 'funcionários\n');

  let processedCount = 0, skippedCount = 0, batch = db.batch(), batchCount = 0;

  for (let i = 1; i < lines.length; i++) {
    const row = lines[i].split(';');
    if (row.length <= chapaIdx) continue;
    let chapa = row[chapaIdx].trim();
    if (!chapa) continue;
    chapa = chapa.padStart(5, '0');
    if (!employeeMap[chapa]) { console.log('⚠️ ', chapa, 'não encontrado'); skippedCount++; continue; }

    const empRef = db.collection('funcionarios').doc(chapa);
    batch.update(empRef, { currentTrienniumStart: TRIENNIUM_START_YEAR });

    if (nota25Idx !== -1 && row.length > nota25Idx) {
      const val = row[nota25Idx].trim();
      if (val) {
        const empData = employeeMap[chapa];
        const docId = '2025_' + chapa + '_FINAL_OPERACIONAL';
        const ref = db.collection('evaluations').doc(docId);
        const cleanVal = val.replace(',', '.');
        const score = parseFloat(cleanVal);
        const evaluation = {
          id: docId, year: 2025, type: 'FINAL_OPERACIONAL', answers: {},
          employeeSnapshot: { id: empData.id || chapa, nome: empData.nome || '', funcao: empData.funcao || '' },
          manualScore: !isNaN(score) ? score : null,
          specialStatus: isNaN(score) ? val : null,
          obs: 'Importado via CSV (25-26-27)',
          createdAt: new Date().toISOString()
        };
        batch.set(ref, evaluation, { merge: true });
        console.log('   ✓', chapa, '- 2025:', !isNaN(score) ? 'nota ' + score : 'status "' + val + '"');
      }
    }

    processedCount++; batchCount++;
    if (batchCount >= 400) {
      console.log('💾 Salvando batch...');
      await batch.commit();
      batch = db.batch();
      batchCount = 0;
    }
  }

  if (batchCount > 0) { console.log('💾 Salvando batch final...'); await batch.commit(); }
  console.log('\n✅', processedCount, 'processados,', skippedCount, 'ignorados\n🎉 Concluído!');
}

importCSV().then(() => process.exit(0)).catch(err => { console.error('\n❌ Erro:', err); process.exit(1); });
