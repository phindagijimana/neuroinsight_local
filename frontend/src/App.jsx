import { useState, useEffect } from 'react'
import { apiService } from './utils/api.js'
import Navigation from './components/Navigation.jsx'
import HomePage from './pages/HomePage.jsx'
import JobsPage from './pages/JobsPage.jsx'
import DashboardPage from './pages/DashboardPage.jsx'
import ViewerPage from './pages/ViewerPage.jsx'

function App() {
  const [activePage, setActivePage] = useState('home')
  const [selectedJobId, setSelectedJobId] = useState(null)
  const [jobs, setJobs] = useState([])
  const [jobsLoading, setJobsLoading] = useState(true)
  const [lastRefreshTime, setLastRefreshTime] = useState(null)
  const [isRefreshing, setIsRefreshing] = useState(false)

  // Global job data management with real-time updates
  useEffect(() => {
    // Load jobs initially
    loadJobs()

    // Simple polling every 15 seconds
    const interval = setInterval(() => {
      loadJobs()
    }, 15000)

    return () => clearInterval(interval)
  }, [])

  const loadJobs = async (showIndicator = false) => {
    try {
      if (showIndicator) setIsRefreshing(true)
      const fetchedJobs = await apiService.getJobs()
      setJobs(fetchedJobs)
      setJobsLoading(false)
      setLastRefreshTime(new Date())
    } catch (error) {
      console.error('Failed to load jobs:', error)
      setJobsLoading(false)
    } finally {
      setIsRefreshing(false)
    }
  }

  return (
    <div>
      <Navigation activePage={activePage} setActivePage={setActivePage} isRefreshing={isRefreshing} lastRefreshTime={lastRefreshTime} />
      {activePage === 'home' && <HomePage setActivePage={setActivePage} />}
      {activePage === 'jobs' && (
        <JobsPage
          setActivePage={setActivePage}
          setSelectedJobId={setSelectedJobId}
          jobs={jobs}
          jobsLoading={jobsLoading}
          onJobsUpdate={loadJobs}
          lastRefreshTime={lastRefreshTime}
          isRefreshing={isRefreshing}
        />
      )}
      {activePage === 'dashboard' && (
        <DashboardPage
          selectedJobId={selectedJobId}
          setSelectedJobId={setSelectedJobId}
          jobs={jobs}
        />
      )}
      {activePage === 'viewer' && (
        <ViewerPage
          selectedJobId={selectedJobId}
          setSelectedJobId={setSelectedJobId}
          jobs={jobs}
        />
      )}
    </div>
  )
}

export default App