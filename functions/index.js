'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const { createHandler } = require('./tts');

admin.initializeApp();

// Set once with: firebase functions:secrets:set DJELIA_API_KEY
const djeliaKey = defineSecret('DJELIA_API_KEY');

const handler = createHandler({
  verifyIdToken: (token) => admin.auth().verifyIdToken(token),
  getApiKey: () => djeliaKey.value(),
});

// Only signed-in N'Ko Kalan users get audio; the Djelia key never leaves the server.
exports.tts = onRequest({ secrets: [djeliaKey], cors: true, region: 'europe-west1', maxInstances: 5 }, handler);
