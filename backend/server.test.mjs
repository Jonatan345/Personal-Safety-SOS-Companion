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
