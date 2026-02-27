# AstraCare 临床智研台

> **多专家协同 · 知识驱动 · 高准度推理**
> 本内容用于学术研讨，不替代正式诊疗。

[![Vue 3](https://img.shields.io/badge/Vue-3.4-42b883?style=flat-square&logo=vue.js)](https://vuejs.org/)
[![Vite](https://img.shields.io/badge/Vite-5.2-646cff?style=flat-square&logo=vite)
[![Pinia](https://img.shields.io/badge/Pinia-2.1-yellow?style=flat-square)](https://pinia.vuejs.org/)
[![Ant Design Vue](https://img.shields.io/badge/Ant%20Design%20Vue-4.2-1890ff?style=flat-square&logo=ant-design)](https://ant.design/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

## 目录

- [项目简介](#项目简介)
- [核心特性](#核心特性)
- [技术栈](#技术栈)
- [界面预览](#界面预览)
- [快速开始](#快速开始)
- [架构概览](#架构概览)
- [提示词工程](#提示词工程)
- [配置说明](#配置说明)
- [文件结构](#文件结构)
- [主要模块](#主要模块)
- [工作流说明](#工作流说明)
- [知识库与向量检索](#知识库与向量检索)
- [图像识别](#图像识别)
- [数据导出](#数据导出)
- [HarmonyOS 版本](#harmonyos-版本)
- [部署指南](#部署指南)
- [常见问题与调试](#常见问题与调试)
- [贡献指南](#贡献指南)
- [更新日志](#更新日志)
- [版权与责任](#版权与责任)

---

## 项目简介

AstraCare 临床智研台是一套多医生协同 AI 会诊面板系统，支持多家大模型（重点集成魔搭社区/ModelScope），提供多轮讨论、投票淘汰、知识库检索、影像识别、最终总结等功能。

本项目旨在为医疗场景提供一个**可演示、可研究、可扩展**的 AI 辅助会诊界面原型，帮助开发者快速构建类似应用。

### 设计理念

- **模块化架构**：UI 组件、状态管理、API 调用层层解耦，便于替换和扩展
- **多模型协作**：模拟真实会诊场景，多个 AI 医生角色协同讨论
- **知识增强**：支持私有知识库构建，提升 AI 回答的专业性和准确性
- **本地优先**：所有数据本地存储，无后端依赖，保护隐私

---

## 核心特性

| 特性 | 描述 |
|------|------|
| **多 LLM 集成** | 支持 OpenAI、Anthropic、Google Gemini、SiliconFlow、魔搭社区，可按医生维度配置不同模型 |
| **多医生协作** | 可添加多名"医生"角色，轮流发言、自动评估、投票淘汰 |
| **工作流可视化** | 讨论、评估、结束等阶段在状态面板实时呈现，支持暂停/恢复 |
| **知识库检索** | 内置向量库，支持 txt/md/pdf/docx/csv 文档，混合检索（关键词+向量权重） |
| **图像识别** | 支持魔搭社区/硅基流动模型，识别结果自动注入病历 |
| **投票淘汰系统** | 自动解析投票 JSON，标记"不太准确"的医生并淘汰 |
| **会话管理** | 会话本地存档与切换，支持导出多种格式 |
| **HarmonyOS 移植** | 提供 ArkTS/ArkUI 原生应用版本 |

---

## 技术栈

### 前端核心

| 技术 | 用途 |
|------|------|
| **Vue 3** | 响应式前端框架 |
| **Vite** | 构建工具与开发服务器 |
| **Pinia** | 状态管理 |
| **Ant Design Vue 4.x** | UI 组件库 |

### 依赖库

| 库 | 用途 |
|----|------|
| **Axios** | HTTP 请求 |
| **Marked** | Markdown 渲染 |
| **pdfjs-dist** | PDF 文档解析 |
| **mammoth** | Word 文档解析 |
| **PapaParse** | CSV 文件解析 |
| **html-to-image** | 页面截图导出 |
| **jspdf** | PDF 导出 |
| **vuedraggable** | 拖拽排序 |

### 平台支持

- **Web**: Chrome、Firefox、Safari、Edge（现代浏览器）
- **HarmonyOS**: 4.0+（ArkTS/ArkUI）

---

## 界面预览

> 截图位置：`docs/screenshots/`（如有需要可添加）

```
┌─────────────────────────────────────────────────────────────┐
│  AstraCare 临床智研台                              [问诊列表] │
├──────────────────────────┬──────────────────────────────────┤
│                          │  患者信息                         │
│  [讨论区]                │  - 姓名：张三                     │
│                          │  - 年龄：45岁                     │
│  👨‍⚕️ 医生A: 诊断建议...   │  - 症状：...                     │
│                          │                                   │
│  👩‍⚕️ 医生B: 补充意见...   │  [参与医生]                      │
│                          │  ✓ 医生A (Qwen3)                  │
│  👨‍⚕️ 医生A: ...         │  ✓ 医生B (GPT-4)                  │
│                          │                                   │
│  ─────────────────────   │  [状态]                           │
│  [输入框]                │  第 3 轮 | 讨论中                 │
│                          │                                   │
│                          │  [操作按钮]                       │
│                          │  开始会诊 | 暂停 | 结束           │
└──────────────────────────┴──────────────────────────────────┘
```

---

## 快速开始

### 环境要求

- Node.js 18.0 或更高版本
- npm 或 pnpm（推荐 pnpm）

### 安装依赖

```bash
# 使用 npm
npm install

# 或使用 pnpm（推荐）
pnpm install
```

### 开发模式

```bash
pnpm dev
```

访问 `http://localhost:5173`

### 生产构建

```bash
pnpm build
pnpm preview  # 预览构建产物
```

---

## 架构概览

```
┌─────────────────────────────────────────────────────────────────┐
│                         前端应用层                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     App.vue                               │  │
│  │         (顶部品牌区 + 左右两栏布局)                        │  │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                  │
│  ┌───────────────────────────┴───────────────────────────┐     │
│  │                    组件层 (Components)                  │     │
│  │  DiscussionPanel │ StatusPanel │ GlobalSettingsModal  │     │
│  │  KnowledgeBaseDrawer │ SessionListDrawer │ ...        │     │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                  │
│  ┌───────────────────────────┴───────────────────────────┐     │
│  │                    状态层 (Pinia Stores)               │     │
│  │  index.js │ knowledge.js │ sessions.js │ global.js   │     │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                  │
│  ┌───────────────────────────┴───────────────────────────┐     │
│  │                    API 层 (Services)                   │     │
│  │  callAI.js │ models.js │ embeddings.js │ imageRecog  │     │
│  └───────────────────────────────────────────────────────────┘  │
│                              │                                  │
│  ┌───────────────────────────┴───────────────────────────┐     │
│  │                    工具层 (Utils)                      │     │
│  │  prompt.js │ textParser.js │ exportSession.js         │     │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 提示词工程

### 系统提示词

在「全局设置」中可配置：

```javascript
settings.globalSystemPrompt = `你是专业的医疗会诊医生，请：
1. 基于提供的病历信息进行分析
2. 给出诊断建议和依据
3. 考虑鉴别诊断
4. 提出检查和治疗建议
5. 注意回答的准确性和专业性`
```

### 总结提示词

```javascript
settings.summaryPrompt = `请生成结构化的临床总结，包括：
- 诊断意见
- 诊断依据
- 鉴别诊断
- 推荐检查
- 治疗方案
- 随访建议
- 患者教育`
```

### 投票提示词

位于 `utils/prompt.js`，强制输出 JSON 格式：

```json
{
  "targetDoctorId": "医生ID",
  "reason": "简短理由（不超过50字）"
}
```

### 提示词构建策略

- **上下文裁剪**：长病历自动截断，避免超长上下文
- **知识注入**：检索结果加权注入提示词
- **格式约束**：使用 JSON Schema 确保输出可解析

---

## 配置说明

### 环境变量（可选）

创建 `.env` 文件：

```env
# 模型调用超时时间（毫秒）
VITE_AI_TIMEOUT_MS=60000

# 开发代理开关
VITE_ENABLE_PROXY=false
```

### 医生配置

| 字段 | 说明 |
|------|------|
| Provider | 模型供应商（openai/anthropic/modelscope 等） |
| API Key | 访问密钥 |
| Base URL | API 端点（可空，部分供应商自动推断） |
| Model | 模型 ID |
| Temperature | 生成温度（0-2），默认 0.7 |
| Max Tokens | 最大输出 token |

### 魔搭社区配置示例

```
Provider: modelscope
API Key: ms-xxxxxxxxxxxxxxxxxxxxxxxx
Base URL: https://api-inference.modelscope.cn/v1
Model: Qwen/Qwen3-235B-A22B
```

### 向量模型配置

```
Provider: modelscope
API Key: ms-xxxxxxxxxxxxxxxxxxxxxxxx
Model: text-embedding-v3
```

---

## 文件结构

```
ai-medical-consultation-panel/
├── README.zh.md              # 中文文档
├── DEPLOY.zh.md              # 部署指南
├── package.json              # 项目配置
├── vite.config.js            # Vite 配置
├── index.html                # HTML 入口
│
├── src/
│   ├── main.js               # 应用入口
│   ├── App.vue               # 根组件
│   ├── assets/
│   │   └── logo.svg          # 品牌 Logo
│   │
│   ├── api/                  # API 调用层
│   │   ├── callAI.js         # LLM 统一调用
│   │   ├── models.js         # 模型列表获取
│   │   ├── embeddings.js     # 向量生成
│   │   ├── imageRecognition.js # 图像识别
│   │   └── http.js           # HTTP 工具/代理
│   │
│   ├── components/           # UI 组件
│   │   ├── ChatDisplay.vue       # 聊天消息显示
│   │   ├── CaseInputForm.vue     # 病例输入表单
│   │   ├── DiscussionPanel.vue   # 讨论区面板
│   │   ├── StatusPanel.vue       # 状态面板
│   │   ├── VoteTally.vue         # 投票统计
│   │   ├── VotingControls.vue    # 投票控制
│   │   ├── DoctorList.vue        # 医生列表
│   │   ├── SessionListDrawer.vue # 会话列表抽屉
│   │   ├── GlobalSettingsModal.vue   # 全局设置弹窗
│   │   ├── ConsultationSettingsModal.vue # 问诊设置弹窗
│   │   └── KnowledgeBaseDrawer.vue    # 知识库抽屉
│   │
│   ├── store/                # Pinia 状态管理
│   │   ├── index.js          # 会诊流程、投票、总结
│   │   ├── knowledge.js      # 知识库、向量、检索
│   │   ├── sessions.js       # 会话管理、存档
│   │   └── global.js         # 全局配置
│   │
│   ├── composables/          # 组合式函数
│   │   └── useImageRecognitionQueue.js # 图像识别队列
│   │
│   └── utils/                # 工具函数
│       ├── prompt.js         # 提示词构建
│       ├── textParser.js     # 文档解析
│       └── exportSession.js  # 会话导出
│
├── harmony/                  # HarmonyOS 移植版本
│   ├── entry/
│   │   └── src/main/ets/
│   │       ├── components/   # ArkUI 组件
│   │       ├── pages/        # 页面
│   │       ├── common/       # 公共服务
│   │       └── ...
│   └── README.md
│
└── docs/                     # 文档资源（可选）
    └── screenshots/          # 界面截图
```

---

## 主要模块

### 1. 多 LLM 调用层 (`api/callAI.js`)

```javascript
// 支持的供应商
const PROVIDERS = {
  openai: { baseUrl: 'https://api.openai.com/v1' },
  anthropic: { baseUrl: 'https://api.anthropic.com/v1' },
  gemini: { baseUrl: 'https://generativelanguage.googleapis.com/v1' },
  siliconflow: { baseUrl: 'https://api.siliconflow.com/v1' },
  modelscope: { baseUrl: 'https://api-inference.modelscope.cn/v1' }
}
```

### 2. 知识库模块

```
文档上传 → 文本解析 → 切片 → 向量化 → 存储 → 检索
```

**支持格式**：
- 纯文本 (.txt)
- Markdown (.md)
- PDF (.pdf)
- Word (.docx)
- CSV (.csv)

### 3. 会诊流程

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ 开始会诊 │ -> │ 医生讨论 │ -> │ 自动投票 │ -> │ 结束/总结 │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
                            │                  │
                            v                  v
                     ┌──────────┐        ┌──────────┐
                     │ 淘汰医生 │        │ 生成总结 │
                     └──────────┘        └──────────┘
```

### 4. 投票与淘汰

- **投票频率**：每轮讨论结束后自动触发
- **淘汰规则**：最高票且唯一 → 标记"不太准确" → 淘汰
- **回退机制**：JSON 解析失败时使用默认策略

### 5. 图像识别

```javascript
// 支持的图像识别供应商
const IMAGE_PROVIDERS = {
  modelscope: { baseUrl: 'https://api-inference.modelscope.cn/v1' },
  siliconflow: { baseUrl: 'https://api.siliconflow.com/v1' }
}
```

---

## 工作流说明

### 完整会诊流程

1. **准备阶段**
   - 配置参与医生（选择模型、API Key）
   - 填写患者信息
   - 可选：上传影像识别
   - 可选：上传知识库文档并向量化

2. **会诊阶段**
   - 点击「开始会诊」
   - 医生按顺序轮流发言
   - 实时显示讨论内容
   - 支持暂停/恢复

3. **投票阶段**
   - 每轮结束后自动投票
   - 解析投票结果
   - 标记并淘汰"不太准确"的医生

4. **结束条件**
   - 只剩 1 名医生
   - 达到连续未淘汰轮数上限
   - 手动点击「结束会诊」

5. **总结阶段**
   - 由优先医生生成临床总结
   - 总结包含诊断、依据、鉴别、检查、治疗、随访

---

## 知识库与向量检索

### 文档处理流程

```
1. 上传文档
2. 解析文本（pdfjs/mammoth/papaparse）
3. 智能切片（按段落/长度）
4. 生成向量（embedding API）
5. 存储到本地
```

### 检索策略

采用**混合检索**：

```javascript
// 检索得分 = α × 向量相似度 + β × 关键词权重
const score = alpha * vectorSimilarity + beta * keywordMatch
```

- **Top-K**：默认返回 5 条结果
- **阈值过滤**：低于 0.5 的结果不注入

### 向量模型配置

```javascript
// 推荐模型
const EMBEDDING_MODELS = {
  modelscope: 'text-embedding-v3',
  openai: 'text-embedding-3-small'
}
```

---

## 图像识别

### 支持的输入

| 方式 | 说明 |
|------|------|
| 本地上传 | 选择图片文件（PNG/JPG） |
| URL 输入 | 粘贴图片链接 |
| 剪贴板 | 直接粘贴截图 |

### 使用流程

1. 进入「图片识别设置」
2. 选择供应商和模型
3. 填入 API Key
4. 上传图片或输入 URL
5. 点击「开始识别」
6. 识别结果自动注入病例

### 推荐模型

| 供应商 | 模型 | 特点 |
|--------|------|------|
| 魔搭 | Qwen/Qwen3-VL-235B-A22B-Instruct | 多模态能力强 |
| 硅基流动 | Qwen-VL-Max | 性价比高 |

---

## 数据导出

### 支持的导出格式

| 格式 | 说明 | 依赖 |
|------|------|------|
| **Markdown** | 纯文本，易于分享 | 内置 |
| **PDF** | 矢量格式，适合打印 | jspdf |
| **图片** | 截图保存 | html-to-image |

### 导出内容

- 患者信息
- 完整讨论记录
- 投票结果
- 最终总结



## 常见问题与调试

### 模型相关

| 问题 | 解决方案 |
|------|----------|
| 401/403 错误 | 检查 API Key 权限和格式 |
| 模型 404 | 确认模型 ID 正确，查看是否在服务列表中 |
| 响应超时 | 调大 `VITE_AI_TIMEOUT_MS` 值 |
| 内容被截断 | 减小 `maxTokens` 或优化提示词 |

### 知识库相关

| 问题 | 解决方案 |
|------|----------|
| 文档解析失败 | 检查文件格式是否支持 |
| 向量生成失败 | 确认向量模型 ID 正确 |
| 检索无结果 | 尝试增大 Top-K 或调整相似度阈值 |

### 界面相关

| 问题 | 解决方案 |
|------|----------|
| 布局错乱 | 尝试刷新页面或清除缓存 |
| 字体显示异常 | 检查系统字体支持 |
| 移动端适配 | 当前主要为桌面端优化 |

### 调试技巧

1. 打开浏览器开发者工具（F12）
2. 查看 Console 错误信息
3. 切换到 Network 标签查看 API 请求
4. 在「全局设置」中使用「测试调用」功能


1. **Bug 反馈**：通过 Issue 报告问题
2. **功能建议**：提出新功能的想法
3. **代码贡献**：提交 Pull Request
4. **文档完善**：改进文档质量

### 开发规范

- 使用 ESLint 保持代码风格
- 提交信息遵循 Conventional Commits
- 保持模块化，便于维护和测试


---

## 更新日志

### v0.1.0 (2025-01)

- 初始版本发布
- 多医生协作讨论功能
- 知识库向量检索
- 图像识别集成
- HarmonyOS 移植版本

详细变更请查看 [CHANGELOG.md](CHANGELOG.md)

---



