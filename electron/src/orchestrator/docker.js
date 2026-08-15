'use strict';

const { execFile, spawn } = require('child_process');
const { promisify } = require('util');

const execFileAsync = promisify(execFile);

function dockerBin() {
  return process.platform === 'win32' ? 'docker.exe' : 'docker';
}

function platformArgs() {
  if (process.arch === 'arm64') {
    return ['--platform', 'linux/amd64'];
  }
  return [];
}

function dockerSocketArgs() {
  if (process.platform === 'win32') {
    return ['-v', '//var/run/docker.sock:/var/run/docker.sock'];
  }
  return ['-v', '/var/run/docker.sock:/var/run/docker.sock'];
}

async function runDocker(args, options = {}) {
  const bin = dockerBin();
  const fullArgs = [...args];
  try {
    const { stdout, stderr } = await execFileAsync(bin, fullArgs, {
      encoding: 'utf8',
      maxBuffer: 20 * 1024 * 1024,
      ...options,
    });
    return { stdout: stdout || '', stderr: stderr || '', ok: true };
  } catch (error) {
    return {
      stdout: error.stdout || '',
      stderr: error.stderr || error.message || '',
      ok: false,
      code: error.code,
    };
  }
}

function spawnDocker(args, onData) {
  const bin = dockerBin();
  return new Promise((resolve, reject) => {
    const child = spawn(bin, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    const handle = (chunk) => {
      if (onData) onData(chunk.toString());
    };
    child.stdout.on('data', handle);
    child.stderr.on('data', handle);
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`docker exited with code ${code}`));
    });
  });
}

async function dockerInfo() {
  const result = await runDocker(['info']);
  return result.ok;
}

async function containerExists(name) {
  const result = await runDocker(['ps', '-a', '--format', '{{.Names}}']);
  if (!result.ok) return false;
  return result.stdout.split('\n').some((line) => line.trim() === name);
}

async function containerRunning(name) {
  const result = await runDocker(['ps', '--format', '{{.Names}}']);
  if (!result.ok) return false;
  return result.stdout.split('\n').some((line) => line.trim() === name);
}

async function getContainerPort(name, containerPort) {
  const result = await runDocker(['port', name, String(containerPort)]);
  if (!result.ok) return null;
  const line = result.stdout.trim().split('\n')[0];
  if (!line) return null;
  const parts = line.split(':');
  return parts[parts.length - 1] || null;
}

async function stopContainer(name) {
  await runDocker(['stop', name]);
}

async function removeContainer(name) {
  await runDocker(['rm', '-f', name]);
}

async function startContainer(name) {
  return runDocker(['start', name]);
}

module.exports = {
  dockerBin,
  platformArgs,
  dockerSocketArgs,
  runDocker,
  spawnDocker,
  dockerInfo,
  containerExists,
  containerRunning,
  getContainerPort,
  stopContainer,
  removeContainer,
  startContainer,
};
