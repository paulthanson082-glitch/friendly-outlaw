import '@testing-library/jest-dom';

// Polyfill for Next.js server environment
if (typeof Request === 'undefined') {
  global.Request = class Request {
    constructor(public url: string, public init?: any) {}
    async json() { return this.init?.body ? JSON.parse(this.init.body) : {}; }
  } as any;
}

if (typeof Response === 'undefined') {
  global.Response = class Response {
    body: any;
    init: any;
    status: number;
    headers: Map<string, string>;

    constructor(body?: any, init?: ResponseInit & { headers?: any }) {
      this.body = body;
      this.init = init;
      this.status = init?.status ?? 200;
      this.headers = new Map();
      if (init?.headers instanceof Map) {
        (init.headers as Map<string, string>).forEach((v, k) => this.headers.set(k, v));
      } else if (init?.headers) {
        Object.entries(init.headers).forEach(([k, v]) => this.headers.set(k, v as string));
      }
    }

    async json() {
      return typeof this.body === 'string' ? JSON.parse(this.body) : this.body;
    }

    async text() {
      return typeof this.body === 'string' ? this.body : JSON.stringify(this.body);
    }

    static json(data: any, init?: ResponseInit) {
      const response = new (global as any).Response(data, init);
      if ((init as any)?.headers) {
        response.headers = new Map(Object.entries((init as any).headers));
      }
      response.headers.set('content-type', 'application/json');
      return response;
    }
  } as any;
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