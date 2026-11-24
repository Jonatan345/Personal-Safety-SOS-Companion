import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { afterEach, beforeEach, test } from 'node:test';

import { createServer } from './server.mjs';

const incident = {
  id: 'incident-1',
  timestamp: '2026-10-15T05:00:00.000Z',
  latitude: -6.2088,
  longitude: 106.8456,
  status: 'sent',
};

let directory;
let server;
let baseUrl;

beforeEach(async () => {
  directory = await mkdtemp(path.join(os.tmpdir(), 'sos-api-test-'));
  server = await createServer({
    dataFile: path.join(directory, 'incidents.json'),
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

afterEach(async () => {
  await new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
  await rm(directory, { recursive: true, force: true });
});

test('health endpoint responds successfully', async () => {
  const response = await fetch(`${baseUrl}/health`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), { status: 'ok' });
});

test('GET incidents starts with an empty array', async () => {
  const response = await fetch(`${baseUrl}/api/incidents`);
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), []);
});

test('POST and GET persist an incident', async () => {
  const created = await fetch(`${baseUrl}/api/incidents`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(incident),
  });
  assert.equal(created.status, 201);
  assert.deepEqual(await created.json(), incident);

  const listed = await fetch(`${baseUrl}/api/incidents`);
  assert.deepEqual(await listed.json(), [incident]);
});

test('PATCH updates an incident and DELETE removes it', async () => {
  await fetch(`${baseUrl}/api/incidents`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(incident),
  });
  const updatedIncident = { ...incident, status: 'cancelled' };
  const updated = await fetch(`${baseUrl}/api/incidents/incident-1`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(updatedIncident),
  });
  assert.equal(updated.status, 200);
  assert.deepEqual(await updated.json(), updatedIncident);

  const deleted = await fetch(`${baseUrl}/api/incidents/incident-1`, {
    method: 'DELETE',
  });
  assert.equal(deleted.status, 204);
  assert.deepEqual(await (await fetch(`${baseUrl}/api/incidents`)).json(), []);
});

test('rejects invalid incident data', async () => {
  const response = await fetch(`${baseUrl}/api/incidents`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ ...incident, latitude: 95 }),
  });
  assert.equal(response.status, 400);
});

// TAMBAHKAN dua test ini di akhir backend/server.test.mjs.
test('accepts an incident whose location is unavailable (null coordinates)', async () => {
  const noLocation = { ...incident, id: 'incident-2', latitude: null, longitude: null };
  const created = await fetch(`${baseUrl}/api/incidents`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(noLocation),
  });
  assert.equal(created.status, 201);
  assert.deepEqual(await created.json(), noLocation);
});

test('rejects an incident with only one coordinate', async () => {
  const response = await fetch(`${baseUrl}/api/incidents`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ ...incident, longitude: null }),
  });
  assert.equal(response.status, 400);
});

test('handles malformed percent-encoding in incident id with 400 instead of 500', async () => {
  const patchResponse = await fetch(`${baseUrl}/api/incidents/%E0%A4%A`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ ...incident, id: '%E0%A4%A' }),
  });
  assert.equal(patchResponse.status, 400);
  assert.deepEqual(await patchResponse.json(), {
    error: 'Incident id is not valid.',
  });

  const deleteResponse = await fetch(`${baseUrl}/api/incidents/%E0%A4%A`, {
    method: 'DELETE',
  });
  assert.equal(deleteResponse.status, 400);
  assert.deepEqual(await deleteResponse.json(), {
    error: 'Incident id is not valid.',
  });
});

test('preserves multibyte UTF-8 characters split across multiple request chunks', async () => {
  const http = await import('node:http');
  const specialText = 'Jatuh di jalan — é 🚨';
  const payload = JSON.stringify({
    ...incident,
    id: 'incident-utf8-chunk',
    status: 'sent',
    source: specialText,
  });

  const payloadBuffer = Buffer.from(payload, 'utf8');
  // Find a split point right in the middle of the multibyte sequence for '—' (e2 80 94)
  const dashIndex = payloadBuffer.indexOf(Buffer.from('—', 'utf8'));
  const splitPoint = dashIndex + 1; // split right inside the 3-byte em-dash

  const part1 = payloadBuffer.subarray(0, splitPoint);
  const part2 = payloadBuffer.subarray(splitPoint);

  const parsedUrl = new URL(`${baseUrl}/api/incidents`);
  const response = await new Promise((resolve, reject) => {
    const req = http.request(
      {
        hostname: parsedUrl.hostname,
        port: parsedUrl.port,
        path: parsedUrl.pathname,
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'content-length': payloadBuffer.length,
        },
      },
      (res) => {
        const bodyChunks = [];
        res.on('data', (c) => bodyChunks.push(c));
        res.on('end', () => {
          resolve({
            statusCode: res.statusCode,
            body: JSON.parse(Buffer.concat(bodyChunks).toString('utf8')),
          });
        });
      },
    );
    req.on('error', reject);
    req.write(part1);
    setTimeout(() => {
      req.write(part2);
      req.end();
    }, 10);
  });

  assert.equal(response.statusCode, 201);
  assert.equal(response.body.source, specialText);
});

test('strips arbitrary extra fields not in whitelist from stored incident (Bug #4)', async () => {
  const response = await fetch(`${baseUrl}/api/incidents`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      ...incident,
      id: 'incident-whitelist',
      junk: 'malicious-or-unwanted',
      extraField: 12345,
    }),
  });
  assert.equal(response.status, 201);
  const json = await response.json();
  assert.equal(json.id, 'incident-whitelist');
  assert.equal(json.junk, undefined);
  assert.equal(json.extraField, undefined);

  const listResponse = await fetch(`${baseUrl}/api/incidents`);
  const list = await listResponse.json();
  const stored = list.find((item) => item.id === 'incident-whitelist');
  assert.ok(stored);
  assert.equal(stored.junk, undefined);
  assert.equal(stored.extraField, undefined);
});

