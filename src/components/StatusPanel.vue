<template>
  <a-card title="状态面板" :bordered="false" class="status-panel-card">
    <!-- ========== 快捷操作栏 ========== -->
    <div class="quick-actions-bar">
      <a-button
        type="primary"
        size="small"
        @click="handleQuickStart"
        :disabled="!canStartConsult"
      >
        <template #icon><PlayCircleOutlined /></template>
        快速开始会诊
      </a-button>
      <a-button size="small" @click="$emit('open-settings')" :disabled="isExportingSession">
        <template #icon><SettingOutlined /></template>
        问诊设置
      </a-button>
      <a-button size="small" @click="handleTogglePause" v-if="isRunning">
        <template #icon><PauseCircleOutlined v-if="!store.workflow.paused" /><PlayCircleOutlined v-else /></template>
        {{ store.workflow.paused ? '恢复' : '暂停' }}
      </a-button>
    </div>

    <!-- ========== 卡片1：会诊进度 ========== -->
    <a-card size="small" class="section-card" :body-style="{ padding: '10px 12px' }">
      <template #title>
        <span class="section-title">
          <FieldTimeOutlined class="section-icon" />
          会诊进度
        </span>
      </template>
      <div class="phase-row">
        <a-tag :color="phaseColor" class="phase-tag">{{ phaseText }}</a-tag>
        <span class="phase-label">第 {{ store.workflow.currentRound }} 轮</span>
        <a-tooltip v-if="store.workflow.phase === 'discussion'" :title="store.workflow.paused ? '已暂停' : '进行中'">
          <span :class="['run-dot', store.workflow.paused ? 'paused' : 'active']"></span>
        </a-tooltip>
      </div>
      <div class="stat-row">
        <span class="stat-label">连续未标</span>
        <span class="stat-value">{{ store.workflow.roundsWithoutElimination }}</span>
        <span class="stat-unit">轮</span>
        <span class="stat-hint">（上限 {{ store.settings.maxRoundsWithoutElimination }}）</span>
      </div>
      <template v-if="store.workflow.phase === 'discussion' && roundProgress.total > 0">
        <div class="progress-row">
          <span class="progress-label">{{ roundProgress.current || '等待中' }}</span>
          <span class="progress-count">{{ roundProgress.done }}/{{ roundProgress.total }}</span>
        </div>
        <a-progress
          :percent="roundProgress.percent"
          :status="store.workflow.paused ? 'normal' : 'active'"
          :show-info="false"
          size="small"
        />
      </template>
    </a-card>

    <!-- ========== 卡片2：患者信息 ========== -->
    <a-card size="small" class="section-card" :body-style="{ padding: '10px 12px' }">
      <template #title>
        <span class="section-title">
          <UserOutlined class="section-icon" />
          患者信息
        </span>
      </template>
      <div class="patient-info-grid">
        <div class="patient-field">
          <span class="field-label">姓名</span>
          <span class="field-value">{{ store.patientCase.name || '—' }}</span>
        </div>
        <div class="patient-field">
          <span class="field-label">年龄</span>
          <span class="field-value">{{ store.patientCase.age ?? '—' }}</span>
        </div>
        <div class="patient-field full-width" v-if="store.patientCase.gender">
          <span class="field-label">性别</span>
          <span class="field-value">{{ genderText }}</span>
        </div>
      </div>
      <div class="patient-text-row" v-if="store.patientCase.pastHistory">
        <span class="field-label">既往</span>
        <ExpandableText :text="store.patientCase.pastHistory" />
      </div>
      <div class="patient-text-row" v-if="store.patientCase.currentProblem">
        <span class="field-label">主诉</span>
        <ExpandableText :text="store.patientCase.currentProblem" />
      </div>
      <div class="patient-text-row" v-if="hasImageRecognitions && store.patientCase.imageRecognitionResult">
        <span class="field-label">图片</span>
        <ExpandableText :text="store.patientCase.imageRecognitionResult" />
      </div>
    </a-card>

    <!-- ========== 卡片3：知识库片段 ========== -->
    <a-card size="small" class="section-card" :body-style="{ padding: '10px 12px' }">
      <template #title>
        <span class="section-title">
          <BookOutlined class="section-icon" />
          已选知识库片段
          <a-badge
            :count="selectedKnowledge.length"
            :number-style="{ backgroundColor: '#1890ff', fontSize: '10px', height: '16px', lineHeight: '16px', minWidth: '16px' }"
            style="margin-left: 6px"
          />
        </span>
      </template>
      <a-empty
        v-if="!selectedKnowledge.length"
        :image="Empty.PRESENTED_IMAGE_SIMPLE"
        description="尚未选择知识片段"
        style="margin: 4px 0"
      >
        <template #description>
          <span style="font-size: 12px; color: #bfbfbf;">可在问诊设置中添加</span>
        </template>
      </a-empty>
      <div v-else class="knowledge-list">
        <div
          v-for="item in selectedKnowledge"
          :key="item.id"
          class="knowledge-item"
        >
          <div class="knowledge-item-main">
            <FileTextOutlined class="knowledge-icon" />
            <div class="knowledge-item-body">
              <div class="knowledge-title">{{ item.title }}</div>
              <div class="knowledge-excerpt" v-if="item.desc">{{ item.desc }}</div>
            </div>
            <a-popconfirm
              title="移除此片段？"
              ok-text="移除"
              cancel-text="取消"
              @confirm="removeKnowledge(item.id)"
            >
              <button class="knowledge-remove-btn" title="移除">
                <CloseOutlined />
              </button>
            </a-popconfirm>
          </div>
        </div>
      </div>
    </a-card>

    <!-- ========== 卡片4：医生团队 ========== -->
    <a-card size="small" class="section-card" :body-style="{ padding: '10px 12px' }">
      <template #title>
        <span class="section-title">
          <TeamOutlined class="section-icon" />
          医生团队
          <a-badge
            :count="activeDoctorCount"
            :number-style="{ backgroundColor: '#52c41a', fontSize: '10px', height: '16px', lineHeight: '16px', minWidth: '16px' }"
            style="margin-left: 6px"
          />
        </span>
      </template>
      <DoctorList :doctors="store.doctors" />
    </a-card>

    <!-- ========== 投票阶段 ========== -->
    <template v-if="store.workflow.phase === 'voting'">
      <a-card size="small" class="section-card" :body-style="{ padding: '10px 12px' }">
        <VoteTally :doctors="store.doctors" :votes="store.lastRoundVotes" />
      </a-card>
    </template>

    <!-- ========== 会诊结束 ========== -->
    <template v-if="store.workflow.phase === 'finished'">
      <a-card size="small" class="section-card finished-card" :body-style="{ padding: '10px 12px' }">
        <div class="finished-header">
          <CheckCircleOutlined class="finished-icon" />
          <span class="finished-title">会诊已结束</span>
          <span class="finished-winner">{{ winnerText }}</span>
        </div>
        <div class="finished-actions">
          <a-button
            type="primary"
            size="small"
            @click="summaryOpen = true"
            :disabled="store.finalSummary.status !== 'ready'"
          >
            <template #icon><SolutionOutlined /></template>
            查看最终答案
          </a-button>
          <a-tag
            v-if="store.finalSummary.status === 'pending'"
            color="processing"
            style="font-size: 11px;"
          >生成中...</a-tag>
          <a-tag
            v-else-if="store.finalSummary.status === 'ready'"
            color="success"
            style="font-size: 11px;"
          >{{ store.finalSummary.adoptedDoctorName || store.finalSummary.doctorName }}</a-tag>
          <a-tag v-else-if="store.finalSummary.status === 'error'" color="error" style="font-size: 11px;">失败</a-tag>
        </div>
      </a-card>
    </template>

    <!-- ========== 底部操作栏 ========== -->
    <div class="bottom-actions">
      <a-button
        size="small"
        @click="exportCurrentSessionAsPDF"
        :loading="isExportingSession"
        :disabled="isExportingSession"
      >
        <template #icon><FilePdfOutlined /></template>
        导出 PDF
      </a-button>
      <a-button
        size="small"
        @click="exportCurrentSessionAsImage"
        :loading="isExportingSession"
        :disabled="isExportingSession"
      >
        <template #icon><FileImageOutlined /></template>
        导出图片
      </a-button>
      <a-popconfirm title="确认重置流程？" @confirm="resetAll" :disabled="isExportingSession">
        <a-button danger size="small" :disabled="isExportingSession">
          <template #icon><ReloadOutlined /></template>
          重置
        </a-button>
      </a-popconfirm>
    </div>
  </a-card>

  <!-- ========== 最终答案弹窗 ========== -->
  <a-modal
    v-model:open="summaryOpen"
    title="最终答案"
    width="900px"
    :footer="null"
    class="final-answer-modal"
  >
    <div v-if="store.finalSummary.status === 'ready'">
      <!-- 操作栏 -->
      <div class="summary-toolbar">
        <div class="summary-meta-tag">
          <a-tag color="blue">
            {{ store.finalSummary.adoptedDoctorName && store.finalSummary.adoptedDoctorName !== store.finalSummary.doctorName
              ? `已采纳 ${store.finalSummary.adoptedDoctorName} 的意见`
              : `由 ${store.finalSummary.doctorName} 生成` }}
          </a-tag>
        </div>
        <div class="summary-toolbar-actions">
          <a-button
            type="text"
            size="small"
            :icon="h(CopyOutlined)"
            @click="copySummary"
          >
            {{ copyLabel }}
          </a-button>
          <a-button
            type="dashed"
            size="small"
            :icon="h(FileImageOutlined)"
            @click="exportSummaryImage"
          >
            导出图片
          </a-button>
        </div>
      </div>

      <!-- 答案卡片 -->
      <div ref="exportRef" class="final-card">
        <div class="final-card-header">
          <div class="final-title">
            <span class="final-title-icon">&#x1F3AF;</span>
            最终答案
          </div>
        </div>

        <!-- 患者摘要 -->
        <div class="case-brief">
          <div class="case-brief-grid">
            <div v-if="store.patientCase.name">
              <span class="case-brief-label">患者</span>
              <span class="case-brief-value">{{ store.patientCase.name }}</span>
            </div>
            <div v-if="store.patientCase.age !== null && store.patientCase.age !== undefined">
              <span class="case-brief-label">年龄</span>
              <span class="case-brief-value">{{ store.patientCase.age }}</span>
            </div>
            <div v-if="store.patientCase.gender">
              <span class="case-brief-label">性别</span>
              <span class="case-brief-value">{{ genderText }}</span>
            </div>
          </div>
          <div class="case-brief-row" v-if="store.patientCase.pastHistory">
            <span class="case-brief-label">既往</span>
            <span>{{ store.patientCase.pastHistory }}</span>
          </div>
          <div class="case-brief-row" v-if="store.patientCase.currentProblem">
            <span class="case-brief-label">主诉</span>
            <span>{{ store.patientCase.currentProblem }}</span>
          </div>
          <div class="case-brief-row" v-if="store.patientCase.imageRecognitionResult">
            <span class="case-brief-label">图片</span>
            <span>{{ store.patientCase.imageRecognitionResult }}</span>
          </div>
        </div>

        <!-- Markdown 内容 -->
        <div
          v-html="renderMarkdown(store.finalSummary.content)"
          class="final-summary-md"
        ></div>

        <!-- 底部免责声明 -->
        <div class="final-disclaimer">
          本内容仅供参考，身体不适请尽早就医
        </div>
      </div>
    </div>
    <div v-else-if="store.finalSummary.status === 'pending'">
      <div class="summary-loading">
        <a-spin tip="最终答案生成中，请稍候..." />
      </div>
    </div>
    <div v-else-if="store.finalSummary.status === 'error'">
      <a-alert type="error" :message="store.finalSummary.content" />
    </div>
  </a-modal>
</template>

<script setup>
import { computed, ref, h } from "vue";
import { marked } from "marked";
import { message, Empty } from "ant-design-vue";
import {
  PlayCircleOutlined,
  PauseCircleOutlined,
  SettingOutlined,
  FieldTimeOutlined,
  UserOutlined,
  BookOutlined,
  TeamOutlined,
  FileTextOutlined,
  CloseOutlined,
  CheckCircleOutlined,
  SolutionOutlined,
  FilePdfOutlined,
  FileImageOutlined,
  ReloadOutlined,
  CopyOutlined,
} from "@ant-design/icons-vue";

import { useConsultStore } from "../store";
import { useSessionsStore } from "../store/sessions";
import { useKnowledgeStore } from "../store/knowledge";
import DoctorList from "./DoctorList.vue";
import VoteTally from "./VoteTally.vue";
import ExpandableText from "./ExpandableText.vue";
import { exportSessionAsPDF, exportSessionAsImage } from "../utils/exportSession";

const emit = defineEmits(["open-settings"]);

const store = useConsultStore();
const sessions = useSessionsStore();
const knowledge = useKnowledgeStore();
const summaryOpen = ref(false);
const exportRef = ref(null);
const isExportingSession = ref(false);
const copyLabel = ref("复制");

const imageRecognitions = computed(() => store.patientCase?.imageRecognitions || []);
const hasImageRecognitions = computed(
  () =>
    (imageRecognitions.value && imageRecognitions.value.length > 0) ||
    !!store.patientCase?.imageRecognitionResult
);

const isRunning = computed(
  () =>
    store.workflow.phase === "discussion" || store.workflow.phase === "voting"
);

const canStartConsult = computed(() => {
  return (
    !isExportingSession.value &&
    !!store.patientCase.name &&
    !!store.patientCase.currentProblem &&
    store.doctors &&
    store.doctors.length > 0 &&
    (store.workflow.phase === "setup" || store.workflow.phase === "finished")
  );
});

const activeDoctorCount = computed(
  () => store.doctors.filter((d) => d.status === "active").length
);

const genderText = computed(() => {
  const g = store.patientCase.gender;
  if (g === "male") return "男";
  if (g === "female") return "女";
  if (g === "other") return "其他";
  return g || "";
});

const phaseColor = computed(() => {
  switch (store.workflow.phase) {
    case "setup":     return "default";
    case "discussion":return "processing";
    case "voting":    return "warning";
    case "finished":  return "success";
    default:          return "default";
  }
});

const phaseText = computed(() => {
  switch (store.workflow.phase) {
    case "setup":     return "准备阶段";
    case "discussion":return "讨论中";
    case "voting":    return "评估中";
    case "finished":  return "已结束";
    default:          return store.workflow.phase;
  }
});

const winnerText = computed(() => {
  const actives = store.doctors.filter((d) => d.status === "active");
  if (actives.length === 1) return `答案来自：${actives[0].name}`;
  return "已达轮数上限";
});

const roundProgress = computed(() => {
  const p = store.workflow?.progress || {};
  const total = p.total || 0;
  const done = p.done || 0;
  const current = p.current || "";
  const percent = total > 0 ? Math.min(100, Math.round((done / total) * 100)) : 0;
  return { total, done, current, percent };
});

const selectedKnowledge = computed(() => {
  const ids = Array.isArray(store.selectedKnowledgeIds) ? store.selectedKnowledgeIds : [];
  return ids
    .map((id) => knowledge.docMap.get(id))
    .filter(Boolean)
    .map((doc) => ({
      id: doc.id,
      title: doc.title || "未命名文档",
      desc: doc.excerpt || (doc.content || "").slice(0, 100),
    }));
});

function handleQuickStart() {
  try {
    store.startConsultation();
  } catch (e) {
    message.warning(e.message);
  }
}

function handleTogglePause() {
  store.togglePause();
}

function removeKnowledge(id) {
  const ids = store.selectedKnowledgeIds.filter((k) => k !== id);
  store.setSelectedKnowledge(ids);
  message.success("已移除知识片段");
}

function renderMarkdown(text) {
  try {
    return marked.parse(text || "");
  } catch (e) {
    return text;
  }
}

async function copySummary() {
  try {
    await navigator.clipboard.writeText(store.finalSummary.content || "");
    copyLabel.value = "已复制!";
    setTimeout(() => { copyLabel.value = "复制"; }, 2000);
  } catch {
    message.error("复制失败，请手动选择内容");
  }
}

async function exportSummaryImage() {
  const node = exportRef.value;
  if (!node) return;
  try {
    const dataUrl = await window.htmlToImage.toPng(node, { pixelRatio: 2, cacheBust: true });
    const a = document.createElement("a");
    const fileBase = store.patientCase?.name
      ? `${store.patientCase.name}-最终答案`
      : "最终答案";
    a.href = dataUrl;
    a.download = `${fileBase}.png`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    message.success("图片导出成功");
  } catch (e) {
    console.error(e);
    message.error("导出图片失败");
  }
}

async function exportCurrentSessionAsPDF() {
  try {
    isExportingSession.value = true;
    const sessionData = sessions.getSessionData(sessions.currentId);
    const meta = sessions.current;

    if (!sessionData) {
      message.error("会诊数据不存在");
      return;
    }

    const fileName = `${meta?.name || "会诊报告"}.pdf`;
    await exportSessionAsPDF(meta, sessionData, fileName);
    message.success("PDF 导出成功");
  } catch (error) {
    console.error("Export PDF error:", error);
    message.error("导出 PDF 失败：" + (error?.message || "未知错误"));
  } finally {
    isExportingSession.value = false;
  }
}

async function exportCurrentSessionAsImage() {
  try {
    isExportingSession.value = true;
    const sessionData = sessions.getSessionData(sessions.currentId);
    const meta = sessions.current;

    if (!sessionData) {
      message.error("会诊数据不存在");
      return;
    }

    const fileName = `${meta?.name || "会诊报告"}.png`;
    await exportSessionAsImage(meta, sessionData, fileName);
    message.success("图片导出成功");
  } catch (error) {
    console.error("Export image error:", error);
    message.error("导出图片失败：" + (error?.message || "未知错误"));
  } finally {
    isExportingSession.value = false;
  }
}

function resetAll() {
  store.workflow = {
    phase: "setup",
    currentRound: 0,
    roundsWithoutElimination: 0,
    activeTurn: null,
    turnQueue: [],
    paused: false,
  };
  store.doctors = store.doctors.map((d) => ({
    ...d,
    status: "active",
    votes: 0,
  }));
  store.discussionHistory = [];
  store.lastRoundVotes = [];
  store.patientCase = {
    name: "",
    gender: "",
    age: null,
    pastHistory: "",
    currentProblem: "",
    imageRecognitionResult: "",
    imageRecognitions: [],
  };
  store.finalSummary = {
    status: "idle",
    doctorId: null,
    doctorName: "",
    content: "",
    usedPrompt: "",
    adoptedDoctorId: null,
    adoptedDoctorName: "",
  };
  store.setSelectedKnowledge([]);
}
</script>

<style scoped>
/* ========== 布局基础 ========== */
.status-panel-card {
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.status-panel-card :deep(.ant-card-body) {
  flex: 1;
  padding: 12px;
  overflow-y: auto;
  scrollbar-width: thin;
}
.status-panel-card :deep(.ant-card-body::-webkit-scrollbar) {
  width: 4px;
}

/* ========== 快捷操作栏 ========== */
.quick-actions-bar {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-bottom: 10px;
  padding-bottom: 10px;
  border-bottom: 1px solid #f0f0f0;
}

/* ========== 卡片分组 ========== */
.section-card {
  margin-bottom: 8px;
  border-radius: 8px;
  overflow: hidden;
}
.section-card :deep(.ant-card-head) {
  min-height: 36px;
  padding: 0 12px;
  background: #fafafa;
  border-bottom: 1px solid #f0f0f0;
}
.section-card :deep(.ant-card-head-title) {
  padding: 4px 0;
  font-size: 13px;
}
.section-title {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: 13px;
  font-weight: 600;
  color: #333;
}
.section-icon {
  color: #1890ff;
  font-size: 13px;
}

/* ========== 会诊进度 ========== */
.phase-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 4px;
}
.phase-tag {
  font-size: 12px;
  line-height: 1.2;
}
.phase-label {
  font-size: 13px;
  color: #595959;
  font-weight: 500;
}
.run-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-left: 2px;
}
.run-dot.active {
  background: #52c41a;
  box-shadow: 0 0 4px #52c41a;
  animation: pulse 1.5s infinite;
}
.run-dot.paused {
  background: #faad14;
}
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}
.stat-row {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: #8c8c8c;
  margin-bottom: 4px;
}
.stat-label { }
.stat-value { font-weight: 600; color: #d46b08; }
.stat-unit { }
.stat-hint { color: #bfbfbf; }
.progress-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 11px;
  color: #8c8c8c;
  margin-bottom: 2px;
}
.progress-label { }
.progress-count { }

/* ========== 患者信息 ========== */
.patient-info-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 0 16px;
  margin-bottom: 4px;
}
.patient-field {
  display: flex;
  align-items: baseline;
  gap: 4px;
  min-width: 60px;
}
.patient-field.full-width {
  width: 100%;
}
.field-label {
  font-size: 11px;
  color: #bfbfbf;
  white-space: nowrap;
}
.field-value {
  font-size: 13px;
  color: #262626;
  font-weight: 500;
}
.patient-text-row {
  display: flex;
  align-items: baseline;
  gap: 6px;
  margin-top: 2px;
  font-size: 12px;
}

/* ========== 知识库片段 ========== */
.knowledge-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.knowledge-item {
  background: #f5f9ff;
  border: 1px solid #d6e4ff;
  border-radius: 6px;
  padding: 6px 8px;
}
.knowledge-item-main {
  display: flex;
  align-items: flex-start;
  gap: 6px;
}
.knowledge-icon {
  color: #1890ff;
  font-size: 13px;
  margin-top: 2px;
  flex-shrink: 0;
}
.knowledge-item-body {
  flex: 1;
  min-width: 0;
}
.knowledge-title {
  font-size: 12px;
  font-weight: 500;
  color: #333;
  line-height: 1.4;
}
.knowledge-excerpt {
  font-size: 11px;
  color: #8c8c8c;
  line-height: 1.4;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  margin-top: 1px;
}
.knowledge-remove-btn {
  background: none;
  border: none;
  padding: 2px;
  cursor: pointer;
  color: #bfbfbf;
  font-size: 10px;
  line-height: 1;
  border-radius: 3px;
  flex-shrink: 0;
  transition: color 0.2s, background 0.2s;
}
.knowledge-remove-btn:hover {
  color: #ff4d4f;
  background: #fff1f0;
}

/* ========== 会诊结束卡片 ========== */
.finished-card :deep(.ant-card-body) {
  background: #f6ffed;
}
.finished-header {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
}
.finished-icon {
  color: #52c41a;
  font-size: 16px;
}
.finished-title {
  font-size: 14px;
  font-weight: 600;
  color: #389e0d;
}
.finished-winner {
  font-size: 12px;
  color: #52c41a;
}
.finished-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

/* ========== 底部操作栏 ========== */
.bottom-actions {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  padding-top: 10px;
  border-top: 1px solid #f0f0f0;
  margin-top: 4px;
}

/* ========== 最终答案弹窗 ========== */
.summary-toolbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}
.summary-meta-tag {
  display: flex;
  align-items: center;
  gap: 6px;
}
.summary-toolbar-actions {
  display: flex;
  gap: 6px;
}

.final-card {
  background: #ffffff;
  border: 1px solid #bae0ff;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 4px 12px rgba(24, 144, 255, 0.08);
}
.final-card-header {
  margin-bottom: 14px;
  padding-bottom: 12px;
  border-bottom: 2px solid #e6f4ff;
}
.final-title {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 22px;
  font-weight: 800;
  color: #0958d9;
}
.final-title-icon {
  font-size: 20px;
}

.case-brief {
  background: #f5f9ff;
  border: 1px solid #d6e4ff;
  border-radius: 8px;
  padding: 10px 14px;
  margin-bottom: 14px;
}
.case-brief-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 20px;
  margin-bottom: 6px;
}
.case-brief-grid > div {
  display: flex;
  align-items: baseline;
  gap: 4px;
}
.case-brief-label {
  font-size: 11px;
  color: #8c8c8c;
}
.case-brief-value {
  font-size: 13px;
  color: #333;
  font-weight: 500;
}
.case-brief-row {
  display: flex;
  align-items: baseline;
  gap: 6px;
  font-size: 12px;
  color: #595959;
  margin-top: 2px;
}

.final-summary-md :deep(h1) { font-size: 18px; margin: 14px 0 8px; color: #0958d9; border-bottom: 1px solid #e6f4ff; padding-bottom: 4px; }
.final-summary-md :deep(h2) { font-size: 16px; margin: 12px 0 6px; color: #1677ff; }
.final-summary-md :deep(h3) { font-size: 14px; margin: 10px 0 6px; color: #4096ff; }
.final-summary-md :deep(p) { margin: 0 0 8px; font-size: 13px; line-height: 1.7; color: #333; }
.final-summary-md :deep(ul),
.final-summary-md :deep(ol) { padding-left: 20px; margin: 0 0 8px; }
.final-summary-md :deep(li) { font-size: 13px; line-height: 1.7; color: #333; margin-bottom: 2px; }
.final-summary-md :deep(table) { border-collapse: collapse; width: 100%; margin-bottom: 8px; font-size: 13px; }
.final-summary-md :deep(th) { background: #e6f4ff; padding: 6px 10px; border: 1px solid #91caff; font-weight: 600; }
.final-summary-md :deep(td) { padding: 5px 10px; border: 1px solid #d9d9d9; }
.final-summary-md :deep(strong) { color: #0958d9; }
.final-summary-md :deep(code) { background: #f5f5f5; padding: 1px 4px; border-radius: 3px; font-size: 12px; }

.final-disclaimer {
  margin-top: 16px;
  text-align: center;
  font-size: 11px;
  color: #bfbfbf;
  padding-top: 10px;
  border-top: 1px dashed #f0f0f0;
}

.summary-loading {
  padding: 40px 0;
  text-align: center;
}
</style>
