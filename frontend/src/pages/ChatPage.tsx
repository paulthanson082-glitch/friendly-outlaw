import React, { useState, useEffect, useRef } from 'react';
import { useChat } from '../hooks/useChat';
import { useAuth } from '../context/AuthContext';
import styles from './ChatPage.module.css';

interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp?: string;
}

export const ChatPage: React.FC = () => {
  const { user } = useAuth();
  const { session, messages, isLoading, error, createSession, sendMessage } =
    useChat();

  const [inputValue, setInputValue] = useState('');
  const [displayMessages, setDisplayMessages] = useState<Message[]>([]);
  const [isComposing, setIsComposing] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Create session on mount
  useEffect(() => {
    if (user && !session) {
      createSession({ userId: user.id });
    }
  }, [user, session, createSession]);

  // Sync messages
  useEffect(() => {
    setDisplayMessages(
      messages.map((m) => ({
        id: m.id,
        role: m.role,
        content: m.content,
        timestamp: m.timestamp,
      }))
    );
  }, [messages]);

  // Auto-scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [displayMessages]);

  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputValue.trim() || !session || isLoading) return;

    const message = inputValue.trim();
    setInputValue('');

    try {
      await sendMessage(message);
    } catch (err) {
      console.error('Error sending message:', err);
    }
  };

  return (
    <div className={styles.chatContainer}>
      <header className={styles.header}>
        <h1>Jules - Your AI Writing Assistant</h1>
        <p className={styles.subtitle}>Chat with AI to improve your writing</p>
      </header>

      <div className={styles.messagesContainer}>
        {displayMessages.length === 0 ? (
          <div className={styles.welcomeMessage}>
            <h2>Welcome to Jules!</h2>
            <p>Start a conversation to get writing assistance, brainstorm ideas, or get feedback.</p>
            <div className={styles.examplePrompts}>
              <button
                onClick={() => setInputValue('Help me brainstorm ideas for a science fiction novel')}
                className={styles.exampleButton}
              >
                Brainstorm Ideas
              </button>
              <button
                onClick={() => setInputValue('Can you help me improve this paragraph?')}
                className={styles.exampleButton}
              >
                Improve Text
              </button>
              <button
                onClick={() => setInputValue('Generate a writing prompt for me')}
                className={styles.exampleButton}
              >
                Writing Prompt
              </button>
            </div>
          </div>
        ) : (
          displayMessages.map((msg) => (
            <div key={msg.id} className={`${styles.message} ${styles[msg.role]}`}>
              <div className={styles.messageRole}>{msg.role === 'user' ? 'You' : 'Jules'}</div>
              <div className={styles.messageContent}>{msg.content}</div>
              {msg.timestamp && (
                <div className={styles.timestamp}>
                  {new Date(msg.timestamp).toLocaleTimeString()}
                </div>
              )}
            </div>
          ))
        )}
        {isLoading && (
          <div className={`${styles.message} ${styles.assistant}`}>
            <div className={styles.messageRole}>Jules</div>
            <div className={styles.typingIndicator}>
              <span></span>
              <span></span>
              <span></span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {error && (
        <div className={styles.errorBanner}>
          <strong>Error:</strong> {error.message}
        </div>
      )}

      <form onSubmit={handleSendMessage} className={styles.inputForm}>
        <input
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onCompositionStart={() => setIsComposing(true)}
          onCompositionEnd={() => setIsComposing(false)}
          placeholder="Type your message... (Shift+Enter for new line)"
          className={styles.input}
          disabled={isLoading || !session}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey && !isComposing) {
              e.preventDefault();
              handleSendMessage(e);
            }
          }}
        />
        <button
          type="submit"
          disabled={isLoading || !inputValue.trim() || !session}
          className={styles.sendButton}
        >
          {isLoading ? 'Sending...' : 'Send'}
        </button>
      </form>

      <div className={styles.footer}>
        <p>Jules is an AI assistant powered by Claude. Always review suggestions before using them.</p>
      </div>
    </div>
  );
};
