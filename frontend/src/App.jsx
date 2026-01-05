import { useState } from 'react'
import Navigation from './components/Navigation.jsx'
import HomePage from './pages/HomePage.jsx'
import JobsPage from './pages/JobsPage.jsx'
import DashboardPage from './pages/DashboardPage.jsx'
import ViewerPage from './pages/ViewerPage.jsx'

function App() {
  const [activePage, setActivePage] = useState('home')
  const [selectedJobId, setSelectedJobId] = useState(null)

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
