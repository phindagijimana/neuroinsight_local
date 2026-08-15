'use strict';

/**
 * Headless E2E: same orchestrator logic as the Electron desktop app (Node + mocked electron.app).
 * Usage: node scripts/e2e-test.js
 */

const path = require('path');
const os = require('os');
const Module = require('module');

const userData = path.join(os.tmpdir(), `neuroinsight-autohs-e2e-${Date.now()}`);
const projectRoot = path.resolve(__dirname, '../..');

Module.prototype.require = new Proxy(Module.prototype.require, {
  apply(target, thisArg, args) {
    if (args[0] === 'electron') {
      return {
        app: {
          isPackaged: false,
          getPath: (name) => (name === 'userData' ? userData : os.tmpdir()),
          whenReady: () => Promise.resolve(),
          getVersion: () => '1.1.0',
        },
      };
    }
    return Reflect.apply(target, thisArg, args);
  },
});

const orchestrator = require('../src/orchestrator');
const { findLicensePath } = require('../src/orchestrator/license');

function log(msg) {
  process.stdout.write(`${msg}\n`);
}

async function main() {
  log('=== NeuroInsight-AutoHS Desktop E2E (orchestrator) ===\n');
  log(`userData: ${userData}`);
  log(`projectRoot: ${projectRoot}`);

  const license = findLicensePath(userData, projectRoot);
  log(`license: ${license || 'NOT FOUND'}`);
  if (!license) {
    throw new Error('Place license.txt in ~/Documents or repo root');
  }

  log('\n--- Preflight (9 steps) ---');
  const report = await orchestrator.runCheck((step) => {
    log(`  [${step.step}/${step.total}] ${step.label}: ${step.status}${step.detail ? ` — ${step.detail}` : ''}`);
  });
  if (!report.ok) {
    log('\nPreflight FAILED');
    for (const b of report.blockers || []) log(`  BLOCKER: ${b}`);
    process.exit(1);
  }
  log('\nPreflight OK\n');

  log('--- Install / ensure running ---');
  const runtime = await orchestrator.ensureRunning({
    onProgress: (line) => log(`  ${line}`),
  });
  log(`\nRuntime: web=${runtime.webUrl} api=${runtime.backendUrl}\n`);

  const status = await orchestrator.getStatus();
  log(`Status: exists=${status.exists} running=${status.running} port=${status.webPort}`);

  log('\n--- HTTP checks ---');
  const health = await fetch(`${runtime.webUrl.replace(/\/$/, '')}/health`, { signal: AbortSignal.timeout(15000) });
  log(`  GET /health → ${health.status}`);
  const home = await fetch(runtime.webUrl, { signal: AbortSignal.timeout(15000) });
  log(`  GET / → ${home.status}`);
  const body = await home.text();
  const hasBrand = body.includes('NeuroInsight-AutoHS') || body.includes('NeuroInsightAutoHS');
  log(`  UI branding present: ${hasBrand}`);

  log('\n=== E2E PASSED ===');
}

main().catch((err) => {
  log(`\n=== E2E FAILED: ${err.message} ===`);
  if (err.stack) log(err.stack);
  process.exit(1);
});
