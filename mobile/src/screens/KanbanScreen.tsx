import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ActivityIndicator,
} from 'react-native';
import { useAPI } from '../context/APIContext';

const COLUMNS = ['backlog', 'planning', 'running', 'review', 'done'];

export default function KanbanScreen() {
  const { client } = useAPI();
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
      const response = await client.get('/kanban/boards');
      setBoards(response.data);
      if (response.data.length > 0 && !selectedBoard) {
        setSelectedBoard(response.data[0].id);
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
      const response = await client.get(`/kanban/boards/${selectedBoard}`);
      setBoardData(response.data);
    } catch (error) {
      console.error('Failed to load board:', error);
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
      {boards.length > 0 && (
        <View style={styles.boardSelector}>
          <Text style={styles.selectorLabel}>Board:</Text>
          <ScrollView horizontal showsHorizontalScrollIndicator={false}>
            {boards.map((board) => (
              <TouchableOpacity
                key={board.id}
                style={[
                  styles.boardOption,
                  selectedBoard === board.id && styles.boardOptionActive,
                ]}
                onPress={() => setSelectedBoard(board.id)}
              >
                <Text
                  style={[
                    styles.boardOptionText,
                    selectedBoard === board.id && styles.boardOptionTextActive,
                  ]}
                >
                  {board.name}
                </Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      )}

      {boardData && (
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.kanbanBoard}>
          {COLUMNS.map((column) => {
            const columnTasks = (boardData.tasks || []).filter((t: any) => t.column === column);
            return (
              <View key={column} style={styles.kanbanColumn}>
                <Text style={styles.columnTitle}>{column}</Text>
                <Text style={styles.columnCount}>{columnTasks.length}</Text>
                <View style={styles.tasksList}>
                  {columnTasks.map((task: any) => (
                    <View key={task.id} style={styles.taskCard}>
                      <Text style={styles.taskTitle} numberOfLines={2}>
                        {task.title}
                      </Text>
                      {task.description && (
                        <Text style={styles.taskDesc} numberOfLines={2}>
                          {task.description}
                        </Text>
                      )}
                    </View>
                  ))}
                </View>
              </View>
            );
          })}
        </ScrollView>
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
  boardSelector: {
    paddingHorizontal: 12,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  selectorLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: '#666',
    marginBottom: 8,
  },
  boardOption: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    marginRight: 8,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  boardOptionActive: {
    backgroundColor: '#007bff',
    borderColor: '#007bff',
  },
  boardOptionText: {
    fontSize: 12,
    color: '#666',
    fontWeight: '500',
  },
  boardOptionTextActive: {
    color: '#fff',
  },
  kanbanBoard: {
    flex: 1,
    paddingHorizontal: 8,
    paddingVertical: 12,
  },
  kanbanColumn: {
    width: 280,
    marginHorizontal: 4,
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    padding: 12,
  },
  columnTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    textTransform: 'uppercase',
    marginBottom: 4,
  },
  columnCount: {
    fontSize: 12,
    color: '#999',
    marginBottom: 12,
  },
  tasksList: {
    gap: 8,
  },
  taskCard: {
    backgroundColor: '#fff',
    borderRadius: 6,
    padding: 10,
    borderWidth: 1,
    borderColor: '#ddd',
  },
  taskTitle: {
    fontSize: 13,
    fontWeight: '500',
    color: '#333',
    marginBottom: 4,
  },
  taskDesc: {
    fontSize: 11,
    color: '#999',
  },
});
