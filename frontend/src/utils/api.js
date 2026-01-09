// API configuration
export const API_BASE_URL = (() => {
  // Check if running in Electron desktop mode (window.electronAPI is set by preload)
  if (window.electronAPI && window.electronAPI.getBackendURL) {
    // We'll fetch this asynchronously, but for now return a placeholder
    // The actual URL will be fetched when needed
    return 'http://localhost:8001'; // Placeholder, will be replaced
  }
  
  // Since frontend is served by FastAPI backend, API is on the same port
  const apiUrl = `${window.location.protocol}//${window.location.hostname}:${window.location.port || (window.location.protocol === 'https:' ? '443' : '80')}`;
  
  // Allow override via query parameter: ?api=http://localhost:8000
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('api')) {
    return urlParams.get('api');
  }
  
  console.log('Web mode detected, using API URL:', apiUrl);
  return apiUrl;
})();

// API service functions
export const apiService = {
  async getJobs() {
    try {
      console.log('Fetching jobs from:', `${API_BASE_URL}/jobs/`);
      const response = await fetch(`${API_BASE_URL}/jobs/`);
      console.log('Response status:', response.status, response.statusText);
      if (!response.ok) {
        const errorText = await response.text();
        console.error('API Error:', errorText);
        throw new Error(`Failed to fetch jobs: ${response.status} ${response.statusText}`);
      }
      const data = await response.json();
      console.log('API returned jobs:', data);
      console.log('Number of jobs:', data?.length || 0);
      return data;
    } catch (error) {
      console.error('Failed to load jobs:', error);
      console.error('Error details:', error.message);
      // Show error in UI but don't block the page
      return [];
    }
  },

  async getJob(jobId) {
    try {
      const response = await fetch(`${API_BASE_URL}/jobs/${jobId}`);
      if (!response.ok) throw new Error('Failed to fetch job');
      return await response.json();
    } catch (error) {
      console.error('Failed to get job:', error);
      return null;
    }
  },

  async uploadFile(file, patientInfo = {}) {
    return new Promise((resolve, reject) => {
      const formData = new FormData();
      formData.append('file', file);

      // Add patient information to form data
      if (patientInfo.patient_name) formData.append('patient_name', patientInfo.patient_name);
      if (patientInfo.age) formData.append('patient_age', patientInfo.age);
      if (patientInfo.sex) formData.append('patient_sex', patientInfo.sex);
      if (patientInfo.scanner) formData.append('scanner_info', patientInfo.scanner);
      if (patientInfo.sequence) formData.append('sequence_info', patientInfo.sequence);
      if (patientInfo.notes) formData.append('notes', patientInfo.notes);

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

      console.log('Uploading to:', `${API_BASE_URL}/upload/`);
      xhr.open('POST', `${API_BASE_URL}/upload/`);
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
