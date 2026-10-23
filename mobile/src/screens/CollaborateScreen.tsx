import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  SafeAreaView,
  ScrollView,
  TextInput,
  Alert,
  FlatList,
} from 'react-native';
import { useLocalization } from '../localization/LocalizationContext';

interface Collaborator {
  id: string;
  email: string;
  name: string;
  role: 'editor' | 'viewer';
  avatar: string;
}

export default function CollaborateScreen() {
  const { t } = useLocalization();
  const [collaborators, setCollaborators] = useState<Collaborator[]>([
    {
      id: '1',
      email: 'alice@example.com',
      name: 'Alice Johnson',
      role: 'editor',
      avatar: 'A',
    },
  ]);
  const [inviteEmail, setInviteEmail] = useState('');
  const [selectedRole, setSelectedRole] = useState<'editor' | 'viewer'>('editor');

  const handleInvite = () => {
    if (!inviteEmail.trim()) {
      Alert.alert(t('common.error'), 'Please enter an email address');
      return;
    }

    const newCollaborator: Collaborator = {
      id: Date.now().toString(),
      email: inviteEmail,
      name: inviteEmail.split('@')[0],
      role: selectedRole,
      avatar: inviteEmail.charAt(0).toUpperCase(),
    };

    setCollaborators([...collaborators, newCollaborator]);
    setInviteEmail('');
    Alert.alert(t('common.success'), t('collaborate.inviteSent'));
  };

  const handleRemove = (id: string) => {
    Alert.alert(t('common.error'), 'Are you sure?', [
      { text: t('common.cancel'), style: 'cancel' },
      {
        text: t('common.delete'),
        style: 'destructive',
        onPress: () => setCollaborators(collaborators.filter((c) => c.id !== id)),
      },
    ]);
  };

  const renderCollaborator = ({ item }: { item: Collaborator }) => (
    <View style={styles.collaboratorItem}>
      <View style={styles.avatarSmall}>
        <Text style={styles.avatarTextSmall}>{item.avatar}</Text>
      </View>
      <View style={styles.collaboratorInfo}>
        <Text style={styles.collaboratorName}>{item.name}</Text>
        <Text style={styles.collaboratorEmail}>{item.email}</Text>
        <Text style={styles.role}>
          {item.role === 'editor'
            ? t('collaborate.editor')
            : t('collaborate.viewer')}
        </Text>
      </View>
      <TouchableOpacity
        style={styles.removeBtn}
        onPress={() => handleRemove(item.id)}
      >
        <Text style={styles.removeBtnText}>✕</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView showsVerticalScrollIndicator={false}>
        {/* Invite Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('collaborate.inviteUser')}</Text>
          <TextInput
            style={styles.input}
            placeholder={t('collaborate.email')}
            placeholderTextColor="#999"
            value={inviteEmail}
            onChangeText={setInviteEmail}
            keyboardType="email-address"
            autoCapitalize="none"
          />

          <View style={styles.roleSelector}>
            <Text style={styles.roleLabel}>{t('collaborate.role')}</Text>
            <View style={styles.roleButtons}>
              <TouchableOpacity
                style={[
                  styles.roleBtn,
                  selectedRole === 'editor' && styles.roleBtnActive,
                ]}
                onPress={() => setSelectedRole('editor')}
              >
                <Text
                  style={[
                    styles.roleBtnText,
                    selectedRole === 'editor' && styles.roleBtnTextActive,
                  ]}
                >
                  {t('collaborate.editor')}
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.roleBtn,
                  selectedRole === 'viewer' && styles.roleBtnActive,
                ]}
                onPress={() => setSelectedRole('viewer')}
              >
                <Text
                  style={[
                    styles.roleBtnText,
                    selectedRole === 'viewer' && styles.roleBtnTextActive,
                  ]}
                >
                  {t('collaborate.viewer')}
                </Text>
              </TouchableOpacity>
            </View>
          </View>

          <TouchableOpacity
            style={styles.inviteBtn}
            onPress={handleInvite}
          >
            <Text style={styles.inviteBtnText}>{t('collaborate.inviteUser')}</Text>
          </TouchableOpacity>
        </View>

        {/* Collaborators List */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t('collaborate.sharedWith')}</Text>
          {collaborators.length === 0 ? (
            <Text style={styles.emptyText}>{t('collaborate.noCollaborators')}</Text>
          ) : (
            <FlatList
              scrollEnabled={false}
              data={collaborators}
              renderItem={renderCollaborator}
              keyExtractor={(item) => item.id}
            />
          )}
        </View>

        {/* Info */}
        <View style={styles.infoSection}>
          <Text style={styles.infoText}>
            💡 Editors can view and edit documents. Viewers can only view.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f9f9f9',
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
    color: '#666',
    textTransform: 'uppercase',
    marginBottom: 12,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    marginBottom: 12,
    backgroundColor: '#f9f9f9',
  },
  roleSelector: {
    marginBottom: 16,
  },
  roleLabel: {
    fontSize: 12,
    fontWeight: '600',
    color: '#666',
    marginBottom: 8,
  },
  roleButtons: {
    flexDirection: 'row',
    gap: 8,
  },
  roleBtn: {
    flex: 1,
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#ddd',
    alignItems: 'center',
    backgroundColor: '#f9f9f9',
  },
  roleBtnActive: {
    borderColor: '#007bff',
    backgroundColor: '#e7f3ff',
  },
  roleBtnText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#666',
  },
  roleBtnTextActive: {
    color: '#007bff',
  },
  inviteBtn: {
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    backgroundColor: '#007bff',
    alignItems: 'center',
  },
  inviteBtnText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#fff',
  },
  collaboratorItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  avatarSmall: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: '#007bff',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  avatarTextSmall: {
    fontSize: 16,
    fontWeight: '700',
    color: '#fff',
  },
  collaboratorInfo: {
    flex: 1,
  },
  collaboratorName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  collaboratorEmail: {
    fontSize: 12,
    color: '#999',
    marginTop: 2,
  },
  role: {
    fontSize: 11,
    color: '#007bff',
    fontWeight: '500',
    marginTop: 2,
  },
  removeBtn: {
    padding: 8,
  },
  removeBtnText: {
    fontSize: 16,
    color: '#dc3545',
    fontWeight: '700',
  },
  emptyText: {
    fontSize: 14,
    color: '#999',
    textAlign: 'center',
    paddingVertical: 16,
  },
  infoSection: {
    backgroundColor: '#e7f3ff',
    margin: 12,
    paddingHorizontal: 12,
    paddingVertical: 12,
    borderRadius: 8,
    borderLeftWidth: 4,
    borderLeftColor: '#007bff',
  },
  infoText: {
    fontSize: 12,
    color: '#0056b3',
    lineHeight: 18,
  },
});
