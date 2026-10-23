import React, { createContext, useContext, useEffect, useState } from 'react';
import { translations } from './translations';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Localization from 'expo-localization';

type LanguageCode = 'en' | 'pt' | 'pl';

interface LocalizationContextType {
  language: LanguageCode;
  setLanguage: (lang: LanguageCode) => Promise<void>;
  t: (key: string, defaultValue?: string) => string;
}

const LocalizationContext = createContext<LocalizationContextType | undefined>(
  undefined
);

const getNestedValue = (obj: any, path: string, defaultValue: string = ''): string => {
  const keys = path.split('.');
  let value = obj;
  for (const key of keys) {
    value = value?.[key];
    if (value === undefined) return defaultValue || path;
  }
  return value || defaultValue || path;
};

export const LocalizationProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [language, setLanguageState] = useState<LanguageCode>('en');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadLanguage = async () => {
      try {
        const savedLanguage = await AsyncStorage.getItem('language');
        if (savedLanguage) {
          setLanguageState(savedLanguage as LanguageCode);
        } else {
          const locales = Localization.getLocales();
          const deviceLanguage = locales?.[0]?.languageCode;
          if (deviceLanguage === 'pt') {
            setLanguageState('pt');
          } else if (deviceLanguage === 'pl') {
            setLanguageState('pl');
          } else {
            setLanguageState('en');
          }
        }
      } catch (error) {
        console.error('Failed to load language:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadLanguage();
  }, []);

  const setLanguage = async (lang: LanguageCode) => {
    try {
      await AsyncStorage.setItem('language', lang);
      setLanguageState(lang);
    } catch (error) {
      console.error('Failed to save language:', error);
    }
  };

  const t = (key: string, defaultValue?: string): string => {
    return getNestedValue(
      translations[language],
      key,
      defaultValue || key
    );
  };

  if (isLoading) {
    return null;
  }

  return (
    <LocalizationContext.Provider value={{ language, setLanguage, t }}>
      {children}
    </LocalizationContext.Provider>
  );
};

export const useLocalization = (): LocalizationContextType => {
  const context = useContext(LocalizationContext);
  if (context === undefined) {
    throw new Error(
      'useLocalization must be used within a LocalizationProvider'
    );
  }
  return context;
};
