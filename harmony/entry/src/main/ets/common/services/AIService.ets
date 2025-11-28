import { http } from '@kit.NetworkKit'
import { Logger } from '../utils/Logger'
import { Doctor, APIMessage, PromptPair } from '../models/index'

const TAG = 'AIService'

function sleep(ms: number): Promise<void> {
  return new Promise((res) => setTimeout(res, ms))
}

function normalizeBaseUrl(baseUrl: string, fallback: string): string {
  const url = (baseUrl || fallback || '').trim()
  if (!url) return ''
  return url.endsWith('/') ? url.slice(0, -1) : url
}

export class AIService {
  static async callAI(
    doctor: Doctor,
    fullPrompt: PromptPair,
    historyForProvider: APIMessage[]
  ): Promise<string> {
    const { provider, model, apiKey, baseUrl } = doctor

    if (!apiKey) {
      await sleep(600)
      return `【模拟回复 - ${doctor.name}】\n根据提供的病历与讨论历史，我认为需要进一步完善体格检查与辅助检查以明确诊断。`
    }

    switch (provider) {
      case 'openai':
        return this.callOpenAI({ apiKey, model, fullPrompt, history: historyForProvider, baseUrl })
      case 'anthropic':
        return this.callAnthropic({ apiKey, model, fullPrompt, history: historyForProvider, baseUrl })
      case 'gemini':
        return this.callGemini({ apiKey, model, fullPrompt, history: historyForProvider, baseUrl })
      case 'siliconflow':
        return this.callSiliconFlow({ apiKey, model, fullPrompt, history: historyForProvider, baseUrl })
      case 'modelscope':
        return this.callModelScope({ apiKey, model, fullPrompt, history: historyForProvider, baseUrl })
      default:
        throw new Error('Unsupported AI provider: ' + provider)
    }
  }

  private static async callOpenAI(params: {
    apiKey: string
    model: string
    fullPrompt: PromptPair
    history: APIMessage[]
    baseUrl: string
  }): Promise<string> {
    const { apiKey, model, fullPrompt, history, baseUrl } = params
    const messages = [
      { role: 'system', content: fullPrompt.system },
      ...history
        .filter(m => m.role === 'user' || m.role === 'assistant')
        .map(m => ({ role: m.role, content: m.content })),
      { role: 'user', content: fullPrompt.user }
    ]

    const root = normalizeBaseUrl(baseUrl, 'https://api.openai.com')
    const url = `${root}/v1/chat/completions`

    try {
      const response = await this.httpPost(url, { model, messages, temperature: 0.7 }, {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      })
      const data = JSON.parse(response)
      return data.choices?.[0]?.message?.content?.trim() || ''
    } catch (e) {
      Logger.error(TAG, `OpenAI call failed: ${e}`)
      throw e
    }
  }

  private static async callAnthropic(params: {
    apiKey: string
    model: string
    fullPrompt: PromptPair
    history: APIMessage[]
    baseUrl: string
  }): Promise<string> {
    const { apiKey, model, fullPrompt, history, baseUrl } = params
    const root = normalizeBaseUrl(baseUrl, 'https://api.anthropic.com')
    const url = `${root}/v1/messages`

    const messages = [
      ...history
        .filter(m => m.role === 'user' || m.role === 'assistant')
        .map(m => ({ role: m.role, content: m.content })),
      { role: 'user', content: fullPrompt.user }
    ]

    try {
      const response = await this.httpPost(url, {
        model,
        max_tokens: 1024,
        system: fullPrompt.system,
        messages
      }, {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json'
      })
      const data = JSON.parse(response)
      return data?.content?.[0]?.text?.trim() || ''
    } catch (e) {
      Logger.error(TAG, `Anthropic call failed: ${e}`)
      throw e
    }
  }

  private static async callGemini(params: {
    apiKey: string
    model: string
    fullPrompt: PromptPair
    history: APIMessage[]
    baseUrl: string
  }): Promise<string> {
    const { apiKey, model, fullPrompt, history, baseUrl } = params
    const root = normalizeBaseUrl(baseUrl, 'https://generativelanguage.googleapis.com')
    const isGoogle = /generativelanguage\.googleapis\.com$/.test(root)
    const endpoint = `${root}/v1beta/models/${encodeURIComponent(model)}:generateContent`
    const url = isGoogle ? `${endpoint}?key=${encodeURIComponent(apiKey)}` : endpoint

    const contents = [
      ...history
        .filter(m => m.role === 'user' || m.role === 'assistant')
        .map(m => ({ role: m.role === 'assistant' ? 'model' : 'user', parts: [{ text: m.content }] })),
      { role: 'user', parts: [{ text: fullPrompt.user }] }
    ]

    const headers: Record<string, string> = { 'Content-Type': 'application/json' }
    if (!isGoogle) headers['x-goog-api-key'] = apiKey

    try {
      const response = await this.httpPost(url, {
        systemInstruction: { role: 'system', parts: [{ text: fullPrompt.system }] },
        contents
      }, headers)
      const data = JSON.parse(response)
      return (
        data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ||
        data?.candidates?.[0]?.content?.parts?.map((p: any) => p.text).join('\n') ||
        ''
      )
    } catch (e) {
      Logger.error(TAG, `Gemini call failed: ${e}`)
      throw e
    }
  }

  private static async callSiliconFlow(params: {
    apiKey: string
    model: string
    fullPrompt: PromptPair
    history: APIMessage[]
    baseUrl: string
  }): Promise<string> {
    const { apiKey, model, fullPrompt, history, baseUrl } = params
    const messages = [
      { role: 'system', content: fullPrompt.system },
      ...history
        .filter(m => m.role === 'user' || m.role === 'assistant')
        .map(m => ({ role: m.role, content: m.content })),
      { role: 'user', content: fullPrompt.user }
    ]

    const root = normalizeBaseUrl(baseUrl, 'https://api.siliconflow.cn')
    const url = `${root}/v1/chat/completions`

    try {
      const response = await this.httpPost(url, { model, messages, temperature: 0.7 }, {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      })
      const data = JSON.parse(response)
      const choice = data?.choices?.[0]
      const content = choice?.message?.content || choice?.text
      return (Array.isArray(content) ? content.join('\n') : content || data?.output_text || '').trim()
    } catch (e) {
      Logger.error(TAG, `SiliconFlow call failed: ${e}`)
      throw e
    }
  }

  private static async callModelScope(params: {
    apiKey: string
    model: string
    fullPrompt: PromptPair
    history: APIMessage[]
    baseUrl: string
  }): Promise<string> {
    const { apiKey, model, fullPrompt, history, baseUrl } = params
    const messages = [
      { role: 'system', content: fullPrompt.system },
      ...history
        .filter(m => m.role === 'user' || m.role === 'assistant')
        .map(m => ({ role: m.role, content: m.content })),
      { role: 'user', content: fullPrompt.user }
    ]

    const root = normalizeBaseUrl(baseUrl, 'https://dashscope.aliyuncs.com')
    const url = `${root}/compatible-mode/v1/chat/completions`

    try {
      const response = await this.httpPost(url, { model, messages, temperature: 0.7 }, {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      })
      const data = JSON.parse(response)
      const choice = data?.choices?.[0]
      const content = choice?.message?.content || choice?.text
      return (Array.isArray(content) ? content.join('\n') : content || data?.output_text || '').trim()
    } catch (e) {
      Logger.error(TAG, `ModelScope call failed: ${e}`)
      throw e
    }
  }

  private static async httpPost(
    url: string,
    data: object,
    headers: Record<string, string>
  ): Promise<string> {
    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp()

      const requestOptions: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: headers,
        readTimeout: 30000,
        connectTimeout: 10000
      }

      httpRequest.request(url, JSON.stringify(data), requestOptions)
        .then((response: http.HttpResponse) => {
          if (response.responseCode === 200) {
            resolve(response.result as string)
          } else {
            reject(new Error(`HTTP ${response.responseCode}: ${response.result}`))
          }
          httpRequest.destroy()
        })
        .catch((error: Error) => {
          Logger.error(TAG, `HTTP request failed: ${error.message}`)
          reject(error)
          httpRequest.destroy()
        })
    })
  }
}
