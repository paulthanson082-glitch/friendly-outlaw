import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import Home from '../page';

// Mock fetch globally
global.fetch = jest.fn();

describe('Home', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.runOnlyPendingTimers();
    jest.useRealTimers();
  });

  const mockTownData = {
    world: {
      status: 'running',
      tick: '5',
    },
    residents: [
      {
        id: '1',
        handle: 'pixel',
        name: 'Pixel',
        description: 'A curious artist',
        latestMemory: 'Had a great day',
        created_at: '2024-01-01T00:00:00Z',
      },
      {
        id: '2',
        handle: 'sage',
        name: 'Sage',
        description: 'A wise librarian',
        latestMemory: null,
        created_at: '2024-01-01T00:00:01Z',
      },
    ],
    feed: [
      {
        id: 'msg-1',
        from: 'pixel',
        to: 'sage',
        from_name: 'Pixel',
        to_name: 'Sage',
        content: 'Hello!',
        type: 'message',
        timestamp: '2024-01-01T00:01:00Z',
      },
    ],
  };

  describe('Initial render and data fetching', () => {
    it('should show loading state initially', () => {
      (global.fetch as jest.Mock).mockImplementation(
        () => new Promise(() => {}) // Never resolves
      );

      render(<Home />);

      expect(screen.getByText(/Loading AI Town/i)).toBeInTheDocument();
    });

    it('should fetch and display town data', async () => {
      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        json: async () => mockTownData,
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel').length).toBeGreaterThan(0);
        expect(screen.getAllByText('Sage').length).toBeGreaterThan(0);
      });
    });

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
  });

  describe('Header and world state display', () => {
    beforeEach(async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => mockTownData,
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      });
    });

    it('should display world tick', () => {
      expect(screen.getByText(/Tick #5/i)).toBeInTheDocument();
    });

    it('should display world status', () => {
      expect(screen.getByText(/running/i)).toBeInTheDocument();
    });

    it('should display app title', () => {
      expect(screen.getByText(/AI Town/i)).toBeInTheDocument();
    });
  });

  describe('Residents panel', () => {
    beforeEach(async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => mockTownData,
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      });
    });

    it('should display all residents', () => {
      expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      expect(screen.getAllByText('Sage')[0]).toBeInTheDocument();
    });

    it('should display resident descriptions', () => {
      expect(screen.getByText('A curious artist')).toBeInTheDocument();
      expect(screen.getByText('A wise librarian')).toBeInTheDocument();
    });

    it('should display resident handles', () => {
      expect(screen.getByText('@pixel')).toBeInTheDocument();
      expect(screen.getByText('@sage')).toBeInTheDocument();
    });

    it('should display latest memory when available', () => {
      expect(screen.getByText(/Had a great day/i)).toBeInTheDocument();
    });

    it('should allow selecting a resident', () => {
      const pixelCard = screen.getAllByText('Pixel')[0].closest('button');
      expect(pixelCard).not.toHaveClass('residentCardSelected');

      fireEvent.click(pixelCard!);

      expect(screen.getByText(/Conversations with @pixel/i)).toBeInTheDocument();
    });
  });

  describe('Message feed', () => {
    beforeEach(async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => mockTownData,
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      });
    });

    it('should display messages in the feed', () => {
      expect(screen.getByText('Hello!')).toBeInTheDocument();
    });

    it('should display message sender and recipient', () => {
      expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      expect(screen.getAllByText('Sage')[0]).toBeInTheDocument();
    });

    it('should filter feed when resident is selected', () => {
      const pixelCard = screen.getAllByText('Pixel')[0].closest('button');
      fireEvent.click(pixelCard!);

      expect(screen.getByText(/Conversations with @pixel/i)).toBeInTheDocument();
    });

    it('should show empty state when no messages exist', async () => {
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
  });

  describe('Simulation controls', () => {
    beforeEach(async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => mockTownData,
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      });

      jest.clearAllMocks();
    });

    it('should have a Tick button', () => {
      const tickButton = screen.getByRole('button', { name: /▶ Tick/i });
      expect(tickButton).toBeInTheDocument();
    });

    it('should call simulate API when Tick is clicked', async () => {
      (global.fetch as jest.Mock)
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({ tick: 6, generated: [] }),
        })
        .mockResolvedValueOnce({
          ok: true,
          json: async () => mockTownData,
        });

      const tickButton = screen.getByRole('button', { name: /▶ Tick/i });
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

    it('should disable Tick button while simulating', async () => {
      (global.fetch as jest.Mock).mockImplementation(
        () => new Promise(() => {}) // Never resolves
      );

      const tickButton = screen.getByRole('button', { name: /▶ Tick/i });
      fireEvent.click(tickButton);

      await waitFor(() => {
        expect(tickButton).toBeDisabled();
      });
    });

    it('should have Auto button', () => {
      const autoButton = screen.getByRole('button', { name: /⚡ Auto/i });
      expect(autoButton).toBeInTheDocument();
    });

    it('should toggle auto-run mode', () => {
      const autoButton = screen.getByRole('button', { name: /⚡ Auto/i });
      fireEvent.click(autoButton);

      expect(screen.getByRole('button', { name: /⏸ Auto/i })).toBeInTheDocument();
    });

    it('should have Pause/Resume button', () => {
      const pauseButton = screen.getByRole('button', { name: /⏸ Pause/i });
      expect(pauseButton).toBeInTheDocument();
    });

    it('should call pause API when Pause is clicked', async () => {
      (global.fetch as jest.Mock)
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({ status: 'paused' }),
        })
        .mockResolvedValueOnce({
          ok: true,
          json: async () => ({
            ...mockTownData,
            world: { ...mockTownData.world, status: 'paused' },
          }),
        });

      const pauseButton = screen.getByRole('button', { name: /⏸ Pause/i });
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

    it('should have refresh button', () => {
      const refreshButton = screen.getByRole('button', { name: '↻' });
      expect(refreshButton).toBeInTheDocument();
    });
  });

  describe('Auto-run mode', () => {
    beforeEach(async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => mockTownData,
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      });

      jest.clearAllMocks();
    });

    it('should run tick automatically when auto mode is enabled', async () => {
      (global.fetch as jest.Mock)
        .mockResolvedValue({
          ok: true,
          json: async () => ({ tick: 6, generated: [] }),
        })
        .mockResolvedValue({
          ok: true,
          json: async () => mockTownData,
        });

      const autoButton = screen.getByRole('button', { name: /⚡ Auto/i });
      fireEvent.click(autoButton);

      // Fast-forward time to trigger interval
      jest.advanceTimersByTime(8000);

      await waitFor(() => {
        expect(global.fetch).toHaveBeenCalledWith(
          '/api/simulate',
          expect.objectContaining({
            method: 'POST',
          })
        );
      });
    });

    it('should stop auto-run when disabled', async () => {
      const autoButton = screen.getByRole('button', { name: /⚡ Auto/i });

      // Enable auto-run
      fireEvent.click(autoButton);
      await waitFor(() => {
        expect(screen.getByRole('button', { name: /⏸ Auto/i })).toBeInTheDocument();
      });

      // Disable auto-run
      const pauseAutoButton = screen.getByRole('button', { name: /⏸ Auto/i });
      fireEvent.click(pauseAutoButton);

      jest.clearAllMocks();
      jest.advanceTimersByTime(8000);

      expect(global.fetch).not.toHaveBeenCalled();
    });
  });

  describe('Error handling', () => {
    it('should display error banner when simulation fails', async () => {
      (global.fetch as jest.Mock)
        .mockResolvedValueOnce({
          ok: true,
          json: async () => mockTownData,
        })
        .mockResolvedValueOnce({
          ok: false,
          json: async () => ({ error: 'Simulation failed' }),
        });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      });

      const tickButton = screen.getByRole('button', { name: /▶ Tick/i });
      fireEvent.click(tickButton);

      await waitFor(() => {
        expect(screen.getByText(/Simulation failed/i)).toBeInTheDocument();
      });
    });

    it('should handle network errors gracefully', async () => {
      (global.fetch as jest.Mock)
        .mockResolvedValueOnce({
          ok: true,
          json: async () => mockTownData,
        })
        .mockRejectedValueOnce(new Error('Network error'));

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      });

      const tickButton = screen.getByRole('button', { name: /▶ Tick/i });
      fireEvent.click(tickButton);

      await waitFor(() => {
        expect(screen.getByText(/Network error/i)).toBeInTheDocument();
      });
    });
  });

  describe('Utility functions', () => {
    it('should format time correctly', async () => {
      const now = Date.now();
      const oneMinuteAgo = new Date(now - 60 * 1000).toISOString();

      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => ({
          ...mockTownData,
          feed: [
            {
              ...mockTownData.feed[0],
              timestamp: oneMinuteAgo,
            },
          ],
        }),
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/1m ago/i)).toBeInTheDocument();
      });
    });

    it('should display correct avatars for known characters', async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => mockTownData,
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('🎨')[0]).toBeInTheDocument(); // Pixel
        expect(screen.getAllByText('📚')[0]).toBeInTheDocument(); // Sage
      });
    });
  });

  describe('Resident selection and filtering', () => {
    beforeEach(async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => ({
          ...mockTownData,
          feed: [
            {
              id: 'msg-1',
              from: 'pixel',
              to: 'sage',
              from_name: 'Pixel',
              to_name: 'Sage',
              content: 'Hello Sage!',
              type: 'message',
              timestamp: '2024-01-01T00:01:00Z',
            },
            {
              id: 'msg-2',
              from: 'sage',
              to: 'pixel',
              from_name: 'Sage',
              to_name: 'Pixel',
              content: 'Hello Pixel!',
              type: 'message',
              timestamp: '2024-01-01T00:01:01Z',
            },
            {
              id: 'msg-3',
              from: 'sage',
              to: 'nova',
              from_name: 'Sage',
              to_name: 'Nova',
              content: 'Hello Nova!',
              type: 'message',
              timestamp: '2024-01-01T00:01:02Z',
            },
          ],
        }),
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      });
    });

    it('should filter messages for selected resident', () => {
      const sageCard = screen.getAllByText('Sage')[0].closest('button');
      fireEvent.click(sageCard!);

      // Should show messages involving sage
      expect(screen.getByText('Hello Sage!')).toBeInTheDocument();
      expect(screen.getByText('Hello Pixel!')).toBeInTheDocument();
      expect(screen.getByText('Hello Nova!')).toBeInTheDocument();
    });

    it('should clear selection when clear button is clicked', () => {
      const pixelCard = screen.getAllByText('Pixel')[0].closest('button');
      fireEvent.click(pixelCard!);

      expect(screen.getByText(/Conversations with @pixel/i)).toBeInTheDocument();

      const clearButton = screen.getByRole('button', { name: /✕ Clear/i });
      fireEvent.click(clearButton);

      expect(screen.getByText(/Town Feed/i)).toBeInTheDocument();
      expect(screen.queryByText(/Conversations with/i)).not.toBeInTheDocument();
    });

    it('should toggle resident selection on click', () => {
      const pixelCard = screen.getAllByText('Pixel')[0].closest('button');

      // Select
      fireEvent.click(pixelCard!);
      expect(screen.getByText(/Conversations with @pixel/i)).toBeInTheDocument();

      // Deselect
      fireEvent.click(pixelCard!);
      expect(screen.getByText(/Town Feed/i)).toBeInTheDocument();
    });
  });

  describe('Race conditions and rapid interactions', () => {
    beforeEach(async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => mockTownData,
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getAllByText('Pixel')[0]).toBeInTheDocument();
      });

      jest.clearAllMocks();
    });

    it('should prevent multiple simultaneous tick operations', async () => {
      (global.fetch as jest.Mock)
        .mockImplementation(() => new Promise(() => {})); // Never resolves

      const tickButton = screen.getByRole('button', { name: /▶ Tick/i });

      // Click multiple times rapidly
      fireEvent.click(tickButton);
      fireEvent.click(tickButton);
      fireEvent.click(tickButton);

      await waitFor(() => {
        expect(tickButton).toBeDisabled();
      });

      // Should only call once due to simulating flag
      expect(global.fetch).toHaveBeenCalledTimes(1);
    });

    it('should handle rapid resident selection changes', () => {
      const pixelCard = screen.getAllByText('Pixel')[0].closest('button');
      const sageCard = screen.getAllByText('Sage')[0].closest('button');

      // Rapidly toggle selections
      fireEvent.click(pixelCard!);
      fireEvent.click(sageCard!);
      fireEvent.click(pixelCard!);

      // Should end up with pixel selected
      expect(screen.getByText(/Conversations with @pixel/i)).toBeInTheDocument();
    });
  });

  describe('Boundary and edge cases', () => {
    it('should handle zero tick count', async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => ({
          ...mockTownData,
          world: { ...mockTownData.world, tick: '0' },
        }),
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/Tick #0/i)).toBeInTheDocument();
      });
    });

    it('should handle very large tick numbers', async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => ({
          ...mockTownData,
          world: { ...mockTownData.world, tick: '999999' },
        }),
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText(/Tick #999999/i)).toBeInTheDocument();
      });
    });

    it('should handle residents with unknown handles (default avatar)', async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => ({
          ...mockTownData,
          residents: [
            {
              id: '999',
              handle: 'unknown',
              name: 'Unknown Bot',
              description: 'Mystery bot',
              latestMemory: null,
              created_at: '2024-01-01T00:00:00Z',
            },
          ],
          feed: [],
        }),
      });

      render(<Home />);

      await waitFor(() => {
        expect(screen.getByText('Unknown Bot')).toBeInTheDocument();
        // Should show default robot emoji
        expect(screen.getAllByText('🤖')[0]).toBeInTheDocument();
      });
    });
  });
});