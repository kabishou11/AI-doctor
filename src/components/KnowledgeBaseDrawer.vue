<template>
  <a-drawer
    :open="open"
    title="知识库管理"
    width="900px"
    @close="emit('update:open', false)"
    destroy-on-close
  >
    <div class="kb-layout">
      <div class="kb-left">
        <div class="kb-toolbar">
          <a-input-search v-model:value="query" placeholder="搜索标题/内容/标签" @search="handleSearch" allow-clear />
          <a-select
            v-model:value="selectedTags"
            mode="multiple"
            allow-clear
            :options="tagOptions"
            placeholder="按标签筛选（可多选）"
          />
          <div class="kb-actions">
            <a-button type="primary" @click="createDoc">新建文档</a-button>
            <a-upload :before-upload="handleFileUpload" :show-upload-list="false" accept=".txt,.md,.pdf,.docx,.csv">
              <a-button>上传文档</a-button>
            </a-upload>
            <a-dropdown>
              <template #overlay>
                <a-menu>
                  <a-menu-item key="export" @click="handleExport">导出 JSON</a-menu-item>
                  <a-menu-item key="import">
                    <a-upload :before-upload="handleImport" :show-upload-list="false" accept=".json">
                      <span>导入 JSON</span>
                    </a-upload>
                  </a-menu-item>
                </a-menu>
              </template>
              <a-button>导入/导出</a-button>
            </a-dropdown>
          </div>
        </div>
        <div class="kb-list" v-if="filtered.length">
          <a-list :data-source="filtered" bordered item-layout="horizontal">
            <template #renderItem="{ item }">
              <a-list-item
                :class="['kb-item', { active: item.id === selectedId }]"
                @click="select(item.id)"
              >
                <a-list-item-meta
                  :title="item.title || '未命名'"
                  :description="item.excerpt || (item.content || '').slice(0, 80)"
                />
                <template #actions>
                  <span class="kb-time">{{ formatTime(item.updatedAt) }}</span>
                </template>
              </a-list-item>
            </template>
          </a-list>
        </div>
        <a-empty v-else description="暂无数据" />
      </div>
      <div class="kb-right" v-if="editing">
        <a-form layout="vertical">
          <a-alert type="info" show-icon message="向量设置" description="使用魔搭社区 embedding 生成向量后，检索会基于相似度 Top-K 注入问诊提示词。" style="margin-bottom: 8px;" />
          <a-row :gutter="8" class="kb-embed-row">
            <a-col :span="8">
              <a-form-item label="Embedding 模型">
                <div class="kb-embed-controls">
                  <a-input v-model:value="embeddingConfig.model" placeholder="手动输入魔搭向量模型ID，如 text-embedding-v3" />
                  <a-button size="small" :loading="testingEmbedding" @click="testEmbedding">测试调用</a-button>
                </div>
              </a-form-item>
            </a-col>
            <a-col :span="8">
              <a-form-item label="API Key">
                <a-input-password v-model:value="embeddingConfig.apiKey" placeholder="sk-..." />
              </a-form-item>
            </a-col>
            <a-col :span="8">
              <a-form-item label="Base URL（可选）">
                <a-input v-model:value="embeddingConfig.baseUrl" placeholder="留空使用默认 dashscope" />
              </a-form-item>
            </a-col>
          </a-row>
          <a-row :gutter="8" class="kb-embed-row">
            <a-col :span="8">
              <a-form-item label="Top-K">
                <a-input-number v-model:value="retrievalConfig.topK" :min="1" :max="10" style="width: 100%;" />
              </a-form-item>
            </a-col>
            <a-col :span="8">
              <a-form-item label="关键词权重 (0-1)">
                <a-input-number v-model:value="retrievalConfig.keywordWeight" :min="0" :max="1" :step="0.1" style="width: 100%;" />
              </a-form-item>
            </a-col>
            <a-col :span="8">
              <a-form-item label="上传后自动向量化">
                <a-switch v-model:checked="autoVectorize" />
              </a-form-item>
            </a-col>
          </a-row>
          <a-form-item label="标题">
            <a-input v-model:value="editing.title" placeholder="输入标题" />
          </a-form-item>
          <a-form-item label="标签（逗号分隔）">
            <a-input v-model:value="tagInput" placeholder="心内, 高血压, 指南" />
          </a-form-item>
          <a-form-item label="摘要（可选，用于提示词简述）">
            <a-textarea v-model:value="editing.excerpt" rows="3" placeholder="简要写要点或小结" />
          </a-form-item>
          <a-form-item label="正文内容">
            <a-textarea v-model:value="editing.content" rows="12" placeholder="输入正文，可粘贴指南/流程/经验" />
          </a-form-item>
          <div class="kb-form-actions">
            <a-space>
              <a-button type="primary" @click="saveDoc">保存</a-button>
              <a-button @click="vectorizeDoc" :loading="vectorizing">生成向量</a-button>
              <a-popconfirm title="确认删除？" @confirm="removeDoc">
                <a-button danger>删除</a-button>
              </a-popconfirm>
            </a-space>
            <div class="kb-meta">
              <span v-if="editing.updatedAt">更新：{{ formatTime(editing.updatedAt) }}</span>
            </div>
          </div>
        </a-form>
      </div>
      <div class="kb-right" v-else>
        <a-empty description="请选择左侧文档或新建" />
      </div>
    </div>
  </a-drawer>
</template>

<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { message, Modal } from 'ant-design-vue'
import { useKnowledgeStore } from '../store/knowledge'
import { parseFileToText } from '../utils/textParser'
import { embedWithModelScope } from '../api/embeddings'

const props = defineProps({ open: { type: Boolean, default: false } })
const emit = defineEmits(['update:open'])

const store = useKnowledgeStore()
const query = ref('')
const selectedTags = ref([])
const selectedId = ref('')
const editing = reactive({
  id: '',
  title: '',
  tags: [],
  content: '',
  excerpt: '',
  updatedAt: ''
})
const tagInput = ref('')
const vectorizing = ref(false)
const embeddingConfig = reactive({
  model: store.embeddingConfig?.model || 'text-embedding-v3',
  apiKey: store.embeddingConfig?.apiKey || '',
  baseUrl: store.embeddingConfig?.baseUrl || ''
})
const retrievalConfig = reactive({
  topK: store.retrievalConfig?.topK || 5,
  keywordWeight: store.retrievalConfig?.keywordWeight ?? 0.5
})
const autoVectorize = ref(true)
const testingEmbedding = ref(false)

watch(
  () => props.open,
  (v) => {
    if (v) {
      query.value = ''
      selectedId.value = store.docs[0]?.id || ''
      loadSelected()
      embeddingConfig.model = store.embeddingConfig?.model || 'text-embedding-v3'
      embeddingConfig.apiKey = store.embeddingConfig?.apiKey || ''
      embeddingConfig.baseUrl = store.embeddingConfig?.baseUrl || ''
      retrievalConfig.topK = store.retrievalConfig?.topK || 5
      retrievalConfig.keywordWeight = store.retrievalConfig?.keywordWeight ?? 0.5
    }
  }
)

function handleSearch() {
  // computed handles filter
}

const tagOptions = computed(() => {
  const all = new Set()
  ;(store.docs || []).forEach((d) => (d.tags || []).forEach((t) => all.add(t)))
  return Array.from(all).map((t) => ({ label: t, value: t }))
})
const filtered = computed(() => store.search(query.value, selectedTags.value))

function select(id) {
  selectedId.value = id
  loadSelected()
}

function loadSelected() {
  const doc = store.docMap.get(selectedId.value)
  if (!doc) {
    resetEditing()
    return
  }
  editing.id = doc.id
  editing.title = doc.title
  editing.tags = doc.tags || []
  editing.content = doc.content || ''
  editing.excerpt = doc.excerpt || ''
  editing.updatedAt = doc.updatedAt
  tagInput.value = (doc.tags || []).join(', ')
}

function resetEditing() {
  editing.id = ''
  editing.title = ''
  editing.tags = []
  editing.content = ''
  editing.excerpt = ''
  editing.updatedAt = ''
  tagInput.value = ''
}

function createDoc() {
  const id = store.addDoc({ title: '未命名文档', content: '' })
  selectedId.value = id
  loadSelected()
}

function saveDoc() {
  if (!editing.id) return
  const tags = tagInput.value
    .split(',')
    .map((t) => t.trim())
    .filter(Boolean)
  store.updateDoc(editing.id, { ...editing, tags })
  store.setEmbeddingConfig(embeddingConfig)
  store.setRetrievalConfig(retrievalConfig)
  message.success('已保存')
  loadSelected()
}

async function vectorizeDoc() {
  if (!editing.id) return
  try {
    vectorizing.value = true
    store.setEmbeddingConfig(embeddingConfig)
    store.setRetrievalConfig(retrievalConfig)
    const count = await store.reembedDoc(editing.id)
    message.success(`已生成向量，切片数：${count}`)
  } catch (err) {
    message.error(err?.message || '生成向量失败')
  } finally {
    vectorizing.value = false
  }
}

function removeDoc() {
  if (!editing.id) return
  const id = editing.id
  store.removeDoc(id)
  message.success('已删除')
  selectedId.value = store.docs[0]?.id || ''
  loadSelected()
}

function handleExport() {
  const jsonStr = store.exportData()
  const blob = new Blob([jsonStr], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = 'knowledge-export.json'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
  message.success('已导出')
}

function handleImport(file) {
  const reader = new FileReader()
  reader.onload = (e) => {
    try {
      store.importData(e.target.result)
      message.success('导入成功')
      if (!selectedId.value && store.docs[0]) {
        selectedId.value = store.docs[0].id
      }
      loadSelected()
    } catch (err) {
      Modal.error({ title: '导入失败', content: err?.message || '文件无效' })
    }
  }
  reader.readAsText(file)
  return false
}

async function handleFileUpload(file) {
  try {
    const text = await parseFileToText(file)
    const title = file.name.replace(/\.[^/.]+$/, '')
    store.setEmbeddingConfig(embeddingConfig)
    store.setRetrievalConfig(retrievalConfig)
    const id = await store.ingestDocument({ title, content: text, autoVectorize: autoVectorize.value })
    selectedId.value = id
    loadSelected()
    message.success(autoVectorize.value ? `已导入并向量化：${file.name}` : `已导入：${file.name}（未向量化）`)
  } catch (err) {
    message.error(err?.message || '导入文件失败')
  }
  return false
}

async function testEmbedding() {
  try {
    if (!embeddingConfig.apiKey) {
      message.error('请先填写向量 API Key（魔搭社区）')
      return
    }
    if (!embeddingConfig.model) {
      message.error('请选择或填写向量模型')
      return
    }
    testingEmbedding.value = true
    store.setEmbeddingConfig(embeddingConfig)
    const vector = await embedWithModelScope({
      apiKey: embeddingConfig.apiKey,
      model: embeddingConfig.model,
      baseUrl: embeddingConfig.baseUrl,
      input: '向量连通性测试'
    })
    message.success(`调用成功，向量维度：${vector.length || 0}`)
  } catch (err) {
    message.error(err?.message || '测试向量模型失败')
  } finally {
    testingEmbedding.value = false
  }
}

function formatTime(t) {
  if (!t) return ''
  try {
    return new Date(t).toLocaleString()
  } catch (e) {
    return t
  }
}
</script>

<style scoped>
.kb-layout {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 12px;
  height: calc(100vh - 120px);
}
.kb-left {
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  padding: 12px;
  display: flex;
  flex-direction: column;
}
.kb-toolbar {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.kb-actions {
  display: flex;
  gap: 8px;
}
.kb-list {
  margin-top: 12px;
  overflow: auto;
  flex: 1;
}
.kb-embed-row {
  margin-bottom: 8px;
}
.kb-embed-controls {
  display: flex;
  gap: 8px;
  align-items: center;
}
.kb-item {
  cursor: pointer;
}
.kb-item.active {
  background: #e6f4ff;
}
.kb-item-title {
  display: flex;
  align-items: center;
  gap: 6px;
}
.kb-right {
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  padding: 16px;
  overflow: auto;
}
.kb-form-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 12px;
}
.kb-meta {
  color: #8c8c8c;
  font-size: 12px;
}
</style>
