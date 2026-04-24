import React, { useState, useRef, useEffect, useCallback } from 'react';
import { useAuth } from '../../context/AuthContext';
import styles from './UserProfile.module.css';

export const UserProfile: React.FC = () => {
  const { user, logout } = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  const initials = user
    ? (user.displayName || user.email)
        .split(' ')
        .map((part) => part[0])
        .slice(0, 2)
        .join('')
        .toUpperCase()
    : '';

  const closeMenu = useCallback(() => {
    setIsOpen(false);
    triggerRef.current?.focus();
  }, []);

  const handleToggle = () => {
    setIsOpen((prev) => !prev);
  };

  const handleLogout = () => {
    closeMenu();
    logout();
  };

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const handleMenuKeyDown = (event: React.KeyboardEvent<HTMLDivElement>) => {
    if (event.key === 'Escape') {
      closeMenu();
    } else if (event.key === 'Tab') {
      setIsOpen(false);
    }
  };

  const handleTriggerKeyDown = (event: React.KeyboardEvent<HTMLButtonElement>) => {
    if (event.key === 'Escape' && isOpen) {
      closeMenu();
    }
  };

  useEffect(() => {
    if (isOpen && menuRef.current) {
      const firstFocusable = menuRef.current.querySelector<HTMLElement>(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      );
      firstFocusable?.focus();
    }
  }, [isOpen]);

  if (!user) return null;

  const menuId = 'user-profile-menu';

  return (
    <div className={styles.container} ref={containerRef}>
      <button
        ref={triggerRef}
        type="button"
        className={styles.trigger}
        onClick={handleToggle}
        onKeyDown={handleTriggerKeyDown}
        aria-haspopup="true"
        aria-expanded={isOpen}
        aria-controls={menuId}
        aria-label={`${user.displayName || user.email} user menu`}
      >
        <span className={styles.avatar} aria-hidden="true">
          {initials}
        </span>
        <span className={styles.displayName}>{user.displayName || user.email}</span>
        <span className={styles.chevron} aria-hidden="true">
          {isOpen ? '▲' : '▼'}
        </span>
      </button>

      {isOpen && (
        <div
          id={menuId}
          ref={menuRef}
          role="menu"
          aria-label="User profile menu"
          className={styles.menu}
          onKeyDown={handleMenuKeyDown}
        >
          <div className={styles.menuHeader} role="none">
            <div className={styles.menuAvatar} aria-hidden="true">
              {initials}
            </div>
            <div className={styles.menuUserInfo}>
              {user.displayName && (
                <span className={styles.menuDisplayName}>{user.displayName}</span>
              )}
              <span className={styles.menuEmail}>{user.email}</span>
            </div>
          </div>

          <hr className={styles.divider} role="separator" />

          <button
            type="button"
            role="menuitem"
            className={styles.menuItem}
            onClick={handleLogout}
          >
            Sign out
          </button>
        </div>
      )}
    </div>
  );
};
