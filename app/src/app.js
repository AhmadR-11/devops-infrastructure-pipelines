const express = require('express');
const app = express();

app.use(express.json());

// REST Endpoint 1: Health Check (Assignment Requirement)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', message: 'Application is healthy' });
});

// REST Endpoint 2: Echo message (For Integration Testing)
app.post('/echo', (req, res) => {
  const { message } = req.body;
  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }
  res.status(200).json({ echo: message });
});

module.exports = app;
