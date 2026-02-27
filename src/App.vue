<template>
  <a-layout style="min-height: 100vh">
    <a-layout-header class="app-header">
      <div class="header-inner">
        <div class="app-brand">
          <img :src="logoUrl" alt="AstraCare Logo" class="logo" />
          <div class="brand-text">
            <div class="brand-title">AstraCare 临床智研台</div>
            <div class="brand-subtitle">多专家协同 · 知识驱动 · 高准度推理</div>
          </div>
          <div class="disclaimer">本内容用于学术研讨，不替代正式诊疗</div>
        </div>
        <div class="app-actions">
          <a-button @click="openSessions">问诊列表</a-button>
          <a-button @click="openGlobalSettings">全局设置</a-button>
          <a-button @click="openKnowledge">知识库</a-button>
          <a-button type="primary" @click="openConsultationSettings">问诊设置</a-button>
        </div>
      </div>
    </a-layout-header>
    <a-layout>
      <a-layout-content style="padding: 16px; height: calc(100vh - 64px); overflow: hidden;">
        <!-- <a-alert
          type="warning"
          show-icon
          message="【本内容仅供参考，身体不适尽早就医】"
          style="margin-bottom: 12px;"
        /> -->
        <a-row :gutter="16" align="stretch" style="height: 100%;">
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
  // 初始化问诊列表并切换到当前问诊
  sessions.init()
  // 监听咨询状态变更并自动保存到本地
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
  background: linear-gradient(135deg, #0f172a 0%, #1c2f4f 70%, #1f3f68 100%);
  padding: 4px 20px 8px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 8px 24px rgba(15, 23, 42, 0.25);
  color: #e7efff;
  line-height: normal;
  min-height: 56px;
}

.header-inner {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: nowrap;
}

.app-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  flex: 1 1 auto;
}

.brand-line {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.logo {
  width: 34px;
  height: 34px;
  border-radius: 10px;
  box-shadow: 0 6px 16px rgba(37, 99, 235, 0.35);
  flex-shrink: 0;
}

.brand-text {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.brand-title {
  font-size: 18px;
  font-weight: 700;
  letter-spacing: 0.02em;
  color: #f8fbff;
  line-height: 1.2;
}

.brand-subtitle {
  font-size: 12px;
  color: #d6e3ff;
  line-height: 1.2;
  white-space: nowrap;
}

.disclaimer {
  padding: 4px 8px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.08);
  color: #ffe6b0;
  font-size: 11px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  backdrop-filter: blur(6px);
  white-space: nowrap;
  flex-shrink: 0;
}

.app-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  justify-content: flex-end;
  flex: 0 0 auto;
}

.discussion-panel-host,
.status-panel-host {
  height: 100%;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

/* Custom scrollbar styles */
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
  .header-inner { flex-wrap: wrap; }
  .brand-subtitle { white-space: normal; }
  .app-actions { width: 100%; justify-content: flex-start; }
}

@media (max-width: 640px) {
  .brand-title { font-size: 17px; }
  .brand-subtitle { font-size: 11px; }
  .app-header { padding: 12px 14px; }
}
</style>
