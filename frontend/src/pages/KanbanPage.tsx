import React, { useState, useEffect } from 'react';
import { apiClient } from '../services/api';
import styles from './KanbanPage.module.css';

const COLUMNS = ['backlog', 'planning', 'running', 'review', 'done'];

export const KanbanPage: React.FC = () => {
  const [boards, setBoards] = useState<any[]>([]);
  const [selectedBoard, setSelectedBoard] = useState<string | null>(null);
  const [boardData, setBoardData] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadBoards();
  }, []);

  const loadBoards = async () => {
    try {
      setIsLoading(true);
      const data = await apiClient.getBoards();
      setBoards(data);
      if (data.length > 0 && !selectedBoard) {
        setSelectedBoard(data[0].id);
      }
    } catch (error) {
      console.error('Failed to load boards:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    if (selectedBoard) {
      loadBoardData();
    }
  }, [selectedBoard]);

  const loadBoardData = async () => {
    if (!selectedBoard) return;
    try {
      const data = await apiClient.getBoard(selectedBoard);
      setBoardData(data);
    } catch (error) {
      console.error('Failed to load board:', error);
    }
  };

  if (isLoading) return <div className={styles.container}><p>Loading...</p></div>;

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <h1>📊 Kanban Board</h1>
        <select value={selectedBoard || ''} onChange={(e) => setSelectedBoard(e.target.value)} className={styles.select}>
          {boards.map((board) => (
            <option key={board.id} value={board.id}>
              {board.name}
            </option>
          ))}
        </select>
      </div>

      {boardData && (
        <div className={styles.board}>
          {COLUMNS.map((column) => {
            const columnTasks = (boardData.tasks || []).filter((t: any) => t.column === column);
            return (
              <div key={column} className={styles.column}>
                <h3 className={styles.columnTitle}>{column}</h3>
                <div className={styles.tasks}>
                  {columnTasks.map((task: any) => (
                    <div key={task.id} className={styles.card}>
                      <p>{task.title}</p>
                      {task.description && <small>{task.description}</small>}
                    </div>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
