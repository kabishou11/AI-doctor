import { defineStore } from 'pinia'
import { callAI } from '../api/callAI'
import { buildFullPrompt, buildVotePrompt, buildFinalSummaryPrompt, formatHistoryForProvider } from '../utils/prompt'
import { useKnowledgeStore } from './knowledge'

const DEFAULT_CALL_TIMEOUT = Number(import.meta.env?.VITE_AI_TIMEOUT_MS || 60000) || 60000

async function callWithTimeout(fn, timeoutMs = DEFAULT_CALL_TIMEOUT) {
  let timer
  try {
    const res = await Promise.race([
      fn(),
      new Promise((_, rej) => {
        timer = setTimeout(() => rej(new Error('调用超时，请检查模型配置或网络')), timeoutMs)
      })
    ])
    return res
  } finally {
    if (timer) clearTimeout(timer)
  }
}

function delay(ms) {
  return new Promise((res) => setTimeout(res, ms))
}

function sanitizeImageRecognitions(list) {
  if (!Array.isArray(list)) return []
  const now = Date.now()
  return list.map((item, idx) => {
    const status = normalizeStatus(item)
    return {
      id: item?.id || `img-${now}-${idx}`,
      name: item?.name || '',
      dataUrl: item?.dataUrl || item?.imageUrl || '',
      result: item?.result || '',
      status,
      error: item?.error || '',
      createdAt: item?.createdAt || now,
      raw: status === 'queued' || status === 'recognizing' ? item?.raw || '' : ''
    }
  })
}

function normalizeStatus(item) {
  const status = item?.status
  if (status === 'queued' || status === 'recognizing') return 'queued'
  if (status === 'error') return 'error'
  if (status === 'success') return 'success'
  if (item?.error) return 'error'
  if (item?.result) return 'success'
  return 'queued'
}

function summarizeImageRecognitions(list) {
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

function sanitizeLinkedConsultations(list) {
  if (!Array.isArray(list)) return []
  return list
    .map((item, idx) => {
      if (!item) return null
      const id = typeof item.id === 'string' && item.id ? item.id : item?.sourceId || `linked-${idx}`
      const patientAge = item?.patientAge
      return {
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
        finishedAt: item?.finishedAt || item?.finishedAt || '',
        metadata: item?.metadata || null
      }
    })
    .filter(Boolean)
}

export const useConsultStore = defineStore('consult', {
  state: () => ({
    consultationName: '',
    settings: {
      globalSystemPrompt:
        '你是一位顶级的、经验丰富的临床诊断医生。你的任务是基于提供的患者病历进行分析和诊断。\n\n现在，你正在参与一个多方专家会诊。你会看到其他医生的诊断意见。请综合考虑他们的分析，这可能会启发你，但你必须保持自己独立的专业判断。\n\n你的发言必须遵循以下原则：\n1.  专业严谨: 你的分析必须基于医学知识和病历信息。\n2.  独立思考: 不要为了迎合他人而轻易改变自己的核心观点。如果其他医生的观点是正确的，你可以表示赞同并加以补充；如果观点有误或你持有不同看法，必须明确、有理有据地指出。\n3.  目标导向: 会诊的唯一目标是为患者找到最佳的解决方案。\n4.  简洁清晰: 直接陈述你的核心诊断、分析和建议。\n\n现在，请根据下面的病历和已有的讨论，发表你的看法。',
      summaryPrompt: '请根据完整会诊内容，以临床医生口吻输出最终总结：包含核心诊断、依据、鉴别诊断、检查建议、治疗建议、随访计划和风险提示。',
      turnOrder: 'random',
      maxRoundsWithoutElimination: 3
    },
    doctors: [],
    patientCase: {
      name: '',
      gender: '',
      age: null,
      pastHistory: '',
      currentProblem: '',
      imageRecognitionResult: '',
      imageRecognitions: []
    },
    selectedKnowledgeIds: [],
    linkedConsultations: [],
    workflow: {
      phase: 'setup',
      currentRound: 0,
      roundsWithoutElimination: 0,
      activeTurn: null,
      turnQueue: [],
      paused: false,
      progress: { total: 0, done: 0, current: '' }
    },
    lastSuccessDoctorId: null,
    discussionHistory: [],
    lastRoundVotes: [],
    finalSummary: { status: 'idle', doctorId: null, doctorName: '', content: '', usedPrompt: '' }
  }),
  getters: {
    activeDoctors(state) {
      return state.doctors.filter((d) => d.status === 'active')
    },
    anyApiKeys(state) {
      return state.doctors.some((d) => d.apiKey)
    }
  },
  actions: {
    setConsultationName(name) {
      const value = typeof name === 'string' ? name.trim() : ''
      this.consultationName = value
    },
    setSettings(newSettings) {
      this.settings = { ...this.settings, ...newSettings }
    },
    setDoctors(newDoctors) {
      this.doctors = newDoctors
    },
    setPatientCase(caseInfo) {
      const payload = { ...this.patientCase, ...caseInfo }
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
    },
    setLinkedConsultations(list, options = {}) {
      const { syncPatientInfo = true } = options
      const sanitized = sanitizeLinkedConsultations(list)
      this.linkedConsultations = sanitized
      if (syncPatientInfo && sanitized.length > 0) {
        const first = sanitized[0]
        const update = {}
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
    },
    addPatientMessage(text) {
      const content = String(text || '').trim()
      if (!content) return
      const name = this.patientCase?.name ? `患者（${this.patientCase.name}）` : '患者'
      this.discussionHistory.push({ type: 'patient', author: name, content })
    },
    setSelectedKnowledge(ids) {
      const valid = Array.isArray(ids) ? ids.filter((x) => typeof x === 'string' && x) : []
      this.selectedKnowledgeIds = Array.from(new Set(valid))
    },
    resetVotes() {
      this.doctors = this.doctors.map((d) => ({ ...d, votes: 0 }))
    },
    startConsultation() {
      if (!this.patientCase.name || !this.patientCase.currentProblem) {
        throw new Error('请填写患者名称和本次问题')
      }
      if (!this.doctors || this.doctors.length === 0) {
        throw new Error('请添加至少一位医生后再开始会诊（可在设置中添加）')
      }
      // 新的问诊开始时，所有医生恢复为在席状态，清空票数，并取消暂停
      this.doctors = this.doctors.map((d) => ({ ...d, status: 'active', votes: 0 }))
      this.workflow.phase = 'discussion'
      this.workflow.currentRound = 1
      this.workflow.roundsWithoutElimination = 0
      this.workflow.paused = false
      this.finalSummary = { status: 'idle', doctorId: null, doctorName: '', content: '', usedPrompt: '' }
      this.discussionHistory.push({ type: 'system', content: `第 ${this.workflow.currentRound} 轮会诊开始` })
      this.generateTurnQueue()
      this.runDiscussionRound()
    },
    generateTurnQueue() {
      const actives = this.doctors.filter((d) => d.status === 'active').map((d) => d.id)
      if (this.settings.turnOrder === 'random') {
        this.workflow.turnQueue = actives
          .map((id) => ({ id, r: Math.random() }))
          .sort((a, b) => a.r - b.r)
          .map((x) => x.id)
      } else {
        this.workflow.turnQueue = this.doctors.filter((d) => d.status === 'active').map((d) => d.id)
      }
      this.workflow.progress = { total: this.workflow.turnQueue.length, done: 0, current: '' }
    },
    buildCaseQueryText() {
      const parts = []
      if (this.patientCase?.name) parts.push(`患者: ${this.patientCase.name}`)
      if (this.patientCase?.gender) parts.push(`性别: ${this.patientCase.gender}`)
      if (this.patientCase?.age !== null && this.patientCase?.age !== undefined) parts.push(`年龄: ${this.patientCase.age}`)
      if (this.patientCase?.pastHistory) parts.push(`既往史: ${this.patientCase.pastHistory}`)
      if (this.patientCase?.currentProblem) parts.push(`主诉: ${this.patientCase.currentProblem}`)
      if (this.patientCase?.imageRecognitionResult) parts.push(`图片识别: ${this.patientCase.imageRecognitionResult}`)
      const latest = this.discussionHistory.slice(-4).map((m) => `${m.type === 'doctor' ? m.doctorName || '医生' : '患者'}: ${m.content}`).join('；')
      if (latest) parts.push(`讨论摘录: ${latest}`)
      return parts.join('\n')
    },
    async fetchKnowledgeContext() {
      try {
        const knowledge = useKnowledgeStore()
        const queryText = this.buildCaseQueryText()
        const entries = await knowledge.retrieveContext({
          queryText,
          selectedIds: this.selectedKnowledgeIds,
          topK: 5
        })
        return entries || []
      } catch (e) {
        return []
      }
    },
async runDiscussionRound() {
      const knowledgeEntries = await this.fetchKnowledgeContext()
      for (let idx = 0; idx < this.workflow.turnQueue.length; idx++) {
        const doctorId = this.workflow.turnQueue[idx]
        const doctor = this.doctors.find((d) => d.id === doctorId)
        if (!doctor || doctor.status !== 'active') continue

        // 如被暂停，等待恢复
        await this.waitWhilePaused()

        this.workflow.activeTurn = doctorId
        this.workflow.progress.current = doctor.name
        this.workflow.progress.done = idx
        // 提示“正在输入...”，随后在得到回复后移除
        const typingIndex = this.discussionHistory.push({ type: 'system', content: `${doctor.name} 正在输入...` }) - 1
        const systemPrompt = doctor.customPrompt || this.settings.globalSystemPrompt
        const fullPrompt = buildFullPrompt(systemPrompt, this.patientCase, this.discussionHistory, doctor.id, this.linkedConsultations, knowledgeEntries)
        try {
          const providerHistory = formatHistoryForProvider(this.discussionHistory, this.patientCase, doctor.id)
          const response = await callWithTimeout(() => callAI(doctor, fullPrompt, providerHistory))

          // 移除“正在输入...”提示
          this.discussionHistory.splice(typingIndex, 1)

          // 先插入空内容的医生气泡，然后打字机式填充
          const msg = { type: 'doctor', doctorId: doctor.id, doctorName: doctor.name, content: '' }
          this.discussionHistory.push(msg)
          const messageIndex = this.discussionHistory.length - 1

          for (let i = 0; i < response.length; i++) {
            await this.waitWhilePaused()
            this.discussionHistory[messageIndex].content += response[i]
            await delay(15)
          }

          this.workflow.activeTurn = null
          this.workflow.progress.done = idx + 1
          this.workflow.progress.current = ''
          this.lastSuccessDoctorId = doctor.id
        } catch (e) {
          this.workflow.activeTurn = null
          // 确保提示被移除
          try { this.discussionHistory.splice(typingIndex, 1) } catch (err) {}
          this.discussionHistory.push({
            type: 'doctor',
            doctorId: doctor.id,
            doctorName: doctor.name,
            content: `调用 ${doctor.name} 失败: ${e.message || e}`
          })
          this.workflow.progress.done = idx + 1
          this.workflow.progress.current = ''
        }
      }
      this.workflow.phase = 'voting'
      this.discussionHistory.push({ type: 'system', content: '本轮发言结束，医生团队正在评估答案...' })
      await this.autoVoteAndProceed()
    },
    // 控制暂停/恢复
    pause() { this.workflow.paused = true },
    resume() { this.workflow.paused = false },
    togglePause() { this.workflow.paused = !this.workflow.paused },

    async waitWhilePaused() {
      while (this.workflow.paused) {
        await delay(100)
      }
    },

    async autoVoteAndProceed() {
      // 使用模型驱动的自动投票（允许投自己）
      this.resetVotes()
      this.lastRoundVotes = []

      function parseVoteJSON(text, doctorList) {
        if (!text || typeof text !== 'string') return null
        // 去掉代码块/标记
        const cleaned = text.replace(/```json/gi, '```').replace(/```/g, '')
        const lower = cleaned.toLowerCase()
        const ids = Array.isArray(doctorList) ? doctorList.map((d) => d.id).filter(Boolean) : []
        const names = Array.isArray(doctorList) ? doctorList.map((d) => d.name).filter(Boolean) : []

        // 优先找包含 targetDoctorId 的对象
        const braceMatches = cleaned.match(/\{[\s\S]*?\}/g) || []
        for (const m of braceMatches) {
          if (!/targetDoctorId/i.test(m)) continue
          const candidate = m.replace(/,\s*}/g, '}').replace(/'/g, '"')
          try {
            return JSON.parse(candidate)
          } catch (e) {
            continue
          }
        }

        // 回退：截取首尾花括号
        const start = cleaned.indexOf('{')
        const end = cleaned.lastIndexOf('}')
        if (start !== -1 && end !== -1 && end > start) {
          const candidate = cleaned.slice(start, end + 1).replace(/,\s*}/g, '}').replace(/'/g, '"')
          try {
            return JSON.parse(candidate)
          } catch (e) {
            // ignore
          }
        }

        // 依据文本包含关系匹配（不区分大小写、去除空格符号）
        const compressedText = lower.replace(/[\s:：]/g, '')
        let bestHit = null
        doctorList.forEach((doc, idx) => {
          const variants = [
            (doc.id || '').toLowerCase(),
            (doc.name || '').toLowerCase(),
            (doc.name || '').toLowerCase().replace(/\s+/g, '')
          ].filter(Boolean)
          const score = variants.reduce((acc, v) => {
            if (!v) return acc
            const re = new RegExp(v.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&'), 'g')
            const matches = lower.match(re)
            const compressedRe = new RegExp(v.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&'), 'g')
            const compressedMatches = compressedText.match(compressedRe)
            return acc + (matches ? matches.length : 0) + (compressedMatches ? compressedMatches.length : 0)
          }, 0)
          if (score > 0 && (!bestHit || score > bestHit.score)) {
            bestHit = { id: doc.id, score }
          } else if (score === bestHit?.score && bestHit && idx === 0) {
            // keep earlier doctor on tie to avoid randomness
          }
        })

        if (bestHit) {
          return { targetDoctorId: bestHit.id, reason: '非JSON输出，依据文本关键词匹配' }
        }

        return { targetDoctorId: '', reason: '未按要求输出JSON' }
      }

      const activeDocs = this.doctors.filter((d) => d.status === 'active')
      const knowledgeEntries = await this.fetchKnowledgeContext()
      const activeIds = activeDocs.map((d) => d.id)

      for (const voterDoc of activeDocs) {
        await this.waitWhilePaused()
        let targetId = null
        let reason = ''
        let parsed = null
        let response = ''

        try {
          // 如果无 API Key，则使用确定性的回退策略：自投
          if (!voterDoc.apiKey) {
            targetId = voterDoc.id
            reason = '模拟模式：自评其答案需进一步论证，标注自己。'
          } else {
            const systemPrompt = voterDoc.customPrompt || this.settings.globalSystemPrompt
            const fullPrompt = buildVotePrompt(
              systemPrompt,
              this.patientCase,
              this.discussionHistory,
              activeDocs,
              voterDoc,
              this.linkedConsultations,
              knowledgeEntries
            )
            const providerHistory = formatHistoryForProvider(this.discussionHistory, this.patientCase, voterDoc.id)
            response = await callWithTimeout(() => callAI(voterDoc, fullPrompt, providerHistory))
            parsed = parseVoteJSON(response, activeDocs)
            if (parsed && typeof parsed.targetDoctorId === 'string') {
              targetId = parsed.targetDoctorId
              reason = String(parsed.reason || '').trim() || '综合讨论后做出的判断。'
            }
          }
        } catch (e) {
          // 忽略错误，使用回退
        }

        if (!targetId || !activeIds.includes(targetId)) {
          // 解析失败时优先回退为自标，避免误伤其他医生
          if (voterDoc?.id && activeIds.includes(voterDoc.id)) {
            targetId = voterDoc.id
            if (!reason) reason = '解析失败：默认标注自己。'
          } else {
            const other = this.doctors.find((d) => d.id !== voterDoc.id) || activeDocs.find((d) => d.id !== voterDoc.id)
            if (other) {
              targetId = other.id
              if (!reason) reason = '解析失败：默认标注其他医生。'
            } else {
              targetId = voterDoc?.id || activeIds[0]
              if (!reason) reason = '解析失败：默认标注自己。'
            }
          }
        }

        // 若解析失败，记录原始输出以便调试
        const trimmedResp = String(response || '').trim()
        if ((!parsed || !parsed.targetDoctorId) && trimmedResp) {
          this.discussionHistory.push({
            type: 'system',
            content: `评估输出未按JSON返回，原始内容：${trimmedResp.slice(0, 200)}`
          })
        }

        const targetDoc = this.doctors.find((d) => d.id === targetId)

        this.lastRoundVotes.push({
          round: this.workflow.currentRound,
          voterId: voterDoc?.id,
          voterName: voterDoc?.name,
          targetId: targetDoc?.id,
          targetName: targetDoc?.name,
          reason
        })

        this.discussionHistory.push({
          type: 'vote_detail',
          voterId: voterDoc?.id,
          voterName: voterDoc?.name,
          targetId: targetDoc?.id,
          targetName: targetDoc?.name,
          reason
        })

        this.voteForDoctor(targetId)
        await delay(50)
      }
      await delay(200)
      await this.confirmVote()
    },

    voteForDoctor(doctorId) {
      this.doctors = this.doctors.map((d) => (d.id === doctorId ? { ...d, votes: d.votes + 1 } : d))
    },
    async confirmVote() {
      const result = this.tallyVotes()
      this.discussionHistory.push({ type: 'vote_result', content: result.message })
      const ended = this.checkEndConditions(result.eliminated)
      if (!ended) {
        this.resetVotes()
        this.workflow.currentRound += 1
        this.discussionHistory.push({ type: 'system', content: `第 ${this.workflow.currentRound} 轮会诊开始` })
        this.workflow.phase = 'discussion'
        this.generateTurnQueue()
        await this.runDiscussionRound()
      }
    },
    async generateFinalSummary(preferredDoctorId) {
      const usedPrompt = this.settings.summaryPrompt || '请根据完整会诊内容，以临床医生口吻输出最终总结：包含核心诊断、依据、鉴别诊断、检查建议、治疗建议、随访计划和风险提示。'
      const activeDocs = this.doctors.filter((d) => d.status === 'active')
      const candidates = []
      if (preferredDoctorId) {
        const pd = this.doctors.find((d) => d.id === preferredDoctorId)
        if (pd) candidates.push(pd)
      }
      if (this.lastSuccessDoctorId) {
        const last = this.doctors.find((d) => d.id === this.lastSuccessDoctorId)
        if (last && !candidates.includes(last)) candidates.push(last)
      }
      activeDocs.forEach((d) => {
        if (!candidates.includes(d)) candidates.push(d)
      })
      if (!candidates.length && this.doctors.length) candidates.push(this.doctors[0])
      for (const summarizer of candidates) {
        try {
          this.finalSummary = { status: 'pending', doctorId: summarizer.id, doctorName: summarizer.name, content: '', usedPrompt }
          const knowledgeEntries = await this.fetchKnowledgeContext()
          const fullPrompt = buildFinalSummaryPrompt(usedPrompt, this.patientCase, this.discussionHistory, summarizer.id, this.linkedConsultations, knowledgeEntries)
          const providerHistory = formatHistoryForProvider(this.discussionHistory, this.patientCase, summarizer.id)
          const response = await callWithTimeout(() => callAI(summarizer, fullPrompt, providerHistory))
          this.finalSummary = { status: 'ready', doctorId: summarizer.id, doctorName: summarizer.name, content: response, usedPrompt }
          return
        } catch (e) {
          this.finalSummary = { status: 'error', doctorId: summarizer.id, doctorName: summarizer.name, content: `生成总结失败：${e?.message || e}`, usedPrompt }
          continue
        }
      }
    },
    tallyVotes() {
      const activeOrElim = this.doctors.filter((d) => d.status === 'active')
      const maxVotes = Math.max(0, ...activeOrElim.map((d) => d.votes))
      const top = activeOrElim.filter((d) => d.votes === maxVotes)
      if (top.length !== 1 || maxVotes === 0) {
        this.workflow.roundsWithoutElimination += 1
        return { eliminated: null, message: '评估结束：因意见不一或未明确，本轮未标注不太准确。' }
      }
      const target = top[0]
      this.doctors = this.doctors.map((d) => (d.id === target.id ? { ...d, status: 'eliminated' } : d))
      this.workflow.roundsWithoutElimination = 0
      return { eliminated: target, message: `评估结束：${target.name} 已被标注为不太准确，并暂停参与后续讨论。` }
    },
    checkEndConditions(eliminated) {
      const activeCount = this.doctors.filter((d) => d.status === 'active').length
      if (this.workflow.roundsWithoutElimination >= this.settings.maxRoundsWithoutElimination) {
        this.workflow.phase = 'finished'
        this.discussionHistory.push({ type: 'system', content: '达到未标注不太准确轮数上限，会诊结束。' })
        // 无单一推荐者时也需要输出最终答案，默认由首位在席医生生成
        this.generateFinalSummary()
        return true
      }
      if (activeCount <= 1) {
        this.workflow.phase = 'finished'
        if (activeCount === 1) {
          const winner = this.doctors.find((d) => d.status === 'active')
          this.discussionHistory.push({ type: 'system', content: `会诊结束：采用 ${winner?.name || ''} 的答案。` })
          this.generateFinalSummary(winner?.id)
        } else {
          this.discussionHistory.push({ type: 'system', content: '会诊结束：无在席医生。' })
          this.generateFinalSummary()
        }
        return true
      }
      this.workflow.phase = 'voting'
      return false
    }
  }
})
