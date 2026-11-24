import Companies_LayoutController from "controllers/companies/layout_controller"
import { registerDictionary } from "controllers/helpers/dictionary"

export default class Companies_Faqs_ShowController extends Companies_LayoutController {
  /** @type {Array} */
  groups = []
  /** @type {Array} */
  searchIndex = []
  /** @type {Map<string, object>} */
  searchIndexBySlug = new Map()
  /** @type {Set<string>} */
  openSlugs = new Set()
  query = ""
  activeGroup = "all"
  loadError = false

  async connect() {
    super.connect()

    this.onHashChange = this.openFromHash.bind(this)
    window.addEventListener("hashchange", this.onHashChange)

    try {
      const { FAQ_GROUPS, FAQ_DICTIONARY } = await import("controllers/companies/faqs/content")
      registerDictionary(FAQ_DICTIONARY)
      this.groups = FAQ_GROUPS
      this.buildSearchIndex()
    } catch (error) {
      this.loadError = true
      console.error("[FAQ] content load failed", error)
    }

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  disconnect() {
    window.removeEventListener("hashchange", this.onHashChange)
    super.disconnect?.()
  }

  renderContent() {
    super.renderContent()

    if (!this.loadError) {
      this.openFromHash()
    }
  }

  contentHTML() {
    if (this.loadError) {
      return this.errorHTML()
    }

    const totalGroups = this.groups.length
    const totalQuestions = this.totalQuestions()
    const visibleGroups = this.filteredGroups()
    const shownQuestions = this.shownQuestions(visibleGroups)

    return `
      <div class="mx-auto w-full max-w-5xl px-4 py-8 md:px-8">
        ${this.headerHTML(totalGroups, totalQuestions, shownQuestions)}
        ${this.toolbarHTML()}
        <div data-faq-results class="mt-6 space-y-4">
          ${this.groupsHTML(visibleGroups)}
        </div>
        ${this.footerHTML()}
      </div>
    `
  }

  headerHTML(totalGroups, totalQuestions, shownQuestions) {
    return `
      <div class="rounded-xl border border-line bg-card p-5 md:p-6">
        <div class="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
          <div class="min-w-0">
            <p class="text-xs font-semibold uppercase tracking-wider text-primary">${translate("System")}</p>
            <h1 class="mt-1 text-2xl font-bold text-foreground md:text-3xl">${translate("Frequently asked questions")}</h1>
            <p class="mt-2 max-w-2xl text-sm leading-relaxed text-muted-foreground">${translate("Answers to common questions about using Skycom.")}</p>
            <p class="mt-3 text-xs text-muted-foreground">
              ${totalGroups} ${translate("groups")} · ${totalQuestions} ${translate("questions")}
            </p>
          </div>

          <div class="flex w-full flex-col gap-2 md:w-80">
            <label class="relative block">
              <span class="material-symbols-outlined pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[18px]! text-muted-foreground">search</span>
              <input
                id="faq-search"
                data-faq-search
                type="search"
                autocomplete="off"
                value="${Helpers.escapeHtml(this.query)}"
                placeholder="${translate("Search questions and answers")}"
                aria-label="${translate("Search questions and answers")}"
                data-action="input->${this.identifier}#onSearch"
                class="w-full rounded-lg border border-line bg-background py-2.5 pl-10 pr-3 text-sm text-foreground placeholder:text-muted-foreground focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary"
              />
            </label>
            <div class="flex items-center justify-between gap-2">
              <p data-faq-count aria-live="polite" class="text-xs text-muted-foreground">${this.countText(shownQuestions)}</p>
              <div class="flex items-center gap-1">
                <button type="button" data-action="click->${this.identifier}#expandAll"
                  class="rounded-lg px-2 py-1 text-xs font-medium text-muted-foreground hover:bg-muted hover:text-primary">
                  ${translate("Expand all")}
                </button>
                <button type="button" data-action="click->${this.identifier}#collapseAll"
                  class="rounded-lg px-2 py-1 text-xs font-medium text-muted-foreground hover:bg-muted hover:text-primary">
                  ${translate("Collapse all")}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    `
  }

  toolbarHTML() {
    const chips = [
      { key: "all", label: translate("All groups") },
      ...this.groups.map((group) => ({ key: group.key, label: this.text(group.title) }))
    ]

    return `
      <div class="mt-4 flex gap-2 overflow-x-auto pb-1" role="group" aria-label="${translate("All groups")}">
        ${chips.map((chip) => this.chipHTML(chip)).join("")}
      </div>
    `
  }

  chipHTML({ key, label }) {
    const active = key === this.activeGroup
    const stateClasses = active
      ? "border-primary bg-primary text-primary-foreground"
      : "border-line bg-card text-muted-foreground hover:bg-muted hover:text-foreground"

    return `
      <button type="button"
        data-faq-group-filter="${Helpers.escapeHtml(key)}"
        data-action="click->${this.identifier}#onGroup"
        class="shrink-0 rounded-full border px-3 py-1.5 text-xs font-medium transition-colors ${stateClasses}">
        ${Helpers.escapeHtml(label)}
      </button>
    `
  }

  groupsHTML(groups) {
    if (groups.length === 0) {
      return this.emptyHTML()
    }

    return groups.map((group) => this.groupHTML(group)).join("")
  }

  groupHTML(group) {
    return `
      <section data-faq-group="${Helpers.escapeHtml(group.key)}"
        class="overflow-hidden rounded-xl border border-line bg-card">
        <div class="flex items-center gap-3 border-b border-line bg-muted/40 px-4 py-3">
          <span class="material-symbols-outlined text-[20px]! text-primary">${Helpers.escapeHtml(group.icon)}</span>
          <h2 class="text-sm font-semibold text-foreground md:text-base">${Helpers.escapeHtml(this.text(group.title))}</h2>
          <span class="ml-auto shrink-0 text-xs text-muted-foreground">${group.questions.length} ${translate("questions")}</span>
        </div>
        <div class="divide-y divide-line">
          ${group.questions.map((question) => this.questionHTML(question)).join("")}
        </div>
      </section>
    `
  }

  questionHTML(question) {
    const slug = Helpers.escapeHtml(question.slug)
    const open = this.query.length > 0 || this.openSlugs.has(question.slug)

    return `
      <details id="faq-${slug}"
        data-faq-question="${slug}"
        data-faq-slug="${slug}"
        data-action="toggle->${this.identifier}#onToggle"
        class="group scroll-mt-24"
        ${open ? "open" : ""}>
        <summary class="flex cursor-pointer list-none items-start justify-between gap-3 px-4 py-4 hover:bg-muted/40 [&::-webkit-details-marker]:hidden">
          <span class="text-sm font-medium leading-relaxed text-foreground md:text-base">${Helpers.escapeHtml(this.text(question.question))}</span>
          <span class="material-symbols-outlined shrink-0 text-[20px]! text-muted-foreground transition-transform group-open:rotate-180">expand_more</span>
        </summary>
        <div class="border-t border-line px-4 py-4 text-sm leading-relaxed text-muted-foreground">
          ${this.badgeHTML(question)}
          ${this.answerHTML(question)}
          <div class="mt-4 flex justify-end">
            <button type="button"
              data-action="click->${this.identifier}#copyLink"
              data-faq-slug="${slug}"
              class="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-muted-foreground hover:bg-muted hover:text-primary"
              ${tooltip(translate("Copy link to this question"))}>
              <span class="material-symbols-outlined text-[16px]!">link</span>
              ${translate("Copy link")}
            </button>
          </div>
        </div>
      </details>
    `
  }

  badgeHTML(question) {
    if (question.status === "planned") {
      return `<span data-faq-badge="planned" class="mb-3 inline-flex items-center gap-1 rounded-full border border-warning/30 bg-warning/10 px-2 py-0.5 text-[11px] font-semibold text-warning">${translate("Not available yet")}</span>`
    }

    if (question.status === "manual") {
      return `<span data-faq-badge="manual" class="mb-3 inline-flex items-center gap-1 rounded-full border border-info/30 bg-info/10 px-2 py-0.5 text-[11px] font-semibold text-info">${translate("Manual step")}</span>`
    }

    return ""
  }

  answerHTML(question) {
    return question.answer.map((block) => this.blockHTML(block)).join("")
  }

  blockHTML(block) {
    switch (block.type) {
      case "p":
        return `<p class="mt-3 first:mt-0">${Helpers.escapeHtml(this.text(block.text))}</p>`
      case "steps":
        return `<ol class="mt-3 list-decimal space-y-1 pl-5">${this.itemsHTML(block.items)}</ol>`
      case "list":
        return `<ul class="mt-3 list-disc space-y-1 pl-5">${this.itemsHTML(block.items)}</ul>`
      case "note":
        return `<div class="mt-3 rounded-lg border border-info/30 bg-info/10 px-3 py-2 text-info">${Helpers.escapeHtml(this.text(block.text))}</div>`
      case "links":
        return `<div class="mt-4 flex flex-wrap gap-2">${this.linksHTML(block.items)}</div>`
      default:
        return ""
    }
  }

  itemsHTML(items) {
    return (items || [])
      .map((item) => `<li>${Helpers.escapeHtml(this.text(item))}</li>`)
      .join("")
  }

  linksHTML(items) {
    return (items || [])
      .map((item) => {
        const href = this.linkHref(item.path)
        if (!href) return ""

        return `
          <a href="${Helpers.escapeHtml(href)}"
            class="inline-flex items-center gap-1 rounded-lg border border-line bg-card px-3 py-1.5 text-xs font-medium text-primary hover:bg-primary/10">
            ${Helpers.escapeHtml(this.text(item.label))}
            <span class="material-symbols-outlined text-[14px]!">open_in_new</span>
          </a>
        `
      })
      .join("")
  }

  linkHref(helperName) {
    if (!helperName || typeof Helpers[helperName] !== "function") return null
    const companyId = currentCompany()?.id
    if (!companyId) return null
    return Helpers[helperName](companyId)
  }

  emptyHTML() {
    return `
      <div class="rounded-xl border border-line bg-card px-6 py-12 text-center">
        <span class="material-symbols-outlined text-[36px]! text-muted-foreground">search_off</span>
        <p class="mt-2 text-sm font-medium text-foreground">${translate("No questions match your search.")}</p>
        <button type="button" data-action="click->${this.identifier}#clearSearch"
          class="mt-4 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground hover:bg-primary/90">
          ${translate("Clear search")}
        </button>
      </div>
    `
  }

  footerHTML() {
    return `
      <div class="mt-8 flex flex-col gap-3 rounded-xl border border-line bg-card p-5 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 class="text-sm font-semibold text-foreground">${translate("Still need help?")}</h2>
          <p class="mt-1 text-sm text-muted-foreground">${translate("Open a Help Center ticket and include the page, what you expected, and what happened.")}</p>
          <p class="mt-2 text-xs text-muted-foreground">${translate("Last reviewed: November 2026")}</p>
        </div>
        <a href="${Helpers.escapeHtml(Helpers.company_company_tickets_path(currentCompany().id))}"
          class="inline-flex shrink-0 items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground hover:bg-primary/90">
          <span class="material-symbols-outlined text-[18px]!">support_agent</span>
          ${translate("Open a Help Center ticket")}
        </a>
      </div>
    `
  }

  errorHTML() {
    return `
      <div class="mx-auto w-full max-w-3xl px-4 py-12 md:px-8">
        <div class="rounded-xl border border-danger/30 bg-danger/10 p-6 text-center">
          <span class="material-symbols-outlined text-[36px]! text-danger">error</span>
          <h1 class="mt-2 text-lg font-semibold text-foreground">${translate("The FAQ could not be loaded.")}</h1>
          <button type="button" data-action="click->${this.identifier}#retryLoad"
            class="mt-4 rounded-lg bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground hover:bg-primary/90">
            ${translate("Reload page")}
          </button>
        </div>
      </div>
    `
  }

  onSearch(event) {
    this.query = event.target.value.trim()
    this.renderResults()
  }

  onGroup(event) {
    this.activeGroup = event.currentTarget.dataset.faqGroupFilter || "all"
    this.renderResults()
  }

  onToggle(event) {
    const slug = event.currentTarget.dataset.faqSlug
    if (!slug) return

    if (event.currentTarget.open) {
      this.openSlugs.add(slug)
    } else {
      this.openSlugs.delete(slug)
    }
  }

  expandAll() {
    this.contentTarget.querySelectorAll("details[data-faq-question]").forEach((element) => {
      element.open = true
      this.openSlugs.add(element.dataset.faqSlug)
    })
  }

  collapseAll() {
    this.contentTarget.querySelectorAll("details[data-faq-question]").forEach((element) => {
      element.open = false
      this.openSlugs.delete(element.dataset.faqSlug)
    })
  }

  clearSearch() {
    this.query = ""
    this.activeGroup = "all"

    const input = this.contentTarget.querySelector("[data-faq-search]")
    if (input) {
      input.value = ""
      input.focus()
    }

    this.renderResults()
  }

  retryLoad() {
    window.location.reload()
  }

  async copyLink(event) {
    const slug = event.currentTarget.dataset.faqSlug
    if (!slug) return

    const url = `${window.location.origin}${window.location.pathname}#faq-${slug}`

    try {
      await navigator.clipboard.writeText(url)
      toast({ type: "success", message: translate("Link copied") })
    } catch (error) {
      toast({ type: "error", message: translate("Could not copy the link.") })
    }
  }

  openFromHash() {
    if (this.loadError || this.groups.length === 0) return

    const rawHash = window.location.hash.replace(/^#/, "")
    if (!rawHash.startsWith("faq-")) return

    const slug = decodeURIComponent(rawHash.slice(4))
    const entry = this.searchIndexBySlug.get(slug)
    if (!entry) return

    this.query = ""
    this.activeGroup = "all"
    this.openSlugs.add(slug)

    const input = this.contentTarget?.querySelector("[data-faq-search]")
    if (input) input.value = ""

    this.renderResults()

    const element = this.contentTarget?.querySelector(`[data-faq-question="${slug}"]`)
    if (!element) return

    element.open = true
    element.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  renderResults() {
    if (!this.hasContentTarget || this.loadError) return

    const groups = this.filteredGroups()
    const shownQuestions = this.shownQuestions(groups)
    const results = this.contentTarget.querySelector("[data-faq-results]")
    const count = this.contentTarget.querySelector("[data-faq-count]")

    if (results) results.innerHTML = this.groupsHTML(groups)
    if (count) count.textContent = this.countText(shownQuestions)

    this.updateChips()
  }

  updateChips() {
    this.contentTarget.querySelectorAll("[data-faq-group-filter]").forEach((chip) => {
      const active = chip.dataset.faqGroupFilter === this.activeGroup

      chip.classList.toggle("border-primary", active)
      chip.classList.toggle("bg-primary", active)
      chip.classList.toggle("text-primary-foreground", active)
      chip.classList.toggle("border-line", !active)
      chip.classList.toggle("bg-card", !active)
      chip.classList.toggle("text-muted-foreground", !active)
      chip.classList.toggle("hover:bg-muted", !active)
      chip.classList.toggle("hover:text-foreground", !active)
    })
  }

  filteredGroups() {
    const query = this.normalize(this.query)

    return this.groups
      .filter((group) => this.activeGroup === "all" || group.key === this.activeGroup)
      .map((group) => ({
        ...group,
        questions: group.questions.filter((question) => this.matches(question, query))
      }))
      .filter((group) => group.questions.length > 0)
  }

  matches(question, normalizedQuery) {
    if (!normalizedQuery) return true
    return this.searchIndexBySlug.get(question.slug)?.text.includes(normalizedQuery) || false
  }

  buildSearchIndex() {
    this.searchIndex = this.groups.flatMap((group) =>
      group.questions.map((question) => ({
        slug: question.slug,
        text: this.normalize([
          this.rawText(group.title),
          this.rawText(question.question),
          ...this.rawAnswerTexts(question)
        ].join(" "))
      }))
    )

    this.searchIndexBySlug = new Map(this.searchIndex.map((entry) => [entry.slug, entry]))
  }

  rawText(value) {
    if (!value) return ""
    if (typeof value === "string") return value
    return [value.en, value.vi].filter(Boolean).join(" ")
  }

  rawAnswerTexts(question) {
    return question.answer.flatMap((block) => {
      const texts = []
      if (block.text) texts.push(this.rawText(block.text))
      if (block.items) {
        block.items.forEach((item) => texts.push(this.rawText(item.text || item.label || item)))
      }
      return texts
    })
  }

  totalQuestions() {
    return this.groups.reduce((total, group) => total + group.questions.length, 0)
  }

  shownQuestions(groups) {
    return groups.reduce((total, group) => total + group.questions.length, 0)
  }

  countText(shownQuestions) {
    if (!this.query && this.activeGroup === "all") {
      return `${this.totalQuestions()} ${translate("questions")}`
    }

    return `${translate("Showing")} ${shownQuestions} ${translate("of")} ${this.totalQuestions()} ${translate("questions")}`
  }

  text(value) {
    if (!value) return ""
    if (typeof value === "string") return translate(value)
    return translate(value.en || "")
  }

  normalize(text) {
    return String(text)
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .replace(/đ/g, "d")
      .replace(/[’‘]/g, "'")
  }
}
