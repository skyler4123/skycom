import Companies_LayoutController from "controllers/companies/layout_controller"
import Companies_Events_NewModalController from "controllers/companies/events/new_modal_controller"

// Workflow → Tailwind mapping (FE-owned, aligned with Helpers.statusBadge).
// Full literal class strings so Tailwind JIT can compile them — never interpolate.
const WORKFLOW_STYLES = {
  draft: { bg: "bg-slate-400", text: "text-slate-500" },
  pending: { bg: "bg-yellow-500", text: "text-yellow-600" },
  confirmed: { bg: "bg-green-500", text: "text-green-600" },
  in_progress: { bg: "bg-blue-500", text: "text-blue-600" },
  completed: { bg: "bg-emerald-600", text: "text-emerald-600" },
  cancelled: { bg: "bg-red-500", text: "text-red-500" }
}

const workflowStatusOf = (ev) => ev.workflow_status || ev.extendedProps?.workflow_status || "pending"
const workflowBg = (status) => (WORKFLOW_STYLES[status] || WORKFLOW_STYLES.pending).bg
const workflowText = (status) => (WORKFLOW_STYLES[status] || WORKFLOW_STYLES.pending).text

export default class Companies_Calendars_IndexController extends Companies_LayoutController {
  // Calendar board — day/week/month views over real Events. Clicking a time
  // slot opens the full-detail create modal prefilled with that slot.
  // Depends on BE: Companies::CalendarsController#index (.json board feed: id/title/start/end/workflow_status),
  //                  Companies::EventsController#create (JSON, via the modal)
  // Endpoints: GET /companies/:id/calendar.json?start=&end=[&branch_id][&category_id]
  // Docs: docs/EVENTS.md
  /** @type {string} */
  view = "month"

  /** @type {string} */
  anchor = new Date().toISOString().split("T")[0]

  /** @type {any[]} */
  events = []

  /** @type {boolean} */
  isLoading = false

  async connect() {
    super.connect()

    this.today = new Date().toISOString().split("T")[0]
    window.addEventListener("calendar:refresh", this.handleRefresh)
    await this.fetchEvents()

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  disconnect() {
    window.removeEventListener("calendar:refresh", this.handleRefresh)
    super.disconnect()
  }

  handleRefresh = () => {
    this.fetchEvents().then(() => {
      if (this.hasContentTarget) this.renderContent()
    })
  }

  async fetchEvents() {
    if (this.isLoading) return
    this.isLoading = true
    if (this.hasContentTarget) this.renderContent()

    try {
      const companyId = window.location.pathname.split("/")[2]
      const range = this.getCurrentRange()
      const response = await fetchJson(`${Helpers.company_calendar_path(companyId)}.json?start=${range.start}&end=${range.end}`)
      this.events = response.events || []
    } catch (error) {
      const __errDetail = error.errors?.join(", ") || error.message
      toast({ type: "error", message: `${ translate("Failed to load events") }${__errDetail ? ": " + __errDetail : ""}` })
      this.events = []
    } finally {
      this.isLoading = false
      if (this.hasContentTarget) this.renderContent()
    }
  }

  getCurrentRange() {
    const d = new Date(this.anchor)
    let start, end
    if (this.view === "month") {
      start = new Date(d.getFullYear(), d.getMonth(), 1)
      end = new Date(d.getFullYear(), d.getMonth() + 1, 0)
    } else if (this.view === "week") {
      start = new Date(d)
      start.setDate(start.getDate() - (start.getDay() || 7) + 1)
      end = new Date(start)
      end.setDate(end.getDate() + 6)
    } else {
      start = end = d
    }
    return { start: start.toISOString().split("T")[0], end: end.toISOString().split("T")[0] }
  }

  prev() { this.move(-1); this.refresh() }
  next() { this.move(+1); this.refresh() }

  move(delta) {
    const d = new Date(this.anchor)
    if (this.view === "month") d.setMonth(d.getMonth() + delta)
    else if (this.view === "week") d.setDate(d.getDate() + delta * 7)
    else d.setDate(d.getDate() + delta)
    this.anchor = d.toISOString().split("T")[0]
  }

  showMonth() { this.view = "month"; this.refresh() }
  showWeek() { this.view = "week"; this.refresh() }
  showDay() { this.view = "day"; this.refresh() }
  refresh() { this.renderContent(); this.fetchEvents() }

  openCreateModal(event) {
    const { date, hour } = event.params
    const start = hour !== undefined && hour !== null && hour !== ""
      ? `${date}T${String(hour).padStart(2, '0')}:00`
      : `${date}T09:00`
    const startDate = new Date(start)
    const endDate = new Date(startDate.getTime() + 60 * 60 * 1000)
    const pad = (n) => String(n).padStart(2, '0')
    const fmt = (d) => `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
    window.pendingEventDefaults = { start_at: fmt(startDate), end_at: fmt(endDate) }
    openModal({ html: `<div data-controller="${identifier(Companies_Events_NewModalController)}"></div>` })
  }

  contentHTML() {
    return `
      <div class="p-4 overflow-y-auto">
        <div class="mx-auto">
          <div class="bg-white dark:bg-slate-900 rounded-2xl shadow-xl overflow-hidden border border-slate-200 dark:border-slate-800 relative">
            ${this.headerHTML()}
            <div class="p-5 md:p-6 min-h-[500px] relative">
              ${this.isLoading ? `
                <div class="absolute inset-0 bg-white/60 dark:bg-slate-900/60 flex items-center justify-center z-10 backdrop-blur-[1px]">
                  <div class="animate-spin h-12 w-12 border-4 border-indigo-500 rounded-full border-t-transparent"></div>
                </div>
              ` : ''}
              ${this.boardHTML()}
            </div>
          </div>
        </div>
      </div>
    `
  }

  headerHTML() {
    const btnBase = "px-4 py-2 text-sm rounded-lg transition cursor-pointer"
    const activeBtn = "bg-indigo-600 text-white shadow"
    const inactiveBtn = "bg-white dark:bg-slate-700 border dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600"

    return `
      <div class="px-6 py-5 border-b border-slate-200 dark:border-slate-700">
        <div class="flex flex-col sm:flex-row justify-between items-center gap-4">
          <div class="flex items-center gap-6">
            <button data-action="click->${this.identifier}#prev" class="flex items-center justify-center w-12 h-12 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition text-slate-600 dark:text-slate-400 cursor-pointer">
              <span class="material-symbols-outlined">arrow_back</span>
            </button>
            <h1 class="text-2xl font-bold text-slate-900 dark:text-white">${this.getTitle()}</h1>
            <button data-action="click->${this.identifier}#next" class="flex items-center justify-center w-12 h-12 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 transition text-slate-600 dark:text-slate-400 cursor-pointer">
              <span class="material-symbols-outlined">arrow_forward</span>
            </button>
          </div>
          <div class="flex gap-2 flex-wrap">
            <button data-action="click->${this.identifier}#showMonth" class="${btnBase} ${this.view === 'month' ? activeBtn : inactiveBtn}">${translate("Month")}</button>
            <button data-action="click->${this.identifier}#showWeek" class="${btnBase} ${this.view === 'week' ? activeBtn : inactiveBtn}">${translate("Week")}</button>
            <button data-action="click->${this.identifier}#showDay" class="${btnBase} ${this.view === 'day' ? activeBtn : inactiveBtn}">${translate("Day")}</button>
          </div>
        </div>
      </div>
    `
  }

  getTitle() {
    const d = new Date(this.anchor)
    if (this.view === "month") return d.toLocaleDateString("en-US", { month: "long", year: "numeric" })
    if (this.view === "day") return d.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric" })
    const s = new Date(d); s.setDate(s.getDate() - (s.getDay() || 7) + 1); const e = new Date(s); e.setDate(e.getDate() + 6)
    return s.toLocaleDateString("en-US", { month: "short", day: "numeric" }) + " – " + e.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
  }

  boardHTML() {
    if (this.view === "month") return this.monthViewHTML()
    if (this.view === "week") return this.weekViewHTML()
    return this.dayViewHTML()
  }

  weekdayHeaderHTML() {
    return `
      <div class="grid grid-cols-7 text-center text-sm font-semibold text-slate-600 dark:text-slate-400 py-3 bg-slate-50 dark:bg-slate-900/50 rounded-t-lg">
        <div>Mon</div><div>Tue</div><div>Wed</div><div>Thu</div>
        <div>Fri</div><div>Sat</div><div class="text-red-600 dark:text-red-400">Sun</div>
      </div>
    `
  }

  dayCellHTML(dateStr, dayNumber) {
    const isToday = dateStr === this.today
    const dayEvents = this.events.filter(ev => ev.start?.split("T")[0] === dateStr)
    const eventItems = dayEvents.slice(0, 3).map(ev => `<div class="text-xs truncate px-1.5 py-0.5 leading-tight ${workflowText(workflowStatusOf(ev))}"><span class="font-medium">${ev.title}</span></div>`).join("")

    return `
      <div class="h-32 bg-white dark:bg-slate-900 hover:bg-indigo-50/60 dark:hover:bg-indigo-900/30 border border-slate-200 dark:border-slate-700 relative overflow-hidden rounded-lg transition flex flex-col items-start justify-start pt-1.5 text-base cursor-pointer select-none"
        data-date="${dateStr}"
        data-action="click->${this.identifier}#openCreateModal"
        data-${this.identifier}-date-param="${dateStr}">
        <div class="w-full px-1.5 flex justify-between items-center text-slate-900 dark:text-slate-200">
          <span class="font-medium">${dayNumber}</span>
          ${isToday ? '<span class="text-[10px] bg-blue-600 text-white px-1.5 rounded-full uppercase">Today</span>' : ''}
        </div>
        <div class="w-full mt-1 flex flex-col overflow-hidden">${eventItems}</div>
      </div>`
  }

  monthViewHTML() {
    const d = new Date(this.anchor), y = d.getFullYear(), m = d.getMonth()
    const first = new Date(y, m, 1), daysInMonth = new Date(y, m + 1, 0).getDate(), startWeekday = first.getDay() || 7
    let html = this.weekdayHeaderHTML() + '<div class="grid grid-cols-7 gap-2">'
    for (let i = 1; i < startWeekday; i++) html += '<div class="h-32 bg-slate-50/30 dark:bg-slate-700/30 rounded-lg"></div>'
    for (let day = 1; day <= daysInMonth; day++) html += this.dayCellHTML(`${y}-${String(m + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`, day)
    const used = startWeekday - 1 + daysInMonth
    for (let i = used % 7; i > 0 && i < 7; i++) html += '<div class="h-32 bg-slate-50/30 dark:bg-slate-700/30 rounded-lg"></div>'
    return html + '</div>'
  }

  weekViewHTML() {
    const d = new Date(this.anchor); d.setDate(d.getDate() - (d.getDay() || 7) + 1)
    const days = Array.from({ length: 7 }, (_, i) => {
      const dayDate = new Date(d); dayDate.setDate(dayDate.getDate() + i)
      return { dateStr: dayDate.toISOString().split("T")[0], dayNumber: dayDate.getDate(), isToday: dayDate.toISOString().split("T")[0] === this.today }
    })

    const timeSlots = []
    for (let hour = 0; hour < 24; hour++) {
      const timeLabel = `${hour.toString().padStart(2, '0')}:00`
      let rowHtml = `<div class="text-right text-xs text-slate-500 dark:text-slate-400 pr-3 pt-1 border-t border-slate-200 dark:border-slate-700">${timeLabel}</div>`
      days.forEach(day => {
        const overlapping = this.events.filter(ev => {
          if (ev.start?.split("T")[0] !== day.dateStr || ev.allDay) return false
          const start = new Date(ev.start), end = new Date(ev.end), sStart = new Date(day.dateStr + 'T' + timeLabel + ':00'), sEnd = new Date(sStart.getTime() + 3600000)
          return start < sEnd && end > sStart
        })
        rowHtml += `<div class="relative border-l border-slate-200 dark:border-slate-700 min-h-[60px] bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-700 transition cursor-pointer"
          data-action="click->${this.identifier}#openCreateModal"
          data-${this.identifier}-date-param="${day.dateStr}"
          data-${this.identifier}-hour-param="${hour}">
          ${overlapping.map(ev => `<div class="absolute inset-x-1 top-0 rounded-md shadow-sm p-1 text-xs text-white overflow-hidden ${workflowBg(workflowStatusOf(ev))}" style="height: ${Math.min((new Date(ev.end) - new Date(ev.start)) / 600, 100)}%; min-height: 40px;"><div class="font-medium truncate">${ev.title}</div></div>`).join('')}
        </div>`
      })
      timeSlots.push(`<div class="grid grid-cols-8 gap-0">${rowHtml}</div>`)
    }

    return `
      <div class="border dark:border-slate-700 rounded-lg overflow-hidden">
        <div class="grid grid-cols-8 bg-slate-100 dark:bg-slate-900 border-b dark:border-slate-700">
          <div class="p-3 text-sm font-semibold text-slate-600 dark:text-slate-400 text-right">Time</div>
          ${days.map(day => `<div class="p-3 text-center text-sm font-semibold ${day.isToday ? 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200' : 'dark:text-slate-300'}">${new Date(day.dateStr).toLocaleString('en-US', { weekday: 'short' })} ${day.dayNumber}</div>`).join('')}
        </div>
        ${timeSlots.join('')}
      </div>
    `
  }

  dayViewHTML() {
    const dateStr = this.anchor, isToday = dateStr === this.today, dayEvents = this.events.filter(ev => ev.start?.split("T")[0] === dateStr)
    const timeSlots = []
    for (let hour = 0; hour < 24; hour++) {
      const timeLabel = `${hour.toString().padStart(2, '0')}:00`, sStart = new Date(dateStr + 'T' + timeLabel + ':00'), sEnd = new Date(sStart.getTime() + 3600000)
      const overlapping = dayEvents.filter(ev => !ev.allDay && new Date(ev.start) < sEnd && new Date(ev.end) > sStart)
      timeSlots.push(`
        <div class="grid grid-cols-[80px_1fr] border-t border-slate-200 dark:border-slate-700">
          <div class="text-right pr-4 pt-2 text-xs text-slate-600 dark:text-slate-400 font-medium bg-slate-50 dark:bg-slate-900/50">${timeLabel}</div>
          <div class="relative min-h-[60px] bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-700 transition cursor-pointer"
            data-action="click->${this.identifier}#openCreateModal"
            data-${this.identifier}-date-param="${dateStr}"
            data-${this.identifier}-hour-param="${hour}">
            ${overlapping.map(ev => `<div class="absolute inset-x-2 top-0 rounded-lg shadow-md p-2 text-sm text-white overflow-hidden ${workflowBg(workflowStatusOf(ev))}" style="height: ${Math.min((new Date(ev.end) - new Date(ev.start)) / 600, 100)}%; min-height: 50px;"><div class="font-semibold truncate">${ev.title}</div></div>`).join('')}
          </div>
        </div>`)
    }
    return `
      <div class="border dark:border-slate-700 rounded-lg overflow-hidden">
        <div class="bg-slate-100 dark:bg-slate-900 p-4 border-b dark:border-slate-700 text-center font-bold text-lg ${isToday ? 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200' : 'dark:text-white'}">
          ${new Date(dateStr).toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric" })}
        </div>
        ${timeSlots.join('')}
      </div>`
  }
}
