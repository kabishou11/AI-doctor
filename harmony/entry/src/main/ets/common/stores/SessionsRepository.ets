import { SessionMeta, ConsultationSnapshot } from '../models/index'
import { PersistenceManager } from '../persistence/PersistenceManager'
import { Logger } from '../utils/Logger'

const TAG = 'SessionsRepository'

function nowISOString(): string {
  return new Date().toISOString()
}

function statusText(phase: string): string {
  switch (phase) {
    case 'setup':
      return '配置/准备'
    case 'discussion':
      return '讨论中'
    case 'voting':
      return '评估中'
    case 'finished':
      return '已结束'
    default:
      return String(phase || '未知')
  }
}

@Observed
export class SessionsRepository {
  @Observed sessions: SessionMeta[] = []
  @Observed currentId: string = ''

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
      const [sessions, currentId] = await Promise.all([
        this.persistence.loadSessionsMeta(),
        this.persistence.loadCurrentSessionId()
      ])

      this.sessions = sessions
      this.currentId = currentId

      // Ensure at least one session exists
      if (!this.sessions.length) {
        const id = await this.createNew('新建问诊')
        await this.switchTo(id)
      } else if (!this.currentId || !this.sessions.find(s => s.id === this.currentId)) {
        await this.switchTo(this.sessions[0].id)
      }

      Logger.info(TAG, 'SessionsRepository initialized')
    } catch (e) {
      Logger.error(TAG, `Failed to initialize: ${e}`)
      throw e
    }
  }

  async createNew(name: string): Promise<string> {
    const id = `consult-${Date.now()}`
    const ts = nowISOString()
    const initialName = typeof name === 'string' && name.trim() ? name.trim() : '未命名问诊'
    const meta = new SessionMeta({
      id,
      name: initialName,
      status: '配置/准备',
      createdAt: ts,
      updatedAt: ts
    })

    this.sessions = [meta, ...this.sessions]
    await this.persistence.saveSessionsMeta(this.sessions)

    // Create initial session data
    const initialData = new ConsultationSnapshot({
      consultationName: initialName,
      settings: undefined,
      doctors: [],
      patientCase: {
        name: '',
        gender: '',
        age: null,
        pastHistory: '',
        currentProblem: '',
        imageRecognitionResult: '',
        imageRecognitions: []
      } as any,
      linkedConsultations: [],
      workflow: {
        phase: 'setup',
        currentRound: 0,
        roundsWithoutElimination: 0,
        activeTurn: null,
        turnQueue: [],
        paused: false
      } as any,
      discussionHistory: [],
      lastRoundVotes: [],
      finalSummary: {
        status: 'idle',
        doctorId: null,
        doctorName: '',
        content: '',
        usedPrompt: ''
      } as any
    })

    await this.persistence.saveSessionData(id, initialData)
    return id
  }

  async rename(id: string, newName: string): Promise<void> {
    this.sessions = this.sessions.map(s =>
      s.id === id ? new SessionMeta({ ...s, name: newName, updatedAt: nowISOString() }) : s
    )
    await this.persistence.saveSessionsMeta(this.sessions)
  }

  async remove(id: string): Promise<void> {
    this.sessions = this.sessions.filter(s => s.id !== id)
    await this.persistence.saveSessionsMeta(this.sessions)
    await this.persistence.deleteSessionData(id)

    if (this.currentId === id) {
      const next = this.sessions[0]
      if (next) {
        await this.switchTo(next.id)
      } else {
        const nid = await this.createNew('新建问诊')
        await this.switchTo(nid)
      }
    }
  }

  async switchTo(id: string): Promise<void> {
    const meta = this.sessions.find(s => s.id === id)
    if (!meta) return

    this.currentId = id
    await this.persistence.saveCurrentSessionId(id)
    Logger.info(TAG, `Switched to session: ${id}`)
  }

  async saveSnapshot(snapshot: ConsultationSnapshot): Promise<void> {
    if (!this.currentId) return

    await this.persistence.saveSessionData(this.currentId, snapshot)

    const phase = snapshot.workflow?.phase || 'setup'
    const status = statusText(phase)
    this.sessions = this.sessions.map(s =>
      s.id === this.currentId
        ? new SessionMeta({ ...s, status, updatedAt: nowISOString() })
        : s
    )
    await this.persistence.saveSessionsMeta(this.sessions)
    Logger.info(TAG, `Saved snapshot for session: ${this.currentId}`)
  }

  async loadSessionData(id: string): Promise<ConsultationSnapshot | null> {
    return await this.persistence.loadSessionData(id)
  }

  getCurrentSession(): SessionMeta | null {
    return this.sessions.find(s => s.id === this.currentId) || null
  }

  getSessions(): SessionMeta[] {
    return [...this.sessions]
  }

  exportJSON(id: string): Promise<string | null> {
    return this.persistence.loadSessionData(id).then(data => {
      if (!data) return null
      const meta = this.sessions.find(s => s.id === id)
      return JSON.stringify({ meta, data }, null, 2)
    })
  }
}

// Singleton instance
let instance: SessionsRepository | null = null

export function getSessionsRepository(): SessionsRepository {
  if (!instance) {
    instance = new SessionsRepository()
  }
  return instance
}
