const fs = require('fs');
const path = require('path');
const { spawn, execSync } = require('child_process');
require('dotenv').config();

const backendDir = path.resolve(__dirname, '..');
const mobileEnvPath = path.resolve(backendDir, '..', 'mobile', '.env');
const port = Number.parseInt(process.env.PORT, 10) || 5000;
const domain = process.env.NGROK_DOMAIN;

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

function killPort(portNumber) {
  try {
    // Windows command to find PID on port and kill it
    const output = execSync(`netstat -ano | findstr :${portNumber}`).toString();
    const lines = output.split('\n');
    const pids = new Set();
    for (const line of lines) {
      const parts = line.trim().split(/\s+/);
      if (parts.length > 4) {
        const pid = parts[parts.length - 1];
        if (pid !== '0' && !Number.isNaN(Number.parseInt(pid))) {
          pids.add(pid);
        }
      }
    }
    for (const pid of pids) {
      console.log(`Membersihkan proses lama di port ${portNumber} (PID: ${pid})...`);
      execSync(`taskkill /F /PID ${pid}`, { stdio: 'ignore' });
    }
  } catch (e) {
    // No process found or kill failed, safely ignore
  }
}

function killNgrok() {
  try {
    console.log('Membersihkan sisa proses Ngrok...');
    execSync('taskkill /F /IM ngrok.exe', { stdio: 'ignore' });
  } catch (e) {
    // No process found, safely ignore
  }
}

function startBackend() {
  console.log('Membersihkan port 5000...');
  killPort(5000);
  killNgrok();
  
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
  // Pattern to match ngrok URLs from the log output
  const match = text.match(/https:\/\/[a-z0-9-.]+\.ngrok-free\.(app|dev)/i);
  if (!match) return '';
  return match[0];
}

function handleTunnelOutput(chunk) {
  const text = String(chunk || '');
  const url = extractUrl(text);
  if (!url || url === currentUrl) return;

  currentUrl = url;
  syncMobileEnv(url)
    .then(() => {
      console.log('\n=========================================');
      console.log('🚀 Ngrok Tunnel Aktif!');
      console.log(`🔗 Public URL: ${url}`);
      console.log('📱 mobile/.env telah diperbarui otomatis.');
      console.log('=========================================\n');
    })
    .catch((error) => {
      console.error('Gagal update mobile/.env:', error.message || error);
    });
}

function startTunnel() {
  console.log('Menyiapkan Ngrok Tunnel...');
  
  // Use a single string for better compatibility with shell: true on Windows
  let command = `npx ngrok http ${port}`;
  if (domain) {
    command += ` --domain ${domain.trim()}`;
  }
  
  tunnelProcess = spawn(command, {
    cwd: backendDir,
    env: process.env,
    stdio: ['ignore', 'pipe', 'pipe'],
    shell: true,
  });

  tunnelProcess.stdout.on('data', (chunk) => {
    // We don't want to flood the console with ngrok UI bits, 
    // but we need to find the URL.
    handleTunnelOutput(chunk);
  });

  tunnelProcess.stderr.on('data', (chunk) => {
    const text = String(chunk);
    if (text.includes('ERROR')) {
       console.error(`\nNgrok Error: ${text.trim()}`);
    }
    handleTunnelOutput(chunk);
  });

  // Since Ngrok CLI is interactive, it might not output the URL raw.
  // Let's also poll the local API as a fallback.
  const apiCheckInterval = setInterval(async () => {
    if (currentUrl || shuttingDown) {
       clearInterval(apiCheckInterval);
       return;
    }
    try {
      const response = await fetch('http://127.0.0.1:4040/api/tunnels');
      if (response.ok) {
        const data = await response.json();
        if (data.tunnels && data.tunnels.length > 0) {
           const url = data.tunnels[0].public_url;
           if (url) {
             handleTunnelOutput(url);
             clearInterval(apiCheckInterval);
           }
        }
      }
    } catch (e) {
      // API not ready yet
    }
  }, 1000);

  tunnelProcess.on('exit', (code) => {
    if (!shuttingDown) {
      console.error(`Ngrok Tunnel terhenti (code ${code}).`);
      shutdown(code || 1);
    }
  });
}

function shutdown(exitCode) {
  if (shuttingDown) return;
  shuttingDown = true;

  if (tunnelProcess && !tunnelProcess.killed) {
    try { tunnelProcess.kill('SIGINT'); } catch (_) {}
  }

  if (backendProcess && !backendProcess.killed) {
    try { backendProcess.kill('SIGINT'); } catch (_) {}
  }

  setTimeout(() => process.exit(exitCode), 150);
}

process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));

startBackend();
startTunnel();
