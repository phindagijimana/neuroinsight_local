import Brain from './icons/Brain.jsx'

function Navigation({ activePage, setActivePage, isRefreshing = false, lastRefreshTime = null }) {
  return (
    <header className="bg-white border-b border-blue-100 shadow-sm sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3 cursor-pointer" onClick={() => setActivePage('home')}>
            <div className="bg-blue-800 p-2 rounded-lg">
              <Brain className="w-8 h-8 text-white" />
            </div>
            <div className="flex items-center gap-3">
              <div>
                <h1 className="text-2xl font-bold text-gray-900">NeuroInsight</h1>
                <p className="text-xs text-gray-500">Hippocampal Analysis Platform</p>
              </div>
              {isRefreshing && (
                <div className="flex items-center gap-2 text-xs text-blue-600">
                  <div className="w-3 h-3 border border-blue-600 border-t-transparent rounded-full animate-spin"></div>
                  <span>Updating...</span>
                </div>
              )}
              {lastRefreshTime && (
                <span className="text-xs text-gray-500 ml-2">Last updated: {lastRefreshTime.toLocaleTimeString()}</span>
              )}
            </div>
          </div>
          <nav className="flex gap-6">
            <button
              onClick={() => setActivePage('home')}
              className={`transition ${
                activePage === 'home' ? 'text-blue-800 font-semibold' : 'text-gray-600 hover:text-blue-800'
              }`}
            >
              Home
            </button>
            <button
              onClick={() => setActivePage('jobs')}
              className={`transition ${
                activePage === 'jobs' ? 'text-blue-800 font-semibold' : 'text-gray-600 hover:text-blue-800'
              }`}
            >
              Jobs
            </button>
            <button
              onClick={() => setActivePage('dashboard')}
              className={`transition ${
                activePage === 'dashboard' ? 'text-blue-800 font-semibold' : 'text-gray-600 hover:text-blue-800'
              }`}
            >
              Dashboard
            </button>
            <button
              onClick={() => setActivePage('viewer')}
              className={`transition ${
                activePage === 'viewer' ? 'text-blue-800 font-semibold' : 'text-gray-600 hover:text-blue-800'
              }`}
            >
              Viewer
            </button>
          </nav>
        </div>
      </div>
    </header>
  )
}

export default Navigation
