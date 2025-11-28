import { preferences } from '@kit.ArkData'
import { Logger } from '../utils/Logger'
import {
  Doctor,
  SessionMeta,
  ConsultationSnapshot,
  ImageRecognitionConfig,
  PresetPrompt
} from '../models/index'

const TAG = 'PersistenceManager'

// Keys for preferences storage
const PREF_NAME = 'consult_app_prefs'
const GLOBAL_DOCTORS_KEY = 'global_doctors_config'
const IMAGE_RECOGNITION_KEY = 'global_image_recognition_config'
const PRESET_PROMPTS_KEY = 'global_preset_prompts'
const SESSIONS_META_KEY = 'consult_sessions_meta'
const CURRENT_SESSION_KEY = 'consult_sessions_current'

// Key prefix for session data
const SESSION_DATA_PREFIX = 'consult_session_data_'

export class PersistenceManager {
  private static instance: PersistenceManager | null = null
  private prefs: preferences.Preferences | null = null
  private initialized: boolean = false

  private constructor() {}

  static getInstance(): PersistenceManager {
    if (!PersistenceManager.instance) {
      PersistenceManager.instance = new PersistenceManager()
    }
    return PersistenceManager.instance
  }

  async init(context: any): Promise<void> {
    if (this.initialized) return

    try {
      this.prefs = await preferences.getPreferences(context, PREF_NAME)
      this.initialized = true
      Logger.info(TAG, 'Persistence initialized')
    } catch (e) {
      Logger.error(TAG, `Failed to initialize preferences: ${e}`)
      throw e
    }
  }

  private ensureInitialized(): void {
    if (!this.prefs) {
      throw new Error('PersistenceManager not initialized. Call init() first.')
    }
  }

  // ============= Global Doctors =============

  async saveGlobalDoctors(doctors: Doctor[]): Promise<void> {
    this.ensureInitialized()
    try {
      const sanitized = doctors.map(d => ({
        id: d.id,
        name: d.name,
        provider: d.provider,
        model: d.model,
        apiKey: d.apiKey,
        baseUrl: d.baseUrl,
        customPrompt: d.customPrompt
      }))
      await this.prefs!.put(GLOBAL_DOCTORS_KEY, JSON.stringify(sanitized))
      await this.prefs!.flush()
      Logger.info(TAG, `Saved ${sanitized.length} global doctors`)
    } catch (e) {
      Logger.error(TAG, `Failed to save global doctors: ${e}`)
      throw e
    }
  }

  async loadGlobalDoctors(): Promise<Doctor[]> {
    this.ensureInitialized()
    try {
      const raw = await this.prefs!.get(GLOBAL_DOCTORS_KEY, '[]')
      if (!raw) return this.getDefaultGlobalDoctors()
      const arr = JSON.parse(String(raw))
      if (Array.isArray(arr)) {
        return arr.map(d => new Doctor(d))
      }
      return this.getDefaultGlobalDoctors()
    } catch (e) {
      Logger.warn(TAG, `Failed to load global doctors: ${e}`)
      return this.getDefaultGlobalDoctors()
    }
  }

  private getDefaultGlobalDoctors(): Doctor[] {
    return [
      new Doctor({
        id: 'doc-1',
        name: 'Dr. GPT-4',
        provider: 'openai',
        model: 'gpt-4o-mini',
        apiKey: '',
        baseUrl: '',
        customPrompt: ''
      }),
      new Doctor({
        id: 'doc-2',
        name: 'Dr. Claude 3',
        provider: 'anthropic',
        model: 'claude-3-haiku-20240307',
        apiKey: '',
        baseUrl: '',
        customPrompt: ''
      }),
      new Doctor({
        id: 'doc-3',
        name: 'Dr. Gemini',
        provider: 'gemini',
        model: 'gemini-1.5-flash',
        apiKey: '',
        baseUrl: '',
        customPrompt: ''
      })
    ]
  }

  // ============= Image Recognition Config =============

  async saveImageRecognitionConfig(config: ImageRecognitionConfig): Promise<void> {
    this.ensureInitialized()
    try {
      await this.prefs!.put(IMAGE_RECOGNITION_KEY, JSON.stringify(config))
      await this.prefs!.flush()
      Logger.info(TAG, 'Saved image recognition config')
    } catch (e) {
      Logger.error(TAG, `Failed to save image recognition config: ${e}`)
      throw e
    }
  }

  async loadImageRecognitionConfig(): Promise<ImageRecognitionConfig> {
    this.ensureInitialized()
    try {
      const raw = await this.prefs!.get(IMAGE_RECOGNITION_KEY, '{}')
      if (!raw) return this.getDefaultImageRecognitionConfig()
      const config = JSON.parse(String(raw))
      return new ImageRecognitionConfig({
        ...this.getDefaultImageRecognitionConfig(),
        ...config,
        maxConcurrent: Math.max(1, Math.floor(config.maxConcurrent || 1))
      })
    } catch (e) {
      Logger.warn(TAG, `Failed to load image recognition config: ${e}`)
      return this.getDefaultImageRecognitionConfig()
    }
  }

  private getDefaultImageRecognitionConfig(): ImageRecognitionConfig {
    return new ImageRecognitionConfig({
      enabled: false,
      provider: 'siliconflow',
      model: 'Pro/Qwen/Qwen2-VL-72B-Instruct',
      apiKey: '',
      baseUrl: '',
      prompt: '识别当前病灶相关的图片内容。请仔细观察图片中的所有细节，用专业医学术语描述图片中的病灶特征、位置、形态、颜色、大小等关键信息。如果图片中没有明显的病灶相关内容或与医疗诊断无关，请明确说明"图片内容与病灶无关"。请使用专业、严谨的语气进行描述。',
      maxConcurrent: 1
    })
  }

  // ============= Preset Prompts =============

  async savePresetPrompts(prompts: PresetPrompt[]): Promise<void> {
    this.ensureInitialized()
    try {
      await this.prefs!.put(PRESET_PROMPTS_KEY, JSON.stringify(prompts))
      await this.prefs!.flush()
      Logger.info(TAG, `Saved ${prompts.length} preset prompts`)
    } catch (e) {
      Logger.error(TAG, `Failed to save preset prompts: ${e}`)
      throw e
    }
  }

  async loadPresetPrompts(): Promise<PresetPrompt[]> {
    this.ensureInitialized()
    try {
      const raw = await this.prefs!.get(PRESET_PROMPTS_KEY, '[]')
      if (!raw) return this.getDefaultPresetPrompts()
      const arr = JSON.parse(String(raw))
      if (Array.isArray(arr)) {
        return arr.map(p => new PresetPrompt(p))
      }
      return this.getDefaultPresetPrompts()
    } catch (e) {
      Logger.warn(TAG, `Failed to load preset prompts: ${e}`)
      return this.getDefaultPresetPrompts()
    }
  }

  private getDefaultPresetPrompts(): PresetPrompt[] {
    return [
      new PresetPrompt({
        id: 'preset-1',
        name: '心血管内科医生',
        prompt: '你是一位资深的心血管内科专家医生，拥有丰富的心血管疾病诊断和治疗经验。你擅长分析心脏病、高血压、心律失常、冠心病等心血管系统疾病。在会诊中，你会特别关注患者的心血管症状、心电图、超声心动图等检查结果，结合临床表现做出专业判断。你的分析必须基于循证医学证据，并保持独立的专业判断。'
      }),
      new PresetPrompt({
        id: 'preset-2',
        name: '呼吸内科医生',
        prompt: '你是一位经验丰富的呼吸内科专家医生，精通呼吸系统疾病的诊断和治疗。你擅长分析肺炎、慢阻肺、哮喘、肺结核、肺癌等呼吸系统疾病。在会诊中，你会特别关注患者的呼吸道症状、胸部影像学检查、肺功能检查等，并结合病史做出专业判断。你的诊断基于扎实的医学知识和临床经验。'
      })
    ]
  }

  // ============= Sessions Meta =============

  async saveSessionsMeta(sessions: SessionMeta[]): Promise<void> {
    this.ensureInitialized()
    try {
      await this.prefs!.put(SESSIONS_META_KEY, JSON.stringify(sessions))
      await this.prefs!.flush()
      Logger.info(TAG, `Saved ${sessions.length} session metadata`)
    } catch (e) {
      Logger.error(TAG, `Failed to save sessions meta: ${e}`)
      throw e
    }
  }

  async loadSessionsMeta(): Promise<SessionMeta[]> {
    this.ensureInitialized()
    try {
      const raw = await this.prefs!.get(SESSIONS_META_KEY, '[]')
      if (!raw) return []
      const arr = JSON.parse(String(raw))
      if (Array.isArray(arr)) {
        return arr.map(s => new SessionMeta(s))
      }
      return []
    } catch (e) {
      Logger.warn(TAG, `Failed to load sessions meta: ${e}`)
      return []
    }
  }

  // ============= Current Session ID =============

  async saveCurrentSessionId(id: string): Promise<void> {
    this.ensureInitialized()
    try {
      await this.prefs!.put(CURRENT_SESSION_KEY, id || '')
      await this.prefs!.flush()
      Logger.info(TAG, `Saved current session ID: ${id}`)
    } catch (e) {
      Logger.error(TAG, `Failed to save current session ID: ${e}`)
      throw e
    }
  }

  async loadCurrentSessionId(): Promise<string> {
    this.ensureInitialized()
    try {
      const raw = await this.prefs!.get(CURRENT_SESSION_KEY, '')
      return String(raw || '')
    } catch (e) {
      Logger.warn(TAG, `Failed to load current session ID: ${e}`)
      return ''
    }
  }

  // ============= Session Data (Snapshots) =============

  async saveSessionData(sessionId: string, snapshot: ConsultationSnapshot): Promise<void> {
    this.ensureInitialized()
    try {
      const key = SESSION_DATA_PREFIX + sessionId
      await this.prefs!.put(key, JSON.stringify(snapshot))
      await this.prefs!.flush()
      Logger.info(TAG, `Saved session data for: ${sessionId}`)
    } catch (e) {
      Logger.error(TAG, `Failed to save session data for ${sessionId}: ${e}`)
      throw e
    }
  }

  async loadSessionData(sessionId: string): Promise<ConsultationSnapshot | null> {
    this.ensureInitialized()
    try {
      const key = SESSION_DATA_PREFIX + sessionId
      const raw = await this.prefs!.get(key, null)
      if (!raw) return null
      const data = JSON.parse(String(raw))
      return new ConsultationSnapshot(data)
    } catch (e) {
      Logger.warn(TAG, `Failed to load session data for ${sessionId}: ${e}`)
      return null
    }
  }

  async deleteSessionData(sessionId: string): Promise<void> {
    this.ensureInitialized()
    try {
      const key = SESSION_DATA_PREFIX + sessionId
      await this.prefs!.delete(key)
      await this.prefs!.flush()
      Logger.info(TAG, `Deleted session data for: ${sessionId}`)
    } catch (e) {
      Logger.warn(TAG, `Failed to delete session data for ${sessionId}: ${e}`)
    }
  }

  // ============= Clear All =============

  async clearAll(): Promise<void> {
    this.ensureInitialized()
    try {
      await this.prefs!.clear()
      await this.prefs!.flush()
      Logger.info(TAG, 'Cleared all preferences')
    } catch (e) {
      Logger.error(TAG, `Failed to clear preferences: ${e}`)
      throw e
    }
  }
}
