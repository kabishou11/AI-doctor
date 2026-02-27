import axios from 'axios'
import { wrapUrlForDev } from './http'

const REQUEST_TIMEOUT_MS = Number(import.meta.env.VITE_AI_TIMEOUT_MS || 60000)

function normalizeBaseUrl(baseUrl, fallback) {
  const url = (baseUrl || fallback || '').trim()
  if (!url) return ''
  return url.endsWith('/') ? url.slice(0, -1) : url
}

function toArray(values) {
  if (!Array.isArray(values)) return []
  return values.map((x) => (typeof x === 'number' ? x : Number(x) || 0))
}

/**
 * 调用魔搭社区（DashScope兼容）的 embeddings 接口
 */
export async function embedWithModelScope({ apiKey, model, baseUrl, input }) {
  if (!apiKey) throw new Error('缺少魔搭 API Key')
  if (!model) throw new Error('缺少魔搭向量模型')
  if (!input || !String(input).trim()) throw new Error('待向量化内容为空')

  // 路由策略：优先使用用户填写；否则 ms- 只走 inference 域，sk- 只走 dashscope
  let endpoints = []
  if (baseUrl && baseUrl.trim()) {
    endpoints = [normalizeBaseUrl(baseUrl, baseUrl)]
  } else if (apiKey?.startsWith('ms-')) {
    endpoints = ['https://api-inference.modelscope.cn/v1']
  } else if (apiKey?.startsWith('sk-')) {
    endpoints = ['https://dashscope.aliyuncs.com/compatible-mode/v1']
  } else {
    endpoints = ['https://api-inference.modelscope.cn/v1']
  }
  const uniq = Array.from(new Set(endpoints.filter(Boolean)))
  const errors = []
  for (const root of uniq) {
    const url = `${normalizeBaseUrl(root, root)}/embeddings`
    try {
      const res = await axios.post(
        wrapUrlForDev(url),
        {
          model,
          input: String(input),
          encoding_format: 'float'
        },
        {
          headers: {
            Authorization: `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
          },
          timeout: REQUEST_TIMEOUT_MS
        }
      )
      const embedding = res.data?.data?.[0]?.embedding || res.data?.embedding || []
      return toArray(embedding)
    } catch (err) {
      const status = err?.response?.status
      const body = err?.response?.data
      errors.push(`endpoint ${root}: ${status || ''} ${body ? JSON.stringify(body) : err?.message || err}`)
    }
  }
  throw new Error(errors.join(' | ') || '调用 embedding 失败')
}
