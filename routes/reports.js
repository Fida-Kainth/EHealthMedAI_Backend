const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Get report templates
router.get('/templates', authenticateToken, async (req, res) => {
  try {
    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const orgId = orgResult.rows[0]?.organization_id;

    let result;
    if (orgId) {
      result = await db.query(
        'SELECT * FROM report_templates WHERE organization_id = $1 ORDER BY created_at DESC',
        [orgId]
      );
    } else {
      result = await db.query(
        'SELECT * FROM report_templates WHERE organization_id IS NULL ORDER BY created_at DESC'
      );
    }

    res.json({ templates: result.rows || [] });
  } catch (error) {
    console.error('Error fetching report templates:', error);
    res.json({ templates: [] });
  }
});

// Create report template
router.post('/templates', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const orgId = orgResult.rows[0]?.organization_id;

    const { name, type, description, query_config, schedule, recipients, format } = req.body;

    if (!name || !type) {
      return res.status(400).json({ message: 'Name and type are required' });
    }

    const result = await db.query(
      `INSERT INTO report_templates (organization_id, name, type, description, query_config, schedule, recipients, format)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [orgId || null, name, type, description || null, JSON.stringify(query_config || {}), schedule || null, recipients || [], format || 'pdf']
    );

    res.status(201).json({ template: result.rows[0] });
  } catch (error) {
    console.error('Error creating report template:', error);
    res.status(500).json({ message: 'Error creating report template' });
  }
});

// Generate report
router.post('/generate', authenticateToken, async (req, res) => {
  try {
    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const orgId = orgResult.rows[0]?.organization_id;

    const { template_id, parameters } = req.body;

    if (!template_id) {
      return res.status(400).json({ message: 'template_id is required' });
    }

    // Verify template belongs to organization
    let templateResult;
    if (orgId) {
      templateResult = await db.query(
        'SELECT * FROM report_templates WHERE id = $1 AND organization_id = $2',
        [template_id, orgId]
      );
    } else {
      templateResult = await db.query(
        'SELECT * FROM report_templates WHERE id = $1 AND organization_id IS NULL',
        [template_id]
      );
    }

    if (templateResult.rows.length === 0) {
      return res.status(404).json({ message: 'Report template not found' });
    }

    // Create report record (in production, this would trigger async report generation)
    const reportResult = await db.query(
      `INSERT INTO generated_reports (template_id, organization_id, generated_by, parameters, status)
       VALUES ($1, $2, $3, $4, 'generating')
       RETURNING *`,
      [template_id, orgId || null, req.user.id, JSON.stringify(parameters || {})]
    );

    const template = templateResult.rows[0];
    const reportFormat = template.format || 'pdf';

    // Simulate report generation (in production, this would be async)
    setTimeout(async () => {
      const reportUrl = `/api/reports/${reportResult.rows[0].id}/download`;
      await db.query(
        `UPDATE generated_reports 
         SET status = $1, completed_at = CURRENT_TIMESTAMP, report_url = $2, format = $3 
         WHERE id = $4`,
        ['completed', reportUrl, reportFormat, reportResult.rows[0].id]
      );
    }, 1000);

    res.status(201).json({ report: reportResult.rows[0] });
  } catch (error) {
    console.error('Error generating report:', error);
    res.status(500).json({ message: 'Error generating report' });
  }
});

// Get generated reports
router.get('/generated', authenticateToken, async (req, res) => {
  try {
    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const orgId = orgResult.rows[0]?.organization_id;

    let result;
    if (orgId) {
      result = await db.query(
        `SELECT gr.*, rt.name as template_name, rt.type as template_type
         FROM generated_reports gr
         JOIN report_templates rt ON gr.template_id = rt.id
         WHERE gr.organization_id = $1
         ORDER BY gr.created_at DESC
         LIMIT 50`,
        [orgId]
      );
    } else {
      result = await db.query(
        `SELECT gr.*, rt.name as template_name, rt.type as template_type
         FROM generated_reports gr
         JOIN report_templates rt ON gr.template_id = rt.id
         WHERE gr.organization_id IS NULL
         ORDER BY gr.created_at DESC
         LIMIT 50`
      );
    }

    res.json({ reports: result.rows || [] });
  } catch (error) {
    console.error('Error fetching generated reports:', error);
    res.json({ reports: [] });
  }
});

// Download report
router.get('/:id/download', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const orgId = orgResult.rows[0]?.organization_id;

    // Get report
    let reportResult;
    if (orgId) {
      reportResult = await db.query(
        `SELECT gr.*, rt.name as template_name, rt.type as template_type, rt.format as template_format
         FROM generated_reports gr
         JOIN report_templates rt ON gr.template_id = rt.id
         WHERE gr.id = $1 AND gr.organization_id = $2 AND gr.status = 'completed'`,
        [id, orgId]
      );
    } else {
      reportResult = await db.query(
        `SELECT gr.*, rt.name as template_name, rt.type as template_type, rt.format as template_format
         FROM generated_reports gr
         JOIN report_templates rt ON gr.template_id = rt.id
         WHERE gr.id = $1 AND gr.organization_id IS NULL AND gr.status = 'completed'`,
        [id]
      );
    }

    if (reportResult.rows.length === 0) {
      return res.status(404).json({ message: 'Report not found or not ready' });
    }

    const report = reportResult.rows[0];
    const format = report.format || report.template_format || 'pdf';

    // Generate a simple report content (in production, this would read from file_path or generate dynamically)
    let content;
    let contentType;
    let filename;

    switch (format.toLowerCase()) {
      case 'pdf':
        // For PDF, we'll return a JSON representation (in production, use a PDF library)
        content = JSON.stringify({
          report_id: report.id,
          template_name: report.template_name,
          template_type: report.template_type,
          generated_at: report.completed_at,
          parameters: report.parameters,
          message: 'This is a sample report. In production, this would be a generated PDF file.'
        }, null, 2);
        contentType = 'application/json';
        filename = `report-${report.id}.json`;
        break;
      case 'csv':
        content = `Report ID,Template Name,Template Type,Generated At\n${report.id},"${report.template_name}","${report.template_type}","${report.completed_at}"\n`;
        contentType = 'text/csv';
        filename = `report-${report.id}.csv`;
        break;
      case 'json':
        content = JSON.stringify({
          report_id: report.id,
          template_name: report.template_name,
          template_type: report.template_type,
          generated_at: report.completed_at,
          parameters: report.parameters
        }, null, 2);
        contentType = 'application/json';
        filename = `report-${report.id}.json`;
        break;
      case 'html':
        content = `<!DOCTYPE html>
<html>
<head>
  <title>Report ${report.id}</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; }
    h1 { color: #333; }
    .info { margin: 20px 0; }
  </style>
</head>
<body>
  <h1>${report.template_name}</h1>
  <div class="info">
    <p><strong>Report ID:</strong> ${report.id}</p>
    <p><strong>Template Type:</strong> ${report.template_type}</p>
    <p><strong>Generated At:</strong> ${new Date(report.completed_at).toLocaleString()}</p>
  </div>
  <p>This is a sample report. In production, this would contain actual report data.</p>
</body>
</html>`;
        contentType = 'text/html';
        filename = `report-${report.id}.html`;
        break;
      default:
        content = JSON.stringify({
          report_id: report.id,
          template_name: report.template_name,
          template_type: report.template_type,
          generated_at: report.completed_at,
          parameters: report.parameters
        }, null, 2);
        contentType = 'application/json';
        filename = `report-${report.id}.json`;
    }

    res.setHeader('Content-Type', contentType);
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.send(content);
  } catch (error) {
    console.error('Error downloading report:', error);
    res.status(500).json({ message: 'Error downloading report', error: error.message });
  }
});

module.exports = router;

