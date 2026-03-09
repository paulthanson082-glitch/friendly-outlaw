import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ActivityIndicator,
  Alert,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useAPI } from '../context/APIContext';

export default function DocumentDetailScreen({ route, navigation }: any) {
  const { id } = route.params;
  const { client } = useAPI();
  const [document, setDocument] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [content, setContent] = useState('');

  useEffect(() => {
    loadDocument();
  }, [id]);

  const loadDocument = async () => {
    try {
      setIsLoading(true);
      const response = await client.get(`/documents/${id}`);
      setDocument(response.data);
      setContent(response.data.content || '');
    } catch (error) {
      Alert.alert('Error', 'Failed to load document');
      navigation.goBack();
    } finally {
      setIsLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      setIsSaving(true);
      await client.put(`/documents/${id}`, { content });
      Alert.alert('Success', 'Document saved');
    } catch (error) {
      Alert.alert('Error', 'Failed to save document');
    } finally {
      setIsSaving(false);
    }
  };

  if (isLoading) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color="#007bff" />
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardAvoid}
      >
        <ScrollView style={styles.scrollView} keyboardDismissMode="interactive">
          {document && (
            <>
              <View style={styles.header}>
                <Text style={styles.title}>{document.title}</Text>
                <Text style={styles.meta}>
                  {document.wordCount} words • {new Date(document.createdAt).toLocaleDateString()}
                </Text>
              </View>

              <View style={styles.toolbar}>
                <TouchableOpacity style={styles.toolBtn}>
                  <Text style={styles.toolBtnText}>✨ AI</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.toolBtn}>
                  <Text style={styles.toolBtnText}>📤 Export</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.toolBtn, styles.toolBtnPrimary]}
                  onPress={handleSave}
                  disabled={isSaving}
                >
                  <Text style={styles.toolBtnTextPrimary}>
                    {isSaving ? 'Saving...' : 'Save'}
                  </Text>
                </TouchableOpacity>
              </View>

              <TextInput
                style={styles.contentInput}
                multiline
                scrollEnabled={false}
                placeholder="Start writing..."
                placeholderTextColor="#bbb"
                value={content}
                onChangeText={setContent}
              />
            </>
          )}
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  centerContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  keyboardAvoid: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  header: {
    paddingHorizontal: 16,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  title: {
    fontSize: 22,
    fontWeight: '700',
    color: '#333',
    marginBottom: 4,
  },
  meta: {
    fontSize: 12,
    color: '#999',
  },
  toolbar: {
    flexDirection: 'row',
    paddingHorizontal: 12,
    paddingVertical: 12,
    gap: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  toolBtn: {
    flex: 1,
    paddingVertical: 10,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#ddd',
    alignItems: 'center',
  },
  toolBtnText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#666',
  },
  toolBtnPrimary: {
    backgroundColor: '#007bff',
    borderColor: '#007bff',
  },
  toolBtnTextPrimary: {
    color: '#fff',
  },
  contentInput: {
    flex: 1,
    paddingHorizontal: 16,
    paddingVertical: 16,
    fontSize: 16,
    lineHeight: 24,
    color: '#333',
    textAlignVertical: 'top',
  },
});
