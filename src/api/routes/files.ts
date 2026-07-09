import { readdir, createReadStream } from 'fs';
import { stat, realpath } from 'fs/promises';
import path from 'path';
import type { Db } from '../../db/index';
import { resolveHome } from '../../project-setup';

const LARGE_FILE = 5 * 1024 * 1024;

const BINARY_EXTS = new Set([
  '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico', '.webp', '.avif',
  '.mp3', '.mp4', '.avi', '.mov', '.mkv', '.wav', '.flac', '.ogg',
  '.zip', '.tar', '.gz', '.bz2', '.7z', '.rar',
  '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
  '.exe', '.dll', '.so', '.dylib', '.bin', '.wasm',
  '.ttf', '.otf', '.woff', '.woff2', '.eot',
  '.o', '.a', '.lib', '.obj',
  '.pyc', '.pyo', '.class', '.jar', '.dex',
  '.db', '.sqlite', '.sqlite3',
  '.svg', '.ico',
]);

const MIME_MAP: Record<string, string> = {
  '.txt': 'text/plain',
  '.md': 'text/markdown',
  '.json': 'application/json',
  '.xml': 'application/xml',
  '.html': 'text/html',
  '.htm': 'text/html',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.ts': 'application/typescript',
  '.tsx': 'application/typescript',
  '.jsx': 'text/javascript',
  '.py': 'text/x-python',
  '.rb': 'text/x-ruby',
  '.go': 'text/x-go',
  '.rs': 'text/x-rust',
  '.java': 'text/x-java',
  '.c': 'text/x-c',
  '.cpp': 'text/x-c++',
  '.h': 'text/x-c',
  '.hpp': 'text/x-c++',
  '.sh': 'application/x-sh',
  '.bash': 'application/x-sh',
  '.zsh': 'application/x-sh',
  '.yml': 'text/yaml',
  '.yaml': 'text/yaml',
  '.toml': 'text/toml',
  '.ini': 'text/plain',
  '.cfg': 'text/plain',
  '.conf': 'text/plain',
  '.log': 'text/plain',
  '.csv': 'text/csv',
  '.env': 'text/plain',
  '.sql': 'text/plain',
  '.vue': 'text/html',
  '.svelte': 'text/html',
  '.astro': 'text/html',
  '.gitignore': 'text/plain',
  '.dockerignore': 'text/plain',
  '.editorconfig': 'text/plain',
  '.prettierrc': 'application/json',
  '.eslintrc': 'application/json',
  '.babelrc': 'application/json',
};

function authenticate(req: Request): Response | null {
  const token = process.env.AUTH_TOKEN;
  if (!token) return null;
  const auth = req.headers.get('Authorization');
  if (auth === `Bearer ${token}`) return null;
  return Response.json({ error: 'Unauthorized' }, { status: 401 });
}

function resolveSafe(root: string, raw: string): string {
  const decoded = decodeURIComponent(raw);
  const safe = decoded.startsWith('/') ? '.' + decoded : decoded;
  const resolved = path.resolve(root, safe);
  const rootNorm = root.endsWith(path.sep) ? root : root + path.sep;
  if (!resolved.startsWith(rootNorm) && resolved !== root) {
    throw new Error('Forbidden');
  }
  return resolved;
}

async function safeRealPath(resolved: string): Promise<string> {
  try {
    return await realpath(resolved);
  } catch {
    throw new Error('Not found');
  }
}

async function validatePath(root: string, raw: string): Promise<string> {
  const resolved = resolveSafe(root, raw);
  const real = await safeRealPath(resolved);
  const rootNorm = root.endsWith(path.sep) ? root : root + path.sep;
  if (!real.startsWith(rootNorm) && real !== root) {
    throw new Error('Forbidden');
  }
  return resolved;
}

function mimeType(filePath: string): string {
  return MIME_MAP[path.extname(filePath).toLowerCase()] || 'application/octet-stream';
}

function isBinary(filePath: string): boolean {
  return BINARY_EXTS.has(path.extname(filePath).toLowerCase());
}

function countLinesStream(filePath: string): Promise<number> {
  return new Promise((resolve, reject) => {
    let count = 0;
    const stream = createReadStream(filePath, { start: 0, end: Math.min(LARGE_FILE, 1024 * 1024) });
    stream.on('data', (chunk: Buffer) => {
      for (let i = 0; i < chunk.length; i++) {
        if (chunk[i] === 10) count++;
      }
    });
    stream.on('end', () => resolve(count));
    stream.on('error', reject);
  });
}

function parseRange(range: string, fileSize: number): { start: number; end: number } {
  const match = range.match(/^bytes=(\d*)-(\d*)$/);
  if (!match) throw new Error('Invalid Range header');

  let start = match[1] ? parseInt(match[1], 10) : 0;
  let end = match[2] ? parseInt(match[2], 10) : fileSize - 1;

  if (isNaN(start) || isNaN(end)) throw new Error('Invalid Range header');
  if (start > end || start >= fileSize) throw new Error('Range not satisfiable');

  if (!match[1] && match[2]) {
    start = Math.max(0, fileSize - parseInt(match[2], 10));
    end = fileSize - 1;
  }

  return { start, end };
}

export async function handleFiles(req: Request, db: Db): Promise<Response> {
  const authErr = authenticate(req);
  if (authErr) return authErr;

  const url = new URL(req.url);
  const pathParts = url.pathname.split('/').filter(Boolean);

  try {
    // /browse/:projectId
    if (pathParts.length === 2 && pathParts[0] === 'browse') {
      if (req.method !== 'GET') return new Response('Method not allowed', { status: 405 });

      const project = db.getProject(pathParts[1]);
      if (!project) return Response.json({ error: 'Project not found' }, { status: 404 });

      const dirPath = url.searchParams.get('path');
      if (!dirPath) return Response.json({ error: 'path query parameter is required' }, { status: 400 });

      const root = resolveHome(project.local_path);
      const resolved = await validatePath(root, dirPath);

      const entries = await new Promise<{ name: string; type: 'file' | 'directory' }[]>((resolve, reject) => {
        readdir(resolved, { withFileTypes: true }, (err, dirents) => {
          if (err) {
            if (err.code === 'ENOENT') return reject(Object.assign(new Error('Not found'), { status: 404 }));
            if (err.code === 'EACCES' || err.code === 'EPERM') return reject(Object.assign(new Error('Forbidden'), { status: 403 }));
            return reject(err);
          }
          const items = dirents
            .filter(d => d.isFile() || d.isDirectory())
            .map(d => ({
              name: d.name,
              type: (d.isDirectory() ? 'directory' : 'file') as 'file' | 'directory',
            }));
          resolve(items);
        });
      });

      entries.sort((a, b) => {
        if (a.type !== b.type) return a.type === 'directory' ? -1 : 1;
        return a.name.localeCompare(b.name);
      });

      const offset = parseInt(url.searchParams.get('offset') || '0', 10);
      const limitParam = url.searchParams.get('limit');
      const limit = limitParam ? parseInt(limitParam, 10) : entries.length;
      const paginated = entries.slice(offset, offset + limit);

      return Response.json(paginated, { status: 200 });
    }

    // /file/:projectId (metadata)
    if (pathParts.length === 2 && pathParts[0] === 'file') {
      if (req.method !== 'GET') return new Response('Method not allowed', { status: 405 });

      const project = db.getProject(pathParts[1]);
      if (!project) return Response.json({ error: 'Project not found' }, { status: 404 });

      const filePath = url.searchParams.get('path');
      if (!filePath) return Response.json({ error: 'path query parameter is required' }, { status: 400 });

      const root = resolveHome(project.local_path);
      const resolved = await validatePath(root, filePath);

      const stats = await stat(resolved);
      if (!stats.isFile()) return Response.json({ error: 'Not a file' }, { status: 400 });

      const mime = mimeType(resolved);
      let lineCount: number | null = null;
      if (!isBinary(resolved) && stats.size <= LARGE_FILE && stats.size > 0) {
        lineCount = await countLinesStream(resolved);
      }

      return Response.json({
        size: stats.size,
        mime,
        modifiedAt: stats.mtime.toISOString(),
        lineCount,
      }, { status: 200 });
    }

    // /file/:projectId/content
    if (pathParts.length === 3 && pathParts[0] === 'file' && pathParts[2] === 'content') {
      if (req.method !== 'GET') return new Response('Method not allowed', { status: 405 });

      const project = db.getProject(pathParts[1]);
      if (!project) return Response.json({ error: 'Project not found' }, { status: 404 });

      const filePath = url.searchParams.get('path');
      if (!filePath) return Response.json({ error: 'path query parameter is required' }, { status: 400 });

      const root = resolveHome(project.local_path);
      const resolved = await validatePath(root, filePath);

      const stats = await stat(resolved);
      if (!stats.isFile()) return Response.json({ error: 'Not a file' }, { status: 400 });

      const mime = mimeType(resolved);
      const rangeHeader = req.headers.get('Range');

      if (!rangeHeader && (stats.size > LARGE_FILE || isBinary(resolved))) {
        return Response.json({
          error: 'File is too large for direct download. Use Range header to stream chunks.',
          size: stats.size,
          mime,
        }, { status: 416 });
      }

      if (rangeHeader) {
        let range: { start: number; end: number };
        try {
          range = parseRange(rangeHeader, stats.size);
        } catch {
          return Response.json({ error: 'Invalid Range header' }, { status: 416 });
        }

        const contentLength = range.end - range.start + 1;
        const stream = createReadStream(resolved, { start: range.start, end: range.end });
        const body = new ReadableStream({
          start(controller) {
            stream.on('data', (chunk: Buffer) => controller.enqueue(chunk));
            stream.on('end', () => controller.close());
            stream.on('error', (err) => controller.error(err));
          },
          cancel() { stream.destroy(); },
        });

        return new Response(body, {
          status: 206,
          headers: {
            'Content-Type': mime,
            'Content-Length': String(contentLength),
            'Content-Range': `bytes ${range.start}-${range.end}/${stats.size}`,
            'Accept-Ranges': 'bytes',
            'Cache-Control': 'no-cache',
          },
        });
      }

      const stream = createReadStream(resolved);
      const body = new ReadableStream({
        start(controller) {
          stream.on('data', (chunk: Buffer) => controller.enqueue(chunk));
          stream.on('end', () => controller.close());
          stream.on('error', (err) => controller.error(err));
        },
        cancel() { stream.destroy(); },
      });

      return new Response(body, {
        headers: {
          'Content-Type': mime,
          'Content-Length': String(stats.size),
          'Accept-Ranges': 'bytes',
          'Cache-Control': 'no-cache',
        },
      });
    }

    return Response.json({ error: 'Not found' }, { status: 404 });
  } catch (err: any) {
    const status = err.status || 400;
    const msg = err.message === 'Forbidden' ? 'Forbidden' :
                err.message === 'Not found' ? 'Not found' :
                err.message;
    return Response.json({ error: msg }, { status });
  }
}
