'use strict';

const path = require('path');
const { app } = require('electron');
const {
  CONTAINER_NAME,
  IMAGE_NAME,
  FREESURFER_IMAGE,
  VOLUME_NAME,
} = require('./constants');
const {
  platformArgs,
  dockerSocketArgs,
  runDocker,
  spawnDocker,
  containerExists,
  containerRunning,
  getContainerPort,
  stopContainer,
  removeContainer,
  startContainer,
} = require('./docker');
const { findWebPort, findMinioPorts } = require('./ports');
const { findLicensePath } = require('./license');
const { runPreflight } = require('./preflight');

function getProjectRoot() {
  if (app.isPackaged) return null;
  return path.resolve(__dirname, '../../..');
}

function getUserDataDir() {
  return app.getPath('userData');
}

function getEntrypointPath() {
  if (app.isPackaged) {
    return path.join(process.resourcesPath, 'entrypoint.sh');
  }
  return path.resolve(__dirname, '../../../deploy/entrypoint.sh');
}

async function pullImages(onProgress) {
  const platform = platformArgs();
  if (onProgress) onProgress(`Pulling ${IMAGE_NAME}...`);
  await spawnDocker(['pull', ...platform, IMAGE_NAME], (line) => {
    if (onProgress) onProgress(line.trim());
  });
  if (onProgress) onProgress(`Pulling ${FREESURFER_IMAGE}...`);
  try {
    await spawnDocker(['pull', ...platform, FREESURFER_IMAGE], (line) => {
      if (onProgress) onProgress(line.trim());
    });
  } catch (error) {
    if (onProgress) onProgress(`Warning: FreeSurfer pull failed (${error.message})`);
  }
}

async function waitForWeb(port, attempts = 60) {
  const url = `http://127.0.0.1:${port}/`;
  for (let i = 0; i < attempts; i += 1) {
    try {
      const response = await fetch(url, { signal: AbortSignal.timeout(4000) });
      if (response.ok) return true;
    } catch {
      // retry
    }
    if (!(await containerRunning(CONTAINER_NAME))) {
      throw new Error('Container stopped while starting');
    }
    // eslint-disable-next-line no-await-in-loop
    await new Promise((r) => setTimeout(r, 5000));
  }
  return false;
}

async function installContainer({ licensePath, onProgress }) {
  const userDataDir = getUserDataDir();
  const resolvedLicense = licensePath || findLicensePath(userDataDir, getProjectRoot());
  if (!resolvedLicense) {
    throw new Error('FreeSurfer license.txt is required');
  }

  if (await containerExists(CONTAINER_NAME)) {
    if (onProgress) onProgress('Removing existing container...');
    if (await containerRunning(CONTAINER_NAME)) await stopContainer(CONTAINER_NAME);
    await removeContainer(CONTAINER_NAME);
  }

  const webPort = await findWebPort();
  const minioPorts = await findMinioPorts();
  if (!webPort || !minioPorts) {
    throw new Error('No free ports available');
  }

  if (onProgress) onProgress('Pulling Docker images (first run may take several minutes)...');
  await pullImages(onProgress);

  const entrypointPath = getEntrypointPath();
  const platform = platformArgs();
  const args = [
    'run',
    '-d',
    '--name',
    CONTAINER_NAME,
    '-p',
    `${webPort}:8000`,
    '-p',
    `${minioPorts.apiPort}:9000`,
    '-p',
    `${minioPorts.consolePort}:9001`,
    ...dockerSocketArgs(),
    '-v',
    `${VOLUME_NAME}:/data`,
    '-v',
    `${resolvedLicense}:/app/license.txt:ro`,
    '-v',
    `${entrypointPath}:/app/entrypoint.sh:ro`,
    ...platform,
    '--restart',
    'unless-stopped',
    IMAGE_NAME,
  ];

  if (onProgress) onProgress('Creating NeuroInsight container...');
  const result = await runDocker(args);
  if (!result.ok) {
    throw new Error(result.stderr || 'Failed to create container');
  }

  if (onProgress) onProgress(`Waiting for web UI on port ${webPort}...`);
  const ready = await waitForWeb(webPort);
  if (!ready) {
    throw new Error(`Web UI did not respond on port ${webPort}`);
  }

  return {
    webPort,
    minioApiPort: minioPorts.apiPort,
    minioConsolePort: minioPorts.consolePort,
    backendUrl: `http://127.0.0.1:${webPort}/api`,
    webUrl: `http://127.0.0.1:${webPort}/`,
  };
}

async function ensureRunning({ onProgress }) {
  if (await containerRunning(CONTAINER_NAME)) {
    const webPort = await getContainerPort(CONTAINER_NAME, 8000);
    if (!webPort) throw new Error('Could not detect container web port');
    const backendUrl = `http://127.0.0.1:${webPort}/api`;
    const webUrl = `http://127.0.0.1:${webPort}/`;
    if (onProgress) onProgress(`Container already running on port ${webPort}`);
    await waitForWeb(Number(webPort), 12);
    return { webPort: Number(webPort), backendUrl, webUrl };
  }

  if (await containerExists(CONTAINER_NAME)) {
    if (onProgress) onProgress('Starting existing container...');
    const start = await startContainer(CONTAINER_NAME);
    if (!start.ok) throw new Error(start.stderr || 'Failed to start container');
    const webPort = await getContainerPort(CONTAINER_NAME, 8000);
    if (!webPort) throw new Error('Could not detect container web port');
    await waitForWeb(Number(webPort), 24);
    return {
      webPort: Number(webPort),
      backendUrl: `http://127.0.0.1:${webPort}/api`,
      webUrl: `http://127.0.0.1:${webPort}/`,
    };
  }

  return installContainer({ onProgress });
}

async function runCheck(onStep) {
  return runPreflight({
    userDataDir: getUserDataDir(),
    projectRoot: getProjectRoot(),
    entrypointPath: getEntrypointPath(),
    onStep,
  });
}

async function getStatus() {
  const exists = await containerExists(CONTAINER_NAME);
  const running = exists && (await containerRunning(CONTAINER_NAME));
  let webPort = null;
  if (running) {
    webPort = await getContainerPort(CONTAINER_NAME, 8000);
  }
  return {
    exists,
    running,
    webPort: webPort ? Number(webPort) : null,
    backendUrl: webPort ? `http://127.0.0.1:${webPort}/api` : null,
    webUrl: webPort ? `http://127.0.0.1:${webPort}/` : null,
  };
}

module.exports = {
  getProjectRoot,
  getUserDataDir,
  getEntrypointPath,
  runCheck,
  installContainer,
  ensureRunning,
  getStatus,
  pullImages,
};
