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
          <a-space>
            <a-button type="text" size="small" @click="showCreateCollection = true" title="新建集合">
              <PlusOutlined />
            </a-button>
            <a-button type="text" size="small" @click="showPresetModal = true" title="加载预设知识库">
              <BookOutlined />
            </a-button>
            <a-button type="text" size="small" @click="showRetrievalConfig = true" title="检索配置">
              <SettingOutlined />
            </a-button>
            <a-button type="text" size="small" @click="showEmbeddingConfig = true" title="向量模型配置">
              <AimOutlined />
            </a-button>
          </a-space>
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

    <!-- 检索配置弹窗 -->
    <a-modal
      v-model:open="showRetrievalConfig"
      title="检索配置"
      width="700px"
      @ok="saveRetrievalSettings"
      @cancel="showRetrievalConfig = false"
    >
      <a-alert type="info" show-icon message="检索策略配置" description="配置知识库的检索方式，包括检索策略、向量权重、分块策略等。" style="margin-bottom: 16px;" />
      <a-tabs v-model:activeKey="configTab">
        <a-tab-pane key="retrieval" tab="检索策略">
          <a-form layout="vertical">
            <a-form-item label="检索策略">
              <a-radio-group v-model:value="retrievalConfig.strategy">
                <a-radio value="hybrid">混合检索（推荐）</a-radio>
                <a-radio value="vector">向量检索</a-radio>
                <a-radio value="keyword">关键词检索</a-radio>
              </a-radio-group>
            </a-form-item>
            <a-row :gutter="12">
              <a-col :span="12">
                <a-form-item label="Top-K 返回数量">
                  <a-input-number v-model:value="retrievalConfig.topK" :min="1" :max="20" style="width: 100%;" />
                </a-form-item>
              </a-col>
              <a-col :span="12">
                <a-form-item label="向量权重">
                  <a-slider v-model:value="retrievalConfig.vectorWeight" :min="0" :max="1" :step="0.1" :marks="{ 0: '0', 0.5: '0.5', 1: '1' }" />
                  <div class="slider-hint">
                    <span>关键词为主</span>
                    <span>向量为主</span>
                  </div>
                </a-form-item>
              </a-col>
            </a-row>
            <a-form-item label="BM25 关键词检索">
              <a-switch v-model:checked="retrievalConfig.bm25Enabled" />
              <span style="margin-left: 8px; color: #8c8c8c;">启用基于词频的关键词匹配</span>
            </a-form-item>
            <a-row :gutter="12" v-if="retrievalConfig.bm25Enabled">
              <a-col :span="12">
                <a-form-item label="BM25 k1 参数">
                  <a-input-number v-model:value="retrievalConfig.bm25K1" :min="0.5" :max="3" :step="0.1" style="width: 100%;" />
                </a-form-item>
              </a-col>
              <a-col :span="12">
                <a-form-item label="BM25 b 参数">
                  <a-input-number v-model:value="retrievalConfig.bm25B" :min="0" :max="1" :step="0.1" style="width: 100%;" />
                </a-form-item>
              </a-col>
            </a-row>
            <a-form-item label="结果去重">
              <a-switch v-model:checked="retrievalConfig.enableDeduplication" />
              <span style="margin-left: 8px; color: #8c8c8c;">合并来自同一文档的重复结果</span>
            </a-form-item>
          </a-form>
        </a-tab-pane>
        <a-tab-pane key="chunking" tab="分块策略">
          <a-form layout="vertical">
            <a-form-item label="分块策略">
              <a-radio-group v-model:value="embeddingConfig.chunkStrategy">
                <a-radio value="sentence">句子级别（推荐）</a-radio>
                <a-radio value="paragraph">段落级别</a-radio>
                <a-radio value="fixed">固定长度</a-radio>
              </a-radio-group>
            </a-form-item>
            <a-row :gutter="12">
              <a-col :span="12">
                <a-form-item label="分块大小">
                  <a-input-number v-model:value="embeddingConfig.chunkSize" :min="100" :max="2000" :step="50" style="width: 100%;" />
                  <span style="color: #8c8c8c; font-size: 12px;">每块最大字符数</span>
                </a-form-item>
              </a-col>
              <a-col :span="12">
                <a-form-item label="重叠字符">
                  <a-input-number v-model:value="embeddingConfig.chunkOverlap" :min="0" :max="500" :step="10" style="width: 100%;" />
                  <span style="color: #8c8c8c; font-size: 12px;">相邻块重叠的字符数</span>
                </a-form-item>
              </a-col>
            </a-row>
            <a-alert type="info" show-icon message="分块策略说明" description="句子级别适合医学指南等结构化内容；段落级别适合有明显分隔的文档；固定长度适合统一格式的内容。" style="margin-top: 8px;" />
          </a-form>
        </a-tab-pane>
        <a-tab-pane key="rerank" tab="重排设置">
          <a-form layout="vertical">
            <a-form-item label="启用重排">
              <a-switch v-model:checked="retrievalConfig.rerankEnabled" />
              <span style="margin-left: 8px; color: #8c8c8c;">在初步检索后对结果进行相关性重排</span>
            </a-form-item>
            <a-row :gutter="12" v-if="retrievalConfig.rerankEnabled">
              <a-col :span="12">
                <a-form-item label="重排 Top-N">
                  <a-input-number v-model:value="retrievalConfig.rerankTopN" :min="1" :max="10" style="width: 100%;" />
                  <span style="color: #8c8c8c; font-size: 12px;">对前 N 个结果进行重排</span>
                </a-form-item>
              </a-col>
            </a-row>
            <a-alert type="info" show-icon message="重排说明" description="重排功能会在初步检索后，使用额外的相关性模型对结果进行二次排序，提升检索质量。" style="margin-top: 8px;" />
          </a-form>
        </a-tab-pane>
      </a-tabs>
    </a-modal>

    <!-- Embedding 配置弹窗 -->
    <a-modal
      v-model:open="showEmbeddingConfig"
      title="向量模型配置"
      width="600px"
      @ok="saveEmbeddingSettings"
      @cancel="showEmbeddingConfig = false"
    >
      <a-form layout="vertical">
        <a-alert type="info" show-icon message="Embedding 模型配置" description="选择向量模型服务商和模型名称。不同的 embedding 模型会影响向量检索的效果。" style="margin-bottom: 16px;" />
        <a-form-item label="服务商">
          <a-select v-model:value="embeddingConfig.provider">
            <a-select-option value="modelscope">魔搭社区（DashScope）</a-select-option>
            <a-select-option value="openai">OpenAI</a-select-option>
            <a-select-option value="minimax">MiniMax</a-select-option>
            <a-select-option value="siliconflow">硅基流动</a-select-option>
            <a-select-option value="custom">自定义</a-select-option>
          </a-select>
        </a-form-item>
        <a-form-item label="模型名称">
          <a-select
            v-model:value="embeddingConfig.model"
            show-search
            allow-create
            :options="modelOptionsByProvider[embeddingConfig.provider] || []"
            placeholder="选择或输入模型名称"
            style="width: 100%;"
          />
          <div class="model-hints">
            <span v-if="embeddingConfig.provider === 'modelscope'">推荐：text-embedding-v3、text-embedding-3-small</span>
            <span v-if="embeddingConfig.provider === 'openai'">推荐：text-embedding-3-small、text-embedding-ada-002</span>
            <span v-if="embeddingConfig.provider === 'minimax'">推荐：embedding-model-v1</span>
            <span v-if="embeddingConfig.provider === 'siliconflow'">推荐：BAAI/bge-large-zh-v1.5</span>
          </div>
        </a-form-item>
        <a-form-item label="API Key">
          <a-input-password v-model:value="embeddingConfig.apiKey" placeholder="输入 API Key（sk-... 或 ms-...）" />
        </a-form-item>
        <a-form-item label="自定义 Base URL">
          <a-input v-model:value="embeddingConfig.baseUrl" placeholder="留空使用默认值" />
          <div class="model-hints" v-if="embeddingConfig.provider === 'modelscope'">
            ms- 开头：api-inference.modelscope.cn；sk- 开头：dashscope.aliyuncs.com
          </div>
        </a-form-item>
      </a-form>
    </a-modal>

    <!-- 预设知识库弹窗 -->
    <a-modal
      v-model:open="showPresetModal"
      title="加载预设知识库"
      @ok="loadPresetKnowledge"
      @cancel="showPresetModal = false"
      :confirm-loading="loadingPreset"
    >
      <a-space direction="vertical" style="width: 100%;">
        <a-alert type="info" show-icon message="预设医学知识库" description="加载包含急救、心血管、药物等医学知识的预设集合和文档。" />
        <div class="preset-list">
          <div class="preset-item">
            <FolderOutlined style="color: #f5222d;" />
            <span class="preset-name">急救知识</span>
            <span class="preset-count">3 篇文档</span>
          </div>
          <div class="preset-item">
            <FolderOutlined style="color: #eb2f96;" />
            <span class="preset-name">心血管指南</span>
            <span class="preset-count">3 篇文档</span>
          </div>
          <div class="preset-item">
            <FolderOutlined style="color: #722ed1;" />
            <span class="preset-name">药物相互作用</span>
            <span class="preset-count">3 篇文档</span>
          </div>
          <div class="preset-item">
            <FolderOutlined style="color: #13c2c2;" />
            <span class="preset-name">呼吸系统</span>
            <span class="preset-count">3 篇文档</span>
          </div>
          <div class="preset-item">
            <FolderOutlined style="color: #fa8c16;" />
            <span class="preset-name">糖尿病管理</span>
            <span class="preset-count">3 篇文档</span>
          </div>
        </div>
        <div class="preset-total">共 5 个集合，15 篇医学知识文档</div>
      </a-space>
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
  InboxOutlined,
  SettingOutlined,
  BookOutlined
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

// 配置相关状态
const showRetrievalConfig = ref(false)
const showEmbeddingConfig = ref(false)
const showPresetModal = ref(false)
const loadingPreset = ref(false)
const configTab = ref('retrieval')

const modelOptionsByProvider = {
  modelscope: [
    { label: 'text-embedding-v3', value: 'text-embedding-v3' },
    { label: 'text-embedding-3-small', value: 'text-embedding-3-small' }
  ],
  openai: [
    { label: 'text-embedding-3-small', value: 'text-embedding-3-small' },
    { label: 'text-embedding-3-large', value: 'text-embedding-3-large' },
    { label: 'text-embedding-ada-002', value: 'text-embedding-ada-002' }
  ],
  minimax: [
    { label: 'embedding-model-v1', value: 'embedding-model-v1' }
  ],
  siliconflow: [
    { label: 'BAAI/bge-large-zh-v1.5', value: 'BAAI/bge-large-zh-v1.5' },
    { label: 'BAAI/bge-base-zh-v1.5', value: 'BAAI/bge-base-zh-v1.5' }
  ]
}

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

// 配置 - 从 store 同步
const embeddingConfig = reactive({
  provider: 'modelscope',
  model: 'text-embedding-v3',
  apiKey: '',
  baseUrl: '',
  chunkStrategy: 'sentence',
  chunkSize: 800,
  chunkOverlap: 100
})

const retrievalConfig = reactive({
  strategy: 'hybrid',
  topK: 5,
  vectorWeight: 0.5,
  bm25Enabled: true,
  bm25K1: 1.5,
  bm25B: 0.75,
  rerankEnabled: false,
  rerankTopN: 3,
  enableDeduplication: true
})

// 集合
const collections = computed(() => store.collections)

onMounted(() => {
  // Load collections from store
  syncConfig()
})

function syncConfig() {
  // Sync embedding config
  const ec = store.embeddingConfig || {}
  embeddingConfig.provider = ec.provider || 'modelscope'
  embeddingConfig.model = ec.model || 'text-embedding-v3'
  embeddingConfig.apiKey = ec.apiKey || ''
  embeddingConfig.baseUrl = ec.baseUrl || ''
  embeddingConfig.chunkStrategy = ec.chunkStrategy || 'sentence'
  embeddingConfig.chunkSize = ec.chunkSize || 800
  embeddingConfig.chunkOverlap = ec.chunkOverlap || 100

  // Sync retrieval config
  const rc = store.retrievalConfig || {}
  retrievalConfig.strategy = rc.strategy || 'hybrid'
  retrievalConfig.topK = rc.topK || 5
  retrievalConfig.vectorWeight = rc.vectorWeight ?? 0.5
  retrievalConfig.bm25Enabled = rc.bm25Enabled !== undefined ? rc.bm25Enabled : true
  retrievalConfig.bm25K1 = rc.bm25K1 || 1.5
  retrievalConfig.bm25B = rc.bm25B || 0.75
  retrievalConfig.rerankEnabled = rc.rerankEnabled !== undefined ? rc.rerankEnabled : false
  retrievalConfig.rerankTopN = rc.rerankTopN || 3
  retrievalConfig.enableDeduplication = rc.enableDeduplication !== undefined ? rc.enableDeduplication : true
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
    store.updateCollection(editingCollection.value.id, {
      name: collectionForm.name,
      color: collectionForm.color
    })
  } else {
    store.addCollection({
      name: collectionForm.name,
      color: collectionForm.color
    })
  }

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
      store.removeCollection(id)
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
  return store.collections.find(c => c.id === editingDoc.value.collectionId)
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
    // Save current config to store before vectorizing
    store.setEmbeddingConfig({
      provider: embeddingConfig.provider,
      model: embeddingConfig.model,
      apiKey: embeddingConfig.apiKey,
      baseUrl: embeddingConfig.baseUrl,
      chunkStrategy: embeddingConfig.chunkStrategy,
      chunkSize: embeddingConfig.chunkSize,
      chunkOverlap: embeddingConfig.chunkOverlap
    })
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
    // Save current config to store before ingesting
    store.setEmbeddingConfig({
      provider: embeddingConfig.provider,
      model: embeddingConfig.model,
      apiKey: embeddingConfig.apiKey,
      baseUrl: embeddingConfig.baseUrl,
      chunkStrategy: embeddingConfig.chunkStrategy,
      chunkSize: embeddingConfig.chunkSize,
      chunkOverlap: embeddingConfig.chunkOverlap
    })
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

function saveRetrievalSettings() {
  store.setRetrievalConfig({
    strategy: retrievalConfig.strategy,
    topK: retrievalConfig.topK,
    vectorWeight: retrievalConfig.vectorWeight,
    bm25Enabled: retrievalConfig.bm25Enabled,
    bm25K1: retrievalConfig.bm25K1,
    bm25B: retrievalConfig.bm25B,
    rerankEnabled: retrievalConfig.rerankEnabled,
    rerankTopN: retrievalConfig.rerankTopN,
    enableDeduplication: retrievalConfig.enableDeduplication
  })
  store.setEmbeddingConfig({
    chunkStrategy: embeddingConfig.chunkStrategy,
    chunkSize: embeddingConfig.chunkSize,
    chunkOverlap: embeddingConfig.chunkOverlap
  })
  showRetrievalConfig.value = false
  message.success('检索配置已保存')
}

function saveEmbeddingSettings() {
  store.setEmbeddingConfig({
    provider: embeddingConfig.provider,
    model: embeddingConfig.model,
    apiKey: embeddingConfig.apiKey,
    baseUrl: embeddingConfig.baseUrl
  })
  showEmbeddingConfig.value = false
  message.success('向量模型配置已保存')
}

async function loadPresetKnowledge() {
  loadingPreset.value = true
  try {
    const result = store.initializePresetKnowledge()
    message.success(`已加载 ${result.collections} 个集合，共 ${result.docs} 篇文档`)
    showPresetModal.value = false
  } catch (e) {
    message.error('加载预设知识库失败')
  } finally {
    loadingPreset.value = false
  }
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

/* 预设知识库列表 */
.preset-list {
  padding: 8px 0;
}

.preset-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-radius: 6px;
  transition: background 0.2s;
}

.preset-item:hover {
  background: #f5f5f5;
}

.preset-name {
  font-weight: 500;
  color: #262626;
}

.preset-count {
  margin-left: auto;
  color: #8c8c8c;
  font-size: 12px;
}

.preset-total {
  text-align: center;
  color: #8c8c8c;
  padding: 12px 0;
  border-top: 1px solid #f0f0f0;
}

/* Slider hint */
.slider-hint {
  display: flex;
  justify-content: space-between;
  font-size: 12px;
  color: #8c8c8c;
  margin-top: 4px;
}

/* Model hints */
.model-hints {
  font-size: 12px;
  color: #8c8c8c;
  margin-top: 4px;
}
</style>
</template>
