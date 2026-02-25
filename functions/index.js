const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Función genérica para enviar notificaciones push al crear un documento en la colección notifications
exports.sendGenericNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const toUserId = data.toUserId;
    const type = data.type || 'mensaje';
    const title = data.title ||
      (type === 'videollamada' ? 'Solicitud de videollamada' :
       type === 'chat' ? 'Nuevo mensaje de chat' :
       type === 'consulta' ? 'Nueva consulta' :
       'Notificación');
    const body = data.message ||
      (type === 'videollamada' ? 'Tienes una nueva solicitud de videollamada de un paciente.' :
       type === 'chat' ? 'Tienes un nuevo mensaje de chat.' :
       type === 'consulta' ? 'Tienes una nueva consulta.' :
       'Tienes una nueva notificación.');

    // Busca el token FCM del destinatario
    const userDoc = await admin.firestore().collection('users').doc(toUserId).get();
    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return null;

    const payload = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        notificationId: context.params.notificationId,
        type: type
      }
    };

    return admin.messaging().sendToDevice(fcmToken, payload);
  });
