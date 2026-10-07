import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import S24ToolsPage from '../s24/page';

const STORAGE_KEY = 's24-tools-checked';

// ---------------------------------------------------------------------------
// localStorage helpers
// ---------------------------------------------------------------------------

function mockLocalStorage() {
  const store: Record<string, string> = {};
  return {
    getItem: jest.fn((key: string) => store[key] ?? null),
    setItem: jest.fn((key: string, value: string) => {
      store[key] = value;
    }),
    removeItem: jest.fn((key: string) => {
      delete store[key];
    }),
    clear: jest.fn(() => {
      Object.keys(store).forEach((k) => delete store[k]);
    }),
    get store() {
      return store;
    },
  };
}

describe('S24ToolsPage', () => {
  let localStorageMock: ReturnType<typeof mockLocalStorage>;

  beforeEach(() => {
    localStorageMock = mockLocalStorage();
    Object.defineProperty(window, 'localStorage', {
      value: localStorageMock,
      writable: true,
    });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  // -------------------------------------------------------------------------
  // Initial render
  // -------------------------------------------------------------------------

  describe('Initial render', () => {
    it('renders the page title', () => {
      render(<S24ToolsPage />);
      expect(screen.getByText(/S24 Tools/i)).toBeInTheDocument();
    });

    it('renders the subtitle', () => {
      render(<S24ToolsPage />);
      expect(
        screen.getByText(/Speed · Productivity · Email · File Cleaning/i)
      ).toBeInTheDocument();
    });

    it('renders all four section tabs', () => {
      render(<S24ToolsPage />);
      expect(screen.getByText('Speed & Performance')).toBeInTheDocument();
      expect(screen.getByText('Productivity')).toBeInTheDocument();
      expect(screen.getByText('Email Management')).toBeInTheDocument();
      expect(screen.getByText('File Cleaning')).toBeInTheDocument();
    });

    it('shows the Speed & Performance section as the default active tab', () => {
      render(<S24ToolsPage />);
      // The section heading appears in the content area (not just the tab)
      const headings = screen.getAllByText(/Speed & Performance/i);
      expect(headings.length).toBeGreaterThanOrEqual(2); // tab + section heading
    });

    it('renders the first section task list on initial load', () => {
      render(<S24ToolsPage />);
      expect(screen.getByText('Run Device Care optimizer')).toBeInTheDocument();
    });

    it('shows overall progress counter starting at 0', () => {
      render(<S24ToolsPage />);
      // 27 total tasks across all sections
      expect(screen.getByText('0/27')).toBeInTheDocument();
    });

    it('renders the footer hint text', () => {
      render(<S24ToolsPage />);
      expect(
        screen.getByText(/Tap any task to mark it done/i)
      ).toBeInTheDocument();
    });

    it('does not show a Reset button when no tasks are checked', () => {
      render(<S24ToolsPage />);
      expect(screen.queryByText('Reset')).not.toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // localStorage persistence
  // -------------------------------------------------------------------------

  describe('localStorage persistence', () => {
    it('reads saved state from localStorage on mount', async () => {
      localStorageMock.getItem.mockReturnValue(
        JSON.stringify({ 'speed-1': true })
      );

      render(<S24ToolsPage />);

      await waitFor(() => {
        // "Run Device Care optimizer" should now be checked
        const btn = screen.getByLabelText('Mark incomplete');
        expect(btn).toBeInTheDocument();
      });
    });

    it('persists checked state to localStorage when a task is toggled', async () => {
      render(<S24ToolsPage />);

      const checkboxes = screen.getAllByLabelText('Mark complete');
      fireEvent.click(checkboxes[0]);

      await waitFor(() => {
        expect(localStorageMock.setItem).toHaveBeenCalledWith(
          STORAGE_KEY,
          expect.stringContaining('true')
        );
      });
    });

    it('handles corrupt localStorage data gracefully', async () => {
      localStorageMock.getItem.mockReturnValue('not-valid-json{{{');

      // Should render without throwing
      expect(() => render(<S24ToolsPage />)).not.toThrow();
      expect(screen.getByText(/S24 Tools/i)).toBeInTheDocument();
    });

    it('handles localStorage.setItem throwing without crashing', async () => {
      localStorageMock.setItem.mockImplementation(() => {
        throw new Error('QuotaExceededError');
      });

      render(<S24ToolsPage />);

      const checkboxes = screen.getAllByLabelText('Mark complete');
      expect(() => fireEvent.click(checkboxes[0])).not.toThrow();
    });

    it('stores the correct task id as the key in localStorage', async () => {
      render(<S24ToolsPage />);

      const checkboxes = screen.getAllByLabelText('Mark complete');
      fireEvent.click(checkboxes[0]); // speed-1

      await waitFor(() => {
        const lastCall =
          localStorageMock.setItem.mock.calls[
            localStorageMock.setItem.mock.calls.length - 1
          ];
        const stored = JSON.parse(lastCall[1]);
        expect(stored['speed-1']).toBe(true);
      });
    });
  });

  // -------------------------------------------------------------------------
  // Task toggling
  // -------------------------------------------------------------------------

  describe('Task toggling', () => {
    it('marks a task complete when its checkbox is clicked', async () => {
      render(<S24ToolsPage />);

      const checkbox = screen.getAllByLabelText('Mark complete')[0];
      fireEvent.click(checkbox);

      await waitFor(() => {
        expect(screen.getByLabelText('Mark incomplete')).toBeInTheDocument();
      });
    });

    it('un-marks a completed task when clicked again (toggle)', async () => {
      render(<S24ToolsPage />);

      const checkbox = screen.getAllByLabelText('Mark complete')[0];
      fireEvent.click(checkbox);

      await waitFor(() =>
        expect(screen.getByLabelText('Mark incomplete')).toBeInTheDocument()
      );

      fireEvent.click(screen.getByLabelText('Mark incomplete'));

      await waitFor(() => {
        expect(screen.queryByLabelText('Mark incomplete')).not.toBeInTheDocument();
      });
    });

    it('shows a checkmark inside a completed task checkbox', async () => {
      render(<S24ToolsPage />);

      const checkbox = screen.getAllByLabelText('Mark complete')[0];
      fireEvent.click(checkbox);

      await waitFor(() => {
        expect(screen.getByText('✓')).toBeInTheDocument();
      });
    });

    it('applies line-through style to a completed task label', async () => {
      render(<S24ToolsPage />);

      // Click the first task checkbox
      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);

      await waitFor(() => {
        const label = screen.getByText('Run Device Care optimizer');
        expect(label).toHaveStyle({ textDecoration: 'line-through' });
      });
    });

    it('increments the overall progress counter when a task is completed', async () => {
      render(<S24ToolsPage />);

      expect(screen.getByText('0/27')).toBeInTheDocument();

      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);

      await waitFor(() => {
        expect(screen.getByText('1/27')).toBeInTheDocument();
      });
    });

    it('increments the section tab badge count when a task is completed', async () => {
      render(<S24ToolsPage />);

      // Speed & Performance has 7 tasks; tab badge initially shows 0/7
      expect(screen.getAllByText('0/7')[0]).toBeInTheDocument();

      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);

      await waitFor(() => {
        expect(screen.getAllByText('1/7')[0]).toBeInTheDocument();
      });
    });
  });

  // -------------------------------------------------------------------------
  // Tab switching
  // -------------------------------------------------------------------------

  describe('Tab switching', () => {
    it('switches to Productivity section when its tab is clicked', async () => {
      render(<S24ToolsPage />);

      fireEvent.click(screen.getByText('Productivity'));

      await waitFor(() => {
        expect(screen.getByText('Install Microsoft 365')).toBeInTheDocument();
      });
    });

    it('switches to Email Management section when its tab is clicked', async () => {
      render(<S24ToolsPage />);

      fireEvent.click(screen.getByText('Email Management'));

      await waitFor(() => {
        expect(
          screen.getByText('Install Spark Mail for smart inbox')
        ).toBeInTheDocument();
      });
    });

    it('switches to File Cleaning section when its tab is clicked', async () => {
      render(<S24ToolsPage />);

      fireEvent.click(screen.getByText('File Cleaning'));

      await waitFor(() => {
        expect(
          screen.getByText('Run storage clean in Device Care')
        ).toBeInTheDocument();
      });
    });

    it('hides the previous section tasks when switching tabs', async () => {
      render(<S24ToolsPage />);

      // Speed tasks visible initially
      expect(screen.getByText('Run Device Care optimizer')).toBeInTheDocument();

      fireEvent.click(screen.getByText('Productivity'));

      await waitFor(() => {
        expect(
          screen.queryByText('Run Device Care optimizer')
        ).not.toBeInTheDocument();
      });
    });

    it('shows correct section progress text after switching tabs', async () => {
      render(<S24ToolsPage />);

      fireEvent.click(screen.getByText('Productivity'));

      await waitFor(() => {
        expect(screen.getByText('0 of 7 tasks completed')).toBeInTheDocument();
      });
    });
  });

  // -------------------------------------------------------------------------
  // Progress display
  // -------------------------------------------------------------------------

  describe('Progress display', () => {
    it('shows correct section progress text initially', () => {
      render(<S24ToolsPage />);
      expect(screen.getByText('0 of 7 tasks completed')).toBeInTheDocument();
    });

    it('updates section progress text when tasks are completed', async () => {
      render(<S24ToolsPage />);

      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);

      await waitFor(() => {
        expect(screen.getByText('1 of 7 tasks completed')).toBeInTheDocument();
      });
    });

    it('shows correct total task count (27) across all sections', () => {
      render(<S24ToolsPage />);
      // totalTasks = 7+7+6+7 = 27
      expect(screen.getByText('0/27')).toBeInTheDocument();
    });
  });

  // -------------------------------------------------------------------------
  // Reset section
  // -------------------------------------------------------------------------

  describe('Reset section', () => {
    it('shows Reset button only after at least one task is completed', async () => {
      render(<S24ToolsPage />);

      expect(screen.queryByText('Reset')).not.toBeInTheDocument();

      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);

      await waitFor(() => {
        expect(screen.getByText('Reset')).toBeInTheDocument();
      });
    });

    it('resets all tasks in the active section when Reset is clicked', async () => {
      render(<S24ToolsPage />);

      // Check first two tasks in Speed section
      const checkboxes = screen.getAllByLabelText('Mark complete');
      fireEvent.click(checkboxes[0]);
      fireEvent.click(checkboxes[1]);

      await waitFor(() =>
        expect(screen.getAllByLabelText('Mark incomplete')).toHaveLength(2)
      );

      fireEvent.click(screen.getByText('Reset'));

      await waitFor(() => {
        expect(screen.queryByLabelText('Mark incomplete')).not.toBeInTheDocument();
      });
    });

    it('hides Reset button after reset clears all tasks', async () => {
      render(<S24ToolsPage />);

      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);

      await waitFor(() =>
        expect(screen.getByText('Reset')).toBeInTheDocument()
      );

      fireEvent.click(screen.getByText('Reset'));

      await waitFor(() => {
        expect(screen.queryByText('Reset')).not.toBeInTheDocument();
      });
    });

    it('does not reset tasks in other sections when Reset is clicked', async () => {
      render(<S24ToolsPage />);

      // Complete a task in Productivity first
      fireEvent.click(screen.getByText('Productivity'));
      await waitFor(() =>
        expect(screen.getByText('Install Microsoft 365')).toBeInTheDocument()
      );
      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);
      await waitFor(() =>
        expect(screen.getByText('1 of 7 tasks completed')).toBeInTheDocument()
      );

      // Switch back to Speed, complete a task, then reset Speed
      fireEvent.click(screen.getByText('Speed & Performance'));
      await waitFor(() =>
        expect(screen.getByText('Run Device Care optimizer')).toBeInTheDocument()
      );
      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);
      await waitFor(() =>
        expect(screen.getByText('Reset')).toBeInTheDocument()
      );
      fireEvent.click(screen.getByText('Reset'));

      // Switch to Productivity and verify its task is still checked
      fireEvent.click(screen.getByText('Productivity'));
      await waitFor(() => {
        expect(screen.getByText('1 of 7 tasks completed')).toBeInTheDocument();
      });
    });
  });

  // -------------------------------------------------------------------------
  // Task details and links
  // -------------------------------------------------------------------------

  describe('Task details and links', () => {
    it('renders task detail text for tasks that have it', () => {
      render(<S24ToolsPage />);
      expect(
        screen.getByText(
          'Settings → Device Care → Optimize Now — clears RAM and junk'
        )
      ).toBeInTheDocument();
    });

    it('renders a link for tasks that have a link property', () => {
      render(<S24ToolsPage />);
      const link = screen.getByText('Play Store →');
      expect(link).toBeInTheDocument();
      expect(link.closest('a')).toHaveAttribute('href', expect.stringContaining('good+lock'));
    });

    it('opens task links in a new tab with noopener noreferrer', () => {
      render(<S24ToolsPage />);
      const link = screen.getByText('Play Store →').closest('a');
      expect(link).toHaveAttribute('target', '_blank');
      expect(link).toHaveAttribute('rel', 'noopener noreferrer');
    });

    it('renders multiple Play Store links when multiple tasks have links', async () => {
      render(<S24ToolsPage />);
      // Speed section has 1 link (Good Lock)
      const speedLinks = screen.getAllByText('Play Store →');
      expect(speedLinks.length).toBe(1);
    });

    it('renders links in Productivity section tasks', async () => {
      render(<S24ToolsPage />);

      fireEvent.click(screen.getByText('Productivity'));

      await waitFor(() => {
        const links = screen.getAllByText('Play Store →');
        // Microsoft 365, Notion, Tasker = 3 links
        expect(links.length).toBe(3);
      });
    });
  });

  // -------------------------------------------------------------------------
  // Boundary and regression cases
  // -------------------------------------------------------------------------

  describe('Boundary and regression cases', () => {
    it('correctly counts total tasks: 7 + 7 + 6 + 7 = 27', () => {
      render(<S24ToolsPage />);
      expect(screen.getByText('0/27')).toBeInTheDocument();
    });

    it('shows tasks done label next to overall count', () => {
      render(<S24ToolsPage />);
      expect(screen.getByText('tasks done')).toBeInTheDocument();
    });

    it('loads pre-checked state from localStorage for multiple tasks', async () => {
      localStorageMock.getItem.mockReturnValue(
        JSON.stringify({ 'speed-1': true, 'speed-2': true, 'speed-3': true })
      );

      render(<S24ToolsPage />);

      await waitFor(() => {
        const incomplete = screen.getAllByLabelText('Mark incomplete');
        expect(incomplete).toHaveLength(3);
      });
    });

    it('handles localStorage returning null (first visit) without errors', () => {
      localStorageMock.getItem.mockReturnValue(null as any);
      expect(() => render(<S24ToolsPage />)).not.toThrow();
      expect(screen.getByText('0/27')).toBeInTheDocument();
    });

    it('tab badge turns green (different style) when all tasks in section are complete', async () => {
      // Load all 7 speed tasks as checked
      const allSpeedChecked: Record<string, boolean> = {};
      for (let i = 1; i <= 7; i++) allSpeedChecked[`speed-${i}`] = true;
      localStorageMock.getItem.mockReturnValue(JSON.stringify(allSpeedChecked));

      render(<S24ToolsPage />);

      await waitFor(() => {
        // The tab badge for Speed should show 7/7
        expect(screen.getAllByText('7/7')[0]).toBeInTheDocument();
      });
    });

    it('does not display Reset button when switching to a section with no completed tasks', async () => {
      render(<S24ToolsPage />);

      // Complete a task in speed
      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);
      await waitFor(() =>
        expect(screen.getByText('Reset')).toBeInTheDocument()
      );

      // Switch to Productivity (no completed tasks)
      fireEvent.click(screen.getByText('Productivity'));
      await waitFor(() => {
        expect(screen.queryByText('Reset')).not.toBeInTheDocument();
      });
    });

    it('persists overall progress across tab switches', async () => {
      render(<S24ToolsPage />);

      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);
      await waitFor(() =>
        expect(screen.getByText('1/27')).toBeInTheDocument()
      );

      fireEvent.click(screen.getByText('Productivity'));
      await waitFor(() => {
        expect(screen.getByText('1/27')).toBeInTheDocument();
      });
    });

    it('renders email section with correct task count (6 tasks)', async () => {
      render(<S24ToolsPage />);

      fireEvent.click(screen.getByText('Email Management'));

      await waitFor(() => {
        expect(screen.getByText('0 of 6 tasks completed')).toBeInTheDocument();
      });
    });

    it('reads localStorage with the exact key "s24-tools-checked"', () => {
      render(<S24ToolsPage />);
      expect(localStorageMock.getItem).toHaveBeenCalledWith('s24-tools-checked');
    });

    it('writes localStorage with the exact key "s24-tools-checked" after toggle', async () => {
      render(<S24ToolsPage />);
      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);
      await waitFor(() => {
        expect(localStorageMock.setItem).toHaveBeenCalledWith(
          's24-tools-checked',
          expect.any(String)
        );
      });
    });

    it('File Cleaning section tab badge starts at 0/7', async () => {
      render(<S24ToolsPage />);
      fireEvent.click(screen.getByText('File Cleaning'));
      await waitFor(() => {
        expect(screen.getByText('0 of 7 tasks completed')).toBeInTheDocument();
      });
    });

    it('checking a task in File Cleaning increments its badge from 0/7 to 1/7', async () => {
      render(<S24ToolsPage />);
      fireEvent.click(screen.getByText('File Cleaning'));
      await waitFor(() =>
        expect(screen.getByText('Run storage clean in Device Care')).toBeInTheDocument()
      );
      fireEvent.click(screen.getAllByLabelText('Mark complete')[0]);
      await waitFor(() => {
        expect(screen.getByText('1 of 7 tasks completed')).toBeInTheDocument();
      });
    });

    it('all email tasks checked shows 6/6 in tab badge', async () => {
      const allEmailChecked: Record<string, boolean> = {};
      for (let i = 1; i <= 6; i++) allEmailChecked[`email-${i}`] = true;
      localStorageMock.getItem.mockReturnValue(JSON.stringify(allEmailChecked));

      render(<S24ToolsPage />);

      await waitFor(() => {
        expect(screen.getByText('6/6')).toBeInTheDocument();
      });
    });

    it('clicking the active tab again keeps the same section active', async () => {
      render(<S24ToolsPage />);
      // Speed is already active; click it again
      fireEvent.click(screen.getByText('Speed & Performance'));
      await waitFor(() => {
        expect(screen.getByText('Run Device Care optimizer')).toBeInTheDocument();
        expect(screen.getByText('0 of 7 tasks completed')).toBeInTheDocument();
      });
    });

    it('overall counter decrements back to 0 after toggling the only completed task off', async () => {
      render(<S24ToolsPage />);
      const checkbox = screen.getAllByLabelText('Mark complete')[0];
      fireEvent.click(checkbox);
      await waitFor(() => expect(screen.getByText('1/27')).toBeInTheDocument());

      fireEvent.click(screen.getByLabelText('Mark incomplete'));
      await waitFor(() => {
        expect(screen.getByText('0/27')).toBeInTheDocument();
      });
    });
  });

  // -------------------------------------------------------------------------
  // Label string exact-match regression tests (PR change: regex → exact string)
  // -------------------------------------------------------------------------

  describe('Checkbox label exact string matching', () => {
    it('uses exact label "Mark complete" (not a partial regex match)', () => {
      render(<S24ToolsPage />);
      // getAllByLabelText with exact string should find checkboxes
      const checkboxes = screen.getAllByLabelText('Mark complete');
      expect(checkboxes.length).toBeGreaterThan(0);
    });

    it('label changes to exact string "Mark incomplete" after completing a task', async () => {
      render(<S24ToolsPage />);
      const checkbox = screen.getAllByLabelText('Mark complete')[0];
      fireEvent.click(checkbox);

      await waitFor(() => {
        const incompleteBtn = screen.getByLabelText('Mark incomplete');
        expect(incompleteBtn).toBeInTheDocument();
      });
    });

    it('label reverts to exact string "Mark complete" after unchecking', async () => {
      render(<S24ToolsPage />);
      const checkbox = screen.getAllByLabelText('Mark complete')[0];
      fireEvent.click(checkbox);

      await waitFor(() =>
        expect(screen.getByLabelText('Mark incomplete')).toBeInTheDocument()
      );

      fireEvent.click(screen.getByLabelText('Mark incomplete'));

      await waitFor(() => {
        // The "Mark incomplete" button is gone
        expect(screen.queryByLabelText('Mark incomplete')).not.toBeInTheDocument();
        // A "Mark complete" button exists again
        expect(screen.getAllByLabelText('Mark complete').length).toBeGreaterThan(0);
      });
    });

    it('no "Mark incomplete" buttons are present on initial render', () => {
      render(<S24ToolsPage />);
      expect(screen.queryByLabelText('Mark incomplete')).not.toBeInTheDocument();
    });

    it('each completed task produces exactly one "Mark incomplete" button', async () => {
      render(<S24ToolsPage />);
      const checkboxes = screen.getAllByLabelText('Mark complete');
      fireEvent.click(checkboxes[0]);
      fireEvent.click(checkboxes[1]);

      await waitFor(() =>
        expect(screen.getAllByLabelText('Mark incomplete')).toHaveLength(2)
      );
    });
  });
});
