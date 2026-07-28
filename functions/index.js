const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

function truncate(text, max = 80) {
  const t = (text || '').toString().trim();
  if (t.length <= max) return t;
  return `${t.slice(0, max - 1)}…`;
}

/** Default true if field missing (users до миграции схемы). */
async function shouldNotify(uid, settingKey) {
  const userDoc = await db.collection('users').doc(uid).get();
  const settings = userDoc.data()?.notificationSettings;
  return settings?.[settingKey] !== false;
}

async function getDeviceTokens(uid) {
  const snap = await db.collection('users').doc(uid).collection('devices').get();
  return snap.docs
    .map((d) => d.data().token)
    .filter((t) => typeof t === 'string' && t.length > 0);
}

async function getDisplayName(uid) {
  const profile = await db.collection('profiles').doc(uid).get();
  if (profile.exists && profile.data() && profile.data().name) {
    return profile.data().name;
  }
  return 'Пользователь';
}

async function sendToUser(uid, { notification, data, settingKey }) {
  if (settingKey && !(await shouldNotify(uid, settingKey))) {
    return { skipped: true };
  }

  const tokens = await getDeviceTokens(uid);
  if (!tokens.length) return { sent: 0 };

  const message = {
    tokens,
    notification,
    data: Object.fromEntries(
      Object.entries(data || {}).map(([k, v]) => [k, String(v)])
    ),
  };
  const res = await admin.messaging().sendEachForMulticast(message);
  return { sent: res.successCount, failure: res.failureCount };
}

/** 2.2 Новый участник + опционально «группа набрана» */
async function notifyMeetingJoined(meetingId, joinedUid) {
  const meetingRef = db.collection('meetings').doc(meetingId);
  const meetingSnap = await meetingRef.get();
  if (!meetingSnap.exists) return null;
  const meeting = meetingSnap.data() || {};
  const creatorId = meeting.creatorId || meeting.hostUserId;
  const topic = meeting.topic || meeting.venueName || 'встреча';
  const results = [];

  if (creatorId && creatorId !== joinedUid) {
    const userName = await getDisplayName(joinedUid);
    results.push(
      await sendToUser(creatorId, {
        settingKey: 'meetingJoined',
        notification: {
          title: 'Новый участник',
          body: `${userName} присоединился к встрече «${topic}»`,
        },
        data: {
          type: 'meeting_joined',
          meetingId,
          joinedUserId: joinedUid,
        },
      })
    );
  }

  const current = meeting.currentParticipantCount || 0;
  const max = meeting.maxParticipants || 0;
  if (max > 0 && current === max) {
    const participantsSnap = await meetingRef
      .collection('participants')
      .where('status', '==', 'joined')
      .get();
    for (const doc of participantsSnap.docs) {
      results.push(
        await sendToUser(doc.id, {
          settingKey: 'meetingJoined',
          notification: {
            title: 'Группа набрана',
            body: `Встреча «${topic}» собрала ${max} участников`,
          },
          data: {
            type: 'meeting_full',
            meetingId,
            title: 'Группа набрана',
          },
        })
      );
    }
  }

  return results;
}

exports.onMeetingParticipantCreated = functions.firestore
  .document('meetings/{meetingId}/participants/{uid}')
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    if (data.status !== 'joined') return null;
    return notifyMeetingJoined(context.params.meetingId, context.params.uid);
  });

exports.onMeetingParticipantUpdated = functions.firestore
  .document('meetings/{meetingId}/participants/{uid}')
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (before.status === 'joined' || after.status !== 'joined') return null;
    return notifyMeetingJoined(context.params.meetingId, context.params.uid);
  });

/** 2.1 Сообщение в чате встречи */
exports.onMeetingChatCreated = functions.firestore
  .document('meetings/{meetingId}/chat/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data() || {};
    const senderId = message.senderId;
    const text = message.text || '';
    const meetingId = context.params.meetingId;
    if (!senderId) return null;

    const participants = await db
      .collection('meetings')
      .doc(meetingId)
      .collection('participants')
      .where('status', '==', 'joined')
      .get();

    const senderName = await getDisplayName(senderId);
    const body = truncate(text);
    const results = [];

    for (const doc of participants.docs) {
      if (doc.id === senderId) continue;
      results.push(
        await sendToUser(doc.id, {
          settingKey: 'meetingChat',
          notification: {
            title: senderName,
            body,
          },
          data: {
            type: 'meeting_chat',
            meetingId,
            senderId,
          },
        })
      );
    }
    return results;
  });

/** 2.4 Кампания: новая встреча под событие */
exports.onMeetingCreated = functions.firestore
  .document('meetings/{meetingId}')
  .onCreate(async (snap, context) => {
    const meeting = snap.data() || {};
    const eventId = meeting.linkedEventId;
    if (!eventId) return null;

    const campaigns = await db
      .collection('eventMeetupCampaigns')
      .where('eventId', '==', eventId)
      .where('status', '==', 'active')
      .limit(1)
      .get();
    if (campaigns.empty) return null;

    const campaignDoc = campaigns.docs[0];
    const campaign = campaignDoc.data() || {};
    const organizerId = campaign.organizerId;
    if (!organizerId) return null;
    if (organizerId === meeting.creatorId) return null;

    return sendToUser(organizerId, {
      settingKey: 'campaignUpdates',
      notification: {
        title: 'Новая встреча в кампании',
        body: `Создана встреча «${meeting.topic || 'без темы'}» под «${
          campaign.title || 'кампанию'
        }»`,
      },
      data: {
        type: 'campaign_new_meeting',
        campaignId: campaignDoc.id,
        meetingId: context.params.meetingId,
      },
    });
  });

/** 2.3 Дайджест чата события — накопление (флаг проверяется при flush) */
exports.onEventChatCreated = functions.firestore
  .document('events/{eventId}/eventChat/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data() || {};
    const senderId = message.senderId;
    const eventId = context.params.eventId;
    if (!senderId) return null;

    const attendees = await db
      .collection('events')
      .doc(eventId)
      .collection('attendees')
      .where('status', '==', 'going')
      .get();

    const batch = db.batch();
    let ops = 0;
    for (const att of attendees.docs) {
      if (att.id === senderId) continue;
      const digestId = `${eventId}_${att.id}`;
      const ref = db.collection('pendingDigests').doc(digestId);
      batch.set(
        ref,
        {
          eventId,
          uid: att.id,
          count: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      ops += 1;
      if (ops >= 400) break;
    }
    if (ops === 0) return null;
    await batch.commit();
    return { queued: ops };
  });

/** 2.3 Scheduled: раз в 20 минут шлём дайджесты */
exports.flushEventChatDigests = functions.pubsub
  .schedule('every 20 minutes')
  .onRun(async () => {
    const snap = await db.collection('pendingDigests').limit(200).get();
    if (snap.empty) return null;

    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const uid = data.uid;
      const eventId = data.eventId;
      const count = data.count || 0;
      if (!uid || !eventId || count < 1) {
        await doc.ref.delete();
        continue;
      }

      let eventTitle = 'события';
      try {
        const eventSnap = await db.collection('events').doc(eventId).get();
        if (eventSnap.exists && eventSnap.data() && eventSnap.data().title) {
          eventTitle = eventSnap.data().title;
        }
      } catch (_) {}

      await sendToUser(uid, {
        settingKey: 'eventChatDigest',
        notification: {
          title: 'Чат события',
          body: `В чате «${eventTitle}» ${count} новых сообщений`,
        },
        data: {
          type: 'event_chat_digest',
          eventId,
          eventTitle,
        },
      });
      await doc.ref.delete();
    }
    return { flushed: snap.size };
  });
