'use strict';

const loadingEl = document.getElementById('state-loading');
const blockedEl = document.getElementById('state-blocked');
const statusEl = document.getElementById('status-message');
const blockedTitleEl = document.getElementById('blocked-title');
const blockedMessageEl = document.getElementById('blocked-message');
const detailsPanel = document.getElementById('details-panel');
const stepsEl = document.getElementById('steps');
const logEl = document.getElementById('log');
const versionEl = document.getElementById('version');
const btnLicense = document.getElementById('btn-license');
const btnDocker = document.getElementById('btn-docker');
const btnRetry = document.getElementById('btn-retry');

const DOCKER_URL = 'https://www.docker.com/products/docker-desktop/';

function showLoading(message) {
  loadingEl.classList.remove('hidden');
  blockedEl.classList.add('hidden');
  statusEl.textContent = message || 'Starting…';
}

function showBlocked(payload) {
  loadingEl.classList.add('hidden');
  blockedEl.classList.remove('hidden');
  detailsPanel.classList.remove('hidden');

  blockedTitleEl.textContent = payload.title || 'Setup needed';
  blockedMessageEl.textContent = payload.message || '';

  btnLicense.classList.add('hidden');
  btnDocker.classList.add('hidden');

  const action = payload.action || 'retry';
  if (action === 'license') btnLicense.classList.remove('hidden');
  if (action === 'docker-install') btnDocker.classList.remove('hidden');

  if (payload.fix) appendLog(payload.fix);
}

function appendLog(line) {
  logEl.textContent += `${line}\n`;
  logEl.scrollTop = logEl.scrollHeight;
}

function renderStep(step) {
  const li = document.createElement('li');
  const mark = step.status === 'ok' ? '✓' : step.status === 'fail' ? '✗' : '·';
  li.textContent = `${mark} ${step.label}${step.detail ? ` — ${step.detail}` : ''}`;
  stepsEl.appendChild(li);
}

async function init() {
  if (!window.electronAPI) {
    showBlocked({
      title: 'Launcher error',
      message: 'Could not connect to the desktop shell.',
    });
    return;
  }

  const version = await window.electronAPI.getAppVersion();
  versionEl.textContent = `Version ${version}`;

  window.electronAPI.onSetupPhase((payload) => {
    if (payload.phase === 'checking' || payload.phase === 'starting' || payload.phase === 'connecting') {
      showLoading(payload.message);
    } else if (payload.phase === 'blocked') {
      showBlocked(payload);
    } else if (payload.phase === 'error') {
      showBlocked({
        title: 'Something went wrong',
        message: payload.message || 'NeuroInsight-AutoHS could not start.',
        action: 'retry',
      });
      detailsPanel.classList.remove('hidden');
    }
  });

  window.electronAPI.onSetupStep((step) => {
    renderStep(step);
  });

  window.electronAPI.onSetupLog((line) => {
    appendLog(line);
  });

  btnRetry.addEventListener('click', () => {
    stepsEl.innerHTML = '';
    logEl.textContent = '';
    showLoading('Retrying…');
    window.electronAPI.retryBootstrap();
  });

  btnLicense.addEventListener('click', async () => {
    showLoading('Saving license…');
    const saved = await window.electronAPI.pickLicense();
    if (saved) {
      stepsEl.innerHTML = '';
      logEl.textContent = '';
      window.electronAPI.retryBootstrap();
    } else {
      showBlocked({
        title: 'FreeSurfer license needed',
        message: 'Choose your license.txt file to continue.',
        action: 'license',
      });
    }
  });

  btnDocker.addEventListener('click', () => {
    window.electronAPI.openExternal(DOCKER_URL);
  });

  blockedMessageEl.addEventListener('dblclick', () => {
    detailsPanel.classList.toggle('hidden');
  });
}

init();
