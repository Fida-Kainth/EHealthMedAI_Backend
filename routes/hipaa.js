const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Get BAA agreements
router.get('/baa', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );

    const orgId = orgResult.rows[0].organization_id;

    const result = await db.query(
      'SELECT * FROM baa_agreements WHERE organization_id = $1 ORDER BY created_at DESC',
      [orgId]
    );

    res.json({ agreements: result.rows });
  } catch (error) {
    console.error('Error fetching BAA agreements:', error);
    res.status(500).json({ message: 'Error fetching BAA agreements' });
  }
});

// Create BAA agreement
router.post('/baa', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );

    const orgId = orgResult.rows[0].organization_id;

    const { vendor_name, vendor_type, status, signed_date, expiration_date, document_url, notes } = req.body;

    const result = await db.query(
      `INSERT INTO baa_agreements (organization_id, vendor_name, vendor_type, status, signed_date, expiration_date, document_url, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [orgId, vendor_name, vendor_type, status, signed_date, expiration_date, document_url, notes]
    );

    res.status(201).json({ agreement: result.rows[0] });
  } catch (error) {
    console.error('Error creating BAA agreement:', error);
    res.status(500).json({ message: 'Error creating BAA agreement' });
  }
});

// Get retention policies
router.get('/retention', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );

    const orgId = orgResult.rows[0].organization_id;

    const result = await db.query(
      'SELECT * FROM retention_policies WHERE organization_id = $1 ORDER BY data_type',
      [orgId]
    );

    res.json({ policies: result.rows });
  } catch (error) {
    console.error('Error fetching retention policies:', error);
    res.status(500).json({ message: 'Error fetching retention policies' });
  }
});

// Update retention policy
router.put('/retention/:data_type', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );

    const orgId = orgResult.rows[0].organization_id;
    const { data_type } = req.params;
    const { retention_days, auto_delete } = req.body;

    const result = await db.query(
      `INSERT INTO retention_policies (organization_id, data_type, retention_days, auto_delete)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (organization_id, data_type)
       DO UPDATE SET retention_days = EXCLUDED.retention_days,
                      auto_delete = EXCLUDED.auto_delete,
                      updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [orgId, data_type, retention_days, auto_delete]
    );

    res.json({ policy: result.rows[0] });
  } catch (error) {
    console.error('Error updating retention policy:', error);
    res.status(500).json({ message: 'Error updating retention policy' });
  }
});

module.exports = router;

