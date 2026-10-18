// Pure CSV chunk splitter for the Data Import upload flow. Rows are found
// with a quote-aware single pass (a quoted field may contain commas, escaped
// "" pairs, and newlines), so a chunk boundary can never land inside a row or
// a quoted field. Every chunk after the first repeats the header row (BOM
// stripped); chunk 0 keeps the source text byte-for-byte (BOM included). A
// single row larger than maxBytes still lands in its own chunk — never dropped.

const byteLength = (text) => new TextEncoder().encode(text).length

const stripBOM = (text) => (text.charCodeAt(0) === 0xfeff ? text.slice(1) : text)

// Splits source text into logical row strings, each keeping its own line
// ending (\n or \r\n) — except possibly the last row.
export const splitLogicalRows = (text) => {
  const rows = []
  let current = ""
  let inQuotes = false

  for (let i = 0; i < text.length; i += 1) {
    const char = text[i]
    current += char

    if (char === '"') {
      if (inQuotes && text[i + 1] === '"') {
        current += '"' // escaped quote inside a quoted field
        i += 1
      } else {
        inQuotes = !inQuotes
      }
    } else if (char === "\n" && !inQuotes) {
      rows.push(current)
      current = ""
    }
  }

  if (current !== "") rows.push(current)
  return rows
}

export const splitCsvChunks = (text, maxBytes) => {
  if (!text || !maxBytes || maxBytes <= 0) return []

  const rows = splitLogicalRows(text)

  // Skip trailing blank lines (some exporters end with a stray newline).
  while (rows.length > 0 && rows[rows.length - 1].trim() === "") rows.pop()
  if (rows.length === 0) return []

  const header = stripBOM(rows[0])
  const chunks = []
  let current = rows[0] // chunk 0 keeps the original header row (BOM included)
  let headerOnly = true

  const push = () => {
    chunks.push({ index: chunks.length, text: current, bytes: byteLength(current) })
  }

  rows.slice(1).forEach((row) => {
    if (headerOnly || byteLength(current + row) <= maxBytes) {
      current += row
    } else {
      push()
      current = header + row // an oversized row starts its own chunk here
    }
    headerOnly = false
  })

  push()
  return chunks
}
