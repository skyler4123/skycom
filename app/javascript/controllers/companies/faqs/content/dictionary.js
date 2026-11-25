/**
 * Builds the page-scoped translation map for the FAQ content.
 *
 * Every content string is authored with `{ en, vi }`. The page controller
 * registers this map with `registerDictionary()` so the renderer can keep using
 * `translate()` while the FAQ corpus stays out of the global dictionary payload.
 */
export const buildFaqDictionary = (groups) => {
  const entries = {}

  const add = (value) => {
    if (!value?.en) return
    entries[value.en] = { vi: value.vi || value.en }
  }

  groups.forEach((group) => {
    add(group.title)

    group.questions.forEach((question) => {
      add(question.question)

      question.answer.forEach((block) => {
        if (block.text) add(block.text)

        const items = block.items || []
        items.forEach((item) => {
          add(item.text || item.label || item)
        })
      })
    })
  })

  return entries
}
