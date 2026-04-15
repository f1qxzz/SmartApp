const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
require('dotenv').config();

const backendDir = path.resolve(__dirname, '..');
const mobileEnvPath = path.resolve(backendDir, '..', 'mobile', '.env');
const port = Number.parseInt(process.env.PORT, 10) || 5000;

const cloudflaredBin =
  String(process.env.CLOUDFLARED_BIN || '').trim() ||
  'C:\\Program Files (x86)\\cloudflared\\cloudflared.exe';

let backendProcess = null;
let tunnelProcess = null;
let shuttingDown = false;
let currentUrl = '';

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
      shutdown(code || 0);
    }
  });
}

function extractUrl(text) {
  const match = text.match(/https:\/\/[a-z0-9-]+\.trycloudflare\.com/i);
  if (!match) {
    return '';
  }
  return match[0];
}

function handleTunnelOutput(chunk) {
  const text = String(chunk || '');
  const url = extractUrl(text);
  if (!url || url === currentUrl) {
    return;
  }

  currentUrl = url;
  syncMobileEnv(url)
    .then(() => {
      // eslint-disable-next-line no-console
      console.log('\nCloudflare Tunnel aktif.');
      // eslint-disable-next-line no-console
      console.log(`Public URL: ${url}`);
      // eslint-disable-next-line no-console
      console.log(`mobile/.env diperbarui -> API_BASE_URL dan SOCKET_URL = ${url}\n`);
    })
    .catch((error) => {
      // eslint-disable-next-line no-console
      console.error('Gagal update mobile/.env:', error.message || error);
    });
}

function startTunnel() {
  const tunnelArgs = ['tunnel', '--url', `http://127.0.0.1:${port}`];
  tunnelProcess = spawn(cloudflaredBin, tunnelArgs, {
    cwd: backendDir,
    env: process.env,
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: false,
  });

  tunnelProcess.stdout.on('data', (chunk) => {
    process.stdout.write(chunk);
    handleTunnelOutput(chunk);
  });

  tunnelProcess.stderr.on('data', (chunk) => {
    process.stderr.write(chunk);
    handleTunnelOutput(chunk);
  });

  tunnelProcess.on('error', (error) => {
    // eslint-disable-next-line no-console
    console.error(
      `Gagal menjalankan cloudflared. Cek path CLOUDFLARED_BIN. Detail: ${error.message || error}`
    );
    shutdown(1);
  });

  tunnelProcess.on('exit', (code) => {
    if (!shuttingDown) {
      // eslint-disable-next-line no-console
      console.error(`cloudflared berhenti (code ${code ?? 'unknown'}).`);
      shutdown(code || 1);
    }
  });
}

function shutdown(exitCode) {
  if (shuttingDown) return;
  shuttingDown = true;

  if (tunnelProcess && !tunnelProcess.killed) {
    try {
      tunnelProcess.kill('SIGINT');
    } catch (_) {
      // no-op
    }
  }

  if (backendProcess && !backendProcess.killed) {
    try {
      backendProcess.kill('SIGINT');
    } catch (_) {
      // no-op
    }
  }

  setTimeout(() => process.exit(exitCode), 150);
}

process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));

startBackend();
startTunnel();
