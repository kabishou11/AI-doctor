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
          <div class="search-label"><SearchOutlined /> 关键词搜索</div>
          <a-input-search
            v-model:value="searchQuery"
            placeholder="输入文档标题或内容关键词..."
            allow-clear
            @search="handleSearch"
            @change="handleSearch"
          />
          <div class="search-label" style="margin-top: 10px;"><TagOutlined /> 按标签筛选</div>
          <a-select
            v-model:value="filterTags"
            mode="multiple"
            allow-clear
            show-search
            :options="tagOptions"
            placeholder="选择标签过滤文档（可多选）"
            :filter-option="filterOption"
            style="width: 100%;"
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
          <a-button block @click="batchVectorizeAll" :loading="batchVectorizing" :disabled="!hasUnvectorizedDocs">
            <AimOutlined /> 一键向量化全部
          </a-button>
          <a-button block @click="openConfigModal">
            <SettingOutlined /> 检索与向量配置
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
      @cancel="showUploadModal = false; uploadCollectionId = ''; uploadAutoVectorize = true; uploadTags = []"
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

    <!-- 预设知识库弹窗 -->
    <a-modal
      v-model:open="showPresetModal"
      title="加载预设知识库"
      @ok="loadSelectedPresets"
      @cancel="showPresetModal = false"
      :confirm-loading="loadingPreset"
      :ok-text="selectedPresets.length > 0 ? `加载 ${selectedPresets.length} 个集合` : '一键加载全部（5个集合/15篇）'"
    >
      <div class="preset-wrapper">
        <a-alert type="info" show-icon message="预设医学知识库" description="勾选要加载的集合，点击确定导入。已加载的集合不会重复导入。" style="margin-bottom: 16px;" />
        <div class="preset-row" v-for="col in PRESET_COLLECTIONS" :key="col.id">
          <a-checkbox v-model:value="selectedPresets" :value="col.id" class="preset-row-check">
            <FolderOutlined :style="{ color: col.color }" />
            <span class="preset-row-name">{{ col.name }}</span>
          </a-checkbox>
          <span class="preset-row-desc">{{ getPresetDesc(col.id) }}</span>
          <a-tag size="small">{{ getPresetDocCount(col.id) }} 篇</a-tag>
        </div>
      </div>
    </a-modal>

    <!-- 检索与向量配置弹窗 -->
    <a-modal
      v-model:open="showConfigModal"
      title="检索与向量配置"
      :width="560"
      @ok="saveConfig"
      @cancel="showConfigModal = false"
      :ok-text="'保存配置'"
    >
      <a-tabs default-active-key="retrieval">
        <a-tab-pane key="retrieval" tab="检索策略">
          <a-form layout="vertical" :label-col="{ span: 8 }">
            <a-form-item label="检索策略">
              <a-select v-model:value="configForm.strategy">
                <a-select-option value="hybrid">混合检索（Hybrid）</a-select-option>
                <a-select-option value="keyword">仅关键词（BM25）</a-select-option>
                <a-select-option value="vector">仅语义向量</a-select-option>
              </a-select>
            </a-form-item>
            <a-form-item label="返回数量">
              <a-input-number v-model:value="configForm.topK" :min="1" :max="20" style="width: 100%;" />
              <div class="field-hint">每次检索返回的知识片段数量</div>
            </a-form-item>
            <a-form-item label="关键词权重" v-if="configForm.strategy === 'hybrid'">
              <a-slider v-model:value="configForm.keywordWeight" :min="0" :max="1" :step="0.1" :marks="{ 0: '0', 0.5: '0.5', 1: '1' }" />
              <div class="field-hint">BM25 关键词命中在混合得分中的权重</div>
            </a-form-item>
            <a-form-item label="语义权重" v-if="configForm.strategy === 'hybrid'">
              <a-slider v-model:value="configForm.vectorWeight" :min="0" :max="1" :step="0.1" :marks="{ 0: '0', 0.5: '0.5', 1: '1' }" />
              <div class="field-hint">向量相似度在混合得分中的权重</div>
            </a-form-item>
            <a-divider>BM25 参数</a-divider>
            <a-form-item label="启用 BM25">
              <a-switch v-model:checked="configForm.bm25Enabled" />
            </a-form-item>
            <a-form-item label="BM25 k1">
              <a-input-number v-model:value="configForm.bm25K1" :min="0.5" :max="3" :step="0.1" style="width: 100%;" />
              <div class="field-hint">词频饱和参数（默认 1.5）</div>
            </a-form-item>
            <a-form-item label="BM25 b">
              <a-input-number v-model:value="configForm.bm25B" :min="0" :max="1" :step="0.05" style="width: 100%;" />
              <div class="field-hint">文档长度归一化参数（默认 0.75）</div>
            </a-form-item>
            <a-divider>高级选项</a-divider>
            <a-form-item label="启用去重">
              <a-switch v-model:checked="configForm.enableDeduplication" />
              <div class="field-hint">同一文档多个切片仅保留最相关的一个</div>
            </a-form-item>
            <a-form-item label="启用重排序">
              <a-switch v-model:checked="configForm.rerankEnabled" />
            </a-form-item>
            <a-form-item label="重排序数量" v-if="configForm.rerankEnabled">
              <a-input-number v-model:value="configForm.rerankTopN" :min="1" :max="10" style="width: 100%;" />
              <div class="field-hint">重排序后取前 N 个结果</div>
            </a-form-item>
          </a-form>
        </a-tab-pane>
        <a-tab-pane key="embedding" tab="向量配置">
          <a-form layout="vertical" :label-col="{ span: 8 }">
            <a-form-item label="向量服务">
              <a-select v-model:value="configForm.provider" :options="embeddingProviderOptions" />
            </a-form-item>
            <a-form-item label="向量模型">
              <a-select
                v-model:value="configForm.model"
                show-search
                allow-create
                :options="embeddingModelOptions"
                placeholder="选择或输入模型名称"
                style="width: 100%;"
              />
            </a-form-item>
            <a-form-item label="API Key">
              <a-input-password v-model:value="configForm.apiKey" placeholder="输入 API Key（可选）" />
            </a-form-item>
            <a-form-item label="Base URL">
              <a-input v-model:value="configForm.baseUrl" :placeholder="configForm.provider === 'modelscope' ? 'https://api-inference.modelscope.cn/v1（留空使用默认）' : 'https://api.openai.com/v1（留空使用默认）'" />
            </a-form-item>
            <a-divider>分块策略</a-divider>
            <a-form-item label="分块方式">
              <a-select v-model:value="configForm.chunkStrategy">
                <a-select-option value="sentence">按句子（推荐）</a-select-option>
                <a-select-option value="paragraph">按段落</a-select-option>
                <a-select-option value="fixed">固定长度</a-select-option>
              </a-select>
            </a-form-item>
            <a-form-item label="块大小">
              <a-input-number v-model:value="configForm.chunkSize" :min="100" :max="2000" :step="50" style="width: 100%;" />
              <div class="field-hint">每个向量切片的最大字符数（默认 800）</div>
            </a-form-item>
            <a-form-item label="重叠字符">
              <a-input-number v-model:value="configForm.chunkOverlap" :min="0" :max="500" :step="10" style="width: 100%;" />
              <div class="field-hint">相邻块之间的重叠字符数（默认 100）</div>
            </a-form-item>
          </a-form>
        </a-tab-pane>
      </a-tabs>
    </a-modal>
  </a-drawer>
</template>
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
  BookOutlined,
  SettingOutlined
} from '@ant-design/icons-vue'
import { useKnowledgeStore } from '../store/knowledge'
import { parseFileToText } from '../utils/textParser'

const props = defineProps({ open: { type: Boolean, default: false } })
const emit = defineEmits(['update:open'])
const open = ref(props.open)

watch(() => props.open, (v) => {
  open.value = v
  if (v) {
    syncConfig()
  } else {
    // Reset local state when drawer closes
    searchQuery.value = ''
    filterTags.value = []
    selectedDocId.value = ''
    editingDoc.value = null
    editingTags.value = []
    showUploadModal.value = false
    uploadCollectionId.value = ''
    uploadAutoVectorize.value = true
    uploadTags.value = []
  }
})
watch(open, (v) => emit('update:open', v))

const store = useKnowledgeStore()

// 预设知识库数据
const PRESET_COLLECTIONS = [
  { id: 'col-first-aid', name: '急救知识', color: '#f5222d' },
  { id: 'col-cardiovascular', name: '心血管指南', color: '#eb2f96' },
  { id: 'col-drug', name: '药物相互作用', color: '#722ed1' },
  { id: 'col-respiratory', name: '呼吸系统', color: '#13c2c2' },
  { id: 'col-diabetes', name: '糖尿病管理', color: '#fa8c16' }
]

const PRESET_DOCS = [
  // 急救知识
  { id: 'doc-first-aid-1', collectionId: 'col-first-aid', title: '心肺复苏术（CPR）操作指南', tags: ['急救', 'CPR', '心肺复苏', '心脏骤停'], excerpt: '心肺复苏术是抢救心脏骤停患者的关键技能，包括胸外按压和人工呼吸。', content: '心肺复苏术（CPR）操作指南\n\n一、适用场景\n当发现患者突然意识丧失、没有呼吸或呼吸异常、无脉搏时，应立即启动心肺复苏。\n\n二、操作步骤\n1. 确保现场安全\n2. 检查意识与呼吸（看、听、感觉，不超过10秒）\n3. 呼叫急救（拨打120，取AED）\n4. 胸外按压：两乳头连线中点，深度5-6厘米，频率100-120次/分钟\n5. 人工呼吸（可选）：每30次按压后给2次人工呼吸\n6. 使用AED：取得后立即开机，按语音提示操作\n\n三、注意事项\n- 持续按压直到急救人员到达或患者恢复意识\n- 不会人工呼吸时可只进行单纯胸外按压\n- AED分析时必须确保无人接触患者' },
  { id: 'doc-first-aid-2', collectionId: 'col-first-aid', title: '海姆立克急救法（气道异物梗阻）', tags: ['急救', '气道异物', '窒息', '海姆立克'], excerpt: '海姆立克急救法是处理气道异物梗阻的标准方法。', content: '海姆立克急救法（气道异物梗阻）\n\n一、适用场景\n患者进食或异物入口后突然不能说话、不能咳嗽、无法呼吸，用力捏住喉咙，面部或嘴唇发青。\n\n二、操作步骤\n1. 背部叩击：用力在两肩胛骨之间拍打5次\n2. 腹部冲击（海姆立克手法）：站于患者身后，双手环抱腰部，一手握拳抵住患者腹部（脐上约2横指处），快速向内向上冲击5次\n3. 反复交替进行背部叩击和腹部冲击，直到异物排出\n\n三、特殊人群\n- 孕妇/肥胖者：冲击位置改为胸骨下半部\n- 婴儿：采用5次拍背+5次压胸法，面部朝下骑跨在手臂上\n\n四、注意事项\n- 不要在异物可见时用手去掏\n- 冲击时注意力度，避免损伤' },
  { id: 'doc-first-aid-3', collectionId: 'col-first-aid', title: '急性心肌梗死急救流程', tags: ['急救', '心肌梗死', '胸痛', '心脏病'], excerpt: '急性心肌梗死的紧急识别与急救处理流程。', content: '急性心肌梗死急救流程\n\n一、识别典型症状\n- 突发剧烈胸痛或压迫感，持续超过20分钟\n- 疼痛可放射至左臂、颈部、下颌、背部\n- 伴有大汗淋漓、恶心呕吐、呼吸困难\n- 含服硝酸甘油症状不缓解\n\n二、急救步骤\n1. 立即让患者停止活动，安静卧位\n2. 拨打120急救电话\n3. 测量血压（若血压不低，可舌下含服硝酸甘油）\n4. 若患者既往有阿司匹林过敏史，可嚼服300mg阿司匹林\n5. 如患者出现心脏骤停，立即进行心肺复苏\n6. 尽可能获取既往病史和用药信息\n\n三、注意事项\n- 争分夺秒，尽早送至有PCI条件的医院\n- 不要自行驾车送患者\n- 保持患者情绪稳定' },
  // 心血管指南
  { id: 'doc-cardio-1', collectionId: 'col-cardiovascular', title: '高血压诊疗指南', tags: ['高血压', '心血管', '慢性病'], excerpt: '高血压的诊断标准与药物治疗原则。', content: '高血压诊疗指南\n\n一、诊断标准\n- 收缩压≥140mmHg和/或舒张压≥90mmHg（诊室测量）\n- 家庭自测血压≥135/85mmHg\n- 24小时动态血压均值≥130/80mmHg\n\n二、血压控制目标\n- 一般患者：<140/90mmHg\n- 能耐受者：<130/80mmHg\n- 老年患者（≥65岁）：收缩压<150mmHg，可耐受则降至<140mmHg\n\n三、药物治疗\n一线药物：ACEI/ARB、β受体阻滞剂、CCB、利尿剂\n联合用药原则：小剂量开始，2-3种药物联合\n\n四、生活方式干预\n- 限盐（<6g/天）\n- 减重（BMI<24）\n- 戒烟限酒\n- 适量运动（每周≥150分钟中等强度）' },
  { id: 'doc-cardio-2', collectionId: 'col-cardiovascular', title: '房颤抗凝治疗方案', tags: ['房颤', '抗凝', '心血管', '卒中'], excerpt: '心房颤动患者的抗凝治疗决策与用药方案。', content: '房颤抗凝治疗方案\n\n一、卒中风险评估（CHA₂DS₂-VASc评分）\n心衰1分、高血压1分、年龄≥75岁2分、糖尿病1分、血管疾病1分、年龄65-74岁1分、女性1分\n\n二、抗凝适应证\n- CHA₂DS₂-VASc≥2分（男性）/≥3分（女性）：推荐抗凝\n- CHA₂DS₂-VASc=1分（男性）/2分（女性）：考虑抗凝\n\n三、常用抗凝药物\n- 华法林：需定期监测INR，目标2.0-3.0\n- 新型口服抗凝药（NOAC）：达比加群、利伐沙班、阿哌沙班、艾多沙班\n\n四、注意事项\n- 使用抗凝药物前需评估出血风险（HAS-BLED评分）\n- 定期复查肝肾功能\n- 避免突然停药' },
  { id: 'doc-cardio-3', collectionId: 'col-cardiovascular', title: '急性心衰处理流程', tags: ['心衰', '急性', '心血管', '急救'], excerpt: '急性心力衰竭的紧急处理与药物治疗。', content: '急性心衰处理流程\n\n一、紧急评估\n- 生命体征（血压、心率、呼吸、血氧）\n- 体位：端坐位或半卧位，双腿下垂\n- 立即吸氧（SpO2<90%时）\n- 心电监护\n\n二、药物治疗\n1. 利尿剂：呋塞米静脉推注（首选）\n2. 血管扩张剂：硝酸甘油（收缩压>90mmHg时可用）\n3. 正性肌力药：多巴酚丁胺、西地兰（心房颤动伴快心室率时）\n\n三、排除诱因\n- 感染、贫血、电解质紊乱、药物依从性差\n\n四、转运指征\n- 症状不缓解、血流动力学不稳定时\n- 尽早转入ICU或心内科病房' },
  // 药物相互作用
  { id: 'doc-drug-1', collectionId: 'col-drug', title: '常用口服降糖药一览', tags: ['糖尿病', '降糖药', '药物'], excerpt: '各类口服降糖药的作用机制与禁忌。', content: '常用口服降糖药一览\n\n一、双胍类（二甲双胍）\n- 机制：减少肝糖输出，增加外周组织对胰岛素敏感性\n- 优点：不引起低血糖，不增加体重\n- 禁忌：eGFR<30ml/min/1.73m²、严重肝功能不全、造影剂使用前后\n\n二、磺脲类\n- 机制：刺激胰岛β细胞分泌胰岛素\n- 代表：格列美脲、格列齐特\n- 风险：低血糖、体重增加\n\n三、格列奈类\n- 机制：餐时促泌，快速短效\n- 代表：瑞格列奈、那格列奈\n- 适用：餐后血糖升高为主\n\n四、DPP-4抑制剂\n- 机制：抑制胰高血糖素样肽-1（GLP-1）降解\n- 代表：西格列汀、利格列汀\n- 优点：不引起低血糖、体重中性\n\n五、SGLT-2抑制剂\n- 机制：抑制肾脏葡萄糖重吸收\n- 代表：达格列净、恩格列净\n- 额外获益：心肾保护、减重' },
  { id: 'doc-drug-2', collectionId: 'col-drug', title: '抗生素联用禁忌', tags: ['抗生素', '药物相互作用', '禁忌'], excerpt: '常见抗生素之间的配伍禁忌与注意事项。', content: '抗生素联用禁忌\n\n一、同类抗生素叠加毒性\n- 氨基糖苷类+多粘菌素：肾毒性叠加\n- 两种肾毒性药物联用：庆大霉素+万古霉素\n\n二、药效降低\n- 四环素类+金属离子（钙、镁、铝、铁）：形成络合物吸收减少\n- 青霉素类+大环内酯类（阿奇霉素）：后者抑菌，前者杀菌，疗效降低\n- 氟喹诺酮类+抗酸剂/铁剂：吸收显著降低\n\n三、不良反应加重\n- 氟喹诺酮类+茶碱：茶碱血药浓度升高，中毒风险增加\n- 大环内酯类（红霉素）+他汀类（辛伐他汀）：横纹肌溶解风险增加\n- 甲硝唑+酒精：双硫仑样反应\n\n四、繁殖期杀菌剂与快速抑菌剂\n- 青霉素（繁殖期杀菌剂）+氯霉素（快速抑菌剂）：后者拮抗前者效果\n- 提示：同类或作用机制相似的药物通常不宜联用' },
  { id: 'doc-drug-3', collectionId: 'col-drug', title: '抗凝药与抗血小板药联用', tags: ['抗凝', '抗血小板', '药物相互作用'], excerpt: '抗凝药与抗血小板药物联合使用的风险与指征。', content: '抗凝药与抗血小板药联用\n\n一、联合用药指征\n- 房颤合并冠心病支架术后（双联→三联→双联）\n- 深静脉血栓合并外周血管疾病\n\n二、三联治疗（抗凝+双抗血小板）\n- 出血风险显著增加（消化道出血、颅内出血）\n- 通常仅在支架术后早期（1-4周）使用\n- 后续转为双联（抗凝+单抗血小板）\n\n三、药物选择\n- NOAC（利伐沙班、达比加群）优于华法林（出血风险相对较低）\n- 抗血小板药优先选择氯吡格雷（较阿司匹林胃肠道出血风险低）\n- 加用PPI（如泮托拉唑）降低消化道出血风险\n\n四、监测\n- 定期复查血常规（贫血）、粪潜血\n- 关注肾功能变化（抗凝药剂量调整）\n- 避免同时使用NSAIDs' },
  // 呼吸系统
  { id: 'doc-resp-1', collectionId: 'col-respiratory', title: 'COPD急性加重处理', tags: ['COPD', '呼吸', '急性加重'], excerpt: '慢性阻塞性肺疾病急性加重的识别与处理。', content: 'COPD急性加重处理\n\n一、识别急性加重\n- 呼吸困难加重、喘息加剧\n- 咳嗽加剧、痰量增多或痰液变脓\n- 全身不适、发热\n\n二、严重程度评估\n- 呼吸频率>25次/分\n- 心率>110次/分\n- 急性意识障碍\n- 低氧血症（SpO2<90%）或高碳酸血症加重\n\n三、治疗\n1. 支气管舒张剂：SABA（沙丁胺醇）+SAMA（异丙托溴铵）雾化吸入\n2. 糖皮质激素：泼尼松龙30-40mg/天，5-7天\n3. 抗生素：（若疑似细菌感染）阿莫西林/克拉维酸、左氧氟沙星\n4. 氧疗：目标SpO2 88-92%\n5. 无创通气（NIV）：PaCO2>45mmHg，pH<7.35时考虑\n\n四、转诊指征\n- 严重呼吸困难、对初始治疗反应差\n- 意识障碍加重\n- 低氧血症难以纠正' },
  { id: 'doc-resp-2', collectionId: 'col-respiratory', title: '哮喘急性发作处置', tags: ['哮喘', '呼吸', '急性发作'], excerpt: '支气管哮喘急性发作的分级处理与用药。', content: '哮喘急性发作处置\n\n一、严重程度分级\n- 轻度：步行时气短，可平卧，说话正常\n- 中度：说话中断，喜坐位，呼吸急促\n- 重度：休息时气短，前倾位，说话只能单词\n- 危重：不能说话，意识模糊，寂静肺\n\n二、峰流速（PEF）评估\n- PEF>80%预计值：轻度发作\n- PEF 60-80%：中度\n- PEF<60%：重度/危重\n\n三、急救用药\n1. 吸入SABA（沙丁胺醇）：每20分钟4-10喷，共1小时\n2. 糖皮质激素：全身用（口服泼尼松40-60mg或静脉甲泼尼龙）\n3. 危重时：肾上腺素0.3-0.5mg皮下（仅用于过敏性反应）\n4. 吸氧：维持SpO2 93-95%\n\n四、脱离危险后\n- ICS/LABA（吸入糖皮质激素+长效β2激动剂）维持治疗\n- 确认诱因（过敏原、感染、运动）\n- 患者教育：正确使用吸入器' },
  { id: 'doc-resp-3', collectionId: 'col-respiratory', title: '肺部感染抗生素选择', tags: ['肺炎', '抗生素', '呼吸', '感染'], excerpt: '社区获得性肺炎与医院获得性肺炎的抗生素经验性治疗。', content: '肺部感染抗生素选择\n\n一、社区获得性肺炎（CAP）\n1. 无合并症青壮年：\n  - 阿莫西林或多西环素或大环内酯类\n2. 有合并症（心肺疾病、糖尿病等）：\n  - β内酰胺类（阿莫西林/克拉维酸/头孢泊肟）+大环内酯类\n  - 或呼吸氟喹诺酮类（莫西沙星、左氧氟沙星）单用\n\n二、医院获得性肺炎（HAP）/呼吸机相关肺炎（VAP）\n- 轻症：β内酰胺类/β内酰胺酶抑制剂复合制剂\n- 危重：碳青霉烯类±氨基糖苷类±万古霉素\n- 评估耐药菌风险（MRSA、铜绿假单胞菌）\n\n三、抗生素使用原则\n- 48-72小时后评估疗效\n- 体温正常、临床稳定后可口服续贯\n- 疗程：CAP 5-7天，HAP/VAP 7-8天\n- 注意：不要盲目联合广谱抗生素\n\n四、辅助检查\n- 血常规、C反应蛋白、降钙素原\n- 痰培养+药敏\n- 胸部X线或CT' },
  // 糖尿病管理
  { id: 'doc-diab-1', collectionId: 'col-diabetes', title: '糖尿病诊断标准与分型', tags: ['糖尿病', '诊断', '分型'], excerpt: '糖尿病的诊断标准与四种主要分型。', content: '糖尿病诊断标准与分型\n\n一、诊断标准（满足以下任一条件）\n- 空腹血糖（FPG）≥7.0mmol/L（空腹定义：至少8小时无热量摄入）\n- OGTT 2小时血糖≥11.1mmol/L\n- 糖化血红蛋白（HbA1c）≥6.5%\n- 随机血糖≥11.1mmol/L+典型高血糖症状\n\n二、糖尿病前期（糖调节受损）\n- 空腹血糖受损（IFG）：FPG 5.6-6.9mmol/L\n- 糖耐量减低（IGT）：OGTT 2h血糖7.8-11.0mmol/L\n- HbA1c 5.7-6.4%\n\n三、分型\n1. 1型糖尿病：胰岛β细胞破坏，胰岛素绝对缺乏\n2. 2型糖尿病：胰岛素抵抗为主+相对胰岛素分泌不足\n3. 妊娠糖尿病（GDM）：妊娠期间首次发现\n4. 其他特殊类型：单基因突变、胰腺疾病、药物性等\n\n四、1型与2型糖尿病特点\n- 1型：发病年龄轻（<30岁）、起病急、有酮症倾向、需要胰岛素治疗\n- 2型：发病年龄大（>40岁）、起病慢、超重/肥胖常见、口服降糖药有效' },
  { id: 'doc-diab-2', collectionId: 'col-diabetes', title: '糖尿病慢性并发症筛查', tags: ['糖尿病', '并发症', '筛查'], excerpt: '糖尿病主要慢性并发症的筛查频率与目标值。', content: '糖尿病慢性并发症筛查\n\n一、糖尿病视网膜病变\n- 筛查频率：诊断时即进行眼底检查，此后每1-2年一次\n- 方法：散瞳后眼底镜检或眼底照相\n- 转诊指征：任何程度的黄斑水肿、严重NPDR、PDR\n\n二、糖尿病肾病\n- 筛查频率：诊断时及此后每年一次\n- 方法：尿白蛋白/肌酐比值（ACR）+ eGFR\n- 诊断：ACR≥30mg/g或eGFR<60ml/min/1.73m²\n- ACEI/ARB是主要治疗药物\n\n三、糖尿病神经病变\n- 筛查频率：诊断时及此后每年一次\n- 方法：10g尼龙丝检查、音叉振动觉、踝反射\n- 足部溃疡是主要风险事件\n\n四、糖尿病大血管并发症\n- 冠心病：心电图、运动负荷试验（必要时）\n- 脑血管病：颈动脉超声\n- 外周血管病：踝肱指数（ABI）\n\n五、筛查频率总结\n| 并发症 | 筛查频率 |\n|--------|----------|\n| 视网膜病变 | 1-2年 |\n| 肾病 | 1年 |\n| 神经病变 | 1年 |\n| 大血管病变 | 1-2年 |' },
  { id: 'doc-diab-3', collectionId: 'col-diabetes', title: '糖尿病患者血糖控制目标', tags: ['糖尿病', '血糖控制', 'HbA1c'], excerpt: '不同人群的HbA1c控制目标与低血糖防范。', content: '糖尿病患者血糖控制目标\n\n一、一般控制目标\n- HbA1c<7%（相当于平均血糖≈8.6mmol/L）\n- 空腹血糖：4.4-7.2mmol/L\n- 餐后2小时血糖：<10mmol/L\n\n二、个体化目标\n- 较年轻、病程短、无并发症：HbA1c<6.5%（若无低血糖风险）\n- 老年患者、预期寿命有限、严重低血糖史：HbA1c<8.0%或<8.5%\n- 合并心血管疾病：避免严格控制（低血糖增加心血管事件）\n\n三、孕期血糖目标\n- 餐前：≤5.3mmol/L\n- 餐后1小时：≤7.8mmol/L\n- 餐后2小时：≤6.7mmol/L\n- HbA1c<6%（孕前）\n\n四、低血糖防范\n- HbA1c过低（<6%）需警惕低血糖风险\n- 使用胰岛素或磺脲类药物的患者需教育低血糖识别与处理\n- 血糖<3.9mmol/L即需干预\n- 随身携带糖果或葡萄糖片\n\n五、监测频率\n- 胰岛素治疗：每日多次（餐前+睡前）\n- 口服药：每周1-2天（空腹+餐后）\n- 稳定期：每月1-2天' }]

// 状态
const searchQuery = ref('')
const filterTags = ref([])
const selectedDocId = ref('')
const selectedCollectionId = ref('')
const editingDoc = ref(null)
const editingTags = ref([])
const saving = ref(false)
const vectorizing = ref(false)

// 预设选择
const showPresetModal = ref(false)
const selectedPresets = ref([])
const loadingPreset = ref(false)

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

// 一键向量化
const batchVectorizing = ref(false)
const hasUnvectorizedDocs = computed(() => {
  const vectorizedDocIds = new Set(store.chunks.map(c => c.docId))
  return store.docs.some(d => d.content && !vectorizedDocIds.has(d.id))
})

async function batchVectorizeAll() {
  if (batchVectorizing.value) return
  const unvectorized = store.docs.filter(d => {
    const hasVectors = store.chunks.some(c => c.docId === d.id)
    return d.content && !hasVectors
  })
  if (!unvectorized.length) {
    message.info('所有文档均已向量化，无需重复处理')
    return
  }
  batchVectorizing.value = true
  try {
    store.setEmbeddingConfig({
      provider: embeddingConfig.provider,
      model: embeddingConfig.model,
      apiKey: embeddingConfig.apiKey,
      baseUrl: embeddingConfig.baseUrl,
      chunkStrategy: embeddingConfig.chunkStrategy,
      chunkSize: embeddingConfig.chunkSize,
      chunkOverlap: embeddingConfig.chunkOverlap
    })
    let success = 0
    for (const doc of unvectorized) {
      try {
        await store.reembedDoc(doc.id)
        success++
      } catch (e) {
        console.error(`向量化失败: ${doc.title}`, e)
      }
    }
    message.success(`已完成 ${success}/${unvectorized.length} 个文档的向量化`)
  } catch (e) {
    message.error(e?.message || '批量向量化失败')
  } finally {
    batchVectorizing.value = false
  }
}

// 向量化配置（用于单文档操作和批量向量化）
const embeddingConfig = reactive({
  provider: 'modelscope',
  model: 'text-embedding-v3',
  apiKey: '',
  baseUrl: 'https://api-inference.modelscope.cn/v1',
  chunkStrategy: 'sentence',
  chunkSize: 800,
  chunkOverlap: 100
})

function syncConfig() {
  const ec = store.embeddingConfig || {}
  embeddingConfig.provider = ec.provider || 'modelscope'
  embeddingConfig.model = ec.model || 'text-embedding-v3'
  embeddingConfig.apiKey = ec.apiKey || ''
  embeddingConfig.baseUrl = ec.baseUrl || 'https://api-inference.modelscope.cn/v1'
  embeddingConfig.chunkStrategy = ec.chunkStrategy || 'sentence'
  embeddingConfig.chunkSize = ec.chunkSize || 800
  embeddingConfig.chunkOverlap = ec.chunkOverlap || 100
}

// 检索与向量配置弹窗
const showConfigModal = ref(false)
const configForm = reactive({
  strategy: 'hybrid',
  topK: 5,
  keywordWeight: 0.5,
  vectorWeight: 0.5,
  bm25Enabled: true,
  bm25K1: 1.5,
  bm25B: 0.75,
  rerankEnabled: false,
  rerankTopN: 3,
  enableDeduplication: true,
  chunkStrategy: 'sentence',
  chunkSize: 800,
  chunkOverlap: 100,
  provider: 'modelscope',
  model: 'text-embedding-v3',
  apiKey: '',
  baseUrl: 'https://api-inference.modelscope.cn/v1'
})

const embeddingProviderOptions = [
  { label: '魔搭社区（DashScope）', value: 'modelscope' },
  { label: 'OpenAI / 兼容接口', value: 'openai' }
]

const embeddingModelOptions = computed(() => {
  if (configForm.provider === 'modelscope') {
    return [
      { label: 'Qwen/Qwen3-Embedding-8B', value: 'Qwen/Qwen3-Embedding-8B' },
      { label: 'Qwen/Qwen3-Embedding-4B', value: 'Qwen/Qwen3-Embedding-4B' },
      { label: 'text-embedding-v3（默认）', value: 'text-embedding-v3' },
      { label: 'text-embedding-3-small', value: 'text-embedding-3-small' },
      { label: 'text-embedding-3-large', value: 'text-embedding-3-large' }
    ]
  } else {
    return [
      { label: 'text-embedding-3-small', value: 'text-embedding-3-small' },
      { label: 'text-embedding-3-large', value: 'text-embedding-3-large' },
      { label: 'text-embedding-ada-002（兼容）', value: 'text-embedding-ada-002' }
    ]
  }
})

function openConfigModal() {
  const ec = store.embeddingConfig || {}
  const rc = store.retrievalConfig || {}
  configForm.strategy = rc.strategy || 'hybrid'
  configForm.topK = rc.topK ?? 5
  configForm.keywordWeight = rc.keywordWeight ?? 0.5
  configForm.vectorWeight = rc.vectorWeight ?? 0.5
  configForm.bm25Enabled = rc.bm25Enabled ?? true
  configForm.bm25K1 = rc.bm25K1 ?? 1.5
  configForm.bm25B = rc.bm25B ?? 0.75
  configForm.rerankEnabled = rc.rerankEnabled ?? false
  configForm.rerankTopN = rc.rerankTopN ?? 3
  configForm.enableDeduplication = rc.enableDeduplication ?? true
  configForm.chunkStrategy = ec.chunkStrategy || 'sentence'
  configForm.chunkSize = ec.chunkSize || 800
  configForm.chunkOverlap = ec.chunkOverlap || 100
  configForm.provider = ec.provider || 'modelscope'
  configForm.model = ec.model || 'text-embedding-v3'
  configForm.apiKey = ec.apiKey || ''
  configForm.baseUrl = ec.baseUrl || 'https://api-inference.modelscope.cn/v1'
  showConfigModal.value = true
}

function saveConfig() {
  store.setRetrievalConfig({
    strategy: configForm.strategy,
    topK: configForm.topK,
    keywordWeight: configForm.keywordWeight,
    vectorWeight: configForm.vectorWeight,
    bm25Enabled: configForm.bm25Enabled,
    bm25K1: configForm.bm25K1,
    bm25B: configForm.bm25B,
    rerankEnabled: configForm.rerankEnabled,
    rerankTopN: configForm.rerankTopN,
    enableDeduplication: configForm.enableDeduplication
  })
  store.setEmbeddingConfig({
    provider: configForm.provider,
    model: configForm.model,
    apiKey: configForm.apiKey,
    baseUrl: configForm.baseUrl,
    chunkStrategy: configForm.chunkStrategy,
    chunkSize: configForm.chunkSize,
    chunkOverlap: configForm.chunkOverlap
  })
  syncConfig()
  showConfigModal.value = false
  message.success('配置已保存')
}

// 集合
const collections = computed(() => store.collections)

onMounted(() => {
  syncConfig()
})

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

const PRESET_COLLECTION_META = {
  'col-first-aid':       { desc: '常见急症处理与急救技能', count: 3 },
  'col-cardiovascular':   { desc: '心血管疾病诊疗指南', count: 3 },
  'col-drug':            { desc: '常用药物配伍与禁忌', count: 3 },
  'col-respiratory':      { desc: '呼吸系统疾病诊治', count: 3 },
  'col-diabetes':         { desc: '糖尿病患者管理与教育', count: 3 }
}

function getPresetDesc(colId) {
  return PRESET_COLLECTION_META[colId]?.desc || ''
}

function getPresetDocCount(colId) {
  return PRESET_COLLECTION_META[colId]?.count || 0
}

async function loadSelectedPresets() {
  // 如果没有勾选任何集合，默认加载全部 5 个集合
  const toLoad = selectedPresets.value.length > 0
    ? selectedPresets.value
    : PRESET_COLLECTIONS.map(c => c.id)

  loadingPreset.value = true
  try {
    let colsAdded = 0
    let docsAdded = 0
    for (const colId of toLoad) {
      const col = PRESET_COLLECTIONS.find(c => c.id === colId)
      if (col && !store.collections.find(c => c.id === col.id)) {
        store.addCollection({ name: col.name, color: col.color })
        colsAdded++
      }
      const docs = PRESET_DOCS.filter(d => d.collectionId === colId)
      for (const docData of docs) {
        const exists = store.docs.find(d => d.title === docData.title && d.content === docData.content)
        if (!exists) {
          store.addDoc({
            title: docData.title,
            content: docData.content,
            tags: docData.tags,
            excerpt: docData.excerpt,
            collectionId: colId
          })
          docsAdded++
        }
      }
    }
    // mark as initialized so future calls don't double-add
    localStorage.setItem('kb_preset_initialized_v2', 'true')
    message.success(`已加载 ${colsAdded} 个集合，${docsAdded} 篇文档（${toLoad.length} 个预设集合）`)
    showPresetModal.value = false
    selectedPresets.value = []
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
.preset-wrapper {
  max-height: 400px;
  overflow-y: auto;
}

.preset-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 8px;
  border-radius: 6px;
  transition: background 0.2s;
}

.preset-row:hover {
  background: #f5f5f5;
}

.preset-row-check {
  display: flex !important;
  align-items: center;
  gap: 8px;
  min-width: 160px;
}

.preset-row-name {
  font-weight: 500;
  color: #262626;
}

.preset-row-desc {
  flex: 1;
  color: #8c8c8c;
  font-size: 12px;
}

/* 搜索标签 */
.search-label {
  font-size: 12px;
  color: #8c8c8c;
  margin-bottom: 6px;
  display: flex;
  align-items: center;
  gap: 4px;
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

/* Config form hints */
.field-hint {
  font-size: 12px;
  color: #8c8c8c;
  margin-top: 4px;
  line-height: 1.4;
}
</style>
