'use strict';

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  getBackendURL: () => ipcRenderer.invoke('backend:get-url'),
  getAppVersion: () => ipcRenderer.invoke('app:get-version'),
  getPaths: () => ipcRenderer.invoke('app:get-paths'),
  pickLicense: () => ipcRenderer.invoke('license:pick'),
  runCheck: () => ipcRenderer.invoke('setup:check'),
  runInstall: () => ipcRenderer.invoke('setup:install'),
  runStart: () => ipcRenderer.invoke('setup:start'),
  openApp: () => ipcRenderer.invoke('setup:open-app'),
  openExternal: (url) => ipcRenderer.invoke('shell:open-external', url),
  onSetupStep: (callback) => {
    const listener = (_event, step) => callback(step);
    ipcRenderer.on('setup:step', listener);
    return () => ipcRenderer.removeListener('setup:step', listener);
  },
  onSetupLog: (callback) => {
    const listener = (_event, line) => callback(line);
    ipcRenderer.on('setup:log', listener);
    return () => ipcRenderer.removeListener('setup:log', listener);
  },
});
