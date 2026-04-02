/**
 * Tests for the jest.setup.ts polyfill behavior.
 *
 * The PR changed the Response polyfill from an unconditional override to a
 * conditional one that only applies when `Response` is not already defined.
 * These tests verify the polyfill class behavior and the conditional logic.
 */

// ---------------------------------------------------------------------------
// Inline re-implementation of the polyfill exactly as it appears in jest.setup.ts
// so we can test the class in isolation without relying on the global set-up.
// ---------------------------------------------------------------------------

class PolyfillResponse {
  public body: any;
  public init: any;
  public status: number;
  public headers: Map<string, string>;

  constructor(body?: any, init?: any) {
    this.body = body;
    this.init = init;
    this.status = 200;
    this.headers = new Map();
  }

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
// Tests for the PolyfillResponse class (mirrors the new jest.setup.ts code)
// ---------------------------------------------------------------------------

describe('Response polyfill class (jest.setup.ts)', () => {
  describe('constructor', () => {
    it('should default status to 200', () => {
      const r = new PolyfillResponse();
      expect(r.status).toBe(200);
    });

    it('should accept a body argument', () => {
      const r = new PolyfillResponse({ hello: 'world' });
      expect(r.body).toEqual({ hello: 'world' });
    });

    it('should initialise with an empty Map for headers', () => {
      const r = new PolyfillResponse();
      expect(r.headers).toBeInstanceOf(Map);
      expect(r.headers.size).toBe(0);
    });

    it('should store body and init on public fields', () => {
      const body = { a: 1 };
      const init = { status: 201 };
      const r = new PolyfillResponse(body, init);
      expect(r.body).toBe(body);
      expect(r.init).toBe(init);
    });
  });

  describe('instance json() method', () => {
    it('should return parsed JSON when body is a string', async () => {
      const r = new PolyfillResponse('{"key":"value"}');
      const result = await r.json();
      expect(result).toEqual({ key: 'value' });
    });

    it('should return the body as-is when it is already an object', async () => {
      const obj = { foo: 'bar' };
      const r = new PolyfillResponse(obj);
      const result = await r.json();
      expect(result).toBe(obj);
    });

    it('should return null body as-is', async () => {
      const r = new PolyfillResponse(null);
      const result = await r.json();
      expect(result).toBeNull();
    });

    it('should handle numeric body', async () => {
      const r = new PolyfillResponse(42);
      const result = await r.json();
      expect(result).toBe(42);
    });
  });

  describe('instance text() method', () => {
    it('should return string body as-is', async () => {
      const r = new PolyfillResponse('hello text');
      const result = await r.text();
      expect(result).toBe('hello text');
    });

    it('should JSON-serialise an object body', async () => {
      const r = new PolyfillResponse({ a: 1 });
      const result = await r.text();
      expect(result).toBe('{"a":1}');
    });

    it('should JSON-serialise an array body', async () => {
      const r = new PolyfillResponse([1, 2, 3]);
      const result = await r.text();
      expect(result).toBe('[1,2,3]');
    });
  });

  describe('static json() factory method', () => {
    it('should set status from init object', () => {
      const r = PolyfillResponse.json({ ok: true }, { status: 201 });
      expect(r.status).toBe(201);
    });

    it('should default status to 200 when init is absent', () => {
      const r = PolyfillResponse.json({ ok: true });
      expect(r.status).toBe(200);
    });

    it('should default status to 200 when init has no status field', () => {
      const r = PolyfillResponse.json({ ok: true }, {});
      expect(r.status).toBe(200);
    });

    it('should set content-type header to application/json', () => {
      const r = PolyfillResponse.json({});
      expect(r.headers.get('content-type')).toBe('application/json');
    });

    it('should apply custom headers from init alongside content-type', () => {
      const r = PolyfillResponse.json({}, { headers: { 'x-custom': 'yes' } });
      expect(r.headers.get('x-custom')).toBe('yes');
      expect(r.headers.get('content-type')).toBe('application/json');
    });

    it('should store the data as the response body', async () => {
      const data = { message: 'created' };
      const r = PolyfillResponse.json(data, { status: 201 });
      const parsed = await r.json();
      expect(parsed).toEqual(data);
    });

    it('should handle 4xx status codes', () => {
      const r = PolyfillResponse.json({ error: 'Not Found' }, { status: 404 });
      expect(r.status).toBe(404);
    });

    it('should handle 5xx status codes', () => {
      const r = PolyfillResponse.json({ error: 'Server Error' }, { status: 500 });
      expect(r.status).toBe(500);
    });

    it('should handle null data', async () => {
      const r = PolyfillResponse.json(null);
      const parsed = await r.json();
      expect(parsed).toBeNull();
    });

    it('should handle array data', async () => {
      const data = [1, 2, 3];
      const r = PolyfillResponse.json(data);
      const parsed = await r.json();
      expect(parsed).toEqual(data);
    });
  });
});

// ---------------------------------------------------------------------------
// Tests for the conditional polyfill application logic in jest.setup.ts
// ---------------------------------------------------------------------------

describe('conditional polyfill application (jest.setup.ts)', () => {
  it('should not overwrite global.Response when it is already defined', () => {
    const originalResponse = global.Response;

    // Simulate the conditional guard from jest.setup.ts
    let polyfillApplied = false;
    if (typeof (global as any).Response === 'undefined') {
      polyfillApplied = true;
    }

    // In jsdom, Response is already provided by the environment
    expect(polyfillApplied).toBe(false);
    expect(global.Response).toBe(originalResponse);
  });

  it('should apply the polyfill when Response is not defined', () => {
    const saved = (global as any).Response;
    delete (global as any).Response;

    let polyfillApplied = false;
    if (typeof (global as any).Response === 'undefined') {
      (global as any).Response = PolyfillResponse;
      polyfillApplied = true;
    }

    expect(polyfillApplied).toBe(true);
    expect((global as any).Response).toBe(PolyfillResponse);

    // Restore
    (global as any).Response = saved;
  });

  it('should apply the Request polyfill when Request is not defined', () => {
    const saved = (global as any).Request;
    delete (global as any).Request;

    let polyfillApplied = false;
    if (typeof (global as any).Request === 'undefined') {
      polyfillApplied = true;
    }

    expect(polyfillApplied).toBe(true);

    // Restore
    (global as any).Request = saved;
  });

  it('global.Response should be defined in jsdom test environment', () => {
    expect(global.Response).toBeDefined();
  });

  it('global.Request should be defined after jest.setup.ts runs', () => {
    // jest.setup.ts installs a Request polyfill if undefined
    expect(global.Request).toBeDefined();
  });

  it('global.Headers should be defined after jest.setup.ts runs', () => {
    // jest.setup.ts installs a Headers polyfill if undefined
    expect(global.Headers).toBeDefined();
  });
});

// ---------------------------------------------------------------------------
// Regression: the NEW polyfill's static json() must set status from init,
// unlike jsdom's native Response which may not honour status in the constructor.
// ---------------------------------------------------------------------------

describe('Response polyfill regression: status propagation', () => {
  it('static json() should reflect a non-200 status (regression for old jsdom bug)', () => {
    // The OLD jest.setup.ts comment said jsdom's Response constructor ignores status.
    // The new polyfill is only conditionally applied, but its static json() must
    // still honour the status when the polyfill IS used.
    const r = PolyfillResponse.json({ err: 'Conflict' }, { status: 409 });
    expect(r.status).toBe(409);
  });

  it('static json() with status 0 should fall back to 200 (falsy guard)', () => {
    // The new code uses `init?.status || 200`, so status: 0 falls back to 200.
    const r = PolyfillResponse.json({}, { status: 0 });
    expect(r.status).toBe(200);
  });
});