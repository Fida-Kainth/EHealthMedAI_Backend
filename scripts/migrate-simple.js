const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

// Create a new pool specifically for migrations
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

async function runMigrations() {
  const client = await pool.connect();
  
  try {
    console.log('🔄 Starting database migration...');
    console.log('📊 Environment:', process.env.NODE_ENV || 'development');
    console.log('🔗 Database URL:', process.env.DATABASE_URL ? '✓ Set' : '✗ Not set');
    
    // Test connection
    try {
      const testResult = await client.query('SELECT NOW() as now, version() as version');
      console.log('✅ Database connection successful!');
      console.log('⏰ Server time:', testResult.rows[0].now);
    } catch (error) {
      console.error('❌ Database connection failed:', error.message);
      throw error;
    }
    
    // Start transaction
    await client.query('BEGIN');
    console.log('📝 Transaction started');
    
    // Read SQL files
    const sqlFiles = [
      { name: 'db.sql', path: path.join(__dirname, '../db.sql') },
      { name: 'db-updates.sql', path: path.join(__dirname, '../db-updates.sql') }
    ];
    
    for (const sqlFile of sqlFiles) {
      console.log(`\n📄 Processing ${sqlFile.name}...`);
      
      // Check if file exists
      if (!fs.existsSync(sqlFile.path)) {
        console.log(`⚠️  ${sqlFile.name} not found, skipping...`);
        continue;
      }
      
      const sql = fs.readFileSync(sqlFile.path, 'utf8');
      
      // Parse SQL into statements
      const statements = parseSQLStatements(sql);
      console.log(`📋 Found ${statements.length} SQL statements`);
      
      // Execute each statement
      for (let i = 0; i < statements.length; i++) {
        const statement = statements[i];
        const preview = statement.substring(0, 80).replace(/\s+/g, ' ');
        
        try {
          console.log(`  [${i + 1}/${statements.length}] ${preview}${statement.length > 80 ? '...' : ''}`);
          await client.query(statement);
          console.log(`  ✓ Success`);
        } catch (error) {
          // Handle "already exists" errors gracefully
          if (
            error.message.includes('already exists') ||
            error.message.includes('duplicate') ||
            error.code === '42P07' || // relation already exists
            error.code === '42710'    // object already exists
          ) {
            console.log(`  ℹ️  Already exists (skipping)`);
          } else {
            console.error(`  ✗ Error:`, error.message);
            throw error;
          }
        }
      }
      
      console.log(`✅ ${sqlFile.name} completed`);
    }
    
    // Commit transaction
    await client.query('COMMIT');
    console.log('✅ Transaction committed');
    
    // Verify tables were created
    const result = await client.query(`
      SELECT 
        table_name,
        (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'public' AND columns.table_name = tables.table_name) as column_count
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);
    
    console.log('\n📋 Database Tables:');
    console.log('─'.repeat(50));
    result.rows.forEach(row => {
      console.log(`  ✓ ${row.table_name.padEnd(30)} (${row.column_count} columns)`);
    });
    console.log('─'.repeat(50));
    console.log(`  Total: ${result.rows.length} tables`);
    
    console.log('\n🎉 Migration completed successfully!');
    
  } catch (error) {
    // Rollback on error
    try {
      await client.query('ROLLBACK');
      console.log('↩️  Transaction rolled back');
    } catch (rollbackError) {
      console.error('❌ Rollback failed:', rollbackError.message);
    }
    
    console.error('\n💥 Migration failed!');
    console.error('Error:', error.message);
    if (process.env.NODE_ENV === 'development') {
      console.error('Stack:', error.stack);
    }
    throw error;
    
  } finally {
    client.release();
    await pool.end();
  }
}

/**
 * Parse SQL file into individual statements
 * Handles comments and multi-line statements
 */
function parseSQLStatements(sql) {
  const lines = sql.split('\n');
  let currentStatement = '';
  const statements = [];
  let inBlockComment = false;
  
  for (const line of lines) {
    let processedLine = line.trim();
    
    // Handle block comments /* */
    if (processedLine.includes('/*')) {
      inBlockComment = true;
    }
    if (inBlockComment) {
      if (processedLine.includes('*/')) {
        inBlockComment = false;
      }
      continue;
    }
    
    // Skip empty lines and single-line comments
    if (!processedLine || processedLine.startsWith('--')) {
      continue;
    }
    
    // Remove inline comments
    const commentIndex = processedLine.indexOf('--');
    if (commentIndex !== -1) {
      processedLine = processedLine.substring(0, commentIndex).trim();
    }
    
    if (!processedLine) continue;
    
    // Add to current statement
    currentStatement += processedLine + '\n';
    
    // Check if statement is complete (ends with semicolon)
    if (processedLine.endsWith(';')) {
      const statement = currentStatement.trim();
      if (statement && statement !== ';') {
        statements.push(statement);
      }
      currentStatement = '';
    }
  }
  
  // Add any remaining statement
  if (currentStatement.trim() && currentStatement.trim() !== ';') {
    statements.push(currentStatement.trim());
  }
  
  return statements;
}

// Run migrations
runMigrations()
  .then(() => {
    console.log('\n✨ All done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Migration script failed');
    process.exit(1);
  });
