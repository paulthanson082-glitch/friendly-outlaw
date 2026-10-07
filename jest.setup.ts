import '@testing-library/jest-dom';

// Polyfill for Next.js server environment
if (typeof Request === 'undefined') {
  global.Request = class Request {
    constructor(public url: string, public init?: any) {}
    async json() { return this.init?.body ? JSON.parse(this.init.body) : {}; }
  } as any;
}

// Always override Response so that NextResponse.json({}, { status: N }) correctly
// reflects the given status code.  jsdom provides a native Response but its
// constructor ignores the `status` option, causing every response to appear as
// 200.  Our replacement properly stores the status supplied in the `init` arg.
{
  class PolyfillResponse {
    private _status: number;
    private _jsonString: string | undefined;
    readonly headers: Map<string, string>;

    constructor(body?: any, init?: any) {
      this._status = init?.status ?? 200;
      // Normalise the body to a JSON string. Next.js passes response.body
      // (a ReadableStream from our own static json()) as the body of NextResponse,
      // so we must be able to round-trip through our body getter.
      if (body === undefined) {
        this._jsonString = undefined;
      } else if (body === null) {
        this._jsonString = 'null';
      } else if (typeof body === 'string') {
        this._jsonString = body;
      } else if (typeof (body as any).getReader === 'function') {
        // ReadableStream — read synchronously via our own body getter
        this._jsonString = (body as any)._jsonString;
      } else {
        this._jsonString = JSON.stringify(body);
      }
      this.headers = new Map();
      if (init?.headers) {
        const h = init.headers;
        const entries = typeof h.entries === 'function'
          ? [...h.entries()]
          : Object.entries(h as Record<string, string>);
        entries.forEach(([k, v]: [string, string]) => {
          this.headers.set(k.toLowerCase(), v);
        });
      }
    }

    get status(): number {
      return this._status;
    }

    // Expose body as a ReadableStream-like object so NextResponse.json() can
    // access response.body and forward it to the NextResponse constructor.
    get body(): any {
      const s = this._jsonString;
      return { _jsonString: s, getReader: () => null };
    }

    async json(): Promise<any> {
      return this._jsonString !== undefined ? JSON.parse(this._jsonString) : undefined;
    }

    async text(): Promise<string> {
      return this._jsonString ?? '';
    }

    static json(data: any, init?: any) {
      const response = new PolyfillResponse(JSON.stringify(data), init);
      response.headers.set('content-type', 'application/json');
      return response;
    }
  }

  global.Response = PolyfillResponse as any;
}

if (typeof Headers === 'undefined') {
  global.Headers = class Headers extends Map {
    constructor(init?: any) {
      super();
      if (init) {
        Object.entries(init).forEach(([key, value]) => {
          this.set(key, value as string);
        });
      }
    }
  } as any;
}