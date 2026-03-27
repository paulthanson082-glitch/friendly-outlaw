// Set required environment variables before any module is loaded
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret-key-at-least-32-characters-long';
process.env.ANTHROPIC_API_KEY = 'test-api-key';
