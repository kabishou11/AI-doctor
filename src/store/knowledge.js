import { defineStore } from 'pinia'

const KNOWLEDGE_KEY = 'kb_docs_v1'
const KNOWLEDGE_CHUNKS_KEY = 'kb_chunks_v1'
const EMBEDDING_CONFIG_KEY = 'kb_embedding_config_v1'
const RETRIEVAL_CONFIG_KEY = 'kb_retrieval_config_v1'

function genId(prefix = 'kb') {
  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`
}

function normalizeDoc(doc) {
  if (!doc) return null
  return {
    id: typeof doc.id === 'string' && doc.id ? doc.id : genId(),
    title: typeof doc.title === 'string' ? doc.title : '未命名文档',
    tags: Array.isArray(doc.tags) ? doc.tags.filter(Boolean) : [],
    collectionId: typeof doc.collectionId === 'string' ? doc.collectionId : '',
    content: typeof doc.content === 'string' ? doc.content : '',
    excerpt: typeof doc.excerpt === 'string' ? doc.excerpt : '',
    createdAt: doc.createdAt || new Date().toISOString(),
    updatedAt: doc.updatedAt || new Date().toISOString()
  }
}

function loadDocs() {
  try {
    const raw = localStorage.getItem(KNOWLEDGE_KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw)
    if (!Array.isArray(parsed)) return []
    return parsed.map((d) => normalizeDoc(d)).filter(Boolean)
  } catch (e) {
    return []
  }
}

function saveDocs(docs) {
  localStorage.setItem(KNOWLEDGE_KEY, JSON.stringify(docs || []))
}

export const useKnowledgeStore = defineStore('knowledge', {
  state: () => ({
    docs: loadDocs(),
    chunks: loadChunks(),
    collections: [],
    pinnedIds: [],
    embeddingConfig: loadEmbeddingConfig(),
    retrievalConfig: loadRetrievalConfig()
  }),
  getters: {
    docMap(state) {
      return new Map((state.docs || []).map((d) => [d.id, d]))
    },
    byCollection: (state) => {
      const grouped = {}
      for (const doc of state.docs || []) {
        const key = doc.collectionId || 'default'
        if (!grouped[key]) grouped[key] = []
        grouped[key].push(doc)
      }
      return grouped
    }
  },
  actions: {
    addDoc(payload) {
      const doc = normalizeDoc(payload)
      doc.createdAt = doc.createdAt || new Date().toISOString()
      doc.updatedAt = new Date().toISOString()
      this.docs.unshift(doc)
      saveDocs(this.docs)
      return doc.id
    },
    updateDoc(id, patch) {
      const idx = this.docs.findIndex((d) => d.id === id)
      if (idx === -1) return
      const next = normalizeDoc({ ...this.docs[idx], ...patch, id })
      next.createdAt = this.docs[idx].createdAt || next.createdAt
      next.updatedAt = new Date().toISOString()
      this.docs.splice(idx, 1, next)
      saveDocs(this.docs)
    },
    removeDoc(id) {
      this.docs = this.docs.filter((d) => d.id !== id)
      this.pinnedIds = this.pinnedIds.filter((pid) => pid !== id)
      this.chunks = this.chunks.filter((c) => c.docId !== id)
      saveDocs(this.docs)
      saveChunks(this.chunks)
    },
    setPinned(ids) {
      const valid = Array.isArray(ids) ? ids.filter((x) => typeof x === 'string' && x) : []
      this.pinnedIds = valid
    },
    search(query, tags = []) {
      const q = (query || '').toLowerCase().trim()
      const activeTags = Array.isArray(tags) ? tags.filter(Boolean) : []
      return (this.docs || []).filter((doc) => {
        const inTags = activeTags.length ? activeTags.every((t) => doc.tags?.includes(t)) : true
        if (!inTags) return false
        if (!q) return true
        return (
          doc.title?.toLowerCase().includes(q) ||
          doc.content?.toLowerCase().includes(q) ||
          (doc.tags || []).some((t) => t.toLowerCase().includes(q))
        )
      })
    },
    importData(json) {
      try {
        const parsed = typeof json === 'string' ? JSON.parse(json) : json
        const incoming = Array.isArray(parsed?.docs) ? parsed.docs : Array.isArray(parsed) ? parsed : []
        const normalized = incoming.map((d) => normalizeDoc(d)).filter(Boolean)
        // 去重: 以 title+content hash 简单去重
        const existing = new Map()
        for (const doc of this.docs) {
          const key = `${doc.title}::${doc.content}`
          existing.set(key, doc)
        }
        const merged = [...this.docs]
        for (const doc of normalized) {
          const key = `${doc.title}::${doc.content}`
          if (existing.has(key)) continue
          merged.push({ ...doc, id: genId() })
        }
        this.docs = merged
        saveDocs(this.docs)
        return { imported: normalized.length, merged: merged.length }
      } catch (e) {
        throw new Error('导入失败：格式错误或内容无效')
      }
    },
    exportData() {
      return JSON.stringify({ docs: this.docs }, null, 2)
    },
    setEmbeddingConfig(config) {
      const payload = {
        provider: 'modelscope',
        model: config?.model || 'text-embedding-v3',
        apiKey: config?.apiKey || '',
        baseUrl: config?.baseUrl || ''
      }
      this.embeddingConfig = payload
      saveEmbeddingConfig(payload)
    },
    setRetrievalConfig(config) {
      const payload = {
        topK: Number.isFinite(config?.topK) ? Math.max(1, Math.min(10, Math.floor(config.topK))) : 5,
        keywordWeight: Number.isFinite(config?.keywordWeight) ? Math.min(1, Math.max(0, config.keywordWeight)) : 0.5
      }
      this.retrievalConfig = payload
      saveRetrievalConfig(payload)
    },
    async ingestDocument({ title, content, tags = [], collectionId = '', autoVectorize = true }) {
      const id = this.addDoc({ title, content, tags, collectionId })
      if (autoVectorize) {
        await this.reembedDoc(id)
      }
      return id
    },
    async reembedDoc(docId) {
      const doc = this.docs.find((d) => d.id === docId)
      if (!doc) throw new Error('文档不存在')
      const chunks = chunkText(doc.content || '')
      const embeddings = []
      for (const chunk of chunks) {
        const vector = await embedChunk(chunk, this.embeddingConfig)
        embeddings.push({ id: genId('chunk'), docId, text: chunk, embedding: vector, createdAt: new Date().toISOString() })
      }
      this.chunks = this.chunks.filter((c) => c.docId !== docId).concat(embeddings)
      saveChunks(this.chunks)
      return embeddings.length
    },
    async retrieveContext({ queryText, selectedIds = [], topK, keywordWeight }) {
      const ids = Array.isArray(selectedIds) && selectedIds.length ? new Set(selectedIds) : null
      const availableChunks = ids ? this.chunks.filter((c) => ids.has(c.docId)) : this.chunks
      if (!availableChunks.length) return []

      const configTopK = Number.isFinite(topK) ? topK : this.retrievalConfig?.topK || 5
      const weight = Number.isFinite(keywordWeight) ? keywordWeight : this.retrievalConfig?.keywordWeight ?? 0.5
      const boundedTopK = Math.max(1, Math.min(10, Math.floor(configTopK)))
      const boundedWeight = Math.min(1, Math.max(0, weight))

      const queryEmbedding = await embedChunk(queryText || '', this.embeddingConfig)
      const useEmbedding = Array.isArray(queryEmbedding) && queryEmbedding.length

      const keywordScores = availableChunks.map((c) => ({
        id: c.id,
        score: keywordSimilarity(queryText || '', c.text || '')
      }))

      const combined = availableChunks.map((c) => {
        const kw = keywordScores.find((k) => k.id === c.id)?.score || 0
        const vs = useEmbedding ? cosineSimilarity(queryEmbedding, c.embedding) : 0
        const score = boundedWeight * kw + (1 - boundedWeight) * vs
        return { chunk: c, score }
      })

      const scored = combined
        .filter((item) => Number.isFinite(item.score))
        .sort((a, b) => b.score - a.score)
        .slice(0, boundedTopK)
        .map(({ chunk, score }) => {
          const doc = this.docMap.get(chunk.docId)
          return {
            id: chunk.id,
            docId: chunk.docId,
            title: doc?.title || '未命名文档',
            content: chunk.text,
            score
          }
        })

      // 若向量不可用，回退为文档正文摘要
      if (!scored.length) {
        const docs = ids ? this.docs.filter((d) => ids.has(d.id)) : this.docs
        return docs.slice(0, boundedTopK).map((d) => ({ id: d.id, docId: d.id, title: d.title, content: d.excerpt || d.content }))
      }
      return scored
    }
  }
})

// helpers
function loadChunks() {
  try {
    const raw = localStorage.getItem(KNOWLEDGE_CHUNKS_KEY)
    if (!raw) return []
    const arr = JSON.parse(raw)
    if (Array.isArray(arr)) return arr
    return []
  } catch (e) {
    return []
  }
}

function saveChunks(chunks) {
  localStorage.setItem(KNOWLEDGE_CHUNKS_KEY, JSON.stringify(chunks || []))
}

function loadEmbeddingConfig() {
  try {
    const raw = localStorage.getItem(EMBEDDING_CONFIG_KEY)
    if (!raw) return { provider: 'modelscope', model: 'text-embedding-v3', apiKey: '', baseUrl: '' }
    const parsed = JSON.parse(raw)
    return {
      provider: 'modelscope',
      model: parsed?.model || 'text-embedding-v3',
      apiKey: parsed?.apiKey || '',
      baseUrl: parsed?.baseUrl || ''
    }
  } catch (e) {
    return { provider: 'modelscope', model: 'text-embedding-v3', apiKey: '', baseUrl: '' }
  }
}

function saveEmbeddingConfig(config) {
  localStorage.setItem(EMBEDDING_CONFIG_KEY, JSON.stringify(config || {}))
}

function loadRetrievalConfig() {
  try {
    const raw = localStorage.getItem(RETRIEVAL_CONFIG_KEY)
    if (!raw) return { topK: 5, keywordWeight: 0.5 }
    const parsed = JSON.parse(raw)
    return {
      topK: Number.isFinite(parsed?.topK) ? parsed.topK : 5,
      keywordWeight: Number.isFinite(parsed?.keywordWeight) ? parsed.keywordWeight : 0.5
    }
  } catch (e) {
    return { topK: 5, keywordWeight: 0.5 }
  }
}

function saveRetrievalConfig(config) {
  localStorage.setItem(RETRIEVAL_CONFIG_KEY, JSON.stringify(config || {}))
}

function chunkText(text, maxLen = 800) {
  const t = (text || '').trim()
  if (!t) return []
  const parts = []
  let buffer = ''
  const sentences = t.split(/(?<=[。！？!?.\n])/)
  for (const s of sentences) {
    if ((buffer + s).length > maxLen && buffer) {
      parts.push(buffer)
      buffer = s
    } else {
      buffer += s
    }
  }
  if (buffer) parts.push(buffer)
  return parts
}

async function embedChunk(text, config) {
  const content = (text || '').trim()
  if (!content) return []
  const { embedWithModelScope } = await import('../api/embeddings')
  return embedWithModelScope({
    apiKey: config?.apiKey || '',
    model: config?.model || 'text-embedding-v3',
    baseUrl: config?.baseUrl || '',
    input: content
  })
}

function cosineSimilarity(a = [], b = []) {
  if (!a.length || !b.length || a.length !== b.length) return 0
  let dot = 0
  let na = 0
  let nb = 0
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i]
    na += a[i] * a[i]
    nb += b[i] * b[i]
  }
  if (!na || !nb) return 0
  return dot / (Math.sqrt(na) * Math.sqrt(nb))
}

function keywordSimilarity(query, text) {
  const q = (query || '').toLowerCase().split(/[\s,，。；;]+/).filter(Boolean)
  const t = (text || '').toLowerCase()
  if (!q.length || !t) return 0
  let hit = 0
  q.forEach((word) => {
    if (t.includes(word)) hit += 1
  })
  return hit / q.length
}
