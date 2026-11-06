import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Exams_FormController extends Companies_LayoutController {
  // Shared exam form behavior for new/edit pages.
  // Depends on BE: Companies::ExamsController#new/#edit/#create/#update
  // Endpoints: GET <pathname>.json, POST /companies/:id/exams,
  //            PATCH /companies/:id/exams/:id
  // Docs: docs/EXAMS.md

  /** @type {Exam | null} */
  exam = null
  /** @type {Question[]} */
  questions = []
  /** @type {Array<{id: string, name: string}>} */
  categories = []
  loaded = false

  async connect() {
    super.connect()

    try {
      await this.loadForm()
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load exam")}${detail ? ": " + detail : ""}` })
    }
  }

  async loadForm() {
    const response = await fetchJson(`${pathname()}.json`)
    this.exam = response.exam || null
    this.questions = response.questions || []
    this.categories = response.categories || []
    this.loaded = true

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  isEditing() {
    return Boolean(this.exam?.id)
  }

  statusLabel(status) {
    const entry = (ENUMS?.exam?.workflow_statuses || []).find(item => item.value === status)
    return entry ? translate(entry.name) : status
  }

  questionPickerHTML() {
    return `
      <div data-controller="companies--exams--question-picker"
        data-companies--exams--question-picker-questions-value="${escapeHtml(JSON.stringify(this.questions))}"
        data-companies--exams--question-picker-selected-value="${escapeHtml(JSON.stringify(this.exam?.question_ids || []))}"></div>
    `
  }

  contentHTML() {
    if (!this.loaded) return `<div class="p-8 text-center text-muted-foreground">${translate("Loading...")}</div>`

    const companyId = currentCompany()?.id
    const exam = this.exam
    const shuffleChecked = exam ? exam.shuffle_options !== false : true
    const submitLabel = this.isEditing() ? translate("Save Changes") : translate("Create Exam")

    const fields = `
      <div class="space-y-6">
        <div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <div class="mb-1 flex items-center gap-2">
              <h2 class="text-xl font-bold text-foreground">${this.isEditing() ? translate("Edit Exam") : translate("New Exam")}</h2>
              ${this.isEditing() ? `<span class="rounded-full bg-muted px-2.5 py-0.5 text-xs font-medium text-foreground">${this.statusLabel(exam.workflow_status)}</span>` : ""}
            </div>
            <p class="text-sm text-muted-foreground">${translate("Compose an exam from the question bank, then publish it before assigning employees.")}</p>
          </div>
          <a href="${Helpers.company_exams_path(companyId)}"
            class="inline-flex items-center gap-1.5 rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-muted hover:text-foreground">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>${translate("Back")}
          </a>
        </div>

        ${this.isEditing() && exam.workflow_status === "published"
          ? `<div class="rounded-lg border border-warning/40 bg-warning/10 p-3 text-sm text-warning">
               ${translate("This exam is published. Question changes affect future attempts only; existing attempts keep their snapshot.")}
             </div>`
          : ""
        }

        <div class="rounded-xl border border-line bg-card p-4">
          <h3 class="mb-4 text-sm font-bold uppercase tracking-wider text-muted-foreground">${translate("Exam Settings")}</h3>
          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div class="sm:col-span-2 space-y-1">
              <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Exam Name")}</label>
              <input type="text" name="exam[name]" value="${escapeHtml(exam?.name || "")}" required maxlength="255"
                class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="${translate("e.g. Annual safety exam")}">
            </div>

            <div class="sm:col-span-2 space-y-1">
              <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Description")}</label>
              <textarea name="exam[description]" rows="2"
                class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="${translate("Optional instructions for employees")}">${escapeHtml(exam?.description || "")}</textarea>
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Duration (minutes)")}</label>
              <input type="number" name="exam[duration_minutes]" min="1" step="1" value="${exam?.duration_minutes ?? ""}"
                class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="${translate("Blank = no time limit")}">
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Passing Score (%)")}</label>
              <input type="number" name="exam[passing_score]" min="0" max="100" step="0.01" value="${exam?.passing_score ?? 70}" required
                class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary">
            </div>

            <div class="space-y-1">
              <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Attempts Allowed")}</label>
              <input type="number" name="exam[max_attempts]" min="1" step="1" value="${exam?.max_attempts ?? ""}"
                class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="${translate("Blank = unlimited")}">
              <p class="text-xs text-muted-foreground">${translate("1 = single attempt. Blank = unlimited.")}</p>
            </div>

            <div class="flex items-center gap-3 pt-6">
              <input type="hidden" name="exam[shuffle_options]" value="false">
              <input type="checkbox" name="exam[shuffle_options]" value="true" ${shuffleChecked ? "checked" : ""}
                class="h-5 w-5 cursor-pointer rounded border-line text-primary">
              <span class="text-sm text-foreground">${translate("Shuffle choice order")}</span>
            </div>
          </div>
        </div>

        <div class="rounded-xl border border-line bg-card p-4">
          <div class="mb-4 flex items-center justify-between gap-3">
            <div>
              <h3 class="text-sm font-bold uppercase tracking-wider text-muted-foreground">${translate("Questions")}</h3>
              <p class="text-xs text-muted-foreground">${translate("Select questions from the bank and put them in order.")}</p>
            </div>
            <a href="${Helpers.company_questions_path(companyId)}" target="_blank" rel="noopener"
              class="inline-flex items-center gap-1 rounded-lg bg-muted px-3 py-1.5 text-xs font-bold text-foreground hover:bg-primary/10 hover:text-primary">
              <span class="material-symbols-outlined text-[16px]!">open_in_new</span>${translate("Question Bank")}
            </a>
          </div>
          ${this.questionPickerHTML()}
        </div>

        <div class="flex justify-end gap-3">
          <a href="${Helpers.company_exams_path(companyId)}"
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
        ? Helpers.company_exam_path(companyId, this.exam.id)
        : Helpers.company_exams_path(companyId),
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
      navigateThenToast(Helpers.company_exam_path(companyId, response.exam.id), {
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
