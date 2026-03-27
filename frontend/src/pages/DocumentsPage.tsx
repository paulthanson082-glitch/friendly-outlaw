import React, { useState, useEffect } from 'react';
import { apiClient } from '../services/api';
import styles from './DocumentsPage.module.css';

export const DocumentsPage: React.FC = () => {
  const [documents, setDocuments] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newDocTitle, setNewDocTitle] = useState('');

  useEffect(() => {
    loadDocuments();
  }, []);

  const loadDocuments = async () => {
    try {
      setIsLoading(true);
      const data = await apiClient.getDocuments();
      setDocuments(data.documents || []);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err : new Error(String(err)));
    } finally {
      setIsLoading(false);
    }
  };

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchQuery.trim()) {
      loadDocuments();
      return;
    }

    try {
      setIsLoading(true);
      const results = await apiClient.searchDocuments(searchQuery);
      setDocuments(results);
    } catch (err) {
      setError(err instanceof Error ? err : new Error(String(err)));
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newDocTitle.trim()) return;

    try {
      await apiClient.createDocument(newDocTitle);
      setNewDocTitle('');
      setShowCreateForm(false);
      loadDocuments();
    } catch (err) {
      setError(err instanceof Error ? err : new Error(String(err)));
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this document?')) return;

    try {
      await apiClient.deleteDocument(id);
      loadDocuments();
    } catch (err) {
      setError(err instanceof Error ? err : new Error(String(err)));
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <h1>📄 Documents</h1>
        <button onClick={() => setShowCreateForm(!showCreateForm)} className={styles.primaryBtn}>
          {showCreateForm ? 'Cancel' : '+ New Document'}
        </button>
      </div>

      {showCreateForm && (
        <form onSubmit={handleCreate} className={styles.createForm}>
          <input
            type="text"
            value={newDocTitle}
            onChange={(e) => setNewDocTitle(e.target.value)}
            placeholder="Document title..."
            className={styles.input}
          />
          <button type="submit" className={styles.primaryBtn}>
            Create
          </button>
        </form>
      )}

      <form onSubmit={handleSearch} className={styles.searchForm}>
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search documents..."
          className={styles.input}
        />
        <button type="submit" className={styles.secondaryBtn}>
          Search
        </button>
      </form>

      {error && <div className={styles.error}>{error.message}</div>}

      {isLoading ? (
        <div className={styles.loading}>Loading documents...</div>
      ) : documents.length === 0 ? (
        <div className={styles.empty}>No documents found. Create one to get started!</div>
      ) : (
        <div className={styles.documentList}>
          {documents.map((doc) => (
            <div key={doc.id} className={styles.documentCard}>
              <div className={styles.docInfo}>
                <h3>{doc.title}</h3>
                <p className={styles.metadata}>
                  {doc.wordCount} words • {new Date(doc.createdAt).toLocaleDateString()}
                </p>
              </div>
              <div className={styles.docActions}>
                <button className={styles.linkBtn}>Edit</button>
                <button
                  onClick={() => handleDelete(doc.id)}
                  className={`${styles.linkBtn} ${styles.danger}`}
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
