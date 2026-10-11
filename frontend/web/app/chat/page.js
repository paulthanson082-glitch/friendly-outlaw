'use client';
import { useState, useEffect, useRef } from 'react';
import { useAuth } from '../../../../frontend/shared/hooks/useAuth';
import { apiClient } from '../../../../frontend/shared/api-client';
import Link from 'next/link';

export default function ChatPage() {
  const { user, isLoading } = useAuth();
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);
  const messagesEndRef = useRef(null);

  useEffect(() => {
    if (user) loadChatHistory();
  }, [user]);

  const loadChatHistory = async () => {
    try {
      const history = await apiClient.getChatHistory(50);
      setMessages(history);
    } catch (error) {
      console.error('Error loading chat history:', error);
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = async () => {
    if (!input.trim()) return;

    const userMessage = { type: 'user', text: input, timestamp: new Date() };
    setMessages([...messages, userMessage]);
    setInput('');

    setChatLoading(true);
    try {
      const response = await apiClient.sendChat(input);
      const botMessage = { type: 'bot', text: response.reply, timestamp: new Date() };
      setMessages((prev) => [...prev, botMessage]);
    } catch (error) {
      console.error('Error sending message:', error);
    } finally {
      setChatLoading(false);
    }
  };

  if (isLoading) {
    return <div className="flex justify-center items-center h-screen">Loading...</div>;
  }

  if (!user) {
    return (
      <div className="flex justify-center items-center h-screen">
        <Link href="/login" className="text-indigo-600">
          Please login first
        </Link>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-2xl mx-auto px-4">
        <h1 className="text-3xl font-bold mb-2">Chat with me, {user.name}! 😄</h1>
        <p className="text-gray-600 mb-6">Let's talk and laugh together</p>

        <div className="bg-white rounded-lg shadow-md p-6 mb-6 min-h-96 max-h-96 overflow-y-auto">
          {messages.length === 0 ? (
            <p className="text-center text-gray-500">No messages yet. Start the conversation!</p>
          ) : (
            <>
              {messages.map((message, idx) => (
                <div key={idx} className={`flex mb-4 ${message.type === 'user' ? 'justify-end' : 'justify-start'}`}>
                  <div
                    className={`px-4 py-3 rounded-lg max-w-xs ${
                      message.type === 'user'
                        ? 'bg-indigo-600 text-white'
                        : 'bg-gray-200 text-gray-900'
                    }`}
                  >
                    <p className="text-sm">{message.text}</p>
                  </div>
                </div>
              ))}
              <div ref={messagesEndRef} />
            </>
          )}
        </div>

        <div className="flex gap-2 mb-6">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
            placeholder="Say something funny..."
            disabled={chatLoading}
            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:opacity-50"
          />
          <button
            onClick={handleSendMessage}
            disabled={chatLoading || !input.trim()}
            className="px-6 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition disabled:opacity-50"
          >
            Send
          </button>
        </div>

        <Link href="/" className="text-indigo-600 hover:underline text-sm">
          ← Back to home
        </Link>
      </div>
    </div>
  );
}
