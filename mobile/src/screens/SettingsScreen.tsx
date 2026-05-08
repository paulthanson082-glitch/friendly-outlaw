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
import { useLocalization } from '../localization/LocalizationContext';

export default function SettingsScreen({ navigation }: any) {
  const { user, logout } = useAuth();
  const { language, setLanguage, t } = useLocalization();
  const [notifications, setNotifications] = React.useState(true);
  const [pushNotifications, setPushNotifications] = React.useState(true);
  const [autoSave, setAutoSave] = React.useState(true);
  const [theme, setTheme] = React.useState<'light' | 'dark' | 'auto'>('auto');

  const handleLogout = () => {
    Alert.alert(t('common.profile'), t('auth.confirmSignOut'), [
      { text: t('common.cancel'), style: 'cancel' },
      {
        text: t('auth.signOut'),
        style: 'destructive',
        onPress: async () => {
          await logout();
        },
      },
    ]);
  };

  const handleClearCache = async () => {
    Alert.alert(t('settings.clearCache'), t('settings.clearCacheConfirm'), [
      { text: t('common.cancel'), style: 'cancel' },
      {
        text: t('common.delete'),
        style: 'destructive',
        onPress: async () => {
          try {
            // Clear cache logic here
            Alert.alert(t('common.success'), t('settings.cacheClear'));
          } catch (error) {
            Alert.alert(t('common.error'), 'Failed to clear cache');
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
          <Text style={styles.sectionTitle}>{t('common.profile')}</Text>
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
          <Text style={styles.sectionTitle}>{t('settings.preferences')}</Text>
          <LanguageSelector
            currentLanguage={language}
            onLanguageChange={setLanguage}
            t={t}
          />
          <ThemeSelector currentTheme={theme} onThemeChange={setTheme} t={t} />
          <SettingRow
            label={t('settings.pushNotifications')}
            value={pushNotifications}
            onValueChange={setPushNotifications}
          />
          <SettingRow
            label={t('settings.autoSave')}
            value={autoSave}
            onValueChange={setAutoSave}
          />
        </View>

        {/* About Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('settings.about')}</Text>
          <SettingItem label={t('settings.version')} value="1.0.0" />
          <SettingItem label={t('settings.build')} value="1" />
        </View>

        {/* Actions Section */}
        <View style={styles.section}>
          <TouchableOpacity style={styles.actionBtn} onPress={handleClearCache}>
            <Text style={styles.actionBtnText}>{t('settings.clearCache')}</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.actionBtn, styles.actionBtnDanger]}
            onPress={handleLogout}
          >
            <Text style={[styles.actionBtnText, styles.actionBtnTextDanger]}>
              {t('auth.signOut')}
            </Text>
          </TouchableOpacity>
        </View>

        {/* Footer */}
        <View style={styles.footer}>
          <Text style={styles.footerText}>{t('settings.copyright')}</Text>
          <Text style={styles.footerText}>{t('settings.made')}</Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function LanguageSelector({
  currentLanguage,
  onLanguageChange,
  t,
}: {
  currentLanguage: string;
  onLanguageChange: (lang: 'en' | 'pt' | 'pl') => void;
  t: (key: string) => string;
}) {
  return (
    <View>
      <Text style={styles.settingLabel}>{t('settings.language')}</Text>
      <View style={styles.languageGrid}>
        <TouchableOpacity
          style={[
            styles.languageBtn,
            currentLanguage === 'en' && styles.languageBtnActive,
          ]}
          onPress={() => onLanguageChange('en')}
        >
          <Text
            style={[
              styles.languageBtnText,
              currentLanguage === 'en' && styles.languageBtnTextActive,
            ]}
          >
            🇬🇧 English
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[
            styles.languageBtn,
            currentLanguage === 'pt' && styles.languageBtnActive,
          ]}
          onPress={() => onLanguageChange('pt')}
        >
          <Text
            style={[
              styles.languageBtnText,
              currentLanguage === 'pt' && styles.languageBtnTextActive,
            ]}
          >
            🇧🇷 Português
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[
            styles.languageBtn,
            currentLanguage === 'pl' && styles.languageBtnActive,
          ]}
          onPress={() => onLanguageChange('pl')}
        >
          <Text
            style={[
              styles.languageBtnText,
              currentLanguage === 'pl' && styles.languageBtnTextActive,
            ]}
          >
            🇵🇱 Polski
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

function ThemeSelector({
  currentTheme,
  onThemeChange,
  t,
}: {
  currentTheme: string;
  onThemeChange: (theme: 'light' | 'dark' | 'auto') => void;
  t: (key: string) => string;
}) {
  return (
    <View style={styles.themeSection}>
      <Text style={styles.settingLabel}>{t('settings.theme')}</Text>
      <View style={styles.themeGrid}>
        <TouchableOpacity
          style={[
            styles.themeBtn,
            currentTheme === 'light' && styles.themeBtnActive,
          ]}
          onPress={() => onThemeChange('light')}
        >
          <Text style={styles.themeBtnIcon}>☀️</Text>
          <Text
            style={[
              styles.themeBtnText,
              currentTheme === 'light' && styles.themeBtnTextActive,
            ]}
          >
            {t('settings.light')}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[
            styles.themeBtn,
            currentTheme === 'dark' && styles.themeBtnActive,
          ]}
          onPress={() => onThemeChange('dark')}
        >
          <Text style={styles.themeBtnIcon}>🌙</Text>
          <Text
            style={[
              styles.themeBtnText,
              currentTheme === 'dark' && styles.themeBtnTextActive,
            ]}
          >
            {t('settings.dark')}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[
            styles.themeBtn,
            currentTheme === 'auto' && styles.themeBtnActive,
          ]}
          onPress={() => onThemeChange('auto')}
        >
          <Text style={styles.themeBtnIcon}>⚙️</Text>
          <Text
            style={[
              styles.themeBtnText,
              currentTheme === 'auto' && styles.themeBtnTextActive,
            ]}
          >
            {t('settings.auto')}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
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
  languageGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 16,
  },
  languageBtn: {
    width: '48%',
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ddd',
    alignItems: 'center',
    backgroundColor: '#f9f9f9',
  },
  languageBtnActive: {
    borderColor: '#007bff',
    backgroundColor: '#e7f3ff',
  },
  languageBtnText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#666',
  },
  languageBtnTextActive: {
    color: '#007bff',
  },
  themeSection: {
    marginBottom: 16,
  },
  themeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginBottom: 16,
  },
  themeBtn: {
    width: '31%',
    paddingVertical: 10,
    paddingHorizontal: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#ddd',
    alignItems: 'center',
    backgroundColor: '#f9f9f9',
  },
  themeBtnActive: {
    borderColor: '#007bff',
    backgroundColor: '#e7f3ff',
  },
  themeBtnIcon: {
    fontSize: 20,
    marginBottom: 4,
  },
  themeBtnText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#666',
  },
  themeBtnTextActive: {
    color: '#007bff',
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
