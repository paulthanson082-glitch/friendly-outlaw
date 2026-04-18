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
    private _body: any;
    readonly headers: Map<string, string>;

    constructor(body?: any, init?: any) {
      this._status = init?.status ?? 200;
      this._body = body;
      this.headers = new Map();
      if (init?.headers) {
        Object.entries(init.headers as Record<string, string>).forEach(([k, v]) => {
          this.headers.set(k.toLowerCase(), v);
        });
      }
    }

    get status(): number {
      return this._status;
    }

    async json() {
      return typeof this._body === 'string' ? JSON.parse(this._body) : this._body;
    }

    async text() {
      return typeof this._body === 'string' ? this._body : JSON.stringify(this._body);
    }

    static json(data: any, init?: any) {
      const response = new PolyfillResponse(data, init);
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