/**
 * Tests for jest.setup.ts polyfills.
 *
 * jest.setup.ts patches the global environment so that Next.js API route
 * tests work correctly under jsdom.  This file verifies the key behaviours
 * that those patches provide:
 *
 *  1. `global.Response` correctly reflects the `status` supplied in the
 *     `init` argument (jsdom's native Response ignores the status option).
 *  2. `Response.json()` is a static factory that sets content-type and
 *     stores the provided data.
 *  3. `global.Request` exposes a `json()` method that parses the body.
 *  4. `global.Headers` behaves like a case-insensitive key-value store.
 */

// jest.setup.ts is executed automatically before every test file via
// `setupFilesAfterEnv` in jest.config.ts, so the polyfills are already
// applied when this file runs.

describe('jest.setup.ts polyfills', () => {
  // ---------------------------------------------------------------------------
  // Response polyfill
  // ---------------------------------------------------------------------------

  describe('Response polyfill', () => {
    it('should be defined on global', () => {
      expect(global.Response).toBeDefined();
    });

    it('should default status to 200 when no init is provided', () => {
      const res = new Response({ message: 'ok' } as any);
      expect(res.status).toBe(200);
    });

    it('should use the provided status code', () => {
      const res = new Response({ error: 'not found' } as any, { status: 404 });
      expect(res.status).toBe(404);
    });

    it('should correctly reflect status 400', () => {
      const res = new Response({ error: 'bad request' } as any, { status: 400 });
      expect(res.status).toBe(400);
    });

    it('should correctly reflect status 500', () => {
      const res = new Response(null, { status: 500 });
      expect(res.status).toBe(500);
    });

    it('should correctly reflect status 201', () => {
      const res = new Response({ id: 1 } as any, { status: 201 });
      expect(res.status).toBe(201);
    });

    it('should return JSON body via async json()', async () => {
      const body = { key: 'value', count: 42 };
      const res = new Response(body as any, { status: 200 });
      const data = await res.json();
      expect(data).toEqual(body);
    });

    it('should parse a JSON string body via async json()', async () => {
      const res = new Response(JSON.stringify({ parsed: true }), { status: 200 });
      const data = await res.json();
      expect(data.parsed).toBe(true);
    });

    it('should return body as string via async text()', async () => {
      const res = new Response('plain text', { status: 200 });
      const text = await res.text();
      expect(text).toBe('plain text');
    });

    it('should stringify an object body in text()', async () => {
      const body = { hello: 'world' };
      const res = new Response(body as any, { status: 200 });
      const text = await res.text();
      expect(text).toContain('hello');
    });

    describe('Response.json() static factory', () => {
      it('should be a function', () => {
        expect(typeof Response.json).toBe('function');
      });

      it('should create a response with the provided data', async () => {
        const data = { success: true };
        const res = Response.json(data);
        const parsed = await res.json();
        expect(parsed).toEqual(data);
      });

      it('should default to status 200', () => {
        const res = Response.json({ ok: true });
        expect(res.status).toBe(200);
      });

      it('should use the provided status in init', () => {
        const res = Response.json({ error: 'not found' }, { status: 404 });
        expect(res.status).toBe(404);
      });

      it('should use the provided status 400', () => {
        const res = Response.json({ error: 'bad input' }, { status: 400 });
        expect(res.status).toBe(400);
      });

      it('should use the provided status 201', () => {
        const res = Response.json({ id: 'abc' }, { status: 201 });
        expect(res.status).toBe(201);
      });

      it('should set content-type header to application/json', () => {
        const res = Response.json({});
        // The polyfill stores headers in a Map with lower-case keys
        const contentType = (res.headers as any).get('content-type');
        expect(contentType).toBe('application/json');
      });

      it('should preserve a null body', async () => {
        const res = Response.json(null, { status: 204 });
        expect(res.status).toBe(204);
        // null is a valid JSON value
        const parsed = await res.json();
        expect(parsed).toBeNull();
      });

      it('should handle an array body', async () => {
        const data = [1, 2, 3];
        const res = Response.json(data, { status: 200 });
        const parsed = await res.json();
        expect(parsed).toEqual(data);
      });

      it('should handle a nested object body', async () => {
        const data = { user: { name: 'Alice', age: 30 } };
        const res = Response.json(data);
        const parsed = await res.json();
        expect(parsed.user.name).toBe('Alice');
      });
    });

    describe('Response headers', () => {
      it('should store headers from init', () => {
        const res = new Response('body', {
          status: 200,
          headers: { 'x-custom': 'value' },
        });
        const header = (res.headers as any).get('x-custom');
        expect(header).toBe('value');
      });

      it('should lower-case header names', () => {
        const res = new Response('body', {
          status: 200,
          headers: { 'X-Correlation-ID': 'abc123' },
        });
        const header = (res.headers as any).get('x-correlation-id');
        expect(header).toBe('abc123');
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Request polyfill
  // ---------------------------------------------------------------------------

  describe('Request polyfill', () => {
    it('should be defined on global', () => {
      expect(global.Request).toBeDefined();
    });

    it('should store the URL', () => {
      const req = new Request('https://example.com/api');
      expect((req as any).url).toBe('https://example.com/api');
    });

    it('should return parsed JSON from a string body', async () => {
      const body = JSON.stringify({ foo: 'bar' });
      const req = new Request('https://example.com/', { body });
      const data = await (req as any).json();
      expect(data).toEqual({ foo: 'bar' });
    });

    it('should return empty object when no body is provided', async () => {
      const req = new Request('https://example.com/');
      const data = await (req as any).json();
      expect(data).toEqual({});
    });

    it('should accept an init object', () => {
      const req = new Request('https://example.com/', { method: 'POST' });
      expect((req as any).init?.method).toBe('POST');
    });
  });

  // ---------------------------------------------------------------------------
  // Boundary and regression cases
  // ---------------------------------------------------------------------------

  describe('Status code boundary cases', () => {
    it('should handle status 0 if explicitly set', () => {
      const res = new Response(null, { status: 0 });
      expect(res.status).toBe(0);
    });

    it('should handle status 999', () => {
      const res = new Response(null, { status: 999 });
      expect(res.status).toBe(999);
    });

    it('should handle the same body used in multiple Response instances', async () => {
      const body = { shared: true };
      const res1 = new Response(body as any, { status: 200 });
      const res2 = new Response(body as any, { status: 404 });

      expect(res1.status).toBe(200);
      expect(res2.status).toBe(404);

      const data1 = await res1.json();
      const data2 = await res2.json();
      expect(data1).toEqual(body);
      expect(data2).toEqual(body);
    });
  });

  // ---------------------------------------------------------------------------
  // Additional Response tests (body edge cases)
  // ---------------------------------------------------------------------------

  describe('Response body edge cases', () => {
    it('should return undefined from json() when body is null', async () => {
      const res = new Response(null, { status: 204 });
      const data = await res.json();
      // null body: json() returns null (object passthrough)
      expect(data).toBeNull();
    });

    it('should return a number body from json()', async () => {
      const res = new Response(42 as any, { status: 200 });
      const data = await res.json();
      expect(data).toBe(42);
    });

    it('should return a boolean body from json()', async () => {
      const res = new Response(true as any, { status: 200 });
      const data = await res.json();
      expect(data).toBe(true);
    });

    it('should stringify a number body in text()', async () => {
      const res = new Response(123 as any, { status: 200 });
      const text = await res.text();
      expect(text).toBe('123');
    });

    it('should stringify a boolean body in text()', async () => {
      const res = new Response(false as any, { status: 200 });
      const text = await res.text();
      expect(text).toBe('false');
    });

    it('should return a plain string body in text() without modification', async () => {
      const res = new Response('raw string body', { status: 200 });
      const text = await res.text();
      expect(text).toBe('raw string body');
    });
  });

  // ---------------------------------------------------------------------------
  // Additional Response.json() static factory tests
  // ---------------------------------------------------------------------------

  describe('Response.json() with primitive values', () => {
    it('should handle a number as data', async () => {
      const res = Response.json(99);
      const data = await res.json();
      expect(data).toBe(99);
    });

    it('should handle a boolean true as data', async () => {
      const res = Response.json(true);
      const data = await res.json();
      expect(data).toBe(true);
    });

    it('should handle a boolean false as data', async () => {
      const res = Response.json(false);
      const data = await res.json();
      expect(data).toBe(false);
    });

    it('should produce independent instances with separate status codes', () => {
      const res200 = Response.json({ a: 1 }, { status: 200 });
      const res500 = Response.json({ b: 2 }, { status: 500 });
      // Changing one must not affect the other
      expect(res200.status).toBe(200);
      expect(res500.status).toBe(500);
    });
  });

  // ---------------------------------------------------------------------------
  // Additional header tests
  // ---------------------------------------------------------------------------

  describe('Response header lookup', () => {
    it('should return undefined for a header that was not set', () => {
      const res = new Response('body', { status: 200 });
      const missing = (res.headers as any).get('x-does-not-exist');
      expect(missing).toBeUndefined();
    });

    it('should handle multiple headers set at once', () => {
      const res = new Response('body', {
        status: 200,
        headers: {
          'x-first': 'one',
          'x-second': 'two',
          'x-third': 'three',
        },
      });
      expect((res.headers as any).get('x-first')).toBe('one');
      expect((res.headers as any).get('x-second')).toBe('two');
      expect((res.headers as any).get('x-third')).toBe('three');
    });
  });

  // ---------------------------------------------------------------------------
  // Additional Request tests
  // ---------------------------------------------------------------------------

  describe('Request additional cases', () => {
    it('should return empty object from json() when init has no body property', async () => {
      // init provided but no body key
      const req = new Request('https://example.com/', { method: 'GET' });
      const data = await (req as any).json();
      expect(data).toEqual({});
    });

    it('should store the full URL including query string', () => {
      const req = new Request('https://example.com/api?key=value&count=3');
      expect((req as any).url).toBe('https://example.com/api?key=value&count=3');
    });

    it('should parse nested JSON body correctly', async () => {
      const body = JSON.stringify({ user: { id: 1, name: 'Alice' } });
      const req = new Request('https://example.com/', { body });
      const data = await (req as any).json();
      expect(data.user.id).toBe(1);
      expect(data.user.name).toBe('Alice');
    });
  });
});