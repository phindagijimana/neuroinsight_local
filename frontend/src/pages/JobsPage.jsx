import { useState } from 'react'
import { apiService, API_BASE_URL } from '../utils/api.js'
import Activity from '../components/icons/Activity.jsx'
import Eye from '../components/icons/Eye.jsx'
import FileText from '../components/icons/FileText.jsx'
import Trash2 from '../components/icons/Trash2.jsx'
import Upload from '../components/icons/Upload.jsx'

function JobsPage({ setActivePage, setSelectedJobId, jobs, jobsLoading, onJobsUpdate, lastRefreshTime, isRefreshing }) {
  const [deletingId, setDeletingId] = useState(null)

  const handleDelete = async (jobId, e) => {
    e.stopPropagation()
    if (deletingId) return
    if (!confirm('Are you sure you want to delete this job? This action cannot be undone.')) return
    setDeletingId(jobId)
    try {
      await apiService.deleteJob(jobId)
      if (onJobsUpdate) onJobsUpdate(true)
    } catch (err) {
      console.error('Delete failed:', err)
      alert('Failed to delete job. Please try again.')
    } finally {
      setDeletingId(null)
    }
  }

  const handleGeneratePdf = async (jobId, e) => {
    e.stopPropagation()
    try {
      const response = await fetch(`${API_BASE_URL}/api/reports/${jobId}/pdf`)
      if (!response.ok) throw new Error('Report failed')
      const blob = await response.blob()
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `neuroinsight_report_${jobId}.pdf`
      a.click()
      URL.revokeObjectURL(url)
    } catch (err) {
      console.error('Report failed:', err)
      alert('Failed to generate report. Please try again.')
    }
  }

  const formatDate = (dateString) => {
    if (!dateString) return '—'
    return new Date(dateString).toLocaleString()
  }

  const getStatusClass = (status) => {
    const s = (status || '').toLowerCase()
    if (s === 'completed') return 'text-green-700 bg-green-100'
    if (s === 'running' || s === 'processing') return 'text-blue-700 bg-blue-100'
    if (s === 'failed') return 'text-red-700 bg-red-100'
    if (s === 'pending') return 'text-yellow-700 bg-yellow-100'
    return 'text-gray-700 bg-gray-100'
  }

  return (
    <div className="max-w-7xl mx-auto px-6 py-8">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">MRI Processing Jobs</h2>
        <div className="flex items-center gap-3">
          {lastRefreshTime && (
            <span className="text-sm text-gray-500">
              Updated {lastRefreshTime.toLocaleTimeString()}
            </span>
          )}
          <button
            type="button"
            onClick={() => onJobsUpdate && onJobsUpdate(true)}
            disabled={isRefreshing}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
          >
            {isRefreshing ? 'Refreshing...' : 'Refresh'}
          </button>
          <button
            type="button"
            onClick={() => setActivePage('home')}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
          >
            Back to Home
          </button>
        </div>
      </div>

      {jobsLoading ? (
        <p className="text-gray-600">Loading jobs...</p>
      ) : !jobs || jobs.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg border border-gray-200">
          <Upload className="w-12 h-12 mx-auto text-gray-400 mb-3" />
          <p className="text-gray-500">No jobs yet. Upload an MRI file from Home to get started.</p>
        </div>
      ) : (
        <div className="bg-white shadow overflow-hidden sm:rounded-md">
          <ul className="divide-y divide-gray-200">
            {jobs.map((job) => {
              const isCompleted = (job.status || '').toLowerCase() === 'completed'
              const jobId = job.id

              return (
                <li
                  key={jobId}
                  className="px-6 py-4 hover:bg-gray-50 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-sm font-medium text-gray-900 truncate">
                        Job {String(jobId).slice(-8)}
                      </span>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusClass(job.status)}`}>
                        {job.status || 'pending'}
                      </span>
                    </div>
                    <div className="mt-1 flex items-center gap-4 text-sm text-gray-500 flex-wrap">
                      <span>Created: {formatDate(job.created_at)}</span>
                      {job.progress != null && <span>Progress: {job.progress}%</span>}
                    </div>
                    {job.input_file && (
                      <p className="mt-1 text-sm text-gray-500 truncate">File: {job.input_file}</p>
                    )}
                  </div>

                  {/* Action buttons: horizontal row, same line as job on desktop */}
                  <div className="flex flex-shrink-0 flex-row flex-wrap items-center gap-2">
                    {isCompleted ? (
                      <>
                        <button
                          type="button"
                          onClick={(e) => { e.stopPropagation(); setSelectedJobId(jobId); setActivePage('dashboard'); }}
                          className="inline-flex items-center gap-1.5 text-sm font-medium px-3 py-1.5 rounded-md text-gray-700 bg-gray-50 hover:bg-gray-100 border border-gray-200"
                        >
                          <Activity className="w-4 h-4" />
                          View Statistics
                        </button>
                        <button
                          type="button"
                          onClick={(e) => { e.stopPropagation(); setSelectedJobId(jobId); setActivePage('viewer'); }}
                          className="inline-flex items-center gap-1.5 text-sm font-medium px-3 py-1.5 rounded-md text-gray-700 bg-gray-50 hover:bg-gray-100 border border-gray-200"
                        >
                          <Eye className="w-4 h-4" />
                          View 2D Slices
                        </button>
                        <button
                          type="button"
                          onClick={(e) => handleGeneratePdf(jobId, e)}
                          className="inline-flex items-center gap-1.5 text-sm font-medium px-3 py-1.5 rounded-md text-gray-700 bg-gray-50 hover:bg-gray-100 border border-gray-200"
                        >
                          <FileText className="w-4 h-4" />
                          Generate PDF Report
                        </button>
                      </>
                    ) : (
                      <button
                        type="button"
                        onClick={(e) => { e.stopPropagation(); setSelectedJobId(jobId); setActivePage('dashboard'); }}
                        className="inline-flex items-center gap-1.5 text-sm font-medium px-3 py-1.5 rounded-md text-gray-700 bg-gray-50 hover:bg-gray-100 border border-gray-200"
                      >
                        View Details
                      </button>
                    )}
                    <button
                      type="button"
                      onClick={(e) => handleDelete(jobId, e)}
                      disabled={deletingId === jobId}
                      title="Delete job"
                      className="p-2 rounded-md text-gray-400 hover:text-red-600 hover:bg-red-50 disabled:opacity-50"
                    >
                      {deletingId === jobId ? (
                        <span className="inline-block w-4 h-4 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin" />
                      ) : (
                        <Trash2 className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </li>
              )
            })}
          </ul>
        </div>
      )}
    </div>
  )
}

export default JobsPage
