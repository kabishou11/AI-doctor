import axios from 'axios'
import { wrapUrlForDev } from './http'

const REQUEST_TIMEOUT_MS = Number(import.meta.env.VITE_AI_TIMEOUT_MS) || 45000

function sleep(ms) {
  return new Promise((res) => setTimeout(res, ms))
}

function normalizeBaseUrl(baseUrl, fallback) {
  const url = (baseUrl || fallback || '').trim()
  if (!url) return ''
  return url.endsWith('/') ? url.slice(0, -1) : url
}

function buildChatUrl(root) {
  const trimmed = root.endsWith('/v1') ? root : `${root}/v1`
  return `${trimmed}/chat/completions`
}

export async function callAI(doctor, fullPrompt, historyForProvider) {
  const { provider, model, apiKey, baseUrl } = doctor

  if (!apiKey) {
    await sleep(600)
    return `【模拟回复 - ${doctor.name}】\n根据提供的病历与讨论历史，我认为需要进一步完善体格检查与辅助检查以明确诊断。`
  }

  switch (provider) {
    case 'openai':
      return callOpenAI({ apiKey, model, fullPrompt, history: historyForProvider, baseUrl })
    case 'anthropic':
      return callAnthropic({ apiKey, model, fullPrompt, history: historyForProvider, baseUrl })
    case 'gemini':
      return callGemini({ apiKey, model, fullPrompt, history: historyForProvider, baseUrl })
    case 'siliconflow':
      return callSiliconFlow({ apiKey, model, fullPrompt, history: historyForProvider, baseUrl })
    case 'modelscope':
      return callModelScope({ apiKey, model, fullPrompt, history: historyForProvider, baseUrl })
    default:
      throw new Error('Unsupported AI provider')
  }
}

async function callOpenAI({ apiKey, model, fullPrompt, history, baseUrl }) {
  const messages = [
    { role: 'system', content: fullPrompt.system },
    ...history
      .filter((m) => m.role === 'user' || m.role === 'assistant')
      .map((m) => ({ role: m.role, content: m.content })),
    { role: 'user', content: fullPrompt.user }
  ]
  const root = normalizeBaseUrl(baseUrl, 'https://api.openai.com')
  const url = wrapUrlForDev(`${root}/v1/chat/completions`)
  const res = await axios.post(
    url,
    { model, messages, temperature: 0.7 },
    {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      timeout: REQUEST_TIMEOUT_MS
    }
  )
  return res.data.choices?.[0]?.message?.content?.trim() || ''
}

async function callAnthropic({ apiKey, model, fullPrompt, history, baseUrl }) {
  const root = normalizeBaseUrl(baseUrl, 'https://api.anthropic.com')
  const url = wrapUrlForDev(`${root}/v1/messages`)
  const messages = [
    ...history
      .filter((m) => m.role === 'user' || m.role === 'assistant')
      .map((m) => ({ role: m.role, content: m.content })),
    { role: 'user', content: fullPrompt.user }
  ]
  const res = await axios.post(
    url,
    {
      model,
      max_tokens: 1024,
      system: fullPrompt.system,
      messages
    },
    {
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json'
      },
      timeout: REQUEST_TIMEOUT_MS
    }
  )
  return res.data?.content?.[0]?.text?.trim() || ''
}

async function callGemini({ apiKey, model, fullPrompt, history, baseUrl }) {
  const root = normalizeBaseUrl(baseUrl, 'https://generativelanguage.googleapis.com')
  const isGoogle = /generativelanguage\.googleapis\.com$/.test(root)
  const endpoint = `${root}/v1beta/models/${encodeURIComponent(model)}:generateContent`
  const url = wrapUrlForDev(isGoogle ? `${endpoint}?key=${encodeURIComponent(apiKey)}` : endpoint)

  const contents = [
    ...history
      .filter((m) => m.role === 'user' || m.role === 'assistant')
      .map((m) => ({ role: m.role === 'assistant' ? 'model' : 'user', parts: [{ text: m.content }] })),
    { role: 'user', parts: [{ text: fullPrompt.user }] }
  ]

  const headers = { 'Content-Type': 'application/json' }
  if (!isGoogle) headers['x-goog-api-key'] = apiKey

  const res = await axios.post(
    url,
    {
      systemInstruction: { role: 'system', parts: [{ text: fullPrompt.system }] },
      contents
    },
    { headers, timeout: REQUEST_TIMEOUT_MS }
  )

  return (
    res.data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ||
    res.data?.candidates?.[0]?.content?.parts?.map((p) => p.text).join('\n') ||
    ''
  )
}

async function callSiliconFlow({ apiKey, model, fullPrompt, history, baseUrl }) {
  const messages = [
    { role: 'system', content: fullPrompt.system },
    ...history
      .filter((m) => m.role === 'user' || m.role === 'assistant')
      .map((m) => ({ role: m.role, content: m.content })),
    { role: 'user', content: fullPrompt.user }
  ]
  const root = normalizeBaseUrl(baseUrl, 'https://api.siliconflow.cn')
  const url = wrapUrlForDev(`${root}/v1/chat/completions`)
  const res = await axios.post(
    url,
    { model, messages, temperature: 0.7 },
    {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      timeout: REQUEST_TIMEOUT_MS
    }
  )
  const choice = res.data?.choices?.[0]
  const content = choice?.message?.content || choice?.text
  return (Array.isArray(content) ? content.join('\n') : content || res.data?.output_text || '').trim()
}

async function callModelScope({ apiKey, model, fullPrompt, history, baseUrl }) {
  const messages = [
    { role: 'system', content: fullPrompt.system },
    ...history
      .filter((m) => m.role === 'user' || m.role === 'assistant')
      .map((m) => ({ role: m.role, content: m.content })),
    { role: 'user', content: fullPrompt.user }
  ]

  const payload = { model, messages, temperature: 0.7 }
  const headers = {
    Authorization: `Bearer ${apiKey}`,
    'Content-Type': 'application/json'
  }

  // 端点优先级：若用户填写 Base URL，严格只使用它；否则按 key 前缀推断，避免 ms- 误走 dashscope
  let endpoints = []
  if (baseUrl && baseUrl.trim()) {
    endpoints = [normalizeBaseUrl(baseUrl, baseUrl)]
  } else if (apiKey?.startsWith('ms-')) {
    endpoints = ['https://api-inference.modelscope.cn/v1']
  } else if (apiKey?.startsWith('sk-')) {
    endpoints = ['https://dashscope.aliyuncs.com/compatible-mode/v1']
  } else {
    endpoints = ['https://api-inference.modelscope.cn/v1', 'https://dashscope.aliyuncs.com/compatible-mode/v1']
  }
  const uniqEndpoints = Array.from(new Set(endpoints.filter(Boolean)))

  const shouldProxy = `${import.meta.env.VITE_ENABLE_PROXY ?? ''}`.toLowerCase().trim() === 'true' || import.meta.env.DEV
  const errors = []

  for (const root of uniqEndpoints) {
    const url = buildChatUrl(root)
    const finalUrl = shouldProxy ? wrapUrlForDev(url) : url
    try {
      const res = await axios.post(finalUrl, payload, { headers, timeout: REQUEST_TIMEOUT_MS })
      const choice = res.data?.choices?.[0]
      const content = choice?.message?.content || choice?.text
      return (Array.isArray(content) ? content.join('\n') : content || res.data?.output_text || '').trim()
    } catch (err) {
      const status = err?.response?.status
      const data = err?.response?.data
      errors.push(`endpoint ${root}: ${status || ''} ${data ? JSON.stringify(data) : err?.message || err}`)
    }
  }

  const msg = errors.length ? errors.join(' | ') : '调用魔搭社区失败'
  throw new Error(msg)
}
