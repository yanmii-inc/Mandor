import { PROVIDER_MODELS } from '../../agents/models';

/**
 * GET /models — returns the selectable models per provider so clients can render a
 * model switcher. Shape: { [agentType]: { id, label }[] }.
 */
export function handleModels(req: Request): Response {
  if (req.method !== 'GET') {
    return new Response('Method not allowed', { status: 405 });
  }
  return Response.json(PROVIDER_MODELS, { status: 200 });
}
