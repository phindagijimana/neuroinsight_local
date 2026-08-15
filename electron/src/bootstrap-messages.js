'use strict';

function friendlyCheckMessage(step) {
  const label = (step.label || '').toLowerCase();
  if (label.includes('docker installation')) return 'Checking Docker…';
  if (label.includes('docker daemon')) return 'Checking Docker is running…';
  if (label.includes('license')) return 'Checking FreeSurfer license…';
  if (label.includes('port')) return 'Checking available ports…';
  if (label.includes('disk')) return 'Checking disk space…';
  if (label.includes('memory')) return 'Checking system memory…';
  return 'Checking your system…';
}

function friendlyProgress(line) {
  const text = String(line || '').toLowerCase();
  if (text.includes('pulling')) {
    return 'Downloading components… First launch may take several minutes.';
  }
  if (text.includes('creating') || text.includes('container')) {
    return 'Preparing NeuroInsight-AutoHS…';
  }
  if (text.includes('waiting') || text.includes('web ui')) {
    return 'Almost ready…';
  }
  if (text.includes('already running') || text.includes('starting existing')) {
    return 'Connecting to NeuroInsight-AutoHS…';
  }
  if (text.includes('removing')) return 'Updating installation…';
  return 'Starting NeuroInsight-AutoHS…';
}

function primaryBlocker(blockers) {
  if (!blockers?.length) {
    return {
      title: 'Setup incomplete',
      message: 'Something prevented NeuroInsight-AutoHS from starting.',
      action: 'retry',
    };
  }

  const first = blockers[0];
  const text = `${first.blocker || ''} ${first.label || ''}`.toLowerCase();

  if (text.includes('license')) {
    return {
      title: 'FreeSurfer license needed',
      message:
        'Place your FreeSurfer license.txt file on this computer, or choose it below. A free research license is available from the FreeSurfer team.',
      action: 'license',
      fix: first.fix,
    };
  }
  if (text.includes('docker') && text.includes('not installed')) {
    return {
      title: 'Docker Desktop required',
      message:
        'NeuroInsight-AutoHS uses Docker to run MRI processing. Install Docker Desktop, open it, then try again.',
      action: 'docker-install',
      fix: first.fix,
    };
  }
  if (text.includes('daemon') || text.includes('not running')) {
    return {
      title: 'Start Docker Desktop',
      message: 'Docker is installed but not running. Open Docker Desktop and wait until it is ready, then try again.',
      action: 'retry',
      fix: first.fix,
    };
  }
  if (text.includes('port')) {
    return {
      title: 'Ports in use',
      message:
        'Another application is using ports NeuroInsight-AutoHS needs (8000 or 9000 range). Close conflicting apps and try again.',
      action: 'retry',
      fix: first.fix,
    };
  }

  return {
    title: 'Unable to start',
    message: first.blocker || 'NeuroInsight-AutoHS could not start.',
    action: 'retry',
    fix: first.fix,
  };
}

module.exports = {
  friendlyCheckMessage,
  friendlyProgress,
  primaryBlocker,
};
