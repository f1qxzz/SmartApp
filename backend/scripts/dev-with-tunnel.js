const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const localtunnel = require('localtunnel');
require('dotenv').config();

const backendDir = path.resolve(__dirname, '..');
const mobileEnvPath = path.resolve(backendDir, '..', 'mobile', '.env');
const port = Number.parseInt(process.env.PORT, 10) || 5000;
const subdomain = String(process.env.LT_SUBDOMAIN || '').trim() || undefined;
const host = String(process.env.LT_HOST || '').trim() || undefined;
const retryMs = Number.parseInt(process.env.LT_RETRY_MS, 10) || 5000;

let backendProcess = null;
let tunnel = null;
let shuttingDown = false;
let reconnectTimer = null;
let activePublicUrl = '';

function upsertEnvValue(source, key, value) {
  const eol = source.includes('\r\n') ? '\r\n' : '\n';
  const nextLine = `${key}=${value}`;
  const pattern = new RegExp(`^${key}=.*$`, 'm');

  if (pattern.test(source)) {
    return source.replace(pattern, nextLine);
  }

  if (!source) {
    return `${nextLine}${eol}`;
  }

  const suffix = source.endsWith('\n') || source.endsWith('\r\n') ? '' : eol;
  return `${source}${suffix}${nextLine}${eol}`;
}

async function syncMobileEnv(publicUrl) {
  let content = '';

  if (fs.existsSync(mobileEnvPath)) {
    content = fs.readFileSync(mobileEnvPath, 'utf8');
  }

  content = upsertEnvValue(content, 'API_BASE_URL', publicUrl);
  content = upsertEnvValue(content, 'SOCKET_URL', publicUrl);

  fs.writeFileSync(mobileEnvPath, content, 'utf8');
}

function startBackend() {
  backendProcess = spawn('npm run dev', {
    cwd: backendDir,
    env: process.env,
    stdio: 'inherit',
    shell: true,
  });

  backendProcess.on('exit', (code) => {
    if (!shuttingDown) {
      shutdown(code ?? 0);
    }
  });
}

function formatError(error) {
  return error?.message || String(error);
}

function getTunnelOptions() {
  const options = {
    port,
  };

  if (subdomain) {
    options.subdomain = subdomain;
  }

  if (host) {
    options.host = host;
  }

  return options;
}

function clearReconnectTimer() {
  if (!reconnectTimer) return;
  clearTimeout(reconnectTimer);
  reconnectTimer = null;
}

function scheduleReconnect() {
  if (shuttingDown || reconnectTimer) return;

  reconnectTimer = setTimeout(() => {
    reconnectTimer = null;
    ensureTunnel().catch((error) => {
      // eslint-disable-next-line no-console
      console.error(`Reconnect LocalTunnel gagal: ${formatError(error)}`);
      scheduleReconnect();
    });
  }, retryMs);
}

function bindTunnelEvents(instance) {
  instance.on('error', (error) => {
    if (shuttingDown) return;
    // eslint-disable-next-line no-console
    console.error(`LocalTunnel error: ${formatError(error)}. Mencoba reconnect ${retryMs / 1000}s...`);
    try {
      instance.close();
    } catch (closeError) {
      // no-op
    }
    scheduleReconnect();
  });

  instance.on('close', () => {
    if (shuttingDown) return;
    // eslint-disable-next-line no-console
    console.error(`LocalTunnel terputus. Mencoba reconnect ${retryMs / 1000}s...`);
    scheduleReconnect();
  });
}

async function ensureTunnel() {
  if (shuttingDown) return;

  tunnel = await localtunnel(getTunnelOptions());
  bindTunnelEvents(tunnel);

  const publicUrl = tunnel.url;

  if (publicUrl !== activePublicUrl) {
    await syncMobileEnv(publicUrl);
    activePublicUrl = publicUrl;

    // eslint-disable-next-line no-console
    console.log('\nLocalTunnel aktif.');
    // eslint-disable-next-line no-console
    console.log(`Public URL: ${publicUrl}`);
    // eslint-disable-next-line no-console
    console.log(`mobile/.env diperbarui -> API_BASE_URL dan SOCKET_URL = ${publicUrl}\n`);
  } else {
    // eslint-disable-next-line no-console
    console.log(`LocalTunnel tersambung ulang di URL yang sama: ${publicUrl}`);
  }
}

async function shutdown(exitCode) {
  if (shuttingDown) return;
  shuttingDown = true;
  clearReconnectTimer();

  if (tunnel) {
    try {
      tunnel.close();
    } catch (error) {
      // no-op
    }
  }

  if (backendProcess && !backendProcess.killed) {
    backendProcess.kill('SIGINT');
  }

  setTimeout(() => process.exit(exitCode), 150);
}

process.on('SIGINT', () => {
  shutdown(0);
});

process.on('SIGTERM', () => {
  shutdown(0);
});

startBackend();

ensureTunnel().catch((error) => {
  // eslint-disable-next-line no-console
  console.error(`Gagal membuat LocalTunnel: ${formatError(error)}. Akan retry ${retryMs / 1000}s...`);
  scheduleReconnect();
});
