// Doctor model
export class Doctor {
  id: string = ''
  name: string = ''
  provider: string = 'openai' // 'openai' | 'anthropic' | 'gemini' | 'siliconflow' | 'modelscope'
  model: string = ''
  apiKey: string = ''
  baseUrl: string = ''
  customPrompt: string = ''
  status: string = 'active' // 'active' | 'eliminated'
  votes: number = 0

  constructor(data?: Partial<Doctor>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Patient case information
export class PatientCase {
  name: string = ''
  gender: string = '' // 'male' | 'female' | 'other'
  age: number | null = null
  pastHistory: string = ''
  currentProblem: string = ''
  imageRecognitionResult: string = ''
  imageRecognitions: ImageRecognition[] = []

  constructor(data?: Partial<PatientCase>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Image recognition result
export class ImageRecognition {
  id: string = ''
  name: string = ''
  dataUrl: string = ''
  imageUrl?: string = ''
  result: string = ''
  status: string = 'queued' // 'queued' | 'recognizing' | 'success' | 'error'
  error: string = ''
  createdAt: number = 0
  raw: string = ''

  constructor(data?: Partial<ImageRecognition>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Linked consultation reference
export class LinkedConsultation {
  id: string = ''
  sourceId: string = ''
  consultationName: string = ''
  patientName: string = ''
  patientGender: string = ''
  patientAge: number | null = null
  pastHistory: string = ''
  currentProblem: string = ''
  imageRecognitionResult: string = ''
  finalSummary: string = ''
  finishedAt: string = ''
  metadata: Object | null = null

  constructor(data?: Partial<LinkedConsultation>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Discussion message
export class DiscussionMessage {
  type: string = 'doctor' // 'doctor' | 'patient' | 'system' | 'vote_detail' | 'vote_result'
  author?: string = ''
  content: string = ''
  doctorId?: string = ''
  doctorName?: string = ''
  voterId?: string = ''
  voterName?: string = ''
  targetId?: string = ''
  targetName?: string = ''
  reason?: string = ''
  createdAt?: number = 0

  constructor(data?: Partial<DiscussionMessage>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Vote record
export class VoteRecord {
  round: number = 0
  voterId: string = ''
  voterName: string = ''
  targetId: string = ''
  targetName: string = ''
  reason: string = ''

  constructor(data?: Partial<VoteRecord>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Workflow state
export class Workflow {
  phase: string = 'setup' // 'setup' | 'discussion' | 'voting' | 'finished'
  currentRound: number = 0
  roundsWithoutElimination: number = 0
  activeTurn: string | null = null
  turnQueue: string[] = []
  paused: boolean = false

  constructor(data?: Partial<Workflow>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Settings
export class ConsultationSettings {
  globalSystemPrompt: string = '你是一位顶级的、经验丰富的临床诊断医生。你的任务是基于提供的患者病历进行分析和诊断。\n\n现在，你正在参与一个多方专家会诊。你会看到其他医生的诊断意见。请综合考虑他们的分析，这可能会启发你，但你必须保持自己独立的专业判断。\n\n你的发言必须遵循以下原则：\n1.  专业严谨: 你的分析必须基于医学知识和病历信息。\n2.  独立思考: 不要为了迎合他人而轻易改变自己的核心观点。如果其他医生的观点是正确的，你可以表示赞同并加以补充；如果观点有误或你持有不同看法，必须明确、有理有据地指出。\n3.  目标导向: 会诊的唯一目标是为患者找到最佳的解决方案。\n4.  简洁清晰: 直接陈述你的核心诊断、分析和建议。\n\n现在，请根据下面的病历和已有的讨论，发表你的看法。'
  summaryPrompt: string = '请根据完整会诊内容，以临床医生口吻输出最终总结：包含核心诊断、依据、鉴别诊断、检查建议、治疗建议、随访计划和风险提示。'
  turnOrder: string = 'random' // 'random' | 'sequential'
  maxRoundsWithoutElimination: number = 3

  constructor(data?: Partial<ConsultationSettings>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Final summary
export class FinalSummary {
  status: string = 'idle' // 'idle' | 'pending' | 'ready' | 'error'
  doctorId: string | null = null
  doctorName: string = ''
  content: string = ''
  usedPrompt: string = ''

  constructor(data?: Partial<FinalSummary>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Global image recognition config
export class ImageRecognitionConfig {
  enabled: boolean = false
  provider: string = 'siliconflow'
  model: string = 'Pro/Qwen/Qwen2-VL-72B-Instruct'
  apiKey: string = ''
  baseUrl: string = ''
  prompt: string = '识别当前病灶相关的图片内容。请仔细观察图片中的所有细节，用专业医学术语描述图片中的病灶特征、位置、形态、颜色、大小等关键信息。如果图片中没有明显的病灶相关内容或与医疗诊断无关，请明确说明"图片内容与病灶无关"。请使用专业、严谨的语气进行描述。'
  maxConcurrent: number = 1

  constructor(data?: Partial<ImageRecognitionConfig>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Preset prompt
export class PresetPrompt {
  id: string = ''
  name: string = ''
  prompt: string = ''

  constructor(data?: Partial<PresetPrompt>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Session metadata
export class SessionMeta {
  id: string = ''
  name: string = ''
  status: string = '配置/准备'
  createdAt: string = ''
  updatedAt: string = ''

  constructor(data?: Partial<SessionMeta>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Full consultation state snapshot
export class ConsultationSnapshot {
  consultationName: string = ''
  settings?: ConsultationSettings
  doctors: Doctor[] = []
  patientCase: PatientCase = new PatientCase()
  linkedConsultations: LinkedConsultation[] = []
  workflow: Workflow = new Workflow()
  discussionHistory: DiscussionMessage[] = []
  lastRoundVotes: VoteRecord[] = []
  finalSummary: FinalSummary = new FinalSummary()

  constructor(data?: Partial<ConsultationSnapshot>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Message types for API calls
export class APIMessage {
  role: string = '' // 'user' | 'assistant' | 'system'
  content: string = ''

  constructor(data?: Partial<APIMessage>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}

// Prompt structure for AI
export class PromptPair {
  system: string = ''
  user: string = ''

  constructor(data?: Partial<PromptPair>) {
    if (data) {
      Object.assign(this, data)
    }
  }
}
