import Brain from './icons/Brain.jsx'

function Navigation({ activePage, setActivePage }) {
  return (
    <header className="bg-white border-b border-blue-100 shadow-sm sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-6 py-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3 cursor-pointer" onClick={() => setActivePage('home')}>
            <div className="bg-[#003d7a] p-2 rounded-lg">
              <Brain className="w-8 h-8 text-white" />
            </div>
            <div className="flex items-center gap-3">
              <div>
                <h1 className="text-2xl font-bold text-gray-900">NeuroInsight-AutoHS</h1>
                <p className="text-xs text-gray-500">Hippocampal Analysis Platform</p>
              </div>
            </div>
          </div>
          <nav className="flex gap-6">
            <button
              onClick={() => setActivePage('home')}
              className={`transition border-none bg-transparent ${
                activePage === 'home' ? 'text-[#003d7a] font-semibold' : 'text-gray-600 hover:text-[#003d7a]'
              }`}
            >
              Home
            </button>
            <button
              onClick={() => setActivePage('jobs')}
              className={`transition border-none bg-transparent ${
                activePage === 'jobs' ? 'text-[#003d7a] font-semibold' : 'text-gray-600 hover:text-[#003d7a]'
              }`}
            >
              Jobs
            </button>
            <button
              onClick={() => setActivePage('dashboard')}
              className={`transition border-none bg-transparent ${
                activePage === 'dashboard' ? 'text-[#003d7a] font-semibold' : 'text-gray-600 hover:text-[#003d7a]'
              }`}
            >
              Dashboard
            </button>
            <button
              onClick={() => setActivePage('viewer')}
              className={`transition border-none bg-transparent ${
                activePage === 'viewer' ? 'text-[#003d7a] font-semibold' : 'text-gray-600 hover:text-[#003d7a]'
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
