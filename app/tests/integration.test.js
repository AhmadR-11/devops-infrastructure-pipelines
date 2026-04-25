const request = require('supertest');
const app = require('../src/app');

describe('API Integration Tests', () => {
  // Integration Test 1
  test('GET /health should return 200 and status UP', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'UP', message: 'Application is healthy' });
  });

  // Integration Test 2
  test('POST /echo should echo the message back', async () => {
    const response = await request(app)
      .post('/echo')
      .send({ message: 'Hello DevOps!' });
    expect(response.status).toBe(200);
    expect(response.body).toEqual({ echo: 'Hello DevOps!' });
  });
});
