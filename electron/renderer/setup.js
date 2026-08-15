'use strict';

const stepsEl = document.getElementById('steps');
const logEl = document.getElementById('log');
const btnCheck = document.getElementById('btn-check');
const btnLicense = document.getElementById('btn-license');
const btnInstall = document.getElementById('btn-install');
const btnOpen = document.getElementById('btn-open');
const versionEl = document.getElementById('version');
const licenseHintEl = document.getElementById('license-hint');

/** @type {Map<number, HTMLLIElement>} */
const stepNodes = new Map();
let lastCheckOk = false;
let runtimeReady = false;

function log(line) {
  logEl.textContent += `${line}\n`;
  logEl.scrollTop = logEl.scrollHeight;
}

function badgeClass(status) {
  if (status === 'ok') return 'ok';
  if (status === 'fail') return 'fail';
  if (status === 'warn') return 'warn';
  return 'pending';
}

function renderStep(step) {
  let li = stepNodes.get(step.step);
  if (!li) {
    li = document.createElement('li');
    li.dataset.step = String(step.step);
    stepsEl.appendChild(li);
    stepNodes.set(step.step, li);
  }
  li.innerHTML = `
    <span class="badge ${badgeClass(step.status)}">${step.status.toUpperCase()}</span>
    <div class="step-body">
      <div class="step-label">[${step.step}/${step.total}] ${step.label}</div>
      <div class="step-detail">${step.detail || ''}</div>
    </div>
  `;
}

function setBusy(busy) {
  btnCheck.disabled = busy;
  btnInstall.disabled = busy || !lastCheckOk;
  btnOpen.disabled = busy || !runtimeReady;
  btnLicense.disabled = busy;
}

async function init() {
  if (!window.electronAPI) {
    log('Electron API unavailable.');
    return;
  }

  const version = await window.electronAPI.getAppVersion();
  versionEl.textContent = `Version ${version}`;

  const paths = await window.electronAPI.getPaths();
  licenseHintEl.textContent = `Recommended license path: ${paths.recommendedLicense}`;

  window.electronAPI.onSetupStep(renderStep);
  window.electronAPI.onSetupLog(log);

  btnLicense.addEventListener('click', async () => {
    setBusy(true);
    try {
      const saved = await window.electronAPI.pickLicense();
      if (saved) {
        log(`License saved to ${saved}`);
        await runChecks();
      }
    } finally {
      setBusy(false);
    }
  });

  btnCheck.addEventListener('click', runChecks);

  btnInstall.addEventListener('click', async () => {
    setBusy(true);
    runtimeReady = false;
    try {
      log('--- install/start ---');
      const result = await window.electronAPI.runStart();
      log(`Ready at ${result.webUrl}`);
      runtimeReady = true;
      btnOpen.disabled = false;
      const paths = await window.electronAPI.getPaths();
      if (paths.isPackaged) {
        await window.electronAPI.openApp();
      }
    } catch (error) {
      log(`Install failed: ${error.message || error}`);
    } finally {
      setBusy(false);
    }
  });

  btnOpen.addEventListener('click', async () => {
    setBusy(true);
    try {
      await window.electronAPI.openApp();
    } catch (error) {
      log(`Open failed: ${error.message || error}`);
    } finally {
      setBusy(false);
    }
  });

  await runChecks();
}

async function runChecks() {
  setBusy(true);
  stepsEl.innerHTML = '';
  stepNodes.clear();
  log('--- running checks ---');
  try {
    const report = await window.electronAPI.runCheck();
    lastCheckOk = report.ok;
    if (report.blockers?.length) {
      report.blockers.forEach((b) => {
        log(`BLOCKER: ${b.blocker}`);
        if (b.fix) log(b.fix);
      });
    } else {
      log('All required checks passed.');
    }
    btnInstall.disabled = !lastCheckOk;
  } catch (error) {
    log(`Check failed: ${error.message || error}`);
    lastCheckOk = false;
    btnInstall.disabled = true;
  } finally {
    setBusy(false);
  }
}

init();
