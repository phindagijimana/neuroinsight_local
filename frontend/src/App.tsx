import { useState, useEffect } from 'react'
import Navigation from './components/Navigation'
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
        />
      )}
      {activePage === 'dashboard' && <DashboardPage selectedJobId={selectedJobId} setSelectedJobId={setSelectedJobId} />}
      {activePage === 'viewer' && <ViewerPage selectedJobId={selectedJobId} setSelectedJobId={setSelectedJobId} />}
    </div>
  )
}

export default App