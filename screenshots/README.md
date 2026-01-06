# NeuroInsight Screenshots for README.md

## Required Screenshots (4 total):
1. **home_page.png** - Main NeuroInsight homepage with navigation
2. **jobs_page.png** - Job management page showing processing queue
3. **dashboard_page.png** - Real-time dashboard with metrics and status
4. **viewer_page.png** - 3D brain viewer with hippocampal segmentation

## Screenshot Specifications:
- **Format**: PNG (high quality)
- **Resolution**: 1200x800px or similar web-friendly size
- **Content**: Show realistic sample data (not placeholder text)
- **Browser**: Modern browser (Chrome, Firefox, Safari)
- **Timing**: Capture when page is fully loaded

## How to Create Screenshots:

### Prerequisites:
- GUI environment (local machine or VNC)
- Modern web browser installed
- NeuroInsight running locally

### Step-by-Step Process:
1. **Start NeuroInsight**:
   ```bash
   cd neuroinsight_app
   ./install.sh    # If not done already
   ./start.sh      # Start all services
   ```

2. **Access Application**:
   - Open browser to `http://localhost:8000`
   - Wait for full page load
   - Ensure all services are running (`./status.sh`)

3. **Take Screenshots**:

   **📄 Home Page** (`screenshots/home_page.png`):
   - Main landing page
   - Include navigation menu
   - Show welcome content

   **📋 Jobs Page** (`screenshots/jobs_page.png`):
   - Navigate to Jobs section
   - Show sample job entries with realistic data
   - Include status indicators and progress bars

   **📊 Dashboard Page** (`screenshots/dashboard_page.png`):
   - System metrics and statistics
   - Processing status overview
   - Real-time data visualization

   **👁️ Viewer Page** (`screenshots/viewer_page.png`):
   - 3D brain visualization
   - Hippocampal segmentation results
   - Interactive viewer controls

4. **Save Files**:
   - Save as PNG format
   - Use exact filenames above
   - Place in `screenshots/` directory
   - Optimize file size (100-300KB each)

5. **Commit to Repository**:
   ```bash
   git add screenshots/*.png
   git commit -m "Add NeuroInsight interface screenshots with sample data"
   git push origin master
   ```

## Sample Data Guidelines:
- Use realistic but anonymized patient data
- Show completed jobs with metrics
- Include various job statuses (running, completed, etc.)
- Demonstrate actual NeuroInsight functionality
- Avoid placeholder text or empty states

## Quality Checklist:
- [ ] Screenshots are clear and readable
- [ ] Sample data looks realistic
- [ ] Interface shows actual NeuroInsight branding
- [ ] All 4 required screenshots present
- [ ] Files are optimized for web viewing
