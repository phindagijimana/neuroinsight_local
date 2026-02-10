"""
Report generation API for creating PDF reports.

Report content comes from the same sources as the UI:
- Data: same as dashboard page (job and metrics from the database).
- Images: same as viewer page (coronal slice PNGs from the job's visualization output;
  the viewer serves or generates these at visualizations/overlays/coronal/).
We read job + metrics from the DB and composite images from that path into the PDF.
"""

import io
from pathlib import Path
from datetime import datetime

import numpy as np
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

try:
    from PIL import Image as PILImage
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    print("Warning: PIL/Pillow not available. Image combination will not work.")

from backend.core.config import get_settings
from backend.core.database import get_db
from backend.core.logging import get_logger
from backend.models import Job
from backend.models.job import JobStatus
from backend.services import MetricService

try:
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
    from reportlab.lib import colors
    REPORTLAB_AVAILABLE = True
except ImportError:
    REPORTLAB_AVAILABLE = False
    print("Warning: reportlab not available. PDF generation will not work.")

logger = get_logger(__name__)
settings = get_settings()

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/{job_id}/pdf")
async def generate_pdf_report(
    job_id: str,
    db: Session = Depends(get_db),
):
    """
    Generate a comprehensive PDF report for a completed job.

    Includes:
    - Patient information
    - Hippocampal volume metrics
    - Asymmetry analysis
    - Coronal visualizations with L/R markers and color legend (Blue=left, Red=right hippocampus).
    """
    if not REPORTLAB_AVAILABLE:
        raise HTTPException(
            status_code=500,
            detail="PDF generation not available. Please install reportlab: pip install reportlab"
        )

    # Validate job exists and is completed (use DB directly)
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    if job.status != JobStatus.COMPLETED:
        raise HTTPException(
            status_code=400,
            detail=f"Job is not completed (status: {job.status}). Reports can only be generated for completed jobs."
        )

    metrics = MetricService.get_metrics_by_job(db, job_id)
    if not metrics:
        raise HTTPException(status_code=400, detail="No metrics available for this job")

    # Report = dashboard data (job + metrics above) + viewer images (coronal PNGs from job result path)
    try:
        pdf_buffer = io.BytesIO()
        doc = SimpleDocTemplate(pdf_buffer, pagesize=A4)
        styles = getSampleStyleSheet()
        dashboard_blue = colors.Color(0/255, 61/255, 122/255)

        table_title_style = ParagraphStyle(
            'TableTitle',
            parent=styles['Heading2'],
            alignment=0,
        )

        story = []

        # Title
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            spaceAfter=30,
            alignment=1,
        )
        story.append(Paragraph("NeuroInsight Hippocampal Analysis Report", title_style))
        story.append(Spacer(1, 12))

        report_date = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
        story.append(Paragraph(f"Generated: {report_date}", ParagraphStyle('Metadata', parent=styles['Normal'], fontSize=10, textColor=colors.gray, alignment=1)))
        story.append(Paragraph(f"Job ID: {job_id}", ParagraphStyle('Metadata', parent=styles['Normal'], fontSize=10, textColor=colors.gray, alignment=1)))
        story.append(Spacer(1, 24))

        # Patient Information
        story.append(Paragraph("Patient Information", table_title_style))
        story.append(Spacer(1, 12))
        age_sex = f"{job.patient_age if job.patient_age else 'N/A'} / {job.patient_sex or 'N/A'}"
        patient_data = [
            ["Item", "Information"],
            ["Patient ID", job.patient_id or job.id],
            ["Age / Sex", age_sex],
            ["Scan Date", job.created_at.strftime("%Y-%m-%d") if job.created_at else "N/A"],
            ["Scanner", job.scanner_info or "N/A"],
        ]
        if job.notes and job.notes != "Uploaded as nii.gz file." and not (job.notes or "").startswith("Uploaded as"):
            clean_notes = (job.notes or "").split(" | Uploaded as")[0].strip()
            if clean_notes:
                patient_data.append(["Notes", clean_notes])

        patient_table = Table(patient_data, colWidths=[2.5*inch, 4.5*inch])
        patient_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), dashboard_blue),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('GRID', (0, 0), (-1, -1), 1, dashboard_blue),
        ]))
        story.append(patient_table)
        story.append(Spacer(1, 24))

        # Hippocampal Volume
        story.append(Paragraph("Hippocampal Volume", table_title_style))
        story.append(Spacer(1, 12))
        left_total = sum(m.left_volume for m in metrics if hasattr(m, 'left_volume'))
        right_total = sum(m.right_volume for m in metrics if hasattr(m, 'right_volume'))
        volume_data = [
            ["Left Hippocampal Volume", "Right Hippocampal Volume"],
            [f"{left_total:.2f} mm³", f"{right_total:.2f} mm³"],
        ]
        volume_table = Table(volume_data, colWidths=[3.5*inch, 3.5*inch])
        volume_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), dashboard_blue),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('GRID', (0, 0), (-1, -1), 1, dashboard_blue),
        ]))
        story.append(volume_table)
        story.append(Spacer(1, 24))

        # Interpretation
        story.append(Paragraph("Interpretation", table_title_style))
        story.append(Spacer(1, 12))
        asymmetry_index = ((left_total - right_total) / (left_total + right_total)) if (left_total + right_total) > 0 else 0
        LEFT_HS_THRESHOLD = -0.070839747728063
        RIGHT_HS_THRESHOLD = 0.046915816971433
        ai_decimal = asymmetry_index
        if ai_decimal > RIGHT_HS_THRESHOLD:
            classification = 'Left-dominant (Right HS suspected)'
        elif ai_decimal < LEFT_HS_THRESHOLD:
            classification = 'Right-dominant (Left HS suspected)'
        else:
            classification = 'Balanced (No HS)'
        thresholds_info = f"""Thresholds:

• Left HS (Right-dominant) if AI < {LEFT_HS_THRESHOLD:.12f}
• Right HS (Left-dominant) if AI > {RIGHT_HS_THRESHOLD:.12f}
• No HS (Balanced) otherwise."""
        laterization = f"{classification}\n\n{thresholds_info}"
        laterization_paragraph = Paragraph(laterization.replace('\n', '<br/>'), styles['Normal'])
        interpretation_data = [
            ["Asymmetry Index", "Laterization"],
            [f"{asymmetry_index:.3f}\n\nFormula: (L-R)/(L+R)", laterization_paragraph],
        ]
        interpretation_table = Table(interpretation_data, colWidths=[3.5*inch, 3.5*inch])
        interpretation_table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), dashboard_blue),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.white),
            ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 11),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.white),
            ('VALIGN', (0, 1), (-1, 1), 'TOP'),
            ('ALIGN', (1, 1), (1, 1), 'LEFT'),
            ('GRID', (0, 0), (-1, -1), 1, dashboard_blue),
        ]))
        story.append(interpretation_table)
        story.append(Spacer(1, 24))

        # Coronal Visualizations
        story.append(Paragraph("Coronal Visualizations", styles['Heading2']))
        story.append(Spacer(1, 12))
        viz_note = Paragraph(
            "The following images show coronal slices with anatomical T1-weighted background and hippocampal segmentation overlays "
            "(30% opacity) combined. Images are rotated 180 degrees for optimal report viewing. Slices 3, 4, 5, and 6 are displayed "
            "in a 2x2 grid to provide comprehensive visualization of the hippocampal regions.",
            styles['Normal']
        )
        story.append(viz_note)
        story.append(Spacer(1, 6))

        # L/R and color legend for report (clearly visible)
        orientation_style = ParagraphStyle(
            'OrientationLegend',
            parent=styles['Normal'],
            fontSize=10,
            textColor=colors.HexColor('#000000'),
            alignment=0,
            spaceBefore=6,
            spaceAfter=6,
        )
        orientation_legend = Paragraph(
            "<b>L/R markers</b> indicate patient orientation (radiological view): left side of image = patient's left, right side = patient's right. "
            "<b>Color coding:</b> Blue = left hippocampus, Red = right hippocampus.",
            orientation_style
        )
        story.append(orientation_legend)
        story.append(Spacer(1, 12))

        coronal_slices = [3, 4, 5, 6]
        if not job.result_path:
            raise HTTPException(status_code=400, detail="Job has no result path; cannot include visualizations.")
        # Same path the viewer uses: visualizations API serves/generates PNGs under this directory
        base_viz_path = Path(job.result_path) / "visualizations" / "overlays" / "coronal"
        images_data = []

        for slice_idx in coronal_slices:
            try:
                slice_id = f"slice_{slice_idx:02d}"
                anatomical_path = base_viz_path / f"anatomical_{slice_id}.png"
                overlay_path = base_viz_path / f"hippocampus_overlay_{slice_id}.png"

                if anatomical_path.exists() and overlay_path.exists():
                    anatomical_img = PILImage.open(anatomical_path)
                    overlay_img = PILImage.open(overlay_path)
                    if anatomical_img.mode != 'RGBA':
                        anatomical_img = anatomical_img.convert('RGBA')
                    if overlay_img.mode != 'RGBA':
                        overlay_img = overlay_img.convert('RGBA')
                    if anatomical_img.size != overlay_img.size:
                        anatomical_img = anatomical_img.resize(overlay_img.size, PILImage.LANCZOS)

                    anatomical_array = np.array(anatomical_img)
                    overlay_array = np.array(overlay_img)
                    anatomical_img = anatomical_img.rotate(180)
                    overlay_img = overlay_img.rotate(180)
                    anatomical_array = np.array(anatomical_img)
                    overlay_array = np.array(overlay_img)

                    opacity = 0.30
                    composite_array = anatomical_array.copy()
                    overlay_mask = overlay_array[:, :, 3] > 0
                    composite_array[overlay_mask] = (
                        opacity * overlay_array[overlay_mask] +
                        (1 - opacity) * anatomical_array[overlay_mask]
                    ).astype(np.uint8)

                    composite_img = PILImage.fromarray(composite_array, 'RGBA')
                    if composite_img.mode != 'RGB':
                        composite_img = composite_img.convert('RGB')

                    composite_buffer = io.BytesIO()
                    composite_img.save(composite_buffer, format='PNG')
                    composite_buffer.seek(0)

                    img_width, img_height = composite_img.size
                    cell_width, cell_height = 3.0*inch, 2.2*inch
                    scale = min(cell_width / img_width, cell_height / img_height)
                    display_width, display_height = img_width * scale, img_height * scale

                    img = Image(composite_buffer, width=display_width, height=display_height)
                    display_slice_num = slice_idx + 3
                    title_para = Paragraph(
                        f"Slice {display_slice_num}<br/><font size=8>(Coronal View)</font>",
                        ParagraphStyle('SliceTitle', parent=styles['Normal'], fontSize=10, alignment=1, spaceAfter=6)
                    )
                    images_data.append([title_para, img])
                else:
                    display_slice_num = slice_idx + 3
                    placeholder = Paragraph(
                        f"Slice {display_slice_num}<br/>Images not found",
                        ParagraphStyle('Placeholder', parent=styles['Normal'], fontSize=9, alignment=1, textColor=colors.gray)
                    )
                    images_data.append([Paragraph(f"Slice {display_slice_num}", ParagraphStyle('SliceTitle', parent=styles['Normal'], fontSize=10, alignment=1, spaceAfter=6)), placeholder])
            except Exception as e:
                logger.error("Error creating composite for slice %s: %s", slice_idx, e)
                display_slice_num = slice_idx + 3
                error_placeholder = Paragraph(
                    f"Slice {display_slice_num}<br/>Error creating composite",
                    ParagraphStyle('ErrorPlaceholder', parent=styles['Normal'], fontSize=9, alignment=1, textColor=colors.gray)
                )
                images_data.append([Paragraph(f"Slice {display_slice_num}", ParagraphStyle('SliceTitle', parent=styles['Normal'], fontSize=10, alignment=1, spaceAfter=6)), error_placeholder])

        if images_data:
            # L/R row above grid (clearly visible)
            l_style = ParagraphStyle('Llabel', parent=styles['Normal'], fontSize=12, alignment=0, textColor=colors.HexColor('#003d7a'))
            r_style = ParagraphStyle('Rlabel', parent=styles['Normal'], fontSize=12, alignment=2, textColor=colors.HexColor('#003d7a'))
            lr_row = Table(
                [[Paragraph("<b>L</b> (patient left)", l_style), Paragraph("<b>R</b> (patient right)", r_style)]],
                colWidths=[3.5*inch, 3.5*inch], rowHeights=[0.28*inch]
            )
            lr_row.setStyle(TableStyle([
                ('ALIGN', (0, 0), (0, 0), 'LEFT'),
                ('ALIGN', (1, 0), (1, 0), 'RIGHT'),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('LEFTPADDING', (0, 0), (-1, -1), 6),
                ('RIGHTPADDING', (0, 0), (-1, -1), 6),
            ]))
            story.append(lr_row)
            story.append(Spacer(1, 4))

            grid_data = [
                [images_data[0][1], images_data[1][1]],
                [images_data[2][1], images_data[3][1]]
            ]
            img_table = Table(grid_data, colWidths=[3.5*inch, 3.5*inch], rowHeights=[2.5*inch, 2.5*inch])
            img_table.setStyle(TableStyle([
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                ('LEFTPADDING', (0, 0), (-1, -1), 6),
                ('RIGHTPADDING', (0, 0), (-1, -1), 6),
                ('TOPPADDING', (0, 0), (-1, -1), 6),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ]))
            story.append(img_table)
            story.append(Spacer(1, 12))
            grid_caption = Paragraph(
                "Figure: Coronal slices 3, 4 (top row) and 5, 6 (bottom row) showing T1-weighted anatomical images with hippocampal segmentation overlays at 30% opacity (rotated 180 degrees for optimal viewing).",
                ParagraphStyle('GridCaption', parent=styles['Normal'], fontSize=9, textColor=colors.gray, alignment=1)
            )
            story.append(grid_caption)
            story.append(Spacer(1, 8))
            # Repeat legend below figure so it is visible
            legend_below = Paragraph(
                "L/R = patient orientation (radiological view). Blue = left hippocampus, Red = right hippocampus.",
                ParagraphStyle('LegendBelow', parent=styles['Normal'], fontSize=9, textColor=colors.HexColor('#333333'), alignment=1)
            )
            story.append(legend_below)
            story.append(Spacer(1, 18))

        doc.build(story)
        pdf_buffer.seek(0)
        filename = f"neuroinsight_report_{job_id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.pdf"
        return StreamingResponse(
            io.BytesIO(pdf_buffer.getvalue()),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )

    except Exception as e:
        logger.error("PDF generation failed for job %s: %s", job_id, e)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate PDF report: {str(e)}"
        )
