import Zap from '../components/icons/Zap.jsx'
import Activity from '../components/icons/Activity.jsx'
import CheckCircle from '../components/icons/CheckCircle.jsx'
import ChevronRight from '../components/icons/ChevronRight.jsx'
import Shield from '../components/icons/Shield.jsx'

function HomePage({ setActivePage }) {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-blue-50">
      <main className="max-w-7xl mx-auto px-6 py-16">
        <div className="grid md:grid-cols-2 gap-12 items-center">
          <div className="space-y-6">
            <h2 className="text-5xl font-bold text-gray-900 leading-tight">
              Automated Hippocampal
              <span className="text-blue-800"> Volumetric Analysis</span>
            </h2>

            <p className="text-lg text-gray-600 leading-relaxed">
              Advanced neuroimaging platform for processing T1-weighted MRI scans, computing hippocampal asymmetry indices, and detecting hippocampal sclerosis with precision and efficiency.
            </p>

            <div className="grid grid-cols-1 gap-3 pt-4">
              {[
                { icon: Zap, text: 'Fast automated segmentation with FreeSurfer' },
                { icon: Activity, text: 'Precise asymmetry index calculation' },
                { icon: CheckCircle, text: 'Clinical-grade HS classification' }
              ].map((feature, idx) => (
                <div key={idx} className="flex items-center gap-3">
                  <div className="bg-blue-100 p-2 rounded-lg">
                    <feature.icon className="w-5 h-5 text-blue-800" />
                  </div>
                  <span className="text-gray-700">{feature.text}</span>
                </div>
              ))}
            </div>

            <div className="pt-6">
              <button
                onClick={() => setActivePage('jobs')}
                className="group flex items-center gap-2 bg-blue-800 text-white px-8 py-4 rounded-xl font-semibold text-lg hover:bg-blue-900 transition shadow-lg hover:shadow-xl"
              >
                Get Started
                <ChevronRight className="w-5 h-5 group-hover:translate-x-1 transition" />
              </button>
            </div>
          </div>

          <div className="relative">
            <div className="absolute top-10 right-10 w-72 h-72 rounded-full filter blur-3xl opacity-60 animate-pulse" style={{ backgroundColor: '#1e40af' }}></div>
            <div className="absolute bottom-10 left-10 w-72 h-72 rounded-full filter blur-3xl opacity-60 animate-pulse" style={{ backgroundColor: '#1e40af', animationDelay: '1s' }}></div>

            <div className="relative bg-white rounded-2xl shadow-2xl p-8 border border-blue-100">
              <svg viewBox="0 0 400 400" className="w-full h-auto">
                <defs>
                  <linearGradient id="brainGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#1e40af" stopOpacity="0.8" />
                    <stop offset="100%" stopColor="#1e40af" stopOpacity="0.6" />
                  </linearGradient>
                </defs>

                {/* Brain outline */}
                <ellipse cx="200" cy="200" rx="150" ry="170" fill="#eff6ff" stroke="#1e40af" strokeWidth="3"/>
                <line x1="200" y1="30" x2="200" y2="370" stroke="#1e40af" strokeWidth="2" strokeDasharray="5,5" opacity="0.3"/>

                {/* Neural pathways - Left side */}
                <path d="M 80 150 Q 100 100, 150 120 T 180 160" fill="none" stroke="#1e40af" strokeWidth="2" opacity="0.7"/>
                <path d="M 70 200 Q 90 180, 130 190 T 170 210" fill="none" stroke="#1e40af" strokeWidth="2" opacity="0.7"/>
                <path d="M 85 250 Q 110 230, 150 245 T 180 270" fill="none" stroke="#1e40af" strokeWidth="2" opacity="0.7"/>

                {/* Neural pathways - Right side */}
                <path d="M 320 150 Q 300 100, 250 120 T 220 160" fill="none" stroke="#1e40af" strokeWidth="2" opacity="0.7"/>
                <path d="M 330 200 Q 310 180, 270 190 T 230 210" fill="none" stroke="#1e40af" strokeWidth="2" opacity="0.7"/>
                <path d="M 315 250 Q 290 230, 250 245 T 220 270" fill="none" stroke="#1e40af" strokeWidth="2" opacity="0.7"/>

                {/* Left Hippocampus - Animated */}
                <ellipse cx="140" cy="260" rx="25" ry="50" fill="url(#brainGradient)" opacity="0.8">
                  <animate attributeName="opacity" values="0.6;0.9;0.6" dur="3s" repeatCount="indefinite" />
                </ellipse>
                <text x="140" y="335" fill="#1e40af" fontSize="16" fontWeight="bold" textAnchor="middle">L</text>

                {/* Right Hippocampus - Animated with delay */}
                <ellipse cx="260" cy="260" rx="23" ry="48" fill="url(#brainGradient)" opacity="0.8">
                  <animate attributeName="opacity" values="0.6;0.9;0.6" dur="3s" repeatCount="indefinite" begin="0.5s" />
                </ellipse>
                <text x="260" y="335" fill="#1e40af" fontSize="16" fontWeight="bold" textAnchor="middle">R</text>

                {/* Measurement circles */}
                <circle cx="140" cy="260" r="55" fill="none" stroke="#1e40af" strokeWidth="2" strokeDasharray="3,3" opacity="0.5"/>
                <circle cx="260" cy="260" r="55" fill="none" stroke="#1e40af" strokeWidth="2" strokeDasharray="3,3" opacity="0.5"/>
              </svg>

              <div className="mt-4 text-center">
                <p className="text-sm text-gray-500">Hippocampal Regions Highlighted</p>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-24 grid md:grid-cols-3 gap-8">
          {[
            {
              icon: Shield,
              title: 'HIPAA Compliant',
              description: 'Enterprise-grade security and privacy protection for patient data'
            },
            {
              icon: Zap,
              title: 'Fast Processing',
              description: 'Automated pipeline delivers results in minutes, not hours'
            },
            {
              icon: Activity,
              title: 'Clinical Accuracy',
              description: 'Validated asymmetry thresholds for hippocampal sclerosis detection'
            }
          ].map((feature, idx) => (
            <div key={idx} className="bg-white rounded-xl p-6 shadow-lg border border-blue-100 hover:shadow-xl transition">
              <div className="bg-blue-100 w-12 h-12 rounded-lg flex items-center justify-center mb-4">
                <feature.icon className="w-6 h-6 text-blue-800" />
              </div>
              <h4 className="text-xl font-bold text-gray-900 mb-2">{feature.title}</h4>
              <p className="text-gray-600">{feature.description}</p>
            </div>
          ))}
        </div>
      </main>
    </div>
  )
}

export default HomePage
