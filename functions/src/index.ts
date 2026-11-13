import sgMail from '@sendgrid/mail';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp, type DocumentData } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { defineSecret, defineString } from 'firebase-functions/params';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as logger from 'firebase-functions/logger';

initializeApp();

const firestore = getFirestore();
const sendGridApiKey = defineSecret('SENDGRID_API_KEY');
const sendGridFromEmail = defineString('SENDGRID_FROM_EMAIL');

interface ReservationData extends DocumentData {
  clientId?: unknown;
  coachId?: unknown;
  scheduleId?: unknown;
  status?: unknown;
}

function asString(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

async function getSessionDescription(
  scheduleId: string | null,
  coachId: string | null,
): Promise<{ coachName: string; sessionDescription: string }> {
  let coachName = 'tu coach';
  let sessionDescription = 'la sesión reservada';

  if (coachId) {
    const coachSnapshot = await firestore.collection('users').doc(coachId).get();
    const coachData = coachSnapshot.data();
    coachName =
      asString(coachData?.name) ??
      asString(coachData?.displayName) ??
      coachName;
  }

  if (scheduleId) {
    const scheduleSnapshot = await firestore
      .collection('schedules')
      .doc(scheduleId)
      .get();
    const schedule = scheduleSnapshot.data();
    if (schedule) {
      const scheduleDate = schedule.date;
      const dateText = scheduleDate instanceof Timestamp
        ? scheduleDate.toDate().toLocaleDateString('es-MX')
        : null;
      const startTime = asString(schedule.startTime);
      const endTime = asString(schedule.endTime);
      const timeText = startTime && endTime
        ? `, ${startTime} - ${endTime}`
        : '';
      if (dateText) {
        sessionDescription = `la sesión del ${dateText}${timeText}`;
      }
    }
  }

  return { coachName, sessionDescription };
}

async function notifyClient({
  clientId,
  reservationId,
  title,
  body,
  type,
}: {
  clientId: string;
  reservationId: string;
  title: string;
  body: string;
  type: 'reservation_created' | 'reservation_confirmed' | 'session_completed';
}): Promise<void> {
  const clientSnapshot = await firestore.collection('users').doc(clientId).get();
  const clientEmail = asString(clientSnapshot.data()?.email);

  await sendPushNotification({
    uid: clientId,
    reservationId,
    title,
    body,
    type,
    audience: 'client',
  });

  if (!clientEmail) {
    logger.warn('El cliente no tiene correo en users/{uid}.', {
      clientId,
      reservationId,
    });
    return;
  }

  sgMail.setApiKey(sendGridApiKey.value());
  await sgMail.send({
    to: clientEmail,
    from: sendGridFromEmail.value(),
    subject: title,
    text: body,
  });
}

async function sendPushNotification({
  uid,
  reservationId,
  title,
  body,
  type,
  audience,
}: {
  uid: string;
  reservationId: string;
  title: string;
  body: string;
  type: string;
  audience: 'client' | 'coach';
}): Promise<boolean> {
  let tokenSnapshot;
  try {
    tokenSnapshot = await firestore
      .collection('fcmTokens')
      .where('uid', '==', uid)
      .get();
  } catch (error) {
    logger.error('No fue posible consultar los tokens push.', {
      uid,
      reservationId,
      audience,
      error,
    });
    return false;
  }
  const tokenDocuments = tokenSnapshot.docs.filter(
    (document) => asString(document.data().token) !== null,
  );

  if (tokenDocuments.length === 0) {
    logger.warn('No hay tokens push registrados para el usuario.', {
      uid,
      reservationId,
      audience,
    });
    return false;
  }

  let delivered = false;
  for (let index = 0; index < tokenDocuments.length; index += 500) {
    const batch = tokenDocuments.slice(index, index + 500);
    const tokens = batch.map((document) => document.data().token as string);
    try {
      const response = await getMessaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data: {
          type,
          reservationId,
          audience,
          route: audience === 'coach' ? '/coach/agenda' : '/reservations',
        },
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      delivered = delivered || response.successCount > 0;

      const batchWrite = firestore.batch();
      let invalidTokenCount = 0;
      response.responses.forEach((result, tokenIndex) => {
        const code = result.error?.code;
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token'
        ) {
          batchWrite.delete(batch[tokenIndex].ref);
          invalidTokenCount++;
        }
      });
      if (invalidTokenCount > 0) {
        await batchWrite.commit();
      }
    } catch (error) {
      logger.error('No fue posible enviar la notificación push.', {
        reservationId,
        uid,
        error,
      });
    }
  }
  return delivered;
}

export const notifyClientWhenReservationCreated = onDocumentCreated(
  {
    document: 'reservations/{reservationId}',
    region: 'us-central1',
    secrets: [sendGridApiKey],
  },
  async (event) => {
    const reservation = event.data?.data() as ReservationData | undefined;
    if (!reservation || reservation.status !== 'pending') return;

    const clientId = asString(reservation.clientId);
    if (!clientId) {
      logger.error('La reserva creada no contiene clientId.', {
        reservationId: event.params.reservationId,
      });
      return;
    }

    const { coachName, sessionDescription } = await getSessionDescription(
      asString(reservation.scheduleId),
      asString(reservation.coachId),
    );
    const title = 'Tu sesión quedó reservada';
    const body = `Reservaste ${sessionDescription} con ${coachName}.`;

    await notifyClient({
      clientId,
      reservationId: event.params.reservationId,
      title,
      body,
      type: 'reservation_created',
    });
  },
);

export const notifyCoachWhenReservationCreated = onDocumentCreated(
  {
    document: 'reservations/{reservationId}',
    region: 'us-central1',
    secrets: [sendGridApiKey],
  },
  async (event) => {
    const reservation = event.data?.data() as ReservationData | undefined;
    if (!reservation || reservation.status !== 'pending') return;

    const coachId = asString(reservation.coachId);
    const clientId = asString(reservation.clientId);
    if (!coachId || !clientId) {
      logger.error('La solicitud no contiene coachId o clientId.', {
        reservationId: event.params.reservationId,
      });
      return;
    }

    const clientSnapshot = await firestore.collection('users').doc(clientId).get();
    const clientData = clientSnapshot.data();
    const clientName =
      asString(clientData?.name) ??
      asString(clientData?.displayName) ??
      'Un cliente';
    const { sessionDescription } = await getSessionDescription(
      asString(reservation.scheduleId),
      coachId,
    );

    const title = 'Nueva solicitud de reservación';
    const body = `${clientName} solicita ${sessionDescription}. Abre tu agenda para responder.`;
    const pushDelivered = await sendPushNotification({
      uid: coachId,
      reservationId: event.params.reservationId,
      title,
      body,
      type: 'reservation_request',
      audience: 'coach',
    });

    if (pushDelivered) return;

    const coachSnapshot = await firestore.collection('users').doc(coachId).get();
    const coachEmail = asString(coachSnapshot.data()?.email);
    if (!coachEmail) {
      logger.warn('El coach no tiene correo en users/{uid}.', {
        coachId,
        reservationId: event.params.reservationId,
      });
      return;
    }

    sgMail.setApiKey(sendGridApiKey.value());
    await sgMail.send({
      to: coachEmail,
      from: sendGridFromEmail.value(),
      subject: title,
      text: body,
    });
  },
);

export const notifyClientWhenReservationConfirmed = onDocumentUpdated(
  {
    document: 'reservations/{reservationId}',
    region: 'us-central1',
    secrets: [sendGridApiKey],
  },
  async (event) => {
    const before = event.data?.before.data() as ReservationData | undefined;
    const after = event.data?.after.data() as ReservationData | undefined;
    if (!before || !after) return;
    if (before.status !== 'pending' || after.status !== 'confirmed') return;

    const clientId = asString(after.clientId);
    if (!clientId) {
      logger.error('La reservación confirmada no contiene clientId.', {
        reservationId: event.params.reservationId,
      });
      return;
    }

    const { coachName, sessionDescription } = await getSessionDescription(
      asString(after.scheduleId),
      asString(after.coachId),
    );

    await notifyClient({
      clientId,
      reservationId: event.params.reservationId,
      title: 'Solicitud aceptada y sesión agendada',
      body: `El Coach ${coachName} aceptó tu solicitud. Tu sesión (${sessionDescription}) ya quedó agendada.`,
      type: 'reservation_confirmed',
    });
  },
);

export const notifyClientWhenSessionCompleted = onDocumentUpdated(
  {
    document: 'reservations/{reservationId}',
    region: 'us-central1',
    secrets: [sendGridApiKey],
  },
  async (event) => {
    const before = event.data?.before.data() as ReservationData | undefined;
    const after = event.data?.after.data() as ReservationData | undefined;
    if (!before || !after) return;
    if (before.status === 'completed' || after.status !== 'completed') return;

    const clientId = asString(after.clientId);
    if (!clientId) {
      logger.error('La reserva completada no contiene clientId.', {
        reservationId: event.params.reservationId,
      });
      return;
    }

    const { coachName, sessionDescription } = await getSessionDescription(
      asString(after.scheduleId),
      asString(after.coachId),
    );
    const title = 'Ya puedes calificar tu sesión';
    const body = `Tu sesión con ${coachName} (${sessionDescription}) fue marcada como completada. Ya puedes calificar y dejar una reseña.`;

    await notifyClient({
      clientId,
      reservationId: event.params.reservationId,
      title,
      body,
      type: 'session_completed',
    });
  },
);