// API configuration
export const API_BASE_URL = (() => {
  // For development (port 5173), use the proxied backend
  // For production (port 8000), use the same origin
  if (window.location.port === '5173') {
    // Vite dev server proxies /api/* to port 8001 (development backend)
    return `${window.location.protocol}//${window.location.hostname}:8001`;
  } else {
    // Production mode - use same origin
    return `${window.location.protocol}//${window.location.hostname}:${window.location.port || '8000'}`;
  }
})();

// API service functions
const normalizeStatus = (status) => {
  if (!status) return 'queued';
  const normalized = String(status).toLowerCase();
  if (normalized === 'running' || normalized === 'processing') return 'processing';
  if (normalized === 'pending') return 'pending';
  if (normalized === 'queued') return 'pending';
  if (normalized === 'completed') return 'completed';
  if (normalized === 'failed') return 'failed';
  return 'queued';
};

const normalizeJob = (job) => {
  if (!job || typeof job !== 'object') return job;
  return {
    ...job,
    status: normalizeStatus(job.status)
  };
};

export const apiService = {
  async getJobs() {
    try {
      console.log('Fetching jobs from:', `${API_BASE_URL}/api/jobs/`);
      const response = await fetch(`${API_BASE_URL}/api/jobs/`);
      console.log('Response status:', response.status, response.statusText);
      if (!response.ok) {
        const errorText = await response.text();
        console.error('API Error:', errorText);
        throw new Error(`Failed to fetch jobs: ${response.status} ${response.statusText}`);
      }
      const data = await response.json();
      console.log('API returned data:', data);
      console.log('Jobs array:', data.jobs);
      console.log('Number of jobs:', data.jobs?.length || 0);
      // Extract jobs array from the response wrapper
      const jobs = data.jobs || [];
      return jobs.map(normalizeJob);
    } catch (error) {
      console.error('Failed to load jobs:', error);
      console.error('Error details:', error.message);
      // Show error in UI but don't block the page
      return [];
    }
  },

  async getJob(jobId) {
    try {
      const response = await fetch(`${API_BASE_URL}/api/jobs/${jobId}`);
      if (!response.ok) throw new Error('Failed to fetch job');
      const job = await response.json();
      return normalizeJob(job);
    } catch (error) {
      console.error('Failed to get job:', error);
      return null;
    }
  },

  async uploadFile(file, patientInfo = {}) {
    return new Promise((resolve, reject) => {
      const formData = new FormData();
      formData.append('file', file);

      // Send patient information as JSON string (backend expects 'patient_data' field)
      // This matches the format from index.dev.html
      formData.append('patient_data', JSON.stringify(patientInfo));
      console.log('Sending patient_data:', JSON.stringify(patientInfo));

      const xhr = new XMLHttpRequest();

      xhr.upload.addEventListener('progress', (event) => {
        if (event.lengthComputable) {
          const percentComplete = (event.loaded / event.total) * 100;
          // Progress callback could be added here
        }
      });

      xhr.addEventListener('load', () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            const response = JSON.parse(xhr.responseText);
            resolve(response);
          } catch (e) {
            resolve(xhr.responseText);
          }
        } else {
          reject(new Error(`Upload failed: ${xhr.status} ${xhr.statusText}`));
        }
      });

      xhr.addEventListener('error', () => {
        reject(new Error('Upload failed due to network error'));
      });

      xhr.addEventListener('abort', () => {
        reject(new Error('Upload was cancelled'));
      });

      console.log('Uploading to:', `${API_BASE_URL}/api/upload/`);
      xhr.open('POST', `${API_BASE_URL}/api/upload/`);
      xhr.send(formData);
    });
  },

  async deleteJob(jobId) {
    try {
      console.log('Deleting job:', jobId);
      const response = await fetch(`${API_BASE_URL}/api/jobs/delete/${jobId}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Failed to delete job: ${response.status} ${response.statusText}`);
      }

      // Backend returns 204 No Content for successful deletion
      console.log('Job deleted successfully:', jobId);
      return { success: true };
    } catch (error) {
      console.error('Failed to delete job:', error);
      throw error;
    }
  }
};

export default apiService;
