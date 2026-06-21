import { existsSync } from 'fs';
import path from 'path';
import { readFile, writeFile } from 'fs/promises';

const SIGN_FILE = '.consign.json';

interface SignFile {
  name: string;
  repo_url?: string;
  agent_profile_id?: string;
}

function detectGitRemote(): string | null {
  try {
    const result = Bun.spawnSync(['git', 'remote', 'get-url', 'origin']);
    if (result.exitCode === 0) {
      return result.stdout.toString().trim();
    }
  } catch {}
  return null;
}

async function initCommand(nameOverride?: string): Promise<void> {
  const cwd = process.cwd();
  const signPath = path.join(cwd, SIGN_FILE);

  if (existsSync(signPath)) {
    console.error(`Error: ${SIGN_FILE} already exists in ${cwd}`);
    process.exit(1);
  }

  const dirName = path.basename(cwd);
  const name = nameOverride || dirName;
  const repoUrl = detectGitRemote() || undefined;

  const sign: SignFile = {
    name,
    ...(repoUrl ? { repo_url: repoUrl } : {}),
  };

  await writeFile(signPath, JSON.stringify(sign, null, 2) + '\n');
  console.log(`Created ${SIGN_FILE} for project "${name}" in ${cwd}`);
}

export async function runCLI(): Promise<void> {
  const args = process.argv.slice(2);
  const cmd = args[0];

  switch (cmd) {
    case 'init': {
      const nameOverride = args[1] || undefined;
      await initCommand(nameOverride);
      break;
    }
    default:
      console.error('Usage: consign init [name]');
      console.error('');
      console.error('Commands:');
      console.error('  init [name]  Create a .consign.json sign file in the current directory');
      process.exit(1);
  }
}
