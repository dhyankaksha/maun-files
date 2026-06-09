const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const REPO_OWNER = 'dhyankaksha';
const REPO_NAME = 'maun-files';
const BRANCH = 'main';

// Helper to determine type and clean name
function processFilename(filename) {
  const ext = path.extname(filename);
  if (ext.toLowerCase() !== '.mp3') return null;

  const base = path.basename(filename, ext);
  let type = 'meditation'; // Default fallback
  let cleanName = base;

  if (/^sleep/i.test(base)) {
    type = 'sleep';
    cleanName = base.replace(/^sleep[_-\s]*/i, '');
  } else if (/^chime/i.test(base)) {
    type = 'chime';
    cleanName = base.replace(/^chime[_-\s]*/i, '');
  } else if (/^(meditation|meditaion|meditatio)/i.test(base)) {
    type = 'meditation';
    cleanName = base.replace(/^(meditation|meditaion|meditatio)[_-\s]*/i, '');
  }

  // Format cleanName to Title Case
  cleanName = cleanName
    .replace(/[\s_-]+/g, ' ')
    .trim()
    .split(' ')
    .map(w => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');

  if (!cleanName) {
    cleanName = base;
  }

  // URL encode the filename for safety in HTTP requests
  const encodedFilename = encodeURIComponent(filename);
  const url = `https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}/${encodedFilename}`;

  return {
    name: cleanName,
    url,
    type,
    file: filename
  };
}

function run() {
  console.log('Scanning audio files...');
  const files = fs.readdirSync(__dirname);
  const tracks = [];

  for (const file of files) {
    const track = processFilename(file);
    if (track) {
      tracks.push(track);
    }
  }

  // Sort tracks alphabetically by name
  tracks.sort((a, b) => a.name.localeCompare(b.name));

  // Write songs.json
  const registryPath = path.join(__dirname, 'songs.json');
  fs.writeFileSync(registryPath, JSON.stringify(tracks, null, 2), 'utf-8');
  console.log(`Successfully generated registry at: ${registryPath}`);
  console.log(`Total tracks indexed: ${tracks.length} (${tracks.filter(t => t.type === 'meditation').length} meditation, ${tracks.filter(t => t.type === 'sleep').length} sleep, ${tracks.filter(t => t.type === 'chime').length} chime)`);

  // Git operations
  try {
    console.log('Staging changes for Git...');
    execSync('git add .', { stdio: 'inherit', cwd: __dirname });
    
    // Check if there are changes to commit
    const status = execSync('git status --porcelain', { cwd: __dirname }).toString().trim();
    if (!status) {
      console.log('No new changes to upload to GitHub.');
      return;
    }

    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
    console.log(`Committing changes: "Sync audio files ${timestamp}"`);
    execSync(`git commit -m "Sync audio files ${timestamp}"`, { stdio: 'inherit', cwd: __dirname });

    console.log('Pushing updates to GitHub...');
    execSync(`git push origin ${BRANCH}`, { stdio: 'inherit', cwd: __dirname });
    console.log('Sync completed successfully!');
  } catch (err) {
    console.error('Git synchronization failed. Please check your internet connection or Git credentials.');
    console.error(err.message);
  }
}

run();
