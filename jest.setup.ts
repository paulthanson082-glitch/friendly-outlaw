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
    constructor(public body?: any, public init?: any) {}
    public status = 200;
    public headers = new Map();

    async json() {
      return typeof this.body === 'string' ? JSON.parse(this.body) : this.body;
    }

    async text() {
      return typeof this.body === 'string' ? this.body : JSON.stringify(this.body);
    }

    static json(data: any, init?: any) {
      const response = new Response(data, init);
      response.status = init?.status || 200;
      if (init?.headers) {
        response.headers = new Map(Object.entries(init.headers));
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