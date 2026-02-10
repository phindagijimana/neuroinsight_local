import { useState, useEffect, useRef } from 'react'
import Navigation from './components/Navigation'
import { FileUpload } from './components/FileUpload'
import HomePage from './pages/HomePage'
import JobsPage from './pages/JobsPage'
import DashboardPage from './pages/DashboardPage'
import ViewerPage from './pages/ViewerPage'
import { apiService } from './utils/api.js'

function App() {
  const [activePage, setActivePage] = useState<string>('home')
  const [selectedJobId, setSelectedJobId] = useState<string | null>(null)
  const [jobs, setJobs] = useState([])
  const [jobsLoading, setJobsLoading] = useState(false)
  const [lastRefreshTime, setLastRefreshTime] = useState(null)
  const [isRefreshing, setIsRefreshing] = useState(false)
  const [pollingJobId, setPollingJobId] = useState<string | null>(null)
  const pollingTimerRef = useRef<NodeJS.Timeout | null>(null)

  // Fetch jobs data
  const fetchJobs = async (showRefreshing = false) => {
    try {
      if (showRefreshing) setIsRefreshing(true)
      else setJobsLoading(true)

      const jobsData = await apiService.getJobs()
      setJobs(jobsData)
      setLastRefreshTime(new Date())
    } catch (error) {
      console.error('Failed to fetch jobs:', error)
      setJobs([])
    } finally {
      setJobsLoading(false)
      setIsRefreshing(false)
    }
  }

  // Initial load and periodic refresh
  useEffect(() => {
    fetchJobs()

    // Refresh jobs every 30 seconds when on jobs page
    const interval = setInterval(() => {
      if (activePage === 'jobs') {
        fetchJobs(true)
      }
    }, 30000)

    return () => clearInterval(interval)
  }, [activePage])

  const handleJobsUpdate = () => {
    fetchJobs(true)
  }

  // Rapid polling for a specific job (every 3 seconds)
  // This provides real-time progress updates for actively processing jobs
  const pollJobUntilDone = async (jobId: string) => {
    console.log('Start rapid polling for job:', jobId)
    setPollingJobId(jobId)
    
    // Clear any existing polling timer
    if (pollingTimerRef.current) {
      clearInterval(pollingTimerRef.current)
    }
    
    let attempts = 0
    const maxAttempts = 200 // ~10 minutes at 3s interval
    const intervalMs = 3000 // 3 seconds - much faster than 30s background polling
    
    pollingTimerRef.current = setInterval(async () => {
      attempts += 1
      
      try {
        const job = await apiService.getJob(jobId)
        if (job) {
          // Update this specific job in the jobs list
          setJobs((prevJobs) => {
            const otherJobs = prevJobs.filter((j: any) => j.id !== jobId)
            return [job, ...otherJobs]
          })
          
          // Check if job is complete
          const status = job.status?.toLowerCase()
          if (status === 'completed' || status === 'failed') {
            console.log('Job finished, stopping polling:', jobId, 'Status:', status)
            if (pollingTimerRef.current) {
              clearInterval(pollingTimerRef.current)
              pollingTimerRef.current = null
            }
            setPollingJobId(null)
            
            // Auto-navigate to dashboard if completed successfully
            if (status === 'completed') {
              setSelectedJobId(jobId)
              setActivePage('dashboard')
            }
          }
        }
      } catch (error) {
        console.warn('Polling failed for job', jobId, error)
      }
      
      // Timeout after max attempts
      if (attempts >= maxAttempts) {
        console.warn('Polling timed out for job', jobId)
        if (pollingTimerRef.current) {
          clearInterval(pollingTimerRef.current)
          pollingTimerRef.current = null
        }
        setPollingJobId(null)
      }
    }, intervalMs)
  }

  // Cleanup polling timer on unmount
  useEffect(() => {
    return () => {
      if (pollingTimerRef.current) {
        clearInterval(pollingTimerRef.current)
      }
    }
  }, [])

  return (
    <div>
      <Navigation activePage={activePage} setActivePage={setActivePage} />
      {activePage === 'home' && <HomePage setActivePage={setActivePage} />}
      {activePage === 'jobs' && (
        <JobsPage
          setActivePage={setActivePage}
          setSelectedJobId={setSelectedJobId}
          jobs={jobs}
          jobsLoading={jobsLoading}
          onJobsUpdate={handleJobsUpdate}
          lastRefreshTime={lastRefreshTime}
          isRefreshing={isRefreshing}
          pollJobUntilDone={pollJobUntilDone}
          pollingJobId={pollingJobId}
        />
      )}
      {activePage === 'upload' && (
        <main className="max-w-7xl mx-auto px-6 py-8">
          <FileUpload
            onUploadComplete={() => { handleJobsUpdate(); setActivePage('jobs'); }}
            onBack={() => setActivePage('jobs')}
          />
        </main>
      )}
      {activePage === 'dashboard' && <DashboardPage selectedJobId={selectedJobId} setSelectedJobId={setSelectedJobId} />}
      {activePage === 'viewer' && <ViewerPage selectedJobId={selectedJobId} setSelectedJobId={setSelectedJobId} />}

      {/* Footer - Copyright Statement */}
      <footer className="bg-gray-50 border-t border-gray-200 mt-12">
        <div className="max-w-7xl mx-auto px-6 py-4 text-sm text-gray-500 text-center">
          © 2025 University of Rochester. All rights reserved.
        </div>
      </footer>
    </div>
  )
}

export default App