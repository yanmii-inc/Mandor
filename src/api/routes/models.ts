/**
 * GET /models — deprecated. The hardcoded catalog was removed; models are now
 * discovered per agent profile via GET /agent-profiles/:id/models. This endpoint
 * returns an empty object for backward compatibility with older clients.
 */
export function handleModels(req: Request): Response {
  if (req.method !== 'GET') {
    return new Response('Method not allowed', { status: 405 });
  }
  return Response.json({}, { status: 200 });
}
