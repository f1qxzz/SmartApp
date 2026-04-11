require('dotenv').config();
const http = require('http');
const app = require('./src/app');
const connectDatabase = require('./src/config/db');
const { initSocketServer } = require('./src/sockets');

const PORT = process.env.PORT || 5000;

async function bootstrap() {
  await connectDatabase();

  const server = http.createServer(app);
  initSocketServer(server);

  server.listen(PORT, () => {
    // eslint-disable-next-line no-console
    console.log(`SmartLife backend running on port ${PORT}`);
  });
}

bootstrap().catch((error) => {
  // eslint-disable-next-line no-console
  console.error('Failed to start server:', error);
  process.exit(1);
});
