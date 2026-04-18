/**
 * Tests for the jest.setup.ts polyfills, focusing on the simplified Response
 * polyfill introduced in this PR.
 *
 * The polyfill is applied by setupFilesAfterEnv so the global Response (and
 * friends) are already in scope when these tests run.
 */

describe('jest.setup.ts – Response polyfill', () => {
  describe('constructor', () => {
    it('creates a Response with body and init', () => {
      const res = new Response('hello', { status: 201 });
      expect(res).toBeDefined();
    });

    it('has a default status of 200', () => {
      const res = new Response('body');
      expect(res.status).toBe(200);
    });

    it('has an empty headers Map by default', () => {
      const res = new Response();
      expect(res.headers).toBeDefined();
    });
  });

  describe('instance methods', () => {
    it('json() parses a JSON string body', async () => {
      const res = new Response(JSON.stringify({ key: 'value' }));
      const data = await res.json();
      expect(data).toEqual({ key: 'value' });
    });

    it('json() returns the body directly when it is already an object', async () => {
      const res = new Response({ key: 'value' });
      const data = await res.json();
      expect(data).toEqual({ key: 'value' });
    });

    it('text() returns the string body as-is', async () => {
      const res = new Response('plain text');
      const text = await res.text();
      expect(text).toBe('plain text');
    });

    it('text() serialises an object body to JSON', async () => {
      const res = new Response({ key: 'value' });
      const text = await res.text();
      expect(JSON.parse(text)).toEqual({ key: 'value' });
    });

    it('text() round-trips with json()', async () => {
      const res = new Response({ a: 1, b: 'two' });
      const text = await res.text();
      expect(JSON.parse(text)).toEqual({ a: 1, b: 'two' });
    });
  });

  describe('static json() factory', () => {
    it('creates a Response from a data object', () => {
      const res = Response.json({ result: 'ok' });
      expect(res).toBeDefined();
    });

    it('sets the content-type header to application/json', () => {
      const res = Response.json({ x: 1 });
      const ct = res.headers.get('content-type');
      expect(ct).toBe('application/json');
    });

    it('uses the status from init when provided', () => {
      const res = Response.json({ error: 'not found' }, { status: 404 });
      expect(res.status).toBe(404);
    });

    it('defaults to status 200 when no init is provided', () => {
      const res = Response.json({ ok: true });
      expect(res.status).toBe(200);
    });

    it('returns json-parseable body data', async () => {
      const payload = { message: 'hello', code: 42 };
      const res = Response.json(payload);
      const data = await res.json();
      expect(data).toEqual(payload);
    });

    it('merges custom headers from init', () => {
      const res = Response.json({ x: 1 }, {
        status: 200,
        headers: { 'x-custom': 'test-value' },
      });
      expect(res.headers.get('x-custom')).toBe('test-value');
      // content-type should still be set
      expect(res.headers.get('content-type')).toBe('application/json');
    });

    it('handles nested objects in body', async () => {
      const payload = { nested: { deep: { value: 99 } }, arr: [1, 2, 3] };
      const res = Response.json(payload);
      const data = await res.json();
      expect(data).toEqual(payload);
    });

    it('handles null body', async () => {
      const res = Response.json(null);
      const data = await res.json();
      expect(data).toBeNull();
    });

    it('handles array body', async () => {
      const res = Response.json([1, 2, 3]);
      const data = await res.json();
      expect(data).toEqual([1, 2, 3]);
    });

    it('passes various 4xx status codes through correctly', () => {
      expect(Response.json({}, { status: 400 }).status).toBe(400);
      expect(Response.json({}, { status: 401 }).status).toBe(401);
      expect(Response.json({}, { status: 409 }).status).toBe(409);
      expect(Response.json({}, { status: 422 }).status).toBe(422);
    });

    it('passes 5xx status codes through correctly', () => {
      expect(Response.json({}, { status: 500 }).status).toBe(500);
      expect(Response.json({}, { status: 503 }).status).toBe(503);
    });
  });

  describe('Request polyfill', () => {
    it('is defined in the test environment', () => {
      expect(typeof Request).not.toBe('undefined');
    });

    it('stores the url', () => {
      const req = new Request('https://example.com/api');
      expect(req.url).toBe('https://example.com/api');
    });

    it('json() returns parsed body from init', async () => {
      const req = new Request('https://example.com', {
        body: JSON.stringify({ foo: 'bar' }),
      });
      const data = await req.json();
      expect(data).toEqual({ foo: 'bar' });
    });

    it('json() returns empty object when no body is given', async () => {
      const req = new Request('https://example.com');
      const data = await req.json();
      expect(data).toEqual({});
    });
  });
});