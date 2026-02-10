import { useState } from 'react'
import { apiService, API_BASE_URL } from '../utils/api.js'
import Activity from '../components/icons/Activity.jsx'
import Eye from '../components/icons/Eye.jsx'
import FileText from '../components/icons/FileText.jsx'
import Trash2 from '../components/icons/Trash2.jsx'
import Upload from '../components/icons/Upload.jsx'
import Clock from '../components/icons/Clock.jsx'
import CheckCircle from '../components/icons/CheckCircle.jsx'
import XCircle from '../components/icons/XCircle.jsx'
import AlertCircle from '../components/icons/AlertCircle.jsx'
import Brain from '../components/icons/Brain.jsx'

function JobsPage({ setActivePage, setSelectedJobId, jobs, jobsLoading, onJobsUpdate, lastRefreshTime, isRefreshing }) {
  const [deletingId, setDeletingId] = useState(null)
  const [selectedFile, setSelectedFile] = useState(null)
  const [uploadProgress, setUploadProgress] = useState(null)
  const [isDragging, setIsDragging] = useState(false)
  const [patientInfo, setPatientInfo] = useState({
    patient_name: '',
    patient_id: '',
    notes: ''
  })

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

  const handleFileSelect = (e) => {
    const file = e.target.files?.[0]
    if (file) {
      const valid = ['.nii', '.nii.gz'].some(f => file.name.toLowerCase().endsWith(f))
      if (valid) setSelectedFile(file)
      else alert('Invalid file format. Please upload .nii or .nii.gz files.')
    }
  }

  const handleDrop = (e) => {
    e.preventDefault()
    setIsDragging(false)
    const file = e.dataTransfer.files?.[0]
    if (file) {
      const valid = ['.nii', '.nii.gz'].some(f => file.name.toLowerCase().endsWith(f))
      if (valid) setSelectedFile(file)
      else alert('Invalid file format. Please upload .nii or .nii.gz files.')
    }
  }

  const handleUpload = async () => {
    if (!selectedFile) return
    try {
      setUploadProgress(0)
      const payload = {
        patient_name: patientInfo.patient_name || selectedFile.name.replace(/\.(nii|nii\.gz|mgz)$/i, ''),
        patient_id: patientInfo.patient_id || `WEB_${Date.now()}`,
        notes: patientInfo.notes || 'Uploaded via web interface'
      }
      await apiService.uploadFile(selectedFile, payload)
      setSelectedFile(null)
      setUploadProgress(null)
      setPatientInfo({ patient_name: '', patient_id: '', notes: '' })
      if (onJobsUpdate) onJobsUpdate(true)
    } catch (err) {
      console.error('Upload failed:', err)
      setUploadProgress(null)
      alert('Upload failed. Please try again.')
    }
  }

  const handlePatientInfoChange = (field, value) => {
    setPatientInfo(prev => ({ ...prev, [field]: value }))
  }

  const safeJobs = Array.isArray(jobs) ? jobs : []
  const stats = {
    total: safeJobs.length,
    completed: safeJobs.filter(j => (j?.status || '').toLowerCase() === 'completed').length,
    processing: safeJobs.filter(j => ['running', 'processing'].includes((j?.status || '').toLowerCase())).length,
    pending: safeJobs.filter(j => (j?.status || '').toLowerCase() === 'pending').length,
    failed: safeJobs.filter(j => (j?.status || '').toLowerCase() === 'failed').length
  }

  const getStatusIcon = (status) => {
    const s = (status || '').toLowerCase()
    if (s === 'completed') return <CheckCircle className="w-5 h-5 text-green-600" />
    if (s === 'running' || s === 'processing') return <Clock className="w-5 h-5 text-blue-600 animate-spin" />
    if (s === 'pending') return <Clock className="w-5 h-5 text-yellow-600" />
    if (s === 'failed') return <XCircle className="w-5 h-5 text-red-600" />
    return <AlertCircle className="w-5 h-5 text-gray-400" />
  }

  const getStatusColor = (status) => {
    const s = (status || '').toLowerCase()
    if (s === 'completed') return 'bg-green-50 text-green-700 border-green-200'
    if (s === 'running' || s === 'processing') return 'bg-blue-50 text-blue-700 border-blue-200'
    if (s === 'pending') return 'bg-yellow-50 text-yellow-700 border-yellow-200'
    if (s === 'failed') return 'bg-red-50 text-red-700 border-red-200'
    return 'bg-gray-50 text-gray-700 border-gray-200'
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-white">
      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Upload section - match native */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-2xl font-bold text-gray-900">Upload New MRI Scan</h2>
            <div className="flex items-center gap-3">
              {lastRefreshTime && (
                <span className="text-sm text-gray-500">Updated {lastRefreshTime.toLocaleTimeString()}</span>
              )}
              <button
                type="button"
                onClick={() => onJobsUpdate && onJobsUpdate(true)}
                disabled={isRefreshing}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
              >
                {isRefreshing ? 'Refreshing...' : 'Refresh'}
              </button>
              <button
                type="button"
                onClick={() => setActivePage('home')}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Back to Home
              </button>
            </div>
          </div>
          <p className="text-gray-600 mb-6">Upload T1-weighted MRI scans in NIfTI format (.nii or .nii.gz)</p>

          {/* Patient info (optional) */}
          <div className="bg-white rounded-xl shadow-sm border border-blue-100 p-6 mb-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <Brain className="w-5 h-5 text-blue-600" />
              Patient Information
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Patient Name</label>
                <input
                  type="text"
                  value={patientInfo.patient_name}
                  onChange={(e) => handlePatientInfoChange('patient_name', e.target.value)}
                  placeholder="Enter patient name"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Patient ID</label>
                <input
                  type="text"
                  value={patientInfo.patient_id}
                  onChange={(e) => handlePatientInfoChange('patient_id', e.target.value)}
                  placeholder="Enter patient ID"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Notes</label>
                <input
                  type="text"
                  value={patientInfo.notes}
                  onChange={(e) => handlePatientInfoChange('notes', e.target.value)}
                  placeholder="Additional notes (optional)"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </div>
          </div>

          {/* Drag-drop upload zone */}
          <div
            onDrop={handleDrop}
            onDragOver={(e) => { e.preventDefault(); setIsDragging(true) }}
            onDragLeave={() => setIsDragging(false)}
            className={`border-2 border-dashed rounded-2xl p-12 transition border-blue-200 bg-white hover:border-blue-400 hover:bg-blue-50 ${isDragging ? 'border-blue-400 bg-blue-50' : ''}`}
          >
            <div className="text-center space-y-4">
              <div className="flex justify-center">
                <div className="bg-blue-100 p-6 rounded-full">
                  <Upload className="w-12 h-12 text-blue-600" />
                </div>
              </div>
              <div>
                <p className="text-xl font-semibold text-gray-900 mb-2">
                  {selectedFile ? selectedFile.name : 'Drop your T1-weighted MRI scan here'}
                </p>
                <p className="text-gray-500">or click to browse files</p>
              </div>
              <label className="inline-block">
                <input
                  type="file"
                  accept=".nii,.nii.gz"
                  onChange={handleFileSelect}
                  className="hidden"
                />
                <span className="mt-4 px-6 py-3 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition cursor-pointer inline-block">
                  Select Files
                </span>
              </label>
              <p className="text-xs text-gray-400 mt-4">Accepted formats: .nii, .nii.gz</p>
            </div>
          </div>
          {uploadProgress !== null && (
            <div className="mt-4">
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm font-medium text-gray-700">Uploading...</span>
                <span className="text-sm font-medium text-gray-700">{uploadProgress}%</span>
              </div>
              <div className="w-full bg-gray-200 rounded-full h-2">
                <div className="bg-blue-600 h-2 rounded-full transition-all" style={{ width: `${uploadProgress}%` }} />
              </div>
            </div>
          )}
          <button
            onClick={handleUpload}
            disabled={!selectedFile || uploadProgress !== null}
            className="mt-4 w-full px-6 py-3 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition disabled:bg-gray-300 disabled:cursor-not-allowed"
          >
            Start Processing
          </button>
        </div>

        {/* Stats cards - match native */}
        <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-8">
          {[
            { label: 'Total Jobs', value: String(stats.total), icon: FileText, bgColor: 'bg-blue-100', iconColor: 'text-blue-600' },
            { label: 'Completed', value: String(stats.completed), icon: CheckCircle, bgColor: 'bg-green-100', iconColor: 'text-green-600' },
            { label: 'Processing', value: String(stats.processing), icon: Clock, bgColor: 'bg-blue-100', iconColor: 'text-blue-600' },
            { label: 'Pending', value: String(stats.pending), icon: Clock, bgColor: 'bg-yellow-100', iconColor: 'text-yellow-600' },
            { label: 'Failed', value: String(stats.failed), icon: XCircle, bgColor: 'bg-red-100', iconColor: 'text-red-600' }
          ].map((stat, idx) => (
            <div key={idx} className="bg-white rounded-xl p-6 shadow-sm border border-blue-100">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-500 mb-1">{stat.label}</p>
                  <p className="text-3xl font-bold text-gray-900">{stat.value}</p>
                </div>
                <div className={`${stat.bgColor} p-3 rounded-lg`}>
                  <stat.icon className={`w-6 h-6 ${stat.iconColor}`} />
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Recent Jobs - match native */}
        <div className="bg-white rounded-xl shadow-sm border border-blue-100 overflow-hidden">
          <div className="px-6 py-4 border-b border-blue-100 flex items-center justify-between">
            <h2 className="text-xl font-bold text-gray-900">Recent Jobs</h2>
            <div className="text-sm text-gray-500">
              Showing {safeJobs.length} job{safeJobs.length !== 1 ? 's' : ''}
              {stats.completed > 0 && ` (${stats.completed} completed)`}
            </div>
          </div>

          {jobsLoading && safeJobs.length === 0 ? (
            <div className="p-12 text-center">
              <Clock className="w-8 h-8 animate-spin mx-auto mb-4 text-blue-600" />
              <p className="text-gray-600">Loading jobs...</p>
            </div>
          ) : safeJobs.length === 0 ? (
            <div className="p-12 text-center text-gray-500">
              <FileText className="w-12 h-12 mx-auto mb-4 opacity-50" />
              <p className="text-lg font-semibold mb-2">No jobs found</p>
              <p className="text-sm">Try uploading a file above to get started.</p>
            </div>
          ) : (
            <div className="divide-y divide-blue-100">
              {safeJobs.map((job) => {
                const jobId = job.id
                const status = (job.status || 'pending').toLowerCase()
                const isCompleted = status === 'completed'
                const progress = job.progress ?? (status === 'completed' ? 100 : status === 'processing' || status === 'running' ? 50 : 0)
                const filename = job.input_file || job.filename || `Job ${String(jobId).slice(-8)}`
                return (
                  <div key={jobId} className="p-6 hover:bg-blue-50 transition">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-4 flex-1">
                        {getStatusIcon(job.status)}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-3 mb-2 flex-wrap">
                            <h3 className="font-semibold text-gray-900 truncate">{filename}</h3>
                            <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${getStatusColor(job.status)}`}>
                              {(job.status || 'pending').toUpperCase()}
                            </span>
                          </div>
                          <div className="flex items-center gap-4 text-sm text-gray-600 flex-wrap">
                            <span>ID: {jobId}</span>
                            <span>•</span>
                            <span>Created: {formatDate(job.created_at)}</span>
                            {job.completed_at && (
                              <>
                                <span>•</span>
                                <span>Completed: {formatDate(job.completed_at)}</span>
                              </>
                            )}
                          </div>
                          {(status === 'processing' || status === 'running' || status === 'pending') && (
                            <div className="mt-3">
                              <div className="flex items-center justify-between mb-1">
                                <span className="text-sm text-gray-600">
                                  {status === 'pending' ? 'Queued for processing' : 'Processing...'}
                                </span>
                                <span className={`text-sm font-semibold ${status === 'pending' ? 'text-yellow-600' : 'text-blue-600'}`}>
                                  {status === 'pending' ? 'Queued' : `${progress}%`}
                                </span>
                              </div>
                              <div className="w-full bg-gray-200 rounded-full h-2">
                                <div
                                  className={`h-2 rounded-full transition-all duration-500 ${status === 'pending' ? 'bg-yellow-600' : 'bg-blue-600'}`}
                                  style={{ width: `${progress}%` }}
                                />
                              </div>
                            </div>
                          )}
                          {status === 'failed' && job.error_message && (
                            <div className="mt-3 max-h-52 overflow-auto bg-red-50 border border-red-200 rounded-lg p-3">
                              <p className="text-sm text-red-800 font-semibold">Job Failed</p>
                              <details className="text-xs mt-1">
                                <summary className="cursor-pointer text-red-700 font-semibold">Show error details</summary>
                                <pre className="mt-2 p-2 bg-red-100 rounded overflow-auto max-h-32 border border-red-200">{job.error_message}</pre>
                              </details>
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="flex items-center gap-2 ml-4 flex-shrink-0">
                        {isCompleted ? (
                          <>
                            <button
                              onClick={() => { setSelectedJobId(jobId); setActivePage('dashboard') }}
                              className="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition"
                              title="View Statistics"
                            >
                              <Activity className="w-5 h-5" />
                            </button>
                            <button
                              onClick={() => { setSelectedJobId(jobId); setActivePage('viewer') }}
                              className="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition"
                              title="View 2D Slices"
                            >
                              <Eye className="w-5 h-5" />
                            </button>
                            <button
                              onClick={(e) => handleGeneratePdf(jobId, e)}
                              className="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition"
                              title="Generate PDF Report"
                            >
                              <FileText className="w-5 h-5" />
                            </button>
                          </>
                        ) : (
                          <button
                            onClick={() => { setSelectedJobId(jobId); setActivePage('dashboard') }}
                            className="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition"
                            title="View Details"
                          >
                            <Eye className="w-5 h-5" />
                          </button>
                        )}
                        <button
                          onClick={(e) => handleDelete(jobId, e)}
                          disabled={deletingId === jobId}
                          className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition disabled:opacity-50"
                          title="Delete job"
                        >
                          {deletingId === jobId ? (
                            <span className="inline-block w-5 h-5 border-2 border-gray-300 border-t-gray-600 rounded-full animate-spin" />
                          ) : (
                            <Trash2 className="w-5 h-5" />
                          )}
                        </button>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default JobsPage
