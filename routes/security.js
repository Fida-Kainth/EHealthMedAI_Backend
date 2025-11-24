const express = require('express');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Get encryption keys
router.get('/encryption-keys', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const orgId = orgResult.rows[0]?.organization_id;

    let result;
    if (orgId) {
      result = await db.query(
        'SELECT id, key_name, key_type, algorithm, rotation_date, is_active, created_at, expires_at FROM encryption_keys WHERE organization_id = $1 ORDER BY created_at DESC',
        [orgId]
      );
    } else {
      result = await db.query(
        'SELECT id, key_name, key_type, algorithm, rotation_date, is_active, created_at, expires_at FROM encryption_keys WHERE organization_id IS NULL ORDER BY created_at DESC'
      );
    }

    res.json({ keys: result.rows || [] });
  } catch (error) {
    console.error('Error fetching encryption keys:', error);
    res.json({ keys: [] });
  }
});

// Create encryption key
router.post('/encryption-keys', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const orgId = orgResult.rows[0]?.organization_id;

    const { key_name, key_type, algorithm, expires_at } = req.body;

    if (!key_name) {
      return res.status(400).json({ message: 'Key name is required' });
    }

    // In production, this would generate and encrypt a real key
    const keyEncrypted = `encrypted_key_${Date.now()}`; // Placeholder

    const result = await db.query(
      `INSERT INTO encryption_keys (organization_id, key_name, key_type, algorithm, key_encrypted, expires_at, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, true)
       RETURNING id, key_name, key_type, algorithm, created_at, expires_at, is_active`,
      [orgId || null, key_name, key_type || 'aes', algorithm || 'AES-256', keyEncrypted, expires_at || null]
    );

    res.status(201).json({ key: result.rows[0] });
  } catch (error) {
    console.error('Error creating encryption key:', error);
    res.status(500).json({ message: 'Error creating encryption key', error: error.message });
  }
});

// Rotate encryption key
router.post('/encryption-keys/rotate', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const orgId = orgResult.rows[0].organization_id;

    const { key_id, rotation_reason } = req.body;

    // Get old key
    const oldKeyResult = await db.query(
      'SELECT * FROM encryption_keys WHERE id = $1 AND organization_id = $2',
      [key_id, orgId]
    );

    if (oldKeyResult.rows.length === 0) {
      return res.status(404).json({ message: 'Encryption key not found' });
    }

    const oldKey = oldKeyResult.rows[0];

    // Create new key (in production, this would generate a new encrypted key)
    const newKeyEncrypted = `new_key_${Date.now()}`; // Placeholder

    // Update key
    await db.query(
      'UPDATE encryption_keys SET key_encrypted = $1, rotation_date = CURRENT_DATE, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
      [newKeyEncrypted, key_id]
    );

    // Log rotation
    await db.query(
      'INSERT INTO key_rotation_log (encryption_key_id, organization_id, old_key_encrypted, new_key_encrypted, rotated_by, rotation_reason) VALUES ($1, $2, $3, $4, $5, $6)',
      [key_id, orgId, oldKey.key_encrypted, newKeyEncrypted, req.user.id, rotation_reason]
    );

    res.json({ message: 'Key rotated successfully' });
  } catch (error) {
    console.error('Error rotating key:', error);
    res.status(500).json({ message: 'Error rotating encryption key' });
  }
});

// Get access policies
router.get('/access-policies', authenticateToken, async (req, res) => {
  try {
    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const orgId = orgResult.rows[0]?.organization_id;

    let result;
    if (orgId) {
      result = await db.query(
        'SELECT * FROM access_policies WHERE organization_id = $1 ORDER BY created_at DESC',
        [orgId]
      );
    } else {
      result = await db.query(
        'SELECT * FROM access_policies WHERE organization_id IS NULL ORDER BY created_at DESC'
      );
    }

    res.json({ policies: result.rows || [] });
  } catch (error) {
    console.error('Error fetching access policies:', error);
    res.json({ policies: [] });
  }
});

// Create access policy
router.post('/access-policies', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const orgResult = await db.query(
      'SELECT organization_id FROM users WHERE id = $1',
      [req.user.id]
    );
    const orgId = orgResult.rows[0]?.organization_id;

    const { name, resource_type, resource_id, role, permissions, conditions } = req.body;

    if (!name || !resource_type || !role) {
      return res.status(400).json({ message: 'Name, resource_type, and role are required' });
    }

    if (!permissions || !Array.isArray(permissions) || permissions.length === 0) {
      return res.status(400).json({ message: 'At least one permission is required' });
    }

    const result = await db.query(
      `INSERT INTO access_policies (organization_id, name, resource_type, resource_id, role, permissions, conditions)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [orgId || null, name, resource_type, resource_id || null, role, permissions, JSON.stringify(conditions || {})]
    );

    res.status(201).json({ policy: result.rows[0] });
  } catch (error) {
    console.error('Error creating access policy:', error);
    res.status(500).json({ message: 'Error creating access policy', error: error.message });
  }
});

module.exports = router;

