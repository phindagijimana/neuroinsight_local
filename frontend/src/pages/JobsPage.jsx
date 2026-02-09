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

function JobsPage({ setActivePage, setSelectedJobId, jobs, jobsLoading, onJobsUpdate, lastRefreshTime, isRefreshing, pollJobUntilDone, pollingJobId }) {
  const [selectedFile, setSelectedFile] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(null);
  const [isDragging, setIsDragging] = useState(false);
  const [patientInfo, setPatientInfo] = useState({
    patient_name: '',
    patient_id: '',
    age: '',
    sex: '',
    scanner: '',
    sequence: '',
    notes: ''
  });
  const [stats, setStats] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

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

  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    try {
      return new Date(dateString).toLocaleDateString('en-US');
    } catch {
      return dateString;
    }
  };

  const isValidNifti = (fileName) => {
    const lower = fileName.toLowerCase();
    return lower.endsWith('.nii.gz') || lower.endsWith('.nii');
  };

  // Calculate statistics whenever jobs change
  useEffect(() => {
    const counts = jobs.reduce(
      (acc, job) => {
        const status = normalizeStatus(job.status);
        acc.total += 1;
        if (status === 'completed') acc.completed += 1;
        if (status === 'processing') acc.processing += 1;
        if (status === 'pending') acc.pending += 1;
        if (status === 'failed') acc.failed += 1;
        return acc;
      },
      { total: 0, completed: 0, processing: 0, pending: 0, failed: 0 }
    );
    setStats(counts);
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
      if (isValidNifti(file.name)) {
        setSelectedFile(file);
      } else {
        alert('Please select a valid MRI file (.nii or .nii.gz)');
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
        patient_id: '',
        age: '',
        sex: '',
        scanner: '',
        sequence: '',
        notes: ''
      });
      
      // Refresh jobs list
      await onJobsUpdate();
      
      // Start rapid polling for this specific job (every 3 seconds for real-time progress)
      if (result && result.id && pollJobUntilDone) {
        console.log('Starting rapid polling for job:', result.id);
        pollJobUntilDone(result.id);
      }
      
      setTimeout(() => setUploadProgress(null), 2000);
    } catch (error) {
      console.error('Upload failed:', error);
      alert('Upload failed: ' + error.message);
      setUploadProgress(null);
    }
  };


  const generateReport = async (jobId) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/reports/${jobId}/pdf`);
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
      <div className="max-w-7xl mx-auto px-6 py-4">

        {/* Upload Section */}
        <div className="mb-4">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Upload New MRI Scan</h2>
          <p className="text-gray-600 mb-6">Upload T1-weighted MRI scans in NIfTI format (.nii or .nii.gz)</p>

          {/* Patient Information Section */}
          <div className="bg-white rounded-xl shadow-sm border border-blue-100 p-3 mb-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
              <Brain className="w-5 h-5 text-[#003d7a]" />
              Patient Information
            </h3>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Patient Name
                </label>
                <input
                  type="text"
                  value={patientInfo.patient_name}
                  onChange={(e) => handlePatientInfoChange('patient_name', e.target.value)}
                  placeholder="Enter patient name"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#003d7a] focus:border-[#002b55]"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Patient ID
                </label>
                <input
                  type="text"
                  value={patientInfo.patient_id}
                  onChange={(e) => handlePatientInfoChange('patient_id', e.target.value)}
                  placeholder="Enter patient ID"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#003d7a] focus:border-[#002b55]"
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#003d7a] focus:border-[#002b55]"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Sex
                </label>
                <select
                  value={patientInfo.sex}
                  onChange={(e) => handlePatientInfoChange('sex', e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#003d7a] focus:border-[#002b55]"
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#003d7a] focus:border-[#002b55]"
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
                  placeholder="e.g., T1w"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#003d7a] focus:border-[#002b55]"
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
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-[#003d7a] focus:border-[#002b55]"
                />
              </div>
            </div>
          </div>

          {/* File Upload Section */}
          <div
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            className={`border-2 border-dashed rounded-2xl p-6 transition-all duration-200 border-blue-200 bg-white hover:border-[#003d7a] hover:bg-blue-50 ${isDragging ? 'border-[#003d7a] bg-blue-50 scale-105' : ''}`}
          >
            <div className="text-center space-y-4">
              <div className="flex justify-center">
                <div className="bg-blue-100 p-4 rounded-full">
                  <Upload className="w-12 h-12 text-[#003d7a]" />
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
                <span className="mt-4 px-6 py-3 bg-[#003d7a] text-white rounded-lg font-semibold hover:bg-[#002b55] transition cursor-pointer inline-block">
                  Select Files
                </span>
              </label>
              <p className="text-xs text-gray-400 mt-4">
                Accepted formats: .nii, .nii.gz • Max size: 500MB
              </p>
            </div>
          </div>

          <button
            onClick={handleUpload}
            disabled={!selectedFile || uploadProgress !== null || !patientInfo.patient_name.trim()}
            className="mt-4 w-full px-6 py-3 bg-[#003d7a] text-white rounded-lg font-semibold hover:bg-[#002b55] transition disabled:bg-gray-300 disabled:cursor-not-allowed"
          >
            {uploadProgress !== null ? `Processing... ${uploadProgress}%` : 'Start Processing'}
          </button>

          {!patientInfo.patient_name.trim() && selectedFile && (
            <p className="text-sm text-red-600 mt-2 text-center">Patient name is required</p>
          )}

          {/* Statistics Dashboard */}
          <div className="grid grid-cols-2 md:grid-cols-5 gap-3 mb-4">
            {[
              { label: 'Total Jobs', value: (stats?.total ?? 0).toString(), icon: FileText, bgColor: 'bg-blue-100', iconColor: 'text-[#003d7a]' },
              { label: 'Completed', value: (stats?.completed ?? 0).toString(), icon: CheckCircle, bgColor: 'bg-green-100', iconColor: 'text-green-600' },
              { label: 'Processing', value: (stats?.processing ?? 0).toString(), icon: Clock, bgColor: 'bg-blue-100', iconColor: 'text-[#003d7a]' },
              { label: 'Pending', value: (stats?.pending ?? 0).toString(), icon: Clock, bgColor: 'bg-yellow-100', iconColor: 'text-yellow-600' },
              { label: 'Failed', value: (stats?.failed ?? 0).toString(), icon: XCircle, bgColor: 'bg-red-100', iconColor: 'text-red-600' }
            ].map((stat, idx) => (
              <div key={idx} className="bg-white rounded-xl p-3 shadow-sm border border-blue-100">
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
        <div className="bg-white rounded-xl shadow-sm border border-blue-100 overflow-hidden">
          <div className="px-6 py-4 border-b border-blue-100 flex items-center justify-between">
            <h2 className="text-xl font-bold text-gray-900">Recent Jobs</h2>
            <div className="text-sm text-gray-500">
              Showing {jobs.length} job{jobs.length !== 1 ? 's' : ''}
              {stats?.completed > 0 ? ` (${stats.completed} completed)` : ''}
            </div>
          </div>

          {jobsLoading ? (
            <div className="p-12 text-center">
              <div className="animate-spin w-8 h-8 border-4 border-blue-800 border-t-transparent rounded-full mx-auto mb-4"></div>
              <p className="text-gray-600">Loading jobs...</p>
            </div>
          ) : jobs.length === 0 ? (
            <div className="p-12 text-center text-gray-500">
              <FileText className="w-12 h-12 mx-auto mb-4 opacity-50" />
              <p className="text-lg font-semibold mb-2">No jobs found</p>
              <p className="text-sm">Try uploading a file to get started.</p>
            </div>
          ) : (
            <div className="divide-y divide-blue-100">
              {jobs.map((job) => {
                const normalizedStatus = normalizeStatus(job.status);
                const statusInfo = {
                  completed: { icon: CheckCircle, color: 'text-green-600', bgColor: 'bg-green-100' },
                  processing: { icon: Activity, color: 'text-[#003d7a]', bgColor: 'bg-blue-100' },
                  pending: { icon: Clock, color: 'text-yellow-600', bgColor: 'bg-yellow-100' },
                  failed: { icon: XCircle, color: 'text-red-600', bgColor: 'bg-red-100' },
                  queued: { icon: Clock, color: 'text-gray-400', bgColor: 'bg-gray-100' }
                };
                const statusColors = {
                  completed: 'bg-green-50 text-green-700 border-green-200',
                  processing: 'bg-blue-50 text-[#003d7a] border-blue-200',
                  pending: 'bg-yellow-50 text-yellow-700 border-yellow-200',
                  failed: 'bg-red-50 text-red-700 border-red-200',
                  queued: 'bg-gray-50 text-gray-700 border-gray-200'
                };
                const StatusIcon = (statusInfo[normalizedStatus] || statusInfo.queued).icon;
                const statusColor = statusColors[normalizedStatus] || statusColors.queued;
                const currentStep = job.current_step || (normalizedStatus === 'processing' ? 'Processing...' : normalizedStatus === 'pending' ? 'Queued for processing' : '');

                return (
                  <div key={job.id} className="p-6 hover:bg-blue-50 transition">
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex items-start gap-4 flex-1 min-w-0">
                      <div className={`p-2 rounded-lg ${(statusInfo[normalizedStatus] || statusInfo.queued).bgColor} flex-shrink-0`}>
                        <StatusIcon className={`w-5 h-5 ${(statusInfo[normalizedStatus] || statusInfo.queued).color}`} />
                      </div>

                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="font-semibold text-gray-900">{job.filename}</h3>
                          <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${statusColor}`}>
                            {normalizedStatus.toUpperCase()}
                          </span>
                        </div>

                        <div className="flex items-center gap-4 text-sm text-gray-600 mb-2">
                          <span>ID: {job.id}</span>
                          <span>•</span>
                          <span>Uploaded: {formatDate(job.created_at || job.started_at)}</span>
                          {job.completed_at && (
                            <>
                              <span>•</span>
                              <span>Completed: {formatDate(job.completed_at)}</span>
                            </>
                          )}
                        </div>

                        {(normalizedStatus === 'processing' || normalizedStatus === 'pending') && (
                          <div className="mt-3">
                            <div className="flex items-center justify-between mb-1">
                              <div className="flex items-center gap-2">
                                <span className="text-sm text-gray-600">{currentStep}</span>
                              </div>
                              <span className={`text-sm font-semibold ${normalizedStatus === 'processing' ? 'text-[#003d7a]' : 'text-yellow-600'}`}>
                                {normalizedStatus === 'pending' ? 'Queued' : `${job.progress || 0}%`}
                              </span>
                            </div>
                            <div className="w-full bg-gray-200 rounded-full h-2">
                              <div
                                className={`h-2 rounded-full transition-all duration-500 ${normalizedStatus === 'processing' ? 'bg-[#003d7a]' : 'bg-yellow-600'}`}
                                style={{ width: `${job.progress || 0}%` }}
                              ></div>
                            </div>
                          </div>
                        )}


                        {normalizedStatus === 'failed' && job.error_message && (
                          <div className="mt-3 bg-red-50 border-2 border-red-300 rounded-lg p-4 shadow-sm">
                            <div className="flex items-start gap-3">
                              <XCircle className="w-6 h-6 text-red-600 flex-shrink-0 mt-0.5" />
                              <div className="flex-1">
                                {(() => {
                                  const errMsg = job.error_message ? job.error_message.toLowerCase() : '';
                                  
                                  const isDockerError = errMsg.includes('docker') && 
                                    (errMsg.includes('not running') || 
                                     errMsg.includes('not installed') || 
                                     errMsg.includes('not available'));
                                  
                                  const isFilenameError = errMsg.includes('filename') && 
                                    (errMsg.includes('does not contain') || 
                                     errMsg.includes('rename'));
                                  
                                  const isT1wError = (errMsg.includes('t1') || 
                                    errMsg.includes('t2') ||
                                    errMsg.includes('flair') ||
                                    errMsg.includes('dwi') ||
                                    errMsg.includes('image type') ||
                                    errMsg.includes('sequence')) && !isFilenameError;

                                  if (isDockerError) {
                                    return (
                                      <div>
                                        <p className="text-base text-red-900 mb-4 font-semibold">
                                          Docker Desktop is not running
                                        </p>
                                        <p className="text-sm text-red-800 mb-3">
                                          NeuroInsight requires Docker to process MRI scans.
                                        </p>
                                        <div className="bg-yellow-50 border-2 border-yellow-400 rounded-md p-4 mb-3">
                                          <p className="text-sm font-bold text-gray-900 mb-3">Quick Fix:</p>
                                          <ol className="text-sm text-gray-800 space-y-2 list-decimal list-inside">
                                            <li className="pl-2">Open <strong className="font-bold">Docker Desktop</strong> from your Applications folder</li>
                                            <li className="pl-2">Wait for the whale icon to appear in your menu bar (Mac) or system tray (Windows/Linux)</li>
                                            <li className="pl-2">The icon should be <strong>steady</strong> (not animating)</li>
                                            <li className="pl-2">Return here and upload your MRI file again</li>
                                          </ol>
                                        </div>
                                        <details className="text-xs">
                                          <summary className="cursor-pointer text-red-700 hover:text-red-900 font-semibold">Show full error details</summary>
                                          <pre className="mt-2 p-3 bg-red-100 rounded text-xs overflow-auto max-h-40 border border-red-200">{job.error_message}</pre>
                                        </details>
                                      </div>
                                    );
                                  } else if (isFilenameError) {
                                    return (
                                      <div>
                                        <p className="text-base text-red-900 mb-4 font-semibold">
                                          Please rename your file
                                        </p>
                                        <p className="text-sm text-red-800 mb-3">
                                          Your filename must contain <strong>'T1'</strong> to indicate it's a T1-weighted MRI scan.
                                        </p>
                                        <div className="bg-yellow-50 border-2 border-yellow-400 rounded-md p-4 mb-3">
                                          <p className="text-sm font-bold text-gray-900 mb-3">Good filename examples:</p>
                                          <ul className="text-sm text-gray-800 space-y-2 list-disc list-inside ml-4 mb-4">
                                            <li className="pl-1 font-mono">subject_T1w.nii</li>
                                            <li className="pl-1 font-mono">brain_T1.nii</li>
                                            <li className="pl-1 font-mono">patient_01_MPRAGE_T1.nii</li>
                                            <li className="pl-1 font-mono">scan_T1-weighted.nii</li>
                                          </ul>
                                          <p className="text-sm font-bold text-gray-900 mb-2">Steps to fix:</p>
                                          <ol className="text-sm text-gray-800 space-y-2 list-decimal list-inside">
                                            <li className="pl-2">Rename your file to include <strong>'T1'</strong> in the filename</li>
                                            <li className="pl-2">Make sure you're using a T1-weighted scan (MPRAGE, SPGR, or 3D T1)</li>
                                            <li className="pl-2">Upload the renamed file</li>
                                          </ol>
                                        </div>
                                        <p className="text-xs text-gray-700 italic mb-2">
                                          Why? This helps ensure you're uploading the correct scan type. FreeSurfer requires T1-weighted images.
                                        </p>
                                        <details className="text-xs">
                                          <summary className="cursor-pointer text-red-700 hover:text-red-900 font-semibold">Show full error details</summary>
                                          <pre className="mt-2 p-3 bg-red-100 rounded text-xs overflow-auto max-h-40 border border-red-200">{job.error_message}</pre>
                                        </details>
                                      </div>
                                    );
                                  } else if (isT1wError) {
                                    return (
                                      <div>
                                        <p className="text-base text-red-900 mb-4 font-semibold">
                                          Wrong MRI sequence type detected
                                        </p>
                                        <p className="text-sm text-red-800 mb-3">
                                          This file appears to be a <strong>non-T1w</strong> MRI scan.
                                        </p>
                                        <div className="bg-yellow-50 border-2 border-yellow-400 rounded-md p-4 mb-3">
                                          <p className="text-sm font-bold text-green-800 mb-2">Accepted T1 indicators:</p>
                                          <p className="text-sm text-gray-800 mb-3">Your T1-weighted scan filename must contain at least one of these:</p>
                                          <ul className="text-sm text-gray-800 space-y-1 list-disc list-inside ml-4 mb-4">
                                            <li className="pl-1"><strong>t1</strong></li>
                                            <li className="pl-1"><strong>t1w</strong></li>
                                            <li className="pl-1"><strong>t1-weighted</strong></li>
                                            <li className="pl-1"><strong>mprage</strong> (most common)</li>
                                            <li className="pl-1"><strong>spgr</strong></li>
                                            <li className="pl-1"><strong>tfl</strong></li>
                                            <li className="pl-1"><strong>tfe</strong></li>
                                            <li className="pl-1"><strong>fspgr</strong></li>
                                          </ul>
                                          <p className="text-sm font-bold text-red-800 mb-2">NOT supported:</p>
                                          <ul className="text-sm text-gray-800 space-y-1 list-disc list-inside ml-4 mb-3">
                                            <li className="pl-1">T2-weighted</li>
                                            <li className="pl-1">FLAIR (unless T1-FLAIR)</li>
                                            <li className="pl-1">DWI/DTI</li>
                                            <li className="pl-1">fMRI/BOLD</li>
                                          </ul>
                                          <p className="text-sm font-bold text-gray-900 mb-2">What to do:</p>
                                          <ol className="text-sm text-gray-800 space-y-2 list-decimal list-inside">
                                            <li className="pl-2">Find your T1-weighted scan in your MRI data</li>
                                            <li className="pl-2">Rename the file to include one of the accepted T1 indicators above</li>
                                            <li className="pl-2">Upload the renamed file</li>
                                          </ol>
                                        </div>
                                        <p className="text-xs text-gray-700 italic mb-2">
                                          Tip: Most T1-weighted scans are labeled with "t1" or "mprage"
                                        </p>
                                        <details className="text-xs">
                                          <summary className="cursor-pointer text-red-700 hover:text-red-900 font-semibold">Show full error details</summary>
                                          <pre className="mt-2 p-3 bg-red-100 rounded text-xs overflow-auto max-h-40 border border-red-200">{job.error_message}</pre>
                                        </details>
                                      </div>
                                    );
                                  } else {
                                    return (
                                      <div>
                                        <p className="text-base font-bold text-red-900 mb-3">Job Failed</p>
                                        <p className="text-sm text-red-800 mb-3">{job.error_message}</p>
                                        <details className="text-xs">
                                          <summary className="cursor-pointer text-red-700 hover:text-red-900 font-semibold">Show full error details</summary>
                                          <pre className="mt-2 p-3 bg-red-100 rounded text-xs overflow-auto max-h-40 border border-red-200">{job.error_message}</pre>
                                        </details>
                                      </div>
                                    );
                                  }
                                })()}
                              </div>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>

                    <div className="flex flex-col items-end gap-2 flex-shrink-0">
                      {normalizedStatus === 'completed' && (
                        <>
                          <button
                            onClick={() => {
                              setSelectedJobId(job.id);
                              setActivePage('dashboard');
                            }}
                            className="p-2 text-blue-600 hover:bg-blue-100 rounded-lg transition"
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
                                const response = await fetch(`${API_BASE_URL}/api/reports/${job.id}/pdf`);
                                if (response.ok) {
                                  const blob = await response.blob();
                                  const url = window.URL.createObjectURL(blob);
                                  const a = document.createElement('a');
                                  a.href = url;
                                  a.download = `neuroinsight_report_${job.id}.pdf`;
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
                        className="p-2 text-red-600 hover:bg-red-100 rounded-lg transition"
                        title="Delete Job"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default JobsPage;
