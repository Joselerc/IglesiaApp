# Igreja Amor em Movimento - Aplicativo Oficial

Una aplicación móvil completa desarrollada en Flutter para la Igreja Amor em Movimento, diseñada para conectar y fortalecer la comunidad de fe.

## 📱 Características Principales

### 🙏 Gestión de Oraciones
- **Oraciones Privadas**: Los usuarios pueden crear y gestionar sus oraciones personales
- **Oraciones Públicas**: Compartir peticiones de oración con la comunidad
- **Seguimiento de Oraciones**: Historial y estado de las peticiones

### 👥 Grupos y Ministerios
- **Grupos de Conexión**: Participar en grupos pequeños de estudio y fellowship
- **Ministerios**: Información sobre diferentes ministerios de la iglesia
- **Eventos de Grupos**: Calendario y actividades específicas

### 📅 Eventos y Cultos
- **Calendario de Eventos**: Programación completa de actividades
- **Cultos en Vivo**: Transmisión y grabaciones de servicios
- **Notificaciones**: Recordatorios automáticos de eventos importantes

### 🎓 Materiales de Estudio
- **Lecciones Bíblicas**: Contenido educativo y devocional
- **Editor de Texto Rico**: Creación y edición de contenido con flutter_quill
- **Materiales Multimedia**: Videos, audios y documentos

### 📊 Panel Administrativo
- **Gestión de Usuarios**: Administración de miembros y roles
- **Estadísticas**: Dashboards con métricas de participación
- **Gestión de Contenido**: Control total sobre eventos, lecciones y anuncios

### 🔔 Notificaciones Inteligentes
- **Push Notifications**: Alertas personalizadas y oportunas
- **Notificaciones por Categoría**: Eventos, oraciones, anuncios
- **Configuración Personalizada**: Control completo del usuario

## 🛠️ Tecnologías Utilizadas

### Frontend (Flutter)
- **Flutter 3.6+**: Framework principal de desarrollo
- **Dart**: Lenguaje de programación
- **firebase_core**: Integración con Firebase
- **flutter_bloc**: Gestión de estado con patrón BLoC
- **flutter_quill**: Editor de texto rico
- **cached_network_image**: Optimización de imágenes

### Backend (Firebase)
- **Firebase Authentication**: Sistema de autenticación
- **Cloud Firestore**: Base de datos NoSQL
- **Firebase Storage**: Almacenamiento de archivos
- **Cloud Functions**: Lógica del servidor
- **Firebase Messaging**: Notificaciones push
- **Firebase Performance**: Monitoreo de rendimiento

### Funcionalidades Avanzadas
- **QR Code**: Generación y lectura de códigos QR
- **Audio/Video**: Reproducción multimedia
- **PDF Generation**: Creación de documentos
- **Image Processing**: Manipulación y optimización de imágenes
- **Calendar Integration**: Integración con calendarios nativos

## 📋 Requisitos del Sistema

### Desarrollo
- Flutter SDK ≥ 3.6.1
- Dart SDK ≥ 3.6.1
- Android Studio / VS Code
- Git

### Dispositivos
- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **Web**: Navegadores modernos

## 🚀 Instalación y Configuración

### 1. Clonar el Repositorio
```bash
git clone https://github.com/Joselerc/church-app.git
cd igreja_amor_em_movimento
```

### 2. Instalar Dependencias
```bash
flutter pub get
```

### 3. Configuración de Firebase
1. Crear proyecto en [Firebase Console](https://console.firebase.google.com)
2. Descargar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
3. Configurar Firebase Authentication, Firestore, Storage y Messaging

### 4. Configurar Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 5. Ejecutar la Aplicación
```bash
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── constants/          # Constantes y configuraciones
├── cubits/            # Gestión de estado con BLoC
├── models/            # Modelos de datos
├── screens/           # Pantallas de la aplicación
│   ├── admin/         # Panel administrativo
│   ├── auth/          # Autenticación
│   ├── events/        # Eventos y cultos
│   ├── groups/        # Grupos y ministerios
│   ├── prayers/       # Gestión de oraciones
│   └── profile/       # Perfil de usuario
├── services/          # Servicios y APIs
├── widgets/           # Componentes reutilizables
├── utils/             # Utilidades y helpers
└── theme/             # Tema y estilos
```

## 🔧 Scripts Útiles

### Generación de Iconos
```bash
flutter pub run flutter_launcher_icons:main
```

### Build para Producción
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### Análisis de Código
```bash
flutter analyze
```

## 🧪 Testing

```bash
# Ejecutar todos los tests
flutter test

# Test con coverage
flutter test --coverage
```

## 📱 Características de la Aplicación

### Autenticación
- Login con email/password
- Registro de nuevos usuarios
- Recuperación de contraseña
- Verificación de email

### Perfiles de Usuario
- Información personal completa
- Foto de perfil
- Configuraciones de notificaciones
- Historial de actividades

### Sistema de Roles
- **Admin**: Control total del sistema
- **Líder**: Gestión de grupos y ministerios
- **Usuario**: Acceso básico a funcionalidades

## 🔒 Seguridad

- Autenticación robusta con Firebase Auth
- Reglas de seguridad en Firestore
- Validación de datos en cliente y servidor
- Encriptación de datos sensibles

## 📊 Monitoreo y Analytics

- Firebase Performance Monitoring
- Crashlytics para reporte de errores
- Analytics de uso y engagement
- Métricas de rendimiento

## 🤝 Contribución

1. Fork el proyecto
2. Crear una rama para la funcionalidad (`git checkout -b feature/nueva-funcionalidad`)
3. Commit los cambios (`git commit -m 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear un Pull Request

## 📄 Licencia

Este proyecto es propiedad de Igreja Amor em Movimento. Todos los derechos reservados.

## 📞 Soporte

Para soporte técnico o consultas sobre la aplicación:
- Email: soporte@igrejamoremovimento.com
- WhatsApp: +55 (11) 99999-9999

## 🔄 Changelog

### v1.0.0 (Actual)
- ✅ Sistema completo de autenticación
- ✅ Gestión de oraciones privadas y públicas
- ✅ Administración de grupos y ministerios
- ✅ Calendar de eventos integrado
- ✅ Panel administrativo completo
- ✅ Notificaciones push
- ✅ Editor de texto rico para materiales
- ✅ Sistema de roles y permisos

---

Desarrollado con ❤️ para la comunidad Igreja Amor em Movimento
