import { useState } from 'react'
import Navigation from './components/Navigation'
import HomePage from './pages/HomePage'
import JobsPage from './pages/JobsPage'
import DashboardPage from './pages/DashboardPage'
import ViewerPage from './pages/ViewerPage'

function App() {
  const [activePage, setActivePage] = useState<string>('home')
  const [selectedJobId, setSelectedJobId] = useState<string | null>(null)

  return (
    <div>
      <Navigation activePage={activePage} setActivePage={setActivePage} />
      {activePage === 'home' && <HomePage setActivePage={setActivePage} />}
      {activePage === 'jobs' && <JobsPage setActivePage={setActivePage} setSelectedJobId={setSelectedJobId} />}
      {activePage === 'dashboard' && <DashboardPage selectedJobId={selectedJobId} setSelectedJobId={setSelectedJobId} />}
      {activePage === 'viewer' && <ViewerPage selectedJobId={selectedJobId} setSelectedJobId={setSelectedJobId} />}
    </div>
  )
}

export default App