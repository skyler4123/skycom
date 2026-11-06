import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_Questions_IndexController extends Companies_LayoutController {
  // Question Bank index.
  // Depends on BE: Companies::QuestionsController#index
  // Endpoints: GET /companies/:id/questions.json?q&category_id&question_type
  // Docs: docs/EXAMS.md

  /** @type {Question[]} */
  questions = []

  async connect() {
    super.connect()

    try {
      const response = await fetchJson()
      this.questions = response.questions || []
      this.pagination = response.pagination || {}

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${translate("Failed to load questions")}${detail ? ": " + detail : ""}` })
    }
  }

  questionCategories() {
    return currentCategories().filter(category => category.resource_name === "questions")
  }

  typeLabel(type) {
    const entry = (ENUMS?.question?.question_types || []).find(item => item.value === type)
    return entry ? translate(entry.name) : type
  }

  contentHTML() {
    const companyId = currentCompany()?.id
    const urlParams = new URLSearchParams(window.location.search)
    const categoryValue = urlParams.get("category_id") || ""
    const typeValue = urlParams.get("question_type") || ""

    const categories = this.questionCategories().map(category => ({ value: category.id, name: category.name }))
    const types = (ENUMS?.question?.question_types || []).map(type => ({ value: type.value, name: translate(type.name) }))

    return `
      <div class="p-4 overflow-y-auto">
        <div class="rounded-xl border border-line bg-card p-4">
          <div class="mb-6 flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
            <form method="get" action="${pathname()}" class="flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-end">
              <div class="flex flex-col gap-1">
                <label class="ml-1 text-[10px] font-bold uppercase text-muted-foreground">${translate("Search")}</label>
                <input type="search" name="q" value="${escapeHtml(urlParams.get("q") || "")}"
                  placeholder="${translate("Search questions...")}"
                  class="h-[38px] rounded-lg border border-line bg-card px-3 text-sm text-foreground placeholder:text-muted-foreground">
              </div>
              <div class="flex flex-col gap-1">
                <label class="ml-1 text-[10px] font-bold uppercase text-muted-foreground">${translate("Category")}</label>
                <select name="category_id" class="h-[38px] rounded-lg border border-line bg-card px-3 text-sm text-foreground">
                  ${selectOptionsHTML(categories, categoryValue, translate("All Categories"))}
                </select>
              </div>
              <div class="flex flex-col gap-1">
                <label class="ml-1 text-[10px] font-bold uppercase text-muted-foreground">${translate("Question Type")}</label>
                <select name="question_type" class="h-[38px] rounded-lg border border-line bg-card px-3 text-sm text-foreground">
                  ${selectOptionsHTML(types, typeValue, translate("All Types"))}
                </select>
              </div>
              <button type="submit"
                class="flex h-[38px] items-center gap-2 rounded-lg bg-primary px-5 text-sm font-medium text-primary-foreground hover:bg-primary/90">
                <span class="material-symbols-outlined text-[18px]!">search</span>${translate("Search")}
              </button>
            </form>

            <a href="${Helpers.new_company_question_path(companyId)}"
              class="flex items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90">
              <span class="material-symbols-outlined text-[20px]">add</span>${translate("Add Question")}
            </a>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full border-collapse text-left">
              <thead>
                <tr class="border-b border-line bg-muted text-sm text-muted-foreground">
                  <th class="px-4 py-3 font-medium">${translate("Question")}</th>
                  <th class="px-4 py-3 font-medium">${translate("Category")}</th>
                  <th class="px-4 py-3 font-medium">${translate("Type")}</th>
                  <th class="px-4 py-3 text-center font-medium">${translate("Points")}</th>
                  <th class="px-4 py-3 text-center font-medium">${translate("Options")}</th>
                  <th class="px-4 py-3 text-right font-medium">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody>
                ${this.questions.map(question => `
                  <tr class="border-b border-line/70 hover:bg-muted/50">
                    <td class="px-4 py-3">
                      <a href="${Helpers.company_question_path(companyId, question.id)}"
                        class="font-medium text-foreground hover:text-primary">${escapeHtml(question.name)}</a>
                      <p class="max-w-md truncate text-xs text-muted-foreground">${escapeHtml(question.description || "")}</p>
                    </td>
                    <td class="px-4 py-3 text-sm text-muted-foreground">${escapeHtml(question.category?.name || "—")}</td>
                    <td class="px-4 py-3">
                      <span class="inline-flex rounded-full bg-muted px-2.5 py-0.5 text-xs font-medium text-foreground">
                        ${this.typeLabel(question.question_type)}
                      </span>
                    </td>
                    <td class="px-4 py-3 text-center text-sm text-foreground">${question.points}</td>
                    <td class="px-4 py-3 text-center text-sm text-foreground">${question.options_count || 0}</td>
                    <td class="px-4 py-3 text-right">
                      <a href="${Helpers.edit_company_question_path(companyId, question.id)}"
                        class="inline-flex items-center justify-center rounded-lg p-2 text-muted-foreground hover:bg-primary/10 hover:text-primary">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </a>
                    </td>
                  </tr>
                `).join("")}
              </tbody>
            </table>
          </div>

          ${this.questions.length === 0 ? `
            <div class="flex flex-col items-center justify-center py-12 text-muted-foreground">
              <span class="material-symbols-outlined mb-2 text-4xl">help</span>
              <p>${translate("No questions found")}</p>
            </div>
          ` : ""}

          <div class="flex justify-center pt-6">${pagination(this.pagination)}</div>
        </div>
      </div>
    `
  }
}
