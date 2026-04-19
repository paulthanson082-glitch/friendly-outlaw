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
    render(
      <RootLayout>
        <div>Test</div>
      </RootLayout>
    );

    const html = document.documentElement;
    expect(html).toHaveAttribute('lang', 'en');
  });

  it('should render body element', () => {
    render(
      <RootLayout>
        <div>Test</div>
      </RootLayout>
    );

    const body = document.body;
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
    render(
      <RootLayout>
        <></>
      </RootLayout>
    );

    expect(document.documentElement).toBeInTheDocument();
    expect(document.body).toBeInTheDocument();
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