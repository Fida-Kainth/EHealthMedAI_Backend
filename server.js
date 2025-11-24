const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const db = require('./config/database');

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/agents', require('./routes/agents'));
app.use('/api/users', require('./routes/users'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/organizations', require('./routes/organizations'));
app.use('/api/telephony', require('./routes/telephony'));
app.use('/api/integrations', require('./routes/integrations'));
app.use('/api/analytics', require('./routes/analytics'));
app.use('/api/hipaa', require('./routes/hipaa'));
app.use('/api/terminology', require('./routes/terminology'));
app.use('/api/references', require('./routes/references'));
app.use('/api/stakeholders', require('./routes/stakeholders'));
app.use('/api/voice-ai', require('./routes/voice-ai'));
app.use('/api/integrations-ehr', require('./routes/integrations-ehr'));
app.use('/api/security', require('./routes/security'));
app.use('/api/reports', require('./routes/reports'));
app.use('/api/presentation', require('./routes/presentation'));
app.use('/api/requirements', require('./routes/requirements'));
app.use('/api/assumptions-constraints', require('./routes/assumptions-constraints'));
app.use('/api/srs', require('./routes/srs'));
app.use('/api/change-control', require('./routes/change-control'));
app.use('/api/deliverables', require('./routes/deliverables'));
app.use('/api/conversations', require('./routes/conversations'));
app.use('/api/ai-status', require('./routes/ai-status'));

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'EHealth Med AI API is running' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    message: 'Something went wrong!', 
    error: process.env.NODE_ENV === 'development' ? err.message : undefined 
  });
});

// Start server
app.listen(PORT, async () => {
  console.log(`Server is running on port ${PORT}`);
  
  // Test database connection
  try {
    await db.query('SELECT NOW()');
    console.log('Database connected successfully');
  } catch (error) {
    console.error('Database connection error:', error.message);
  }
});

module.exports = app;

