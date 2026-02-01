// app/javascript/controllers/calendar_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    view:       { type: String, default: "month" },     // month | week | day | year
    anchor:     { type: String, default: new Date().toISOString().split("T")[0] },
    start:      String,
    end:        String,
    mode:       { type: String, default: "range" },     // single | range
    dragging:   { type: Boolean, default: false },
    dragStart:  String,
    dragEnd:    String
  }

  connect() {
    this.today = new Date().toISOString().split("T")[0]
    this.renderAll()
  }

  // ─────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────

  prev()  { this.move(-1); this.renderAll() }
  next()  { this.move(+1); this.renderAll() }

  move(step) {
    const d = new Date(this.anchorValue)
    const v = this.viewValue

    if      (v === "month") d.setMonth(d.getMonth() + step)
    else if (v === "week")  d.setDate(d.getDate() + step * 7)
    else if (v === "day")   d.setDate(d.getDate() + step)
    else if (v === "year")  d.setFullYear(d.getFullYear() + step)

    this.anchorValue = d.toISOString().split("T")[0]
  }

  // ─────────────────────────────────────────────
  // View switchers
  // ─────────────────────────────────────────────

  month() { this.viewValue = "month"; this.renderAll() }
  week()  { this.viewValue = "week";  this.renderAll() }
  day()   { this.viewValue = "day";   this.renderAll() }
  year()  { this.viewValue = "year";  this.renderAll() }

  // ─────────────────────────────────────────────
  // Core render – everything lives here
  // ─────────────────────────────────────────────

  renderAll() {
    this.element.innerHTML = `
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="bg-white rounded-2xl shadow-xl overflow-hidden border border-gray-200">

          <!-- Header -->
          <div class="px-6 py-5 border-b border-gray-200 bg-gradient-to-r from-indigo-50 to-blue-50">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div class="flex items-center gap-4">
                <button data-action="click->calendar#prev" 
                        class="p-2.5 rounded-lg hover:bg-white/80 text-gray-700 transition">
                  ←
                </button>
                <h1 class="text-2xl font-bold text-gray-900 tracking-tight">
                  ${this.getTitle()}
                </h1>
                <button data-action="click->calendar#next" 
                        class="p-2.5 rounded-lg hover:bg-white/80 text-gray-700 transition">
                  →
                </button>
              </div>

              <div class="flex flex-wrap gap-2">
                <button data-action="click->calendar#month"
                        class="px-4 py-2 text-sm font-medium rounded-lg transition ${this.viewValue==='month'?'bg-indigo-600 text-white shadow-md':'bg-white border border-gray-300 hover:bg-gray-50'}">
                  Month
                </button>
                <button data-action="click->calendar#week"
                        class="px-4 py-2 text-sm font-medium rounded-lg transition ${this.viewValue==='week'?'bg-indigo-600 text-white shadow-md':'bg-white border border-gray-300 hover:bg-gray-50'}">
                  Week
                </button>
                <button data-action="click->calendar#day"
                        class="px-4 py-2 text-sm font-medium rounded-lg transition ${this.viewValue==='day'?'bg-indigo-600 text-white shadow-md':'bg-white border border-gray-300 hover:bg-gray-50'}">
                  Day
                </button>
                <button data-action="click->calendar#year"
                        class="px-4 py-2 text-sm font-medium rounded-lg transition ${this.viewValue==='year'?'bg-indigo-600 text-white shadow-md':'bg-white border border-gray-300 hover:bg-gray-50'}">
                  Year
                </button>
              </div>
            </div>
          </div>

          <!-- Calendar content -->
          <div class="p-5 md:p-6">
            ${this.renderCalendarContent()}
          </div>

        </div>

        <!-- Selection feedback (optional – can be removed) -->
        <div class="mt-6 text-center text-sm text-gray-600">
          Selected: 
          <span class="font-medium text-indigo-700">
            ${this.startValue || "—"} ${this.endValue && this.endValue !== this.startValue ? `→ ${this.endValue}` : ""}
          </span>
        </div>
      </div>
    `

    // Re-attach drag/click listeners after render
    this.refreshListeners()
  }

  getTitle() {
    const d = new Date(this.anchorValue)
    switch (this.viewValue) {
      case "month":
        return d.toLocaleDateString("en-US", { month: "long", year: "numeric" })
      case "week": {
        const s = new Date(d)
        s.setDate(s.getDate() - (s.getDay()||7) + 1)
        const e = new Date(s); e.setDate(e.getDate() + 6)
        return `${s.toLocaleDateString("en-US", { month: "short", day: "numeric" })} – ${e.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}`
      }
      case "day":
        return d.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric" })
      case "year":
        return d.getFullYear()
      default:
        return "Calendar"
    }
  }

  renderCalendarContent() {
    switch (this.viewValue) {
      case "year":  return this.renderYear()
      case "month": return this.renderMonth()
      case "week":  return this.renderWeek()
      case "day":   return this.renderDay()
      default:      return "<p class='text-red-600'>View not implemented</p>"
    }
  }

  // ─── Year view ───────────────────────────────────────
  renderYear() {
    const y = new Date(this.anchorValue).getFullYear()
    let html = '<div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4">'
    for (let m = 0; m < 12; m++) {
      html += `
        <button data-action="click->calendar#jumpMonth" data-m="${m}"
                class="p-5 border rounded-xl text-center hover:border-indigo-400 hover:shadow-md transition-all">
          <div class="text-lg font-semibold text-gray-800">${new Date(y, m).toLocaleString("en-US", {month:"long"})}</div>
          <div class="text-sm text-gray-500 mt-1">${y}</div>
        </button>
      `
    }
    html += '</div>'
    return html
  }

  jumpMonth(e) {
    const m = parseInt(e.currentTarget.dataset.m)
    const d = new Date(this.anchorValue)
    d.setMonth(m)
    d.setDate(1)
    this.anchorValue = d.toISOString().split("T")[0]
    this.viewValue = "month"
    this.renderAll()
  }

  // ─── Month / Week / Day shared day cell ─────────────
  dayCell(dateStr, label, heightClass = "h-28", extra = "") {
    const isToday   = dateStr === this.today
    const inRange   = this.isInRange(dateStr)
    const isStart   = dateStr === (this.dragStartValue || this.startValue)
    const isEnd     = dateStr === (this.dragEndValue   || this.endValue)

    let style = "bg-white hover:bg-indigo-50/70 border border-gray-200"
    if (isToday)   style = "bg-blue-50 border-2 border-blue-400 font-bold shadow-sm"
    if (inRange)   style = "bg-indigo-100/80 border-indigo-200"
    if (isStart || isEnd) style = "bg-indigo-600 text-white shadow-md hover:bg-indigo-700"

    return `
      <div class="${heightClass} ${extra} ${style} rounded-lg flex items-center justify-center text-lg transition-all cursor-pointer select-none"
           data-date="${dateStr}"
           data-action="mousedown->calendar#dragStart mouseenter->calendar#dragMove mouseup->calendar#dragEnd click->calendar#pickDate">
        ${label}
        ${isToday ? '<div class="absolute -top-1 -right-1 w-5 h-5 bg-blue-600 text-white text-[10px] rounded-full flex items-center justify-center font-bold">NOW</div>' : ''}
      </div>
    `
  }

  isInRange(date) {
    if (!this.startValue) return false
    if (this.modeValue === "single") return date === this.startValue

    const a = this.dragStartValue || this.startValue
    const b = this.dragEndValue   || this.endValue || a
    if (!a || !b) return false
    return (date >= a && date <= b) || (date >= b && date <= a)
  }

  // ─── Month view ──────────────────────────────────────
  renderMonth() {
    const d = new Date(this.anchorValue)
    const y = d.getFullYear(), m = d.getMonth()
    const first = new Date(y, m, 1)
    const days = new Date(y, m+1, 0).getDate()
    const startDay = first.getDay() || 7   // Mon=1 .. Sun=7

    let html = this.weekdayHeader()

    html += '<div class="grid grid-cols-7 gap-2">'
    for (let i = 1; i < startDay; i++) html += '<div class="h-28"></div>'

    for (let day = 1; day <= days; day++) {
      const dateStr = `${y}-${String(m+1).padStart(2,'0')}-${String(day).padStart(2,'0')}`
      html += this.dayCell(dateStr, day)
    }

    const used = startDay - 1 + days
    for (let i = used % 7; i > 0 && i < 7; i++) html += '<div class="h-28"></div>'

    html += '</div>'
    return html
  }

  // ─── Week view ───────────────────────────────────────
  renderWeek() {
    const d = new Date(this.anchorValue)
    d.setDate(d.getDate() - (d.getDay()||7) + 1) // monday

    let html = this.weekdayHeader()

    html += '<div class="grid grid-cols-7 gap-2">'
    for (let i = 0; i < 7; i++) {
      const dd = new Date(d)
      dd.setDate(dd.getDate() + i)
      const ds = dd.toISOString().split("T")[0]
      html += this.dayCell(ds, dd.getDate(), "h-64")
    }
    html += '</div>'
    return html
  }

  // ─── Day view ────────────────────────────────────────
  renderDay() {
    const ds = this.anchorValue
    const d = new Date(ds)
    return `
      ${this.weekdayHeader(true)}
      <div class="grid grid-cols-1 gap-2">
        ${this.dayCell(ds, d.getDate(), "h-96 md:h-[32rem]", "flex-col items-start justify-start p-5 text-left text-2xl font-bold")}
      </div>
    `
  }

  weekdayHeader(force = false) {
    if (this.viewValue === "year" && !force) return ""
    return `
      <div class="grid grid-cols-7 text-center text-sm font-semibold text-gray-600 py-3 bg-gray-50/80 rounded-t-lg mb-2">
        <div>Mon</div><div>Tue</div><div>Wed</div><div>Thu</div>
        <div>Fri</div><div>Sat</div><div class="text-red-600">Sun</div>
      </div>
    `
  }

  // ─────────────────────────────────────────────
  // Drag & selection
  // ─────────────────────────────────────────────

  dragStart(e) {
    const date = e.currentTarget?.dataset?.date
    if (!date) return
    this.draggingValue = true
    this.dragStartValue = date
    this.dragEndValue = null
    e.preventDefault()
    this.refreshCells()
  }

  dragMove(e) {
    if (!this.draggingValue) return
    const date = e.currentTarget?.dataset?.date
    if (date) this.dragEndValue = date
    this.refreshCells()
  }

  dragEnd(e) {
    if (!this.draggingValue) return
    this.draggingValue = false

    let s = this.dragStartValue
    let e = this.dragEndValue || s

    if (s > e) [s, e] = [e, s]

    if (this.modeValue === "single") {
      this.startValue = s
      this.endValue = ""
    } else {
      this.startValue = s
      this.endValue = e
    }

    this.dragStartValue = null
    this.dragEndValue = null

    this.renderAll()
    this.dispatchChange()
  }

  pickDate(e) {
    if (this.draggingValue) return
    const date = e.currentTarget?.dataset?.date
    if (!date) return

    this.startValue = date
    this.endValue = ""
    this.dragStartValue = null
    this.dragEndValue = null

    this.renderAll()
    this.dispatchChange()
  }

  refreshCells() {
    this.element.querySelectorAll("[data-date]").forEach(cell => {
      const date = cell.dataset.date
      const inRange = this.isInRange(date)
      const isS = date === (this.dragStartValue || this.startValue)
      const isE = date === (this.dragEndValue   || this.endValue)

      cell.classList.toggle("bg-indigo-100/80", inRange && !isS && !isE)
      cell.classList.toggle("bg-indigo-600", isS || isE)
      cell.classList.toggle("text-white", isS || isE)
      cell.classList.toggle("hover:bg-indigo-700", isS || isE)
      cell.classList.toggle("hover:bg-indigo-50/70", !(isS || isE))
    })
  }

  dispatchChange() {
    const payload = this.modeValue === "range" && this.endValue
      ? { start: this.startValue, end: this.endValue }
      : { date: this.startValue }

    this.dispatch("calendar:change", { detail: payload, bubbles: true })
    this.dispatch("change", { detail: payload, bubbles: true })
  }

  // Optional public methods
  goTo(dateStr) {
    this.anchorValue = dateStr
    this.startValue = dateStr
    this.renderAll()
  }
}