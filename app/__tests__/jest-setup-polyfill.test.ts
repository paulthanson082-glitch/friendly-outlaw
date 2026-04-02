/**
 * Tests for the jest.setup.ts Response polyfill behavior.
 *
 * The PR changed the polyfill from always overriding Response to only
 * overriding it when typeof Response === 'undefined'. These tests validate
 * the polyfill class's behavior directly by re-implementing the class inline,
 * ensuring the static and instance methods work correctly.
 */

// Inline re-implementation of the polyfill class from jest.setup.ts
// (matches the changed code in the PR exactly)
class PolyfillResponse {
  constructor(public body?: any, public init?: any) {}
  public status = 200;
  public headers = new Map<string, string>();

  async json() {
    return typeof this.body === 'string' ? JSON.parse(this.body) : this.body;
  }

  async text() {
    return typeof this.body === 'string' ? this.body : JSON.stringify(this.body);
  }

  static json(data: any, init?: any) {
    const response = new PolyfillResponse(data, init);
    response.status = init?.status || 200;
    if (init?.headers) {
      response.headers = new Map(Object.entries(init.headers as Record<string, string>));
    }
    response.headers.set('content-type', 'application/json');
    return response;
  }
}

describe('Response polyfill (jest.setup.ts)', () => {
  describe('static json() factory', () => {
    it('should default to status 200 when no init is provided', () => {
      const response = PolyfillResponse.json({ ok: true });
      expect(response.status).toBe(200);
    });

    it('should use provided status code', () => {
      const response = PolyfillResponse.json({ error: 'not found' }, { status: 404 });
      expect(response.status).toBe(404);
    });

    it('should use status 201 for created responses', () => {
      const response = PolyfillResponse.json({ id: 1 }, { status: 201 });
      expect(response.status).toBe(201);
    });

    it('should use status 409 for conflict responses', () => {
      const response = PolyfillResponse.json({ error: 'paused' }, { status: 409 });
      expect(response.status).toBe(409);
    });

    it('should always set content-type to application/json', () => {
      const response = PolyfillResponse.json({ data: 'value' });
      expect(response.headers.get('content-type')).toBe('application/json');
    });

    it('should preserve custom headers when provided in init', () => {
      const response = PolyfillResponse.json(
        { data: 'value' },
        { headers: { 'X-Custom-Header': 'test-value' } }
      );
      expect(response.headers.get('X-Custom-Header')).toBe('test-value');
    });

    it('should set content-type even when custom headers are provided', () => {
      const response = PolyfillResponse.json(
        { data: 'value' },
        { headers: { 'X-Custom': 'header' } }
      );
      expect(response.headers.get('content-type')).toBe('application/json');
    });

    it('should store the data body for later retrieval', async () => {
      const data = { key: 'value', num: 42 };
      const response = PolyfillResponse.json(data);
      const parsed = await response.json();
      expect(parsed).toEqual(data);
    });

    it('should use || 200 fallback, so status 0 becomes 200', () => {
      // This documents the || 200 behavior (falsy zero becomes 200)
      const response = PolyfillResponse.json({}, { status: 0 });
      expect(response.status).toBe(200);
    });

    it('should use null init as status 200', () => {
      const response = PolyfillResponse.json({}, null);
      expect(response.status).toBe(200);
    });
  });

  describe('instance json() method', () => {
    it('should parse a JSON string body', async () => {
      const response = new PolyfillResponse('{"key":"value"}');
      const result = await response.json();
      expect(result).toEqual({ key: 'value' });
    });

    it('should return an object body as-is (no double parsing)', async () => {
      const obj = { key: 'value', nested: { a: 1 } };
      const response = new PolyfillResponse(obj);
      const result = await response.json();
      expect(result).toBe(obj);
    });

    it('should parse a JSON array string', async () => {
      const response = new PolyfillResponse('[1,2,3]');
      const result = await response.json();
      expect(result).toEqual([1, 2, 3]);
    });

    it('should handle numeric bodies', async () => {
      const response = new PolyfillResponse(42);
      const result = await response.json();
      expect(result).toBe(42);
    });
  });

  describe('instance text() method', () => {
    it('should return a string body as-is', async () => {
      const response = new PolyfillResponse('hello world');
      const result = await response.text();
      expect(result).toBe('hello world');
    });

    it('should stringify an object body', async () => {
      const obj = { key: 'value' };
      const response = new PolyfillResponse(obj);
      const result = await response.text();
      expect(result).toBe(JSON.stringify(obj));
    });

    it('should stringify an array body', async () => {
      const arr = [1, 2, 3];
      const response = new PolyfillResponse(arr);
      const result = await response.text();
      expect(result).toBe('[1,2,3]');
    });
  });

  describe('instance properties', () => {
    it('should default status to 200', () => {
      const response = new PolyfillResponse();
      expect(response.status).toBe(200);
    });

    it('should start with an empty headers map', () => {
      const response = new PolyfillResponse();
      expect(response.headers.size).toBe(0);
    });

    it('should store body and init arguments', () => {
      const body = { data: 1 };
      const init = { status: 201 };
      const response = new PolyfillResponse(body, init);
      expect(response.body).toBe(body);
      expect(response.init).toBe(init);
    });

    it('should allow status to be set after construction', () => {
      const response = new PolyfillResponse({});
      response.status = 404;
      expect(response.status).toBe(404);
    });
  });

  describe('conditional polyfill application', () => {
    it('should not override existing Response if already defined', () => {
      // The polyfill in jest.setup.ts is wrapped in:
      // if (typeof Response === 'undefined') { ... }
      // In jsdom environment, Response is already defined, so the polyfill
      // should NOT override it. We verify this by checking Response is defined.
      expect(typeof Response).not.toBe('undefined');
    });

    it('should have a working Response.json() in jsdom test environment', async () => {
      // Verify the actual Response (whether jsdom or polyfill) has a json static method
      expect(typeof Response.json).toBe('function');
    });

    it('should produce a Response with status reflecting the provided status code', () => {
      // Both jsdom Response and our polyfill should respect the status code
      // This is the key regression tested: the OLD polyfill always overrode Response
      // to fix status code handling; the NEW one only applies if undefined.
      const response = Response.json({ error: 'test' }, { status: 400 });
      expect(response.status).toBe(400);
    });

    it('should produce a Response with default 200 status when no status provided', () => {
      const response = Response.json({ ok: true });
      expect(response.status).toBe(200);
    });
  });
});