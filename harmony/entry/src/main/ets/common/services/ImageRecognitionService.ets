import { http } from '@kit.NetworkKit'
import { Logger } from '../utils/Logger'

const TAG = 'ImageRecognitionService'

function normalizeBaseUrl(baseUrl: string, fallback: string): string {
  const url = (baseUrl || fallback || '').trim()
  if (!url) return ''
  return url.endsWith('/') ? url.slice(0, -1) : url
}

function extractTextFromChoice(choice: any): string {
  if (!choice) return ''
  const { message, text } = choice
  if (text) return String(text).trim()
  if (Array.isArray(message?.content)) {
    return message.content
      .map((part: any) => {
        if (!part) return ''
        if (typeof part === 'string') return part
        return part.text || part.content || ''
      })
      .join('\n')
      .trim()
  }
  if (typeof message?.content === 'string') return message.content.trim()
  return ''
}

export class ImageRecognitionService {
  static async recognizeImageWithSiliconFlow(params: {
    apiKey: string
    baseUrl: string
    model: string
    prompt: string
    imageBase64: string
  }): Promise<string> {
    const { apiKey, baseUrl, model, prompt, imageBase64 } = params

    if (!apiKey) {
      throw new Error('未配置图像识别 API Key')
    }
    if (!model) {
      throw new Error('请选择图像识别模型')
    }
    if (!imageBase64) {
      throw new Error('请提供要识别的图片')
    }

    const root = normalizeBaseUrl(baseUrl, 'https://api.siliconflow.cn')
    const url = `${root}/v1/chat/completions`

    const payload = {
      model,
      messages: [
        {
          role: 'system',
          content: [
            {
              type: 'text',
              text:
                prompt ||
                '识别当前病情相关的图片内容。请仔细观察图片中的所有细节，用专业医学术语描述图片中的和病情相关的任何关键信息。如果图片中没有明显的病情相关内容或与医疗诊断无关，请明确说明"图片内容与病情无关"。请使用专业、严谨的语气进行描述。'
            }
          ]
        },
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: '请根据上述要求分析以下图片，并返回详细的医学描述。'
            },
            {
              type: 'image_url',
              image_url: {
                url: `data:image/jpeg;base64,${imageBase64}`,
                detail: 'high'
              }
            }
          ]
        }
      ],
      temperature: 0.1
    }

    try {
      const response = await this.httpPost(url, payload, {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      })
      const data = JSON.parse(response)
      const choice = data?.choices?.[0]
      const content = extractTextFromChoice(choice) || data?.output_text
      return (content || '').trim()
    } catch (e) {
      Logger.error(TAG, `Image recognition failed: ${e}`)
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
        readTimeout: 60000,
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
