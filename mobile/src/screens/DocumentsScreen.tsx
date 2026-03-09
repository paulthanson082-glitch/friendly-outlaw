import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  TextInput,
  Alert,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useAPI } from '../context/APIContext';

export default function DocumentsScreen({ navigation }: any) {
  const { client } = useAPI();
  const [documents, setDocuments] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [refreshing, setRefreshing] = useState(false);

  const loadDocuments = async () => {
    try {
      setIsLoading(true);
      const response = await client.get('/documents');
      setDocuments(response.data.documents || []);
    } catch (error) {
      Alert.alert('Error', 'Failed to load documents');
      console.error(error);
    } finally {
      setIsLoading(false);
    }
  };

  useFocusEffect(
    useCallback(() => {
      loadDocuments();
    }, [])
  );

  const handleSearch = async () => {
    if (!searchQuery.trim()) {
      loadDocuments();
      return;
    }
    try {
      const response = await client.get('/documents/search', {
        params: { q: searchQuery },
      });
      setDocuments(response.data);
    } catch (error) {
      Alert.alert('Error', 'Search failed');
    }
  };

  const handleCreateDocument = async () => {
    Alert.prompt(
      'New Document',
      'Enter document title:',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Create',
          onPress: async (title) => {
            if (!title) return;
            try {
              await client.post('/documents', { title });
              loadDocuments();
            } catch (error) {
              Alert.alert('Error', 'Failed to create document');
            }
          },
        },
      ]
    );
  };

  const handleDeleteDocument = (id: string) => {
    Alert.alert('Delete Document', 'Are you sure?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          try {
            await client.delete(`/documents/${id}`);
            loadDocuments();
          } catch (error) {
            Alert.alert('Error', 'Failed to delete document');
          }
        },
      },
    ]);
  };

  const onRefresh = async () => {
    setRefreshing(true);
    await loadDocuments();
    setRefreshing(false);
  };

  if (isLoading && !refreshing) {
    return (
      <View style={styles.centerContainer}>
        <ActivityIndicator size="large" color="#007bff" />
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TextInput
          style={styles.searchInput}
          placeholder="Search documents..."
          value={searchQuery}
          onChangeText={setSearchQuery}
          onSubmitEditing={handleSearch}
        />
        <TouchableOpacity style={styles.createBtn} onPress={handleCreateDocument}>
          <Text style={styles.createBtnText}>+</Text>
        </TouchableOpacity>
      </View>

      <FlatList
        data={documents}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.documentCard}
            onPress={() => navigation.navigate('DocumentDetail', { id: item.id })}
          >
            <View style={styles.docInfo}>
              <Text style={styles.docTitle} numberOfLines={2}>
                {item.title}
              </Text>
              <Text style={styles.docMeta}>
                {item.wordCount} words • {new Date(item.createdAt).toLocaleDateString()}
              </Text>
            </View>
            <TouchableOpacity
              style={styles.deleteBtn}
              onPress={() => handleDeleteDocument(item.id)}
            >
              <Text style={styles.deleteBtnText}>✕</Text>
            </TouchableOpacity>
          </TouchableOpacity>
        )}
        ListEmptyComponent={
          <View style={styles.emptyState}>
            <Text style={styles.emptyTitle}>No Documents</Text>
            <Text style={styles.emptyText}>
              Tap + to create your first document
            </Text>
          </View>
        }
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} />
        }
      />
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
  header: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 12,
    gap: 8,
  },
  searchInput: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
  },
  createBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#007bff',
    justifyContent: 'center',
    alignItems: 'center',
  },
  createBtnText: {
    fontSize: 24,
    color: '#fff',
    fontWeight: '600',
  },
  documentCard: {
    flexDirection: 'row',
    marginHorizontal: 16,
    marginVertical: 8,
    paddingHorizontal: 12,
    paddingVertical: 12,
    backgroundColor: '#f9f9f9',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#e0e0e0',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  docInfo: {
    flex: 1,
  },
  docTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 4,
  },
  docMeta: {
    fontSize: 12,
    color: '#999',
  },
  deleteBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#ffebee',
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 8,
  },
  deleteBtnText: {
    color: '#dc3545',
    fontSize: 16,
    fontWeight: '600',
  },
  emptyState: {
    paddingVertical: 60,
    alignItems: 'center',
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  emptyText: {
    fontSize: 14,
    color: '#999',
  },
});
