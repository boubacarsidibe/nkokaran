'use strict';

// Pure request handler for the Djelia TTS proxy — dependencies are injected
// so it can be unit tested without Firebase or the network.

const DJELIA_TTS_URL = 'https://djelia.cloud/api/v1/models/tts';
const MAX_TEXT_LENGTH = 200;
const RATE_LIMIT = { windowMs: 60_000, max: 30 };

function createHandler({ verifyIdToken, getApiKey, fetchImpl = fetch, now = Date.now }) {
  const hits = new Map(); // uid -> [timestamps] (best effort, per instance)

  function rateLimited(uid) {
    const t = now();
    const recent = (hits.get(uid) || []).filter((ts) => t - ts < RATE_LIMIT.windowMs);
    if (recent.length >= RATE_LIMIT.max) {
      hits.set(uid, recent);
      return true;
    }
    recent.push(t);
    hits.set(uid, recent);
    return false;
  }

  return async function handle(req, res) {
    if (req.method !== 'POST') return res.status(405).send('POST only');

    const auth = req.get('Authorization') || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    let uid;
    try {
      uid = (await verifyIdToken(token)).uid;
    } catch (_) {
      return res.status(401).send('Sign-in required');
    }

    if (rateLimited(uid)) return res.status(429).send('Too many requests');

    const text = req.body && typeof req.body.text === 'string' ? req.body.text.trim() : '';
    if (!text || text.length > MAX_TEXT_LENGTH) return res.status(400).send('Invalid text');

    let upstream;
    try {
      upstream = await fetchImpl(DJELIA_TTS_URL, {
        method: 'POST',
        headers: { 'x-api-key': getApiKey(), 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text,
          description: 'Sekou speaks with a clear, warm and natural voice',
          format: 'mp3',
        }),
      });
    } catch (_) {
      return res.status(502).send('Upstream unreachable');
    }
    if (!upstream.ok) return res.status(502).send('Upstream error');

    const audio = Buffer.from(await upstream.arrayBuffer());
    res.set('Content-Type', 'audio/mpeg');
    res.set('Cache-Control', 'private, max-age=86400');
    return res.status(200).send(audio);
  };
}

module.exports = { createHandler, MAX_TEXT_LENGTH, RATE_LIMIT };
