"""
Report generation API for creating PDF reports with dashboard data and visualizations.

This module provides endpoints for generating comprehensive PDF reports that include
all dashboard content plus coronal visualizations for specified slices.
"""

import io
import uuid
from pathlib import Path
from typing import List, Optional
from datetime import datetime

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
from backend.services import JobService, MetricService

try:
    from reportlab.pdfgen import canvas
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
    from reportlab.lib import colors
    REPORTLAB_AVAILABLE = True
except ImportError:
    REPORTLAB_AVAILABLE = False
    print("Warning: reportlab not available. PDF generation will not work.")

# Note: requests no longer needed for report generation - images read directly from filesystem

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
    - Processing metadata
    - Hippocampal volume metrics
    - Asymmetry analysis
    - Coronal visualizations (slices 3, 4, 5, 6)

    Args:
        job_id: Job identifier

    Returns:
        PDF file as streaming response
    """
    if not REPORTLAB_AVAILABLE:
        raise HTTPException(
            status_code=500,
            detail="PDF generation not available. Please install reportlab: pip install reportlab"
        )

    # Note: Images are now read directly from filesystem, no external requests needed

    # Validate job exists and is completed
    job = JobService.get_job(db, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    if job.status != JobStatus.COMPLETED:
        raise HTTPException(
            status_code=400,
            detail=f"Job is not completed (status: {job.status}). Reports can only be generated for completed jobs."
        )

    # Get metrics
    metrics = MetricService.get_metrics_by_job(db, job_id)
    if not metrics:
        raise HTTPException(status_code=400, detail="No metrics available for this job")

    try:
        # Generate PDF
        pdf_buffer = io.BytesIO()
        doc = SimpleDocTemplate(pdf_buffer, pagesize=A4)
        styles = getSampleStyleSheet()

        # Define custom colors matching dashboard theme
        # Custom NeuroInsight blue: #000080
        dashboard_blue = colors.HexColor('#000080')

        # Create left-aligned heading style for table titles to match table content
        table_title_style = ParagraphStyle(
            'TableTitle',
            parent=styles['Heading2'],
            alignment=0,  # 0 = LEFT, 1 = CENTER, 2 = RIGHT
        )

        story = []

        # Title
        title_style = ParagraphStyle(
            'CustomTitle',
            parent=styles['Heading1'],
            fontSize=24,
            spaceAfter=30,
            alignment=1,  # Center
        )
        story.append(Paragraph("NeuroInsight Hippocampal Analysis Report", title_style))
        story.append(Spacer(1, 12))

        # Report metadata
        metadata_style = ParagraphStyle(
            'Metadata',
            parent=styles['Normal'],
            fontSize=10,
            textColor=colors.gray,
            alignment=1,
        )
        report_date = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
        story.append(Paragraph(f"Generated: {report_date}", metadata_style))
        story.append(Paragraph(f"Job ID: {job_id}", metadata_style))
        story.append(Spacer(1, 24))

        # Patient Information
        story.append(Paragraph("Patient Information", table_title_style))
        story.append(Spacer(1, 12))

        patient_data = [
            ["Item", "Information"],  # Header row
            ["Patient ID", job.patient_id or "N/A"],
            ["Patient Name", job.patient_name or "N/A"],
            ["Age", str(job.patient_age) if job.patient_age else "N/A"],
            ["Sex", job.patient_sex or "N/A"],
            ["Scan Date", job.created_at.strftime("%Y-%m-%d") if job.created_at else "N/A"],
            ["Processed Date", job.completed_at.strftime("%Y-%m-%d %H:%M") if job.completed_at else "N/A"],
            ["Scanner", job.scanner_info or "N/A"],
            ["Sequence", job.sequence_info or "T1-MPRAGE"],
        ]

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

        # Calculate totals
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

        # Calculate asymmetry index and laterization
        asymmetry_index = ((left_total - right_total) / (left_total + right_total)) if (left_total + right_total) > 0 else 0

        # Determine laterization based on HS thresholds (same as dashboard)
        LEFT_HS_THRESHOLD = -0.070839747728063
        RIGHT_HS_THRESHOLD = 0.046915816971433

        ai_decimal = asymmetry_index  # No conversion needed
        if ai_decimal > RIGHT_HS_THRESHOLD:
            classification = 'Left-dominant (Right HS suspected)'
        elif ai_decimal < LEFT_HS_THRESHOLD:
            classification = 'Right-dominant (Left HS suspected)'
        else:
            classification = 'Balanced (No HS)'

        # Add threshold information as bullet points
        thresholds_info = f"""Thresholds:

• Left HS (Right-dominant) if AI < {LEFT_HS_THRESHOLD:.12f}
• Right HS (Left-dominant) if AI > {RIGHT_HS_THRESHOLD:.12f}
• No HS (Balanced) otherwise."""

        laterization = f"{classification}\n\n{thresholds_info}"

        # Create a properly formatted paragraph for the laterization cell
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
            ('ALIGN', (1, 1), (1, 1), 'LEFT'),  # Left-align the laterization column
            ('GRID', (0, 0), (-1, -1), 1, dashboard_blue),
        ]))
        story.append(interpretation_table)
        story.append(Spacer(1, 24))

        # Clinical Notes (if any)
        if job.notes:
            story.append(Paragraph("Clinical Notes", styles['Heading3']))
            story.append(Spacer(1, 6))
            notes_style = ParagraphStyle(
                'Notes',
                parent=styles['Normal'],
                fontSize=11,
                leftIndent=20,
            )
            story.append(Paragraph(job.notes, notes_style))
            story.append(Spacer(1, 24))

        # Coronal Visualizations Section
        story.append(Paragraph("Coronal Visualizations", styles['Heading2']))
        story.append(Spacer(1, 12))

        viz_note = Paragraph(
            "The following images show coronal slices with anatomical T1-weighted background and hippocampal segmentation overlays "
            "(15% opacity) combined, providing the same visualization as the interactive viewer. Slices 3, 4, 5, and 6 are displayed "
            "in a 2x2 grid to provide comprehensive visualization of the hippocampal regions.",
            styles['Normal']
        )
        story.append(viz_note)
        story.append(Spacer(1, 18))

        # Add coronal visualizations for slices 3, 4, 5, 6 in 2x2 grid
        coronal_slices = [3, 4, 5, 6]

        # Read visualization files directly from filesystem
        from backend.core.config import get_settings
        settings = get_settings()
        viz_dir = Path(settings.output_dir) / str(job_id) / "visualizations" / "overlays" / "coronal"

        # Collect images for 2x2 grid
        images_data = []
        for slice_idx in coronal_slices:
            try:
                slice_id = f"slice_{slice_idx:02d}"

                # Read both anatomical (background) and overlay images directly from filesystem
                anatomical_path = viz_dir / f"anatomical_{slice_id}.png"
                overlay_path = viz_dir / f"hippocampus_overlay_{slice_id}.png"

                if anatomical_path.exists() and overlay_path.exists():
                    # Combine anatomical and overlay images
                    anatomical_img = PILImage.open(anatomical_path)
                    overlay_img = PILImage.open(overlay_path)

                    # Apply 15% opacity to overlay
                    overlay_with_opacity = overlay_img.copy()
                    overlay_with_opacity.putalpha(int(255 * 0.15))  # 15% opacity

                    # Create combined image (overlay on top of anatomical)
                    combined_img = PILImage.new('RGBA', anatomical_img.size, (0, 0, 0, 0))
                    combined_img.paste(anatomical_img.convert('RGBA'), (0, 0))
                    combined_img.paste(overlay_with_opacity, (0, 0), overlay_with_opacity)  # Use overlay as mask with opacity

                    # Convert back to RGB for PDF
                    combined_img = combined_img.convert('RGB')

                    # Convert to ReportLab Image
                    combined_buffer = io.BytesIO()
                    combined_img.save(combined_buffer, format='PNG')
                    combined_buffer.seek(0)

                    img = Image(combined_buffer, width=2.5*inch, height=2*inch)  # Smaller for grid layout

                    # Add title above image
                    title_para = Paragraph(f"Slice {slice_idx}",
                                         ParagraphStyle('SliceTitle',
                                                       parent=styles['Normal'],
                                                       fontSize=10,
                                                       alignment=1,
                                                       spaceAfter=6))
                    images_data.append([title_para, img])
                else:
                    logger.warning(f"Visualization files not found for coronal slice {slice_idx}: anatomical={anatomical_path.exists()}, overlay={overlay_path.exists()}")
                    # Add placeholder for missing image
                    placeholder = Paragraph(f"Slice {slice_idx}<br/>Image not available",
                                          ParagraphStyle('Placeholder',
                                                        parent=styles['Normal'],
                                                        fontSize=9,
                                                        alignment=1,
                                                        textColor=colors.gray))
                    images_data.append([Paragraph(f"Slice {slice_idx}", ParagraphStyle('SliceTitle', parent=styles['Normal'], fontSize=10, alignment=1, spaceAfter=6)), placeholder])

            except Exception as e:
                logger.error(f"Error adding coronal slice {slice_idx}: {e}")
                # Add error placeholder
                error_placeholder = Paragraph(f"Slice {slice_idx}<br/>Error loading",
                                            ParagraphStyle('ErrorPlaceholder',
                                                          parent=styles['Normal'],
                                                          fontSize=9,
                                                          alignment=1,
                                                          textColor=colors.red))
                images_data.append([Paragraph(f"Slice {slice_idx}", ParagraphStyle('SliceTitle', parent=styles['Normal'], fontSize=10, alignment=1, spaceAfter=6)), error_placeholder])

        # Create 2x2 grid table
        if images_data:
            # Arrange as 2x2 grid: [3, 4] in first row, [5, 6] in second row
            grid_data = [
                [images_data[0][1], images_data[1][1]],  # Row 1: slices 3, 4
                [images_data[2][1], images_data[3][1]]   # Row 2: slices 5, 6
            ]

            # Create table with proper spacing
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

            # Add caption for the entire grid
            grid_caption = Paragraph(
                "Figure: Coronal slices 3, 4 (top row) and 5, 6 (bottom row) showing T1-weighted anatomical images with hippocampal segmentation overlays at 15% opacity. "
                "NeuroInsight blue regions indicate segmented hippocampal structures.",
                ParagraphStyle('GridCaption', parent=styles['Normal'], fontSize=9, textColor=colors.gray, alignment=1)
            )
            story.append(grid_caption)
            story.append(Spacer(1, 18))

        # Build PDF
        doc.build(story)

        # Return PDF as downloadable file
        pdf_buffer.seek(0)
        filename = f"neuroinsight_report_{job_id}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.pdf"

        return StreamingResponse(
            io.BytesIO(pdf_buffer.getvalue()),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}"}
        )

    except Exception as e:
        logger.error(f"PDF generation failed for job {job_id}: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to generate PDF report: {str(e)}"
        )
