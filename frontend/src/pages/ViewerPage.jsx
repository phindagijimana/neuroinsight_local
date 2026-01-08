import { useState, useEffect, useRef } from 'react'
import { apiService, API_BASE_URL } from '../utils/api.js'
import AlertCircle from '../components/icons/AlertCircle.jsx'
import ChevronLeft from '../components/icons/ChevronLeft.jsx'
import ChevronRight from '../components/icons/ChevronRight.jsx'
import ZoomIn from '../components/icons/ZoomIn.jsx'
import Clock from '../components/icons/Clock.jsx'

function ViewerPage({ selectedJobId, setSelectedJobId }) {
  // FORCE CACHE BUST TEST - If you see this, you have NEW CODE
  console.log(' NEW CODE LOADED - SLICE NAVIGATION FIX ACTIVE ');
  console.log('Current selectedJobId:', selectedJobId);

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
  const FLIP_VERTICAL = false; // No flip needed; backend overlays saved with correct orientation

  // Zoom handlers
  const handleZoomIn = () => {
    setZoomLevel(prev => Math.min(prev + 0.25, 3.0)); // Max 300%
  };

  const handleZoomReset = () => {
    setZoomLevel(1.0);
  };

  // Load available completed jobs
  useEffect(() => {
    loadAvailableJobs();
  }, []);

  // Load slices when job or orientation changes
  const prevSelectedJobId = useRef(selectedJobId);
  const prevOrientation = useRef(orientation);

  useEffect(() => {
    const jobChanged = prevSelectedJobId.current !== selectedJobId;
    const orientationChanged = prevOrientation.current !== orientation;

    console.log('useEffect triggered:', {
      selectedJobId_changed: jobChanged,
      orientation_changed: orientationChanged,
      prev_selectedJobId: prevSelectedJobId.current,
      new_selectedJobId: selectedJobId,
      prev_orientation: prevOrientation.current,
      new_orientation: orientation
    });

    // Clear slicesLoaded when job or orientation changes to allow fresh slice loading
    if (jobChanged || orientationChanged) {
      console.log('Clearing slicesLoaded cache due to job/orientation change');
      setSlicesLoaded(new Set());
    }

    prevSelectedJobId.current = selectedJobId;
    prevOrientation.current = orientation;

    if (selectedJobId) {
      loadSlices();
      setImageLoadError(false); // Reset error state when switching slices/orientation
    }
  }, [selectedJobId, orientation]); // Removed activeView dependency to prevent infinite loop

  // Debug: Watch all state changes
  useEffect(() => {
    console.log(`SELECTEDJOBID CHANGED: "${selectedJobId}"`);
    console.log(`Stack trace:`, new Error().stack);
  }, [selectedJobId]);

  useEffect(() => {
    console.log(`ORIENTATION CHANGED: "${orientation}"`);
    console.log(`Stack trace:`, new Error().stack);
  }, [orientation]);

  useEffect(() => {
    console.log(`ACTIVEVIEW CHANGED: ${activeView}`);
    console.log(`Stack trace:`, new Error().stack);
  }, [activeView]);

  const loadAvailableJobs = async () => {
    try {
      const data = await apiService.getJobs();
      const completedJobs = (data || []).filter(j => j.status === 'completed');
      setAvailableJobs(completedJobs);

      // Auto-select first completed job if none selected
      if (!selectedJobId && completedJobs.length > 0) {
        setSelectedJobId(completedJobs[0].id);
      }
    } catch (error) {
      console.error('Failed to load jobs:', error);
    }
  };

  const loadSlices = async () => {
    if (!selectedJobId) return;

    const cacheKey = `${selectedJobId}_${orientation}`;
    if (slicesLoaded.has(cacheKey)) {
      console.log(`Slices already loaded for ${cacheKey}, skipping`);
      return;
    }

    try {
      setLoading(true);
      console.log(`Loading slices for job ${selectedJobId}, orientation ${orientation}`);

      // For demo purposes, create mock slice data
      // In real implementation, this would fetch from backend
      const mockSlices = Array.from({ length: 10 }, (_, i) => ({
        slice: i,
        anatomical: `/api/placeholder/anatomical/${selectedJobId}/${orientation}/${i}.png`,
        overlay: `/api/placeholder/overlay/${selectedJobId}/${orientation}/${i}.png`
      }));

      setSlices(mockSlices);
      setSlicesLoaded(prev => new Set([...prev, cacheKey]));
      console.log(`Loaded ${mockSlices.length} slices for ${cacheKey}`);
    } catch (error) {
      console.error('Failed to load slices:', error);
    } finally {
      setLoading(false);
    }
  };

  const getSliceUrls = (sliceIndex) => {
    // Use the same URL structure as the original
    const ts = Date.now(); // Cache busting
    return {
      anatomical: `${API_BASE_URL}/visualizations/${selectedJobId}/overlay/${sliceIndex}?orientation=${orientation}&layer=anatomical&v=${ts}`,
      overlay: `${API_BASE_URL}/visualizations/${selectedJobId}/overlay/${sliceIndex}?orientation=${orientation}&layer=overlay&v=${ts}`
    };
  };

  // Generate preview slices for the overview grid
  const previewSlices = Array.from({ length: 10 }, (_, i) => i);

  if (!selectedJobId) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-white">
        <div className="max-w-7xl mx-auto px-6 py-8">
          <div className="flex justify-center items-center mb-8">
            <h1 className="text-3xl font-bold text-gray-900">Medical Image Viewer</h1>
          </div>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-12 text-center">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">No Job Selected</h2>
            <p className="text-gray-600 mb-6">
              Please select a completed job to view the 3D medical image visualization.
            </p>
            {availableJobs.length > 0 ? (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Select Job:</label>
                <select
                  value={selectedJobId || ''}
                  onChange={(e) => setSelectedJobId(e.target.value)}
                  className="w-full border border-gray-300 rounded-lg px-4 py-2 text-sm"
                >
                  <option value="">-- Select a job --</option>
                  {availableJobs.map(job => (
                    <option key={job.id} value={job.id}>{job.id} - {job.filename}</option>
                  ))}
                </select>
              </div>
            ) : (
              <p className="text-gray-500">No completed jobs available. Please upload and process an MRI scan first.</p>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-white">
      <div className="max-w-7xl mx-auto px-6 py-8">

        {/* Header */}
        <div className="flex justify-center items-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Medical Image Viewer</h1>
        </div>

        <div className="grid md:grid-cols-1 gap-8">
          {/* Main Viewer */}
          <div className="md:col-span-1">
            {/* Controls at the top */}
            <div className="bg-white rounded-xl shadow-sm border border-blue-100 p-6 mb-6">
              <div className="flex flex-wrap items-center gap-6">
                {/* Orientation Selection */}
                <div className="flex items-center gap-3">
                  <label className="text-sm font-medium text-gray-700 whitespace-nowrap">
                    Orientation:
                  </label>
                  <select
                    value={orientation}
                    onChange={(e) => setOrientation(e.target.value)}
                    className="px-4 py-2 border border-gray-300 rounded-lg bg-white text-sm font-medium focus:ring-2 focus:ring-blue-800 focus:border-blue-900"
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
                    onClick={handleZoomReset}
                    className="px-3 py-2 hover:bg-blue-100 rounded-md transition text-sm font-semibold text-blue-900 min-w-[60px]"
                    title="Click to reset zoom"
                  >
                    {Math.round(zoomLevel * 100)}%
                  </button>
                  <button
                    onClick={handleZoomIn}
                    disabled={zoomLevel >= 3.0}
                    className={`p-2 rounded-md transition ${zoomLevel >= 3.0 ? 'opacity-30 cursor-not-allowed text-gray-400' : 'hover:bg-blue-100 text-blue-800'}`}
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
                    className="w-32 h-2 bg-blue-200 rounded-lg appearance-none cursor-pointer accent-blue-800"
                    title={`Opacity: ${Math.round(overlayOpacity * 100)}%`}
                  />
                  <span className="text-sm font-semibold text-blue-900 min-w-[48px] text-right">
                    {Math.round(overlayOpacity * 100)}%
                  </span>
                </div>
              </div>
            </div>
            <div className="relative bg-black rounded-xl overflow-auto mb-6" style={{ height: '650px' }}>
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
                      transform: `scale(${zoomLevel})${FLIP_VERTICAL ? ' scaleY(-1)' : ''}`,
                      transformOrigin: 'center center',
                      transition: 'transform 0.2s ease-out',
                      cursor: zoomLevel > 1 ? 'move' : 'default'
                    }}
                  >
                    {/* Base layer: Anatomical T1 (grayscale) */}
                    <img
                      src={getSliceUrls(activeView).anatomical}
                      alt={`${orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slice ${activeView} - Anatomical`}
                      onLoad={() => console.log(`ANATOMICAL IMAGE LOADED: ${getSliceUrls(activeView).anatomical}`)}
                      className="block"
                      style={{
                        display: 'block',
                        width: 'auto',
                        height: 'auto'
                      }}
                      onError={(e) => {
                        console.error(`ANATOMICAL IMAGE LOAD ERROR: ${e.target.src}`);
                        setImageLoadError(true);
                      }}
                    />
                    {/* Overlay layer: Hippocampus segmentation (colored, transparent PNG) */}
                    <img
                      src={getSliceUrls(activeView).overlay}
                      alt={`${orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slice ${activeView} - Overlay`}
                      onLoad={() => console.log(`OVERLAY IMAGE LOADED: ${getSliceUrls(activeView).overlay}`)}
                      className="block absolute top-0 left-0"
                      style={{
                        opacity: overlayOpacity,
                        transition: 'opacity 0.15s ease-out',
                        pointerEvents: 'none',
                        width: '100%',
                        height: '100%'
                      }}
                      onError={(e) => {
                        console.error(`OVERLAY IMAGE LOAD ERROR: ${e.target.src}`);
                        // Just hide overlay if it fails, anatomical will still show
                        e.target.style.display = 'none';
                      }}
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
                onClick={() => {
                  console.log(`PREV BUTTON: current activeView=${activeView}, setting to ${Math.max(0, activeView - 1)}`);
                  setActiveView(Math.max(0, activeView - 1));
                }}
                className="p-3 bg-blue-800 hover:bg-blue-900 text-white rounded-lg transition"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
              <div className="flex-1">
                <input
                  type="range"
                  min="0"
                  max={maxSlice}
                  value={activeView}
                  onChange={(e) => {
                    const newValue = parseInt(e.target.value);
                    console.log(`Range slider: current activeView=${activeView}, setting to ${newValue}`);
                    setActiveView(newValue);
                  }}
                  className="w-full h-2 bg-blue-200 rounded-lg appearance-none cursor-pointer accent-blue-800"
                />
              </div>
              <button
                onClick={() => {
                  console.log(`NEXT BUTTON: current activeView=${activeView}, setting to ${Math.min(maxSlice, activeView + 1)}`);
                  setActiveView(Math.min(maxSlice, activeView + 1));
                }}
                className="p-3 bg-blue-800 hover:bg-blue-900 text-white rounded-lg transition"
              >
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>

            {/* Multi-Slice Overview */}
            <div className="border-t border-blue-100 pt-4">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Multi-Slice Overview (All 10 {orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slices)</h3>
              <div className="grid grid-cols-5 gap-3">
                {previewSlices.map((slice, idx) => {
                  const sliceUrls = getSliceUrls(slice);
                  return (
                    <div
                      key={slice}
                      onClick={() => setActiveView(slice)}
                      className={`relative bg-black rounded-lg overflow-hidden cursor-pointer transition transform hover:scale-105 ${
                        activeView === slice ? 'ring-4 ring-blue-800 shadow-xl' : 'hover:ring-2 hover:ring-blue-300'
                      }`}
                    >
                      <div className="w-24 h-24 flex items-center justify-center overflow-hidden relative">
                        {/* Base anatomical layer */}
                        <img
                          src={sliceUrls.anatomical}
                          alt={`${orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slice ${slice} - Anatomical`}
                          className="w-full h-full object-cover"
                          onError={(e) => {
                            e.target.style.display = 'none';
                          }}
                        />
                        {/* Overlay layer with opacity */}
                        <img
                          src={sliceUrls.overlay}
                          alt={`${orientation.charAt(0).toUpperCase() + orientation.slice(1)} Slice ${slice} - Overlay`}
                          className="absolute top-0 left-0 w-full h-full object-cover"
                          style={{
                            opacity: overlayOpacity,
                            pointerEvents: 'none'
                          }}
                          onError={(e) => {
                            e.target.style.display = 'none';
                          }}
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
