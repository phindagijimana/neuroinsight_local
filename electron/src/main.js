'use strict';

const path = require('path');
const {
  app,
  BrowserWindow,
  ipcMain,
  dialog,
  shell,
  Menu,
} = require('electron');
const orchestrator = require('./orchestrator');
const { saveLicenseFromFile, recommendedLicensePath } = require('./orchestrator/license');
const {
  friendlyCheckMessage,
  friendlyProgress,
  primaryBlocker,
} = require('./bootstrap-messages');

/** @type {BrowserWindow | null} */
let mainWindow = null;
/** @type {{ webUrl: string, backendUrl: string, webPort: number } | null} */
let runtime = null;
let bootstrapRunning = false;

const SPLASH = { width: 440, height: 380 };
const APP = { width: 1280, height: 860, minWidth: 960, minHeight: 640 };

if (process.platform === 'darwin') {
  app.setName('NeuroInsight-AutoHS');
}

function send(channel, payload) {
  mainWindow?.webContents.send(channel, payload);
}

function sendPhase(phase, message, extra = {}) {
  send('setup:phase', { phase, message, ...extra });
}

async function waitForHealthy(webUrl, attempts = 12) {
  const base = webUrl.replace(/\/$/, '');
  for (let i = 0; i < attempts; i += 1) {
    try {
      const response = await fetch(`${base}/health`, { signal: AbortSignal.timeout(4000) });
      if (response.ok) return true;
    } catch {
      // retry
    }
    // eslint-disable-next-line no-await-in-loop
    await new Promise((r) => setTimeout(r, 1500));
  }
  return false;
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: SPLASH.width,
    height: SPLASH.height,
    minWidth: SPLASH.width,
    minHeight: SPLASH.height,
    resizable: false,
    title: 'NeuroInsight-AutoHS',
    show: false,
    center: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  mainWindow.loadFile(path.join(__dirname, '../renderer/setup.html'));
}

function resizeForApp() {
  if (!mainWindow) return;
  mainWindow.setMinimumSize(APP.minWidth, APP.minHeight);
  mainWindow.setResizable(true);
  mainWindow.setSize(APP.width, APP.height);
  mainWindow.center();
}

async function loadAppUi(webUrl, backendUrl) {
  if (!mainWindow) return;
  runtime = { webUrl, backendUrl, webPort: new URL(webUrl).port || '8000' };
  resizeForApp();
  await mainWindow.loadURL(webUrl);
  await mainWindow.webContents.executeJavaScript(
    `window.BACKEND_URL = ${JSON.stringify(backendUrl)};`,
    true
  );
}

async function tryConnectExisting() {
  const status = await orchestrator.getStatus();
  if (!status.running || !status.webUrl) return false;

  sendPhase('connecting', 'Connecting to NeuroInsight-AutoHS…');
  const healthy = await waitForHealthy(status.webUrl);
  if (!healthy) return false;

  await loadAppUi(status.webUrl, status.backendUrl);
  return true;
}

async function runBootstrap() {
  if (bootstrapRunning) return { ok: false, reason: 'busy' };
  bootstrapRunning = true;

  try {
    sendPhase('checking', 'Checking your system…');

    const report = await orchestrator.runCheck((step) => {
      send('setup:step', step);
      if (step.status !== 'fail') {
        sendPhase('checking', friendlyCheckMessage(step));
      }
    });

    if (!report.ok) {
      const summary = primaryBlocker(report.blockers);
      sendPhase('blocked', summary.message, {
        title: summary.title,
        message: summary.message,
        action: summary.action,
        fix: summary.fix,
        blockers: report.blockers,
      });
      return { ok: false, blockers: report.blockers };
    }

    sendPhase('starting', 'Starting NeuroInsight-AutoHS…');

    const result = await orchestrator.ensureRunning({
      onProgress: (line) => {
        send('setup:log', line);
        sendPhase('starting', friendlyProgress(line));
      },
    });

    runtime = result;
    sendPhase('starting', 'Opening NeuroInsight-AutoHS…');
    await loadAppUi(result.webUrl, result.backendUrl);
    return { ok: true, ...result };
  } catch (error) {
    sendPhase('error', error.message || 'NeuroInsight-AutoHS could not start.');
    return { ok: false, error };
  } finally {
    bootstrapRunning = false;
  }
}

async function startApplication() {
  let splashShown = false;
  const splashTimer = setTimeout(() => {
    if (!splashShown && mainWindow && !mainWindow.isVisible()) {
      mainWindow.show();
      splashShown = true;
    }
  }, 700);

  try {
    if (await tryConnectExisting()) {
      clearTimeout(splashTimer);
      mainWindow?.show();
      return;
    }
  } catch {
    // fall through to full bootstrap
  }

  clearTimeout(splashTimer);
  if (!splashShown) mainWindow?.show();
  await runBootstrap();
}

function buildMenu() {
  const template = [
    {
      label: 'NeuroInsight-AutoHS',
      submenu: [
        {
          label: 'Restart',
          click: async () => {
            if (!mainWindow) return;
            runtime = null;
            mainWindow.setMinimumSize(SPLASH.width, SPLASH.height);
            mainWindow.setSize(SPLASH.width, SPLASH.height);
            mainWindow.setResizable(false);
            mainWindow.center();
            await mainWindow.loadFile(path.join(__dirname, '../renderer/setup.html'));
            mainWindow.webContents.once('did-finish-load', () => startApplication());
          },
        },
        {
          label: 'Docker troubleshooting',
          click: () =>
            shell.openExternal(
              'https://github.com/phindagijimana/neuroinsight_local/blob/master/deploy/DOCKER_SOCKET_FIX.md'
            ),
        },
        { type: 'separator' },
        { role: 'quit' },
      ],
    },
    {
      label: 'View',
      submenu: [{ role: 'reload' }, { role: 'toggleDevTools' }, { role: 'resetZoom' }],
    },
  ];
  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

function registerIpc() {
  ipcMain.handle('app:get-version', () => app.getVersion());

  ipcMain.handle('app:get-paths', () => ({
    userData: orchestrator.getUserDataDir(),
    projectRoot: orchestrator.getProjectRoot(),
    recommendedLicense: recommendedLicensePath(
      orchestrator.getUserDataDir(),
      orchestrator.getProjectRoot()
    ),
    isPackaged: app.isPackaged,
  }));

  ipcMain.handle('license:pick', async () => {
    const result = await dialog.showOpenDialog(mainWindow, {
      title: 'Select FreeSurfer license.txt',
      properties: ['openFile'],
      filters: [{ name: 'License', extensions: ['txt'] }],
    });
    if (result.canceled || !result.filePaths[0]) return null;
    return saveLicenseFromFile(result.filePaths[0], orchestrator.getUserDataDir());
  });

  ipcMain.handle('setup:bootstrap', () => runBootstrap());
  ipcMain.handle('setup:retry', () => runBootstrap());

  ipcMain.handle('setup:open-app', async () => {
    const status = runtime || (await orchestrator.getStatus());
    if (!status?.webUrl) throw new Error('NeuroInsight-AutoHS is not running');
    await loadAppUi(status.webUrl, status.backendUrl);
    return status;
  });

  ipcMain.handle('backend:get-url', async () => {
    if (runtime?.backendUrl) return runtime.backendUrl;
    const status = await orchestrator.getStatus();
    if (status.backendUrl) {
      runtime = status;
      return status.backendUrl;
    }
    throw new Error('Backend URL not available');
  });

  ipcMain.handle('shell:open-external', (_event, url) => shell.openExternal(url));
}

app.whenReady().then(() => {
  buildMenu();
  registerIpc();
  createWindow();
  mainWindow?.webContents.once('did-finish-load', () => startApplication());

  app.on('activate', async () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
      mainWindow?.webContents.once('did-finish-load', () => startApplication());
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

if (!app.isPackaged) {
  app.commandLine.appendSwitch('ignore-certificate-errors');
}
