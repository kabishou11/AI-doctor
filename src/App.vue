<template>
  <a-layout style="min-height: 100vh">
    <a-layout-header class="app-header">
      <div class="header-inner">
        <div class="app-brand">
          <img :src="logoUrl" alt="AstraCare Logo" class="logo" />
          <div class="brand-text">
            <div class="brand-title">AstraCare</div>
            <div class="brand-subtitle">临床智研台</div>
          </div>
        </div>

        <div class="header-divider"></div>

        <div class="consultation-info" v-if="sessions.current?.name">
          <a-tag color="blue" style="margin-right: 8px;">
            <template #icon><MessageOutlined /></template>
            问诊
          </a-tag>
          <span class="consult-name">{{ sessions.current.name }}</span>
        </div>

        <div class="spacer"></div>

        <div class="header-actions">
          <a-button-group size="small">
            <a-button @click="openSessions" title="问诊列表">
              <template #icon><UnorderedListOutlined /></template>
              列表
            </a-button>
            <a-button @click="openKnowledge" title="知识库">
              <template #icon><BookOutlined /></template>
              知识库
            </a-button>
            <a-button @click="openGlobalSettings" title="全局设置">
              <template #icon><SettingOutlined /></template>
            </a-button>
          </a-button-group>

          <a-divider type="vertical" style="margin: 0 8px; height: 24px;" />

          <a-button type="primary" size="small" @click="openConsultationSettings">
            <template #icon><SettingOutlined /></template>
            问诊设置
          </a-button>
        </div>

        <div class="disclaimer">
          <WarningOutlined style="margin-right: 4px;" />
          学术研讨用，不替代诊疗
        </div>
      </div>
    </a-layout-header>
    <a-layout>
      <a-layout-content style="padding: 12px 16px; height: calc(100vh - 52px); overflow: hidden;">
        <a-row :gutter="12" align="stretch" style="height: 100%;">
          <a-col :span="16" style="height: 100%;">
            <DiscussionPanel class="discussion-panel-host" />
          </a-col>
          <a-col :span="8" style="height: 100%;">
            <StatusPanel class="status-panel-host" @open-settings="openConsultationSettings" />
          </a-col>
        </a-row>
      </a-layout-content>
    </a-layout>
  </a-layout>
  <GlobalSettingsModal v-model:open="globalSettingsOpen" />
  <ConsultationSettingsModal v-model:open="consultationSettingsOpen" @open-knowledge="openKnowledge" />
  <SessionListDrawer v-model:open="sessionsOpen" />
  <KnowledgeBaseDrawer v-model:open="knowledgeOpen" />
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'
import {
  MessageOutlined,
  BookOutlined,
  SettingOutlined,
  UnorderedListOutlined,
  WarningOutlined
} from '@ant-design/icons-vue'
import DiscussionPanel from './components/DiscussionPanel.vue'
import StatusPanel from './components/StatusPanel.vue'
import GlobalSettingsModal from './components/GlobalSettingsModal.vue'
import ConsultationSettingsModal from './components/ConsultationSettingsModal.vue'
import SessionListDrawer from './components/SessionListDrawer.vue'
import KnowledgeBaseDrawer from './components/KnowledgeBaseDrawer.vue'
import { useConsultStore } from './store'
import { useSessionsStore } from './store/sessions'
import logoUrl from './assets/logo.svg'

const globalSettingsOpen = ref(false)
const consultationSettingsOpen = ref(false)
const sessionsOpen = ref(false)
const knowledgeOpen = ref(false)

const openGlobalSettings = () => {
  globalSettingsOpen.value = true
}
const openConsultationSettings = () => {
  consultationSettingsOpen.value = true
}
const openKnowledge = () => {
  knowledgeOpen.value = true
}
const openSessions = () => {
  sessionsOpen.value = true
}

function handleOpenConsultationSettings() {
  consultationSettingsOpen.value = true
}

function handleOpenGlobalSettings() {
  globalSettingsOpen.value = true
}

const consult = useConsultStore()
const sessions = useSessionsStore()
let saveTimer = null

onMounted(() => {
  window.addEventListener('open-settings', handleOpenConsultationSettings)
  window.addEventListener('open-global-settings', handleOpenGlobalSettings)
  sessions.init()
  watch(
    () => consult.$state,
    () => {
      if (saveTimer) clearTimeout(saveTimer)
      saveTimer = setTimeout(() => sessions.saveSnapshotFromConsult(), 500)
    },
    { deep: true }
  )
})

onBeforeUnmount(() => {
  window.removeEventListener('open-settings', handleOpenConsultationSettings)
  window.removeEventListener('open-global-settings', handleOpenGlobalSettings)
  if (saveTimer) clearTimeout(saveTimer)
})
</script>

<style>
html, body, #app { height: 100%; }

.app-header {
  background: linear-gradient(135deg, #0f172a 0%, #1c2f4f 50%, #1f3f68 100%);
  padding: 0 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 4px 16px rgba(15, 23, 42, 0.2);
  color: #e7efff;
  line-height: normal;
  height: 52px;
}

.header-inner {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  gap: 12px;
}

.app-brand {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logo {
  width: 30px;
  height: 30px;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.35);
}

.brand-text {
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.brand-title {
  font-size: 16px;
  font-weight: 700;
  letter-spacing: 0.02em;
  color: #f8fbff;
  line-height: 1.2;
}

.brand-subtitle {
  font-size: 11px;
  color: #94a3b8;
  line-height: 1.2;
}

.header-divider {
  width: 1px;
  height: 28px;
  background: rgba(255, 255, 255, 0.15);
  margin: 0 4px;
}

.consultation-info {
  display: flex;
  align-items: center;
  padding: 4px 0;
}

.consult-name {
  font-size: 13px;
  color: #e2e8f0;
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.spacer {
  flex: 1;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 0;
}

.header-actions :deep(.ant-btn-group .ant-btn) {
  background: rgba(255, 255, 255, 0.08);
  border-color: rgba(255, 255, 255, 0.15);
  color: #e2e8f0;
}

.header-actions :deep(.ant-btn-group .ant-btn:hover) {
  background: rgba(255, 255, 255, 0.15);
  border-color: rgba(255, 255, 255, 0.25);
}

.header-actions :deep(.ant-btn-group .ant-btn-primary) {
  background: #1890ff;
  border-color: #1890ff;
}

.header-actions :deep(.ant-btn-group .ant-btn-primary:hover) {
  background: #40a9ff;
  border-color: #40a9ff;
}

.disclaimer {
  display: flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.06);
  color: #fbbf24;
  font-size: 11px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  white-space: nowrap;
}

.discussion-panel-host,
.status-panel-host {
  height: 100%;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

::-webkit-scrollbar-track {
  background: #f5f5f5;
  border-radius: 3px;
}

::-webkit-scrollbar-thumb {
  background: #bfbfbf;
  border-radius: 3px;
  transition: background 0.2s ease;
}

::-webkit-scrollbar-thumb:hover {
  background: #8c8c8c;
}

@media (max-width: 992px) {
  .disclaimer { display: none; }
  .consult-name { max-width: 120px; }
}

@media (max-width: 768px) {
  .consultation-info { display: none; }
  .header-divider { display: none; }
}
</style>
