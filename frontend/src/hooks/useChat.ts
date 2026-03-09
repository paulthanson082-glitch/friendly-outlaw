import { useState, useCallback, useRef } from 'react';
import { apiClient, ChatSession, ChatMessage } from '../services/api';

interface UseChatOptions {
  onError?: (error: Error) => void;
  onSuccess?: (message: ChatMessage) => void;
}

export const useChat = (options?: UseChatOptions) => {
  const [session, setSession] = useState<ChatSession | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const abortControllerRef = useRef<AbortController | null>(null);

  // Create a new chat session
  const createSession = useCallback(async (context?: Record<string, any>) => {
    try {
      setError(null);
      const newSession = await apiClient.createSession(context);
      setSession(newSession);
      setMessages([]);
      return newSession;
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      setError(error);
      options?.onError?.(error);
      throw error;
    }
  }, [options]);

  // Load existing session and history
  const loadSession = useCallback(async (sessionId: string) => {
    try {
      setError(null);
      const [sess, hist] = await Promise.all([
        apiClient.getSession(sessionId),
        apiClient.getHistory(sessionId),
      ]);
      setSession(sess);
      setMessages(hist);
      return { session: sess, messages: hist };
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      setError(error);
      options?.onError?.(error);
      throw error;
    }
  }, [options]);

  // Send a message to Jules
  const sendMessage = useCallback(
    async (content: string, systemPrompt?: string) => {
      if (!session) {
        throw new Error('No active chat session');
      }

      try {
        setError(null);
        setIsLoading(true);

        // Add user message immediately
        const userMessage: ChatMessage = {
          id: `temp-${Date.now()}`,
          sessionId: session.id,
          role: 'user',
          content,
          timestamp: new Date().toISOString(),
        };
        setMessages((prev) => [...prev, userMessage]);

        // Stream assistant response
        let assistantContent = '';

        await new Promise<void>((resolve, reject) => {
          apiClient.streamMessageFetch(
            session.id,
            content,
            (chunk) => {
              if (chunk.type === 'text') {
                assistantContent += chunk.content;
                // Update UI with partial response
                setMessages((prev) => {
                  const updated = [...prev];
                  const lastMsg = updated[updated.length - 1];
                  if (lastMsg && lastMsg.role === 'assistant' && lastMsg.id === 'temp-stream') {
                    lastMsg.content = assistantContent;
                  } else {
                    updated.push({
                      id: 'temp-stream',
                      sessionId: session.id,
                      role: 'assistant',
                      content: assistantContent,
                      timestamp: new Date().toISOString(),
                    });
                  }
                  return updated;
                });
              } else if (chunk.type === 'error') {
                reject(new Error(chunk.content));
              } else if (chunk.type === 'stop') {
                resolve();
              }
            },
            reject,
            systemPrompt
          );
        });

        // Refresh message history from server
        const history = await apiClient.getHistory(session.id);
        setMessages(history);

        return assistantContent;
      } catch (err) {
        const error = err instanceof Error ? err : new Error(String(err));
        setError(error);
        options?.onError?.(error);
        throw error;
      } finally {
        setIsLoading(false);
      }
    },
    [session, options]
  );

  // Clear message history
  const clearHistory = useCallback(async () => {
    if (!session) {
      throw new Error('No active chat session');
    }

    try {
      await apiClient.clearHistory(session.id);
      setMessages([]);
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      setError(error);
      options?.onError?.(error);
      throw error;
    }
  }, [session, options]);

  // Delete session
  const deleteSession = useCallback(async (sessionId: string) => {
    try {
      await apiClient.deleteSession(sessionId);
      if (session?.id === sessionId) {
        setSession(null);
        setMessages([]);
      }
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      setError(error);
      options?.onError?.(error);
      throw error;
    }
  }, [session, options]);

  // Cancel ongoing request
  const cancel = useCallback(() => {
    if (abortControllerRef.current) {
      abortControllerRef.current.abort();
    }
  }, []);

  return {
    // State
    session,
    messages,
    isLoading,
    error,

    // Methods
    createSession,
    loadSession,
    sendMessage,
    clearHistory,
    deleteSession,
    cancel,
  };
};
