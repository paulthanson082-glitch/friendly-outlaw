import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useLocalization } from '../localization/LocalizationContext';

interface StatCard {
  label: string;
  value: string | number;
  icon: string;
  color: string;
}

export default function InsightsScreen() {
  const { t } = useLocalization();
  const [timeframe, setTimeframe] = useState<'week' | 'month' | 'all'>('month');

  const stats: StatCard[] = [
    {
      label: t('insights.totalWords'),
      value: '12,450',
      icon: '📝',
      color: '#007bff',
    },
    {
      label: t('insights.totalSessions'),
      value: '28',
      icon: '⏱️',
      color: '#28a745',
    },
    {
      label: t('insights.averageSession'),
      value: '32m',
      icon: '⏲️',
      color: '#fd7e14',
    },
    {
      label: t('insights.writingStreak'),
      value: '7 ' + t('insights.days'),
      icon: '🔥',
      color: '#dc3545',
    },
  ];

  const chartData = [
    { day: 'Mon', words: 450 },
    { day: 'Tue', words: 680 },
    { day: 'Wed', words: 520 },
    { day: 'Thu', words: 890 },
    { day: 'Fri', words: 750 },
    { day: 'Sat', words: 300 },
    { day: 'Sun', words: 860 },
  ];

  const maxWords = Math.max(...chartData.map((d) => d.words));
  const chartHeight = 200;

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Timeframe Selector */}
        <View style={styles.timeframeSection}>
          <TouchableOpacity
            style={[
              styles.timeframeBtn,
              timeframe === 'week' && styles.timeframeBtnActive,
            ]}
            onPress={() => setTimeframe('week')}
          >
            <Text
              style={[
                styles.timeframeBtnText,
                timeframe === 'week' && styles.timeframeBtnTextActive,
              ]}
            >
              Week
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              styles.timeframeBtn,
              timeframe === 'month' && styles.timeframeBtnActive,
            ]}
            onPress={() => setTimeframe('month')}
          >
            <Text
              style={[
                styles.timeframeBtnText,
                timeframe === 'month' && styles.timeframeBtnTextActive,
              ]}
            >
              Month
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              styles.timeframeBtn,
              timeframe === 'all' && styles.timeframeBtnActive,
            ]}
            onPress={() => setTimeframe('all')}
          >
            <Text
              style={[
                styles.timeframeBtnText,
                timeframe === 'all' && styles.timeframeBtnTextActive,
              ]}
            >
              All Time
            </Text>
          </TouchableOpacity>
        </View>

        {/* Stats Grid */}
        <View style={styles.statsGrid}>
          {stats.map((stat, index) => (
            <LinearGradient
              key={index}
              colors={[stat.color + '20', stat.color + '05']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={styles.statCard}
            >
              <Text style={styles.statIcon}>{stat.icon}</Text>
              <Text style={styles.statValue}>{stat.value}</Text>
              <Text style={styles.statLabel}>{stat.label}</Text>
            </LinearGradient>
          ))}
        </View>

        {/* Chart Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Weekly Writing Activity</Text>
          <View style={styles.chart}>
            <View style={styles.chartBars}>
              {chartData.map((data, index) => {
                const barHeight = (data.words / maxWords) * chartHeight;
                return (
                  <View key={index} style={styles.barContainer}>
                    <View
                      style={[
                        styles.bar,
                        {
                          height: barHeight,
                          backgroundColor:
                            barHeight > 600
                              ? '#28a745'
                              : barHeight > 400
                              ? '#007bff'
                              : '#ffc107',
                        },
                      ]}
                    />
                    <Text style={styles.barLabel}>{data.day}</Text>
                    <Text style={styles.barValue}>{data.words}</Text>
                  </View>
                );
              })}
            </View>
          </View>
        </View>

        {/* Most Productive Day */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('insights.mostProductiveDay')}</Text>
          <View style={styles.productiveCard}>
            <View style={styles.productiveIcon}>
              <Text style={styles.productiveIconText}>🏆</Text>
            </View>
            <View style={styles.productiveInfo}>
              <Text style={styles.productiveDay}>Thursday</Text>
              <Text style={styles.productiveWords}>890 words</Text>
              <Text style={styles.productivePercent}>8% above average</Text>
            </View>
          </View>
        </View>

        {/* Goals Progress */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Monthly Goals</Text>
          <ProgressItem label="20,000 words goal" current={12450} target={20000} />
          <ProgressItem label="30 sessions goal" current={28} target={30} />
        </View>

        {/* Achievements */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Achievements</Text>
          <View style={styles.achievementsGrid}>
            <AchievementBadge icon="🎯" label="Goal Setter" achieved={true} />
            <AchievementBadge icon="🔥" label="7-Day Streak" achieved={true} />
            <AchievementBadge icon="📚" label="50K Words" achieved={false} />
            <AchievementBadge icon="⭐" label="Pro Writer" achieved={false} />
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function ProgressItem({
  label,
  current,
  target,
}: {
  label: string;
  current: number;
  target: number;
}) {
  const percentage = Math.min((current / target) * 100, 100);

  return (
    <View style={styles.progressItem}>
      <View style={styles.progressHeader}>
        <Text style={styles.progressLabel}>{label}</Text>
        <Text style={styles.progressValue}>
          {current} / {target}
        </Text>
      </View>
      <View style={styles.progressBar}>
        <View
          style={[
            styles.progressFill,
            { width: `${percentage}%` },
          ]}
        />
      </View>
      <Text style={styles.progressPercent}>{Math.round(percentage)}% complete</Text>
    </View>
  );
}

function AchievementBadge({
  icon,
  label,
  achieved,
}: {
  icon: string;
  label: string;
  achieved: boolean;
}) {
  return (
    <View
      style={[
        styles.achievementBadge,
        !achieved && styles.achievementBadgeInactive,
      ]}
    >
      <Text
        style={[
          styles.achievementIcon,
          !achieved && styles.achievementIconInactive,
        ]}
      >
        {icon}
      </Text>
      <Text
        style={[
          styles.achievementLabel,
          !achieved && styles.achievementLabelInactive,
        ]}
      >
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f9f9f9',
  },
  timeframeSection: {
    flexDirection: 'row',
    gap: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  timeframeBtn: {
    flex: 1,
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#ddd',
    alignItems: 'center',
    backgroundColor: '#f9f9f9',
  },
  timeframeBtnActive: {
    borderColor: '#007bff',
    backgroundColor: '#007bff',
  },
  timeframeBtnText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#666',
  },
  timeframeBtnTextActive: {
    color: '#fff',
  },
  statsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    paddingHorizontal: 8,
    paddingVertical: 12,
  },
  statCard: {
    width: '48%',
    paddingVertical: 16,
    paddingHorizontal: 12,
    borderRadius: 12,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#e0e0e0',
  },
  statIcon: {
    fontSize: 28,
    marginBottom: 8,
  },
  statValue: {
    fontSize: 18,
    fontWeight: '700',
    color: '#333',
  },
  statLabel: {
    fontSize: 11,
    color: '#666',
    marginTop: 4,
    textAlign: 'center',
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
    color: '#333',
    marginBottom: 12,
  },
  chart: {
    height: 280,
    justifyContent: 'flex-end',
  },
  chartBars: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'flex-end',
    height: 240,
  },
  barContainer: {
    alignItems: 'center',
    gap: 4,
  },
  bar: {
    width: 28,
    borderRadius: 4,
    minHeight: 4,
  },
  barLabel: {
    fontSize: 11,
    color: '#666',
    fontWeight: '600',
  },
  barValue: {
    fontSize: 9,
    color: '#999',
  },
  productiveCard: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 12,
    backgroundColor: '#fff8e1',
    borderRadius: 8,
    borderLeftWidth: 4,
    borderLeftColor: '#ffc107',
  },
  productiveIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: '#ffc107',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  productiveIconText: {
    fontSize: 24,
  },
  productiveInfo: {
    flex: 1,
  },
  productiveDay: {
    fontSize: 14,
    fontWeight: '700',
    color: '#333',
  },
  productiveWords: {
    fontSize: 12,
    color: '#666',
    marginTop: 2,
  },
  productivePercent: {
    fontSize: 11,
    color: '#999',
    marginTop: 2,
  },
  progressItem: {
    marginBottom: 12,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  progressHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  progressLabel: {
    fontSize: 12,
    color: '#666',
    fontWeight: '500',
  },
  progressValue: {
    fontSize: 12,
    color: '#999',
  },
  progressBar: {
    height: 8,
    backgroundColor: '#e0e0e0',
    borderRadius: 4,
    overflow: 'hidden',
    marginBottom: 6,
  },
  progressFill: {
    height: '100%',
    backgroundColor: '#007bff',
  },
  progressPercent: {
    fontSize: 11,
    color: '#999',
  },
  achievementsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  achievementBadge: {
    width: '48%',
    paddingVertical: 12,
    paddingHorizontal: 8,
    backgroundColor: '#e7f3ff',
    borderRadius: 8,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#bce0ff',
  },
  achievementBadgeInactive: {
    backgroundColor: '#f0f0f0',
    borderColor: '#ddd',
  },
  achievementIcon: {
    fontSize: 24,
    marginBottom: 4,
  },
  achievementIconInactive: {
    opacity: 0.4,
  },
  achievementLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: '#0056b3',
    textAlign: 'center',
  },
  achievementLabelInactive: {
    color: '#999',
  },
});
