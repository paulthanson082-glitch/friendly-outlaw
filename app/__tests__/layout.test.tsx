import { render } from '@testing-library/react';
import RootLayout, { metadata } from '../layout';

describe('RootLayout', () => {
  it('should render children correctly', () => {
    const { getByTestId } = render(
      <RootLayout>
        <div data-testid="child-content">Test Content</div>
      </RootLayout>
    );

    expect(getByTestId('child-content')).toBeInTheDocument();
    expect(getByTestId('child-content')).toHaveTextContent('Test Content');
  });

  it('should render multiple children', () => {
    const { getByText } = render(
      <RootLayout>
        <>
          <div>First Child</div>
          <div>Second Child</div>
        </>
      </RootLayout>
    );

    expect(getByText('First Child')).toBeInTheDocument();
    expect(getByText('Second Child')).toBeInTheDocument();
  });

  it('should handle empty children gracefully', () => {
    const { container } = render(
      <RootLayout>
        <div></div>
      </RootLayout>
    );

    expect(container).toBeInTheDocument();
  });

  it('should accept ReactNode as children', () => {
    const { getByText } = render(
      <RootLayout>
        <span>Text child</span>
      </RootLayout>
    );

    expect(getByText('Text child')).toBeInTheDocument();
  });

  it('should render without errors', () => {
    expect(() => {
      render(
        <RootLayout>
          <div>Content</div>
        </RootLayout>
      );
    }).not.toThrow();
  });
});

describe('metadata', () => {
  it('should have correct title', () => {
    expect(metadata.title).toBe('AI Town');
  });

  it('should have correct description', () => {
    expect(metadata.description).toBe(
      'A virtual town where AI residents live, chat, and socialize'
    );
  });

  it('should only have title and description fields', () => {
    const keys = Object.keys(metadata);
    expect(keys).toHaveLength(2);
    expect(keys).toContain('title');
    expect(keys).toContain('description');
  });

  it('should have string values for all fields', () => {
    expect(typeof metadata.title).toBe('string');
    expect(typeof metadata.description).toBe('string');
  });

  it('should have non-empty values', () => {
    expect(metadata.title.length).toBeGreaterThan(0);
    expect(metadata.description.length).toBeGreaterThan(0);
  });

  it('should have SEO-friendly description length', () => {
    // Google typically displays 150-160 characters
    expect(metadata.description.length).toBeLessThanOrEqual(160);
  });
});

describe('RootLayout component structure', () => {
  it('should be a valid React component', () => {
    expect(typeof RootLayout).toBe('function');
  });

  it('should accept children prop with correct TypeScript type', () => {
    const layoutProps = {
      children: <div>Test</div>,
    };

    expect(() => {
      render(<RootLayout {...layoutProps}><div>Test</div></RootLayout>);
    }).not.toThrow();
  });

  it('should render without crashing with complex children', () => {
    const { container } = render(
      <RootLayout>
        <div>
          <span>Nested</span>
          <p>Content</p>
        </div>
      </RootLayout>
    );

    expect(container).toBeInTheDocument();
  });
});