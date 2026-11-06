import { Controller } from "@hotwired/stimulus"

export default class Companies_Exams_QuestionPickerController extends Controller {
  // Question selection + ordering for the exam form.
  // Depends on BE: Companies::ExamsController#new/#edit reference data.
  // Endpoints: none (data comes from the parent form JSON).
  // Docs: docs/EXAMS.md

  static values = {
    questions: Array,
    selected: Array
  }

  selectedIds = []
  query = ""
  categoryId = ""
  type = ""

  connect() {
    this.selectedIds = [ ...(this.selectedValue || []) ]
    this.render()
  }

  questions() {
    return this.questionsValue || []
  }

  selectedQuestions() {
    return this.selectedIds
      .map(id => this.questions().find(question => String(question.id) === String(id)))
      .filter(Boolean)
  }

  availableQuestions() {
    const query = this.query.trim().toLowerCase()
    const selected = new Set(this.selectedIds.map(String))

    return this.questions().filter(question => {
      if (selected.has(String(question.id))) return false
      if (this.categoryId && String(question.category?.id) !== String(this.categoryId)) return false
      if (this.type && question.question_type !== this.type) return false
      if (query && !`${question.name} ${question.category?.name || ""}`.toLowerCase().includes(query)) return false
      return true
    })
  }

  categories() {
    return this.questions()
      .map(question => question.category)
      .filter(Boolean)
      .reduce((result, category) => {
        if (!result.some(entry => String(entry.id) === String(category.id))) result.push(category)
        return result
      }, [])
  }

  typeLabel(type) {
    const entry = (ENUMS?.question?.question_types || []).find(item => item.value === type)
    return entry ? translate(entry.name) : type
  }

  onSearch(event) {
    this.query = event.target.value
    this.renderAvailable()
  }

  onCategoryChange(event) {
    this.categoryId = event.target.value
    this.renderAvailable()
  }

  onTypeChange(event) {
    this.type = event.target.value
    this.renderAvailable()
  }

  toggleQuestion(event) {
    const id = event.currentTarget.dataset.questionId
    if (event.currentTarget.checked) {
      if (!this.selectedIds.some(selected => String(selected) === String(id))) this.selectedIds.push(id)
    } else {
      this.selectedIds = this.selectedIds.filter(selected => String(selected) !== String(id))
    }
    this.render()
  }

  removeQuestion(event) {
    const id = event.currentTarget.dataset.questionId
    this.selectedIds = this.selectedIds.filter(selected => String(selected) !== String(id))
    this.render()
  }

  moveUp(event) {
    const index = Number(event.currentTarget.dataset.index)
    if (index <= 0) return
    const [ item ] = this.selectedIds.splice(index, 1)
    this.selectedIds.splice(index - 1, 0, item)
    this.render()
  }

  moveDown(event) {
    const index = Number(event.currentTarget.dataset.index)
    if (index >= this.selectedIds.length - 1) return
    const [ item ] = this.selectedIds.splice(index, 1)
    this.selectedIds.splice(index + 1, 0, item)
    this.render()
  }

  render() {
    this.element.innerHTML = this.contentHTML()
  }

  renderAvailable() {
    const container = this.element.querySelector("[data-question-picker-available]")
    if (container) container.innerHTML = this.availableListHTML()
  }

  availableListHTML() {
    const questions = this.availableQuestions()

    if (questions.length === 0) {
      return `<p class="p-4 text-sm text-muted-foreground">${translate("No questions match these filters.")}</p>`
    }

    return questions.map(question => `
      <label class="flex cursor-pointer items-start gap-3 rounded-lg border border-line bg-card p-3 hover:bg-muted/50">
        <input type="checkbox" data-action="change->${this.identifier}#toggleQuestion"
          data-question-id="${question.id}" class="mt-1 h-4 w-4 rounded border-line text-primary">
        <span class="min-w-0 flex-1">
          <span class="block truncate text-sm font-medium text-foreground">${escapeHtml(question.name)}</span>
          <span class="mt-0.5 flex flex-wrap gap-2 text-xs text-muted-foreground">
            <span>${escapeHtml(question.category?.name || "—")}</span>
            <span>${this.typeLabel(question.question_type)}</span>
            <span>${question.points} ${translate("points")}</span>
          </span>
        </span>
      </label>
    `).join("")
  }

  selectedListHTML() {
    const questions = this.selectedQuestions()

    if (questions.length === 0) {
      return `<p class="p-4 text-sm text-muted-foreground">${translate("No questions selected yet.")}</p>`
    }

    return questions.map((question, index) => `
      <div class="flex items-center gap-2 rounded-lg border border-line bg-card p-3">
        <span class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-bold text-primary">${index + 1}</span>
        <span class="min-w-0 flex-1">
          <span class="block truncate text-sm font-medium text-foreground">${escapeHtml(question.name)}</span>
          <span class="text-xs text-muted-foreground">${this.typeLabel(question.question_type)} · ${question.points} ${translate("points")}</span>
        </span>
        <button type="button" data-action="click->${this.identifier}#moveUp" data-index="${index}" ${index === 0 ? "disabled" : ""}
          class="rounded-lg p-1.5 text-muted-foreground hover:bg-muted disabled:cursor-not-allowed disabled:opacity-30">
          <span class="material-symbols-outlined text-[18px]!">arrow_upward</span>
        </button>
        <button type="button" data-action="click->${this.identifier}#moveDown" data-index="${index}" ${index === questions.length - 1 ? "disabled" : ""}
          class="rounded-lg p-1.5 text-muted-foreground hover:bg-muted disabled:cursor-not-allowed disabled:opacity-30">
          <span class="material-symbols-outlined text-[18px]!">arrow_downward</span>
        </button>
        <button type="button" data-action="click->${this.identifier}#removeQuestion" data-question-id="${question.id}"
          class="rounded-lg p-1.5 text-muted-foreground hover:bg-danger/10 hover:text-danger">
          <span class="material-symbols-outlined text-[18px]!">close</span>
        </button>
        <input type="hidden" name="exam[question_ids][]" value="${question.id}">
      </div>
    `).join("")
  }

  contentHTML() {
    const categories = this.categories().map(category => ({ value: category.id, name: category.name }))
    const types = (ENUMS?.question?.question_types || []).map(type => ({ value: type.value, name: translate(type.name) }))

    return `
      <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div class="space-y-3">
          <div class="grid grid-cols-1 gap-2 sm:grid-cols-2">
            <input type="search" value="${escapeHtml(this.query)}" placeholder="${translate("Search questions...")}" data-action="input->${this.identifier}#onSearch"
              class="rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground placeholder:text-muted-foreground">
            <select data-action="change->${this.identifier}#onCategoryChange"
              class="rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground">
              ${selectOptionsHTML(categories, this.categoryId, translate("All Categories"))}
            </select>
            <select data-action="change->${this.identifier}#onTypeChange"
              class="rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground">
              ${selectOptionsHTML(types, this.type, translate("All Types"))}
            </select>
          </div>
          <div class="max-h-80 space-y-2 overflow-y-auto" data-question-picker-available>
            ${this.availableListHTML()}
          </div>
        </div>

        <div class="space-y-2">
          <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
            ${translate("Selected Questions")} (${this.selectedIds.length})
          </p>
          <div class="max-h-80 space-y-2 overflow-y-auto">
            ${this.selectedListHTML()}
          </div>
        </div>
      </div>
    `
  }
}
