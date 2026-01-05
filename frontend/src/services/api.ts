import type { Job } from '../types';
import { CONFIG } from '../utils/config';

/**
 * API Service - Centralized API communication layer
 */
export class ApiService {
  private baseUrl: string;

  constructor() {
    this.baseUrl = CONFIG.API_BASE_URL;
  }

  /**
   * Fetch all jobs from the API
   */
  async getJobs(): Promise<Job[]> {
    try {
      console.log('Fetching jobs from:', `${this.baseUrl}/jobs/`);
      const response = await fetch(`${this.baseUrl}/jobs/`);
      console.log('Response status:', response.status, response.statusText);

      if (!response.ok) {
        const errorText = await response.text();
        console.error('API Error:', errorText);
        throw new Error(`Failed to fetch jobs: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      console.log('API returned jobs:', data);
      console.log('Number of jobs:', data?.length || 0);
      return data || [];
    } catch (error) {
      console.error('Error fetching jobs:', error);
      throw error;
    }
  }

  /**
   * Get a specific job by ID
   */
  async getJob(jobId: string): Promise<Job | null> {
    try {
      console.log('Fetching job:', jobId);
      const response = await fetch(`${this.baseUrl}/jobs/${jobId}`);

      if (!response.ok) {
        if (response.status === 404) {
          return null;
        }
        const errorText = await response.text();
        console.error('API Error:', errorText);
        throw new Error(`Failed to fetch job: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      console.log('Job data:', data);
      return data;
    } catch (error) {
      console.error('Error fetching job:', error);
      throw error;
    }
  }

  /**
   * Upload a file for processing
   */
  async uploadFile(file: File): Promise<{ job_id: string }> {
    try {
      const formData = new FormData();
      formData.append('file', file);

      console.log('Uploading file:', file.name, 'Size:', file.size);
      const response = await fetch(`${this.baseUrl}/upload/`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Upload error:', errorText);
        throw new Error(`Upload failed: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      console.log('Upload successful, job ID:', data.job_id);
      return data;
    } catch (error) {
      console.error('Error uploading file:', error);
      throw error;
    }
  }

  /**
   * Get health status
   */
  async getHealth(): Promise<{ status: string }> {
    try {
      const response = await fetch(`${this.baseUrl}/health`);
      if (!response.ok) {
        throw new Error(`Health check failed: ${response.status}`);
      }
      return await response.json();
    } catch (error) {
      console.error('Health check error:', error);
      throw error;
    }
  }
}

// Export singleton instance
export const apiService = new ApiService();


/**
 * API Service - Centralized API communication layer
 */













