import { Doctor, ImageRecognitionConfig, PresetPrompt } from '../models/index'
import { PersistenceManager } from '../persistence/PersistenceManager'
import { Logger } from '../utils/Logger'

const TAG = 'GlobalConfigStore'

@Observed
export class GlobalConfigStore {
  @Observed doctors: Doctor[] = []
  @Observed imageRecognition: ImageRecognitionConfig = new ImageRecognitionConfig()
  @Observed presetPrompts: PresetPrompt[] = []

  private persistence: PersistenceManager = PersistenceManager.getInstance()
  private loadPromise: Promise<void> | null = null

  async init(): Promise<void> {
    if (this.loadPromise) {
      return this.loadPromise
    }

    this.loadPromise = this.loadAllData()
    return this.loadPromise
  }

  private async loadAllData(): Promise<void> {
    try {
      const [doctors, imageRecognition, presetPrompts] = await Promise.all([
        this.persistence.loadGlobalDoctors(),
        this.persistence.loadImageRecognitionConfig(),
        this.persistence.loadPresetPrompts()
      ])

      this.doctors = doctors
      this.imageRecognition = imageRecognition
      this.presetPrompts = presetPrompts

      Logger.info(TAG, 'GlobalConfigStore initialized')
    } catch (e) {
      Logger.error(TAG, `Failed to initialize: ${e}`)
      throw e
    }
  }

  async setDoctors(list: Doctor[]): Promise<void> {
    this.doctors = list
    await this.persistence.saveGlobalDoctors(list)
  }

  async setImageRecognition(config: ImageRecognitionConfig): Promise<void> {
    this.imageRecognition = config
    await this.persistence.saveImageRecognitionConfig(config)
  }

  async setPresetPrompts(list: PresetPrompt[]): Promise<void> {
    this.presetPrompts = list
    await this.persistence.savePresetPrompts(list)
  }

  addOrUpdateDoctor(doctor: Doctor): void {
    const index = this.doctors.findIndex(d => d.id === doctor.id)
    if (index >= 0) {
      this.doctors[index] = doctor
      this.doctors = [...this.doctors] // Trigger reactivity
    } else {
      this.doctors = [...this.doctors, doctor]
    }
    this.persistence.saveGlobalDoctors(this.doctors).catch(e => {
      Logger.warn(TAG, `Failed to save doctor: ${e}`)
    })
  }

  removeDoctor(id: string): void {
    this.doctors = this.doctors.filter(d => d.id !== id)
    this.persistence.saveGlobalDoctors(this.doctors).catch(e => {
      Logger.warn(TAG, `Failed to remove doctor: ${e}`)
    })
  }

  getDoctorById(id: string): Doctor | null {
    return this.doctors.find(d => d.id === id) || null
  }

  addOrUpdatePresetPrompt(prompt: PresetPrompt): void {
    const index = this.presetPrompts.findIndex(p => p.id === prompt.id)
    if (index >= 0) {
      this.presetPrompts[index] = prompt
      this.presetPrompts = [...this.presetPrompts]
    } else {
      this.presetPrompts = [...this.presetPrompts, prompt]
    }
    this.persistence.savePresetPrompts(this.presetPrompts).catch(e => {
      Logger.warn(TAG, `Failed to save preset prompt: ${e}`)
    })
  }

  removePresetPrompt(id: string): void {
    this.presetPrompts = this.presetPrompts.filter(p => p.id !== id)
    this.persistence.savePresetPrompts(this.presetPrompts).catch(e => {
      Logger.warn(TAG, `Failed to remove preset prompt: ${e}`)
    })
  }

  getPresetPromptById(id: string): PresetPrompt | null {
    return this.presetPrompts.find(p => p.id === id) || null
  }
}

// Singleton instance
let instance: GlobalConfigStore | null = null

export function getGlobalConfigStore(): GlobalConfigStore {
  if (!instance) {
    instance = new GlobalConfigStore()
  }
  return instance
}
