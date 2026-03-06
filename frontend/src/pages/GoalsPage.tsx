import React, { useState, useEffect } from 'react';
import { apiClient } from '../services/api';
import styles from './GoalsPage.module.css';

export const GoalsPage: React.FC = () => {
  const [goals, setGoals] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({ title: '', goalType: 'daily', unit: 'words', targetValue: 1000 });

  useEffect(() => {
    loadGoals();
  }, []);

  const loadGoals = async () => {
    try {
      setIsLoading(true);
      const data = await apiClient.getGoals();
      setGoals(data);
    } catch (error) {
      console.error('Failed to load goals:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateGoal = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiClient.createGoal(formData.title, formData.goalType, formData.unit, formData.targetValue);
      setFormData({ title: '', goalType: 'daily', unit: 'words', targetValue: 1000 });
      setShowForm(false);
      loadGoals();
    } catch (error) {
      console.error('Failed to create goal:', error);
    }
  };

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <h1>🎯 Writing Goals</h1>
        <button onClick={() => setShowForm(!showForm)} className={styles.btn}>
          {showForm ? 'Cancel' : '+ New Goal'}
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleCreateGoal} className={styles.form}>
          <input
            type="text"
            placeholder="Goal title"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            className={styles.input}
            required
          />
          <select value={formData.goalType} onChange={(e) => setFormData({ ...formData, goalType: e.target.value })} className={styles.input}>
            <option value="daily">Daily</option>
            <option value="weekly">Weekly</option>
            <option value="monthly">Monthly</option>
            <option value="project">Project</option>
          </select>
          <select value={formData.unit} onChange={(e) => setFormData({ ...formData, unit: e.target.value })} className={styles.input}>
            <option value="words">Words</option>
            <option value="pages">Pages</option>
            <option value="minutes">Minutes</option>
          </select>
          <input
            type="number"
            placeholder="Target value"
            value={formData.targetValue}
            onChange={(e) => setFormData({ ...formData, targetValue: parseInt(e.target.value) })}
            className={styles.input}
            required
          />
          <button type="submit" className={styles.btn}>
            Create Goal
          </button>
        </form>
      )}

      {isLoading ? (
        <p>Loading goals...</p>
      ) : goals.length === 0 ? (
        <p>No goals yet. Create one to get started!</p>
      ) : (
        <div className={styles.goalsList}>
          {goals.map((goal) => {
            const progress = (goal.currentValue / goal.targetValue) * 100;
            return (
              <div key={goal.id} className={styles.goalCard}>
                <h3>{goal.title}</h3>
                <p className={styles.meta}>
                  {goal.goalType} • {goal.currentValue} / {goal.targetValue} {goal.unit}
                </p>
                <div className={styles.progressBar}>
                  <div className={styles.progress} style={{ width: `${Math.min(100, progress)}%` }}></div>
                </div>
                <p className={styles.percentage}>{Math.round(progress)}% complete</p>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
