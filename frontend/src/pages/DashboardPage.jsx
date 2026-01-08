import { useState, useEffect, useMemo } from 'react';
import { apiService, API_BASE_URL } from '../utils/api.js';

function DashboardPage({ selectedJobId, setSelectedJobId, jobs }) {
  const [metrics, setMetrics] = useState(null);
  const [patientInfo, setPatientInfo] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (selectedJobId) {
      loadDashboardData();
    } else {
      setLoading(false);
      setPatientInfo(null);
      setMetrics(null);
    }
  }, [selectedJobId]);

  const loadDashboardData = async () => {
    try {
      setLoading(true);

      // Load patient info and metrics in parallel
      console.log('Dashboard: Loading data for job ID:', selectedJobId);
      console.log('Dashboard: API base URL:', API_BASE_URL);

      const [jobResponse, metricsResponse] = await Promise.allSettled([
        fetch(`${API_BASE_URL}/jobs/${selectedJobId}`),
        fetch(`${API_BASE_URL}/metrics/?job_id=${selectedJobId}`)
      ]);

      console.log('Dashboard: Job response status:', jobResponse);
      console.log('Dashboard: Metrics response status:', metricsResponse);

      // Extract patient info from job data
      if (jobResponse.status === 'fulfilled') {
        console.log('Dashboard: Job response received, status:', jobResponse.value.status);
        console.log('Dashboard: Job response headers:', jobResponse.value.headers.get('content-type'));

        if (jobResponse.value.ok) {
          try {
            const jobData = await jobResponse.value.json();
            console.log('Dashboard: Job data loaded:', jobData);
            setPatientInfo({
              id: jobData.patient_id || selectedJobId,
              patient_name: jobData.patient_name || 'N/A',
              age: jobData.patient_age || 'N/A',
              sex: jobData.patient_sex || 'N/A',
              created_at: jobData.created_at,
              completed_at: jobData.completed_at,
              scanner_info: jobData.scanner_info || 'N/A',
              sequence_info: jobData.sequence_info || 'T1-MPRAGE',
              notes: jobData.notes || ''
            });
          } catch (error) {
            console.error('Dashboard: Failed to parse job JSON:', error);
            console.error('Dashboard: Raw response text:', await jobResponse.value.text());
          }
        } else {
          console.error('Dashboard: Job request failed with status:', jobResponse.value.status);
          console.error('Dashboard: Response text:', await jobResponse.value.text());
        }
      } else {
        console.error('Dashboard: Job request rejected:', jobResponse.reason);
      }

      // Load metrics
      if (metricsResponse.status === 'fulfilled') {
        console.log('Dashboard: Metrics response received, status:', metricsResponse.value.status);

        if (metricsResponse.value.ok) {
          try {
            const metricsData = await metricsResponse.value.json();
            console.log('Dashboard: Metrics loaded:', metricsData);
            setMetrics(metricsData);
          } catch (error) {
            console.error('Dashboard: Failed to parse metrics JSON:', error);
            console.error('Dashboard: Raw metrics response:', await metricsResponse.value.text());
          }
        } else {
          console.warn('Dashboard: Metrics request failed with status:', metricsResponse.value.status);
          console.warn('Dashboard: Metrics response text:', await metricsResponse.value.text());
          setMetrics([]); // Ensure metrics is set to empty array so volume analysis doesn't show
        }
      } else {
        console.warn('Dashboard: Metrics request rejected:', metricsResponse.reason);
        setMetrics([]); // Ensure metrics is set to empty array so volume analysis doesn't show
      }
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Calculate system statistics from all jobs
  const systemStats = jobs && jobs.length > 0 ? {
    total: jobs.length,
    completed: jobs.filter(job => job.status === 'completed').length,
    processing: jobs.filter(job => job.status === 'processing' || job.status === 'running').length,
    pending: jobs.filter(job => job.status === 'pending').length,
    failed: jobs.filter(job => job.status === 'failed').length,
    successRate: jobs.length > 0 ? Math.round((jobs.filter(job => job.status === 'completed').length / jobs.length) * 100) : 0,
    avgProcessingTime: (() => {
      const completedJobs = jobs.filter(job => job.status === 'completed' && job.created_at && job.completed_at);
      if (completedJobs.length === 0) return null;

      const totalTime = completedJobs.reduce((sum, job) => {
        const start = new Date(job.created_at);
        const end = new Date(job.completed_at);
        return sum + (end - start);
      }, 0);

      return Math.round(totalTime / completedJobs.length / 1000 / 60); // minutes
    })()
  } : null;

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-white flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin w-8 h-8 border-4 border-blue-800 border-t-transparent rounded-full mx-auto mb-4"></div>
          <p className="text-gray-600">Loading statistics...</p>
        </div>
      </div>
    );
  }

  // Calculate total volumes
  const totalHippocampalVolume = metrics && metrics.length > 0 ? {
    left: metrics.reduce((sum, m) => sum + (m.left_volume || 0), 0),
    right: metrics.reduce((sum, m) => sum + (m.right_volume || 0), 0),
    aiDecimal: metrics.length > 0 ? ((metrics[0].left_volume - metrics[0].right_volume) / (metrics[0].left_volume + metrics[0].right_volume)) : 0
  } : null;

  // For demonstration, provide sample data if no metrics exist
  const sampleMetrics = [
    { region: 'Left-Hippocampus', left_volume: 3.245, right_volume: 0, asymmetry_index: 1.0 },
    { region: 'Right-Hippocampus', left_volume: 0, right_volume: 3.189, asymmetry_index: -1.0 }
  ];

  const displayMetrics = metrics && metrics.length > 0 ? metrics : sampleMetrics;
  const displayVolumes = metrics && metrics.length > 0 ? totalHippocampalVolume : {
    left: sampleMetrics[0].left_volume,
    right: sampleMetrics[1].right_volume,
    aiDecimal: (sampleMetrics[0].left_volume - sampleMetrics[1].right_volume) / (sampleMetrics[0].left_volume + sampleMetrics[1].right_volume)
  };

  if (!selectedJobId) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-white">
        <div className="max-w-6xl mx-auto px-6 py-8">
          {/* System Overview Header */}
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-gray-900 mb-2">System Overview</h1>
            <p className="text-gray-600">Aggregate statistics across all jobs</p>
          </div>

          {/* System Statistics Cards */}
          {systemStats && (
            <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-8">
              <div className="bg-white rounded-xl p-6 shadow-sm border border-blue-100">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500 mb-1">Total Jobs</p>
                    <p className="text-3xl font-bold text-gray-900">{systemStats.total}</p>
                  </div>
                  <div className="bg-blue-100 p-3 rounded-lg">
                    <svg className="w-6 h-6 text-blue-800" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                    </svg>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-xl p-6 shadow-sm border border-green-100">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500 mb-1">Success Rate</p>
                    <p className="text-3xl font-bold text-green-600">{systemStats.successRate}%</p>
                  </div>
                  <div className="bg-green-100 p-3 rounded-lg">
                    <svg className="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-xl p-6 shadow-sm border border-yellow-100">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-gray-500 mb-1">Active Jobs</p>
                    <p className="text-3xl font-bold text-yellow-600">{systemStats.processing + systemStats.pending}</p>
                  </div>
                  <div className="bg-yellow-100 p-3 rounded-lg">
                    <svg className="w-6 h-6 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                </div>
              </div>

              {systemStats.avgProcessingTime && (
                <div className="bg-white rounded-xl p-6 shadow-sm border border-purple-100">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm text-gray-500 mb-1">Avg Processing Time</p>
                      <p className="text-3xl font-bold text-purple-600">{systemStats.avgProcessingTime}m</p>
                    </div>
                    <div className="bg-purple-100 p-3 rounded-lg">
                      <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                      </svg>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Job Status Breakdown */}
          {jobs && jobs.length > 0 && (
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8">
              <h2 className="text-xl font-bold text-gray-900 mb-6">Job Status Breakdown</h2>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="text-center p-4 bg-green-50 rounded-lg border border-green-200">
                  <div className="text-2xl font-bold text-green-600 mb-1">{systemStats?.completed || 0}</div>
                  <div className="text-sm text-green-800">Completed</div>
                </div>
                <div className="text-center p-4 bg-blue-50 rounded-lg border border-blue-200">
                  <div className="text-2xl font-bold text-blue-600 mb-1">{systemStats?.processing || 0}</div>
                  <div className="text-sm text-blue-800">Processing</div>
                </div>
                <div className="text-center p-4 bg-yellow-50 rounded-lg border border-yellow-200">
                  <div className="text-2xl font-bold text-yellow-600 mb-1">{systemStats?.pending || 0}</div>
                  <div className="text-sm text-yellow-800">Pending</div>
                </div>
                <div className="text-center p-4 bg-red-50 rounded-lg border border-red-200">
                  <div className="text-2xl font-bold text-red-600 mb-1">{systemStats?.failed || 0}</div>
                  <div className="text-sm text-red-800">Failed</div>
                </div>
              </div>
            </div>
          )}

          {/* Empty State */}
          {(!jobs || jobs.length === 0) && (
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center">
              <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
              <h3 className="text-lg font-medium text-gray-900 mb-2">No Jobs Yet</h3>
              <p className="text-gray-500 mb-6">Upload your first MRI scan to get started with NeuroInsight</p>
              <button
                onClick={() => window.location.href = '#'}
                className="bg-blue-800 hover:bg-blue-900 text-white font-semibold py-2 px-6 rounded-lg transition"
              >
                Upload MRI Scan
              </button>
            </div>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-white">
      <div className="max-w-7xl mx-auto px-6 py-8">

        {/* Generate Report Button - Top right corner */}
        {patientInfo && (
        <div className="flex justify-end mb-8">
          <button
            onClick={() => {
              const response = fetch(`${API_BASE_URL}/reports/${selectedJobId}/pdf`);
              response.then(res => {
                if (res.ok) {
                  res.blob().then(blob => {
                    const url = window.URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = `neuroinsight_report_${selectedJobId}.pdf`;
                    document.body.appendChild(a);
                    a.click();
                    document.body.removeChild(a);
                    window.URL.revokeObjectURL(url);
                  });
                } else {
                  alert('Failed to generate report. Please try again.');
                }
              }).catch(error => {
                console.error('Report generation failed:', error);
                alert('Failed to generate report. Please try again.');
              });
            }}
            className="flex items-center gap-3 bg-blue-800 text-white px-8 py-4 rounded-xl font-semibold text-lg hover:bg-blue-900 transition-all duration-200 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            Generate PDF Report
          </button>
        </div>
        )}

        {patientInfo && (
        <div className="bg-white rounded-xl shadow-sm border border-blue-100 p-6 mb-6">
          <div className="flex items-center gap-2 mb-4">
            <svg className="w-5 h-5 text-blue-800" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <h2 className="text-lg font-semibold text-gray-900">Patient Information</h2>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-6">
            <div>
              <p className="text-sm text-gray-500">ID</p>
              <p className="font-semibold text-gray-900">{patientInfo.id || 'N/A'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Age / Sex</p>
              <p className="font-semibold text-gray-900">{patientInfo.age || 'N/A'} / {patientInfo.sex || 'N/A'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Scan Date</p>
              <p className="font-semibold text-gray-900">{patientInfo.created_at ? new Date(patientInfo.created_at).toLocaleDateString() : 'N/A'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Processed Date</p>
              <p className="font-semibold text-gray-900">{patientInfo.completed_at ? new Date(patientInfo.completed_at).toLocaleDateString() : 'N/A'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Scanner</p>
              <p className="font-semibold text-gray-900">{patientInfo.scanner_info || 'N/A'}</p>
            </div>
            <div>
              <p className="text-sm text-gray-500">Sequence</p>
              <p className="font-semibold text-gray-900">{patientInfo.sequence_info || 'T1-MPRAGE'}</p>
            </div>
          </div>
        </div>
        )}

        {displayMetrics && displayMetrics.length > 0 ? (
        <div className="grid grid-cols-3 gap-6">
          {(!metrics || metrics.length === 0) && (
            <div className="col-span-3 mb-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
              <p className="text-sm text-yellow-800">
                <strong>Note:</strong> Displaying sample metrics for demonstration. Complete MRI processing will generate real volumetric data.
              </p>
            </div>
          )}
            <div className="col-span-1 bg-white rounded-xl shadow-sm border border-blue-100 p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-8">Hippocampal Volume Comparison (mm³)</h2>
            {/* Simple Bar Chart */}
            <div className="mb-8 pt-8">
              <div className="flex items-end justify-center space-x-12 mb-6">
                <div className="text-center">
                  <div className="w-16 bg-blue-800 rounded-t-lg relative" style={{ height: `${Math.max(displayVolumes.left / 50, 30)}px` }}>
                    <div className="absolute -top-1 left-1/2 transform -translate-x-1/2 -translate-y-full text-sm font-bold text-blue-800 bg-white px-1 rounded">
                      {displayVolumes.left.toFixed(1)}
                    </div>
                  </div>
                  <div className="mt-3 text-sm text-gray-600">Left</div>
                </div>
                <div className="text-center">
                  <div className="w-16 bg-blue-800 rounded-t-lg relative" style={{ height: `${Math.max(displayVolumes.right / 50, 30)}px` }}>
                    <div className="absolute -top-1 left-1/2 transform -translate-x-1/2 -translate-y-full text-sm font-bold text-blue-800 bg-white px-1 rounded">
                      {displayVolumes.right.toFixed(1)}
                    </div>
                  </div>
                  <div className="mt-3 text-sm text-gray-600">Right</div>
                </div>
              </div>
              <div className="text-center text-xs text-gray-500 mt-2">Volume (mm³)</div>
            </div>
          </div>

            <div className="col-span-2 space-y-6">
            <div className="bg-white rounded-xl shadow-sm border border-blue-100 p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Total Hippocampal Volume</h2>
              <div className="space-y-4">
                <div className="bg-blue-50 rounded-lg p-4">
                  <p className="text-sm text-gray-600 mb-1">Left Hemisphere</p>
                    <p className="text-2xl font-bold text-blue-800">{displayVolumes.left.toFixed(1)} mm³</p>
                </div>
                <div className="bg-blue-50 rounded-lg p-4">
                  <p className="text-sm text-gray-600 mb-1">Right Hemisphere</p>
                    <p className="text-2xl font-bold text-blue-800">{displayVolumes.right.toFixed(1)} mm³</p>
                </div>
                  {/* Asymmetry Index */}
                  <div className="bg-blue-50 rounded-lg p-4">
                    <p className="text-sm text-gray-600 mb-1">Asymmetry Index</p>
                    <p className="text-2xl font-bold text-blue-800">{displayVolumes.aiDecimal.toFixed(4)}</p>
                    <p className="text-xs text-gray-500 mt-1">AI = (Left − Right) / (Left + Right)</p>
                  </div>
                  {/* Lateralization */}
                  <div className="bg-blue-50 rounded-lg p-4">
                    <p className="text-sm text-gray-600 mb-1">Lateralization</p>
                    {(() => {
                      const ai = displayVolumes.aiDecimal;
                      // Use HS thresholds for lateralization cutoffs
                      const HS_THRESHOLDS = {
                        LEFT_HS: -0.070839747728063,
                        RIGHT_HS: 0.046915816971433
                      };
                      const label = ai > HS_THRESHOLDS.RIGHT_HS
                        ? 'Left-dominant'
                        : ai < HS_THRESHOLDS.LEFT_HS
                        ? 'Right-dominant'
                        : 'Balanced';
                      const color = label === 'Balanced' ? 'text-gray-700' : 'text-blue-900';
                      return <p className={`text-xl font-semibold ${color}`}>{label}</p>;
                    })()}
                    <div className="text-xs text-gray-500 mt-2">
                      <p className="font-semibold mb-1">Thresholds:</p>
                      <ul className="list-disc list-inside space-y-1">
                        <li>Left HS (Right-dominant) if AI &lt; -0.070840.</li>
                        <li>Right HS (Left-dominant) if AI &gt; 0.046916.</li>
                        <li>No HS (Balanced) otherwise.</li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            </div>
        </div>
        ) : null}
      </div>
    </div>
  );
}

export default DashboardPage;