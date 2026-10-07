import Admin_LayoutController from "controllers/admin/layout_controller"

// Admin ticket detail — handle, comment, resolve/close/reopen.
// Subscribes to the ticket's company channel for live customer replies.
// (List page stays socket-free; only the open detail subscribes once.)
// Depends on BE: Admin::CompanyTicketsController#show|assign|resolve|close|reopen|comment
// Endpoints: GET /admin/company_tickets/:id.json; POST .../:id/assign|resolve|close|reopen|comment
// Docs: docs/superpowers/plans/2026-10-07-company-support-center.md
export default class Admin_CompanyTickets_ShowController extends Admin_LayoutController {
  /** @type {any | null} */
  ticket = null

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

    if (this.ticket?.company?.id && window.WEBSOCKET) {
      try {
        const channel = WEBSOCKET.channelName("company", this.ticket.company.id)
        if (channel) {
          WEBSOCKET.subscribe(channel, "company_ticket_commented", () => this.refresh())
          WEBSOCKET.subscribe(channel, "company_ticket_status_changed", () => this.refresh())
        }
      } catch (e) { /* socket unavailable — Refresh button covers it */ }
    }
  }

  ticketId() {
    return window.location.pathname.split("/").pop()
  }

  async refresh() {
    try {
      const response = await fetchJson(`${Helpers.admin_company_ticket_path(this.ticketId())}.json`)
      this.ticket = response.company_ticket
      if (this.hasContentTarget) this.renderContent()
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Ticket not found." })
    }
  }

  async runMemberAction(event, pathFn, successMessage) {
    event.preventDefault()
    try {
      await fetchJson(pathFn(this.ticket.id), { method: "POST" })
      await this.refresh()
      toast({ type: "success", message: successMessage })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Action failed" })
    }
  }

  pickUp(event) {
    return this.runMemberAction(event, Helpers.assign_admin_company_ticket_path, "Ticket assigned to you")
  }

  resolve(event) {
    return this.runMemberAction(event, Helpers.resolve_admin_company_ticket_path, "Ticket resolved")
  }

  close(event) {
    return this.runMemberAction(event, Helpers.close_admin_company_ticket_path, "Ticket closed")
  }

  reopen(event) {
    return this.runMemberAction(event, Helpers.reopen_admin_company_ticket_path, "Ticket reopened")
  }

  refreshView(event) {
    event.preventDefault()
    return this.refresh()
  }

  async handleCommentSubmit(event) {
    event.preventDefault()
    const formEl = event.target
    try {
      await fetchJson(Helpers.comment_admin_company_ticket_path(this.ticket.id), {
        method: "POST",
        body: new FormData(formEl)
      })
      formEl.reset()
      await this.refresh()
      toast({ type: "success", message: "Comment posted" })
    } catch (error) {
      toast({ type: "error", message: error.errors?.join(", ") || "Failed to post comment" })
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

  actionButtons() {
    const t = this.ticket
    const btn = (action, label, primary) => `
      <button type="button" data-action="click->${this.identifier}#${action}"
        class="px-4 py-2 rounded-lg font-medium text-sm cursor-pointer ${primary ? "bg-blue-600 hover:bg-blue-700 text-white" : "text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800"}">
        ${label}
      </button>`
    if (!t.assigned_user) return btn("pickUp", "Pick Up", true)
    if (t.status === "resolved") return btn("close", "Close", true) + " " + btn("reopen", "Reopen", false)
    if (t.status === "closed" || t.status === "cancelled") return btn("reopen", "Reopen", false)
    return btn("resolve", "Resolve", true)
  }

  contentHTML() {
    const t = this.ticket
    if (!t) return `<div class="p-8 text-center text-slate-500">Ticket not found.</div>`

    const comments = (t.comments || []).map((c) => `
      <div class="flex flex-col gap-1 py-4 border-b border-slate-100 dark:border-slate-800 last:border-0">
        <div class="flex items-center gap-2">
          <span class="text-sm font-bold text-slate-900 dark:text-white">${escapeHtml(c.author_name) || this.humanize(c.author_type)}</span>
          ${c.author_type === "User" ? `<span class="inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-md bg-violet-50 text-violet-700 dark:bg-violet-900/30 dark:text-violet-300">Skycom Support</span>` : ""}
          <span class="text-xs text-slate-400">${c.created_at ? new Date(c.created_at).toLocaleString() : ""}</span>
        </div>
        <p class="text-sm text-slate-700 dark:text-slate-300 whitespace-pre-line">${escapeHtml(c.message)}</p>
        ${(c.attachments || []).length > 0 ? `<div class="flex flex-wrap gap-2 mt-2">${c.attachments.map((a) => this.attachmentHTML(a)).join("")}</div>` : ""}
      </div>`).join("")

    return `
      <div class="p-4 overflow-y-auto">
        <div class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <a href="${Helpers.admin_company_tickets_path()}"
            class="inline-flex items-center gap-1 text-sm text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 mb-6 cursor-pointer">
            <span class="material-symbols-outlined text-[18px]!">arrow_back</span>
            Back to Support Pool
          </a>

          <div class="flex items-center gap-2 mb-2">
            ${Helpers.statusBadge(t.status || "open")}
            ${Helpers.statusBadge(t.priority || "medium")}
            <span class="font-mono text-xs bg-slate-100 dark:bg-slate-800/60 px-2 py-0.5 rounded text-slate-600 dark:text-slate-300 font-medium">${this.humanize(t.ticket_category)}</span>
          </div>
          <h2 class="text-2xl font-black text-slate-900 dark:text-white">${escapeHtml(t.name)}</h2>
          <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">${escapeHtml(t.company?.name) || ""}</p>
          <p class="text-sm text-slate-700 dark:text-slate-300 mt-4 whitespace-pre-line">${escapeHtml(t.description)}</p>

          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 mt-6 pt-6 border-t border-slate-200 dark:border-slate-700 text-sm">
            <div><p class="text-xs font-medium text-slate-500">Assignee</p><p class="font-semibold text-slate-900 dark:text-white">${escapeHtml(t.assigned_user?.name || t.assigned_user?.email) || "—"}</p></div>
            <div><p class="text-xs font-medium text-slate-500">Raised by</p><p class="font-semibold text-slate-900 dark:text-white">${escapeHtml(t.employee?.name) || "—"}</p></div>
            <div><p class="text-xs font-medium text-slate-500">First response</p><p class="font-semibold text-slate-900 dark:text-white">${t.first_responded_at ? new Date(t.first_responded_at).toLocaleString() : "—"}</p></div>
            <div><p class="text-xs font-medium text-slate-500">Rating</p><p class="font-semibold text-slate-900 dark:text-white">${t.rate ? `${t.rate} / 5` : "—"}</p></div>
          </div>

          <div class="flex gap-2 mt-6">
            ${this.actionButtons()}
            <button type="button" data-action="click->${this.identifier}#refreshView"
              class="px-4 py-2 rounded-lg font-medium text-sm cursor-pointer text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800">
              Refresh
            </button>
          </div>

          <div class="mt-6 pt-6 border-t border-slate-200 dark:border-slate-700">
            <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase mb-2">Comments</h3>
            ${comments || `<p class="text-sm text-slate-400">No comments yet</p>`}
          </div>

          <form data-action="submit->${this.identifier}#handleCommentSubmit" class="mt-4 space-y-3">
            <textarea name="company_ticket_comment[message]" rows="3" required placeholder="Reply as Skycom support"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none placeholder:text-slate-400 dark:placeholder:text-slate-500"></textarea>
            <div class="flex items-center justify-between gap-3">
              <input type="file" name="company_ticket_comment[file_attachments][]" multiple
                class="text-sm text-slate-500 dark:text-slate-400 cursor-pointer">
              <button type="submit" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium text-sm cursor-pointer">Post Comment</button>
            </div>
          </form>
        </div>
      </div>`
  }
}
