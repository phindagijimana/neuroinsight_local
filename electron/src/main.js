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

/** @type {BrowserWindow | null} */
let mainWindow = null;
/** @type {{ webUrl: string, backendUrl: string, webPort: number } | null} */
let runtime = null;

const isDev = !app.isPackaged;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 860,
    minWidth: 960,
    minHeight: 640,
    title: 'NeuroInsight',
    show: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  });

  mainWindow.once('ready-to-show', () => mainWindow?.show());
  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  loadSetupPage();
}

function loadSetupPage() {
  if (!mainWindow) return;
  mainWindow.loadFile(path.join(__dirname, '../renderer/setup.html'));
}

async function loadAppUi(webUrl, backendUrl) {
  if (!mainWindow) return;
  runtime = { webUrl, backendUrl, webPort: new URL(webUrl).port || '8000' };

  await mainWindow.loadURL(webUrl);
  await mainWindow.webContents.executeJavaScript(
    `window.BACKEND_URL = ${JSON.stringify(backendUrl)};`,
    true
  );
}

function send(channel, payload) {
  mainWindow?.webContents.send(channel, payload);
}

function buildMenu() {
  const template = [
    {
      label: 'NeuroInsight',
      submenu: [
        {
          label: 'Run setup checks',
          click: () => loadSetupPage(),
        },
        {
          label: 'Open Docker troubleshooting',
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
    const saved = saveLicenseFromFile(
      result.filePaths[0],
      orchestrator.getUserDataDir()
    );
    return saved;
  });

  ipcMain.handle('setup:check', async () => {
    const steps = [];
    const report = await orchestrator.runCheck((step) => {
      steps.push(step);
      send('setup:step', step);
    });
    return report;
  });

  ipcMain.handle('setup:install', async () => {
    send('setup:log', 'Installing NeuroInsight container...');
    const result = await orchestrator.installContainer({
      onProgress: (line) => send('setup:log', line),
    });
    runtime = result;
    return result;
  });

  ipcMain.handle('setup:start', async () => {
    send('setup:log', 'Starting NeuroInsight...');
    const result = await orchestrator.ensureRunning({
      onProgress: (line) => send('setup:log', line),
    });
    runtime = result;
    return result;
  });

  ipcMain.handle('setup:open-app', async () => {
    const status = runtime || (await orchestrator.getStatus());
    if (!status?.webUrl) {
      throw new Error('NeuroInsight is not running');
    }
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

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

if (isDev) {
  app.commandLine.appendSwitch('ignore-certificate-errors');
}
