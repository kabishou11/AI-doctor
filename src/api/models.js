import axios from 'axios'
import { wrapUrlForDev } from './http'

function normalizeBaseUrl(baseUrl, fallback) {
  const url = (baseUrl || fallback || '').trim()
  if (!url) return ''
  return url.endsWith('/') ? url.slice(0, -1) : url
}

function toOptions(list) {
  return list.map((m) => ({ label: m.displayName ? `${m.id} (${m.displayName})` : m.id, value: m.id }))
}

export async function listModels(provider, apiKey, baseUrl) {
  switch (provider) {
    case 'openai':
      return toOptions(await listOpenAIModels(apiKey, baseUrl))
    case 'anthropic':
      return toOptions(await listAnthropicModels(apiKey, baseUrl))
    case 'gemini':
      return toOptions(await listGeminiModels(apiKey, baseUrl))
    case 'siliconflow':
      return toOptions(await listSiliconFlowModels(apiKey, baseUrl))
    case 'modelscope':
      return toOptions(await listModelScopeModels(apiKey, baseUrl))
    default:
      return []
  }
}

export async function listOpenAIModels(apiKey, baseUrl) {
  const root = normalizeBaseUrl(baseUrl, 'https://api.openai.com')
  const url = wrapUrlForDev(`${root}/v1/models`)
  const res = await axios.get(url, {
    headers: { Authorization: `Bearer ${apiKey}` }
  })
  const data = res.data?.data || []
  return data
    .map((m) => ({ id: m.id, displayName: m.owned_by ? m.owned_by : undefined }))
    .sort((a, b) => a.id.localeCompare(b.id))
}

export async function listAnthropicModels(apiKey, baseUrl) {
  const root = normalizeBaseUrl(baseUrl, 'https://api.anthropic.com')
  const url = wrapUrlForDev(`${root}/v1/models`)
  const res = await axios.get(url, {
    headers: {
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01'
    }
  })
  const arr = res.data?.data || res.data?.models || []
  return arr
    .map((m) => ({ id: m.id || m.slug || m.name, displayName: m.display_name || undefined }))
    .filter((m) => !!m.id)
    .sort((a, b) => a.id.localeCompare(b.id))
}

export async function listGeminiModels(apiKey, baseUrl) {
  const root = normalizeBaseUrl(baseUrl, 'https://generativelanguage.googleapis.com')
  const isGoogle = /generativelanguage\.googleapis\.com$/.test(root)
  // Gemini supports v1 and v1beta. Try v1 first then fallback to v1beta.
  const tryPaths = [`${root}/v1/models`, `${root}/v1beta/models`]
  let models = []
  for (const p of tryPaths) {
    try {
      const url = wrapUrlForDev(isGoogle ? `${p}?key=${encodeURIComponent(apiKey)}` : p)
      const res = await axios.get(url, { headers: isGoogle ? {} : { 'x-goog-api-key': apiKey } })
      const arr = res.data?.models || []
      models = arr.map((m) => ({ id: (m.name || '').replace(/^models\//, ''), displayName: m.displayName }))
      break
    } catch (e) {
      // try next
    }
  }
  return models.sort((a, b) => a.id.localeCompare(b.id))
}

export async function listSiliconFlowModels(apiKey, baseUrl) {
  const root = normalizeBaseUrl(baseUrl, 'https://api.siliconflow.cn')
  const url = wrapUrlForDev(`${root}/v1/models`)
  const res = await axios.get(url, {
    headers: { Authorization: `Bearer ${apiKey}` }
  })
  const data = res.data?.data || res.data?.models || []
  return data
    .map((m) => ({
      id: m.id || m.name,
      displayName: m.display_name || m.owned_by || m.provider || undefined
    }))
    .filter((m) => !!m.id)
    .sort((a, b) => a.id.localeCompare(b.id))
}

export async function listModelScopeModels(apiKey, baseUrl) {
  const endpoints = []
  if (baseUrl && baseUrl.trim()) {
    endpoints.push(normalizeBaseUrl(baseUrl, baseUrl))
  }
  if (apiKey?.startsWith('ms-')) endpoints.push('https://api-inference.modelscope.cn/v1')
  if (apiKey?.startsWith('sk-')) endpoints.push('https://dashscope.aliyuncs.com/compatible-mode/v1')
  endpoints.push('https://api-inference.modelscope.cn/v1', 'https://dashscope.aliyuncs.com/compatible-mode/v1')
  const uniq = Array.from(new Set(endpoints.filter(Boolean)))

  const headers = { Authorization: `Bearer ${apiKey}` }
  const errors = []
  for (const root of uniq) {
    const url = root.includes('compatible-mode') ? `${normalizeBaseUrl(root, root)}/models` : `${normalizeBaseUrl(root, root)}/models`
    try {
      const finalUrl = wrapUrlForDev(url)
      const res = await axios.get(finalUrl, { headers })
      const data = res.data?.data || res.data?.models || []
      return data
        .map((m) => ({
          id: m.id || m.name,
          displayName: m.display_name || m.owned_by || m.provider || undefined
        }))
        .filter((m) => !!m.id)
        .sort((a, b) => a.id.localeCompare(b.id))
    } catch (err) {
      const status = err?.response?.status
      const body = err?.response?.data
      errors.push(`endpoint ${root}: ${status || ''} ${body ? JSON.stringify(body) : err?.message || err}`)
    }
  }
  const msg = errors.length ? errors.join(' | ') : '加载模型失败'
  throw new Error(msg)
}
