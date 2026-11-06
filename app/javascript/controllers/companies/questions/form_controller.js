import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Questions_FormController extends Companies_LayoutController {
  // Shared question form behavior for new/edit pages.
  // Depends on BE: Companies::QuestionsController#new/#edit/#create/#update
  // Endpoints: GET <pathname>.json, POST /companies/:id/questions,
  //            PATCH /companies/:id/questions/:id
  // Docs: docs/EXAMS.md

  /** @type {Question | null} */
  question = null
  /** @type {Array<{id: string, name: string, resource_name: string}>} */
  categories = []
  /** @type {Array<{id?: string, content: string, correct?: boolean}>} */
  options = []
  correctOptionIndex = 0
  loaded = false

  async connect() {
    super.connect()

    try {
      await this.loadForm()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load question")}${detail ? ": " + detail : ""}` })
    }
  }

  async loadForm() {
    const response = await fetchJson(`${pathname()}.json`)
    this.question = response.question || null
    this.categories = response.categories || []

    if (this.question?.options?.length) {
      this.options = this.question.options.map(option => ({ ...option }))
      this.correctOptionIndex = Math.max(0, this.options.findIndex(option => option.correct))
    } else {
      this.options = this.defaultOptionsFor(this.questionType())
    }

    this.loaded = true
    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  questionType() {
    return this.question?.question_type || "single_choice"
  }

  isEditing() {
    return Boolean(this.question?.id)
  }

  defaultOptionsFor(type) {
    if (type === "true_false") {
      return [
        { content: "True", correct: true },
        { content: "False", correct: false }
      ]
    }
    if (type === "text") return []

    return [
      { content: "", correct: true },
      { content: "", correct: false }
    ]
  }

  onTypeChange(event) {
    const type = event.target.value
    this.question = { ...(this.question || {}), question_type: type }
    this.options = this.defaultOptionsFor(type)
    this.correctOptionIndex = 0
    this.renderContent()
  }

  addOption() {
    this.options.push({ content: "" })
    this.renderContent()
  }

  removeOption(event) {
    const index = Number(event.currentTarget.dataset.index)
    if (this.options.length <= 2) return

    this.options.splice(index, 1)
    if (this.correctOptionIndex >= this.options.length) this.correctOptionIndex = 0
    this.renderContent()
  }

  setCorrect(event) {
    this.correctOptionIndex = Number(event.currentTarget.value)
    this.contentTarget.querySelectorAll("[data-question-correct-radio]").forEach((radio) => {
      radio.checked = Number(radio.value) === this.correctOptionIndex
    })
  }

  categoryOptionsHTML() {
    const selected = this.question?.category_id
    return this.categories.map(category => `
      <option value="${category.id}" ${String(category.id) === String(selected) ? "selected" : ""}>
        ${escapeHtml(category.name)}
      </option>
    `).join("")
  }

  optionRowsHTML(type) {
    if (type === "text") return ""

    return this.options.map((option, index) => `
      <div class="flex items-center gap-3 rounded-lg border border-line bg-card p-3">
        <input type="hidden" name="question[options][${index}][id]" value="${option.id || ""}">
        ${type === "true_false"
          ? `<input type="hidden" name="question[options][${index}][content]" value="${escapeHtml(option.content)}">
             <span class="min-w-20 text-sm font-medium text-foreground">${escapeHtml(option.content)}</span>`
          : `<input type="text" name="question[options][${index}][content]" value="${escapeHtml(option.content || "")}"
               placeholder="${translate("Option")} ${index + 1}" required
               class="flex-1 rounded-lg border border-line bg-background px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary">`
        }
        <label class="flex items-center gap-2 text-xs font-medium text-muted-foreground">
          <input type="radio" name="question[correct_option_index]" value="${index}"
            data-question-correct-radio
            data-action="change->${this.identifier}#setCorrect"
            ${index === this.correctOptionIndex ? "checked" : ""}
            class="h-4 w-4 cursor-pointer">
          ${translate("Correct")}
        </label>
        ${type === "single_choice" && this.options.length > 2
          ? `<button type="button" data-action="click->${this.identifier}#removeOption" data-index="${index}"
               class="rounded-lg p-2 text-muted-foreground hover:bg-danger/10 hover:text-danger">
               <span class="material-symbols-outlined text-[18px]!">delete</span>
             </button>`
          : ""
        }
      </div>
    `).join("")
  }

  answerSectionHTML(type) {
    if (type === "text") {
      return `
        <div class="space-y-2">
          <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Model Answer")}</label>
          <textarea name="question[correct_text]" rows="4"
            class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
            placeholder="${translate("Reference answer for manual grading")}">${escapeHtml(this.question?.correct_text || "")}</textarea>
          <p class="text-xs text-muted-foreground">${translate("Text answers are graded manually by a manager.")}</p>
        </div>
      `
    }

    return `
      <div class="space-y-3">
        <div class="flex items-center justify-between gap-3">
          <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Options")}</label>
          ${type === "single_choice"
            ? `<button type="button" data-action="click->${this.identifier}#addOption"
                 class="inline-flex items-center gap-1 rounded-lg bg-muted px-3 py-1.5 text-xs font-bold text-foreground hover:bg-primary/10 hover:text-primary">
                 <span class="material-symbols-outlined text-[16px]!">add</span>${translate("Add Option")}
               </button>`
            : ""
          }
        </div>
        <div class="space-y-2">${this.optionRowsHTML(type)}</div>
      </div>
    `
  }

  contentHTML() {
    if (!this.loaded) return `<div class="p-8 text-center text-muted-foreground">${translate("Loading...")}</div>`

    const type = this.questionType()
    const companyId = currentCompany()?.id
    const submitLabel = this.isEditing() ? translate("Save Changes") : translate("Create Question")

    const fields = `
      <div class="space-y-6">
        <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 class="text-xl font-bold text-foreground">${this.isEditing() ? translate("Edit Question") : translate("New Question")}</h2>
            <p class="text-sm text-muted-foreground">${translate("Questions are reused across exams in this company.")}</p>
          </div>
          <a href="${Helpers.company_questions_path(companyId)}"
            class="inline-flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>${translate("Back")}
          </a>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div class="sm:col-span-2 space-y-1">
            <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Question")}</label>
            <input type="text" name="question[name]" value="${escapeHtml(this.question?.name || "")}" required maxlength="255"
              class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
              placeholder="${translate("Write the question prompt")}">
          </div>

          <div class="sm:col-span-2 space-y-1">
            <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Description")}</label>
            <textarea name="question[description]" rows="2"
              class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
              placeholder="${translate("Optional context")}">${escapeHtml(this.question?.description || "")}</textarea>
          </div>

          <div class="space-y-1">
            <div class="flex items-center justify-between">
              <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Category")}</label>
              ${newCategoryLink(currentCompany().id, "questions")}
            </div>
            <select name="question[category_id]" required
              class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary">
              ${this.categoryOptionsHTML()}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Question Type")}</label>
            <select name="question[question_type]" data-action="change->${this.identifier}#onTypeChange"
              class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary">
              ${selectOptionsHTML(
                (ENUMS?.question?.question_types || []).map(type => ({ value: type.value, name: translate(type.name) })),
                type
              )}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Points")}</label>
            <input type="number" name="question[points]" min="1" step="1" value="${this.question?.points || 1}" required
              class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary">
          </div>
        </div>

        <div class="rounded-xl border border-line bg-muted/30 p-4">
          ${this.answerSectionHTML(type)}
        </div>

        <div class="flex justify-end gap-3">
          <a href="${Helpers.company_questions_path(companyId)}"
            class="rounded-lg px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted">${translate("Cancel")}</a>
          <button type="submit"
            class="rounded-lg bg-primary px-5 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90">
            ${submitLabel}
          </button>
        </div>
      </div>
    `

    return form({
      action: this.isEditing()
        ? Helpers.company_question_path(companyId, this.question.id)
        : Helpers.company_questions_path(companyId),
      method: this.isEditing() ? "PATCH" : "POST",
      attributes: `class="p-4" data-action="submit->${this.identifier}#handleSubmit"`,
      html: fields
    })
  }

  async handleSubmit(event) {
    event.preventDefault()

    try {
      const response = await fetchJson(event.target.action, {
        method: event.target.method.toUpperCase(),
        body: new FormData(event.target)
      })
      const companyId = currentCompany()?.id
      navigateThenToast(Helpers.company_question_path(companyId, response.question.id), {
        type: "success",
        message: response.message
      })
    } catch (error) {
      toast({
        type: "error",
        message: error.errors?.join(", ") || error.message
      })
    }
  }
}
