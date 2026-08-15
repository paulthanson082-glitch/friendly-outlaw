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
import CollaborateScreen from './src/screens/CollaborateScreen';
import InsightsScreen from './src/screens/InsightsScreen';

// Context
import { AuthProvider, useAuth } from './src/context/AuthContext';
import { APIProvider } from './src/context/APIContext';
import { LocalizationProvider, useLocalization } from './src/localization/LocalizationContext';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

// Keep splash screen visible while loading
SplashScreen.preventAutoHideAsync();

/**
 * Main navigation stack when authenticated
 */
const MainTabs = () => {
  const { t } = useLocalization();

  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: true,
        tabBarActiveTintColor: '#007bff',
        tabBarInactiveTintColor: '#999',
        tabBarLabelStyle: { fontSize: 11, marginTop: -8 },
        tabBarStyle: { paddingBottom: 5, height: 60 },
      }}
    >
      <Tab.Screen
        name="Documents"
        component={DocumentsScreen}
        options={{
          tabBarLabel: '📄 ' + t('navigation.documents'),
          headerTitle: t('documents.myDocuments'),
        }}
      />
      <Tab.Screen
        name="Templates"
        component={TemplatesScreen}
        options={{
          tabBarLabel: '📚 ' + t('navigation.templates'),
          headerTitle: t('templates.writingTemplates'),
        }}
      />
      <Tab.Screen
        name="Kanban"
        component={KanbanScreen}
        options={{
          tabBarLabel: '📊 ' + t('navigation.kanban'),
          headerTitle: t('kanban.taskBoard'),
        }}
      />
      <Tab.Screen
        name="Insights"
        component={InsightsScreen}
        options={{
          tabBarLabel: '📈 ' + t('navigation.insights'),
          headerTitle: t('insights.analytics'),
        }}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsScreen}
        options={{
          tabBarLabel: '⚙️ ' + t('navigation.settings'),
          headerTitle: t('settings.settings'),
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
          contentStyle: { backgroundColor: '#fff' },
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
    <LocalizationProvider>
      <AuthProvider>
        <APIProvider>
          <AppContent />
        </APIProvider>
      </AuthProvider>
    </LocalizationProvider>
  );
}
