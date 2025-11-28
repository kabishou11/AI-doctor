import {
  Doctor,
  PatientCase,
  LinkedConsultation,
  DiscussionMessage,
  Workflow,
  ConsultationSettings,
  FinalSummary,
  VoteRecord,
  ImageRecognition,
  ConsultationSnapshot
} from '../models/index'
import { PersistenceManager } from '../persistence/PersistenceManager'
import { Logger } from '../utils/Logger'
import { AIService } from '../services/AIService'
import { PromptBuilder } from '../utils/PromptBuilder'

const TAG = 'ConsultViewModel'

function delay(ms: number): Promise<void> {
  return new Promise((res) => setTimeout(res, ms))
}

function sanitizeImageRecognitions(list: any[]): ImageRecognition[] {
  if (!Array.isArray(list)) return []
  const now = Date.now()
  return list.map((item, idx) => {
    const status = normalizeStatus(item)
    return new ImageRecognition({
      id: item?.id || `img-${now}-${idx}`,
      name: item?.name || '',
      dataUrl: item?.dataUrl || item?.imageUrl || '',
      result: item?.result || '',
      status,
      error: item?.error || '',
      createdAt: item?.createdAt || now,
      raw: status === 'queued' || status === 'recognizing' ? item?.raw || '' : ''
    })
  })
}

function normalizeStatus(item: any): string {
  const status = item?.status
  if (status === 'queued' || status === 'recognizing') return 'queued'
  if (status === 'error') return 'error'
  if (status === 'success') return 'success'
  if (item?.error) return 'error'
  if (item?.result) return 'success'
  return 'queued'
}

function summarizeImageRecognitions(list: ImageRecognition[]): string {
  if (!Array.isArray(list) || !list.length) return ''
  return list
    .map((entry, idx) => ({ entry, idx }))
    .filter(({ entry }) => entry.status === 'success' && entry.result)
    .map(({ entry, idx }) => {
      const namePart = entry.name ? `（${entry.name}）` : ''
      return `图片${idx + 1}${namePart}: ${entry.result}`
    })
    .join('\n')
}

function sanitizeLinkedConsultations(list: any[]): LinkedConsultation[] {
  if (!Array.isArray(list)) return []
  return list
    .map((item, idx) => {
      if (!item) return null
      const id = typeof item.id === 'string' && item.id ? item.id : item?.sourceId || `linked-${idx}`
      const patientAge = item?.patientAge
      return new LinkedConsultation({
        id,
        sourceId: item?.sourceId || id,
        consultationName: item?.consultationName || item?.name || `关联问诊${idx + 1}`,
        patientName: item?.patientName || '',
        patientGender: item?.patientGender || '',
        patientAge: Number.isFinite(patientAge) ? patientAge : patientAge === null || patientAge === undefined ? null : Number(patientAge) || null,
        pastHistory: item?.pastHistory || '',
        currentProblem: item?.currentProblem || '',
        imageRecognitionResult: item?.imageRecognitionResult || '',
        finalSummary: item?.finalSummary || '',
        finishedAt: item?.finishedAt || '',
        metadata: item?.metadata || null
      })
    })
    .filter((x): x is LinkedConsultation => x !== null)
}

@Observed
export class ConsultViewModel {
  @Observed consultationName: string = ''
  @Observed settings: ConsultationSettings = new ConsultationSettings()
  @Observed doctors: Doctor[] = []
  @Observed patientCase: PatientCase = new PatientCase()
  @Observed linkedConsultations: LinkedConsultation[] = []
  @Observed workflow: Workflow = new Workflow()
  @Observed discussionHistory: DiscussionMessage[] = []
  @Observed lastRoundVotes: VoteRecord[] = []
  @Observed finalSummary: FinalSummary = new FinalSummary()

  private persistence: PersistenceManager = PersistenceManager.getInstance()
  private autoSaveTimer: number | null = null
  private onAutoSaveCallback: ((snapshot: ConsultationSnapshot) => Promise<void>) | null = null

  getActiveDoctors(): Doctor[] {
    return this.doctors.filter(d => d.status === 'active')
  }

  hasAnyApiKeys(): boolean {
    return this.doctors.some(d => d.apiKey)
  }

  setConsultationName(name: string): void {
    const value = typeof name === 'string' ? name.trim() : ''
    this.consultationName = value
    this.debounceAutoSave()
  }

  setSettings(newSettings: Partial<ConsultationSettings>): void {
    this.settings = new ConsultationSettings({ ...this.settings, ...newSettings })
    this.debounceAutoSave()
  }

  setDoctors(newDoctors: Doctor[]): void {
    this.doctors = newDoctors
    this.debounceAutoSave()
  }

  setPatientCase(caseInfo: Partial<PatientCase>): void {
    const payload = new PatientCase({ ...this.patientCase, ...caseInfo })

    if (caseInfo?.imageRecognitions !== undefined) {
      payload.imageRecognitions = sanitizeImageRecognitions(caseInfo.imageRecognitions)
      const summary = summarizeImageRecognitions(payload.imageRecognitions)
      if (summary) {
        payload.imageRecognitionResult = summary
      } else if (!payload.imageRecognitionResult) {
        payload.imageRecognitionResult = ''
      }
    }

    if (!Array.isArray(payload.imageRecognitions)) {
      payload.imageRecognitions = []
    }

    this.patientCase = payload
    this.debounceAutoSave()
  }

  setLinkedConsultations(list: LinkedConsultation[], options: { syncPatientInfo?: boolean } = {}): void {
    const { syncPatientInfo = true } = options
    const sanitized = sanitizeLinkedConsultations(list)
    this.linkedConsultations = sanitized

    if (syncPatientInfo && sanitized.length > 0) {
      const first = sanitized[0]
      const update: Partial<PatientCase> = {}

      if (first.patientName !== undefined && first.patientName !== null) {
        update.name = String(first.patientName).trim()
      }
      if (first.patientGender !== undefined && first.patientGender !== null) {
        update.gender = String(first.patientGender).trim()
      }
      if (first.patientAge !== undefined) {
        if (first.patientAge === null || first.patientAge === undefined || first.patientAge === '') {
          update.age = null
        } else {
          const ageNumber = Number(first.patientAge)
          update.age = Number.isFinite(ageNumber) ? ageNumber : null
        }
      }

      if (Object.keys(update).length > 0) {
        this.setPatientCase(update)
      }
    }

    this.debounceAutoSave()
  }

  addPatientMessage(text: string): void {
    const content = String(text || '').trim()
    if (!content) return

    const name = this.patientCase?.name ? `患者（${this.patientCase.name}）` : '患者'
    const msg = new DiscussionMessage({
      type: 'patient',
      author: name,
      content
    })
    this.discussionHistory = [...this.discussionHistory, msg]
    this.debounceAutoSave()
  }

  addDoctorMessage(doctorId: string, doctorName: string, content: string): void {
    const msg = new DiscussionMessage({
      type: 'doctor',
      doctorId,
      doctorName,
      content
    })
    this.discussionHistory = [...this.discussionHistory, msg]
    this.debounceAutoSave()
  }

  addSystemMessage(content: string): void {
    const msg = new DiscussionMessage({
      type: 'system',
      content
    })
    this.discussionHistory = [...this.discussionHistory, msg]
    this.debounceAutoSave()
  }

  addVoteDetailMessage(voterId: string, voterName: string, targetId: string, targetName: string, reason: string): void {
    const msg = new DiscussionMessage({
      type: 'vote_detail',
      voterId,
      voterName,
      targetId,
      targetName,
      reason
    })
    this.discussionHistory = [...this.discussionHistory, msg]
    this.debounceAutoSave()
  }

  addVoteResultMessage(content: string): void {
    const msg = new DiscussionMessage({
      type: 'vote_result',
      content
    })
    this.discussionHistory = [...this.discussionHistory, msg]
    this.debounceAutoSave()
  }

  resetVotes(): void {
    this.doctors = this.doctors.map(d => new Doctor({ ...d, votes: 0 }))
  }

  voteForDoctor(doctorId: string): void {
    this.doctors = this.doctors.map(d =>
      d.id === doctorId ? new Doctor({ ...d, votes: d.votes + 1 }) : d
    )
  }

  eliminateDoctor(doctorId: string): void {
    this.doctors = this.doctors.map(d =>
      d.id === doctorId ? new Doctor({ ...d, status: 'eliminated' }) : d
    )
  }

  async startConsultation(): Promise<void> {
    if (!this.patientCase.name || !this.patientCase.currentProblem) {
      throw new Error('请填写患者名称和本次问题')
    }
    if (!this.doctors || this.doctors.length === 0) {
      throw new Error('请添加至少一位医生后再开始会诊（可在设置中添加）')
    }

    this.doctors = this.doctors.map(d => new Doctor({ ...d, status: 'active', votes: 0 }))
    this.workflow = new Workflow({
      phase: 'discussion',
      currentRound: 1,
      roundsWithoutElimination: 0,
      activeTurn: null,
      turnQueue: [],
      paused: false
    })
    this.finalSummary = new FinalSummary({
      status: 'idle',
      doctorId: null,
      doctorName: '',
      content: '',
      usedPrompt: ''
    })

    this.addSystemMessage(`第 ${this.workflow.currentRound} 轮会诊开始`)
    this.generateTurnQueue()
    this.debounceAutoSave()
  }

  generateTurnQueue(): void {
    const actives = this.doctors.filter(d => d.status === 'active').map(d => d.id)

    if (this.settings.turnOrder === 'random') {
      this.workflow.turnQueue = actives
        .map(id => ({ id, r: Math.random() }))
        .sort((a, b) => a.r - b.r)
        .map(x => x.id)
    } else {
      this.workflow.turnQueue = actives
    }
  }

  async runDiscussionRound(): Promise<void> {
    for (const doctorId of this.workflow.turnQueue) {
      const doctor = this.doctors.find(d => d.id === doctorId)
      if (!doctor || doctor.status !== 'active') continue

      await this.waitWhilePaused()

      this.workflow = new Workflow({ ...this.workflow, activeTurn: doctorId })
      this.debounceAutoSave()

      const typingIndex = this.discussionHistory.length
      this.addSystemMessage(`${doctor.name} 正在输入...`)

      const systemPrompt = doctor.customPrompt || this.settings.globalSystemPrompt
      const fullPrompt = PromptBuilder.buildFullPrompt(
        systemPrompt,
        this.patientCase,
        this.discussionHistory,
        doctor.id,
        this.linkedConsultations
      )

      try {
        const providerHistory = PromptBuilder.formatHistoryForProvider(
          this.discussionHistory,
          this.patientCase,
          doctor.id
        )
        const response = await AIService.callAI(doctor, fullPrompt, providerHistory)

        // Remove typing indicator
        this.discussionHistory = this.discussionHistory.filter((_, idx) => idx !== typingIndex)

        // Add doctor message with typewriter effect
        const msg = new DiscussionMessage({
          type: 'doctor',
          doctorId: doctor.id,
          doctorName: doctor.name,
          content: ''
        })
        this.discussionHistory = [...this.discussionHistory, msg]
        const messageIndex = this.discussionHistory.length - 1

        for (let i = 0; i < response.length; i++) {
          await this.waitWhilePaused()
          const current = this.discussionHistory[messageIndex]
          if (current) {
            current.content += response[i]
            this.discussionHistory = [...this.discussionHistory]
          }
          await delay(15)
        }

        this.workflow = new Workflow({ ...this.workflow, activeTurn: null })
        this.debounceAutoSave()
      } catch (e) {
        this.workflow = new Workflow({ ...this.workflow, activeTurn: null })
        this.debounceAutoSave()

        // Remove typing indicator
        this.discussionHistory = this.discussionHistory.filter((_, idx) => idx !== typingIndex)

        this.addDoctorMessage(
          doctor.id,
          doctor.name,
          `调用 ${doctor.name} 失败: ${(e as Error).message || e}`
        )
      }
    }

    this.workflow = new Workflow({ ...this.workflow, phase: 'voting' })
    this.addSystemMessage('本轮发言结束，医生团队正在评估答案...')
    this.debounceAutoSave()
  }

  pause(): void {
    this.workflow = new Workflow({ ...this.workflow, paused: true })
    this.debounceAutoSave()
  }

  resume(): void {
    this.workflow = new Workflow({ ...this.workflow, paused: false })
    this.debounceAutoSave()
  }

  togglePause(): void {
    this.workflow = new Workflow({ ...this.workflow, paused: !this.workflow.paused })
    this.debounceAutoSave()
  }

  async waitWhilePaused(): Promise<void> {
    while (this.workflow.paused) {
      await delay(100)
    }
  }

  async autoVoteAndProceed(): Promise<void> {
    this.resetVotes()
    this.lastRoundVotes = []

    function parseVoteJSON(text: string): any {
      if (!text || typeof text !== 'string') return null
      const start = text.indexOf('{')
      const end = text.lastIndexOf('}')
      if (start !== -1 && end !== -1 && end > start) {
        const candidate = text.slice(start, end + 1)
        try {
          return JSON.parse(candidate)
        } catch (e) {
          try {
            const fixed = candidate.replace(/'/g, '"')
            return JSON.parse(fixed)
          } catch (e2) {
            return null
          }
        }
      }
      return null
    }

    const activeDocs = this.getActiveDoctors()
    const activeIds = activeDocs.map(d => d.id)

    for (const voterDoc of activeDocs) {
      await this.waitWhilePaused()
      let targetId: string | null = null
      let reason: string = ''

      try {
        if (!voterDoc.apiKey) {
          targetId = voterDoc.id
          reason = '模拟模式：自评其答案需进一步论证，标注自己。'
        } else {
          const systemPrompt = voterDoc.customPrompt || this.settings.globalSystemPrompt
          const fullPrompt = PromptBuilder.buildVotePrompt(
            systemPrompt,
            this.patientCase,
            this.discussionHistory,
            activeDocs,
            voterDoc,
            this.linkedConsultations
          )
          const providerHistory = PromptBuilder.formatHistoryForProvider(
            this.discussionHistory,
            this.patientCase,
            voterDoc.id
          )
          const response = await AIService.callAI(voterDoc, fullPrompt, providerHistory)
          const parsed = parseVoteJSON(response)
          if (parsed && typeof parsed.targetDoctorId === 'string') {
            targetId = parsed.targetDoctorId
            reason = String(parsed.reason || '').trim() || '综合讨论后做出的判断。'
          }
        }
      } catch (e) {
        Logger.warn(TAG, `Vote call failed: ${e}`)
      }

      if (!targetId || !activeIds.includes(targetId)) {
        targetId = voterDoc.id
        if (!reason) reason = '解析失败：默认标注自己。'
      }

      const targetDoc = this.doctors.find(d => d.id === targetId)

      this.lastRoundVotes = [
        ...this.lastRoundVotes,
        new VoteRecord({
          round: this.workflow.currentRound,
          voterId: voterDoc?.id || '',
          voterName: voterDoc?.name || '',
          targetId: targetDoc?.id || '',
          targetName: targetDoc?.name || '',
          reason
        })
      ]

      this.addVoteDetailMessage(
        voterDoc?.id || '',
        voterDoc?.name || '',
        targetDoc?.id || '',
        targetDoc?.name || '',
        reason
      )

      this.voteForDoctor(targetId!)
      await delay(50)
    }

    await delay(200)
    await this.confirmVote()
  }

  tallyVotes(): { eliminated: Doctor | null; message: string } {
    const activeOrElim = this.doctors.filter(d => d.status === 'active')
    const maxVotes = Math.max(0, ...activeOrElim.map(d => d.votes))
    const top = activeOrElim.filter(d => d.votes === maxVotes)

    if (top.length !== 1 || maxVotes === 0) {
      this.workflow = new Workflow({
        ...this.workflow,
        roundsWithoutElimination: this.workflow.roundsWithoutElimination + 1
      })
      return { eliminated: null, message: '评估结束：因意见不一或未明确，本轮未标注不太准确。' }
    }

    const target = top[0]
    this.eliminateDoctor(target.id)
    this.workflow = new Workflow({
      ...this.workflow,
      roundsWithoutElimination: 0
    })

    return { eliminated: target, message: `评估结束：${target.name} 已被标注为不太准确，并暂停参与后续讨论。` }
  }

  async confirmVote(): Promise<void> {
    const result = this.tallyVotes()
    this.addVoteResultMessage(result.message)
    this.debounceAutoSave()

    const ended = await this.checkEndConditions(result.eliminated)
    if (!ended) {
      this.resetVotes()
      this.workflow = new Workflow({
        ...this.workflow,
        currentRound: this.workflow.currentRound + 1
      })
      this.addSystemMessage(`第 ${this.workflow.currentRound} 轮会诊开始`)
      this.workflow = new Workflow({
        ...this.workflow,
        phase: 'discussion'
      })
      this.generateTurnQueue()
      this.debounceAutoSave()
      await this.runDiscussionRound()
    }
  }

  async checkEndConditions(eliminated: Doctor | null): Promise<boolean> {
    const activeCount = this.doctors.filter(d => d.status === 'active').length

    if (this.workflow.roundsWithoutElimination >= this.settings.maxRoundsWithoutElimination) {
      this.workflow = new Workflow({
        ...this.workflow,
        phase: 'finished'
      })
      this.addSystemMessage('达到未标注不太准确轮数上限，会诊结束。')
      this.debounceAutoSave()
      await this.generateFinalSummary(null)
      return true
    }

    if (activeCount <= 1) {
      this.workflow = new Workflow({
        ...this.workflow,
        phase: 'finished'
      })

      if (activeCount === 1) {
        const winner = this.doctors.find(d => d.status === 'active')
        this.addSystemMessage(`会诊结束：采用 ${winner?.name || ''} 的答案。`)
        this.debounceAutoSave()
        await this.generateFinalSummary(winner?.id || null)
      } else {
        this.addSystemMessage('会诊结束：无在席医生。')
        this.debounceAutoSave()
        await this.generateFinalSummary(null)
      }

      return true
    }

    this.workflow = new Workflow({
      ...this.workflow,
      phase: 'voting'
    })
    this.debounceAutoSave()
    return false
  }

  async generateFinalSummary(preferredDoctorId: string | null): Promise<void> {
    try {
      const activeDocs = this.getActiveDoctors()
      const summarizer = preferredDoctorId
        ? this.doctors.find(d => d.id === preferredDoctorId)
        : activeDocs[0] || this.doctors[0] || null

      if (!summarizer) return

      const usedPrompt = this.settings.summaryPrompt || '请根据完整会诊内容，以临床医生口吻输出最终总结：包含核心诊断、依据、鉴别诊断、检查建议、治疗建议、随访计划和风险提示。'
      this.finalSummary = new FinalSummary({
        status: 'pending',
        doctorId: summarizer.id,
        doctorName: summarizer.name,
        content: '',
        usedPrompt
      })
      this.debounceAutoSave()

      const fullPrompt = PromptBuilder.buildFinalSummaryPrompt(
        usedPrompt,
        this.patientCase,
        this.discussionHistory,
        summarizer.id,
        this.linkedConsultations
      )
      const providerHistory = PromptBuilder.formatHistoryForProvider(
        this.discussionHistory,
        this.patientCase,
        summarizer.id
      )

      const response = await AIService.callAI(summarizer, fullPrompt, providerHistory)
      this.finalSummary = new FinalSummary({
        status: 'ready',
        doctorId: summarizer.id,
        doctorName: summarizer.name,
        content: response,
        usedPrompt
      })
      this.debounceAutoSave()
    } catch (e) {
      this.finalSummary = new FinalSummary({
        ...this.finalSummary,
        status: 'error',
        content: `生成总结失败：${(e as Error)?.message || e}`
      })
      this.debounceAutoSave()
    }
  }

  loadFromSnapshot(snapshot: ConsultationSnapshot): void {
    this.consultationName = snapshot.consultationName || ''
    this.settings = new ConsultationSettings(snapshot.settings)
    this.doctors = snapshot.doctors?.map(d => new Doctor(d)) || []
    this.patientCase = new PatientCase(snapshot.patientCase)
    this.linkedConsultations = snapshot.linkedConsultations?.map(c => new LinkedConsultation(c)) || []
    this.workflow = new Workflow(snapshot.workflow)
    this.discussionHistory = snapshot.discussionHistory?.map(m => new DiscussionMessage(m)) || []
    this.lastRoundVotes = snapshot.lastRoundVotes?.map(v => new VoteRecord(v)) || []
    this.finalSummary = new FinalSummary(snapshot.finalSummary)
  }

  toSnapshot(): ConsultationSnapshot {
    return new ConsultationSnapshot({
      consultationName: this.consultationName,
      settings: this.settings,
      doctors: this.doctors,
      patientCase: this.patientCase,
      linkedConsultations: this.linkedConsultations,
      workflow: this.workflow,
      discussionHistory: this.discussionHistory,
      lastRoundVotes: this.lastRoundVotes,
      finalSummary: this.finalSummary
    })
  }

  setOnAutoSaveCallback(callback: (snapshot: ConsultationSnapshot) => Promise<void>): void {
    this.onAutoSaveCallback = callback
  }

  private debounceAutoSave(): void {
    if (this.autoSaveTimer !== null) {
      clearTimeout(this.autoSaveTimer)
    }

    this.autoSaveTimer = setTimeout(() => {
      if (this.onAutoSaveCallback) {
        this.onAutoSaveCallback(this.toSnapshot()).catch(e => {
          Logger.warn(TAG, `Auto-save failed: ${e}`)
        })
      }
      this.autoSaveTimer = null
    }, 1000) as any // Debounce for 1 second
  }

  reset(): void {
    this.consultationName = ''
    this.settings = new ConsultationSettings()
    this.doctors = []
    this.patientCase = new PatientCase()
    this.linkedConsultations = []
    this.workflow = new Workflow()
    this.discussionHistory = []
    this.lastRoundVotes = []
    this.finalSummary = new FinalSummary()
  }
}

// Singleton instance
let instance: ConsultViewModel | null = null

export function getConsultViewModel(): ConsultViewModel {
  if (!instance) {
    instance = new ConsultViewModel()
  }
  return instance
}
