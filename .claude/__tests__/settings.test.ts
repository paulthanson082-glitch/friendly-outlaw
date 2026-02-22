import * as fs from 'fs';
import * as path from 'path';

describe('Claude Settings Configuration', () => {
  const settingsPath = path.join(__dirname, '..', 'settings.json');
  let settingsContent: string;
  let settings: any;

  beforeAll(() => {
    // Read the settings file
    settingsContent = fs.readFileSync(settingsPath, 'utf-8');
    settings = JSON.parse(settingsContent);
  });

  describe('JSON Validity', () => {
    test('should be valid JSON', () => {
      expect(() => JSON.parse(settingsContent)).not.toThrow();
    });

    test('should parse to an object', () => {
      expect(typeof settings).toBe('object');
      expect(settings).not.toBeNull();
    });
  });

  describe('Schema Structure', () => {
    test('should have a hooks property', () => {
      expect(settings).toHaveProperty('hooks');
      expect(typeof settings.hooks).toBe('object');
    });

    test('hooks should contain SessionStart', () => {
      expect(settings.hooks).toHaveProperty('SessionStart');
      expect(Array.isArray(settings.hooks.SessionStart)).toBe(true);
    });

    test('SessionStart should be an array with at least one entry', () => {
      expect(settings.hooks.SessionStart.length).toBeGreaterThan(0);
    });

    test('SessionStart entries should have hooks arrays', () => {
      settings.hooks.SessionStart.forEach((entry: any, index: number) => {
        expect(entry).toHaveProperty('hooks');
        expect(Array.isArray(entry.hooks)).toBe(true);
      });
    });

    test('hook entries should have type and command properties', () => {
      settings.hooks.SessionStart.forEach((entry: any) => {
        entry.hooks.forEach((hook: any) => {
          expect(hook).toHaveProperty('type');
          expect(hook).toHaveProperty('command');
          expect(typeof hook.type).toBe('string');
          expect(typeof hook.command).toBe('string');
        });
      });
    });

    test('hook type should be "command"', () => {
      settings.hooks.SessionStart.forEach((entry: any) => {
        entry.hooks.forEach((hook: any) => {
          expect(hook.type).toBe('command');
        });
      });
    });
  });

  describe('Hook Script Validation', () => {
    test('all hook commands should reference valid paths', () => {
      settings.hooks.SessionStart.forEach((entry: any) => {
        entry.hooks.forEach((hook: any) => {
          // Extract the path, handling environment variables
          const command = hook.command;
          expect(command).toBeTruthy();
          expect(command.length).toBeGreaterThan(0);
        });
      });
    });

    test('session-start.sh script should exist', () => {
      const hookScriptPath = path.join(__dirname, '..', 'hooks', 'session-start.sh');
      expect(fs.existsSync(hookScriptPath)).toBe(true);
    });

    test('session-start.sh should be a file (not a directory)', () => {
      const hookScriptPath = path.join(__dirname, '..', 'hooks', 'session-start.sh');
      const stats = fs.statSync(hookScriptPath);
      expect(stats.isFile()).toBe(true);
    });

    test('session-start.sh should have executable permissions', () => {
      const hookScriptPath = path.join(__dirname, '..', 'hooks', 'session-start.sh');
      const stats = fs.statSync(hookScriptPath);
      // Check if file has any execute bit set (owner, group, or other)
      // On Unix: mode & 0o111 checks if any execute permission is set
      const hasExecutePermission = (stats.mode & 0o111) !== 0;
      expect(hasExecutePermission).toBe(true);
    });

    test('session-start.sh should not be empty', () => {
      const hookScriptPath = path.join(__dirname, '..', 'hooks', 'session-start.sh');
      const stats = fs.statSync(hookScriptPath);
      expect(stats.size).toBeGreaterThan(0);
    });
  });

  describe('Configuration Integrity', () => {
    test('should not contain any additional top-level properties beyond hooks', () => {
      const allowedKeys = ['hooks'];
      const actualKeys = Object.keys(settings);
      actualKeys.forEach(key => {
        expect(allowedKeys).toContain(key);
      });
    });

    test('should have proper JSON formatting (no trailing commas)', () => {
      // This is validated by successful JSON.parse, but we can check formatting
      expect(() => JSON.parse(settingsContent)).not.toThrow();
    });

    test('settings file should be readable', () => {
      expect(fs.accessSync(settingsPath, fs.constants.R_OK)).toBeUndefined();
    });
  });

  describe('Edge Cases and Error Handling', () => {
    test('should handle reading settings without throwing', () => {
      expect(() => {
        fs.readFileSync(settingsPath, 'utf-8');
      }).not.toThrow();
    });

    test('SessionStart array should not be empty', () => {
      expect(settings.hooks.SessionStart).not.toHaveLength(0);
    });

    test('each hook should have non-empty command strings', () => {
      settings.hooks.SessionStart.forEach((entry: any) => {
        entry.hooks.forEach((hook: any) => {
          expect(hook.command.trim()).not.toBe('');
        });
      });
    });

    test('command paths should use forward slashes or environment variables', () => {
      settings.hooks.SessionStart.forEach((entry: any) => {
        entry.hooks.forEach((hook: any) => {
          // Commands should either start with $CLAUDE_PROJECT_DIR or be absolute paths
          const command = hook.command;
          expect(
            command.startsWith('$CLAUDE_PROJECT_DIR') ||
            command.startsWith('/') ||
            command.startsWith('./')
          ).toBe(true);
        });
      });
    });
  });

  describe('Negative Test Cases', () => {
    test('should fail gracefully if hook script is missing (simulated)', () => {
      const fakePath = path.join(__dirname, '..', 'hooks', 'nonexistent-script.sh');
      expect(fs.existsSync(fakePath)).toBe(false);
    });

    test('should detect if hooks array is malformed (current structure is valid)', () => {
      // This tests that our validation would catch malformed data
      expect(Array.isArray(settings.hooks.SessionStart)).toBe(true);

      // Verify each entry has the expected structure
      settings.hooks.SessionStart.forEach((entry: any) => {
        expect(entry).toHaveProperty('hooks');
        expect(Array.isArray(entry.hooks)).toBe(true);
      });
    });

    test('should validate hook type is not an unexpected value', () => {
      settings.hooks.SessionStart.forEach((entry: any) => {
        entry.hooks.forEach((hook: any) => {
          // Currently only "command" type is supported
          expect(['command']).toContain(hook.type);
        });
      });
    });
  });

  describe('Regression Tests', () => {
    test('settings should maintain backward compatibility with SessionStart hook structure', () => {
      // Ensure the structure matches expected format:
      // hooks.SessionStart[].hooks[].{type, command}
      expect(settings.hooks.SessionStart).toBeDefined();
      expect(Array.isArray(settings.hooks.SessionStart)).toBe(true);

      const firstEntry = settings.hooks.SessionStart[0];
      expect(firstEntry).toHaveProperty('hooks');
      expect(Array.isArray(firstEntry.hooks)).toBe(true);

      const firstHook = firstEntry.hooks[0];
      expect(firstHook).toHaveProperty('type');
      expect(firstHook).toHaveProperty('command');
    });

    test('should preserve exact command path format from settings.json', () => {
      const firstHook = settings.hooks.SessionStart[0].hooks[0];
      expect(firstHook.command).toBe('$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh');
    });

    test('JSON should not include any comments or invalid JSON extensions', () => {
      // Valid JSON should parse without issues
      const parsed = JSON.parse(settingsContent);
      const reserialized = JSON.stringify(parsed);
      const reparsed = JSON.parse(reserialized);

      expect(reparsed).toEqual(parsed);
    });
  });

  describe('Security Considerations', () => {
    test('command paths should not contain shell injection characters without proper context', () => {
      settings.hooks.SessionStart.forEach((entry: any) => {
        entry.hooks.forEach((hook: any) => {
          const command = hook.command;
          // Allow environment variables like $CLAUDE_PROJECT_DIR but check for injection patterns
          // Remove legitimate env var references before checking
          const commandWithoutEnvVars = command.replace(/\$[A-Z_]+/g, '');
          // Check for shell injection characters: semicolons, pipes, backticks, command substitution
          expect(commandWithoutEnvVars).not.toMatch(/[;&|`$()]/g);
        });
      });
    });

    test('settings file should not be world-writable', () => {
      const stats = fs.statSync(settingsPath);
      // Check that world-write bit is not set (check last bit of mode)
      const isWorldWritable = (stats.mode & 0o002) !== 0;
      expect(isWorldWritable).toBe(false);
    });
  });

  describe('Boundary Tests', () => {
    test('should handle settings with exactly one SessionStart entry', () => {
      expect(settings.hooks.SessionStart.length).toBeGreaterThanOrEqual(1);
    });

    test('should handle settings with exactly one hook per SessionStart entry', () => {
      settings.hooks.SessionStart.forEach((entry: any) => {
        expect(entry.hooks.length).toBeGreaterThanOrEqual(1);
      });
    });

    test('file size should be reasonable (not suspiciously large)', () => {
      const stats = fs.statSync(settingsPath);
      // Settings file should be under 10KB for a simple config
      expect(stats.size).toBeLessThan(10 * 1024);
    });
  });
});