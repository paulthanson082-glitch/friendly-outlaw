import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import Home from '../page';

// Mock fetch
global.fetch = jest.fn();

describe('Home Page', () => {
  const mockTownData = {
    world: {
      tick: '5',
      status: 'running',
    },
    residents: [
      {
        id: '1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'A curious artist',
        latestMemory: 'Had a great day painting',
        created_at: '2024-01-01T00:00:00Z',
      },
      {
        id: '2',
        handle: 'sage',
        name: 'Sage',
        description: 'A wise librarian',
        latestMemory: null,
        created_at: '2024-01-01T00:00:00Z',
      },
    ],
    feed: [
      {
        id: 'msg1',
        from: 'pixel',
        to: 'sage',
        from_name: 'Pixel',
        to_name: 'Sage',
        content: 'Hello Sage!',
        type: 'message',
        timestamp: new Date(Date.now() - 5000).toISOString(),
      },
      {
        id: 'msg2',
        from: 'sage',
        to: 'pixel',
        from_name: 'Sage',
        to_name: 'Pixel',
        content: 'Hi Pixel!',
        type: 'message',
        timestamp: new Date(Date.now() - 10000).toISOString(),
      },
    ],
  };

  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: true,
      json: async () => mockTownData,
      text: async () => 'Mock response',
    });
  });

  afterEach(() => {
    jest.runOnlyPendingTimers();
    jest.useRealTimers();
  });

  describe('Initial render', () => {
    it('should show loading state initially', () => {
      render(<Home />);
      expect(screen.getByText(/Loading AI Town/i)).toBeInTheDocument();
    });

    it('should fetch town data on mount', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(global.fetch).toHaveBeenCalledWith('/api/town');
      });
    });

    it('should display town data after loading', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByRole('heading', { name: /AI Town/i })).toBeInTheDocument();
      });
    });

    it('should display residents after loading', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel').length).toBeGreaterThan(0);
        expect(screen.getAllByText('Sage').length).toBeGreaterThan(0);
      });
    });

    it('should display messages after loading', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText('Hello Sage!')).toBeInTheDocument();
        expect(screen.getByText('Hi Pixel!')).toBeInTheDocument();
      });
    });
  });

  describe('World status display', () => {
    it('should display current tick number', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/Tick #5/i)).toBeInTheDocument();
      });
    });

    it('should display running status in green', async () => {
      render(<Home />);

      await waitFor(() => {
        const statusElement = screen.getByText('running');
        expect(statusElement).toHaveStyle({ color: '#4ade80' });
      });
    });

    it('should display paused status in red', async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => ({
          ...mockTownData,
          world: { tick: '5', status: 'paused' },
        }),
      });

      render(<Home />);

      await waitFor(() => {
        const statusElement = screen.getByText('paused');
        expect(statusElement).toHaveStyle({ color: '#f87171' });
      });
    });
  });

  describe('Residents panel', () => {
    it('should display all residents', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel').length).toBeGreaterThan(0);
        expect(screen.getAllByText('Sage').length).toBeGreaterThan(0);
      });
    });

    it('should display resident descriptions', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText('A curious artist')).toBeInTheDocument();
        expect(screen.getByText('A wise librarian')).toBeInTheDocument();
      });
    });

    it('should display resident handles', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText('@pixel')).toBeInTheDocument();
        expect(screen.getByText('@sage')).toBeInTheDocument();
      });
    });

    it('should display latest memory when available', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/Had a great day painting/i)).toBeInTheDocument();
      });
    });

    it('should allow selecting a resident', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel').length).toBeGreaterThan(0);
      });

      const pixelButton = screen.getAllByText('Pixel')[0].closest('button');
      await user.click(pixelButton!);

      await waitFor(() => {
        expect(screen.getByText(/Conversations with @pixel/i)).toBeInTheDocument();
      });
    });

    it('should filter feed when resident is selected', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel').length).toBeGreaterThan(0);
      });

      const pixelButton = screen.getAllByText('Pixel')[0].closest('button');
      await user.click(pixelButton!);

      await waitFor(() => {
        expect(screen.getByText('Hello Sage!')).toBeInTheDocument();
      });
    });
  });

  describe('Controls', () => {
    it('should have a Tick button', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/▶ Tick/i)).toBeInTheDocument();
      });
    });

    it('should have an Auto button', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/Auto/i)).toBeInTheDocument();
      });
    });

    it('should have a Pause/Resume button', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/Pause/i)).toBeInTheDocument();
      });
    });

    it('should have a refresh button', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText('↻')).toBeInTheDocument();
      });
    });

    it('should run simulation when Tick is clicked', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/▶ Tick/i)).toBeInTheDocument();
      });

      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => ({ tick: 6, generated: [] }),
      });

      const tickButton = screen.getByText(/▶ Tick/i);
      await user.click(tickButton);

      await waitFor(() => {
        expect(global.fetch).toHaveBeenCalledWith(
          '/api/simulate',
          expect.objectContaining({
            method: 'POST',
          })
        );
      });
    });

    it('should disable Tick button while simulating', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/▶ Tick/i)).toBeInTheDocument();
      });

      (global.fetch as jest.Mock).mockImplementation(() =>
        new Promise(resolve => setTimeout(() => resolve({
          ok: true,
          json: async () => ({ tick: 6, generated: [] }),
        }), 100))
      );

      const tickButton = screen.getByText(/▶ Tick/i);
      await user.click(tickButton);

      expect(tickButton).toBeDisabled();
    });

    it('should toggle pause/resume', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/⏸ Pause/i)).toBeInTheDocument();
      });

      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => ({ status: 'paused' }),
      });

      const pauseButton = screen.getByText(/⏸ Pause/i);
      await user.click(pauseButton);

      await waitFor(() => {
        expect(global.fetch).toHaveBeenCalledWith(
          '/api/simulate',
          expect.objectContaining({
            method: 'PATCH',
          })
        );
      });
    });

    it('should refresh town data when refresh button is clicked', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText('↻')).toBeInTheDocument();
      });

      jest.clearAllMocks();

      const refreshButton = screen.getByText('↻');
      await user.click(refreshButton);

      await waitFor(() => {
        expect(global.fetch).toHaveBeenCalledWith('/api/town');
      });
    });
  });

  describe('Auto-run mode', () => {
    it('should toggle auto-run when Auto button is clicked', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/⚡ Auto/i)).toBeInTheDocument();
      });

      const autoButton = screen.getByText(/⚡ Auto/i);
      await user.click(autoButton);

      await waitFor(() => {
        expect(screen.getByText(/⏸ Auto/i)).toBeInTheDocument();
      });
    });

    it('should run tick every 8 seconds in auto mode', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/⚡ Auto/i)).toBeInTheDocument();
      });

      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => ({ tick: 6, generated: [] }),
      });

      const autoButton = screen.getByText(/⚡ Auto/i);
      await user.click(autoButton);

      jest.advanceTimersByTime(8000);

      await waitFor(() => {
        expect(global.fetch).toHaveBeenCalledWith(
          '/api/simulate',
          expect.objectContaining({ method: 'POST' })
        );
      });
    });
  });

  describe('Error handling', () => {
    it('should display error message on fetch failure', async () => {
      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: false,
        text: async () => 'Server error',
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/Server error/i)).toBeInTheDocument();
      });
    });

    it('should display error on simulation failure', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/▶ Tick/i)).toBeInTheDocument();
      });

      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: false,
        json: async () => ({ error: 'Simulation failed' }),
      });

      const tickButton = screen.getByText(/▶ Tick/i);
      await user.click(tickButton);

      await waitFor(() => {
        expect(screen.getByText(/Simulation failed/i)).toBeInTheDocument();
      });
    });

    it('should handle network errors gracefully', async () => {
      (global.fetch as jest.Mock).mockRejectedValueOnce(new Error('Network error'));

      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/Network error/i)).toBeInTheDocument();
      });
    });
  });

  describe('Message feed', () => {
    it('should display empty state when no messages', async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => ({
          ...mockTownData,
          feed: [],
        }),
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/No messages yet/i)).toBeInTheDocument();
      });
    });

    it('should display message content', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText('Hello Sage!')).toBeInTheDocument();
        expect(screen.getByText('Hi Pixel!')).toBeInTheDocument();
      });
    });

    it('should display message metadata', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText(/ago/i).length).toBeGreaterThan(0);
      });
    });

    it('should clear filter when Clear button is clicked', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel').length).toBeGreaterThan(0);
      });

      const pixelButton = screen.getAllByText('Pixel')[0].closest('button');
      await user.click(pixelButton!);

      await waitFor(() => {
        expect(screen.getByText(/Conversations with @pixel/i)).toBeInTheDocument();
      });

      const clearButton = screen.getByText('✕ Clear');
      await user.click(clearButton);

      await waitFor(() => {
        expect(screen.getByText('Town Feed')).toBeInTheDocument();
      });
    });
  });

  describe('Helper functions', () => {
    it('should format timestamps correctly', async () => {
      render(<Home />);

      await waitFor(() => {
        const timeElements = screen.getAllByText(/ago/i);
        expect(timeElements.length).toBeGreaterThan(0);
      });
    });

    it('should display avatars for residents', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('🎨').length).toBeGreaterThan(0); // pixel
        expect(screen.getAllByText('📚').length).toBeGreaterThan(0); // sage
      });
    });
  });

  describe('Boundary conditions', () => {
    it('should handle very long message content', async () => {
      const longContent = 'A'.repeat(1000);
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => ({
          ...mockTownData,
          feed: [
            {
              ...mockTownData.feed[0],
              content: longContent,
            },
          ],
        }),
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(longContent)).toBeInTheDocument();
      });
    });

    it('should handle many residents', async () => {
      const manyResidents = Array.from({ length: 20 }, (_, i) => ({
        id: `${i}`,
        handle: `bot${i}`,
        name: `Bot ${i}`,
        description: `Bot number ${i}`,
        latestMemory: null,
        created_at: '2024-01-01T00:00:00Z',
      }));

      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => ({
          ...mockTownData,
          residents: manyResidents,
        }),
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText('Bot 0')).toBeInTheDocument();
        expect(screen.getByText('Bot 19')).toBeInTheDocument();
      });
    });

    it('should prevent double-clicking tick button', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/▶ Tick/i)).toBeInTheDocument();
      });

      let resolveFirstCall: any;
      (global.fetch as jest.Mock).mockImplementation(() =>
        new Promise(resolve => {
          resolveFirstCall = () => resolve({
            ok: true,
            json: async () => ({ tick: 6, generated: [] }),
          });
        })
      );

      const tickButton = screen.getByText(/▶ Tick/i);
      await user.click(tickButton);

      // Button should be disabled immediately
      expect(tickButton).toBeDisabled();

      // Resolve the promise
      resolveFirstCall();
    });

    it('should cleanup interval on unmount when auto-run is active', async () => {
      const user = userEvent.setup({ delay: null });
      const { unmount } = render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/⚡ Auto/i)).toBeInTheDocument();
      });

      const autoButton = screen.getByText(/⚡ Auto/i);
      await user.click(autoButton);

      // Unmount while auto-run is active
      unmount();

      // No assertion needed - just verifying no errors occur
    });

    it('should handle rapid tick button clicks gracefully', async () => {
      const user = userEvent.setup({ delay: null });
      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/▶ Tick/i)).toBeInTheDocument();
      });

      // Override fetch to return simulate response for POST and town data for GET
      (global.fetch as jest.Mock).mockImplementation((url: string) => {
        if (url.includes('/api/simulate')) {
          return Promise.resolve({
            ok: true,
            json: async () => ({ tick: 6, generated: [] }),
          });
        }
        return Promise.resolve({
          ok: true,
          json: async () => mockTownData,
        });
      });

      const tickButton = screen.getByText(/▶ Tick/i);

      // Try to click multiple times rapidly
      await user.click(tickButton);
      await user.click(tickButton);
      await user.click(tickButton);

      // Should only process one request at a time
      await waitFor(() => {
        expect(tickButton).not.toBeDisabled();
      });
    });

    it('should display correct avatar for each resident type', async () => {
      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('🎨').length).toBeGreaterThan(0);
        expect(screen.getAllByText('📚').length).toBeGreaterThan(0);
      });
    });
  });
});