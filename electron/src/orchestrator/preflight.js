'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');
const {
  MIN_DISK_GB,
  MIN_RAM_GB,
  FREESURFER_IMAGE,
  IMAGE_NAME,
} = require('./constants');
const { dockerInfo, runDocker } = require('./docker');
const { findWebPort, findMinioPorts } = require('./ports');
const { findLicensePath } = require('./license');

const TOTAL_STEPS = 9;

async function runPreflight({ userDataDir, projectRoot, entrypointPath, onStep }) {
  const steps = [];
  let stepNum = 0;

  const emit = (label, status, detail, blocker = null, fix = null) => {
    stepNum += 1;
    const entry = {
      step: stepNum,
      total: TOTAL_STEPS,
      label,
      status,
      detail,
      blocker,
      fix,
    };
    steps.push(entry);
    if (onStep) onStep(entry);
    return entry;
  };

  // 1. Docker CLI
  let dockerCli = false;
  try {
    execFileSync(process.platform === 'win32' ? 'docker.exe' : 'docker', ['--version'], {
      stdio: 'ignore',
    });
    dockerCli = true;
    emit('Checking Docker installation', 'ok', 'Docker CLI found');
  } catch {
    emit(
      'Checking Docker installation',
      'fail',
      'Docker CLI not found',
      'Docker is not installed',
      'Install Docker Desktop:\nhttps://www.docker.com/products/docker-desktop/'
    );
  }

  // 2. Docker daemon
  if (dockerCli) {
    const running = await dockerInfo();
    if (running) {
      emit('Checking Docker daemon', 'ok', 'Docker daemon is running');
    } else {
      emit(
        'Checking Docker daemon',
        'fail',
        'Docker daemon is not running',
        'Docker daemon is not running',
        process.platform === 'darwin'
          ? 'Start Docker Desktop from Applications, then retry.'
          : 'Start Docker Desktop or run: sudo systemctl start docker'
      );
    }
  } else {
    emit('Checking Docker daemon', 'fail', 'Skipped (Docker not installed)');
  }

  // 3. License
  const licensePath = findLicensePath(userDataDir, projectRoot);
  if (licensePath) {
    emit('Checking FreeSurfer license.txt', 'ok', `Valid license at ${licensePath}`);
  } else {
    const recommended = projectRoot
      ? path.join(projectRoot, 'license.txt')
      : path.join(userDataDir, 'license.txt');
    emit(
      'Checking FreeSurfer license.txt',
      'fail',
      'license.txt not found',
      'FreeSurfer license.txt not found',
      `Place your license here (recommended):\n  ${recommended}\n\nOr use the button below to select your license file.\n\nGet a free research license:\nhttps://surfer.nmr.mgh.harvard.edu/registration.html`
    );
  }

  // 4. Web port
  const webPort = await findWebPort();
  if (webPort) {
    emit('Checking web UI port (8000-8050)', 'ok', `Port ${webPort} available`);
  } else {
    emit(
      'Checking web UI port (8000-8050)',
      'fail',
      'No free port',
      'No free port for web UI (8000-8050)',
      'Stop other services using ports 8000-8050.'
    );
  }

  // 5. MinIO ports
  const minioPorts = await findMinioPorts();
  if (minioPorts) {
    emit(
      'Checking MinIO ports (9000-9050)',
      'ok',
      `Ports ${minioPorts.apiPort} and ${minioPorts.consolePort} available`
    );
  } else {
    emit(
      'Checking MinIO ports (9000-9050)',
      'fail',
      'No free MinIO ports',
      'No free ports for MinIO (9000-9050)',
      'Stop other services using ports 9000-9050.'
    );
  }

  // 6. Entrypoint
  if (entrypointPath && fs.existsSync(entrypointPath)) {
    emit('Checking macOS Docker Desktop entrypoint fix', 'ok', 'entrypoint.sh bundled');
  } else {
    emit(
      'Checking macOS Docker Desktop entrypoint fix',
      'warn',
      'entrypoint.sh missing — macOS installs may fail'
    );
  }

  // 7. curl equivalent — always ok on desktop (we use fetch)
  emit('Checking network tools', 'ok', 'HTTP client available');

  // 8. Disk
  try {
    const stats = fs.statfsSync ? fs.statfsSync(os.homedir()) : null;
    if (stats && stats.bavail && stats.bsize) {
      const freeGb = Math.floor((stats.bavail * stats.bsize) / 1024 ** 3);
      if (freeGb < MIN_DISK_GB) {
        emit(
          'Checking disk space',
          'warn',
          `${freeGb}GB free (recommend ${MIN_DISK_GB}GB+)`
        );
      } else {
        emit('Checking disk space', 'ok', `${freeGb}GB free`);
      }
    } else {
      emit('Checking disk space', 'ok', 'Disk check skipped');
    }
  } catch {
    emit('Checking disk space', 'ok', 'Disk check skipped');
  }

  // 9. RAM
  const totalMemGb = Math.floor(os.totalmem() / 1024 ** 3);
  if (totalMemGb < MIN_RAM_GB) {
    emit(
      'Checking system memory',
      'warn',
      `${totalMemGb}GB RAM (recommend ${MIN_RAM_GB}GB+)`
    );
  } else {
    emit('Checking system memory', 'ok', `${totalMemGb}GB RAM`);
  }

  const blockers = steps.filter((s) => s.blocker);
  return {
    ok: blockers.length === 0,
    steps,
    blockers,
    licensePath,
    webPort,
    minioPorts,
    images: { app: IMAGE_NAME, freesurfer: FREESURFER_IMAGE },
  };
}

module.exports = { runPreflight, TOTAL_STEPS };
