'use strict';

const CONTAINER_NAME = 'neuroinsight';
const IMAGE_NAME = 'phindagijimana321/neuroinsight:latest';
const FREESURFER_IMAGE = process.env.FREESURFER_IMAGE || 'freesurfer/freesurfer:7.4.1';
const VOLUME_NAME = 'neuroinsight-data';
const MIN_DISK_GB = Number(process.env.NEUROINSIGHT_MIN_DISK_GB || 50);
const MIN_RAM_GB = Number(process.env.NEUROINSIGHT_MIN_RAM_GB || 16);
const WEB_PORT_MIN = 8000;
const WEB_PORT_MAX = 8050;
const MINIO_PORT_MIN = 9000;
const MINIO_PORT_MAX = 9050;

module.exports = {
  CONTAINER_NAME,
  IMAGE_NAME,
  FREESURFER_IMAGE,
  VOLUME_NAME,
  MIN_DISK_GB,
  MIN_RAM_GB,
  WEB_PORT_MIN,
  WEB_PORT_MAX,
  MINIO_PORT_MIN,
  MINIO_PORT_MAX,
};
