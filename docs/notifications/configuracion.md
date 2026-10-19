# Notificaciones de reserva

## Servicios utilizados

- Firebase Cloud Messaging para notificaciones push.
- Cloud Functions para reaccionar a la creación y finalización de reservas.
- SendGrid para correo; la clave se guarda como secreto de Firebase y nunca en Flutter.

## Configuración requerida antes del despliegue

1. Verificar una dirección remitente en SendGrid y definir el secreto:

   ```powershell
   firebase functions:secrets:set SENDGRID_API_KEY --project coach-app-govarohub
   ```

2. Crear `functions/.env.coach-app-govarohub` a partir de `functions/.env.example`
   y asignar `SENDGRID_FROM_EMAIL` a la dirección verificada.
3. En Firebase Console, generar una clave Web Push (VAPID). Para ejecutar Flutter
   Web, pasarla mediante `--dart-define=FCM_WEB_VAPID_KEY=<clave-publica>`.
4. Para iOS, habilitar Push Notifications y cargar la clave APNs en Firebase
   Console. Android solicita el permiso de notificaciones en tiempo de ejecución.
5. Instalar las dependencias del backend y desplegar reglas y funciones:

   ```powershell
   npm --prefix functions install
   firebase deploy --only firestore:rules,functions --project coach-app-govarohub
   ```

## Eventos

- Al crearse una reserva `pending`, el cliente recibe push y correo con el coach,
  fecha y horario.
- Al cambiar una reserva a `completed`, el cliente recibe push y correo indicando
  que ya puede calificar y reseñar.
- Los mensajes push llevan `reservationId`; al abrirlos, la app navega a
  “Mis reservaciones”.