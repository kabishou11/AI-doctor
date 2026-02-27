import * as pdfjsLib from 'pdfjs-dist'
import mammoth from 'mammoth'
import { parse } from 'papaparse'

pdfjsLib.GlobalWorkerOptions.workerSrc = typeof window !== 'undefined' ? new URL('pdfjs-dist/build/pdf.worker.min.js', import.meta.url).toString() : ''

async function parsePDF(file) {
  const arrayBuffer = await file.arrayBuffer()
  const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise
  let text = ''
  for (let i = 1; i <= pdf.numPages; i++) {
    const page = await pdf.getPage(i)
    const content = await page.getTextContent()
    const strings = content.items.map((item) => item.str || '').join(' ')
    text += strings + '\n'
  }
  return text
}

async function parseDocx(file) {
  const arrayBuffer = await file.arrayBuffer()
  const result = await mammoth.extractRawText({ arrayBuffer })
  return result.value || ''
}

async function parseText(file) {
  const text = await file.text()
  return text
}

async function parseCsv(file) {
  const text = await file.text()
  const parsed = parse(text, { skipEmptyLines: true })
  if (!parsed?.data || !Array.isArray(parsed.data)) return text
  return parsed.data.map((row) => (Array.isArray(row) ? row.join(' | ') : String(row || ''))).join('\n')
}

export async function parseFileToText(file) {
  if (!file) throw new Error('未选择文件')
  const ext = (file.name.split('.').pop() || '').toLowerCase()
  if (ext === 'pdf') return parsePDF(file)
  if (ext === 'docx') return parseDocx(file)
  if (ext === 'csv') return parseCsv(file)
  return parseText(file)
}
