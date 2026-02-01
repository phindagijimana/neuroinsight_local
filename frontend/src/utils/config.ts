// Frontend configuration
export const CONFIG = {
  // API Base URL - uses window.location.origin for automatic port detection
  // This allows backend to start on any available port (8000-8050) and frontend adapts automatically
  // Since frontend is served from the backend, they're always on the same origin/port
  API_BASE_URL: (import.meta as any).env?.VITE_API_BASE_URL || window.location.origin,
  API_VERSION: 'v1',

  // File upload settings
  MAX_FILE_SIZE: 1073741824, // 1GB
  ALLOWED_EXTENSIONS: ['.nii', '.nii.gz'] as readonly string[],

  // UI settings
  POLLING_INTERVAL: 5000, // 5 seconds
  DEFAULT_TIMEOUT: 300000, // 5 minutes

  // Development settings
  DEBUG: (import.meta as any).env?.DEV || false,
} as const;

export default CONFIG;







