'use strict';

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  getBackendURL: () => ipcRenderer.invoke('backend:get-url'),
  getAppVersion: () => ipcRenderer.invoke('app:get-version'),
  getPaths: () => ipcRenderer.invoke('app:get-paths'),
  pickLicense: () => ipcRenderer.invoke('license:pick'),
  retryBootstrap: () => ipcRenderer.invoke('setup:retry'),
  openApp: () => ipcRenderer.invoke('setup:open-app'),
  openExternal: (url) => ipcRenderer.invoke('shell:open-external', url),
  onSetupPhase: (callback) => {
    const listener = (_event, payload) => callback(payload);
    ipcRenderer.on('setup:phase', listener);
    return () => ipcRenderer.removeListener('setup:phase', listener);
  },
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
