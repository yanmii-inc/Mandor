import type { Db } from '../../db/index';
import type { CreateTaskInput } from '../../agents/base';
import { Orchestrator } from '../../orchestrator/index';

export function handleTasks(req: Request, db: Db, orchestrator: Orchestrator): Response | Promise<Response> {
  const url = new URL(req.url);
  const pathParts = url.pathname.split('/').filter(Boolean);

  // POST /tasks or GET /tasks
  if (pathParts.length === 1) {
    if (req.method === 'POST') return createTask(req, db, orchestrator);
    if (req.method === 'GET') return listTasks(req, db);
    return new Response('Method not allowed', { status: 405 });
  }

  // /tasks/:id
  if (pathParts.length === 2) {
    const taskId = pathParts[1];
    if (req.method === 'GET') return getTask(taskId, db);
    if (req.method === 'DELETE') return deleteTask(taskId, db, orchestrator);
    return new Response('Method not allowed', { status: 405 });
  }

  // /tasks/:id/logs, /tasks/:id/confirm, /tasks/:id/reply
  if (pathParts.length === 3) {
    const taskId = pathParts[1];
    const action = pathParts[2];

    if (action === 'logs') {
      if (req.method === 'GET') return streamLogs(taskId, req, db, orchestrator);
      return new Response('Method not allowed', { status: 405 });
    }

    if (action === 'confirm') {
      if (req.method === 'POST') return confirmTask(taskId, db, orchestrator);
      return new Response('Method not allowed', { status: 405 });
    }

    if (action === 'reply') {
      if (req.method === 'POST') return replyToTask(taskId, req, db, orchestrator);
      return new Response('Method not allowed', { status: 405 });
    }
  }

  return new Response('Not found', { status: 404 });
}

async function createTask(req: Request, db: Db, orchestrator: Orchestrator): Promise<Response> {
  try {
    const body = await req.json() as CreateTaskInput;

    if (!body.project_id || !body.description) {
      return Response.json({ error: 'project_id and description are required' }, { status: 400 });
    }

    const project = db.getProject(body.project_id);
    if (!project) {
      return Response.json({ error: 'Project not found' }, { status: 404 });
    }

    const task = db.createTask(body);

    // Dispatch asynchronously
    orchestrator.dispatchTask(task.id).catch(err => {
      console.error(`Task ${task.id} failed:`, err);
      db.updateTask(task.id, { status: 'failed' });
    });

    return Response.json(task, { status: 201 });
  } catch (err: any) {
    return Response.json({ error: err.message }, { status: 400 });
  }
}

function listTasks(req: Request, db: Db): Response {
  const url = new URL(req.url);
  const projectId = url.searchParams.get('project_id') ?? undefined;
  const tasks = db.listTasks(projectId);
  return Response.json(tasks, { status: 200 });
}

function getTask(taskId: string, db: Db): Response {
  const task = db.getTask(taskId);
  if (!task) {
    return Response.json({ error: 'Task not found' }, { status: 404 });
  }
  return Response.json(task, { status: 200 });
}

async function deleteTask(taskId: string, db: Db, orchestrator: Orchestrator): Promise<Response> {
  await orchestrator.killTask(taskId);
  db.deleteTask(taskId);
  return new Response(null, { status: 204 });
}

async function confirmTask(taskId: string, db: Db, orchestrator: Orchestrator): Promise<Response> {
  const task = db.getTask(taskId);
  if (!task) {
    return Response.json({ error: 'Task not found' }, { status: 404 });
  }

  if (task.status !== 'pending') {
    return Response.json({ error: 'Task is not in pending status' }, { status: 400 });
  }

  db.updateTask(taskId, { confirmed: 1 });

  // Re-dispatch
  orchestrator.dispatchTask(taskId).catch(err => {
    console.error(`Task ${taskId} failed:`, err);
    db.updateTask(taskId, { status: 'failed' });
  });

  return Response.json(db.getTask(taskId), { status: 200 });
}

async function replyToTask(taskId: string, req: Request, db: Db, orchestrator: Orchestrator): Promise<Response> {
  try {
    const body = await req.json() as { message: string };
    if (!body.message) {
      return Response.json({ error: 'message is required' }, { status: 400 });
    }

    await orchestrator.reply(taskId, body.message);
    return Response.json({ status: 'ok' }, { status: 200 });
  } catch (err: any) {
    return Response.json({ error: err.message }, { status: 400 });
  }
}

function streamLogs(taskId: string, req: Request, db: Db, orchestrator: Orchestrator): Response {
  const task = db.getTask(taskId);
  if (!task) {
    return Response.json({ error: 'Task not found' }, { status: 404 });
  }

  const stream = new ReadableStream({
    start(controller) {
      const encoder = new TextEncoder();

      const sendSSE = (event: string, data: string) => {
        controller.enqueue(encoder.encode(`event: ${event}\ndata: ${data}\n\n`));
      };

      // Send existing logs
      const existingLogs = db.getTaskLogs(taskId);
      for (const log of existingLogs) {
        sendSSE('log', JSON.stringify(log));
      }

      // Subscribe to new messages
      const unsubscribe = orchestrator.subscribeToSSE(taskId, (msg) => {
        sendSSE('message', JSON.stringify(msg));

        if (msg.type === 'done') {
          sendSSE('done', JSON.stringify({ taskId }));
        }

        if (msg.type === 'error') {
          sendSSE('error', JSON.stringify({ message: msg.content }));
        }
      });

      req.signal.addEventListener('abort', () => {
        unsubscribe();
        controller.close();
      });
    },
  });

  return new Response(stream, {
    status: 200,
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  });
}
