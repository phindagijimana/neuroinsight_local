import React, { useState, useEffect } from 'react';
import type { Job } from '../types';
import { apiService } from '../services/api';

interface JobViewerProps {
  job: Job | null;
  onBack: () => void;
}

export const JobViewer: React.FC<JobViewerProps> = ({ job, onBack }) => {
  const [jobDetails, setJobDetails] = useState<Job | null>(job);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (job?.id) {
      loadJobDetails();
    }
  }, [job?.id]);

  const loadJobDetails = async () => {
    if (!job?.id) return;

    setLoading(true);
    try {
      const details = await apiService.getJob(job.id);
      setJobDetails(details);
    } catch (error) {
      console.error('Failed to load job details:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: Job['status']) => {
    switch (status) {
      case 'completed':
        return 'text-green-600 bg-green-100';
      case 'running':
        return 'text-blue-800 bg-blue-100';
      case 'failed':
        return 'text-red-600 bg-red-100';
      case 'pending':
        return 'text-yellow-600 bg-yellow-100';
      default:
        return 'text-gray-600 bg-gray-100';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  if (!jobDetails) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold text-gray-900">Job Details</h2>
          <button
            onClick={onBack}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
          >
            ← Back to Jobs
          </button>
        </div>
        <div className="text-center py-8">
          <p className="text-gray-500">No job selected</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900">Job Details</h2>
        <button
          onClick={onBack}
          className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
        >
          ← Back to Jobs
        </button>
      </div>

      <div className="bg-white shadow overflow-hidden sm:rounded-lg">
        <div className="px-4 py-5 sm:px-6">
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div>
              <dt className="text-sm font-medium text-gray-500">Job ID</dt>
              <dd className="mt-1 text-sm text-gray-900">{jobDetails.id}</dd>
            </div>
            <div>
              <dt className="text-sm font-medium text-gray-500">Status</dt>
              <dd className="mt-1">
                <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(jobDetails.status)}`}>
                  {jobDetails.status.toUpperCase()}
                </span>
              </dd>
            </div>
            <div>
              <dt className="text-sm font-medium text-gray-500">Created</dt>
              <dd className="mt-1 text-sm text-gray-900">
                {formatDate(jobDetails.created_at)}
              </dd>
            </div>
            <div>
              <dt className="text-sm font-medium text-gray-500">Progress</dt>
              <dd className="mt-1">
                <div className="flex items-center">
                  <div className="flex-1 bg-gray-200 rounded-full h-2 mr-2">
                    <div
                      className="bg-blue-800 h-2 rounded-full"
                      style={{ width: `${jobDetails.progress || 0}%` }}
                    ></div>
                  </div>
                  <span className="text-sm text-gray-600">
                    {jobDetails.progress || 0}%
                  </span>
                </div>
              </dd>
            </div>
          </div>

          {jobDetails.file_name && (
            <div className="mt-6">
              <dt className="text-sm font-medium text-gray-500">File Name</dt>
              <dd className="mt-1 text-sm text-gray-900">{jobDetails.file_name}</dd>
            </div>
          )}

          {jobDetails.error_message && (
            <div className="mt-6">
              <dt className="text-sm font-medium text-red-500">Error Message</dt>
              <dd className="mt-1 text-sm text-red-900 bg-red-50 p-3 rounded">
                {jobDetails.error_message}
              </dd>
            </div>
          )}

          {loading && (
            <div className="mt-6 text-center">
              <div className="inline-flex items-center px-4 py-2 text-sm text-gray-700">
                <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-gray-700" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                Loading job details...
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};















