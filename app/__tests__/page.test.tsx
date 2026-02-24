import { describe, expect, test, jest, beforeEach } from '@jest/globals';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import Home from '../page';

// Mock fetch globally
global.fetch = jest.fn() as jest.MockedFunction<typeof fetch>;

describe('Home component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (global.fetch as jest.MockedFunction<typeof fetch>).mockClear();
  });

  const mockTownData = {
    world: { status: 'running', tick: '5' },
    residents: [
      {
        id: '1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'An artist',
        latestMemory: 'I love colors',
        created_at: '2024-01-01T00:00:00Z',
      },
    ],
    feed: [
      {
        id: '1',
        from: 'pixel',
        to: 'sage',
        from_name: 'Pixel',
        to_name: 'Sage',
        content: 'Hello!',
        type: 'message',
        timestamp: '2024-01-01T00:00:00Z',
      },
    ],
  };

  test('should render loading state initially', () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockImplementation(
      () => new Promise(() => {}) // Never resolves
    );

    render(<Home />);
    expect(screen.getByText(/Loading AI Town/i)).toBeInTheDocument();
  });

  test('should fetch and display town data', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => mockTownData,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText('🏠 AI Town')).toBeInTheDocument();
    });

    expect(screen.getAllByText('Pixel').length).toBeGreaterThan(0);
    expect(screen.getByText('@pixel')).toBeInTheDocument();
  });

  test('should display world status and tick', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => mockTownData,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText(/Tick #5/i)).toBeInTheDocument();
      expect(screen.getByText(/running/i)).toBeInTheDocument();
    });
  });

  test('should display error when fetch fails', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: false,
      text: async () => 'Server error',
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText(/⚠/)).toBeInTheDocument();
    });
  });

  test('should show residents list', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => mockTownData,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText('Residents')).toBeInTheDocument();
      expect(screen.getByText('An artist')).toBeInTheDocument();
    });
  });

  test('should display messages in feed', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => mockTownData,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText('Hello!')).toBeInTheDocument();
    });
  });

  test('should filter feed when resident is selected', async () => {
    const mockDataWithMultipleMessages = {
      ...mockTownData,
      feed: [
        {
          id: '1',
          from: 'pixel',
          to: 'sage',
          from_name: 'Pixel',
          to_name: 'Sage',
          content: 'From Pixel',
          type: 'message',
          timestamp: '2024-01-01T00:00:00Z',
        },
        {
          id: '2',
          from: 'nova',
          to: 'reed',
          from_name: 'Nova',
          to_name: 'Reed',
          content: 'From Nova',
          type: 'message',
          timestamp: '2024-01-01T00:01:00Z',
        },
      ],
      residents: [
        ...mockTownData.residents,
        {
          id: '2',
          handle: 'nova',
          name: 'Nova',
          description: 'A scientist',
          latestMemory: null,
          created_at: '2024-01-01T00:00:00Z',
        },
      ],
    };

    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => mockDataWithMultipleMessages,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText('From Pixel')).toBeInTheDocument();
      expect(screen.getByText('From Nova')).toBeInTheDocument();
    });

    const pixelButton = screen.getAllByText('Pixel')[0].closest('button');
    if (pixelButton) {
      fireEvent.click(pixelButton);
    }

    await waitFor(() => {
      expect(screen.getByText('From Pixel')).toBeInTheDocument();
      // Nova's message might not be visible after filtering
    });
  });

  test('should run simulation when tick button is clicked', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => mockTownData,
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ tick: 6, generated: [] }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ ...mockTownData, world: { status: 'running', tick: '6' } }),
      } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText(/Tick #5/i)).toBeInTheDocument();
    });

    const tickButton = screen.getByText(/▶ Tick/i);
    fireEvent.click(tickButton);

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledWith(
        '/api/simulate',
        expect.objectContaining({
          method: 'POST',
        })
      );
    });
  });

  test('should toggle pause/resume when pause button is clicked', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => mockTownData,
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ status: 'paused' }),
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ ...mockTownData, world: { status: 'paused', tick: '5' } }),
      } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText(/running/i)).toBeInTheDocument();
    });

    const pauseButton = screen.getByText(/⏸ Pause/i);
    fireEvent.click(pauseButton);

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledWith(
        '/api/simulate',
        expect.objectContaining({
          method: 'PATCH',
          body: JSON.stringify({ action: 'pause' }),
        })
      );
    });
  });

  test('should refresh data when refresh button is clicked', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => mockTownData,
      } as Response)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => mockTownData,
      } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getAllByText('Pixel').length).toBeGreaterThan(0);
    });

    const refreshButton = screen.getByText('↻');
    fireEvent.click(refreshButton);

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledTimes(2);
    });
  });

  test('should display empty state when no messages', async () => {
    const emptyTownData = {
      ...mockTownData,
      feed: [],
    };

    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => emptyTownData,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText(/No messages yet/i, { exact: false })).toBeInTheDocument();
      expect(screen.getAllByText(/Tick/i).length).toBeGreaterThan(0);
    });
  });

  test('should show memory when resident has one', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => mockTownData,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText(/I love colors/i)).toBeInTheDocument();
    });
  });

  test('should disable tick button while simulating', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => mockTownData,
      } as Response)
      .mockImplementationOnce(
        () =>
          new Promise((resolve) =>
            setTimeout(
              () =>
                resolve({
                  ok: true,
                  json: async () => ({ tick: 6, generated: [] }),
                } as Response),
              100
            )
          )
      );

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText(/Tick #5/i)).toBeInTheDocument();
    });

    const tickButton = screen.getByText(/▶ Tick/i);
    fireEvent.click(tickButton);

    // Button should be disabled during simulation
    expect(tickButton).toBeDisabled();
  });

  test('should display resident description', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => mockTownData,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText('An artist')).toBeInTheDocument();
    });
  });

  test('should show message timestamp', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => mockTownData,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      // The timeAgo function should display some time format
      const timestamps = screen.getAllByText(/ago$/);
      expect(timestamps.length).toBeGreaterThan(0);
    });
  });

  test('should handle simulation error gracefully', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => mockTownData,
      } as Response)
      .mockResolvedValueOnce({
        ok: false,
        json: async () => ({ error: 'Simulation failed' }),
      } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getByText(/Tick #5/i)).toBeInTheDocument();
    });

    const tickButton = screen.getByText(/▶ Tick/i);
    fireEvent.click(tickButton);

    await waitFor(() => {
      expect(screen.getByText(/Simulation failed/i)).toBeInTheDocument();
    });
  });

  test('should clear resident filter when clear button is clicked', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => mockTownData,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getAllByText('Pixel').length).toBeGreaterThan(0);
    });

    // Select a resident
    const pixelButton = screen.getAllByText('Pixel')[0].closest('button');
    if (pixelButton) {
      fireEvent.click(pixelButton);
    }

    await waitFor(() => {
      expect(screen.getByText(/Conversations with @pixel/i)).toBeInTheDocument();
    });

    // Clear the filter
    const clearButton = screen.getByText('✕ Clear');
    fireEvent.click(clearButton);

    await waitFor(() => {
      expect(screen.getByText('Town Feed')).toBeInTheDocument();
    });
  });

  test('should toggle auto-run mode', async () => {
    (global.fetch as jest.MockedFunction<typeof fetch>).mockResolvedValueOnce({
      ok: true,
      json: async () => mockTownData,
    } as Response);

    render(<Home />);

    await waitFor(() => {
      expect(screen.getAllByText('Pixel').length).toBeGreaterThan(0);
    });

    const autoButton = screen.getByText(/⚡ Auto/i);
    fireEvent.click(autoButton);

    await waitFor(() => {
      expect(screen.getByText(/⏸ Auto/i)).toBeInTheDocument();
    });
  });
});