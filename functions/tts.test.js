'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { createHandler, RATE_LIMIT } = require('./tts');

function fakeRes() {
  const r = { code: 200, headers: {}, body: undefined };
  r.status = (c) => ((r.code = c), r);
  r.send = (b) => ((r.body = b), r);
  r.set = (k, v) => ((r.headers[k] = v), r);
  return r;
}
const req = (over = {}) => ({
  method: 'POST',
  body: { text: 'ba' },
  get: (h) => (h === 'Authorization' ? 'Bearer good' : ''),
  ...over,
});
const deps = (over = {}) => ({
  verifyIdToken: async (t) => {
    if (t !== 'good') throw new Error('bad');
    return { uid: 'u1' };
  },
  getApiKey: () => 'secret',
  fetchImpl: async () => ({ ok: true, arrayBuffer: async () => new Uint8Array([1, 2, 3]).buffer }),
  ...over,
});

test('rejects non-POST', async () => {
  const res = fakeRes();
  await createHandler(deps())(req({ method: 'GET' }), res);
  assert.equal(res.code, 405);
});

test('rejects missing or invalid token', async () => {
  const res = fakeRes();
  await createHandler(deps())(req({ get: () => '' }), res);
  assert.equal(res.code, 401);
});

test('rejects empty or oversized text', async () => {
  for (const text of ['', '  ', 'x'.repeat(201), 42]) {
    const res = fakeRes();
    await createHandler(deps())(req({ body: { text } }), res);
    assert.equal(res.code, 400);
  }
});

test('proxies audio and sends the key only upstream', async () => {
  let seen;
  const res = fakeRes();
  await createHandler(deps({ fetchImpl: async (url, init) => ((seen = init), { ok: true, arrayBuffer: async () => new Uint8Array([9]).buffer }) }))(req(), res);
  assert.equal(res.code, 200);
  assert.equal(res.headers['Content-Type'], 'audio/mpeg');
  assert.equal(seen.headers['x-api-key'], 'secret');
  assert.ok(!JSON.stringify(res.headers).includes('secret'));
});

test('maps upstream failures to 502', async () => {
  const res = fakeRes();
  await createHandler(deps({ fetchImpl: async () => ({ ok: false }) }))(req(), res);
  assert.equal(res.code, 502);
  const res2 = fakeRes();
  await createHandler(deps({ fetchImpl: async () => { throw new Error('net'); } }))(req(), res2);
  assert.equal(res2.code, 502);
});

test('rate limits a user, then recovers after the window', async () => {
  let t = 0;
  const h = createHandler(deps({ now: () => t }));
  for (let i = 0; i < RATE_LIMIT.max; i++) {
    const r = fakeRes();
    await h(req(), r);
    assert.equal(r.code, 200);
  }
  const blocked = fakeRes();
  await h(req(), blocked);
  assert.equal(blocked.code, 429);
  t += RATE_LIMIT.windowMs + 1;
  const ok = fakeRes();
  await h(req(), ok);
  assert.equal(ok.code, 200);
});
