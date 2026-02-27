# 部署与迁移指南（AstraCare 临床智研台）

> 场景：将本项目拷贝/打包到另一台电脑运行（无服务端依赖，纯前端）。

## 一、准备
- 新电脑需安装：
  - Node.js（建议 18+ LTS）
  - npm（随 Node 自带）
- 将代码目录整体复制过去，或从压缩包解压。

## 二、安装依赖
```bash
npm install
```
> 如网络受限，可切换国内源：`npm config set registry https://registry.npmmirror.com`

## 三、本地开发
```bash
npm run dev
```
- 默认启动 `http://localhost:5173`
- 若端口被占用，可用 `npm run dev -- --host --port 5174`

## 四、生产构建与本地预览
```bash
npm run build
npm run preview   # 默认 http://localhost:4173
```
`dist/` 目录即为构建产物，可直接放在任意静态服务器/对象存储。

## 五、配置要点
- 环境变量（可选，`.env`）：
  - `VITE_AI_TIMEOUT_MS`：模型调用超时（ms），默认 60000
  - `VITE_ENABLE_PROXY`：`true` 时走开发代理
- 所有密钥、模型、Base URL 在前端界面填写（不写入仓库）：
  - 医生模型：全局设置 -> 医生配置
  - 向量模型：知识库抽屉 -> 向量设置
  - 图像识别：图片识别设置

## 六、魔搭社区使用提示
- Base URL：`https://api-inference.modelscope.cn/v1`（留空也会自动推断）
- 聊天模型示例：`Qwen/Qwen3-235B-A22B`
- 多模态模型示例：`Qwen/Qwen3-VL-235B-A22B-Instruct`
- 向量模型示例：`text-embedding-v3`
- 密钥前缀：
  - `ms-`：魔搭 inference 域
  - `sk-`：dashscope 兼容域

## 七、常见问题
- **401/403**：核对密钥权限、模型是否支持对应能力；Base URL 是否正确（魔搭用 inference 域）。
- **模型列表加载失败**：检查网络/代理，或手动输入模型名。
- **图像识别失败**：确保供应商与密钥匹配，图片可用 URL 或上传 base64，模型需支持多模态。
- **体积警告**：Vite 构建的 chunk 体积提示可忽略，或自行拆分 chunk。

## 八、快速检查清单
1) `npm install` 成功  
2) `npm run dev` 能打开页面  
3) 在界面填入魔搭密钥 + 模型，点击“测试调用”通过  
4) 知识库填入向量密钥 + 模型，点击“测试调用”通过  
5) 构建：`npm run build` 无报错  
6) `npm run preview` 可正常访问构建产物  
