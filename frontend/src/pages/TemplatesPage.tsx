import React, { useState, useEffect } from 'react';
import { apiClient } from '../services/api';
import styles from './TemplatesPage.module.css';

export const TemplatesPage: React.FC = () => {
  const [templates, setTemplates] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string | undefined>();

  useEffect(() => {
    loadTemplates();
  }, []);

  const loadTemplates = async () => {
    try {
      setIsLoading(true);
      const data = await apiClient.getTemplates(selectedCategory);
      setTemplates(data);
    } catch (error) {
      console.error('Failed to load templates:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadTemplates();
  }, [selectedCategory]);

  const categories = ['novel', 'shortStory', 'blogPost', 'essay', 'screenplay', 'article', 'poetry'];

  return (
    <div className={styles.container}>
      <h1>📚 Templates</h1>

      <div className={styles.filters}>
        <button
          onClick={() => setSelectedCategory(undefined)}
          className={`${styles.filterBtn} ${!selectedCategory ? styles.active : ''}`}
        >
          All
        </button>
        {categories.map((cat) => (
          <button
            key={cat}
            onClick={() => setSelectedCategory(cat)}
            className={`${styles.filterBtn} ${selectedCategory === cat ? styles.active : ''}`}
          >
            {cat}
          </button>
        ))}
      </div>

      {isLoading ? (
        <div className={styles.loading}>Loading templates...</div>
      ) : (
        <div className={styles.templateGrid}>
          {templates.map((template) => (
            <div key={template.id} className={styles.templateCard}>
              <h3>{template.name}</h3>
              <p className={styles.category}>{template.category}</p>
              <p className={styles.description}>{template.description}</p>
              <div className={styles.placeholders}>
                <strong>Placeholders:</strong> {template.placeholders?.length || 0}
              </div>
              <button className={styles.useBtn}>Use Template</button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
