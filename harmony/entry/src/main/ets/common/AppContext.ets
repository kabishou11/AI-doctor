import { PersistenceManager } from './persistence/PersistenceManager'
import { GlobalConfigStore, getGlobalConfigStore } from './stores/GlobalConfigStore'
import { SessionsRepository, getSessionsRepository } from './stores/SessionsRepository'
import { ConsultViewModel, getConsultViewModel } from './stores/ConsultViewModel'
import { Logger } from './utils/Logger'

const TAG = 'AppContext'

export class AppContext {
  private static instance: AppContext | null = null

  private persistence: PersistenceManager = PersistenceManager.getInstance()
  private globalConfig: GlobalConfigStore | null = null
  private sessions: SessionsRepository | null = null
  private consult: ConsultViewModel | null = null
  private initialized: boolean = false

  private constructor() {}

  static getInstance(): AppContext {
    if (!AppContext.instance) {
      AppContext.instance = new AppContext()
    }
    return AppContext.instance
  }

  async init(context: any): Promise<void> {
    if (this.initialized) return

    try {
      // Initialize persistence layer
      await this.persistence.init(context)
      Logger.info(TAG, 'Persistence initialized')

      // Get store instances
      this.globalConfig = getGlobalConfigStore()
      this.sessions = getSessionsRepository()
      this.consult = getConsultViewModel()

      // Initialize stores in order
      await Promise.all([
        this.globalConfig.init(),
        this.sessions.init()
      ])

      Logger.info(TAG, 'Global config and sessions initialized')

      // Load current session data
      const currentSessionId = this.sessions.currentId
      if (currentSessionId) {
        const snapshot = await this.sessions.loadSessionData(currentSessionId)
        if (snapshot) {
          this.consult.loadFromSnapshot(snapshot)
          Logger.info(TAG, `Loaded session: ${currentSessionId}`)
        }
      }

      // Set up auto-save callback
      this.consult.setOnAutoSaveCallback(async (snapshot) => {
        await this.sessions.saveSnapshot(snapshot)
      })

      this.initialized = true
      Logger.info(TAG, 'AppContext fully initialized')
    } catch (e) {
      Logger.error(TAG, `Initialization failed: ${e}`)
      throw e
    }
  }

  getGlobalConfig(): GlobalConfigStore {
    if (!this.globalConfig) {
      throw new Error('AppContext not initialized')
    }
    return this.globalConfig
  }

  getSessions(): SessionsRepository {
    if (!this.sessions) {
      throw new Error('AppContext not initialized')
    }
    return this.sessions
  }

  getConsult(): ConsultViewModel {
    if (!this.consult) {
      throw new Error('AppContext not initialized')
    }
    return this.consult
  }

  isInitialized(): boolean {
    return this.initialized
  }

  async switchSession(sessionId: string): Promise<void> {
    if (!this.sessions || !this.consult) {
      throw new Error('AppContext not initialized')
    }

    try {
      // Save current consultation state before switching
      const currentSessionId = this.sessions.currentId
      if (currentSessionId) {
        await this.sessions.saveSnapshot(this.consult.toSnapshot())
      }

      // Switch to new session
      await this.sessions.switchTo(sessionId)

      // Load new session data
      const snapshot = await this.sessions.loadSessionData(sessionId)
      if (snapshot) {
        this.consult.loadFromSnapshot(snapshot)
        Logger.info(TAG, `Switched to session: ${sessionId}`)
      } else {
        this.consult.reset()
        Logger.warn(TAG, `No data found for session: ${sessionId}`)
      }
    } catch (e) {
      Logger.error(TAG, `Failed to switch session: ${e}`)
      throw e
    }
  }

  async createNewSession(name: string): Promise<string> {
    if (!this.sessions || !this.consult) {
      throw new Error('AppContext not initialized')
    }

    try {
      // Save current state
      const currentSessionId = this.sessions.currentId
      if (currentSessionId) {
        await this.sessions.saveSnapshot(this.consult.toSnapshot())
      }

      // Create new session
      const newId = await this.sessions.createNew(name)
      await this.switchSession(newId)

      Logger.info(TAG, `Created new session: ${newId}`)
      return newId
    } catch (e) {
      Logger.error(TAG, `Failed to create session: ${e}`)
      throw e
    }
  }

  async deleteSession(sessionId: string): Promise<void> {
    if (!this.sessions) {
      throw new Error('AppContext not initialized')
    }

    try {
      await this.sessions.remove(sessionId)
      Logger.info(TAG, `Deleted session: ${sessionId}`)
    } catch (e) {
      Logger.error(TAG, `Failed to delete session: ${e}`)
      throw e
    }
  }
}

export function getAppContext(): AppContext {
  return AppContext.getInstance()
}
