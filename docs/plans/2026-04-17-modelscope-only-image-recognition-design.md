# 2026-04-17 全局设置与图片识别 ModelScope 单供应商改造设计

## 背景

当前项目在图片识别与多模态会诊链路上存在三个核心问题：

1. 用户界面同时暴露“硅基流动”和“魔搭社区 / ModelScope”两个供应商入口，但用户实际只需要 ModelScope。
2. 图片识别配置在 UI 层是双入口双字段，在存储层却只有一套主配置结构，导致显示、保存、测试与实际调用不一致。
3. 设置页测试链路与真实业务链路没有完全收口到同一入口，导致“测试能过但会诊不可用”或“配置看似正确但实际走了另一条逻辑”的问题。

这次改造的目标不是做多供应商抽象，而是把图片识别与相关多模态会诊能力明确收口为单一的 ModelScope 方案，并保证从设置页到会诊的真实可用性。

## 目标

- 全站删除“硅基流动”作为用户可见供应商选项。
- 图片识别只保留 ModelScope 一套配置、一套测试链路、一套调用链路。
- 统一图片识别配置结构，移除并行字段与双入口状态。
- 自动迁移旧的本地配置，避免已有用户因 provider 或旧字段残留而失效。
- 确保图片识别结果能稳定写入病例信息，并在会诊与最终总结中继续生效。

## 非目标

- 不新增其他供应商支持。
- 不重构整个 AI provider 抽象层。
- 不顺手扩展新的会诊能力或新设置项。
- 不做与本次问题无关的 UI 大改。

## 方案概述

### 1. 产品与交互层

全局设置中的图片识别页改为单供应商方案：

- 固定展示“魔搭社区 / ModelScope”
- 不再出现“硅基流动 / SiliconFlow”文案、卡片、测试按钮或说明
- 不再让用户在图片识别场景中选择供应商

图片识别区域保留以下内容：

- API Key
- Base URL
- 模型名称
- 最大并发数
- 图片识别提示词
- 测试连接
- 测试图像识别

这样用户面对的是一条明确链路，而不是两套看似平行、实际互相覆盖的入口。

### 2. 数据结构收口

图片识别配置统一为单一结构：

```js
{
  enabled: boolean,
  provider: 'modelscope',
  apiKey: string,
  baseUrl: string,
  model: string,
  prompt: string,
  maxConcurrent: number
}
```

删除并停止使用以下旧字段：

- `modelscopeApiKey`
- `modelscopeBaseUrl`
- `modelscopeModel`
- 任何面向图片识别的 `siliconflow` 专属配置字段

`provider` 在图片识别场景中固定为 `modelscope`，不再作为用户可选值存在。

### 3. 旧配置自动迁移

在全局 store 的加载阶段执行迁移，保证已有 localStorage 数据可继续使用。

#### 医生配置迁移

若历史医生配置中存在：

- `provider === 'siliconflow'`

则自动迁移为：

- `provider = 'modelscope'`

同时保留：

- `apiKey`
- `baseUrl`
- `model`
- `customPrompt`

#### 图片识别配置迁移

若历史配置存在以下任一情况：

- `provider === 'siliconflow'`
- 存在 `modelscopeApiKey`
- 存在 `modelscopeBaseUrl`
- 存在 `modelscopeModel`

则合并为统一主配置字段，并最终写回单一结构。

迁移优先级：

1. 若存在 ModelScope 专用副字段，则优先采用它们
2. 否则回退到原主字段
3. 最终固定输出 `provider: 'modelscope'`

目标是刷新页面后即可进入新结构，不要求用户手动重配。

### 4. 调用链统一

图片识别相关链路统一只保留 ModelScope。

#### 模型加载

设置页模型加载统一调用：

- `listModels('modelscope', apiKey, baseUrl)`

#### 连接测试

设置页“测试连接”统一调用：

- `listModels('modelscope', apiKey, baseUrl)`

#### 测试图像识别

设置页“测试图像识别”统一调用：

- `recognizeImageWithModelScope(...)`

#### 实际业务图像识别

业务触发图片识别的地方也统一调用同一条 ModelScope 图片识别方法，不再通过“SiliconFlow 命名函数 + key 前缀改路由”的方式间接跳转。

这确保设置页测试、上传图片识别、实际会诊使用的是同一条链路。

### 5. 会诊多模态链路保证

本项目已有逻辑会把 `patientCase.imageRecognitionResult` 拼入会诊 prompt 与最终总结上下文，因此本次改造不新增会诊功能，而是确保图像识别结果稳定产出并进入现有链路。

需要保证以下流程成立：

1. 在全局设置中配置 ModelScope 多模态模型
2. 测试连接成功
3. 测试图像识别成功
4. 在患者信息上传图片后识别成功
5. 识别结果写入 `patientCase.imageRecognitionResult`
6. 开始会诊时医生上下文能读取该结果
7. 最终总结阶段仍能读取该结果

## 受影响文件

### `src/components/GlobalSettingsModal.vue`

主改动文件。

改动点：

- 删除图片识别中的硅基流动卡片与相关文案
- 删除 ModelScope 专用副字段输入框，统一回主字段
- 删除双测试按钮结构，收口为“测试连接”和“测试图像识别”
- `loadImageModels()` 只走 ModelScope
- `testImageAPI()` 只走 ModelScope
- 删除 `testSiliconFlowConnection()`
- 删除 `testModelscopeConnection()` 这种双分支结构，改成统一方法
- 所有提示文案只保留 ModelScope 语义

### `src/store/global.js`

负责统一默认值与迁移逻辑。

改动点：

- 图片识别默认 provider 固定为 `modelscope`
- 加载图片识别配置时执行旧字段迁移
- 保存图片识别配置时只写统一结构
- 加载医生配置时将 `siliconflow` 自动转为 `modelscope`

### `src/api/imageRecognition.js`

负责图片识别调用收口。

改动点：

- 删除 `recognizeImageWithSiliconFlow`
- 删除通过 key 前缀改 provider 的隐式逻辑
- 仅保留明确的 ModelScope 图像识别入口
- 错误提示统一围绕 ModelScope 输出

### `src/api/models.js`

负责模型加载。

改动点：

- 图片识别场景只使用 `modelscope`
- 若全站范围确认彻底删除硅基流动用户入口，则进一步评估删除 `listSiliconFlowModels`

### `src/components/ConsultationSettingsModal.vue`

负责会诊医生供应商展示。

改动点：

- 删除 `siliconflow` 作为用户可选供应商项
- 保留 `modelscope`
- 保证用户全站无法再选到硅基流动

### 其他需要核验的文件

- `src/components/CaseInputForm.vue`
- `src/components/DiscussionPanel.vue`
- `src/composables/useImageRecognitionQueue.js`

这些文件的目标是确认最终图片识别调用与错误提示都已统一到 ModelScope，不一定需要大改，但必须验证。

## Root cause

### 根因 1

图片识别 UI 是双供应商设计，但 store 只有单主配置结构。

结果是：界面、保存、加载、测试、实际调用并不对应同一份数据。

### 根因 2

设置页测试链路和真实业务链路没有统一入口。

结果是：用户看到的“测试成功”并不总能代表业务调用一定成功。

### 根因 3

产品层仍保留硅基流动这一可见概念，但项目的真实需求是只使用 ModelScope。

结果是：用户多了一个错误决策点，代码也被迫维护多余分支。

## 验证方案

### 用例 1，设置页展示

- 打开全局设置
- 图片识别页只出现 ModelScope 相关内容
- 不再看到硅基流动文案或测试按钮

### 用例 2，模型加载

- 填写 ModelScope API Key
- 点击加载模型
- 模型列表正确返回

### 用例 3，连接测试

- 点击测试连接
- 成功时给出明确成功提示
- 失败时给出明确失败原因
- 不再混用双供应商文案

### 用例 4，测试图像识别

- 上传测试图片
- 调用返回识别文本
- 失败时错误提示只提 ModelScope

### 用例 5，病例输入链路

- 在患者信息中上传图片
- 图片识别结果写入病例
- 页面展示正常

### 用例 6，会诊链路

- 开始会诊
- 医生 prompt 能读取图片识别结果
- 会诊过程无 provider 相关错误
- 最终总结阶段继续可用

## 实施原则

- 只做本次问题要求的收口与修复
- 优先删除歧义入口，而不是继续叠兼容层
- 确保设置页测试和实际业务走同一条链
- 保持最小必要改动，不顺手扩展额外功能

## 结论

本次改造的明确边界是：

**全站删除“硅基流动”，图片识别与相关多模态会诊能力只保留 ModelScope，并确保从设置页配置到实际会诊的整条链路真实可用。**
