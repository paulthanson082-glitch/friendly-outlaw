import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import { useAPI } from '../context/APIContext';

export default function TemplatesScreen() {
  const { client } = useAPI();
  const [templates, setTemplates] = useState<any[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string | undefined>();
  const [isLoading, setIsLoading] = useState(true);

  const categories = ['novel', 'shortStory', 'blogPost', 'essay', 'screenplay', 'article'];

  useEffect(() => {
    loadTemplates();
  }, [selectedCategory]);

  const loadTemplates = async () => {
    try {
      setIsLoading(true);
      const params = selectedCategory ? { category: selectedCategory } : {};
      const response = await client.get('/templates', { params });
      setTemplates(response.data);
    } catch (error) {
      console.error('Failed to load templates:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView horizontal style={styles.categoryScroll} showsHorizontalScrollIndicator={false}>
        <TouchableOpacity
          style={[styles.categoryBtn, !selectedCategory && styles.categoryBtnActive]}
          onPress={() => setSelectedCategory(undefined)}
        >
          <Text style={[styles.categoryText, !selectedCategory && styles.categoryTextActive]}>All</Text>
        </TouchableOpacity>
        {categories.map((cat) => (
          <TouchableOpacity
            key={cat}
            style={[styles.categoryBtn, selectedCategory === cat && styles.categoryBtnActive]}
            onPress={() => setSelectedCategory(cat)}
          >
            <Text style={[styles.categoryText, selectedCategory === cat && styles.categoryTextActive]}>
              {cat}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {isLoading ? (
        <View style={styles.centerContainer}>
          <ActivityIndicator size="large" color="#007bff" />
        </View>
      ) : (
        <FlatList
          data={templates}
          keyExtractor={(item) => item.id}
          renderItem={({ item }) => (
            <TouchableOpacity style={styles.templateCard}>
              <Text style={styles.templateName}>{item.name}</Text>
              <Text style={styles.templateCategory}>{item.category}</Text>
              {item.description && (
                <Text style={styles.templateDesc} numberOfLines={2}>
                  {item.description}
                </Text>
              )}
              <View style={styles.templateFooter}>
                <Text style={styles.placeholderCount}>
                  {item.placeholders?.length || 0} placeholders
                </Text>
                <TouchableOpacity style={styles.useBtn}>
                  <Text style={styles.useBtnText}>Use</Text>
                </TouchableOpacity>
              </View>
            </TouchableOpacity>
          )}
          contentContainerStyle={styles.listContent}
        />
      )}
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
  categoryScroll: {
    paddingHorizontal: 12,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  categoryBtn: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    marginHorizontal: 4,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  categoryBtnActive: {
    backgroundColor: '#007bff',
    borderColor: '#007bff',
  },
  categoryText: {
    color: '#666',
    fontSize: 12,
    fontWeight: '600',
  },
  categoryTextActive: {
    color: '#fff',
  },
  listContent: {
    padding: 12,
  },
  templateCard: {
    backgroundColor: '#f9f9f9',
    borderRadius: 8,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  templateName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 4,
  },
  templateCategory: {
    fontSize: 12,
    color: '#999',
    textTransform: 'uppercase',
    marginBottom: 8,
  },
  templateDesc: {
    fontSize: 13,
    color: '#666',
    marginBottom: 12,
    lineHeight: 18,
  },
  templateFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  placeholderCount: {
    fontSize: 12,
    color: '#999',
  },
  useBtn: {
    backgroundColor: '#007bff',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 6,
  },
  useBtnText: {
    color: '#fff',
    fontWeight: '600',
    fontSize: 12,
  },
});
