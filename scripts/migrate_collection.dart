#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Script para migrar colecciones específicas entre proyectos Firebase
/// Uso: dart scripts/migrate_collection.dart <collection_name>
/// Ejemplo: dart scripts/migrate_collection.dart homeScreenSections

void main(List<String> args) async {
  if (args.isEmpty) {
    print('❌ Error: Especifica el nombre de la colección');
    print('Uso: dart scripts/migrate_collection.dart <collection_name>');
    print('Ejemplo: dart scripts/migrate_collection.dart homeScreenSections');
    exit(1);
  }

  final collectionName = args[0];
  print('🔄 Iniciando migración de la colección: $collectionName');

  // Configuraciones de los proyectos
  const sourceProject = 'churchappbr';
  const targetProject = 'igreja-amor-em-movimento';

  try {
    // Paso 1: Exportar desde emulador o usar REST API
    await _exportCollection(sourceProject, collectionName);
    
    // Paso 2: Importar al proyecto destino
    await _importCollection(targetProject, collectionName);
    
    print('✅ ¡Migración completada exitosamente!');
    
  } catch (e) {
    print('❌ Error durante la migración: $e');
    exit(1);
  }
}

Future<void> _exportCollection(String projectId, String collectionName) async {
  print('📤 Exportando colección $collectionName del proyecto $projectId...');
  
  // Usar Firebase REST API para obtener los documentos
  final result = await Process.run('curl', [
    '-H', 'Authorization: Bearer \$(gcloud auth print-access-token)',
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionName'
  ]);
  
  if (result.exitCode != 0) {
    throw Exception('Error al exportar: ${result.stderr}');
  }
  
  // Guardar los datos en archivo temporal
  final file = File('temp_$collectionName.json');
  await file.writeAsString(result.stdout);
  
  print('📦 Datos exportados a temp_$collectionName.json');
}

Future<void> _importCollection(String projectId, String collectionName) async {
  print('📥 Importando colección $collectionName al proyecto $projectId...');
  
  final file = File('temp_$collectionName.json');
  if (!await file.exists()) {
    throw Exception('Archivo de datos no encontrado');
  }
  
  final data = await file.readAsString();
  final jsonData = jsonDecode(data);
  
  // Procesar cada documento
  if (jsonData['documents'] != null) {
    for (var doc in jsonData['documents']) {
      final docId = doc['name'].split('/').last;
      await _createDocument(projectId, collectionName, docId, doc['fields']);
    }
  }
  
  // Limpiar archivo temporal
  await file.delete();
  print('🗑️ Archivo temporal eliminado');
}

Future<void> _createDocument(String projectId, String collectionName, String docId, Map<String, dynamic> fields) async {
  print('📝 Creando documento: $docId');
  
  final result = await Process.run('curl', [
    '-X', 'PATCH',
    '-H', 'Authorization: Bearer \$(gcloud auth print-access-token)',
    '-H', 'Content-Type: application/json',
    '-d', jsonEncode({'fields': fields}),
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionName/$docId'
  ]);
  
  if (result.exitCode != 0) {
    print('⚠️ Error al crear documento $docId: ${result.stderr}');
  }
} 