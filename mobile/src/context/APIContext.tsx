import React, { createContext, useContext } from 'react';
import axios, { AxiosInstance } from 'axios';
import { useAuth } from './AuthContext';

interface APIContextType {
  client: AxiosInstance;
}

const APIContext = createContext<APIContextType | undefined>(undefined);

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3000/api';

export const APIProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { token } = useAuth();

  const client = axios.create({
    baseURL: API_URL,
    headers: {
      'Content-Type': 'application/json',
    },
  });

  // Add token to every request
  client.interceptors.request.use((config) => {
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  });

  // Handle errors globally
  client.interceptors.response.use(
    (response) => response,
    (error) => {
      if (error.response?.status === 401) {
        // Token expired - handle refresh or logout
        console.error('Unauthorized - token may have expired');
      }
      return Promise.reject(error);
    }
  );

  return <APIContext.Provider value={{ client }}>{children}</APIContext.Provider>;
};

export const useAPI = (): APIContextType => {
  const context = useContext(APIContext);
  if (context === undefined) {
    throw new Error('useAPI must be used within an APIProvider');
  }
  return context;
};
