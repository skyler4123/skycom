// Quote-aware CSV header extraction for the Import pre-check. Returns the
// header names from the first logical row (a quoted field may contain commas,
// escaped "" pairs, or a newline). BOM stripped. Does not parse data rows.
export const parseCsvHeaderLine = (text) => {
  if (!text) return []

  const source = text.charCodeAt(0) === 0xfeff ? text.slice(1) : text
  const fields = []
  let current = ""
  let inQuotes = false

  for (let i = 0; i < source.length; i += 1) {
    const char = source[i]

    if (inQuotes) {
      if (char === '"') {
        if (source[i + 1] === '"') {
          current += '"'
          i += 1
        } else {
          inQuotes = false
        }
      } else {
        current += char
      }
    } else if (char === '"') {
      inQuotes = true
    } else if (char === ",") {
      fields.push(current)
      current = ""
    } else if (char === "\n" || char === "\r") {
      break
    } else {
      current += char
    }
  }

  fields.push(current)
  return fields.map((field) => field.trim())
}
