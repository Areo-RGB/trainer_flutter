const { spawn } = require('child_process');
const chokidar = require('chokidar');
const path = require('path');

// Get arguments passed to the script (forwarded to flutter run)
const args = process.argv.slice(2);

console.log(`Starting flutter run with args: ${args.join(' ')}`);

const flutterProcess = spawn('flutter', ['run', ...args], {
  stdio: ['pipe', 'inherit', 'inherit'], // Pipe stdin, inherit stdout/stderr
  shell: true
});

let isReloading = false;

// Initialize watcher
const watcher = chokidar.watch('lib/**/*.dart', {
  ignored: /(^|[\/\\])\../, // ignore dotfiles
  persistent: true
});

watcher.on('change', (path) => {
  if (isReloading) return;
  
  console.log(`\nFile ${path} has been changed. Triggering Hot Reload...`);
  isReloading = true;
  
  // Send 'r' to flutter process
  if (flutterProcess.stdin) {
    flutterProcess.stdin.write('r');
  }

  // Debounce slightly to prevent double-reloads
  setTimeout(() => {
    isReloading = false;
  }, 1000);
});

flutterProcess.on('close', (code) => {
  console.log(`Flutter process exited with code ${code}`);
  process.exit(code);
});

// Handle termination signals
process.on('SIGINT', () => {
    flutterProcess.kill('SIGINT');
    process.exit();
});

process.on('SIGTERM', () => {
    flutterProcess.kill('SIGTERM');
    process.exit();
});
