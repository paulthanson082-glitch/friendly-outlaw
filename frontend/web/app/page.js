'use client';
import { useState, useEffect } from 'react';
import { useAuth } from '../../../frontend/shared/hooks/useAuth';
import { apiClient } from '../../../frontend/shared/api-client';
import Link from 'next/link';

export default function Home() {
  const { user, isLoading } = useAuth();
  const [joke, setJoke] = useState('');
  const [jokeLoading, setJokeLoading] = useState(false);

  useEffect(() => {
    if (user) fetchJoke();
  }, [user]);

  const fetchJoke = async () => {
    setJokeLoading(true);
    try {
      const data = await apiClient.getRandomJoke('general');
      setJoke(data.text);
    } catch (error) {
      setJoke('Oops! I ran out of jokes. Try again later!');
    } finally {
      setJokeLoading(false);
    }
  };

  if (isLoading) {
    return <div className="flex justify-center items-center h-screen">Loading...</div>;
  }

  if (!user) {
    return (
      <div className="flex flex-col items-center justify-center h-screen bg-gradient-to-br from-indigo-500 to-pink-500">
        <h1 className="text-4xl font-bold text-white mb-8">Adult Joke Bot</h1>
        <p className="text-xl text-white mb-12">Tell me a joke and let's laugh together!</p>
        <Link href="/login" className="px-8 py-3 bg-white text-indigo-600 rounded-lg font-bold hover:bg-gray-100 transition mr-4">
          Login
        </Link>
        <Link href="/signup" className="px-8 py-3 bg-transparent border-2 border-white text-white rounded-lg font-bold hover:bg-white hover:text-indigo-600 transition">
          Sign Up
        </Link>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 py-8">
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-4xl font-bold text-center mb-2">
          Welcome, {user.name}! 😄
        </h1>
        <p className="text-center text-gray-600 mb-8">
          Here's a joke for you:
        </p>

        {jokeLoading ? (
          <div className="flex justify-center">
            <div className="text-gray-500">Loading joke...</div>
          </div>
        ) : (
          <>
            <div className="bg-white rounded-lg shadow-md p-8 max-w-2xl mx-auto mb-8">
              <p className="text-lg text-gray-800 mb-6 leading-relaxed">{joke}</p>
              <div className="flex gap-4 justify-center">
                <button
                  onClick={() => window.location.reload()}
                  className="px-6 py-2 bg-pink-500 hover:bg-pink-600 text-white rounded-lg font-medium transition"
                >
                  🤍 Save
                </button>
                <button
                  onClick={fetchJoke}
                  className="px-6 py-2 bg-indigo-500 hover:bg-indigo-600 text-white rounded-lg font-medium transition"
                >
                  Another one!
                </button>
              </div>
            </div>

            <div className="flex justify-center gap-4">
              <Link href="/chat" className="px-6 py-2 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 transition">
                Chat with me
              </Link>
              <Link href="/favorites" className="px-6 py-2 bg-pink-600 text-white rounded-lg font-medium hover:bg-pink-700 transition">
                My favorites
              </Link>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
