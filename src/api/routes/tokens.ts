import type { Db } from '../../db/index';

export function handleTokens(req: Request, db: Db): Response {
  if (req.method !== 'GET') {
    return new Response('Method not allowed', { status: 405 });
  }

  const summary = db.getTokenUsageSummary();
  return Response.json(summary, { status: 200 });
}
