import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { ActivityIndicator, View } from 'react-native';
import * as SplashScreen from 'expo-splash-screen';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Screens
import LoginScreen from './src/screens/LoginScreen';
import DocumentsScreen from './src/screens/DocumentsScreen';
import TemplatesScreen from './src/screens/TemplatesScreen';
import KanbanScreen from './src/screens/KanbanScreen';
import GoalsScreen from './src/screens/GoalsScreen';
import DocumentDetailScreen from './src/screens/DocumentDetailScreen';
import SettingsScreen from './src/screens/SettingsScreen';

// Context
import { AuthProvider, useAuth } from './src/context/AuthContext';
import { APIProvider } from './src/context/APIContext';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

// Keep splash screen visible while loading
SplashScreen.preventAutoHideAsync();

/**
 * Main navigation stack when authenticated
 */
const MainTabs = () => {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: true,
        tabBarActiveTintColor: '#007bff',
        tabBarInactiveTintColor: '#999',
        tabBarLabelStyle: { fontSize: 12, marginTop: -8 },
        tabBarStyle: { paddingBottom: 5, height: 60 },
      }}
    >
      <Tab.Screen
        name="Documents"
        component={DocumentsScreen}
        options={{
          tabBarLabel: '📄 Documents',
          headerTitle: 'My Documents',
        }}
      />
      <Tab.Screen
        name="Templates"
        component={TemplatesScreen}
        options={{
          tabBarLabel: '📚 Templates',
          headerTitle: 'Writing Templates',
        }}
      />
      <Tab.Screen
        name="Kanban"
        component={KanbanScreen}
        options={{
          tabBarLabel: '📊 Kanban',
          headerTitle: 'Task Board',
        }}
      />
      <Tab.Screen
        name="Goals"
        component={GoalsScreen}
        options={{
          tabBarLabel: '🎯 Goals',
          headerTitle: 'Writing Goals',
        }}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsScreen}
        options={{
          tabBarLabel: '⚙️ Settings',
          headerTitle: 'Settings',
        }}
      />
    </Tab.Navigator>
  );
};

/**
 * Main App component with authentication check
 */
const AppContent = () => {
  const { isAuthenticated, isLoading } = useAuth();
  const [appReady, setAppReady] = useState(false);

  useEffect(() => {
    // Simulate app initialization
    setTimeout(async () => {
      setAppReady(true);
      await SplashScreen.hideAsync();
    }, 500);
  }, []);

  if (!appReady || isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#fff' }}>
        <ActivityIndicator size="large" color="#007bff" />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          cardStyle: { backgroundColor: '#fff' },
        }}
      >
        {!isAuthenticated ? (
          // Auth Stack
          <Stack.Screen
            name="Login"
            component={LoginScreen}
            options={{ headerShown: false }}
          />
        ) : (
          // Main Stack
          <>
            <Stack.Screen
              name="MainTabs"
              component={MainTabs}
              options={{ headerShown: false }}
            />
            <Stack.Screen
              name="DocumentDetail"
              component={DocumentDetailScreen}
              options={{
                headerTitle: 'Document',
                headerBackTitle: 'Back',
              }}
            />
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
};

/**
 * Root App component with providers
 */
export default function App() {
  return (
    <AuthProvider>
      <APIProvider>
        <AppContent />
      </APIProvider>
    </AuthProvider>
  );
}
