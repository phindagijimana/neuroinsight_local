'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

const EXAMPLE_MARKERS = [
  'REPLACE THIS EXAMPLE CONTENT',
  'FreeSurfer License File - EXAMPLE',
];

function isExampleLicense(content) {
  return EXAMPLE_MARKERS.some((marker) => content.includes(marker));
}

function licenseCandidates(userDataDir, projectRoot) {
  const home = os.homedir();
  const list = [];
  if (userDataDir) {
    list.push(path.join(userDataDir, 'license.txt'));
  }
  if (projectRoot) {
    list.push(path.join(projectRoot, 'license.txt'));
  }
  list.push(
    path.join(home, 'Documents', 'license.txt'),
    path.join(home, 'license.txt')
  );
  return list;
}

function findLicensePath(userDataDir, projectRoot) {
  for (const candidate of licenseCandidates(userDataDir, projectRoot)) {
    if (!fs.existsSync(candidate)) continue;
    const content = fs.readFileSync(candidate, 'utf8');
    if (isExampleLicense(content)) continue;
    return candidate;
  }
  return null;
}

function saveLicenseFromFile(sourcePath, userDataDir) {
  fs.mkdirSync(userDataDir, { recursive: true });
  const dest = path.join(userDataDir, 'license.txt');
  fs.copyFileSync(sourcePath, dest);
  return dest;
}

function recommendedLicensePath(userDataDir, projectRoot) {
  if (projectRoot) return path.join(projectRoot, 'license.txt');
  return path.join(userDataDir, 'license.txt');
}

module.exports = {
  findLicensePath,
  saveLicenseFromFile,
  recommendedLicensePath,
  isExampleLicense,
  licenseCandidates,
};
