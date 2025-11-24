const fs = require('fs');
const path = require('path');
const db = require('../config/database');
const dotenv = require('dotenv');

dotenv.config();

async function runMigrations() {
  try {
    console.log('Starting database migration...');
    console.log('Database URL:', process.env.DATABASE_URL ? 'Set' : 'Not set');
    
    // Test connection first
    try {
      const testResult = await db.query('SELECT NOW()');
      console.log('Database connection successful!');
    } catch (error) {
      console.error('Database connection failed:', error.message);
      throw error;
    }
    
    const sqlFile = path.join(__dirname, '../config/db.sql');
    const sql = fs.readFileSync(sqlFile, 'utf8');
    
    // Remove comments and split by semicolons more intelligently
    const lines = sql.split('\n');
    let currentStatement = '';
    const statements = [];
    
    for (const line of lines) {
      const trimmedLine = line.trim();
      
      // Skip empty lines and comment-only lines
      if (!trimmedLine || trimmedLine.startsWith('--')) {
        continue;
      }
      
      // Remove inline comments
      const lineWithoutComments = trimmedLine.split('--')[0].trim();
      if (!lineWithoutComments) continue;
      
      currentStatement += lineWithoutComments + ' ';
      
      // If line ends with semicolon, it's the end of a statement
      if (trimmedLine.endsWith(';')) {
        const statement = currentStatement.trim();
        if (statement && statement !== ';') {
          statements.push(statement);
        }
        currentStatement = '';
      }
    }
    
    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      try {
        console.log(`\nExecuting statement ${i + 1}/${statements.length}...`);
        console.log('SQL:', statement.substring(0, 100) + (statement.length > 100 ? '...' : ''));
        await db.query(statement);
        console.log('✓ Success');
      } catch (error) {
        console.error(`✗ Error in statement ${i + 1}:`, error.message);
        console.error('Full statement:', statement);
        // Continue with other statements instead of failing completely
        if (error.message.includes('already exists') || error.message.includes('duplicate')) {
          console.log('(This is okay - object already exists)');
        } else {
          throw error;
        }
      }
    }
    
    console.log('\n✓ Database migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('\n✗ Migration error:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

runMigrations();

