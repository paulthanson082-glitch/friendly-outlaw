import React from 'react';
import { render } from '@testing-library/react';
import RootLayout, { metadata } from '../layout';

describe('RootLayout', () => {
  it('should render children', () => {
    const { container } = render(
      <RootLayout>
        <div data-testid="test-child">Test Content</div>
      </RootLayout>
    );

    expect(container.querySelector('[data-testid="test-child"]')).toBeInTheDocument();
  });

  it('should render html element with lang="en"', () => {
    const { container } = render(
      <RootLayout>
        <div>Test</div>
      </RootLayout>
    );

    const html = container.querySelector('html');
    expect(html).toHaveAttribute('lang', 'en');
  });

  it('should render body element', () => {
    const { container } = render(
      <RootLayout>
        <div>Test</div>
      </RootLayout>
    );

    const body = container.querySelector('body');
    expect(body).toBeInTheDocument();
  });

  it('should wrap children in body element', () => {
    const { getByText } = render(
      <RootLayout>
        <div>Test Content</div>
      </RootLayout>
    );

    const content = getByText('Test Content');
    expect(content.closest('body')).toBeInTheDocument();
  });

  it('should handle multiple children', () => {
    const { getByText } = render(
      <RootLayout>
        <div>Child 1</div>
        <div>Child 2</div>
        <div>Child 3</div>
      </RootLayout>
    );

    expect(getByText('Child 1')).toBeInTheDocument();
    expect(getByText('Child 2')).toBeInTheDocument();
    expect(getByText('Child 3')).toBeInTheDocument();
  });

  it('should handle empty children', () => {
    const { container } = render(
      <RootLayout>
        <></>
      </RootLayout>
    );

    expect(container.querySelector('html')).toBeInTheDocument();
    expect(container.querySelector('body')).toBeInTheDocument();
  });

  it('should handle complex nested children', () => {
    const { getByText } = render(
      <RootLayout>
        <div>
          <header>Header</header>
          <main>Main Content</main>
          <footer>Footer</footer>
        </div>
      </RootLayout>
    );

    expect(getByText('Header')).toBeInTheDocument();
    expect(getByText('Main Content')).toBeInTheDocument();
    expect(getByText('Footer')).toBeInTheDocument();
  });
});

describe('metadata', () => {
  it('should have correct title', () => {
    expect(metadata.title).toBe('AI Town');
  });

  it('should have correct description', () => {
    expect(metadata.description).toBe('A virtual town where AI residents live, chat, and socialize');
  });

  it('should be exported as Metadata type', () => {
    expect(metadata).toHaveProperty('title');
    expect(metadata).toHaveProperty('description');
  });

  it('should have string values for both properties', () => {
    expect(typeof metadata.title).toBe('string');
    expect(typeof metadata.description).toBe('string');
  });

  it('should have non-empty title', () => {
    expect(metadata.title).toBeTruthy();
    expect(metadata.title.length).toBeGreaterThan(0);
  });

  it('should have non-empty description', () => {
    expect(metadata.description).toBeTruthy();
    expect(metadata.description.length).toBeGreaterThan(0);
  });

  it('should have descriptive content', () => {
    expect(metadata.description).toContain('AI');
    expect(metadata.description).toContain('town');
  });

  it('should have SEO-friendly title length', () => {
    expect(metadata.title.length).toBeLessThan(60);
  });

  it('should have SEO-friendly description length', () => {
    expect(metadata.description.length).toBeGreaterThan(50);
    expect(metadata.description.length).toBeLessThan(160);
  });

  it('should not contain special HTML entities in metadata', () => {
    expect(metadata.title).not.toContain('&');
    expect(metadata.title).not.toContain('<');
    expect(metadata.title).not.toContain('>');
  });

  it('should have metadata that matches page purpose', () => {
    expect(metadata.title.toLowerCase()).toContain('ai');
    expect(metadata.description.toLowerCase()).toContain('residents');
  });
});

describe('RootLayout structure regression tests (PR container.querySelector change)', () => {
  // The PR changed assertions from `document.documentElement` / `document.body`
  // to `container.querySelector('html')` / `container.querySelector('body')`.
  //
  // In jsdom, when React renders <html><body>...</body></html>, the html and body
  // elements are parsed as document.documentElement and document.body rather than
  // being nested as children of the render container div. Therefore:
  //   - container.querySelector('html') returns null
  //   - document.documentElement returns the <html lang="en"> element
  //
  // These tests document the actual rendering behaviour in jsdom and verify that
  // the RootLayout renders the expected document structure.

  it('should produce an html element with lang="en" accessible via document.documentElement', () => {
    render(
      <RootLayout>
        <span data-testid="anchor">content</span>
      </RootLayout>
    );

    // The <html> element rendered by RootLayout ends up as document.documentElement
    // in jsdom (not as a child of the container div).
    expect(document.documentElement).toHaveAttribute('lang', 'en');
  });

  it('should produce a body element accessible via document.body', () => {
    render(
      <RootLayout>
        <span>content</span>
      </RootLayout>
    );

    expect(document.body).toBeInTheDocument();
  });

  it('container.querySelector("html") is null because html is not nested inside the container div', () => {
    // This test documents a jsdom behaviour that was the source of the PR test changes:
    // container is a <div> appended to document.body, so html is never a descendant.
    const { container } = render(
      <RootLayout>
        <span>content</span>
      </RootLayout>
    );

    expect(container.querySelector('html')).toBeNull();
  });

  it('should render children into the document tree and make them queryable via container', () => {
    const { container } = render(
      <RootLayout>
        <p data-testid="inner-para">paragraph text</p>
      </RootLayout>
    );

    // Children ARE reachable via container (they end up inside the container div
    // that RTL appends to document.body).
    expect(container.querySelector('[data-testid="inner-para"]')).toBeInTheDocument();
  });

  it('should set the document lang attribute to "en" when rendering RootLayout', () => {
    render(
      <RootLayout>
        <div />
      </RootLayout>
    );

    // The lang attribute on <html> affects the document language.
    expect(document.documentElement.getAttribute('lang')).toBe('en');
  });

  it('should render children inside the document body when using RootLayout', () => {
    const { getByText } = render(
      <RootLayout>
        <article>Nested article content</article>
      </RootLayout>
    );

    const articleEl = getByText('Nested article content');
    // The article is a descendant of document.body.
    expect(document.body.contains(articleEl)).toBe(true);
  });
});