import axios from "axios"
import { wrapUrlForDev } from "./http"

function normalizeBaseUrl(baseUrl, fallback) {
  const url = (baseUrl || fallback || "").trim()
  if (!url) return ""
  return url.endsWith("/") ? url.slice(0, -1) : url
}

function buildChatUrl(root) {
  const trimmed = root.endsWith("/v1") ? root : `${root}/v1`
  return `${trimmed}/chat/completions`
}

function extractTextFromChoice(choice) {
  if (!choice) return ""
  const { message, text } = choice
  if (text) return String(text).trim()
  if (Array.isArray(message?.content)) {
    return message.content
      .map((part) => {
        if (!part) return ""
        if (typeof part === "string") return part
        return part.text || part.content || ""
      })
      .join("\n")
      .trim()
  }
  if (typeof message?.content === "string") return message.content.trim()
  return ""
}

export async function recognizeImageWithSiliconFlow(options) {
  const key = options?.apiKey || ""
  // 如果误选了硅基流动但填的是魔搭/阿里系 key，则自动按魔搭路由，避免 401
  const provider = key.startsWith("ms-") || key.startsWith("sk-") ? "modelscope" : "siliconflow"
  return recognizeImage(options, { endpoints: buildEndpointList(options, provider) })
}

export async function recognizeImageWithModelScope(options) {
  return recognizeImage(options, { endpoints: buildEndpointList(options, "modelscope") })
}

function buildEndpointList(options, provider) {
  const { apiKey, baseUrl } = options || {}
  const list = []
  if (baseUrl && baseUrl.trim()) list.push(normalizeBaseUrl(baseUrl, baseUrl))
  if (provider === "siliconflow") {
    list.push("https://api.siliconflow.cn")
  } else if (provider === "modelscope") {
    if (apiKey?.startsWith("ms-")) {
      list.push("https://api-inference.modelscope.cn")
    } else if (apiKey?.startsWith("sk-")) {
      list.push("https://dashscope.aliyuncs.com/compatible-mode")
    } else {
      list.push("https://api-inference.modelscope.cn", "https://dashscope.aliyuncs.com/compatible-mode")
    }
  }
  return Array.from(new Set(list.filter(Boolean)))
}

async function recognizeImage({ apiKey, model, prompt, imageBase64, imageUrl }, { endpoints }) {
  if (!apiKey) throw new Error("未配置图像识别 API Key")
  if (!model) throw new Error("请选择图像识别模型")
  if (!imageBase64 && !imageUrl) throw new Error("请提供要识别的图片")

  const errors = []
  for (const root of endpoints) {
    const url = wrapUrlForDev(buildChatUrl(root))

    const imagePayload = imageBase64
      ? {
          type: "image_url",
          image_url: {
            url: `data:image/jpeg;base64,${imageBase64}`,
            detail: "high"
          }
        }
      : {
          type: "image_url",
          image_url: {
            url: imageUrl,
            detail: "high"
          }
        }

    const payload = {
      model,
      messages: [
        {
          role: "system",
          content: [
            {
              type: "text",
              text:
                prompt ||
                '识别当前病情相关的图片内容。请仔细观察图片中的所有细节，用专业医学术语描述图片中的和病情相关的任何关键信息。如果图片中没有明显的病情相关内容或与医疗诊断无关，请明确说明"图片内容与病情无关"。请使用专业、严谨的语气进行描述。'
            }
          ]
        },
        {
          role: "user",
          content: [
            { type: "text", text: "请根据上述要求分析以下图片，并返回详细的医学描述。" },
            imagePayload
          ]
        }
      ],
      temperature: 0.1
    }

    try {
      const res = await axios.post(url, payload, {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json"
        },
        timeout: Number(import.meta.env?.VITE_AI_TIMEOUT_MS || 60000)
      })
      const choice = res.data?.choices?.[0]
      const content = extractTextFromChoice(choice) || res.data?.output_text
      return (content || "").trim()
    } catch (err) {
      const status = err?.response?.status
      const body = err?.response?.data
      errors.push(`endpoint ${root}: ${status || ""} ${body ? JSON.stringify(body) : err?.message || err}`)
    }
  }
  throw new Error(errors.join(" | ") || "图像识别调用失败")
}
