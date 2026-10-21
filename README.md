# Biblioteca Personal

Aplicación Flutter Web para guardar libros con título, autor, género, descripción y portada. Usa Firebase Authentication para el registro e inicio de sesión, Cloud Firestore para crear, consultar, editar y eliminar libros, y Cloudinary para subir y mostrar las portadas.

## Preparar las cuentas

1. Instala Flutter con Dart 3.11 o posterior y habilita el destino Web (`flutter doctor`).
2. En [Firebase Console](https://console.firebase.google.com/), crea un proyecto. Agrega una aplicación **Web** y copia los valores de su configuración: `apiKey`, `appId`, `messagingSenderId` y `projectId`. Copia `authDomain` si aparece; en proyectos nuevos puede estar ausente.
3. En **Authentication > Sign-in method**, habilita **Correo electrónico/Contraseña**. Esta app usa el acceso directo con contraseña; los dominios autorizados se configuran si más adelante usas vínculos de correo o proveedores OAuth.
4. Crea una base de **Cloud Firestore**. En la pestaña **Rules**, reemplaza las reglas con el contenido de `firestore.rules` y publícalas. La app guarda los documentos en `users/{uid}/books/{bookId}`.
5. En [Cloudinary](https://cloudinary.com/), crea una cuenta, copia el **Cloud name** y crea un **upload preset unsigned** en **Settings > Upload > Upload presets**. Para esta práctica conviene limitar los formatos del preset a JPG, PNG y WebP y usar una carpeta específica. La app valida que cada archivo pese 10 MB o menos; Cloudinary no ofrece un límite de tamaño por preset.

## Configurar y ejecutar

En esta carpeta:

```powershell
Copy-Item config.example.json config.local.json
```

Completa `config.local.json` con los datos públicos de Firebase y el cloud name y preset de Cloudinary:

| Clave local | Campo del servicio |
| --- | --- |
| `FIREBASE_API_KEY` | `apiKey` de la aplicación Web |
| `FIREBASE_APP_ID` | `appId` |
| `FIREBASE_MESSAGING_SENDER_ID` | `messagingSenderId` |
| `FIREBASE_PROJECT_ID` | `projectId` |
| `FIREBASE_AUTH_DOMAIN` | `authDomain`, si aparece; en otro caso déjalo vacío |
| `CLOUDINARY_CLOUD_NAME` | Cloud name |
| `CLOUDINARY_UPLOAD_PRESET` | Nombre del preset unsigned |

Luego ejecuta:

```powershell
flutter pub get
flutter analyze
flutter run -d chrome --dart-define-from-file=config.local.json
```

Para abrir la versión compilada en esta computadora, ejecuta `Iniciar_Biblioteca.cmd`. Usa Python 3.13 para servir `build/web` únicamente en la computadora local y abre el navegador. Mantén la terminal abierta mientras usas la app. Este arranque no vuelve a compilar con Flutter. Si cambias código o configuración, actualiza primero la compilación con `flutter build web --dart-define-from-file=config.local.json`. La instalación beta de Flutter sigue presentando errores internos de compilación en la terminal del usuario; el servidor local permite usar la versión compilada sin depender de esa compilación en cada arranque.

Los archivos de plataforma Web ya están incluidos. La app muestra una pantalla de configuración si faltan valores. **No incluyas API Secret de Cloudinary, contraseñas ni claves privadas** en el proyecto. `config.local.json` está excluido de Git.

## Comprobación funcional

1. Registra un usuario y comprueba que aparece en Firebase Authentication.
2. Crea un libro con portada. Comprueba que se ve en la lista, que el documento incluye `ownerUid` e `imageUrl` en Firestore, y que el asset aparece en Cloudinary.
3. Cambia el título o género y verifica el cambio en la app y en Firestore.
4. Elimina el libro y verifica que desaparece de Firestore.
5. Cierra sesión y verifica que ya no se ve la colección. Inicia sesión de nuevo.
6. Prueba guardar un formulario vacío y verifica el mensaje de validación.

La eliminación del registro quita el documento de Firestore. El archivo subido permanece en Cloudinary, ya que una app cliente con preset unsigned no debe incluir el API Secret necesario para borrarlo. Puedes retirarlo manualmente de Cloudinary después de la demostración.

## Entrega

- Completa `Integrantes.txt` con tu nombre completo.
- Completa `Evidencias_Biblioteca_Personal.docx` con capturas reales de tu ejecución y las consolas. Cada captura ya tiene un título y una explicación guía; ajusta la explicación a lo que efectivamente hiciste.
- Graba un video MP4 de 6 a 10 minutos siguiendo `Guion_video.md`. Muestra registro o inicio, alta, consulta, edición, eliminación, imagen y cierre de sesión.
- Si te piden código principal, entrega los `.dart` de `lib/` o un enlace al repositorio, sin `config.local.json`.

## Fuentes técnicas

- [Configurar Firebase para Flutter](https://firebase.google.com/docs/flutter/setup)
- [Cloudinary Upload API](https://cloudinary.com/documentation/image_upload_api_reference)
- [Subida de imágenes en Flutter con Cloudinary](https://cloudinary.com/documentation/flutter_image_and_video_upload)
