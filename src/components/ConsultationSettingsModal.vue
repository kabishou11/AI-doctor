<template>
  <a-modal
    v-model:open="open"
    title="问诊设置"
    width="960px"
    :confirm-loading="saving"
    @ok="onSave"
    ok-text="保存"
    :after-close="resetModal"
  >
    <a-tabs v-model:activeKey="activeTab">
      <a-tab-pane key="consultSettings" tab="问诊参数">
        <a-form layout="vertical">
          <a-alert type="info" show-icon message="问诊参数" description="配置当前问诊的名称与提示词。" style="margin-bottom: 16px;" />
          <a-form-item label="问诊名称" :validate-status="nameError ? 'error' : undefined" :help="nameError">
            <a-input v-model:value="localConsultationName" placeholder="请输入问诊名称" allow-clear />
          </a-form-item>
          <a-form-item label="当前会诊系统提示词">
            <a-textarea v-model:value="localSettings.globalSystemPrompt" rows="6" />
          </a-form-item>
          <a-form-item label="最终总结提示词">
            <a-textarea v-model:value="localSettings.summaryPrompt" rows="6" />
          </a-form-item>
          <a-form-item label="发言顺序">
            <a-radio-group v-model:value="localSettings.turnOrder">
              <a-radio value="random">随机</a-radio>
              <a-radio value="custom">自定义（按医生列表顺序）</a-radio>
            </a-radio-group>
          </a-form-item>
          <a-form-item label="连续未标注不太准确的最大轮数">
            <a-input-number v-model:value="localSettings.maxRoundsWithoutElimination" :min="1" />
          </a-form-item>
        </a-form>
      </a-tab-pane>

      <a-tab-pane key="consultDoctors" tab="问诊医生">
        <a-space direction="vertical" style="width: 100%">
          <a-alert type="info" show-icon message="当前问诊医生" description="从全局配置中选择医生加入本次问诊。支持拖拽调整顺序以控制发言优先级。" />

          <!-- 视图切换 + 添加控制 -->
          <div style="display:flex; gap: 8px; flex-wrap: wrap; align-items: center; margin-bottom: 8px;">
            <a-select v-model:value="selectedToAdd" :options="globalDoctorOptions" style="flex:1; min-width: 200px;" placeholder="选择要添加的医生" />
            <a-button type="primary" @click="addToConsult">添加</a-button>
            <a-button @click="addAllToConsult">添加全部</a-button>
            <a-divider type="vertical" style="margin: 0 4px;" />
            <a-button-group>
              <a-button :type="doctorViewMode === 'list' ? 'primary' : 'default'" @click="doctorViewMode = 'list'">
                <UnorderedListOutlined />
              </a-button>
              <a-button :type="doctorViewMode === 'card' ? 'primary' : 'default'" @click="doctorViewMode = 'card'">
                <AppstoreOutlined />
              </a-button>
            </a-button-group>
            <a-popconfirm title="确认清空当前问诊医生？" @confirm="clearConsultDoctors">
              <a-button danger>清空</a-button>
            </a-popconfirm>
          </div>

          <!-- 列表视图 -->
          <a-list v-if="doctorViewMode === 'list' && consultDoctors.length > 0" :data-source="consultDoctors" :render-item="renderConsultDoctorList" />
          <!-- 卡片视图 -->
          <div v-else-if="doctorViewMode === 'card' && consultDoctors.length > 0" class="doctor-card-grid">
            <div
              v-for="(doc, index) in consultDoctors"
              :key="doc.id"
              class="doctor-card"
              :draggable="true"
              @dragstart="onDoctorDragStart($event, index)"
              @dragover.prevent="onDoctorDragOver($event, index)"
              @drop="onDoctorDrop($event, index)"
              @dragend="onDoctorDragEnd"
              :class="{ 'doctor-card-dragging': draggingDoctorIndex === index, 'doctor-card-drag-over': dragOverDoctorIndex === index }"
            >
              <div class="doctor-card-drag-handle" title="拖拽排序">
                <HolderOutlined />
              </div>
              <div class="doctor-card-body">
                <div class="doctor-card-header">
                  <a-avatar :style="{ backgroundColor: getAvatarColor(doc.name) }" size="large">
                    {{ doc.name?.charAt(0) || '?' }}
                  </a-avatar>
                  <div class="doctor-card-info">
                    <div class="doctor-card-name">{{ doc.name }}</div>
                    <div class="doctor-card-model">
                      <TagOutlined />
                      {{ doc.model }}
                    </div>
                    <div class="doctor-card-provider">
                      <ApiOutlined />
                      {{ resolveProviderLabel(doc.provider) }}
                    </div>
                  </div>
                  <div class="doctor-card-status">
                    <a-tag :color="doc.status === 'active' ? 'green' : 'orange'">
                      {{ doc.status === 'active' ? '在席' : '不太准确' }}
                    </a-tag>
                  </div>
                </div>
                <div class="doctor-card-desc" v-if="doc.description">
                  {{ previewText(doc.description, 80) }}
                </div>
                <div class="doctor-card-actions">
                  <a-button type="text" size="small" @click="toggleDoctorStatus(doc.id)">
                    {{ doc.status === 'active' ? '标记不太准确' : '恢复在席' }}
                  </a-button>
                  <a-button type="text" danger size="small" @click="removeConsultDoctor(doc.id)">移除</a-button>
                </div>
              </div>
            </div>
          </div>

          <a-empty v-if="consultDoctors.length === 0" description="暂未添加问诊医生，请从上方添加" />
        </a-space>
      </a-tab-pane>

      <a-tab-pane key="linkedConsultations" tab="关联问诊">
        <a-space direction="vertical" style="width: 100%">
          <a-alert type="info" show-icon message="关联问诊" description="可以从已结束的问诊中选择关联问诊，作为医生诊断的参考上下文。多选的问诊必须具有相同的患者名称、性别、年龄。" />
          <div style="display:flex; gap: 8px;">
            <a-select
              v-model:value="selectedLinkedIds"
              mode="multiple"
              :options="finishedConsultationOptions"
              style="flex:1;"
              placeholder="选择已结束的问诊（可多选）"
              :filter-option="filterLinkedOption"
              @change="handleLinkedChange"
            />
            <a-popconfirm title="确认清空关联问诊？" @confirm="clearLinkedConsultations">
              <a-button danger>清空</a-button>
            </a-popconfirm>
          </div>

          <!-- 卡片视图 -->
          <div v-if="linkedConsultations.length > 0" class="linked-card-grid">
            <div v-for="item in linkedConsultations" :key="item.id" class="linked-card">
              <div class="linked-card-header">
                <FileTextOutlined style="font-size: 18px; color: #1890ff; flex-shrink: 0;" />
                <span class="linked-card-title">{{ item.consultationName }}</span>
                <a-tag v-if="item.finishedAt" color="blue" style="margin-left: auto; flex-shrink: 0;">
                  {{ formatDateTime(item.finishedAt) }}
                </a-tag>
              </div>
              <div class="linked-card-patient">
                <UserOutlined /> 患者：
                <a-space>
                  <span>{{ item.patientName || '未知' }}</span>
                  <span>{{ genderMap[item.patientGender] || item.patientGender || '未知' }}</span>
                  <span>{{ item.patientAge != null ? `${item.patientAge}岁` : '年龄未知' }}</span>
                </a-space>
              </div>
              <div class="linked-card-summary">
                <CollapseGhost :bordered="false" style="width: 100%;">
                  <a-collapse-panel key="1" header="查看详情">
                    <div v-if="item.pastHistory" class="linked-card-field">
                      <span class="linked-card-label">既往疾病：</span>
                      <span>{{ item.pastHistory }}</span>
                    </div>
                    <div v-if="item.currentProblem" class="linked-card-field">
                      <span class="linked-card-label">本次问题：</span>
                      <span>{{ item.currentProblem }}</span>
                    </div>
                    <div v-if="item.imageRecognitionResult" class="linked-card-field">
                      <span class="linked-card-label">图片识别：</span>
                      <span>{{ item.imageRecognitionResult }}</span>
                    </div>
                    <div v-if="item.finalSummary" class="linked-card-field">
                      <span class="linked-card-label">最终答案：</span>
                      <span>{{ item.finalSummary }}</span>
                    </div>
                  </a-collapse-panel>
                </CollapseGhost>
              </div>
              <div class="linked-card-actions">
                <a-button type="link" danger size="small" @click="removeLinkedConsultation(item.id)">移除关联</a-button>
              </div>
            </div>
          </div>

          <a-empty v-else description="暂无关联问诊" />
        </a-space>
      </a-tab-pane>

      <a-tab-pane key="knowledge" tab="知识库选择">
        <a-space direction="vertical" style="width: 100%" :size="12">
          <a-alert type="info" show-icon message="选择要用于当前问诊的知识片段" description="勾选后将作为上下文附加到提示词中，请确保内容与患者相关。" />

          <!-- 知识库配置快捷入口 -->
          <a-card size="small" :bordered="false" style="background: #fffbe6; border: 1px solid #ffe58f;">
            <template #title>
              <span><SettingOutlined /> 知识库配置</span>
            </template>
            <template #extra>
              <a-button type="primary" size="small" @click="() => emit('open-knowledge')">
                <SettingOutlined /> 管理知识库
              </a-button>
            </template>
            <a-space wrap>
              <a-statistic title="文档总数" :value="knowledge.docs?.length || 0" :value-style="{ fontSize: '20px' }" />
              <a-divider type="vertical" />
              <a-statistic title="已选片段" :value="selectedKnowledgeIds.length" :value-style="{ fontSize: '20px', color: '#52c41a' }" />
              <a-divider type="vertical" />
              <a-statistic title="知识集合" :value="knowledgeCollections.length" :value-style="{ fontSize: '20px' }" />
            </a-space>
          </a-card>

          <!-- 智能推荐 -->
          <a-card size="small" title="智能推荐" :bordered="false" style="background: #f0f7ff;">
            <template #extra>
              <a-button type="link" size="small" @click="autoRecommendKnowledge" :loading="autoRecommending">
                <ReloadOutlined /> 重新分析
              </a-button>
            </template>
            <div v-if="recommendedKnowledge.length > 0">
              <div style="margin-bottom: 8px; color: #595959; font-size: 12px;">
                根据当前患者问题，系统推荐以下相关知识（点击标签快速选择）：
              </div>
              <a-space wrap>
                <a-tag
                  v-for="rec in recommendedKnowledge"
                  :key="rec.id"
                  :color="selectedKnowledgeIds.includes(rec.id) ? 'blue' : 'default'"
                  class="recommend-tag"
                  @click="toggleKnowledge(rec.id)"
                  style="cursor: pointer;"
                >
                  <StarOutlined v-if="selectedKnowledgeIds.includes(rec.id)" />
                  {{ rec.title }}
                  <span style="opacity: 0.7; margin-left: 4px;">({{ Math.round(rec.score * 100) }}%)</span>
                </a-tag>
              </a-space>
            </div>
            <div v-else style="color: #8c8c8c; font-size: 12px;">
              暂无推荐，请先输入患者问题或手动选择知识片段
            </div>
          </a-card>

          <!-- 搜索和筛选 -->
          <div style="display:flex; gap: 8px; flex-wrap: wrap; align-items: center;">
            <a-input-search
              v-model:value="knowledgeSearch"
              placeholder="搜索标题/内容/标签"
              allow-clear
              style="flex: 1; min-width: 200px;"
              @search="knowledgeSearch = $event"
            />
            <a-select
              v-model:value="knowledgeCollectionFilter"
              placeholder="按集合筛选"
              allow-clear
              style="width: 150px;"
            >
              <a-select-option value="">全部集合</a-select-option>
              <a-select-option v-for="col in knowledgeCollections" :key="col.id" :value="col.id">
                <a-space>
                  <a-tag :color="col.color || 'blue'" size="small">{{ col.name }}</a-tag>
                </a-space>
              </a-select-option>
            </a-select>
            <a-select
              v-model:value="knowledgeTagFilter"
              mode="multiple"
              placeholder="按标签筛选"
              allow-clear
              style="width: 200px;"
              :options="knowledgeTagOptions"
              :max-tag-count="1"
            />
          </div>

          <!-- 批量操作工具栏 -->
          <div style="display:flex; gap: 8px; align-items: center; flex-wrap: wrap;">
            <a-space>
              <a-button size="small" @click="selectAllVisible" :disabled="knowledgeOptions.length === 0">
                全选当前页
              </a-button>
              <a-button size="small" @click="deselectAllVisible" :disabled="knowledgeOptions.length === 0">
                取消当前页
              </a-button>
              <a-button size="small" type="primary" @click="selectAllRelated" :disabled="recommendedKnowledge.length === 0">
                <StarOutlined /> 全选推荐相关
              </a-button>
            </a-space>
            <a-divider type="vertical" style="margin: 0 4px;" />
            <span style="color: #8c8c8c; font-size: 12px;">
              共 {{ knowledgeOptions.length }} 条，已选 {{ selectedKnowledgeIds.length }} 条
            </span>
          </div>

          <!-- 已选知识预览摘要 -->
          <div v-if="selectedKnowledgePreview.length > 0" style="padding: 8px 12px; background: #f6ffed; border-radius: 6px; border: 1px solid #b7eb8f;">
            <div style="color: #52c41a; font-weight: 500; margin-bottom: 8px;">
              <CheckCircleOutlined /> 已选择 {{ selectedKnowledgeIds.length }} 个知识片段
            </div>
            <div class="selected-knowledge-chips">
              <a-tag
                v-for="item in selectedKnowledgePreview"
                :key="item.id"
                closable
                color="green"
                @close="toggleKnowledge(item.id)"
                style="margin-bottom: 4px;"
              >
                {{ item.title }}
              </a-tag>
              <a-tag v-if="selectedKnowledgeIds.length > selectedKnowledgePreview.length" color="green">
                +{{ selectedKnowledgeIds.length - selectedKnowledgePreview.length }} 更多
              </a-tag>
            </div>
            <!-- 预览摘要 -->
            <a-collapse
              ghost
              :bordered="false"
              style="margin-top: 8px;"
              v-if="selectedKnowledgeDetails.length > 0"
            >
              <a-collapse-panel key="preview" header="预览已选内容摘要">
                <div v-for="item in selectedKnowledgeDetails" :key="item.id" style="margin-bottom: 8px;">
                  <div style="font-weight: 600; font-size: 12px; color: #262626;">{{ item.title }}</div>
                  <div style="font-size: 12px; color: #8c8c8c;">{{ previewText(item.content, 120) }}</div>
                </div>
              </a-collapse-panel>
            </a-collapse>
            <a-button type="link" size="small" danger @click="clearKnowledgeSelection" style="padding: 0; margin-top: 4px;">
              清空已选
            </a-button>
          </div>

          <!-- 知识列表 -->
          <a-list
            v-if="knowledgeOptions.length"
            :data-source="knowledgeOptions"
            item-layout="vertical"
            size="small"
            :pagination="{ pageSize: 8, showSizeChanger: false }"
            :render-item="renderKnowledgeItem"
          />
          <a-empty v-else description="暂无知识文档，请先在知识库中创建" />
        </a-space>
      </a-tab-pane>
    </a-tabs>
  </a-modal>
</template>

<script setup>
import { ref, watch, h, resolveComponent, computed } from 'vue'
import { useConsultStore } from '../store'
import { useGlobalStore } from '../store/global'
import { useSessionsStore } from '../store/sessions'
import { useKnowledgeStore } from '../store/knowledge'
import { message, Modal } from 'ant-design-vue'
import {
  SettingOutlined,
  StarOutlined,
  UnorderedListOutlined,
  AppstoreOutlined,
  HolderOutlined,
  TagOutlined,
  ApiOutlined,
  UserOutlined,
  FileTextOutlined,
  ReloadOutlined,
  CheckCircleOutlined
} from '@ant-design/icons-vue'

const store = useConsultStore()
const global = useGlobalStore()
const sessions = useSessionsStore()
const knowledge = useKnowledgeStore()

const props = defineProps({ open: { type: Boolean, default: false } })
const emit = defineEmits(['update:open', 'open-knowledge'])

const open = ref(props.open)
const saving = ref(false)
const activeTab = ref('consultSettings')

watch(
  () => props.open,
  (v) => (open.value = v)
)
watch(open, (v) => emit('update:open', v))

// ─── 本地状态 ──────────────────────────────────────────────────────────────
const localConsultationName = ref(store.consultationName || '')
const localSettings = ref(JSON.parse(JSON.stringify(store.settings)))
const consultDoctors = ref(JSON.parse(JSON.stringify(store.doctors)))
const linkedConsultations = ref(JSON.parse(JSON.stringify(store.linkedConsultations || [])))
const selectedToAdd = ref(null)
const selectedLinkedIds = ref(
  (store.linkedConsultations || []).map((item) => item.sourceId || item.id?.replace(/^linked-/, '') || item.id)
)
const previousValidLinkedIds = ref([...selectedLinkedIds.value])
const selectedKnowledgeIds = ref(Array.isArray(store.selectedKnowledgeIds) ? [...store.selectedKnowledgeIds] : [])
const knowledgeSearch = ref('')
const knowledgeCollectionFilter = ref('')
const knowledgeTagFilter = ref([])
const recommendedKnowledge = ref([])
const autoRecommending = ref(false)
const nameError = ref('')

// 医生视图模式
const doctorViewMode = ref('card')

// 拖拽相关
const draggingDoctorIndex = ref(-1)
const dragOverDoctorIndex = ref(-1)

// 集合列表
const COLLECTIONS_KEY = 'kb_collections_v1'
const knowledgeCollections = ref([])

function loadKnowledgeCollections() {
  try {
    const raw = localStorage.getItem(COLLECTIONS_KEY)
    knowledgeCollections.value = raw ? JSON.parse(raw) : []
  } catch (e) {
    knowledgeCollections.value = []
  }
}

watch(
  () => props.open,
  (v) => {
    if (v) {
      activeTab.value = 'consultSettings'
      localConsultationName.value = store.consultationName || ''
      localSettings.value = JSON.parse(JSON.stringify(store.settings))
      consultDoctors.value = JSON.parse(JSON.stringify(store.doctors))
      linkedConsultations.value = JSON.parse(JSON.stringify(store.linkedConsultations || []))
      selectedToAdd.value = null
      selectedLinkedIds.value = (store.linkedConsultations || []).map(
        (item) => item.sourceId || item.id?.replace(/^linked-/, '') || item.id
      )
      previousValidLinkedIds.value = [...selectedLinkedIds.value]
      selectedKnowledgeIds.value = Array.isArray(store.selectedKnowledgeIds) ? [...store.selectedKnowledgeIds] : []
      knowledgeSearch.value = ''
      knowledgeCollectionFilter.value = ''
      knowledgeTagFilter.value = []
      nameError.value = ''
      doctorViewMode.value = 'card'
      loadKnowledgeCollections()
      setTimeout(() => autoRecommendKnowledge(), 100)
    }
  }
)

function resetModal() {
  nameError.value = ''
}

// ─── 医生相关 ──────────────────────────────────────────────────────────────
const providerOptionsMap = computed(() => {
  const map = {}
  const options = [
    { label: 'OpenAI规范', value: 'openai' },
    { label: 'Anthropic规范', value: 'anthropic' },
    { label: 'Gemini规范', value: 'gemini' },
    { label: '硅基流动', value: 'siliconflow' },
    { label: '魔搭社区', value: 'modelscope' }
  ]
  options.forEach((item) => { map[item.value] = item.label })
  return map
})

const AVATAR_COLORS = ['#1890ff', '#52c41a', '#fa8c16', '#f5222d', '#722ed1', '#13c2c2', '#eb2f96']

function getAvatarColor(name) {
  if (!name) return AVATAR_COLORS[0]
  let hash = 0
  for (const ch of name) hash = ch.charCodeAt(0) + ((hash << 5) - hash)
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length]
}

const globalDoctorOptions = computed(() => {
  const included = new Set((consultDoctors.value || []).map((d) => d.id))
  return (global.doctors || [])
    .filter((d) => !included.has(d.id))
    .map((d) => ({
      label: `${d.name}（${providerOptionsMap.value[d.provider] || d.provider} / ${d.model}）`,
      value: d.id
    }))
})

function isValidDoctor(doctor) {
  return doctor && doctor.apiKey && doctor.apiKey.trim() && doctor.model && doctor.model.trim()
}

function addToConsult() {
  const targetId = selectedToAdd.value
  if (!targetId) return
  const d = (global.doctors || []).find((x) => x.id === targetId)
  if (!d) return
  if (!isValidDoctor(d)) {
    message.error(`医生"${d.name}"未配置API Key或模型，请先去全局设置中配置。`)
    return
  }
  consultDoctors.value.push({ ...d, status: 'active', votes: 0 })
  selectedToAdd.value = null
}

function addAllToConsult() {
  const included = new Set((consultDoctors.value || []).map((d) => d.id))
  const toAdd = (global.doctors || []).filter((d) => !included.has(d.id))
  const validDoctors = toAdd.filter((d) => isValidDoctor(d))
  const invalidDoctors = toAdd.filter((d) => !isValidDoctor(d))
  if (invalidDoctors.length > 0) {
    const invalidNames = invalidDoctors.map((d) => d.name).join('、')
    message.error(`以下医生未配置API Key或模型，无法添加：${invalidNames}。请先去全局设置中配置。`)
  }
  if (validDoctors.length > 0) {
    consultDoctors.value = consultDoctors.value.concat(validDoctors.map((d) => ({ ...d, status: 'active', votes: 0 })))
    message.success(`已添加 ${validDoctors.length} 位有效医生`)
  }
}

function clearConsultDoctors() {
  consultDoctors.value = []
}

function removeConsultDoctor(id) {
  consultDoctors.value = consultDoctors.value.filter((d) => d.id !== id)
}

function toggleDoctorStatus(id) {
  const doc = consultDoctors.value.find((d) => d.id === id)
  if (doc) doc.status = doc.status === 'active' ? 'eliminated' : 'active'
}

// 拖拽排序
function onDoctorDragStart(event, index) {
  draggingDoctorIndex.value = index
  event.dataTransfer.effectAllowed = 'move'
  event.dataTransfer.setData('text/plain', String(index))
}

function onDoctorDragOver(event, index) {
  if (draggingDoctorIndex.value === -1 || draggingDoctorIndex.value === index) return
  dragOverDoctorIndex.value = index
  event.dataTransfer.dropEffect = 'move'
}

function onDoctorDrop(event, toIndex) {
  event.preventDefault()
  const fromIndex = draggingDoctorIndex.value
  if (fromIndex === -1 || fromIndex === toIndex) return
  const list = [...consultDoctors.value]
  const [item] = list.splice(fromIndex, 1)
  list.splice(toIndex, 0, item)
  consultDoctors.value = list
}

function onDoctorDragEnd() {
  draggingDoctorIndex.value = -1
  dragOverDoctorIndex.value = -1
}

function renderConsultDoctorList({ item }) {
  const AButton = resolveComponent('a-button')
  return h(
    'a-list-item',
    null,
    {
      default: () =>
        h('div', { style: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%', padding: '8px 0' } }, [
          h('div', { style: { display: 'flex', alignItems: 'center', gap: '12px' } }, [
            h('div', { style: { cursor: 'move', color: '#bfbfbf', fontSize: '16px' }, title: '拖拽排序', onDragend: onDoctorDragEnd, draggable: true }, [
              h(HolderOutlined)
            ]),
            h('div', [
              h('div', { style: { fontWeight: '600' } }, item.name),
              h('div', { style: { color: '#8c8c8c', fontSize: '12px' } },
                `${resolveProviderLabel(item.provider)} / ${item.model}`
              )
            ]),
            h('div', [
              h('span', { style: { fontSize: '12px', color: item.status === 'active' ? '#52c41a' : '#fa8c16' } },
                item.status === 'active' ? '在席' : '不太准确'
              )
            ])
          ]),
          h('div', [
            h(AButton, { type: 'link', size: 'small', onClick: () => toggleDoctorStatus(item.id) }, { default: () => item.status === 'active' ? '不太准确' : '恢复在席' }),
            h(AButton, { type: 'link', danger: true, size: 'small', onClick: () => removeConsultDoctor(item.id) }, { default: () => '移除' })
          ])
        ])
    }
  )
}

// ─── 关联问诊相关 ───────────────────────────────────────────────────────────
const genderMap = { male: '男', female: '女', other: '其他' }

function resolveProviderLabel(value) {
  return providerOptionsMap.value[value] || value
}

function formatDateTime(value) {
  if (!value) return '未知时间'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  const pad = (n) => String(n).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`
}

function previewText(text, maxLength = 80) {
  if (!text) return '无'
  const normalized = String(text).replace(/\s+/g, ' ').trim()
  if (!normalized) return '无'
  return normalized.length > maxLength ? `${normalized.slice(0, maxLength)}…` : normalized
}

const finishedConsultationOptions = computed(() => {
  const currentId = sessions.currentId
  return sessions.sessions
    .filter((s) => s.status === '已结束' && s.id !== currentId)
    .map((s) => ({
      label: `${s.name}（${formatDateTime(s.updatedAt)}）`,
      value: s.id
    }))
})

function filterLinkedOption(input, option) {
  return option.label.toLowerCase().includes(input.toLowerCase())
}

function handleLinkedChange(selectedIds) {
  if (!selectedIds || !selectedIds.length) {
    linkedConsultations.value = []
    previousValidLinkedIds.value = []
    return
  }
  const ids = Array.isArray(selectedIds) ? [...selectedIds] : []
  const newLinked = []

  for (const id of ids) {
    const data = sessions.getSessionData(id)
    if (!data) {
      message.error('读取关联问诊数据失败，请确认该问诊已保存。')
      selectedLinkedIds.value = [...previousValidLinkedIds.value]
      return
    }
    const sessionMeta = sessions.sessions.find((s) => s.id === id)
    const consultName = sessionMeta?.name || data?.consultationName || '未命名问诊'
    const patientCase = data?.patientCase || {}
    const patientName = patientCase.name || ''
    const patientGender = patientCase.gender || ''
    const patientAge = patientCase.age
    const pastHistory = patientCase.pastHistory || ''
    const currentProblem = patientCase.currentProblem || ''
    const imageRecognitionResult = patientCase.imageRecognitionResult || ''
    const finalSummary = data?.finalSummary?.content || ''
    const finishedAt = sessionMeta?.updatedAt || ''

    newLinked.push({
      id: `linked-${id}`,
      sourceId: id,
      consultationName: consultName,
      patientName,
      patientGender,
      patientAge,
      pastHistory,
      currentProblem,
      imageRecognitionResult,
      finalSummary,
      finishedAt,
      metadata: { sessionMeta, patientCase }
    })
  }

  if (newLinked.length === 0) {
    linkedConsultations.value = []
    previousValidLinkedIds.value = []
    return
  }

  const firstPatient = newLinked[0]
  const firstName = firstPatient.patientName || ''
  const firstGender = firstPatient.patientGender || ''
  const firstAge = firstPatient.patientAge

  for (let i = 1; i < newLinked.length; i++) {
    const item = newLinked[i]
    const name = item.patientName || ''
    const gender = item.patientGender || ''
    const age = item.patientAge
    if (name !== firstName || gender !== firstGender || age !== firstAge) {
      const firstAgeStr = firstAge != null ? `${firstAge}岁` : '未知'
      const itemAgeStr = age != null ? `${age}岁` : '未知'
      message.error(
        `无法添加：多选的问诊必须具有相同的患者名称、性别、年龄。\n第1个：${firstName || '未知'}，${genderMap[firstGender] || firstGender || '未知'}，${firstAgeStr}\n第${i + 1}个：${name || '未知'}，${genderMap[gender] || gender || '未知'}，${itemAgeStr}`
      )
      selectedLinkedIds.value = [...previousValidLinkedIds.value]
      return
    }
  }

  linkedConsultations.value = newLinked
  previousValidLinkedIds.value = [...ids]
}

function clearLinkedConsultations() {
  linkedConsultations.value = []
  selectedLinkedIds.value = []
  previousValidLinkedIds.value = []
}

function removeLinkedConsultation(id) {
  const target = linkedConsultations.value.find((item) => item.id === id)
  linkedConsultations.value = linkedConsultations.value.filter((item) => item.id !== id)
  const sourceId = target?.sourceId || id.replace(/^linked-/, '')
  selectedLinkedIds.value = selectedLinkedIds.value.filter((sid) => sid !== sourceId)
  handleLinkedChange([...selectedLinkedIds.value])
}

// ─── 知识库相关 ─────────────────────────────────────────────────────────────
const knowledgeOptions = computed(() => {
  let list = knowledge.search(knowledgeSearch.value)
  if (knowledgeCollectionFilter.value) {
    list = list.filter((item) => item.collectionId === knowledgeCollectionFilter.value)
  }
  if (knowledgeTagFilter.value.length > 0) {
    list = list.filter((item) =>
      knowledgeTagFilter.value.every((tag) => (item.tags || []).includes(tag))
    )
  }
  return (list || []).map((item) => ({
    id: item.id,
    title: item.title || '未命名文档',
    desc: item.excerpt || previewText(item.content, 120),
    tags: item.tags || [],
    content: item.content || ''
  }))
})

const knowledgeTagOptions = computed(() => {
  const tags = new Set()
  ;(knowledge.docs || []).forEach((d) => (d.tags || []).forEach((t) => tags.add(t)))
  return Array.from(tags).map((t) => ({ label: t, value: t }))
})

// 已选知识预览
const selectedKnowledgeDetails = computed(() => {
  return (knowledge.docs || [])
    .filter((d) => selectedKnowledgeIds.value.includes(d.id))
    .map((item) => ({
      id: item.id,
      title: item.title || '未命名文档',
      content: item.content || ''
    }))
})

const selectedKnowledgePreview = computed(() => {
  return selectedKnowledgeDetails.value.slice(0, 8)
})

// 智能推荐
async function autoRecommendKnowledge() {
  const patientProblem = store.patientCase?.currentProblem || ''
  const pastHistory = store.patientCase?.pastHistory || ''
  const searchText = `${patientProblem} ${pastHistory}`.trim()
  if (!searchText) {
    recommendedKnowledge.value = []
    return
  }
  autoRecommending.value = true
  try {
    const searchWords = searchText.toLowerCase().split(/[\s,，。；!?]+/).filter((w) => w.length > 1)
    const docs = knowledge.docs || []
    const scored = docs.map((doc) => {
      const title = (doc.title || '').toLowerCase()
      const content = (doc.content || '').toLowerCase()
      const tags = (doc.tags || []).map((t) => t.toLowerCase())
      let score = 0
      for (const word of searchWords) {
        if (title.includes(word)) score += 3
        if (tags.some((t) => t.includes(word))) score += 2
        if (content.includes(word)) score += 1
      }
      const maxScore = searchWords.length * 3
      return { ...doc, score: maxScore > 0 ? score / maxScore : 0 }
    })
    recommendedKnowledge.value = scored.filter((d) => d.score > 0).sort((a, b) => b.score - a.score).slice(0, 10)
    if (recommendedKnowledge.value.length === 0) {
      message.info('未找到与当前问题直接相关的知识片段')
    }
  } catch (e) {
    console.error('Auto recommend error:', e)
  } finally {
    autoRecommending.value = false
  }
}

function toggleKnowledge(id) {
  const set = new Set(selectedKnowledgeIds.value || [])
  if (set.has(id)) set.delete(id)
  else set.add(id)
  selectedKnowledgeIds.value = Array.from(set)
}

function clearKnowledgeSelection() {
  selectedKnowledgeIds.value = []
}

// 批量选择
function selectAllVisible() {
  const visible = knowledgeOptions.value
  const currentSet = new Set(selectedKnowledgeIds.value)
  visible.forEach((item) => currentSet.add(item.id))
  selectedKnowledgeIds.value = Array.from(currentSet)
  message.success(`已选择当前页 ${visible.length} 个知识片段`)
}

function deselectAllVisible() {
  const visible = new Set(knowledgeOptions.value.map((item) => item.id))
  selectedKnowledgeIds.value = selectedKnowledgeIds.value.filter((id) => !visible.has(id))
  message.success('已取消当前页选择')
}

function selectAllRelated() {
  const currentSet = new Set(selectedKnowledgeIds.value)
  recommendedKnowledge.value.forEach((rec) => currentSet.add(rec.id))
  selectedKnowledgeIds.value = Array.from(currentSet)
  message.success(`已选择 ${recommendedKnowledge.value.length} 个推荐相关片段`)
}

function renderKnowledgeItem({ item }) {
  const ACheckbox = resolveComponent('a-checkbox')
  return h(
    'a-list-item',
    null,
    {
      default: () =>
        h('div', { style: { display: 'flex', gap: '12px', alignItems: 'flex-start', padding: '8px 0', width: '100%' } }, [
          h(ACheckbox, {
            checked: selectedKnowledgeIds.value.includes(item.id),
            onChange: () => toggleKnowledge(item.id)
          }),
          h('div', { style: { flex: 1, minWidth: 0 } }, [
            h('div', { style: { display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' } }, [
              h('span', { style: { fontWeight: '600' } }, item.title),
              selectedKnowledgeIds.value.includes(item.id)
                ? h('a-tag', { color: 'green', size: 'small' }, '已选')
                : null
            ]),
            h('div', { style: { color: '#8c8c8c', fontSize: '12px', marginBottom: '6px' } }, item.desc || '无摘要'),
            h('div', { style: { display: 'flex', flexWrap: 'wrap', gap: '4px' } },
              (item.tags || []).map((tag) => h('a-tag', { key: tag, size: 'small', color: 'blue' }, tag))
            )
          ])
        ])
    }
  )
}

// ─── 保存逻辑 ──────────────────────────────────────────────────────────────
async function onSave() {
  // 验证：问诊名称必填
  if (!localConsultationName.value.trim()) {
    nameError.value = '问诊名称不能为空'
    Modal.error({ title: '保存失败', content: '问诊名称不能为空，请填写后再保存。' })
    return
  }
  nameError.value = ''

  // 验证：至少需要一位问诊医生
  if (consultDoctors.value.length === 0) {
    const { default: ConfirmModal } = await import('ant-design-vue')
    Modal.confirm({
      title: '未添加问诊医生',
      content: '当前未添加任何问诊医生，确定要保存吗？',
      okText: '仍要保存',
      cancelText: '返回修改',
      onOk() {
        doSave()
      }
    })
    return
  }

  doSave()
}

function doSave() {
  saving.value = true
  try {
    store.setConsultationName(localConsultationName.value)
    store.setSettings(localSettings.value)
    store.setDoctors(consultDoctors.value)
    store.setLinkedConsultations(linkedConsultations.value)
    store.setSelectedKnowledge(selectedKnowledgeIds.value)
    if (localConsultationName.value.trim() && sessions.currentId) {
      sessions.rename(sessions.currentId, localConsultationName.value.trim())
    }
    message.success('问诊设置已保存')
    open.value = false
  } catch (e) {
    console.error('Save consultation settings error:', e)
    message.error('保存失败：' + (e?.message || '未知错误'))
  } finally {
    saving.value = false
  }
}
</script>

<style scoped>
/* ── 医生卡片视图 ─────────────────────────────── */
.doctor-card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 12px;
  margin-bottom: 16px;
}

.doctor-card {
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  padding: 12px;
  background: #fff;
  transition: all 0.2s;
  cursor: default;
  position: relative;
  display: flex;
  gap: 8px;
}

.doctor-card:hover {
  border-color: #1890ff;
  box-shadow: 0 2px 8px rgba(24, 144, 255, 0.12);
}

.doctor-card-dragging {
  opacity: 0.5;
  border-style: dashed;
  border-color: #1890ff;
}

.doctor-card-drag-over {
  border-color: #52c41a;
  background: #f6ffed;
}

.doctor-card-drag-handle {
  display: flex;
  align-items: center;
  color: #bfbfbf;
  cursor: grab;
  font-size: 16px;
  padding: 4px 2px;
}

.doctor-card-drag-handle:active {
  cursor: grabbing;
}

.doctor-card-body {
  flex: 1;
  min-width: 0;
}

.doctor-card-header {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  margin-bottom: 8px;
}

.doctor-card-info {
  flex: 1;
  min-width: 0;
}

.doctor-card-name {
  font-weight: 600;
  font-size: 15px;
  color: #262626;
  margin-bottom: 2px;
}

.doctor-card-model {
  font-size: 12px;
  color: #1890ff;
  display: flex;
  align-items: center;
  gap: 4px;
}

.doctor-card-provider {
  font-size: 11px;
  color: #8c8c8c;
  display: flex;
  align-items: center;
  gap: 4px;
}

.doctor-card-status {
  flex-shrink: 0;
}

.doctor-card-desc {
  font-size: 12px;
  color: #8c8c8c;
  margin-bottom: 6px;
  line-height: 1.4;
}

.doctor-card-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-top: 1px solid #f0f0f0;
  padding-top: 6px;
  margin-top: 2px;
}

/* ── 关联问诊卡片视图 ─────────────────────────── */
.linked-card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 12px;
  margin-top: 12px;
}

.linked-card {
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  padding: 12px;
  background: #fff;
  transition: all 0.2s;
}

.linked-card:hover {
  border-color: #1890ff;
  box-shadow: 0 2px 8px rgba(24, 144, 255, 0.08);
}

.linked-card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 8px;
}

.linked-card-title {
  font-weight: 600;
  font-size: 14px;
  color: #262626;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.linked-card-patient {
  font-size: 12px;
  color: #595959;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  gap: 4px;
  flex-wrap: wrap;
}

.linked-card-summary {
  margin-bottom: 4px;
}

.linked-card-field {
  display: flex;
  gap: 4px;
  font-size: 12px;
  margin-bottom: 4px;
  line-height: 1.5;
}

.linked-card-label {
  color: #8c8c8c;
  flex-shrink: 0;
  min-width: 56px;
}

.linked-card-actions {
  display: flex;
  justify-content: flex-end;
  border-top: 1px solid #f0f0f0;
  padding-top: 4px;
}

/* ── 知识库选中摘要 ─────────────────────────── */
.selected-knowledge-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

/* ── 智能推荐标签 ─────────────────────────── */
.recommend-tag {
  cursor: pointer;
  user-select: none;
  padding: 2px 8px;
  border-radius: 4px;
}
</style>
