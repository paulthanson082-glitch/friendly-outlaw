// Starts a real mongod on port 27017 using the mongodb-memory-server binary.
// Run with: node scripts/start-mongo.mjs
import { MongoMemoryServer } from 'mongodb-memory-server';

const server = await MongoMemoryServer.create({
  instance: {
    port: 27017,
    dbName: 'writers_app',
  },
});

const uri = server.getUri();
console.log(`MongoDB running at: ${uri}`);
console.log('Press Ctrl+C to stop.');

process.on('SIGINT', async () => {
  await server.stop();
  process.exit(0);
});
