# Report vs Viewer Orientation – Checklist for GitHub

If **report images appear upside down** while the **viewer shows them upright**, the cause is usually a mismatch between where the report gets its images and where the viewer gets them.

---

## Why report and viewer can differ

| Source | Viewer | Report |
|--------|--------|--------|
| **Data** | API on the fly: `GET /visualizations/{job_id}/overlay/slice_XX?orientation=coronal&layer=...` | Pre-generated PNGs on disk from the pipeline |
| **Backend** | `backend/api/visualizations.py` — applies transpose + `flipud` for coronal (and LIA) so “superior at top” | N/A (report does not call this) |
| **Pipeline** | N/A | `pipeline/utils/visualization.py` — writes PNGs to `result_path/visualizations/overlays/coronal/` during job processing |
| **Frontend** | Uses API images; `shouldFlipVertical = false` when backend is correct | N/A (report embeds PNGs as-is) |

So:

- **Viewer upright** → API in `visualizations.py` is applying the right orientation (transpose + flipud for coronal).
- **Report upside down** → Either the **pipeline** PNGs were written with wrong orientation, or the report is using old PNGs from before orientation fixes.

---

## What must be on GitHub for both to match

1. **`backend/api/visualizations.py`**
   - For coronal (and LIA/RAS), slice data must be transposed and then `np.flipud(slice_data)` so that “superior at top” is consistent.
   - Search for `flipud` and `transpose.*(1, 0, 2)` for coronal branches; all coronal paths should have this.

2. **`pipeline/utils/visualization.py`**
   - For **coronal**, the same convention: transpose then `np.flipud` so the array is (S, L) with row 0 = superior before `imshow(..., origin='upper')`.
   - So the PNGs written to `.../overlays/coronal/` (e.g. `anatomical_slice_XX.png`, `hippocampus_overlay_slice_XX.png`) are already “head at top”; the report uses them as-is.

3. **`backend/api/reports.py`**
   - Uses `Path(job.result_path) / "visualizations" / "overlays" / "coronal"` and expects:
     - `anatomical_slice_03.png` … `anatomical_slice_06.png`
     - `hippocampus_overlay_slice_03.png` … `hippocampus_overlay_slice_06.png`
   - No extra flip in the report; it assumes pipeline wrote “superior at top”.

4. **Frontend (viewer)**
   - **`index.dev.html`** and **`index.html`** (and any `ViewerPage.jsx`): use **`shouldFlipVertical = false`** when the backend is fixed, so the viewer does not flip coronal again. Otherwise you can get:
     - Viewer correct + report wrong (if only API is fixed), or
     - Viewer wrong (double flip) if both backend and frontend flip.

---

## Quick checks on GitHub

- In **`backend/api/visualizations.py`**: coronal branches for `('L','S','P')`, `('L','I','A')`, `('R','A','S')` (and fallback) all do transpose + `np.flipud` for coronal.
- In **`pipeline/utils/visualization.py`**: for `orientation == 'coronal'`, after slicing you have `t1_slice = t1_slice.T` and `t1_slice = np.flipud(t1_slice)` (and same for seg_slice) before saving PNGs.
- In **`frontend/index.html`** and **`index.dev.html`**: `shouldFlipVertical = false` (no coronal flip in the viewer).

---

## If the report is still upside down after pushing

1. **Re-run a job** so new PNGs are generated with the current pipeline (current `visualization.py`). Old jobs may have been run before the orientation fix.
2. **Confirm path**: report reads from `job.result_path/visualizations/overlays/coronal/`; pipeline must write exactly there with the filenames above.
3. **Confirm pipeline orientation**: In `generate_segmentation_overlays`, for coronal, the display array must be (S, L) with row 0 = superior before `imshow`/save; that matches the transpose+flipud logic.

---

## Local-only reference

See **`LOCAL_ONLY_FIXES_ORIENTATION_REPORT_VIEWER.md`** in the repo root for a detailed list of orientation/report/viewer changes that were kept local during testing; ensure the same logic is present on GitHub for report and viewer to match.
