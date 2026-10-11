'use client';
import { useState, useEffect } from 'react';
import { useAuth } from '../../../../frontend/shared/hooks/useAuth';
import { apiClient } from '../../../../frontend/shared/api-client';
import Link from 'next/link';

export default function FavoritesPage() {
  const { user, isLoading } = useAuth();
  const [favorites, setFavorites] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (user) loadFavorites();
  }, [user]);

  const loadFavorites = async () => {
    setLoading(true);
    try {
      const data = await apiClient.getFavorites();
      setFavorites(data);
    } catch (error) {
      console.error('Error loading favorites:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleUnsave = async (jokeId) => {
    try {
      await apiClient.unsaveFavorite(jokeId);
      setFavorites(favorites.filter((fav) => fav.jokeId !== jokeId));
    } catch (error) {
      console.error('Error unsaving joke:', error);
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
      <div className="max-w-4xl mx-auto px-4">
        <h1 className="text-3xl font-bold mb-2">Your Favorite Jokes, {user.name}!</h1>
        <p className="text-gray-600 mb-8">
          {favorites.length === 0
            ? "You haven't saved any jokes yet. Go find some!"
            : `You have ${favorites.length} saved joke${favorites.length !== 1 ? 's' : ''}`}
        </p>

        {loading ? (
          <div className="text-center">Loading...</div>
        ) : favorites.length === 0 ? (
          <Link href="/" className="text-indigo-600 hover:underline">
            ← Go back and find some jokes
          </Link>
        ) : (
          <div className="grid gap-4 mb-6">
            {favorites.map((joke) => (
              <div key={joke.jokeId} className="bg-white rounded-lg shadow-md p-6">
                <p className="text-lg text-gray-800 mb-4">{joke.text}</p>
                <div className="flex justify-between items-center">
                  <span className="text-sm bg-indigo-100 text-indigo-800 px-3 py-1 rounded-full">
                    {joke.category}
                  </span>
                  <button
                    onClick={() => handleUnsave(joke.jokeId)}
                    className="text-pink-600 hover:text-pink-800 font-medium"
                  >
                    Remove
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        <Link href="/" className="text-indigo-600 hover:underline text-sm">
          ← Back to home
        </Link>
      </div>
    </div>
  );
}
