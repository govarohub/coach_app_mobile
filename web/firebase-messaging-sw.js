importScripts('https://www.gstatic.com/firebasejs/11.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDM-0NdBKOys5FyHXWQ0PHTbXC6ct18fgo',
  authDomain: 'coach-app-govarohub.firebaseapp.com',
  projectId: 'coach-app-govarohub',
  storageBucket: 'coach-app-govarohub.firebasestorage.app',
  messagingSenderId: '993530648',
  appId: '1:993530648:web:34ae181c25b5672fa2046d',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const title = notification.title || 'Coach App Mobile';
  const options = {
    body: notification.body || '',
    data: payload.data || {},
  };

  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = new URL('/#/reservations', self.location.origin).href;

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then(
      (windows) => {
        const existingWindow = windows.find(
          (client) => client.url.startsWith(self.location.origin),
        );
        if (existingWindow) {
          return existingWindow.navigate(targetUrl).then(() => existingWindow.focus());
        }
        return self.clients.openWindow(targetUrl);
      },
    ),
  );
});