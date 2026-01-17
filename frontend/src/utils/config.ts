// Frontend configuration
export const CONFIG = {
  API_BASE_URL: (import.meta as any).env?.VITE_API_BASE_URL || 'http://localhost:8000',
  API_VERSION: 'v1',

  // File upload settings
  MAX_FILE_SIZE: 1073741824, // 1GB
  ALLOWED_EXTENSIONS: ['.nii', '.nii.gz', '.dcm', '.dicom'] as readonly string[],

  // UI settings
  POLLING_INTERVAL: 5000, // 5 seconds
  DEFAULT_TIMEOUT: 300000, // 5 minutes

  // Development settings
  DEBUG: (import.meta as any).env?.DEV || false,
} as const;

export default CONFIG;







