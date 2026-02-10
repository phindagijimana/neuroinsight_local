import { useState, useEffect, useRef } from 'react'
import { apiService, API_BASE_URL } from '../utils/api.js'
import AlertCircle from '../components/icons/AlertCircle.jsx'
import ChevronLeft from '../components/icons/ChevronLeft.jsx'
import ChevronRight from '../components/icons/ChevronRight.jsx'
import ZoomIn from '../components/icons/ZoomIn.jsx'
import ZoomOut from '../components/icons/ZoomOut.jsx'
import Clock from '../components/icons/Clock.jsx'

function ViewerPage({ selectedJobId, setSelectedJobId, jobs }) {
  const [activeView, setActiveView] = useState(0);
  const [orientation, setOrientation] = useState('coronal'); // coronal or axial
  const [loading, setLoading] = useState(false);
  const [slices, setSlices] = useState([]);
  const [availableJobs, setAvailableJobs] = useState([]);
  const [maxSlice, setMaxSlice] = useState(9); // Start with expected 10 slices (0-9)
  const [zoomLevel, setZoomLevel] = useState(1.0);  // Zoom level: 1.0 = 100%, 2.0 = 200%, etc.
  const [overlayOpacity, setOverlayOpacity] = useState(0.6);  // Overlay opacity: 0.0 = only anatomical, 1.0 = full overlay
  const [imageLoadError, setImageLoadError] = useState(false);  // Track if current slice image failed to load
  const [slicesLoaded, setSlicesLoaded] = useState(new Set()); // Track which job/orientation combinations have had slices loaded
  const [rotation, setRotation] = useState(0); // Rotation: 0, 90, 180, 270 degrees (works for both axial and coronal)
  const [jobVisualizations, setJobVisualizations] = useState(null); // Store visualization data from API
  const shouldFlipVertical = orientation === 'coronal'; // Coronal slices are upside down; flip vertically

  // Zoom handlers
  const handleZoomIn = () => {
    setZoomLevel(prev => Math.min(prev + 0.25, 3.0)); // Max 300%
  };

  const handleZoomOut = () => {
    setZoomLevel(prev => Math.max(prev - 0.25, 0.5)); // Min 50%
  };

  const handleZoomReset = () => {
    setZoomLevel(1.0);
  };

  // Rotation handlers for both axial and coronal views
  const handleRotateClockwise = () => {
    setRotation(prev => (prev + 90) % 360);
  };

  const handleRotateCounterClockwise = () => {
    setRotation(prev => (prev - 90 + 360) % 360);
  };

  const handleRotateReset = () => {
    setRotation(0);
  };

  // Load available completed jobs from props
  useEffect(() => {
    if (jobs && jobs.length > 0) {
      const completedJobs = jobs.filter(j => (j.status || '').toLowerCase() === 'completed');
      setAvailableJobs(completedJobs);
      if (!selectedJobId && completedJobs.length > 0) {
        setSelectedJobId(completedJobs[0].id);
      }
    }
  }, [jobs, selectedJobId]);

  // Load slices when job or orientation changes
  const prevSelectedJobId = useRef(selectedJobId);
  const prevOrientation = useRef(orientation);

  useEffect(() => {
    const jobChanged = prevSelectedJobId.current !== selectedJobId;
    const orientationChanged = prevOrientation.current !== orientation;

    if (jobChanged || orientationChanged) {
      setSlicesLoaded(new Set());
      setJobVisualizations(null);
    }

    prevSelectedJobId.current = selectedJobId;
    prevOrientation.current = orientation;

    if (selectedJobId) {
      loadSlices();
      setImageLoadError(false);
    }
  }, [selectedJobId, orientation]);

  const loadSlices = async () => {
    if (!selectedJobId) return;

    const cacheKey = `${selectedJobId}_${orientation}`;
    if (slicesLoaded.has(cacheKey)) return;

    try {
      setLoading(true);

      const jobData = await apiService.getJob(selectedJobId);

      if (jobData && jobData.visualizations && jobData.visualizations.overlays) {
        const vizData = jobData.visualizations.overlays;
        setJobVisualizations(vizData);

        const actualSlices = [];
        if (vizData[orientation]) {
          actualSlices.push({
            slice: 0,
            anatomical: vizData[orientation].anatomical,
            overlay: vizData[orientation].hippocampus
          });
        }

        for (let i = 1; i < 10; i++) {
          if (vizData[orientation]) {
            actualSlices.push({
              slice: i,
              anatomical: vizData[orientation].anatomical,
              overlay: vizData[orientation].hippocampus
            });
          }
        }

        setSlices(actualSlices);
        setSlicesLoaded(prev => new Set([...prev, cacheKey]));
      } else {
        setSlices([]);
      }
    } catch (error) {
      console.error('Failed to load slices:', error);
      setSlices([]);
    } finally {
      setLoading(false);
    }
  };

  const getSliceUrls = (sliceIndex) => {
    if (!selectedJobId) return { anatomical: '', overlay: '' };

    const sliceId = sliceIndex < 100
      ? `slice_${String(sliceIndex).padStart(2, '0')}`
      : `slice_${sliceIndex}`;

    const ts = Date.now();

    return {
      anatomical: `${API_BASE_URL}/api/visualizations/${selectedJobId}/overlay/${sliceId}?orientation=${orientation}&layer=anatomical&v=${ts}`,
      overlay: `${API_BASE_URL}/api/visualizations/${selectedJobId}/overlay/${sliceId}?orientation=${orientation}&layer=overlay&v=${ts}`
    };
  };

  // Generate preview slices for the overview grid
  const previewSlices = Array.from({ length: 10 }, (_, i) => i);

  if (!selectedJobId || !jobVisualizations) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-white">
        <div className="max-w-[1800px] mx-auto px-6 py-4">
          <div className="bg-white rounded-xl shadow-sm border border-blue-100 p-4">
            <div className="text-center py-12">
              <AlertCircle className="w-16 h-16 text-gray-400 mx-auto mb-4" />
              <h2 className="text-xl font-semibold text-gray-900 mb-2">
                {selectedJobId ? 'Loading Visualizations...' : 'No Job Selected'}
              </h2>
              <p className="text-gray-600 mb-6">
                {selectedJobId
                  ? 'Loading brain slice visualizations for the selected job...'
                  : 'Please select a completed job to view 2D slice visualizations'
                }
              </p>
              {availableJobs.length > 0 ? (
                <div className="max-w-md mx-auto">
                  <label className="block text-sm font-medium text-gray-700 mb-2">Select Job:</label>
                  <select
                    value={selectedJobId || ''}
                    onChange={(e) => setSelectedJobId(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg px-4 py-2 text-sm"
                  >
                    <option value="">-- Select a job --</option>
                    {availableJobs.map(job => (
                      <option key={job.id} value={job.id}>
                        {job.id} - {job.input_file || job.filename || job.id}
                      </option>
                    ))}
                  </select>
                </div>
              ) : (
                <p className="text-gray-500">No completed jobs available. Please upload and process an MRI scan first.</p>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-white">
      <div className="max-w-7xl mx-auto px-6 py-4">

        <div className="grid md:grid-cols-1 gap-8">
          {/* Main Viewer */}
          <div className="md:col-span-1">
            {/* Controls at the top */}
            <div className="bg-white rounded-xl shadow-sm border border-blue-100 p-3 mb-4">
              <div className="flex flex-wrap items-center gap-6">
                {/* Orientation Selection */}
                <div className="flex items-center gap-3">
                  <label className="text-sm font-medium text-gray-700 whitespace-nowrap">
                    Orientation:
                  </label>
                  <select
                    id="orientation-select"
                    value={orientation}
                    onChange={(e) => setOrientation(e.target.value)}
                    className="rounded-lg px-4 py-2 text-sm font-semibold bg-blue-50 focus:ring-2 focus:ring-blue-600 focus:border-blue-600 appearance-none"
                    style={{
                      color: '#003d7a',
                      borderColor: '#003d7a',
                      border: '1px solid #003d7a',
                      backgroundColor: '#f8fafc'
                    }}
                  >
                    <option value="coronal">Coronal</option>
                    <option value="axial">Axial</option>
                  </select>
                </div>

                {/* Zoom Controls */}
                <div className="flex items-center gap-3">
                  <label className="text-sm font-medium text-gray-700 whitespace-nowrap">
                    Zoom:
                  </label>
                  <button
                    onClick={handleZoomOut}
                    disabled={zoomLevel <= 0.5}
                    className={`p-2 rounded-md transition ${zoomLevel <= 0.5 ? 'opacity-30 cursor-not-allowed text-gray-400' : 'hover:bg-blue-100 text-[#003d7a]'}`}
                    title="Zoom Out"
                  >
                    <ZoomOut className="w-5 h-5" />
                  </button>
                  <button
                    onClick={handleZoomReset}
                    className="px-3 py-2 hover:bg-blue-100 rounded-md transition text-sm font-semibold text-[#003d7a] min-w-[60px]"
                    title="Click to reset zoom"
                  >
                    {Math.round(zoomLevel * 100)}%
                  </button>
                  <button
                    onClick={handleZoomIn}
                    disabled={zoomLevel >= 3.0}
                    className={`p-2 rounded-md transition ${zoomLevel >= 3.0 ? 'opacity-30 cursor-not-allowed text-gray-400' : 'hover:bg-blue-100 text-[#003d7a]'}`}
                    title="Zoom In"
                  >
                    <ZoomIn className="w-5 h-5" />
                  </button>
                </div>

                {/* Overlay Opacity */}
                <div className="flex items-center gap-3 bg-white border border-blue-200 rounded-lg px-4 py-2">
                  <label className="text-sm font-medium text-gray-700 whitespace-nowrap">
                    Overlay Opacity:
                  </label>
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={overlayOpacity * 100}
                    onChange={(e) => setOverlayOpacity(parseInt(e.target.value) / 100)}
                    className="w-32 h-2 bg-blue-200 rounded-lg appearance-none cursor-pointer accent-[#003d7a]"
                    title={`Opacity: ${Math.round(overlayOpacity * 100)}%`}
                  />
                  <span className="text-sm font-semibold text-[#003d7a] min-w-[48px] text-right">
                    {Math.round(overlayOpacity * 100)}%
                  </span>
                </div>

                {/* Rotation Controls */}
                <div className="flex items-center gap-3">
                  <label className="text-sm font-medium text-gray-700 whitespace-nowrap">
                    Rotation:
                  </label>
                  <button
                    onClick={handleRotateCounterClockwise}
                    className="p-2 hover:bg-blue-100 rounded-md transition text-[#003d7a]"
                    title="Rotate Counter-Clockwise (-90 degrees)"
                  >
                    <ChevronLeft className="w-5 h-5" />
                  </button>
                  <button
                    onClick={handleRotateReset}
                    className="px-3 py-2 hover:bg-blue-100 rounded-md transition text-sm font-semibold text-[#003d7a] min-w-[60px]"
                    title="Reset Rotation (0 degrees)"
                  >
                    {rotation} degrees
                  </button>
                  <button
                    onClick={handleRotateClockwise}
                    className="p-2 hover:bg-blue-100 rounded-md transition text-[#003d7a]"
                    title="Rotate Clockwise (+90 degrees)"
                  >
                    <ChevronRight className="w-5 h-5" />
                  </button>
                </div>
              </div>
            </div>

            {/* L/R and color legend (viewer only) */}
            <div className="mb-4 rounded-lg border border-[#003d7a]/30 bg-[#003d7a]/10 px-4 py-3 text-center">
              <p className="text-sm font-medium text-gray-800">
                <span className="font-semibold text-[#003d7a]">L/R markers</span> indicate patient orientation (radiological view).
                <span className="mx-2 text-gray-500">|</span>
                <span className="inline-flex items-center gap-2">
                  <span className="w-4 h-4 rounded-full border border-gray-400 bg-[#0064ff] shrink-0" aria-hidden />
                  <span>Blue = left hippocampus</span>
                </span>
                <span className="mx-2 text-gray-500">|</span>
                <span className="inline-flex items-center gap-2">
                  <span className="w-4 h-4 rounded-full border border-gray-400 bg-[#e53935] shrink-0" aria-hidden />
                  <span>Red = right hippocampus</span>
                </span>
              </p>
            </div>

            <div className="relative bg-black rounded-xl overflow-auto mb-4" style={{ height: '600px' }}>
              {loading ? (
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="text-center text-white">
                    <Clock className="w-12 h-12 mx-auto mb-4 animate-spin opacity-50" />
                    <p className="text-gray-300">Loading slice image...</p>
                  </div>
                </div>
              ) : (
                <div className="flex items-center justify-center min-h-full">
                  <div
                    className="relative max-w-none"
                    style={{
                      transform: `scale(${zoomLevel})${shouldFlipVertical ? ' scaleY(-1)' : ''}${rotation !== 0 ? ` rotate(${rotation}deg)` : ''}`,
                      transformOrigin: 'center center',
                      transition: 'transform 0.2s ease-out',
                      cursor: zoomLevel > 1 ? 'move' : 'default'
                    }}
                  >
                    {/* Base layer: Anatomical T1 (grayscale) */}
                    <img
                      src={getSliceUrls(activeView).anatomical}
                      alt={`${orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slice ${activeView} - Anatomical`}
                      className="block"
                      style={{
                        display: 'block',
                        width: 'auto',
                        height: 'auto'
                      }}
                      onError={() => setImageLoadError(true)}
                    />
                    {/* Overlay layer: Hippocampus segmentation (colored, transparent PNG) */}
                    <img
                      src={getSliceUrls(activeView).overlay}
                      alt={`${orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slice ${activeView} - Overlay`}
                      className="block absolute top-0 left-0"
                      style={{
                        opacity: overlayOpacity,
                        transition: 'opacity 0.15s ease-out',
                        pointerEvents: 'none',
                        width: '100%',
                        height: '100%'
                      }}
                      onError={(e) => { e.target.style.display = 'none'; }}
                    />
                  </div>
                </div>
              )}

              {imageLoadError && (
                <div className="absolute inset-0 flex items-center justify-center bg-black pointer-events-none">
                  <div className="text-center text-white">
                    <AlertCircle className="w-16 h-16 mx-auto mb-4 opacity-50" />
                    <p className="text-gray-300">{orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slice {activeView} not available</p>
                  </div>
                </div>
              )}

              <div className="absolute top-6 right-6 bg-black/80 px-4 py-3 rounded-lg">
                <span className="text-white text-sm font-semibold">{orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slice: {activeView} / {maxSlice}</span>
              </div>
            </div>

            {/* Slice Navigation */}
            <div className="flex items-center gap-4 mb-6">
              <button
                onClick={() => setActiveView(Math.max(0, activeView - 1))}
                className="p-3 bg-[#003d7a] hover:bg-[#002b55] text-white rounded-lg transition"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
              <div className="flex-1">
                <input
                  type="range"
                  min="0"
                  max={maxSlice}
                  value={activeView}
                  onChange={(e) => setActiveView(parseInt(e.target.value))}
                  className="w-full h-2 bg-blue-200 rounded-lg appearance-none cursor-pointer accent-[#003d7a]"
                />
              </div>
              <button
                onClick={() => setActiveView(Math.min(maxSlice, activeView + 1))}
                className="p-3 bg-[#003d7a] hover:bg-[#002b55] text-white rounded-lg transition"
              >
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>

            {/* Multi-Slice Overview */}
            <div className="border-t border-blue-100 pt-4">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Multi-Slice Overview (All 10 {orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slices)</h3>
              <div className="grid grid-cols-5 gap-3">
                {previewSlices.map((slice) => {
                  const sliceUrls = getSliceUrls(slice);
                  return (
                    <div
                      key={slice}
                      onClick={() => setActiveView(slice)}
                      className={`relative bg-black rounded-lg overflow-hidden cursor-pointer transition transform hover:scale-105 ${
                        activeView === slice ? 'ring-4 ring-[#003d7a] shadow-xl' : 'hover:ring-2 hover:ring-blue-300'
                      }`}
                    >
                      <div className="w-24 h-24 flex items-center justify-center overflow-hidden relative">
                        <img
                          src={sliceUrls.anatomical}
                          alt={`${orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slice ${slice} - Anatomical`}
                          className="w-full h-full object-cover"
                          style={shouldFlipVertical ? { transform: 'scaleY(-1)' } : {}}
                          onError={(e) => { e.target.style.display = 'none'; }}
                        />
                        <img
                          src={sliceUrls.overlay}
                          alt={`${orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slice ${slice} - Overlay`}
                          className="absolute top-0 left-0 w-full h-full object-cover"
                          style={{
                            opacity: overlayOpacity,
                            pointerEvents: 'none',
                            ...(shouldFlipVertical ? { transform: 'scaleY(-1)' } : {})
                          }}
                          onError={(e) => { e.target.style.display = 'none'; }}
                        />
                      </div>
                      <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black via-black/80 to-transparent p-2">
                        <p className="text-white text-xs font-semibold text-center">{orientation.charAt(0).toUpperCase() + orientation.slice(1)} {slice}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default ViewerPage;
