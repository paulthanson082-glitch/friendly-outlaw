import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { AuthProvider, useAuthContext } from '../../shared/context/AuthContext';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

function AuthStack() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen
        name="Login"
        component={() => (
          <View style={{flex: 1, justifyContent: 'center', alignItems: 'center'}}>
            <Text>Login Screen (Tasks 15-16)</Text>
            <Text>To be implemented with React Native components</Text>
          </View>
        )}
      />
    </Stack.Navigator>
  );
}

function AppStack() {
  return (
    <Tab.Navigator
      screenOptions={{
        tabBarActiveTintColor: '#6366f1',
        tabBarInactiveTintColor: '#9ca3af'
      }}
    >
      <Tab.Screen
        name="Home"
        component={() => (
          <View style={{flex: 1, justifyContent: 'center', alignItems: 'center'}}>
            <Text>Home Screen (Task 15)</Text>
            <Text>Display jokes and manage favorites</Text>
          </View>
        )}
        options={{ title: 'Jokes' }}
      />
      <Tab.Screen
        name="Chat"
        component={() => (
          <View style={{flex: 1, justifyContent: 'center', alignItems: 'center'}}>
            <Text>Chat Screen (Task 16)</Text>
            <Text>Conversational interface</Text>
          </View>
        )}
        options={{ title: 'Chat' }}
      />
      <Tab.Screen
        name="Favorites"
        component={() => (
          <View style={{flex: 1, justifyContent: 'center', alignItems: 'center'}}>
            <Text>Favorites Screen (Task 16)</Text>
            <Text>View saved jokes</Text>
          </View>
        )}
        options={{ title: 'Saved' }}
      />
    </Tab.Navigator>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <NavigationContainer>
        <AuthStack />
      </NavigationContainer>
    </AuthProvider>
  );
}

import { View, Text } from 'react-native';
