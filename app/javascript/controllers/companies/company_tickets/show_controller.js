import Companies_LayoutController from "controllers/companies/layout_controller"

// Ticket detail — thread, attachments, activity log, comment box, rating.
// Comment/rate forms POST JSON via fetchJson submit handlers (notifications
// mark-read precedent) because the endpoints are JSON-only; the page refreshes
// its own state instead of navigating. Subscribes to the company channel for
// live staff replies — comment events carry the full comment payload and are
// injected into the thread (no re-fetch); status events still refresh.
// Depends on BE: Companies::CompanyTicketsController#show|rate,
//               Companies::CompanyTicketCommentsController#create
// Endpoints: GET <pathname>.json — ticket + comments + logs + attachments;
//            POST /companies/:id/company_ticket_comments; POST .../company_tickets/:id/rate
// Docs: docs/superpowers/plans/2026-10-07-company-support-center.md
export default class Companies_CompanyTickets_ShowController extends Companies_LayoutController {
  /** @type {any | null} */
  ticket = null
  _ownIds = new Set()

  async connect() {
    super.connect()

    await this.refresh()

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })

    const channel = window.WEBSOCKET && WEBSOCKET.channelName("company", currentCompany().id)
    if (channel) {
      try {
        WEBSOCKET.subscribe(channel, "company_ticket_commented", (data) => this.handleSocketComment(data))
        WEBSOCKET.subscribe(channel, "company_ticket_status_changed", () => this.refresh())
      } catch (e) { /* socket unavailable — page works via action refreshes */ }
    }
  }

  handleSocketComment(data) {
    if (!this.ticket || data?.id !== this.ticket.id) return
    const c = data.payload?.comment
    if (!c?.id) return
    if ((this.ticket.comments || []).some((x) => x.id === c.id)) return
    if (data.payload?.first_responded_at) this.ticket.first_responded_at = data.payload.first_responded_at
    this.appendComment(c, { silent: this._ownIds.has(c.id) })
  }

  appendComment(c, { silent = false } = {}) {
    this.ticket.comments = [...(this.ticket.comments || []), c].sort((a, b) =>
      new Date(a.created_at) - new Date(b.created_at))
    if (this.hasContentTarget) this.renderContent()
    if (!silent) toast({ type: "info", message: translate("New comment") })
  }

  acceptablePickedFile(picked) {
    const isImage = ["image/png", "image/jpeg"].includes(picked.type)
    const isExcel = [
      "application/vnd.ms-excel",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    ].includes(picked.type)
    if (!isImage && !isExcel) {
      toast({ type: "error", message: translate("Only PNG/JPEG images or Excel files are allowed") })
      return false
    }
    const max = isImage ? 2 * 1024 * 1024 : 1 * 1024 * 1024
    if (picked.size > max) {
      toast({ type: "error", message: translate("File is too big (images up to 2MB, Excel up to 1MB)") })
      return false
    }
    return true
  }

  async refresh() {
    try {
      const response = await fetchJson(`${pathname()}.json`)
      this.ticket = response.company_ticket
      if (this.hasContentTarget) this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Ticket not found.") })
    }
  }

  async handleCommentSubmit(event) {
    event.preventDefault()
    const formEl = event.target
    const picked = formEl.querySelector('input[type="file"]')?.files?.[0]
    if (picked && !this.acceptablePickedFile(picked)) return
    try {
      const response = await fetchJson(Helpers.company_company_ticket_comments_path(currentCompany().id), {
        method: "POST",
        body: new FormData(formEl)
      })
      const c = response.company_ticket_comment
      if (c?.id) {
        this._ownIds.add(c.id)
        this.appendComment(c, { silent: true })
      }
      formEl.reset()
      toast({ type: "success", message: translate("Comment posted") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to post comment") })
    }
  }

  async handleRateSubmit(event) {
    event.preventDefault()
    const value = new FormData(event.target).get("company_ticket[rate]")
    try {
      await fetchJson(Helpers.rate_company_company_ticket_path(currentCompany().id, this.ticket.id), {
        method: "POST",
        body: { company_ticket: { rate: value } }
      })
      await this.refresh()
      toast({ type: "success", message: translate("Thanks for your rating") })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || translate("Failed to save rating") })
    }
  }

  humanize(value) {
    if (!value) return "—"
    return value.split("_").map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join(" ")
  }

  attachmentHTML(a) {
    const filename = escapeHtml(a.filename)
    if (a.image) {
      return `
        <a href="${a.url}" target="_blank" class="block shrink-0 cursor-pointer">
          <img src="${a.url}" alt="${filename}" class="w-24 h-24 object-cover rounded-lg border border-slate-200 dark:border-slate-700">
        </a>`
    }
    return `
      <a href="${a.url}" target="_blank"
        class="flex items-center gap-2 px-3 py-2 border border-slate-200 dark:border-slate-700 rounded-lg text-sm text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 cursor-pointer shrink-0">
        <span class="material-symbols-outlined text-[20px]">description</span>
        <span class="max-w-[160px] truncate">${filename}</span>
      </a>`
  }

  contentHTML() {
    const t = this.ticket
    if (!t) return `<div class="p-8 text-center text-slate-500">${translate("Ticket not found.")}</div>`

    const comments = (t.comments || []).map((c) => `
      <div class="flex flex-col gap-1 py-4 border-b border-slate-100 dark:border-slate-800 last:border-0">
        <div class="flex items-center gap-2">
          <span class="text-sm font-bold text-slate-900 dark:text-white">${escapeHtml(c.author_name) || this.humanize(c.author_type)}</span>
          ${c.author_type === "User" ? `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-violet-50 text-violet-700 dark:bg-violet-900/30 dark:text-violet-300">${translate("Skycom Support")}</span>` : ""}
          <span class="text-xs text-slate-400">${c.created_at ? new Date(c.created_at).toLocaleString() : ""}</span>
        </div>
        <p class="text-sm text-slate-700 dark:text-slate-300 whitespace-pre-line">${escapeHtml(c.message)}</p>
        ${(c.attachments || []).length > 0 ? `<div class="flex flex-wrap gap-2 mt-2">${c.attachments.map((a) => this.attachmentHTML(a)).join("")}</div>` : ""}
      </div>`).join("")

    const logs = (t.logs || []).map((l) => `
      <div class="flex items-center gap-2 py-1.5 text-xs text-slate-500 dark:text-slate-400">
        <span class="material-symbols-outlined text-[16px]">history</span>
        <span>${this.humanize(l.action)}${l.from_status ? ` (${l.from_status} → ${l.to_status})` : ""}</span>
        ${l.note ? `<span class="truncate">— ${escapeHtml(l.note)}</span>` : ""}
        <span class="ml-auto shrink-0">${l.created_at ? new Date(l.created_at).toLocaleString() : ""}</span>
      </div>`).join("")

    const ratingBlock = t.rate
      ? `<p class="mt-6 pt-6 border-t border-slate-200 dark:border-slate-700 text-sm text-slate-600 dark:text-slate-300">${translate("Your rating")}: <span class="font-bold text-slate-900 dark:text-white">${t.rate} / 5</span></p>`
      : (t.can_rate
        ? `
        <form data-action="submit->${this.identifier}#handleRateSubmit" class="flex items-center gap-3 mt-6 pt-6 border-t border-slate-200 dark:border-slate-700">
          <label class="text-sm font-medium text-slate-600 dark:text-slate-300">${translate("Rate this ticket")}</label>
          <select name="company_ticket[rate]" class="px-3 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
            ${[1, 2, 3, 4, 5].map((v) => `<option value="${v}">${v}</option>`).join("")}
          </select>
          <button type="submit" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">${translate("Rate")}</button>
        </form>`
        : "")

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.company_company_tickets_path(currentCompany().id)}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            ${translate("Back to Support Tickets")}
          </a>

          <div class="flex items-center gap-2 mb-2">
            ${Helpers.statusBadge(t.status || "open")}
            ${Helpers.statusBadge(t.priority || "medium")}
            <span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${this.humanize(t.ticket_category)}</span>
          </div>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white">${escapeHtml(t.name)}</h2>
          <p class="text-sm text-slate-700 dark:text-slate-300 mt-4 whitespace-pre-line">${escapeHtml(t.description)}</p>

          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 mt-6 pt-6 border-t border-slate-200 dark:border-slate-700 text-sm">
            <div><p class="text-xs font-medium text-slate-500">${translate("Assignee")}</p><p class="font-semibold text-slate-900 dark:text-white">${escapeHtml(t.assigned_user?.name || t.assigned_user?.email) || "—"}</p></div>
            <div><p class="text-xs font-medium text-slate-500">${translate("Raised by")}</p><p class="font-semibold text-slate-900 dark:text-white">${escapeHtml(t.employee?.name) || "—"}</p></div>
            <div><p class="text-xs font-medium text-slate-500">${translate("Created")}</p><p class="font-semibold text-slate-900 dark:text-white">${t.created_at ? new Date(t.created_at).toLocaleString() : "—"}</p></div>
            <div><p class="text-xs font-medium text-slate-500">${translate("First response")}</p><p class="font-semibold text-slate-900 dark:text-white">${t.first_responded_at ? new Date(t.first_responded_at).toLocaleString() : "—"}</p></div>
          </div>

          ${(t.attachments || []).length > 0 ? `
            <div class="mt-6 pt-6 border-t border-slate-200 dark:border-slate-700">
              <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase mb-3">${translate("Attachments")}</h3>
              <div class="flex flex-wrap gap-2">${t.attachments.map((a) => this.attachmentHTML(a)).join("")}</div>
            </div>` : ""}

          <div class="mt-6 pt-6 border-t border-slate-200 dark:border-slate-700">
            <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase mb-2">${translate("Activity")}</h3>
            ${logs}
          </div>

          <div class="mt-6 pt-6 border-t border-slate-200 dark:border-slate-700">
            <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase mb-2">${translate("Comments")}</h3>
            ${comments || `<p class="text-sm text-slate-400">${translate("No comments yet")}</p>`}
          </div>

          <form data-action="submit->${this.identifier}#handleCommentSubmit" class="mt-4 space-y-3">
            <input type="hidden" name="company_ticket_comment[company_ticket_id]" value="${t.id}">
            <textarea name="company_ticket_comment[message]" rows="3" required placeholder="${translate("Add a comment")}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500"></textarea>
            <div class="flex items-center justify-between gap-3">
              <div class="flex flex-col gap-1">
                <input type="file" name="company_ticket_comment[file_attachments][]"
                  accept="image/png,image/jpeg,.xls,.xlsx"
                  class="text-sm text-slate-500 dark:text-slate-400 cursor-pointer">
                <span class="text-xs text-slate-400">${translate("1 image (PNG/JPEG, up to 2MB) or 1 Excel file (up to 1MB)")}</span>
              </div>
              <button type="submit" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">${translate("Post Comment")}</button>
            </div>
          </form>

          ${ratingBlock}
        </div>
      </div>`
  }
}
