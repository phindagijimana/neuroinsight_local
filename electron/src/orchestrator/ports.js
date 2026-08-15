'use strict';

const net = require('net');
const {
  WEB_PORT_MIN,
  WEB_PORT_MAX,
  MINIO_PORT_MIN,
  MINIO_PORT_MAX,
} = require('./constants');

function isPortAvailable(port) {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.unref();
    server.on('error', () => resolve(false));
    server.listen({ port, host: '127.0.0.1' }, () => {
      server.close(() => resolve(true));
    });
  });
}

async function findAvailablePort(min, max, exclude = new Set()) {
  for (let port = min; port <= max; port += 1) {
    if (exclude.has(port)) continue;
    // eslint-disable-next-line no-await-in-loop
    if (await isPortAvailable(port)) return port;
  }
  return null;
}

async function findWebPort() {
  return findAvailablePort(WEB_PORT_MIN, WEB_PORT_MAX);
}

async function findMinioPorts() {
  const apiPort = await findAvailablePort(MINIO_PORT_MIN, MINIO_PORT_MAX);
  if (!apiPort) return null;
  const consolePort = await findAvailablePort(
    MINIO_PORT_MIN,
    MINIO_PORT_MAX,
    new Set([apiPort])
  );
  if (!consolePort) return null;
  return { apiPort, consolePort };
}

module.exports = {
  findWebPort,
  findMinioPorts,
  isPortAvailable,
};
