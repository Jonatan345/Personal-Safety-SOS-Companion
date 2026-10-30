import { createServer as createHttpServer } from 'node:http';
import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const defaultDataFile = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  'data',
  'incidents.json',
);
const validStatuses = new Set(['sent', 'cancelled', 'pending']);
const maxBodySize = 64 * 1024;

export async function createServer({ dataFile = defaultDataFile } = {}) {
  let incidents = await loadIncidents(dataFile);
  let writes = Promise.resolve();

  async function persist() {
    const snapshot = JSON.stringify(incidents, null, 2);
    const write = writes.then(async () => {
      await mkdir(path.dirname(dataFile), { recursive: true });
      const temporaryFile = `${dataFile}.tmp`;
      await writeFile(temporaryFile, snapshot, 'utf8');
      await rename(temporaryFile, dataFile);
    });
    writes = write.catch(() => {});
    await write;
  }

  return createHttpServer((request, response) => {
    void handleRequest(request, response).catch((error) => {
      console.error('Incident API request failed:', error);
      if (response.headersSent) {
        response.destroy();
      } else {
        sendJson(response, 500, { error: 'Internal server error.' });
      }
    });
  });

  async function handleRequest(request, response) {
    response.setHeader('access-control-allow-origin', '*');
    response.setHeader('access-control-allow-methods', 'GET, POST, PATCH, DELETE, OPTIONS');
    response.setHeader('access-control-allow-headers', 'content-type');

    if (request.method === 'OPTIONS') {
      response.writeHead(204).end();
      return;
    }

    const url = new URL(request.url ?? '/', 'http://localhost');
    if (url.pathname === '/health' && request.method === 'GET') {
      sendJson(response, 200, { status: 'ok' });
      return;
    }

    if (url.pathname === '/api/incidents' && request.method === 'GET') {
      sendJson(
        response,
        200,
        [...incidents].sort(
          (left, right) =>
            Date.parse(right.timestamp) - Date.parse(left.timestamp),
        ),
      );
      return;
    }

    if (url.pathname === '/api/incidents' && request.method === 'POST') {
      const incident = await readIncident(request, response);
      if (incident == null) return;
      if (incidents.some((item) => item.id === incident.id)) {
        sendJson(response, 409, { error: 'Incident id already exists.' });
        return;
      }

      incidents = [...incidents, incident];
      await persist();
      sendJson(response, 201, incident);
      return;
    }

    const match = url.pathname.match(/^\/api\/incidents\/([^/]+)$/);
    if (match != null) {
      const id = decodeURIComponent(match[1]);
      const index = incidents.findIndex((item) => item.id === id);
      if (index < 0) {
        sendJson(response, 404, { error: 'Incident not found.' });
        return;
      }

      if (request.method === 'PATCH') {
        const incident = await readIncident(request, response);
        if (incident == null) return;
        if (incident.id !== id) {
          sendJson(response, 400, { error: 'Incident id does not match URL.' });
          return;
        }
        incidents = incidents.map((item, itemIndex) =>
          itemIndex === index ? incident : item,
        );
        await persist();
        sendJson(response, 200, incident);
        return;
      }

      if (request.method === 'DELETE') {
        incidents = incidents.filter((item) => item.id !== id);
        await persist();
        response.writeHead(204).end();
        return;
      }
    }

    sendJson(response, 404, { error: 'Route not found.' });
  }
}

async function loadIncidents(dataFile) {
  try {
    const parsed = JSON.parse(await readFile(dataFile, 'utf8'));
    if (!Array.isArray(parsed) || !parsed.every(isIncident)) {
      throw new Error(`Invalid incident data in ${dataFile}.`);
    }
    return parsed;
  } catch (error) {
    if (error.code === 'ENOENT') return [];
    throw error;
  }
}

async function readIncident(request, response) {
  let body = '';
  let tooLarge = false;
  for await (const chunk of request) {
    if (tooLarge) continue;
    body += chunk;
    if (Buffer.byteLength(body) > maxBodySize) {
      tooLarge = true;
      body = '';
    }
  }
  if (tooLarge) {
    sendJson(response, 413, { error: 'Request body is too large.' });
    return null;
  }

  let incident;
  try {
    incident = JSON.parse(body);
  } catch {
    sendJson(response, 400, { error: 'Request body must contain valid JSON.' });
    return null;
  }
  if (!isIncident(incident)) {
    sendJson(response, 400, { error: 'Incident fields are invalid.' });
    return null;
  }
  return incident;
}

function isCoordinate(value, limit) {
  return (
    typeof value === 'number' &&
    Number.isFinite(value) &&
    value >= -limit &&
    value <= limit
  );
}

// Lokasi boleh null (GPS gagal), tetapi harus null KEDUANYA atau valid KEDUANYA.
function hasValidLocation(value) {
  if (value.latitude === null && value.longitude === null) return true;
  return isCoordinate(value.latitude, 90) && isCoordinate(value.longitude, 180);
}

function isIncident(value) {
  return (
    value != null &&
    typeof value === 'object' &&
    typeof value.id === 'string' &&
    value.id.trim().length > 0 &&
    typeof value.timestamp === 'string' &&
    Number.isFinite(Date.parse(value.timestamp)) &&
    hasValidLocation(value) &&
    validStatuses.has(value.status)
  );
}

function sendJson(response, statusCode, value) {
  response.writeHead(statusCode, { 'content-type': 'application/json; charset=utf-8' });
  response.end(JSON.stringify(value));
}

if (
  process.argv[1] != null &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const port = Number(process.env.PORT ?? 8080);
  const server = await createServer();
  server.listen(port, '0.0.0.0', () => {
    console.log(`SOS incident API listening on http://0.0.0.0:${port}`);
  });
}
