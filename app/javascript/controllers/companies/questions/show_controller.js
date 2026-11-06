import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Questions_ShowController extends Companies_LayoutController {
  // Question detail.
  // Depends on BE: Companies::QuestionsController#show + #destroy
  // Endpoints: GET /companies/:id/questions/:id.json,
  //            DELETE /companies/:id/questions/:id
  // Docs: docs/EXAMS.md

  /** @type {Question | null} */
  question = null
  usageCount = 0

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.question = response.question
      this.usageCount = response.usage_count || 0

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load question")}${detail ? ": " + detail : ""}` })
    }
  }

  typeLabel(type) {
    const entry = (ENUMS?.question?.question_types || []).find(item => item.value === type)
    return entry ? translate(entry.name) : type
  }

  async deleteQuestion() {
    const result = await Helpers.confirmAction({
      title: translate("Delete this question?"),
      text: translate("This cannot be undone."),
      confirmButtonText: translate("Delete"),
      cancelButtonText: translate("Cancel")
    })
    if (!result.isConfirmed) return

    try {
      await fetchJson(Helpers.company_question_path(currentCompany()?.id, this.question.id), { method: "DELETE" })
      navigateThenToast(Helpers.company_questions_path(currentCompany()?.id), {
        type: "success",
        message: translate("Question deleted successfully.")
      })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || error.message })
    }
  }

  optionsHTML() {
    if (this.question.question_type === "text") {
      return `
        <div class="rounded-xl border border-line bg-card p-4">
          <p class="mb-2 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Model Answer")}</p>
          <p class="whitespace-pre-wrap text-sm text-foreground">${escapeHtml(this.question.correct_text || "—")}</p>
        </div>
      `
    }

    return `
      <div class="space-y-2">
        ${(this.question.options || []).map((option, index) => `
          <div class="flex items-center gap-3 rounded-lg border ${option.correct ? "border-success/40 bg-success/10" : "border-line bg-card"} p-3">
            <span class="flex h-7 w-7 items-center justify-center rounded-full bg-muted text-xs font-bold text-foreground">
              ${String.fromCharCode(65 + index)}
            </span>
            <span class="flex-1 text-sm text-foreground">${escapeHtml(option.content)}</span>
            ${option.correct ? `<span class="text-xs font-bold text-success">${translate("Correct")}</span>` : ""}
          </div>
        `).join("")}
      </div>
    `
  }

  contentHTML() {
    const question = this.question
    if (!question) return `<div class="p-8 text-center text-muted-foreground">${translate("Question not found.")}</div>`

    const companyId = currentCompany()?.id

    return `
      <div class="p-4 overflow-y-auto">
        <div class="mx-auto max-w-4xl space-y-4">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <div class="mb-2 flex flex-wrap items-center gap-2">
                <span class="inline-flex rounded-full bg-muted px-2.5 py-0.5 text-xs font-medium text-foreground">${this.typeLabel(question.question_type)}</span>
                <span class="inline-flex rounded-full bg-primary/10 px-2.5 py-0.5 text-xs font-medium text-primary">${question.points} ${translate("points")}</span>
                <span class="text-xs text-muted-foreground">${translate("Used in")} ${this.usageCount} ${translate("exams")}</span>
              </div>
              <h2 class="text-xl font-bold text-foreground">${escapeHtml(question.name)}</h2>
              <p class="mt-1 text-sm text-muted-foreground">${escapeHtml(question.category?.name || "—")}</p>
            </div>
            <div class="flex items-center gap-2">
              <a href="${Helpers.company_questions_path(companyId)}"
                class="rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-muted">${translate("Back")}</a>
              <a href="${Helpers.edit_company_question_path(companyId, question.id)}"
                class="inline-flex items-center gap-1.5 rounded-lg bg-primary px-3 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">
                <span class="material-symbols-outlined text-[18px]!">edit</span>${translate("Edit")}
              </a>
              <button type="button" data-action="click->${this.identifier}#deleteQuestion"
                class="inline-flex items-center gap-1.5 rounded-lg border border-line px-3 py-2 text-sm font-medium text-danger hover:bg-danger/10">
                <span class="material-symbols-outlined text-[18px]!">delete</span>${translate("Delete")}
              </button>
            </div>
          </div>

          <div class="rounded-xl border border-line bg-card p-4">
            <p class="mb-3 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Question")}</p>
            <p class="text-sm text-foreground">${escapeHtml(question.name)}</p>
            ${question.description ? `<p class="mt-2 text-sm text-muted-foreground">${escapeHtml(question.description)}</p>` : ""}
          </div>

          <div class="rounded-xl border border-line bg-card p-4">
            <p class="mb-3 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Answer")}</p>
            ${this.optionsHTML()}
          </div>
        </div>
      </div>
    `
  }
}
