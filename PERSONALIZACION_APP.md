# Personalización de la Aplicación

## Descripción

Esta funcionalidad permite al **superusuario** personalizar aspectos clave de la aplicación sin necesidad de modificar el código:

1. **Nombre de la Iglesia** - El texto que aparece en el encabezado del Home Screen
2. **Logo de la Iglesia** - La imagen del logo que aparece en toda la aplicación
3. **Color Principal** - El color primario de la aplicación (requiere reinicio)

## Acceso a la Funcionalidad

### Requisitos
- El usuario debe tener el campo `isSuperUser: true` en su documento de Firestore (`users/{userId}`)

### Ubicación
1. Ir a **Perfil**
2. Buscar la sección **Administración**
3. La primera opción será **Personalización de la App** (con ícono de paleta morada)

## Cómo Usar

### Cambiar el Nombre de la Iglesia
1. Escribir el nuevo nombre en el campo de texto
2. Presionar el ícono de guardar o el botón integrado
3. El cambio se verá reflejado inmediatamente en el Home Screen

### Cambiar el Logo
1. Presionar **Seleccionar Imagen**
2. Elegir una imagen de la galería (se redimensionará automáticamente a 1024x1024)
3. Presionar **Subir Logo**
4. El nuevo logo aparecerá inmediatamente en toda la aplicación

### Cambiar el Color Principal
1. Presionar **Cambiar Color**
2. Seleccionar un color del selector
3. Presionar **Aceptar**
4. Presionar **Guardar Color**
5. **Reiniciar la aplicación** para ver el cambio completo

## Estructura Técnica

### Firestore Collection
```
appConfig/
  └─ main_config/
      ├─ churchName: string
      ├─ logoUrl: string (Firebase Storage URL)
      ├─ primaryColor: int (Color value)
      ├─ createdAt: timestamp
      └─ updatedAt: timestamp
```

### Firebase Storage
Los logos se almacenan en:
```
gs://[tu-bucket]/app_config/church_logo_[timestamp].png
```

### Archivos Modificados

#### Servicios
- `lib/services/app_config_service.dart` - Servicio principal para gestionar la configuración

#### Pantallas
- `lib/screens/admin/app_customization_screen.dart` - Pantalla de personalización
- `lib/screens/profile_screen.dart` - Agregada opción en menú de administración
- `lib/screens/home_screen.dart` - Usa nombre dinámico

#### Widgets
- `lib/widgets/common/church_logo.dart` - Usa logo dinámico

#### Traducciones
- `lib/l10n/app_es.arb` - Claves en español
- `lib/l10n/app_pt.arb` - Claves en portugués

## Configuración Inicial

Para inicializar la configuración por defecto, el servicio tiene un método `initializeDefaultConfig()` que crea el documento con valores por defecto:
- churchName: "Amor Em Movimento"
- logoUrl: "" (vacío, usa logo por defecto)
- primaryColor: 0xFF1E6FF2 (azul)

## Notas Importantes

1. **Reinicio requerido para color**: Los cambios de color requieren reiniciar la app completamente para aplicarse en todos los componentes
2. **Eliminación automática**: Al subir un nuevo logo, el anterior se elimina automáticamente de Storage
3. **Fallback**: Si no hay configuración o falla la carga, la app usa valores por defecto
4. **Tiempo real**: Los cambios de nombre y logo se reflejan en tiempo real mediante StreamBuilder
5. **Optimización**: Se usa `CachedNetworkImage` para cachear el logo y mejorar performance

## Seguridad

- Solo usuarios con `isSuperUser: true` pueden acceder a esta funcionalidad
- Las reglas de Firestore deben configurarse adecuadamente para proteger la colección `appConfig`
- Se recomienda configurar reglas de Storage para que solo superusuarios puedan escribir en `app_config/`

## Ejemplo de Reglas de Firestore

```javascript
match /appConfig/{document=**} {
  allow read: if true; // Todos pueden leer la configuración
  allow write: if request.auth != null && 
               get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperUser == true;
}
```

## Ejemplo de Reglas de Storage

```javascript
match /app_config/{allPaths=**} {
  allow read: if true;
  allow write: if request.auth != null && 
               firestore.get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperUser == true;
}
```

