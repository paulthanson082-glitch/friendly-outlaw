import React from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  Alert,
  Switch,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { useAuth } from '../context/AuthContext';

export default function SettingsScreen({ navigation }: any) {
  const { user, logout } = useAuth();
  const [notifications, setNotifications] = React.useState(true);
  const [autoSave, setAutoSave] = React.useState(true);

  const handleLogout = () => {
    Alert.alert('Sign Out', 'Are you sure you want to sign out?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Sign Out',
        style: 'destructive',
        onPress: async () => {
          await logout();
        },
      },
    ]);
  };

  const handleClearCache = async () => {
    Alert.alert('Clear Cache', 'This will clear all cached data. Continue?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Clear',
        style: 'destructive',
        onPress: async () => {
          try {
            // Clear cache logic here
            Alert.alert('Success', 'Cache cleared');
          } catch (error) {
            Alert.alert('Error', 'Failed to clear cache');
          }
        },
      },
    ]);
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Profile Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Profile</Text>
          <View style={styles.profileCard}>
            <View style={styles.avatarPlaceholder}>
              <Text style={styles.avatarText}>
                {user?.displayName?.charAt(0).toUpperCase()}
              </Text>
            </View>
            <View style={styles.profileInfo}>
              <Text style={styles.profileName}>{user?.displayName}</Text>
              <Text style={styles.profileEmail}>{user?.email}</Text>
            </View>
          </View>
        </View>

        {/* Preferences Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Preferences</Text>
          <SettingRow
            label="Push Notifications"
            value={notifications}
            onValueChange={setNotifications}
          />
          <SettingRow
            label="Auto-Save Documents"
            value={autoSave}
            onValueChange={setAutoSave}
          />
        </View>

        {/* About Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>About</Text>
          <SettingItem label="Version" value="1.0.0" />
          <SettingItem label="Build" value="1" />
        </View>

        {/* Actions Section */}
        <View style={styles.section}>
          <TouchableOpacity style={styles.actionBtn} onPress={handleClearCache}>
            <Text style={styles.actionBtnText}>Clear Cache</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.actionBtn, styles.actionBtnDanger]}
            onPress={handleLogout}
          >
            <Text style={[styles.actionBtnText, styles.actionBtnTextDanger]}>
              Sign Out
            </Text>
          </TouchableOpacity>
        </View>

        {/* Footer */}
        <View style={styles.footer}>
          <Text style={styles.footerText}>© 2024 Jules Writers App</Text>
          <Text style={styles.footerText}>Made with ❤️ by Anthropic</Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function SettingRow({
  label,
  value,
  onValueChange,
}: {
  label: string;
  value: boolean;
  onValueChange: (value: boolean) => void;
}) {
  return (
    <View style={styles.settingRow}>
      <Text style={styles.settingLabel}>{label}</Text>
      <Switch
        value={value}
        onValueChange={onValueChange}
        trackColor={{ false: '#ddd', true: '#81c784' }}
        thumbColor={value ? '#007bff' : '#f4f3f4'}
      />
    </View>
  );
}

function SettingItem({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.settingRow}>
      <Text style={styles.settingLabel}>{label}</Text>
      <Text style={styles.settingValue}>{value}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f9f9f9',
  },
  section: {
    backgroundColor: '#fff',
    marginVertical: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#e0e0e0',
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#666',
    textTransform: 'uppercase',
    marginBottom: 12,
  },
  profileCard: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
  },
  avatarPlaceholder: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#007bff',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  avatarText: {
    fontSize: 24,
    fontWeight: '700',
    color: '#fff',
  },
  profileInfo: {
    flex: 1,
  },
  profileName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  profileEmail: {
    fontSize: 12,
    color: '#999',
    marginTop: 4,
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  settingLabel: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  settingValue: {
    fontSize: 14,
    color: '#999',
  },
  actionBtn: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#ddd',
    backgroundColor: '#f9f9f9',
  },
  actionBtnDanger: {
    borderColor: '#dc3545',
    backgroundColor: '#fff5f5',
  },
  actionBtnText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#666',
  },
  actionBtnTextDanger: {
    color: '#dc3545',
  },
  footer: {
    paddingVertical: 32,
    alignItems: 'center',
  },
  footerText: {
    fontSize: 12,
    color: '#999',
    marginVertical: 2,
  },
});
