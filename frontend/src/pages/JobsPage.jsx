import { useState, useEffect } from 'react'
import { apiService, API_BASE_URL } from '../utils/api.js'
import Brain from '../components/icons/Brain.jsx'
import Upload from '../components/icons/Upload.jsx'
import Eye from '../components/icons/Eye.jsx'
import Activity from '../components/icons/Activity.jsx'
import Download from '../components/icons/Download.jsx'
import FileText from '../components/icons/FileText.jsx'
import CheckCircle from '../components/icons/CheckCircle.jsx'
import Clock from '../components/icons/Clock.jsx'
import XCircle from '../components/icons/XCircle.jsx'
import Trash2 from '../components/icons/Trash2.jsx'

function JobsPage({ setActivePage, setSelectedJobId, jobs, jobsLoading, onJobsUpdate, lastRefreshTime, isRefreshing }) {
  const [selectedFile, setSelectedFile] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(null);
  const [isDragging, setIsDragging] = useState(false);
  const [patientInfo, setPatientInfo] = useState({
    patient_name: '',
    age: '',
    sex: '',
    scanner: '',
    sequence: '',
    notes: ''
  });
  const [stats, setStats] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  // Calculate statistics whenever jobs change
  useEffect(() => {
    if (jobs.length > 0) {
      const stats = {
        total: jobs.length,
        completed: jobs.filter(job => job.status === 'completed').length,
        processing: jobs.filter(job => job.status === 'processing' || job.status === 'running').length,
        pending: jobs.filter(job => job.status === 'pending').length,
        failed: jobs.filter(job => job.status === 'failed').length
      };
      setStats(stats);
    }
  }, [jobs]);

  const handleRefresh = async () => {
    setRefreshing(true);
    await onJobsUpdate();
    setTimeout(() => setRefreshing(false), 500); // Show refresh indicator briefly
  };

  const handleFileSelect = (event) => {
    const file = event.target.files[0];
    if (file) {
      setSelectedFile(file);
    }
  };

  const handleDrop = (event) => {
    event.preventDefault();
    setIsDragging(false);

    const files = event.dataTransfer.files;
    if (files.length > 0) {
      const file = files[0];
      // Check file extension
      const allowedExtensions = ['.nii', '.nii.gz', '.dcm', '.dicom'];
      const fileName = file.name.toLowerCase();
      const isAllowed = allowedExtensions.some(ext => fileName.endsWith(ext));

      if (isAllowed) {
        setSelectedFile(file);
      } else {
        alert('Please select a valid MRI file (.nii, .nii.gz, .dcm, .dicom)');
      }
    }
  };

  const handleDragOver = (event) => {
    event.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handlePatientInfoChange = (field, value) => {
    setPatientInfo(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleUpload = async () => {
    if (!selectedFile) return;

    try {
      setUploadProgress(0);
      const result = await apiService.uploadFile(selectedFile, patientInfo);
      console.log('Upload successful:', result);
      setUploadProgress(100);
      setSelectedFile(null);
      // Clear patient info after successful upload
      setPatientInfo({
        patient_name: '',
        age: '',
        sex: '',
        scanner: '',
        sequence: '',
        notes: ''
      });
      // Refresh jobs list
      await onJobsUpdate();
      setTimeout(() => setUploadProgress(null), 2000);
    } catch (error) {
      console.error('Upload failed:', error);
      alert('Upload failed: ' + error.message);
      setUploadProgress(null);
    }
  };


  const generateReport = async (jobId) => {
    try {
      const response = await fetch(`${API_BASE_URL}/reports/${jobId}/pdf`);
      if (response.ok) {
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `neuroinsight_report_${jobId}.pdf`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
      } else {
        alert('Failed to generate report. Please try again.');
      }
    } catch (error) {
      console.error('Report generation failed:', error);
      alert('Failed to generate report. Please try again.');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-white">
      <div className="max-w-6xl mx-auto px-6 py-8">

        {/* Upload Section */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Upload New MRI Scan</h2>
          <p className="text-gray-600 mb-6">Upload T1-weighted MRI scans in DICOM or NIfTI format</p>

          {/* Patient Information Section */}
          <div className="bg-white rounded-xl shadow-sm border border-blue-100 p-6 mb-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <Brain className="w-5 h-5 text-blue-800" />
              Patient Information
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Patient Name *
                </label>
                <input
                  type="text"
                  value={patientInfo.patient_name}
                  onChange={(e) => handlePatientInfoChange('patient_name', e.target.value)}
                  placeholder="Enter patient name"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-800 focus:border-blue-900"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Age
                </label>
                <input
                  type="number"
                  value={patientInfo.age}
                  onChange={(e) => handlePatientInfoChange('age', e.target.value)}
                  placeholder="Enter age"
                  min="0"
                  max="120"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-800 focus:border-blue-900"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Sex
                </label>
                <select
                  value={patientInfo.sex}
                  onChange={(e) => handlePatientInfoChange('sex', e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-800 focus:border-blue-900"
                >
                  <option value="">Select...</option>
                  <option value="M">Male</option>
                  <option value="F">Female</option>
                  <option value="Other">Other</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Scanner
                </label>
                <input
                  type="text"
                  value={patientInfo.scanner}
                  onChange={(e) => handlePatientInfoChange('scanner', e.target.value)}
                  placeholder="e.g., Siemens, GE, Philips"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-800 focus:border-blue-900"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Sequence
                </label>
                <input
                  type="text"
                  value={patientInfo.sequence}
                  onChange={(e) => handlePatientInfoChange('sequence', e.target.value)}
                  placeholder="e.g., T1w, T2w, FLAIR"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-800 focus:border-blue-900"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Notes
                </label>
                <input
                  type="text"
                  value={patientInfo.notes}
                  onChange={(e) => handlePatientInfoChange('notes', e.target.value)}
                  placeholder="Additional notes (optional)"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-800 focus:border-blue-900"
                />
              </div>
            </div>
          </div>

          {/* File Upload Section */}
          <div
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            className={`border-2 border-dashed rounded-2xl p-12 transition-all duration-200 border-blue-200 bg-white hover:border-blue-400 hover:bg-blue-50 ${isDragging ? 'border-blue-400 bg-blue-50 scale-105' : ''}`}
          >
            <div className="text-center space-y-4">
              <div className="flex justify-center">
                <div className="bg-blue-100 p-6 rounded-full">
                  <Upload className="w-12 h-12 text-blue-800" />
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
                  accept=".nii,.nii.gz,.dcm,.dicom"
                  onChange={handleFileSelect}
                  className="hidden"
                />
                <span className="mt-4 px-6 py-3 bg-blue-800 text-white rounded-lg font-semibold hover:bg-blue-900 transition cursor-pointer inline-block">
                  Select Files
                </span>
              </label>
              <p className="text-xs text-gray-400 mt-4">
                Accepted formats: .dcm, .nii, .nii.gz • Max size: 500MB
              </p>
            </div>
          </div>

          <button
            onClick={handleUpload}
            disabled={!selectedFile || uploadProgress !== null || !patientInfo.patient_name.trim()}
            className="mt-4 w-full px-6 py-3 bg-blue-800 text-white rounded-lg font-semibold hover:bg-blue-900 transition disabled:bg-gray-300 disabled:cursor-not-allowed"
          >
            {uploadProgress !== null ? `Processing... ${uploadProgress}%` : 'Start Processing'}
          </button>

          {!patientInfo.patient_name.trim() && selectedFile && (
            <p className="text-sm text-red-600 mt-2 text-center">Patient name is required</p>
          )}

          {/* Statistics Dashboard */}
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-8">
            {[
              { label: 'Total Jobs', value: (stats?.total ?? 0).toString(), icon: FileText, bgColor: 'bg-blue-100', iconColor: 'text-blue-800' },
              { label: 'Completed', value: (stats?.completed ?? 0).toString(), icon: CheckCircle, bgColor: 'bg-green-100', iconColor: 'text-green-600' },
              { label: 'Processing', value: (stats?.processing ?? 0).toString(), icon: Clock, bgColor: 'bg-blue-100', iconColor: 'text-blue-800' },
              { label: 'Pending', value: (stats?.pending ?? 0).toString(), icon: Clock, bgColor: 'bg-yellow-100', iconColor: 'text-yellow-600' },
              { label: 'Failed', value: (stats?.failed ?? 0).toString(), icon: XCircle, bgColor: 'bg-red-100', iconColor: 'text-red-600' }
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
        </div>

        {/* Jobs List */}
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
          <div className="px-6 py-4 border-b border-blue-100 flex items-center justify-between">
            <h2 className="text-xl font-bold text-gray-900">Recent Jobs</h2>
            <div className="flex items-center gap-4">
              {lastRefreshTime && (
                <div className="text-xs text-gray-500 flex items-center gap-1">
                  <div className={`w-2 h-2 rounded-full ${isRefreshing ? 'bg-blue-400 animate-pulse' : 'bg-green-400'}`}></div>
                  Updated {lastRefreshTime.toLocaleTimeString()}
                </div>
              )}
              <button
                onClick={() => onJobsUpdate(true)}
                disabled={isRefreshing}
                className="flex items-center gap-2 px-3 py-1 text-sm bg-blue-50 hover:bg-blue-100 text-blue-700 rounded-lg transition disabled:opacity-50"
                title="Refresh job list"
              >
                <div className={`w-4 h-4 border-2 border-blue-600 border-t-transparent rounded-full transition-opacity ${isRefreshing ? 'animate-spin opacity-100' : 'opacity-0'}`}></div>
                {isRefreshing ? 'Refreshing...' : 'Refresh'}
              </button>
            </div>
          </div>

          {jobsLoading ? (
            <div className="p-12 text-center">
              <div className="animate-spin w-8 h-8 border-4 border-blue-800 border-t-transparent rounded-full mx-auto mb-4"></div>
              <p className="text-gray-600">Loading jobs...</p>
            </div>
          ) : jobs.length === 0 ? (
            <div className="p-12 text-center">
              <p className="text-gray-600 mb-4">No jobs found</p>
              <button
                onClick={() => setActivePage('home')}
                className="bg-blue-800 hover:bg-blue-900 text-white font-semibold py-2 px-6 rounded-lg"
              >
                Upload Your First File
              </button>
            </div>
          ) : (
            <div className="divide-y divide-blue-100">
              {jobs.map((job) => (
                <div key={job.id} className="p-6 hover:bg-blue-50 transition">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4 flex-1">
                      {(() => {
                        const statusInfo = {
                          completed: { icon: CheckCircle, color: 'text-green-600', bgColor: 'bg-green-100' },
                          processing: { icon: Activity, color: 'text-blue-800', bgColor: 'bg-blue-100' },
                          running: { icon: Activity, color: 'text-blue-800', bgColor: 'bg-blue-100' },
                          pending: { icon: Clock, color: 'text-yellow-600', bgColor: 'bg-yellow-100' },
                          failed: { icon: XCircle, color: 'text-red-600', bgColor: 'bg-red-100' }
                        };
                        const status = statusInfo[job.status] || statusInfo.pending;
                        const StatusIcon = status.icon;

                        return (
                          <div className={`p-2 rounded-lg ${status.bgColor}`}>
                            <StatusIcon className={`w-5 h-5 ${status.color}`} />
                          </div>
                        );
                      })()}

                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="font-semibold text-gray-900">{job.filename}</h3>
                          <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${(() => {
                            const statusColors = {
                              completed: 'bg-green-100 text-green-800 border-green-200',
                              processing: 'bg-blue-100 text-blue-800 border-blue-200',
                              running: 'bg-blue-100 text-blue-800 border-blue-200',
                              pending: 'bg-yellow-100 text-yellow-800 border-yellow-200',
                              failed: 'bg-red-100 text-red-800 border-red-200'
                            };
                            return statusColors[job.status] || 'bg-gray-100 text-gray-800 border-gray-200';
                          })()}`}>
                            {job.status.toUpperCase()}
                          </span>
                        </div>

                        <div className="flex items-center gap-4 text-sm text-gray-600 mb-2">
                          <span>ID: {job.id}</span>
                          <span>•</span>
                          <span>Uploaded: {new Date(job.created_at).toLocaleDateString()}</span>
                          {job.completed_at && (
                            <>
                              <span>•</span>
                              <span>Completed: {new Date(job.completed_at).toLocaleDateString()}</span>
                            </>
                          )}
                        </div>

                        {/* Patient Information */}
                        {(job.patient_name || job.patient_age || job.patient_sex) && (
                          <div className="flex items-center gap-4 text-sm text-gray-600">
                            {job.patient_name && <span>Patient: {job.patient_name}</span>}
                            {job.patient_age && (
                              <>
                                {job.patient_name && <span>•</span>}
                                <span>Age: {job.patient_age}</span>
                              </>
                            )}
                            {job.patient_sex && (
                              <>
                                {(job.patient_name || job.patient_age) && <span>•</span>}
                                <span>Sex: {job.patient_sex}</span>
                              </>
                            )}
                            {job.scanner_info && (
                              <>
                                {(job.patient_name || job.patient_age || job.patient_sex) && <span>•</span>}
                                <span>Scanner: {job.scanner_info}</span>
                              </>
                            )}
                          </div>
                        )}

                        {(job.status === 'processing' || job.status === 'running') && (
                          <div className="mt-3">
                            <div className="flex items-center justify-between mb-1">
                              <span className="text-sm text-gray-600">{job.current_step || 'Processing...'}</span>
                              <span className="text-sm font-semibold text-blue-800">
                                {job.progress || 0}%
                              </span>
                            </div>
                            <div className="w-full bg-gray-200 rounded-full h-2">
                              <div className="h-2 bg-blue-800 rounded-full transition-all duration-500" style={{ width: `${job.progress || 0}%` }}></div>
                            </div>
                          </div>
                        )}


                        {job.status === 'failed' && job.error_message && (
                          <div className="mt-3 bg-red-50 border-2 border-red-300 rounded-lg p-4 shadow-sm">
                            <div className="flex items-start gap-3">
                              <XCircle className="w-6 h-6 text-red-600 flex-shrink-0 mt-0.5" />
                              <div className="flex-1">
                                <p className="text-base font-bold text-red-900 mb-3">Job Failed</p>
                                <p className="text-sm text-red-800 mb-3">{job.error_message}</p>
                                <details className="text-xs">
                                  <summary className="cursor-pointer text-red-700 hover:text-red-900 font-semibold">Show full error details</summary>
                                  <pre className="mt-2 p-3 bg-red-100 rounded text-xs overflow-auto max-h-40 border border-red-200">{job.error_message}</pre>
                                </details>
                              </div>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Action buttons - always visible below content */}
                  <div className="flex items-center justify-end gap-2 mt-4 border-t border-gray-200 pt-3">
                      {job.status === 'completed' && (
                        <>
                          <button
                            onClick={() => {
                              setSelectedJobId(job.id);
                              setActivePage('dashboard');
                            }}
                            className="p-2 text-blue-800 hover:bg-blue-100 rounded-lg transition"
                            title="View Statistics"
                          >
                            <Eye className="w-5 h-5" />
                          </button>
                          <button
                            onClick={() => {
                              setSelectedJobId(job.id);
                              setActivePage('viewer');
                            }}
                            className="p-2 text-purple-600 hover:bg-purple-100 rounded-lg transition"
                            title="View 2D Slices"
                          >
                            <Activity className="w-5 h-5" />
                          </button>
                          <button
                            onClick={async () => {
                              try {
                                const response = await fetch(`${API_BASE_URL}/reports/${job.id}/pdf`);
                                if (response.ok) {
                                  const blob = await response.blob();
                                  const url = window.URL.createObjectURL(blob);
                                  document.body.appendChild(a);
                                  a.click();
                                  document.body.removeChild(a);
                                  window.URL.revokeObjectURL(url);
                                } else {
                                  alert('Failed to generate report. Please try again.');
                                }
                              } catch (error) {
                                console.error('Report generation failed:', error);
                                alert('Failed to generate report. Please try again.');
                              }
                            }}
                            className="p-2 text-green-600 hover:bg-green-100 rounded-lg transition"
                            title="Generate PDF Report"
                          >
                            <Download className="w-5 h-5" />
                          </button>
                        </>
                      )}
                      <button
                        onClick={async () => {
                          if (confirm('Delete this job?')) {
                            try {
                              await apiService.deleteJob(job.id);
                              await onJobsUpdate(); // Refresh global job state
                            } catch (error) {
                              console.error('Delete failed:', error);
                              alert('Failed to delete job');
                            }
                          }
                        }}
                        className="p-3 bg-red-600 text-white hover:bg-red-700 rounded-lg transition font-semibold"
                        title="Delete Job"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default JobsPage;
