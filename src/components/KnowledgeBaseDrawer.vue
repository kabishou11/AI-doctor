<template>
  <a-drawer
    :open="open"
    title="知识库管理"
    width="1100px"
    @close="emit('update:open', false)"
    :body-style="{ padding: 0 }"
  >
    <div class="kb-container">
      <!-- 左侧：知识库列表 -->
      <div class="kb-sidebar">
        <div class="kb-sidebar-header">
          <div class="kb-sidebar-title">
            <FolderOutlined />
            <span>知识库集合</span>
          </div>
          <a-button type="text" size="small" @click="showCreateCollection = true" title="新建集合">
            <PlusOutlined />
          </a-button>
        </div>

        <!-- 集合列表 -->
        <div class="collection-list">
          <div
            :class="['collection-item', { active: !selectedCollectionId }]"
            @click="selectCollection(null)"
          >
            <FolderOpenOutlined style="color: #1890ff;" />
            <span>全部文档</span>
            <span class="count">{{ store.docs.length }}</span>
          </div>
          <div
            v-for="col in collections"
            :key="col.id"
            :class="['collection-item', { active: selectedCollectionId === col.id }]"
            @click="selectCollection(col.id)"
          >
            <FolderOutlined :style="{ color: col.color || '#52c41a' }" />
            <span>{{ col.name }}</span>
            <span class="count">{{ getCollectionDocCount(col.id) }}</span>
            <a-dropdown trigger="hover" @click.stop>
              <a-button type="text" size="small" class="col-actions">
                <MoreOutlined />
              </a-button>
              <template #overlay>
                <a-menu>
                  <a-menu-item key="edit" @click.stop="editCollection(col)">编辑</a-menu-item>
                  <a-menu-item key="delete" @click.stop="deleteCollection(col.id)">删除</a-menu-item>
                </a-menu>
              </template>
            </a-dropdown>
          </div>
        </div>

        <!-- 搜索和筛选 -->
        <div class="kb-search">
          <a-input-search
            v-model:value="searchQuery"
            placeholder="搜索文档..."
            allow-clear
            @search="handleSearch"
            @change="handleSearch"
          />
          <a-select
            v-model:value="filterTags"
            mode="multiple"
            allow-clear
            show-search
            :options="tagOptions"
            placeholder="按标签筛选"
            :filter-option="filterOption"
            style="width: 100%; margin-top: 8px;"
            :max-tag-count="2"
          />
        </div>

        <!-- 文档列表 -->
        <div class="doc-list">
          <div v-if="filteredDocs.length === 0" class="empty-docs">
            <Empty description="暂无文档" />
            <a-button type="link" @click="createDoc">新建文档</a-button>
          </div>
          <div
            v-for="doc in filteredDocs"
            :key="doc.id"
            :class="['doc-item', { active: selectedDocId === doc.id }]"
            @click="selectDoc(doc.id)"
          >
            <div class="doc-item-main">
              <div class="doc-title">{{ doc.title || '未命名' }}</div>
              <div class="doc-meta">
                <a-tag v-for="tag in (doc.tags || []).slice(0, 3)" :key="tag" size="small" :color="getTagColor(tag)">
                  {{ tag }}
                </a-tag>
                <span v-if="(doc.tags || []).length > 3" class="more-tags">+{{ doc.tags.length - 3 }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- 底部操作 -->
        <div class="kb-sidebar-footer">
          <a-button type="primary" block @click="createDoc">
            <PlusOutlined /> 新建文档
          </a-button>
          <a-button block @click="showUploadModal = true">
            <UploadOutlined /> 上传文档
          </a-button>
        </div>
      </div>

      <!-- 右侧：文档编辑 -->
      <div class="kb-editor">
        <div v-if="!editingDoc" class="kb-editor-empty">
          <Empty description="选择左侧文档或新建" />
        </div>
        <div v-else class="kb-editor-content">
          <div class="editor-header">
            <a-input
              v-model:value="editingDoc.title"
              placeholder="文档标题"
              class="title-input"
              :bordered="false"
            />
            <a-space>
              <a-tag :color="currentCollection?.color || 'blue'">
                <FolderOutlined /> {{ currentCollection?.name || '未分类' }}
              </a-tag>
            </a-space>
          </div>

          <!-- 标签管理 -->
          <div class="editor-section">
            <div class="section-label">
              <TagOutlined /> 标签
              <a-button type="link" size="small" @click="showCreateTag = true">+ 新标签</a-button>
            </div>
            <div class="tags-area">
              <a-select
                v-model:value="editingTags"
                mode="tags"
                style="width: 100%;"
                placeholder="输入或选择标签（回车确认）"
                :options="availableTagOptions"
                :max-tag-count="10"
                @change="handleTagsChange"
              />
            </div>
          </div>

          <!-- 摘要 -->
          <div class="editor-section">
            <div class="section-label">
              <FileTextOutlined /> 摘要
            </div>
            <a-textarea
              v-model:value="editingDoc.excerpt"
              placeholder="简要描述文档内容，用于快速识别"
              :rows="2"
            />
          </div>

          <!-- 正文内容 -->
          <div class="editor-section flex-1">
            <div class="section-label">
              <FileOutlined /> 正文内容
              <span class="char-count">{{ (editingDoc.content || '').length }} 字</span>
            </div>
            <a-textarea
              v-model:value="editingDoc.content"
              placeholder="粘贴指南/流程/经验等内容..."
              :rows="12"
              class="content-textarea"
            />
          </div>

          <!-- 向量状态 -->
          <div class="editor-section">
            <div class="section-label">
              <AimOutlined /> 向量化状态
              <a-tag :color="hasVectors ? 'success' : 'default'" size="small">
                {{ hasVectors ? '已向量化' : '未向量化' }}
              </a-tag>
            </div>
            <div class="vector-info">
              <span v-if="hasVectors">已生成 {{ chunkCount }} 个向量切片</span>
              <span v-else>点击"生成向量"以启用语义检索</span>
            </div>
          </div>

          <!-- 操作栏 -->
          <div class="editor-actions">
            <a-space>
              <a-button type="primary" @click="saveDoc" :loading="saving">
                <SaveOutlined /> 保存
              </a-button>
              <a-button @click="vectorizeDoc" :loading="vectorizing" :disabled="!editingDoc.content">
                <AimOutlined /> 生成向量
              </a-button>
              <a-divider type="vertical" />
              <a-popconfirm title="确认删除此文档？" @confirm="deleteDoc">
                <a-button danger>
                  <DeleteOutlined /> 删除
                </a-button>
              </a-popconfirm>
            </a-space>
            <div class="doc-timestamps" v-if="editingDoc.updatedAt">
              更新于 {{ formatTime(editingDoc.updatedAt) }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 新建/编辑集合弹窗 -->
    <a-modal
      v-model:open="showCreateCollection"
      :title="editingCollection ? '编辑集合' : '新建集合'"
      @ok="saveCollection"
      @cancel="closeCollectionModal"
    >
      <a-form layout="vertical">
        <a-form-item label="集合名称" required>
          <a-input v-model:value="collectionForm.name" placeholder="如：急救知识、心脏病指南" />
        </a-form-item>
        <a-form-item label="集合颜色">
          <a-space>
            <a-tag
              v-for="color in collectionColors"
              :key="color"
              :color="color"
              :class="{ selected: collectionForm.color === color }"
              @click="collectionForm.color = color"
              class="color-tag"
            >
              {{ collectionForm.color === color ? '✓' : '' }}
            </a-tag>
          </a-space>
        </a-form-item>
      </a-form>
    </a-modal>

    <!-- 新建标签弹窗 -->
    <a-modal v-model:open="showCreateTag" title="新建标签" @ok="createTag" @cancel="showCreateTag = false">
      <a-form layout="vertical">
        <a-form-item label="标签名称" required>
          <a-input v-model:value="newTagName" placeholder="输入标签名称" />
        </a-form-item>
      </a-form>
    </a-modal>

    <!-- 上传文档弹窗 -->
    <a-modal
      v-model:open="showUploadModal"
      title="上传文档"
      :footer="null"
    >
      <a-upload-dragger
        :before-upload="handleFileUpload"
        :show-upload-list="false"
        accept=".txt,.md,.pdf,.docx,.csv"
        name="file"
      >
        <p class="ant-upload-drag-icon">
          <InboxOutlined />
        </p>
        <p class="ant-upload-text">点击或拖拽上传文件</p>
        <p class="ant-upload-hint">支持 .txt, .md, .pdf, .docx, .csv 格式</p>
      </a-upload-dragger>
      <a-divider />
      <a-form layout="vertical" style="margin-top: 16px;">
        <a-form-item label="归属集合">
          <a-select v-model:value="uploadCollectionId" placeholder="选择集合（可选）">
            <a-select-option :value="''">无集合</a-select-option>
            <a-select-option v-for="col in collections" :key="col.id" :value="col.id">
              <a-space>
                <a-tag :color="col.color || 'blue'" size="small">{{ col.name }}</a-tag>
              </a-space>
            </a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="自动生成向量">
          <a-switch v-model:checked="uploadAutoVectorize" />
        </a-form-item>
        <a-form-item label="添加标签">
          <a-select v-model:value="uploadTags" mode="tags" placeholder="输入标签（可选）" style="width: 100%;" />
        </a-form-item>
      </a-form>
    </a-modal>
  </a-drawer>

<script setup>
import { computed, reactive, ref, watch, onMounted } from 'vue'
import {
  message,
  Modal,
  Empty
} from 'ant-design-vue'
import {
  FolderOutlined,
  FolderOpenOutlined,
  PlusOutlined,
  SearchOutlined,
  TagOutlined,
  FileTextOutlined,
  FileOutlined,
  AimOutlined,
  SaveOutlined,
  DeleteOutlined,
  UploadOutlined,
  MoreOutlined,
  InboxOutlined
} from '@ant-design/icons-vue'
import { useKnowledgeStore } from '../store/knowledge'
import { parseFileToText } from '../utils/textParser'
import { embedWithModelScope } from '../api/embeddings'

const props = defineProps({ open: { type: Boolean, default: false } })
const emit = defineEmits(['update:open'])

const store = useKnowledgeStore()

// 状态
const searchQuery = ref('')
const filterTags = ref([])
const selectedDocId = ref('')
const selectedCollectionId = ref('')
const editingDoc = ref(null)
const editingTags = ref([])
const saving = ref(false)
const vectorizing = ref(false)

// 集合管理
const showCreateCollection = ref(false)
const editingCollection = ref(null)
const collectionForm = reactive({ name: '', color: '#1890ff' })
const collectionColors = ['#1890ff', '#52c41a', '#faad14', '#f5222d', '#722ed1', '#eb2f96', '#13c2c2', '#fa8c16']

// 标签管理
const showCreateTag = ref(false)
const newTagName = ref('')

// 上传
const showUploadModal = ref(false)
const uploadCollectionId = ref('')
const uploadAutoVectorize = ref(true)
const uploadTags = ref([])

// 配置
const embeddingConfig = reactive({
  model: '',
  apiKey: '',
  baseUrl: ''
})
const retrievalConfig = reactive({
  topK: 5,
  keywordWeight: 0.5
})

// 集合
const COLLECTIONS_KEY = 'kb_collections_v1'
const collections = ref([])

onMounted(() => {
  loadCollections()
})

function loadCollections() {
  try {
    const raw = localStorage.getItem(COLLECTIONS_KEY)
    collections.value = raw ? JSON.parse(raw) : []
  } catch (e) {
    collections.value = []
  }
}

function saveCollections() {
  localStorage.setItem(COLLECTIONS_KEY, JSON.stringify(collections.value))
}

function selectCollection(id) {
  selectedCollectionId.value = id
}

function selectDoc(id) {
  selectedDocId.value = id
  const doc = store.docMap.get(id)
  if (doc) {
    editingDoc.value = { ...doc }
    editingTags.value = [...(doc.tags || [])]
  } else {
    editingDoc.value = null
    editingTags.value = []
  }
}

function getCollectionDocCount(collectionId) {
  return store.docs.filter(d => d.collectionId === collectionId).length
}

function editCollection(col) {
  editingCollection.value = col
  collectionForm.name = col.name
  collectionForm.color = col.color || '#1890ff'
  showCreateCollection.value = true
}

function saveCollection() {
  if (!collectionForm.name.trim()) {
    message.error('请输入集合名称')
    return
  }

  if (editingCollection.value) {
    const idx = collections.value.findIndex(c => c.id === editingCollection.value.id)
    if (idx !== -1) {
      collections.value[idx] = { ...collections.value[idx], name: collectionForm.name, color: collectionForm.color }
    }
  } else {
    collections.value.push({
      id: `col-${Date.now()}`,
      name: collectionForm.name,
      color: collectionForm.color,
      createdAt: new Date().toISOString()
    })
  }

  saveCollections()
  closeCollectionModal()
  message.success(editingCollection.value ? '集合已更新' : '集合已创建')
}

function closeCollectionModal() {
  showCreateCollection.value = false
  editingCollection.value = null
  collectionForm.name = ''
  collectionForm.color = '#1890ff'
}

function deleteCollection(id) {
  Modal.confirm({
    title: '确认删除此集合？',
    content: '删除集合不会删除其中的文档，文档将移至"未分类"',
    onOk() {
      collections.value = collections.value.filter(c => c.id !== id)
      saveCollections()
      if (selectedCollectionId.value === id) {
        selectedCollectionId.value = ''
      }
      message.success('集合已删除')
    }
  })
}

function createTag() {
  if (!newTagName.value.trim()) {
    message.error('请输入标签名称')
    return
  }
  if (!editingTags.value.includes(newTagName.value.trim())) {
    editingTags.value.push(newTagName.value.trim())
  }
  newTagName.value = ''
  showCreateTag.value = false
}

function handleTagsChange(tags) {
  editingTags.value = tags
}

const currentCollection = computed(() => {
  if (!editingDoc.value?.collectionId) return null
  return collections.value.find(c => c.id === editingDoc.value.collectionId)
})

const hasVectors = computed(() => {
  if (!selectedDocId.value) return false
  return store.chunks.some(c => c.docId === selectedDocId.value)
})

const chunkCount = computed(() => {
  if (!selectedDocId.value) return 0
  return store.chunks.filter(c => c.docId === selectedDocId.value).length
})

// 计算属性
const filteredDocs = computed(() => {
  let docs = store.docs || []

  // 按集合筛选
  if (selectedCollectionId.value) {
    docs = docs.filter(d => d.collectionId === selectedCollectionId.value)
  }

  // 按搜索词筛选
  const q = searchQuery.value.toLowerCase().trim()
  if (q) {
    docs = docs.filter(d =>
      (d.title || '').toLowerCase().includes(q) ||
      (d.content || '').toLowerCase().includes(q) ||
      (d.tags || []).some(t => t.toLowerCase().includes(q))
    )
  }

  // 按标签筛选
  if (filterTags.value.length > 0) {
    docs = docs.filter(d =>
      filterTags.value.every(tag => (d.tags || []).includes(tag))
    )
  }

  return docs
})

const allTags = computed(() => {
  const tags = new Set()
  ;(store.docs || []).forEach(d => (d.tags || []).forEach(t => tags.add(t)))
  return Array.from(tags)
})

const tagOptions = computed(() => {
  return allTags.value.map(t => ({ label: t, value: t }))
})

const availableTagOptions = computed(() => {
  return allTags.value.map(t => ({ label: t, value: t }))
})

function filterOption(input, option) {
  return option.label.toLowerCase().includes(input.toLowerCase())
}

function handleSearch() {
  // 搜索由 computed 处理
}

function createDoc() {
  const id = store.addDoc({
    title: '未命名文档',
    content: '',
    tags: [],
    collectionId: selectedCollectionId.value || ''
  })
  selectDoc(id)
  message.success('已创建新文档')
}

async function saveDoc() {
  if (!editingDoc.value?.id) return

  try {
    saving.value = true
    store.updateDoc(editingDoc.value.id, {
      title: editingDoc.value.title,
      content: editingDoc.value.content,
      excerpt: editingDoc.value.excerpt,
      tags: editingTags.value,
      collectionId: selectedCollectionId.value || ''
    })
    message.success('已保存')
  } catch (e) {
    message.error('保存失败')
  } finally {
    saving.value = false
  }
}

async function vectorizeDoc() {
  if (!editingDoc.value?.id) return

  try {
    vectorizing.value = true
    syncConfig()
    const count = await store.reembedDoc(editingDoc.value.id)
    message.success(`已生成 ${count} 个向量切片`)
  } catch (e) {
    message.error(e?.message || '向量生成失败')
  } finally {
    vectorizing.value = false
  }
}

function deleteDoc() {
  if (!editingDoc.value?.id) return
  store.removeDoc(editingDoc.value.id)
  editingDoc.value = null
  selectedDocId.value = ''
  message.success('文档已删除')
}

async function handleFileUpload(file) {
  try {
    syncConfig()
    const text = await parseFileToText(file)
    const title = file.name.replace(/\.[^/.]+$/, '')

    const id = await store.ingestDocument({
      title,
      content: text,
      tags: uploadTags.value,
      collectionId: uploadCollectionId.value || '',
      autoVectorize: uploadAutoVectorize.value
    })

    selectDoc(id)
    showUploadModal.value = false
    uploadTags.value = []
    message.success(uploadAutoVectorize.value ? `已导入并向量化：${file.name}` : `已导入：${file.name}`)
  } catch (e) {
    message.error(e?.message || '上传失败')
  }
  return false
}

function syncConfig() {
  store.setEmbeddingConfig(embeddingConfig)
  store.setRetrievalConfig(retrievalConfig)
}

function getTagColor(tag) {
  const colors = ['blue', 'green', 'orange', 'red', 'purple', 'cyan', 'gold', 'lime', 'magenta', 'volcano']
  const hash = tag.split('').reduce((acc, c) => acc + c.charCodeAt(0), 0)
  return colors[hash % colors.length]
}

function formatTime(t) {
  if (!t) return ''
  try {
    return new Date(t).toLocaleString('zh-CN')
  } catch (e) {
    return t
  }
}

// 监听抽屉打开
watch(() => props.open, (v) => {
  if (v) {
    syncConfig()
    embeddingConfig.model = store.embeddingConfig?.model || 'text-embedding-v3'
    embeddingConfig.apiKey = store.embeddingConfig?.apiKey || ''
    embeddingConfig.baseUrl = store.embeddingConfig?.baseUrl || ''
    retrievalConfig.topK = store.retrievalConfig?.topK || 5
    retrievalConfig.keywordWeight = store.retrievalConfig?.keywordWeight ?? 0.5
  }
})
</script>

<style scoped>
.kb-container {
  display: flex;
  height: calc(100vh - 55px);
}

/* 侧边栏 */
.kb-sidebar {
  width: 340px;
  border-right: 1px solid #f0f0f0;
  display: flex;
  flex-direction: column;
  background: #fafbfc;
}

.kb-sidebar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid #f0f0f0;
  background: #fff;
}

.kb-sidebar-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  color: #262626;
}

/* 集合列表 */
.collection-list {
  padding: 8px;
  border-bottom: 1px solid #f0f0f0;
  max-height: 200px;
  overflow-y: auto;
}

.collection-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 13px;
}

.collection-item:hover {
  background: #f0f7ff;
}

.collection-item.active {
  background: #e6f4ff;
  font-weight: 500;
}

.collection-item .count {
  margin-left: auto;
  color: #8c8c8c;
  font-size: 12px;
}

.collection-item .col-actions {
  opacity: 0;
  transition: opacity 0.2s;
}

.collection-item:hover .col-actions {
  opacity: 1;
}

/* 搜索 */
.kb-search {
  padding: 12px;
  border-bottom: 1px solid #f0f0f0;
}

/* 文档列表 */
.doc-list {
  flex: 1;
  overflow-y: auto;
  padding: 8px;
}

.empty-docs {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 0;
}

.doc-item {
  padding: 10px 12px;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s;
  margin-bottom: 4px;
}

.doc-item:hover {
  background: #f0f7ff;
}

.doc-item.active {
  background: #e6f4ff;
  border-left: 3px solid #1890ff;
}

.doc-title {
  font-size: 13px;
  font-weight: 500;
  color: #262626;
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.doc-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  align-items: center;
}

.more-tags {
  font-size: 11px;
  color: #8c8c8c;
}

/* 底部操作 */
.kb-sidebar-footer {
  padding: 12px;
  border-top: 1px solid #f0f0f0;
  display: flex;
  flex-direction: column;
  gap: 8px;
  background: #fff;
}

/* 编辑器 */
.kb-editor {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.kb-editor-empty {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
}

.kb-editor-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  padding: 16px 20px;
  overflow-y: auto;
}

.editor-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-bottom: 12px;
  border-bottom: 1px solid #f0f0f0;
  margin-bottom: 16px;
}

.title-input {
  font-size: 18px;
  font-weight: 600;
}

.title-input :deep(input) {
  font-size: 18px;
  font-weight: 600;
}

.editor-section {
  margin-bottom: 16px;
}

.editor-section.flex-1 {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.section-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 500;
  color: #595959;
  margin-bottom: 8px;
}

.char-count {
  margin-left: auto;
  font-weight: normal;
  color: #8c8c8c;
}

.tags-area {
  margin-bottom: 8px;
}

.vector-info {
  font-size: 12px;
  color: #8c8c8c;
  padding: 8px 12px;
  background: #fafafa;
  border-radius: 6px;
}

.content-textarea {
  flex: 1;
  font-family: 'Monaco', 'Menlo', monospace;
  font-size: 13px;
}

.editor-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding-top: 16px;
  border-top: 1px solid #f0f0f0;
  margin-top: auto;
}

.doc-timestamps {
  font-size: 12px;
  color: #8c8c8c;
}

/* 颜色标签 */
.color-tag {
  cursor: pointer;
  transition: transform 0.2s;
}

.color-tag:hover {
  transform: scale(1.1);
}

.color-tag.selected {
  font-weight: bold;
}
</style>
