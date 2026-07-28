# Eventa Cloud Functions (FCM)

## Deploy

```bash
cd functions
npm install
cd ..
firebase deploy --only functions,firestore:rules
```

## Triggers

| Export | Trigger | Purpose |
|--------|---------|---------|
| `onMeetingParticipantCreated` / `Updated` | participants joined | Push to meeting creator |
| `onMeetingChatCreated` | meeting chat message | Multicast to other joined participants |
| `onMeetingCreated` | new meeting with linkedEventId | Push to active campaign organizer |
| `onEventChatCreated` | event chat message | Queue digest in `pendingDigests` |
| `flushEventChatDigests` | every 20 minutes | Send digest pushes |

Tokens live in `users/{uid}/devices/{deviceId}`. Settings in `users/{uid}.notificationSettings`.
