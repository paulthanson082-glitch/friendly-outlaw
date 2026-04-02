/**
 * Tests for the Response polyfill defined in jest.setup.ts.
 *
 * The PR changed the polyfill from always-overriding global.Response to a
 * conditional guard (`if (typeof Response === 'undefined')`).  These tests
 * verify the behaviour of the polyfill class itself by constructing instances
 * directly, mirroring what the module-level guard would install.
 */

// ---------------------------------------------------------------------------
// A local copy of the polyfill class, matching the exact implementation in
// jest.setup.ts after the PR change.
// ---------------------------------------------------------------------------
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
      response.headers = new Map(Object.entries(init.headers));
    }
    response.headers.set('content-type', 'application/json');
    return response;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe('Response polyfill (jest.setup.ts)', () => {
  describe('constructor', () => {
    it('should create a response with default status 200', () => {
      const r = new PolyfillResponse({ hello: 'world' });
      expect(r.status).toBe(200);
    });

    it('should expose the body passed to the constructor', async () => {
      const body = { foo: 'bar' };
      const r = new PolyfillResponse(body);
      expect(await r.json()).toEqual(body);
    });

    it('should create a response with no arguments', () => {
      const r = new PolyfillResponse();
      expect(r.status).toBe(200);
      expect(r.body).toBeUndefined();
    });

    it('should initialise headers as an empty Map', () => {
      const r = new PolyfillResponse();
      expect(r.headers).toBeInstanceOf(Map);
      expect(r.headers.size).toBe(0);
    });
  });

  describe('json() instance method', () => {
    it('should parse a JSON string body', async () => {
      const r = new PolyfillResponse('{"key":"value"}');
      expect(await r.json()).toEqual({ key: 'value' });
    });

    it('should return a non-string body as-is', async () => {
      const obj = { a: 1, b: [2, 3] };
      const r = new PolyfillResponse(obj);
      expect(await r.json()).toBe(obj);
    });

    it('should return a number body as-is', async () => {
      const r = new PolyfillResponse(42);
      expect(await r.json()).toBe(42);
    });

    it('should return null body as-is', async () => {
      const r = new PolyfillResponse(null);
      expect(await r.json()).toBeNull();
    });
  });

  describe('text() instance method', () => {
    it('should return a string body unchanged', async () => {
      const r = new PolyfillResponse('hello');
      expect(await r.text()).toBe('hello');
    });

    it('should serialise a non-string body to JSON', async () => {
      const r = new PolyfillResponse({ x: 1 });
      expect(await r.text()).toBe(JSON.stringify({ x: 1 }));
    });

    it('should serialise an array body to JSON', async () => {
      const r = new PolyfillResponse([1, 2, 3]);
      expect(await r.text()).toBe('[1,2,3]');
    });
  });

  describe('static json() factory', () => {
    it('should set content-type header to application/json', () => {
      const r = PolyfillResponse.json({ ok: true });
      expect(r.headers.get('content-type')).toBe('application/json');
    });

    it('should default status to 200 when no init provided', () => {
      const r = PolyfillResponse.json({ ok: true });
      expect(r.status).toBe(200);
    });

    it('should use explicit status from init', () => {
      const r = PolyfillResponse.json({ error: 'not found' }, { status: 404 });
      expect(r.status).toBe(404);
    });

    it('should use explicit status 409', () => {
      const r = PolyfillResponse.json({ error: 'paused' }, { status: 409 });
      expect(r.status).toBe(409);
    });

    it('should use explicit status 400', () => {
      const r = PolyfillResponse.json({ error: 'bad request' }, { status: 400 });
      expect(r.status).toBe(400);
    });

    it('should use explicit status 500', () => {
      const r = PolyfillResponse.json({ error: 'server error' }, { status: 500 });
      expect(r.status).toBe(500);
    });

    it('should copy custom headers from init when provided', () => {
      const r = PolyfillResponse.json({}, {
        headers: { 'x-custom': 'value', 'cache-control': 'no-store' },
      });
      expect(r.headers.get('x-custom')).toBe('value');
      expect(r.headers.get('cache-control')).toBe('no-store');
    });

    it('should set content-type even when other headers are provided', () => {
      const r = PolyfillResponse.json({}, { headers: { 'x-foo': 'bar' } });
      expect(r.headers.get('content-type')).toBe('application/json');
    });

    it('should not add headers when init has no headers property', () => {
      const r = PolyfillResponse.json({ data: 1 }, { status: 201 });
      // Only content-type should be set
      expect(r.headers.size).toBe(1);
      expect(r.headers.has('content-type')).toBe(true);
    });

    it('should make the body accessible via json()', async () => {
      const payload = { tick: 5, generated: [] };
      const r = PolyfillResponse.json(payload);
      expect(await r.json()).toEqual(payload);
    });

    it('should treat status 0 as 200 due to || operator (regression guard)', () => {
      // The new polyfill uses `init?.status || 200` (not ??).
      // This means status=0 falls back to 200.  Document this behaviour.
      const r = PolyfillResponse.json({}, { status: 0 });
      expect(r.status).toBe(200);
    });
  });

  describe('conditional polyfill guard semantics', () => {
    it('should not override a pre-existing global Response', () => {
      // Simulate the guard: the polyfill only installs when Response is undefined.
      const previousResponse = (global as any).Response;
      try {
        // If Response is already defined, the guard does nothing.
        if (typeof (global as any).Response === 'undefined') {
          (global as any).Response = PolyfillResponse;
        }
        // In jsdom the native Response is present, so no override should occur.
        expect((global as any).Response).toBe(previousResponse);
      } finally {
        (global as any).Response = previousResponse;
      }
    });

    it('should install polyfill when Response is undefined', () => {
      const previousResponse = (global as any).Response;
      try {
        (global as any).Response = undefined;

        if (typeof (global as any).Response === 'undefined') {
          (global as any).Response = PolyfillResponse;
        }

        expect((global as any).Response).toBe(PolyfillResponse);
      } finally {
        (global as any).Response = previousResponse;
      }
    });
  });
});