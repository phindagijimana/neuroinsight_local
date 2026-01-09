import React, { useState } from 'react';
import type { Job } from '../types';
import { apiService } from '../services/api';
import { Trash2 } from './icons/Trash2';

interface JobListProps {
  jobs: Job[];
  onJobSelect: (job: Job) => void;
  onBack: () => void;
  onJobDeleted?: () => void;
}

export const JobList: React.FC<JobListProps> = ({ jobs, onJobSelect, onBack, onJobDeleted }) => {
  const [deletingJobs, setDeletingJobs] = useState<Set<string>>(new Set());

  const handleDeleteJob = async (jobId: string, e: React.MouseEvent) => {
    e.stopPropagation(); // Prevent triggering the row click

    if (deletingJobs.has(jobId)) return;

    if (!confirm('Are you sure you want to delete this job? This action cannot be undone.')) {
      return;
    }

    setDeletingJobs(prev => new Set(prev).add(jobId));

    try {
      await apiService.deleteJob(jobId);
      console.log('Job deleted successfully:', jobId);
      if (onJobDeleted) {
        onJobDeleted();
      }
    } catch (error) {
      console.error('Failed to delete job:', error);
      alert('Failed to delete job. Please try again.');
    } finally {
      setDeletingJobs(prev => {
        const newSet = new Set(prev);
        newSet.delete(jobId);
        return newSet;
      });
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

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-gray-900">MRI Processing Jobs</h2>
        <button
          onClick={onBack}
          className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
        >
          ← Back to Home
        </button>
      </div>

      {jobs.length === 0 ? (
        <div className="text-center py-8">
          <p className="text-gray-500">No jobs found. Upload an MRI file to get started.</p>
        </div>
      ) : (
        <div className="bg-white shadow overflow-hidden sm:rounded-md">
          <ul className="divide-y divide-gray-200">
            {jobs.map((job) => (
              <li key={job.id} className="px-6 py-4 hover:bg-gray-50 cursor-pointer" onClick={() => onJobSelect(job)}>
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <div className="flex items-center">
                      <p className="text-sm font-medium text-gray-900 truncate">
                        Job {job.id.slice(-8)}
                      </p>
                      <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(job.status)}`}>
                        {job.status}
                      </span>
                    </div>
                    <div className="mt-1 flex items-center text-sm text-gray-500">
                      <p>Created: {formatDate(job.created_at)}</p>
                      {job.progress !== undefined && (
                        <span className="ml-4">Progress: {job.progress}%</span>
                      )}
                    </div>
                    {job.input_file && (
                      <p className="mt-1 text-sm text-gray-500 truncate">
                        File: {job.input_file}
                      </p>
                    )}
                  </div>
                  <div className="flex-shrink-0 flex items-center space-x-3">
                    <button
                      className={`text-sm font-medium px-3 py-1 rounded-md transition-colors ${
                        job.status === 'failed'
                          ? 'text-red-700 bg-red-50 hover:bg-red-100 border border-red-200'
                          : 'text-gray-700 bg-gray-50 hover:bg-gray-100 border border-gray-200'
                      }`}
                      onClick={(e) => {
                        e.stopPropagation();
                        onJobSelect(job);
                      }}
                    >
                      View Details →
                    </button>

                    <button
                      className={`p-2 rounded-md transition-colors ${
                        deletingJobs.has(job.id)
                          ? 'text-gray-400 cursor-not-allowed'
                          : job.status === 'failed'
                          ? 'text-red-600 hover:text-red-800 hover:bg-red-50'
                          : 'text-gray-400 hover:text-red-600 hover:bg-red-50'
                      }`}
                      onClick={(e) => handleDeleteJob(job.id, e)}
                      disabled={deletingJobs.has(job.id)}
                      title={job.status === 'failed' ? 'Delete failed job' : 'Delete job'}
                    >
                      {deletingJobs.has(job.id) ? (
                        <svg className="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                      ) : (
                        <Trash2 className="h-4 w-4" />
                      )}
                    </button>
                  </div>
                </div>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};


interface JobListProps {
  jobs: Job[];
  onJobSelect: (job: Job) => void;
  onBack: () => void;
  onJobDeleted?: () => void;
}





