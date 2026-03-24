<template>
  <a-modal v-model:open="open" title="全局设置" width="960px" :footer="null" @cancel="open = false">
    <a-tabs v-model:activeKey="activeTab" class="settings-tabs">
      <!-- 医生配置 -->
      <a-tab-pane key="doctors" tab="医生配置">
        <div class="section-header">
          <a-space>
            <span class="section-icon">&#128137;</span>
            <span>医生配置列表</span>
          </a-space>
          <a-space>
            <a-button size="small" @click="sortDoctors('name')">
              <template #icon>&#8595;</template>按名称排序
            </a-button>
            <a-button size="small" @click="sortDoctors('provider')">
              <template #icon>&#8595;</template>按供应商排序
            </a-button>
            <a-upload :before-upload="handleDoctorImport" :show-upload-list="false" accept=".json">
              <a-button size="small">导入医生</a-button>
            </a-upload>
            <a-button size="small" @click="handleDoctorExport">导出医生</a-button>
          </a-space>
        </div>
        <a-alert type="info" show-icon message="提示" description="可添加多个由不同 LLM 驱动的医生。未填写 API Key 将使用模拟回复。" style="margin-bottom: 12px;" />

        <draggable v-model="localDoctors" item-key="id" handle=".drag-handle">
          <template #item="{ element, index }">
            <a-card size="small" class="doctor-card" style="margin-bottom: 10px;">
              <div class="doctor-card-header">
                <!-- 医生颜色标识 -->
                <div class="doctor-avatar" :style="{ backgroundColor: getDoctorColor(index) }">
                  {{ (element.name || 'D').charAt(0).toUpperCase() }}
                </div>
                <div class="doctor-card-title">
                  <span class="doctor-name">{{ element.name || '未命名医生' }}</span>
                  <a-tag :color="getProviderColor(element.provider)">{{ getProviderLabel(element.provider) }}</a-tag>
                  <span v-if="element.apiKey" class="status-dot active"></span>
                  <span v-else class="status-dot inactive"></span>
                </div>
                <div class="doctor-card-actions">
                  <a-tooltip title="拖动排序"><span class="drag-handle">&#8942;&#8942;</span></a-tooltip>
                  <a-button type="link" danger size="small" @click="removeDoctor(index)">删除</a-button>
                </div>
              </div>

              <a-row :gutter="[12, 0]">
                <a-col :span="8">
                  <a-form-item label="医生名称" size="small">
                    <a-input v-model:value="element.name" placeholder="Dr. GPT-4" />
                  </a-form-item>
                </a-col>
                <a-col :span="8">
                  <a-form-item label="供应商" size="small">
                    <a-select v-model:value="element.provider" :options="providerOptions" />
                  </a-form-item>
                </a-col>
                <a-col :span="8">
                  <a-form-item label="API Key" size="small">
                    <a-input-password v-model:value="element.apiKey" placeholder="sk-..." size="small" />
                  </a-form-item>
                </a-col>
              </a-row>

              <a-row :gutter="[12, 0]">
                <a-col :span="8">
                  <a-form-item label="自定义 Base URL" size="small">
                    <a-input
                      v-model:value="element.baseUrl"
                      :placeholder="element.provider === 'modelscope' ? 'DeepSeek/GLM 等填入服务商地址' : '留空使用默认地址'"
                      size="small"
                    />
                    <div v-if="element.provider === 'modelscope' && !element.baseUrl" style="font-size: 11px; color: #ff7a45; margin-top: 2px;">
                      提示：DeepSeek/GLM 等模型需填入对应服务商地址，否则可能调用失败
                    </div>
                  </a-form-item>
                </a-col>
                <a-col :span="16">
                  <a-form-item label="模型名称" size="small">
                    <div class="model-row">
                      <a-select
                        class="model-select"
                        v-model:value="element.model"
                        :options="modelOptions[element.id] || []"
                        show-search
                        :loading="loadingModel[element.id]"
                        placeholder="选择或输入模型"
                        allow-create
                        :filter-option="false"
                        style="flex:1"
                      />
                      <a-button :loading="loadingModel[element.id]" size="small" @click="loadModels(element)">加载</a-button>
                      <a-button :loading="!!testingDoctor[element.id]" size="small" @click="testDoctorModel(element)">测试</a-button>
                    </div>
                  </a-form-item>
                </a-col>
              </a-row>

              <a-form-item label="自定义提示词（可选）" size="small">
                <div class="prompt-row">
                  <a-select
                    v-model:value="selectedPreset[element.id]"
                    :options="presetPromptOptions"
                    style="flex:1"
                    placeholder="选择预设提示词"
                    allow-clear
                    size="small"
                    @change="(value) => handlePresetSelect(element, value)"
                  />
                </div>
                <a-textarea v-model:value="element.customPrompt" rows="2" placeholder="可手动输入或选择上方预设提示词" size="small" style="margin-top: 4px;" />
              </a-form-item>
            </a-card>
          </template>
        </draggable>

        <a-button type="dashed" block @click="addDoctor" size="small" style="margin-top: 4px;">+ 添加医生</a-button>
      </a-tab-pane>

      <!-- 医生预设提示词 -->
      <a-tab-pane key="presets" tab="医生预设">
        <div class="section-header">
          <a-space>
            <span class="section-icon">&#128221;</span>
            <span>医生预设提示词</span>
          </a-space>
        </div>
        <a-alert type="info" show-icon message="医生预设提示词" description="预设各主要科室医生的提示词模板，可在医生配置中快速引用并继续编辑。" style="margin-bottom: 12px;" />

        <draggable v-model="localPresetPrompts" item-key="id" handle=".drag-handle">
          <template #item="{ element }">
            <a-card size="small" style="margin-bottom: 8px;">
              <div class="preset-card-header">
                <span class="drag-handle" style="cursor:move; color:#999; font-size:18px; margin-right:8px;">&#8942;&#8942;</span>
                <a-input v-model:value="element.name" placeholder="预设名称" size="small" style="flex:1; font-weight:600;" />
                <a-popconfirm title="确认删除此预设？" @confirm="removePresetById(element.id)">
                  <a-button type="link" danger size="small">删除</a-button>
                </a-popconfirm>
              </div>
              <a-textarea v-model:value="element.prompt" rows="3" placeholder="撰写该科室医生的提示词" size="small" style="margin-top: 6px;" />
            </a-card>
          </template>
        </draggable>

        <a-button type="dashed" block @click="addPreset" size="small">+ 添加预设提示词</a-button>
      </a-tab-pane>

      <!-- 全局参数 -->
      <a-tab-pane key="globalSettings" tab="全局参数">
        <div class="section-header">
          <a-space>
            <span class="section-icon">&#9881;</span>
            <span>全局参数配置</span>
          </a-space>
        </div>
        <a-card size="small" style="margin-bottom: 12px;">
          <a-form layout="vertical" size="small">
            <a-form-item label="全局系统提示词">
              <a-textarea v-model:value="localSettings.globalSystemPrompt" rows="4" />
            </a-form-item>
            <a-form-item label="最终总结提示词（默认）">
              <a-textarea v-model:value="localSettings.summaryPrompt" rows="4" />
            </a-form-item>
          </a-form>
        </a-card>
        <a-card size="small" style="margin-bottom: 12px;">
          <a-form layout="vertical" size="small">
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
        </a-card>
      </a-tab-pane>

      <!-- 图片识别 -->
      <a-tab-pane key="imageRecognition" tab="图片识别">
        <div class="section-header">
          <a-space>
            <span class="section-icon">&#128247;</span>
            <span>图片识别配置</span>
          </a-space>
          <a-switch v-model:checked="localImageRecognition.enabled" checked-children="启用" un-checked-children="禁用" size="small" />
        </div>

        <template v-if="localImageRecognition.enabled">
          <a-alert type="info" show-icon message="配置说明" description="请选择支持图片识别的模型，并填写相应的 API Key。支持硅基流动和魔搭社区。" style="margin-bottom: 12px;" />

          <!-- SiliconFlow 配置 -->
          <a-card size="small" class="config-card" style="margin-bottom: 10px;">
            <template #title>
              <a-space>
                <span>&#9889;</span>
                <span>硅基流动 SiliconFlow</span>
                <a-tag v-if="localImageRecognition.provider === 'siliconflow'" color="blue">当前</a-tag>
              </a-space>
            </template>
            <a-row :gutter="[12, 0]">
              <a-col :span="12">
                <a-form-item label="API Key" size="small">
                  <a-input-password v-model:value="localImageRecognition.apiKey" placeholder="sk-..." size="small" />
                </a-form-item>
              </a-col>
              <a-col :span="12">
                <a-form-item label="自定义 Base URL" size="small">
                  <a-input v-model:value="localImageRecognition.baseUrl" placeholder="留空使用默认 https://api.siliconflow.cn" size="small" />
                </a-form-item>
              </a-col>
            </a-row>
            <a-row :gutter="[12, 0]">
              <a-col :span="16">
                <a-form-item label="模型名称" size="small">
                  <div class="model-row">
                    <a-select
                      style="flex:1"
                      v-model:value="localImageRecognition.model"
                      :options="imageModelOptions"
                      show-search
                      :loading="loadingImageModel"
                      placeholder="选择模型"
                      allow-create
                      :filter-option="false"
                      size="small"
                    />
                    <a-button :loading="loadingImageModel" size="small" @click="loadImageModels">加载</a-button>
                  </div>
                </a-form-item>
              </a-col>
              <a-col :span="8">
                <a-form-item label="最大并发数" size="small">
                  <a-input-number v-model:value="localImageRecognition.maxConcurrent" :min="1" :max="10" style="width:100%" size="small" />
                </a-form-item>
              </a-col>
            </a-row>
          </a-card>

          <!-- ModelScope 配置 -->
          <a-card size="small" class="config-card" style="margin-bottom: 10px;">
            <template #title>
              <a-space>
                <span>&#128640;</span>
                <span>魔搭社区 ModelScope</span>
                <a-tag v-if="localImageRecognition.provider === 'modelscope'" color="green">当前</a-tag>
              </a-space>
            </template>
            <a-row :gutter="[12, 0]">
              <a-col :span="12">
                <a-form-item label="API Key" size="small">
                  <a-input-password v-model:value="localImageRecognition.modelscopeApiKey" placeholder="魔搭 API Key" size="small" />
                </a-form-item>
              </a-col>
              <a-col :span="12">
                <a-form-item label="自定义 Base URL" size="small">
                  <a-input v-model:value="localImageRecognition.modelscopeBaseUrl" placeholder="留空使用默认 https://api.modelscope.cn" size="small" />
                </a-form-item>
              </a-col>
            </a-row>
            <a-row :gutter="[12, 0]">
              <a-col :span="16">
                <a-form-item label="模型名称" size="small">
                  <div class="model-row">
                    <a-select
                      style="flex:1"
                      v-model:value="localImageRecognition.modelscopeModel"
                      :options="modelscopeModelOptions"
                      show-search
                      :loading="loadingModelscopeModel"
                      placeholder="选择模型"
                      allow-create
                      :filter-option="false"
                      size="small"
                    />
                    <a-button :loading="loadingModelscopeModel" size="small" @click="loadModelscopeModels">加载</a-button>
                  </div>
                </a-form-item>
              </a-col>
            </a-row>
          </a-card>

          <!-- 统一配置 -->
          <a-card size="small" class="config-card" style="margin-bottom: 10px;">
            <template #title>
              <a-space>
                <span>&#128172;</span>
                <span>识别配置</span>
              </a-space>
            </template>
            <a-form-item label="图像识别提示词" size="small">
              <a-textarea v-model:value="localImageRecognition.prompt" rows="3" placeholder="描述图像识别的需求..." />
            </a-form-item>
            <a-form-item label="测试连接" size="small">
              <div class="test-row">
                <a-upload :before-upload="handleTestImageUpload" :show-upload-list="false" accept="image/*">
                  <a-button size="small">
                    <span>&#128247;</span> 选择测试图片
                  </a-button>
                </a-upload>
                <div v-if="testImage" class="test-thumb">
                  <img :src="testImage.preview" alt="预览" />
                  <a-button type="link" danger size="small" @click="removeTestImage">移除</a-button>
                </div>
                <a-button type="primary" :loading="testingImageAPI" @click="testImageAPI" size="small">
                  测试图像识别
                </a-button>
                <a-button :loading="testingSiliconFlow" @click="testSiliconFlowConnection" size="small">
                  测试 SiliconFlow 连接
                </a-button>
                <a-button :loading="testingModelscope" @click="testModelscopeConnection" size="small">
                  测试 ModelScope 连接
                </a-button>
              </div>
              <div v-if="testResult" class="test-result" :class="testResult.type">
                <strong>{{ testResult.type === 'success' ? '成功' : '失败' }}：</strong>{{ testResult.message }}
              </div>
            </a-form-item>
          </a-card>
        </template>

        <a-alert v-else type="warning" show-icon message="图片识别已禁用" description="开启上方开关以启用图片识别功能。" />
      </a-tab-pane>

      <!-- 导入导出 -->
      <a-tab-pane key="importExport" tab="导入导出">
        <div class="section-header">
          <a-space>
            <span class="section-icon">&#128194;</span>
            <span>导入 / 导出配置</span>
          </a-space>
        </div>
        <a-row :gutter="12">
          <a-col :span="12">
            <a-card size="small" class="action-card">
              <template #title><span>&#128228;</span> 导出设置</template>
              <a-alert type="info" show-icon message="导出设置" description="选择要导出的配置项，导出为 JSON 文件。" style="margin-bottom: 12px;" />
              <a-checkbox-group v-model:value="exportSelection" style="width: 100%">
                <a-space direction="vertical" style="width: 100%">
                  <a-checkbox value="doctors">医生配置</a-checkbox>
                  <a-checkbox value="presetPrompts">医生预设提示词</a-checkbox>
                  <a-checkbox value="settings">全局设置</a-checkbox>
                  <a-checkbox value="imageRecognition">图片识别</a-checkbox>
                </a-space>
              </a-checkbox-group>
              <a-button type="primary" @click="handleExport" :disabled="exportSelection.length === 0" block style="margin-top: 12px;">
                导出选中项
              </a-button>
            </a-card>
          </a-col>
          <a-col :span="12">
            <a-card size="small" class="action-card">
              <template #title><span>&#128229;</span> 导入设置</template>
              <a-alert type="info" show-icon message="导入设置" description="选择 JSON 文件导入配置，将自动覆盖现有配置。" style="margin-bottom: 12px;" />
              <a-upload :before-upload="handleImport" :show-upload-list="false" accept=".json">
                <a-button type="primary" block>
                  <span>&#128193;</span> 选择 JSON 文件导入
                </a-button>
              </a-upload>
            </a-card>
          </a-col>
        </a-row>
      </a-tab-pane>

      <!-- 系统信息 -->
      <a-tab-pane key="system" tab="系统信息">
        <div class="section-header">
          <a-space>
            <span class="section-icon">&#128737;</span>
            <span>系统信息</span>
          </a-space>
        </div>

        <!-- 版本信息 -->
        <a-card size="small" class="info-card" style="margin-bottom: 10px;">
          <template #title>
            <a-space><span>&#128196;</span> 版本信息</a-space>
          </template>
          <a-descriptions :column="2" size="small">
            <a-descriptions-item label="应用名称">{{ appInfo.name }}</a-descriptions-item>
            <a-descriptions-item label="版本号">{{ appInfo.version }}</a-descriptions-item>
            <a-descriptions-item label="前端框架">Vue 3 + Pinia</a-descriptions-item>
            <a-descriptions-item label="UI 组件库">Ant Design Vue 4</a-descriptions-item>
          </a-descriptions>
        </a-card>

        <!-- 本地存储 -->
        <a-card size="small" class="info-card" style="margin-bottom: 10px;">
          <template #title>
            <a-space><span>&#128190;</span> 本地存储</a-space>
          </template>
          <div class="storage-info">
            <div class="storage-bar">
              <div class="storage-used" :style="{ width: storagePercent + '%' }"></div>
              <div class="storage-label">{{ storageUsedStr }} / {{ storageTotalStr }}</div>
            </div>
            <div class="storage-details">
              <div v-for="item in storageDetails" :key="item.key" class="storage-item">
                <span class="storage-key">{{ item.key }}</span>
                <span class="storage-val">{{ item.size }}</span>
              </div>
            </div>
          </div>
          <div style="margin-top: 12px;">
            <a-popconfirm title="确认清理？此操作不可恢复。" @confirm="clearStorage">
              <a-button danger size="small">一键清理全部数据</a-button>
            </a-popconfirm>
            <a-popconfirm title="确认清理？将删除所有本地问诊记录。" @confirm="clearConsultData">
              <a-button danger size="small" style="margin-left: 8px;">清理问诊记录</a-button>
            </a-popconfirm>
            <a-popconfirm title="确认清理？将删除所有上传的文档。" @confirm="clearDocuments">
              <a-button danger size="small" style="margin-left: 8px;">清理上传文档</a-button>
            </a-popconfirm>
          </div>
        </a-card>

        <!-- 关于 -->
        <a-card size="small" class="info-card">
          <template #title>
            <a-space><span>&#8505;</span> 关于 AstraCare</a-space>
          </template>
          <p style="color:#666; font-size:13px; margin-bottom: 0;">
            AstraCare 是一个纯前端的多医生 AI 会诊模拟平台，支持多模型配置、知识库检索、图片识别等功能。
            所有配置数据均存储在浏览器本地，不会上传至任何服务器。
          </p>
        </a-card>
      </a-tab-pane>
    </a-tabs>

    <!-- 底部保存按钮 -->
    <div class="modal-footer">
      <a-button @click="open = false">取消</a-button>
      <a-button type="primary" @click="onSave">保存设置</a-button>
    </div>
  </a-modal>
</template>

<script setup>
import { ref, watch, computed, h, resolveComponent, nextTick } from 'vue'
import draggable from 'vuedraggable'
import { useConsultStore } from '../store'
import { useGlobalStore } from '../store/global'
import { message, Modal } from 'ant-design-vue'
import { callAI } from '../api/callAI'
import { listModels } from '../api/models'
import { recognizeImageWithSiliconFlow } from '../api/imageRecognition'

const store = useConsultStore()
const global = useGlobalStore()

const props = defineProps({ open: { type: Boolean, default: false } })
const emit = defineEmits(['update:open'])

const open = ref(props.open)
const activeTab = ref('doctors')

watch(() => props.open, (v) => (open.value = v))
watch(open, (v) => emit('update:open', v))

// --- 版本信息 ---
const appInfo = {
  name: 'AstraCare',
  version: '0.1.0'
}

// --- 存储信息 ---
const storageDetails = ref([])
const storageUsed = ref(0)
const storageTotalStr = '约 5MB'
const storagePercent = computed(() => Math.min(100, (storageUsed.value / (5 * 1024 * 1024)) * 100))
const storageUsedStr = computed(() => {
  if (storageUsed.value < 1024) return storageUsed.value + ' B'
  if (storageUsed.value < 1024 * 1024) return (storageUsed.value / 1024).toFixed(1) + ' KB'
  return (storageUsed.value / 1024 / 1024).toFixed(2) + ' MB'
})

function calcStorage() {
  let total = 0
  const details = []
  const keys = [
    { key: '全局医生配置', name: 'global_doctors_config' },
    { key: '图片识别配置', name: 'global_image_recognition_config' },
    { key: '医生预设提示词', name: 'global_preset_prompts' },
    { key: '问诊设置', name: 'consult_settings' },
    { key: '问诊状态', name: 'consult_state' },
    { key: '问诊记录', name: 'consult_discussions' },
    { key: '知识库配置', name: 'knowledge_base_config' },
    { key: '知识库文档', name: 'knowledge_base_documents' }
  ]
  keys.forEach(({ key, name }) => {
    try {
      const raw = localStorage.getItem(name)
      if (raw) {
        const bytes = raw.length * 2 // UTF-16
        total += bytes
        details.push({ key, size: bytes < 1024 ? bytes + ' B' : (bytes / 1024).toFixed(1) + ' KB' })
      }
    } catch (e) {}
  })
  storageUsed.value = total
  storageDetails.value = details
}

function clearStorage() {
  Modal.confirm({
    title: '确认清理全部数据？',
    content: '这将删除所有本地存储的配置、问诊记录等数据，此操作不可恢复。',
    okText: '确认清理',
    okType: 'danger',
    onOk() {
      localStorage.clear()
      message.success('已清理全部本地数据，页面将刷新')
      setTimeout(() => location.reload(), 800)
    }
  })
}

function clearConsultData() {
  const keys = ['consult_state', 'consult_discussions', 'consult_settings']
  keys.forEach((k) => localStorage.removeItem(k))
  message.success('问诊记录已清理')
  calcStorage()
}

function clearDocuments() {
  localStorage.removeItem('knowledge_base_documents')
  message.success('上传文档已清理')
  calcStorage()
}

// --- 医生配置 ---
const providerOptions = [
  { label: 'OpenAI', value: 'openai' },
  { label: 'Anthropic', value: 'anthropic' },
  { label: 'Gemini', value: 'gemini' },
  { label: '硅基流动', value: 'siliconflow' },
  { label: '魔搭社区', value: 'modelscope' }
]

const DOCTOR_COLORS = [
  '#1890ff', '#52c41a', '#faad14', '#f5222d', '#722ed1',
  '#13c2c2', '#eb2f96', '#fa8c16', '#a0d911', '#2f54eb'
]

function getDoctorColor(idx) {
  return DOCTOR_COLORS[idx % DOCTOR_COLORS.length]
}

function getProviderColor(provider) {
  const map = {
    openai: '#10a37f', anthropic: '#d97706', gemini: '#4285f4',
    siliconflow: '#6f42c1', modelscope: '#11a863'
  }
  return map[provider] || '#999'
}

function getProviderLabel(provider) {
  return providerOptions.find((p) => p.value === provider)?.label || provider
}

const localDoctors = ref([])
const localSettings = ref({})
const localImageRecognition = ref({})
const localPresetPrompts = ref([])
const selectedPreset = ref({})
const modelOptions = ref({})
const loadingModel = ref({})
const testingDoctor = ref({})
const testingImageAPI = ref(false)
const testingSiliconFlow = ref(false)
const testingModelscope = ref(false)
const testImage = ref(null)
const exportSelection = ref([])
const testResult = ref(null)

// ModelScope 专用
const modelscopeModelOptions = ref([])
const loadingModelscopeModel = ref(false)

watch(
  () => props.open,
  (v) => {
    if (v) {
      activeTab.value = 'doctors'
      localDoctors.value = JSON.parse(JSON.stringify(global.doctors))
      localSettings.value = JSON.parse(JSON.stringify(store.settings))
      localImageRecognition.value = {
        maxConcurrent: 1,
        ...JSON.parse(JSON.stringify(global.imageRecognition || {}))
      }
      localPresetPrompts.value = JSON.parse(JSON.stringify(global.presetPrompts || []))
      selectedPreset.value = {}
      modelOptions.value = {}
      loadingModel.value = {}
      testingDoctor.value = {}
      imageModelOptions.value = []
      loadingImageModel.value = false
      testingImageAPI.value = false
      testingSiliconFlow.value = false
      testingModelscope.value = false
      testImage.value = null
      exportSelection.value = []
      testResult.value = null
      modelscopeModelOptions.value = []
      calcStorage()
    }
  }
)

const presetPromptOptions = computed(() => {
  return (localPresetPrompts.value || []).map((p) => ({
    label: p.name || '未命名预设',
    value: p.id
  }))
})

// --- 医生排序 ---
function sortDoctors(by) {
  localDoctors.value.sort((a, b) => {
    if (by === 'name') return (a.name || '').localeCompare(b.name || '')
    if (by === 'provider') return (a.provider || '').localeCompare(b.provider || '')
    return 0
  })
}

function addDoctor() {
  const id = `doc-${Date.now()}-${Math.random().toString(16).slice(2, 6)}`
  localDoctors.value.push({ id, name: '', provider: 'openai', model: 'gpt-4o-mini', apiKey: '', baseUrl: '', customPrompt: '' })
}

function removeDoctor(idx) {
  const target = localDoctors.value[idx]
  if (target) {
    const copy = { ...selectedPreset.value }
    delete copy[target.id]
    selectedPreset.value = copy
  }
  localDoctors.value.splice(idx, 1)
}

function handlePresetSelect(doctor, presetId) {
  if (!presetId) {
    const copy = { ...selectedPreset.value }
    delete copy[doctor?.id]
    selectedPreset.value = copy
    return
  }
  const preset = (localPresetPrompts.value || []).find((p) => p.id === presetId)
  if (!preset) { message.warning('所选预设不存在'); return }
  doctor.customPrompt = preset.prompt || ''
  message.success(`已应用预设提示词：${preset.name || '未命名预设'}`)
  const copy = { ...selectedPreset.value }
  delete copy[doctor.id]
  selectedPreset.value = copy
}

function addPreset() {
  const id = `preset-${Date.now()}-${Math.random().toString(16).slice(2, 6)}`
  localPresetPrompts.value.push({ id, name: '', prompt: '' })
}

function removePresetById(id) {
  const idx = localPresetPrompts.value.findIndex((p) => p.id === id)
  if (idx !== -1) {
    const removed = localPresetPrompts.value[idx]
    localPresetPrompts.value.splice(idx, 1)
    const copy = { ...selectedPreset.value }
    Object.keys(copy).forEach((doctorId) => {
      if (copy[doctorId] === removed.id) delete copy[doctorId]
    })
    selectedPreset.value = copy
  }
}

// --- 模型加载与测试 ---
async function loadModels(element) {
  const id = element.id
  loadingModel.value = { ...loadingModel.value, [id]: true }
  try {
    const options = await listModels(element.provider, element.apiKey, element.baseUrl)
    modelOptions.value = { ...modelOptions.value, [id]: options }
    message.success('模型列表已加载')
  } catch (e) {
    message.error(`加载模型失败：${e?.message || e}`)
  } finally {
    loadingModel.value = { ...loadingModel.value, [id]: false }
  }
}

async function testDoctorModel(element) {
  const id = element.id
  testingDoctor.value = { ...testingDoctor.value, [id]: true }
  try {
    const doctor = { id, name: element.name || id, provider: element.provider, model: element.model, apiKey: element.apiKey, baseUrl: element.baseUrl }
    const reply = await callAI(doctor, { system: 'You are a connection test bot.', user: '请回复：OK' }, [])
    const preview = String(reply || '').slice(0, 80)
    message.success(`模型可用，返回: ${preview || 'OK'}`)
  } catch (e) {
    message.error(`调用失败：${e?.message || e}`)
  } finally {
    testingDoctor.value = { ...testingDoctor.value, [id]: false }
  }
}

// --- 医生导入导出 ---
function handleDoctorImport(file) {
  const reader = new FileReader()
  reader.onload = (e) => {
    try {
      const data = JSON.parse(e.target.result)
      if (Array.isArray(data)) {
        const sanitized = data.map((d, i) => ({
          id: d.id || `doc-import-${Date.now()}-${i}`,
          name: d.name || '',
          provider: d.provider || 'openai',
          model: d.model || '',
          apiKey: d.apiKey || '',
          baseUrl: d.baseUrl || '',
          customPrompt: d.customPrompt || ''
        }))
        localDoctors.value = sanitized
        message.success(`已导入 ${sanitized.length} 个医生配置`)
      } else {
        message.warning('文件格式不正确，应为数组')
      }
    } catch {
      message.error('读取文件失败')
    }
  }
  reader.readAsText(file)
  return false
}

function handleDoctorExport() {
  const data = localDoctors.value.map((d) => ({
    name: d.name, provider: d.provider, model: d.model,
    apiKey: d.apiKey, baseUrl: d.baseUrl, customPrompt: d.customPrompt
  }))
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `doctors-export-${new Date().toISOString().slice(0, 10)}.json`
  a.click()
  URL.revokeObjectURL(url)
  message.success('医生配置已导出')
}

// --- 图片模型 ---
const imageModelOptions = ref([])
const loadingImageModel = ref(false)

async function loadImageModels() {
  if (!localImageRecognition.value.apiKey) { message.warning('请先填写 SiliconFlow API Key'); return }
  loadingImageModel.value = true
  try {
    const options = await listModels(localImageRecognition.value.provider, localImageRecognition.value.apiKey, localImageRecognition.value.baseUrl)
    imageModelOptions.value = options
    message.success('图像识别模型列表已加载')
  } catch (e) {
    message.error(`加载失败：${e?.message || e}`)
  } finally {
    loadingImageModel.value = false
  }
}

async function loadModelscopeModels() {
  if (!localImageRecognition.value.modelscopeApiKey) { message.warning('请先填写魔搭 API Key'); return }
  loadingModelscopeModel.value = true
  try {
    const options = await listModels('modelscope', localImageRecognition.value.modelscopeApiKey, localImageRecognition.value.modelscopeBaseUrl)
    modelscopeModelOptions.value = options
    message.success('魔搭模型列表已加载')
  } catch (e) {
    message.error(`加载失败：${e?.message || e}`)
  } finally {
    loadingModelscopeModel.value = false
  }
}

async function testSiliconFlowConnection() {
  if (!localImageRecognition.value.apiKey) { message.warning('请先填写 SiliconFlow API Key'); return }
  testingSiliconFlow.value = true
  testResult.value = null
  try {
    await listModels('siliconflow', localImageRecognition.value.apiKey, localImageRecognition.value.baseUrl)
    testResult.value = { type: 'success', message: 'SiliconFlow 连接成功，API Key 有效' }
    message.success('SiliconFlow 连接成功')
  } catch (e) {
    testResult.value = { type: 'error', message: e?.message || '连接失败' }
    message.error(`SiliconFlow 连接失败：${e?.message || e}`)
  } finally {
    testingSiliconFlow.value = false
  }
}

async function testModelscopeConnection() {
  const key = localImageRecognition.value.modelscopeApiKey
  if (!key) { message.warning('请先填写魔搭 API Key'); return }
  testingModelscope.value = true
  testResult.value = null
  try {
    await listModels('modelscope', key, localImageRecognition.value.modelscopeBaseUrl)
    testResult.value = { type: 'success', message: 'ModelScope 连接成功，API Key 有效' }
    message.success('ModelScope 连接成功')
  } catch (e) {
    testResult.value = { type: 'error', message: e?.message || '连接失败' }
    message.error(`ModelScope 连接失败：${e?.message || e}`)
  } finally {
    testingModelscope.value = false
  }
}

async function handleTestImageUpload(file) {
  try {
    const reader = new FileReader()
    reader.onload = (e) => {
      const fullData = e.target.result
      let base64Only = fullData
      if (typeof fullData === 'string') {
        const parts = fullData.split(',')
        base64Only = parts.length > 1 ? parts[1] : parts[0]
      }
      testImage.value = { name: file.name, preview: fullData, base64: base64Only }
      message.success(`已选择测试图片：${file.name}`)
    }
    reader.readAsDataURL(file)
  } catch { message.error('读取图片失败') }
  return false
}

function removeTestImage() { testImage.value = null }

async function testImageAPI() {
  if (!localImageRecognition.value.apiKey) { message.warning('请先填写 API Key'); return }
  if (!localImageRecognition.value.model) { message.warning('请先选择模型'); return }
  testingImageAPI.value = true
  testResult.value = null
  try {
    const defaultTestImage = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
    const imageBase64 = testImage.value?.base64 || defaultTestImage
    const result = await recognizeImageWithSiliconFlow({
      apiKey: localImageRecognition.value.apiKey,
      baseUrl: localImageRecognition.value.baseUrl,
      model: localImageRecognition.value.model,
      prompt: localImageRecognition.value.prompt || '请描述这张图片',
      imageBase64
    })
    testResult.value = { type: 'success', message: String(result).slice(0, 120) }
    message.success('图像识别测试成功')
  } catch (e) {
    testResult.value = { type: 'error', message: e?.message || '测试失败' }
    message.error(`测试失败：${e?.message || e}`)
  } finally {
    testingImageAPI.value = false
  }
}

// --- 导入导出 ---
function handleExport() {
  if (exportSelection.value.length === 0) { message.warning('请至少选择一项'); return }
  const exportData = {}
  if (exportSelection.value.includes('doctors')) exportData.doctors = localDoctors.value
  if (exportSelection.value.includes('presetPrompts')) exportData.presetPrompts = localPresetPrompts.value
  if (exportSelection.value.includes('settings')) exportData.settings = localSettings.value
  if (exportSelection.value.includes('imageRecognition')) exportData.imageRecognition = localImageRecognition.value
  const blob = new Blob([JSON.stringify(exportData, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `astracare-settings-${new Date().toISOString().slice(0, 10)}.json`
  a.click()
  URL.revokeObjectURL(url)
  message.success('设置已导出')
}

function handleImport(file) {
  const reader = new FileReader()
  reader.onload = (e) => {
    try {
      const data = JSON.parse(e.target.result)
      const imported = []
      if (data.doctors) { localDoctors.value = JSON.parse(JSON.stringify(data.doctors)); imported.push('医生配置') }
      if (data.presetPrompts) { localPresetPrompts.value = JSON.parse(JSON.stringify(data.presetPrompts)); imported.push('医生预设提示词') }
      if (data.settings) { localSettings.value = { ...localSettings.value, ...data.settings }; imported.push('全局设置') }
      if (data.imageRecognition) {
        localImageRecognition.value = { maxConcurrent: 1, ...JSON.parse(JSON.stringify(data.imageRecognition)) }
        imported.push('图片识别')
      }
      if (imported.length) message.success(`已导入：${imported.join('、')}`)
      else message.warning('无有效配置项')
    } catch { message.error('导入失败：文件格式不正确') }
  }
  reader.readAsText(file)
  return false
}

// --- 保存 ---
function onSave() {
  global.setDoctors(localDoctors.value)
  global.setPresetPrompts(localPresetPrompts.value)
  global.setImageRecognition(localImageRecognition.value)
  store.setSettings(localSettings.value)
  calcStorage()
  message.success('已保存全局设置')
  open.value = false
}
</script>

<style scoped>
.settings-tabs :deep(.ant-tabs-nav) {
  margin-bottom: 8px;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
  font-weight: 600;
  font-size: 14px;
}

.section-icon {
  font-size: 16px;
}

/* 医生卡片 */
.doctor-card {
  border-left: 3px solid #1890ff;
}
.doctor-card-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}
.doctor-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 16px;
  font-weight: 700;
  flex-shrink: 0;
}
.doctor-card-title {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}
.doctor-name {
  font-weight: 600;
  font-size: 14px;
}
.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}
.status-dot.active { background: #52c41a; }
.status-dot.inactive { background: #d9d9d9; }
.doctor-card-actions {
  display: flex;
  align-items: center;
  gap: 4px;
}
.drag-handle {
  cursor: move;
  font-size: 18px;
  color: #999;
  user-select: none;
  padding: 0 2px;
}

/* 模型行 */
.model-row {
  display: flex;
  gap: 6px;
  align-items: center;
}

/* 提示词行 */
.prompt-row {
  margin-bottom: 4px;
}

/* 配置卡片 */
.config-card :deep(.ant-card-head) {
  min-height: 36px;
  padding: 0 12px;
  font-size: 13px;
}
.config-card :deep(.ant-card-head-title) {
  padding: 6px 0;
}
.config-card :deep(.ant-card-body) {
  padding: 12px;
}

/* 测试行 */
.test-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.test-thumb {
  display: flex;
  align-items: center;
  gap: 4px;
}
.test-thumb img {
  width: 36px;
  height: 36px;
  object-fit: cover;
  border-radius: 4px;
  border: 1px solid #f0f0f0;
}
.test-result {
  margin-top: 6px;
  padding: 6px 10px;
  border-radius: 4px;
  font-size: 12px;
  word-break: break-all;
}
.test-result.success {
  background: #f6ffed;
  border: 1px solid #b7eb8f;
  color: #52c41a;
}
.test-result.error {
  background: #fff2f0;
  border: 1px solid #ffccc7;
  color: #f5222d;
}

/* 导入导出卡片 */
.action-card :deep(.ant-card-head) {
  min-height: 36px;
  font-size: 13px;
}

/* 系统信息卡片 */
.info-card :deep(.ant-card-head) {
  min-height: 36px;
  font-size: 13px;
}

/* 存储信息 */
.storage-info { }
.storage-bar {
  position: relative;
  height: 20px;
  background: #f0f0f0;
  border-radius: 10px;
  overflow: hidden;
  margin-bottom: 8px;
}
.storage-used {
  height: 100%;
  background: linear-gradient(90deg, #1890ff, #52c41a);
  border-radius: 10px;
  transition: width 0.3s;
}
.storage-label {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  color: #fff;
  text-shadow: 0 1px 2px rgba(0,0,0,0.4);
}
.storage-details {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 4px;
}
.storage-item {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  padding: 2px 6px;
  background: #fafafa;
  border-radius: 3px;
}
.storage-key { color: #666; }
.storage-val { color: #333; font-weight: 500; }

/* 底部保存 */
.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding-top: 12px;
  border-top: 1px solid #f0f0f0;
  margin-top: 4px;
}

/* 表单项紧凑 */
:deep(.ant-form-item) { margin-bottom: 10px; }
:deep(.ant-form-item-label) { padding-bottom: 2px; }
:deep(.ant-form-item-label > label) { font-size: 12px; color: #666; }

/* 通用 */
:deep(.ant-card-size-small) { border-radius: 6px; }
:deep(.ant-tabs-tab) { font-size: 13px; }
:deep(.ant-alert) { border-radius: 6px; }

.model-select :deep(.ant-select-selector) {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
