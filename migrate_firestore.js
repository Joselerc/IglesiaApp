const admin = require('firebase-admin');

// Configuración del proyecto fuente
const sourceConfig = {
  projectId: 'churchappbr',
  credential: admin.credential.applicationDefault()
};

// Configuración del proyecto destino
const targetConfig = {
  projectId: 'igreja-amor-em-movimento',  
  credential: admin.credential.applicationDefault()
};

async function migrateCollection(collectionName) {
  console.log(`🔄 Iniciando migración de la colección: ${collectionName}`);
  
  try {
    // Inicializar apps de Firebase
    const sourceApp = admin.initializeApp(sourceConfig, 'source');
    const targetApp = admin.initializeApp(targetConfig, 'target');
    
    const sourceDb = sourceApp.firestore();
    const targetDb = targetApp.firestore();
    
    console.log('✅ Conexiones Firebase establecidas');
    
    // Leer todos los documentos de la colección fuente
    console.log(`📖 Leyendo colección ${collectionName} del proyecto fuente...`);
    const sourceSnapshot = await sourceDb.collection(collectionName).get();
    
    if (sourceSnapshot.empty) {
      console.log(`⚠️  No se encontraron documentos en ${collectionName} del proyecto fuente`);
      return;
    }
    
    console.log(`📦 Encontrados ${sourceSnapshot.size} documentos`);
    
    // Migrar documentos en lotes
    const batch = targetDb.batch();
    
    sourceSnapshot.docs.forEach(doc => {
      const targetDocRef = targetDb.collection(collectionName).doc(doc.id);
      batch.set(targetDocRef, doc.data());
      console.log(`➕ Preparando migración del documento: ${doc.id}`);
    });
    
    // Ejecutar el lote
    console.log('💾 Escribiendo datos en el proyecto destino...');
    await batch.commit();
    
    console.log('✅ ¡Migración completada exitosamente!');
    console.log(`📊 Se migraron ${sourceSnapshot.size} documentos de ${collectionName}`);
    
  } catch (error) {
    console.error('❌ Error durante la migración:', error);
    process.exit(1);
  }
}

// Ejecutar script
if (require.main === module) {
  const collectionName = process.argv[2];
  
  if (!collectionName) {
    console.log('❌ Error: Especifica el nombre de la colección');
    console.log('Uso: node migrate_firestore.js <collection_name>');
    console.log('Ejemplo: node migrate_firestore.js homeScreenSections');
    process.exit(1);
  }
  
  migrateCollection(collectionName);
} 