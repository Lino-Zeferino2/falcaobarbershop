// Firebase Cloud Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: 'AIzaSyDx4uTpzX7X8_Epthzu0CKcVQPtx92Kx5Y',
  authDomain: 'falcaobarbershopv2.firebaseapp.com',
  projectId: 'falcaobarbershopv2',
  storageBucket: 'falcaobarbershopv2.firebasestorage.app',
  messagingSenderId: '703328438774',
  appId: '1:703328438774:web:42e8dbe82138e7831e9fd7',
  measurementId: 'G-LKL9XXBZRB'
});


// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification?.title || 'Nova Notificação';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: payload.notification?.icon || '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    tag: payload.data?.tag || 'default',
    requireInteraction: true,
    silent: false,
    // Remove sound property as it's not supported in all browsers
    // Instead, rely on the browser's default notification sound
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');
  
  event.notification.close();
  
  // Get the click action from the notification data
  const clickAction = event.notification.data?.click_action || '/';
  
  // Open the app at the specified URL
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Check if there's already a window open
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus();
          client.postMessage({
            type: 'NOTIFICATION_CLICK',
            data: event.notification.data
          });
          return;
        }
      }
      // If no window is open, open a new one
      if (clients.openWindow) {
        return clients.openWindow(clickAction);
      }
    })
  );
});
