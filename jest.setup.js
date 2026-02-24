import '@testing-library/jest-dom'
import { TextEncoder, TextDecoder } from 'util'

// Polyfill Web APIs for Node environment
global.TextEncoder = TextEncoder
global.TextDecoder = TextDecoder

// Add fetch polyfill
if (!global.fetch) {
  global.fetch = jest.fn()
}

// Only polyfill if not already defined (Next.js provides these)
if (typeof global.Response === 'undefined' || !global.Response.json) {
  class CustomResponse {
    constructor(body, init) {
      this.body = body
      this.status = init?.status || 200
      this.headers = new Map(Object.entries(init?.headers || {}))
    }

    async json() {
      return typeof this.body === 'string' ? JSON.parse(this.body) : this.body
    }

    static json(data, init) {
      const response = new CustomResponse(JSON.stringify(data), init)
      response.json = async () => data
      return response
    }
  }

  if (typeof global.Response === 'undefined') {
    global.Response = CustomResponse
  } else {
    // Augment existing Response
    global.Response.json = CustomResponse.json
  }
}

if (typeof global.Headers === 'undefined') {
  global.Headers = Map
}

// Note: Next.js provides its own Request/Response implementations
// No need to polyfill Request as tests import NextRequest directly

// Need to import Anthropic shim after polyfills are set up
import('@anthropic-ai/sdk/shims/node')