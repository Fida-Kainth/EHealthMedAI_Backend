const fs = require('fs');
const path = require('path');
const db = require('../config/database');
const dotenv = require('dotenv');

dotenv.config();

async function runMigrations() {
  const client = await db.pool.connect();
  
  try {
    console.log('Starting database migration...');
    console.log('Connecting to database...');
    
    // Test connection
    await client.query('SELECT NOW()');
    console.log('✓ Database connection successful!\n');
    
    const sqlFile = path.join(__dirname, '../config/db.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');
    
    // Execute the entire SQL file
    console.log('Executing SQL migration file...\n');
    await client.query(sql);
    
    console.log('\n✓ Database migration completed successfully!');
    
    // Verify tables were created
    const tablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_type = 'BASE TABLE'
      ORDER BY table_name;
    `);
    
    console.log('\nCreated tables:');
    tablesResult.rows.forEach(row => {
      console.log(`  - ${row.table_name}`);
    });
    
    // Verify agents were inserted
    const agentsResult = await client.query('SELECT COUNT(*) as count FROM ai_agents');
    console.log(`\nAI Agents in database: ${agentsResult.rows[0].count}`);
    
  } catch (error) {
    console.error('\n✗ Migration error:', error.message);
    if (error.code) {
      console.error('Error code:', error.code);
    }
    if (error.detail) {
      console.error('Details:', error.detail);
    }
    if (error.position) {
      console.error('Position:', error.position);
    }
    process.exit(1);
  } finally {
    client.release();
    process.exit(0);
  }
}

runMigrations();

