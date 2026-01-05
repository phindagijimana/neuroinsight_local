// Type definitions for NeuroInsight

export interface Job {
  id: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  created_at: string;
  updated_at: string;
  input_file?: string;
  output_files?: string[];
  file_name?: string;
  progress?: number;
  error_message?: string;
}

export interface ApiResponse<T> {
  data?: T;
  error?: string;
  message?: string;
}

export interface Config {
  api: {
    baseUrl: string;
  };
  ui: {
    refreshInterval: number;
    maxUploadSize: number;
  };
  environment: 'development' | 'production';
}
