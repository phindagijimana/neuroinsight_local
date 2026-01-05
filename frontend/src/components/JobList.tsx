import React from 'react';
import type { Job } from '../types';

interface JobListProps {
  jobs: Job[];
  onJobSelect: (job: Job) => void;
  onBack: () => void;
}

export const JobList: React.FC<JobListProps> = ({ jobs, onJobSelect, onBack }) => {
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
                  <div className="flex-shrink-0">
                    <button
                      className="text-blue-800 hover:text-blue-900 text-sm font-medium"
                      onClick={(e) => {
                        e.stopPropagation();
                        onJobSelect(job);
                      }}
                    >
                      View Details →
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
}





