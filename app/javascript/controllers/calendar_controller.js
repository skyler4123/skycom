// app/javascript/controllers/calendar_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    view:       { type: String, default: "month" },
    anchor:     { type: String, default: new Date().toISOString().split("T")[0] },
    startDate:  String,
    endDate:    String,
    mode:       { type: String, default: "range" },
    dragging:   { type: Boolean, default: false },
    dragStart:  String,
    dragEnd:    String,
    apiUrl:     { type: String, default: "/demo/calendar_events" }
  }

  connect() {
    console.log("Calendar controller connected")
    this.today     = new Date().toISOString().split("T")[0]
    this.events    = []
    this.isLoading = false

    this.renderAll()       // empty calendar first
    this.fetchEvents()     // then load data
  }

  async fetchEvents() {
    if (this.isLoading) return
    this.isLoading = true
    this.renderAll()

    try {
      const range = this.getCurrentRange()
      const url = `${this.apiUrlValue}?start=${range.start}&end=${range.end}`

      const response = await fetch(url, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      this.events = await response.json() || []
    } catch (error) {
      console.error("Failed to load calendar events:", error)
      this.events = []
    } finally {
      this.isLoading = false
      this.renderAll()
    }
  }

  getCurrentRange() {
    const d = new Date(this.anchorValue)
    let start, end

    switch (this.viewValue) {
      case "month":
        start = new Date(d.getFullYear(), d.getMonth(), 1)
        end   = new Date(d.getFullYear(), d.getMonth() + 1, 0)
        break
      case "week":
        start = new Date(d)
        start.setDate(start.getDate() - (start.getDay() || 7) + 1)
        end = new Date(start)
        end.setDate(end.getDate() + 6)
        break
      case "day":
        start = end = d
        break
      case "year":
        start = new Date(d.getFullYear(), 0, 1)
        end   = new Date(d.getFullYear(), 11, 31)
        break
      default:
        start = new Date(d.getFullYear(), d.getMonth(), 1)
        end   = new Date(d.getFullYear(), d.getMonth() + 1, 0)
    }

    return {
      start: start.toISOString().split("T")[0],
      end:   end.toISOString().split("T")[0]
    }
  }

  prev()  { this.move(-1); this.refresh() }
  next()  { this.move(+1); this.refresh() }

  move(delta) {
    const d = new Date(this.anchorValue)
    if      (this.viewValue === "month") d.setMonth(d.getMonth() + delta)
    else if (this.viewValue === "week")  d.setDate(d.getDate() + delta * 7)
    else if (this.viewValue === "day")   d.setDate(d.getDate() + delta)
    else if (this.viewValue === "year")  d.setFullYear(d.getFullYear() + delta)
    this.anchorValue = d.toISOString().split("T")[0]
  }

  month() { this.viewValue = "month"; this.refresh() }
  week()  { this.viewValue = "week";  this.refresh() }
  day()   { this.viewValue = "day";   this.refresh() }
  year()  { this.viewValue = "year";  this.refresh() }

  refresh() {
    this.renderAll()
    this.fetchEvents()
  }

  renderAll() {
    this.element.innerHTML = `
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="bg-white rounded-2xl shadow-xl overflow-hidden border border-gray-200 relative">

          <div class="px-6 py-5 border-b bg-gradient-to-r from-indigo-50 to-blue-50">
            <div class="flex flex-col sm:flex-row justify-between items-center gap-4">
              <div class="flex items-center gap-4">
                <button data-action="click->calendar#prev" class="p-3 rounded-lg hover:bg-white/80 text-gray-700">←</button>
                <h1 class="text-2xl font-bold text-gray-900">${this.getTitle()}</h1>
                <button data-action="click->calendar#next" class="p-3 rounded-lg hover:bg-white/80 text-gray-700">→</button>
              </div>
              <div class="flex gap-2 flex-wrap">
                <button data-action="click->calendar#month" class="px-4 py-2 text-sm rounded-lg transition ${this.viewValue==='month' ? 'bg-indigo-600 text-white shadow' : 'bg-white border hover:bg-gray-50'}">Month</button>
                <button data-action="click->calendar#week"  class="px-4 py-2 text-sm rounded-lg transition ${this.viewValue==='week'  ? 'bg-indigo-600 text-white shadow' : 'bg-white border hover:bg-gray-50'}">Week</button>
                <button data-action="click->calendar#day"   class="px-4 py-2 text-sm rounded-lg transition ${this.viewValue==='day'   ? 'bg-indigo-600 text-white shadow' : 'bg-white border hover:bg-gray-50'}">Day</button>
                <button data-action="click->calendar#year"  class="px-4 py-2 text-sm rounded-lg transition ${this.viewValue==='year'  ? 'bg-indigo-600 text-white shadow' : 'bg-white border hover:bg-gray-50'}">Year</button>
              </div>
            </div>
          </div>

          <div class="p-5 md:p-6 min-h-[500px] relative">
            ${this.isLoading ? `
              <div class="absolute inset-0 bg-white/60 flex items-center justify-center z-10">
                <div class="animate-spin h-12 w-12 border-4 border-indigo-500 rounded-full border-t-transparent"></div>
              </div>
            ` : ""}
            ${this.renderContent()}
          </div>
        </div>

        <div class="mt-4 text-center text-sm text-gray-600">
          Selected: <strong class="text-indigo-700">${this.formatSelection()}</strong>
        </div>
      </div>
    `
  }

  formatSelection() {
    if (!this.startDateValue) return "—"
    if (this.modeValue === "single" || !this.endDateValue) return this.startDateValue
    return `${this.startDateValue} → ${this.endDateValue}`
  }

  getTitle() {
    const d = new Date(this.anchorValue)
    switch (this.viewValue) {
      case "month": return d.toLocaleDateString("en-US", { month: "long", year: "numeric" })
      case "week": {
        const s = new Date(d); s.setDate(s.getDate() - (s.getDay()||7) + 1)
        const e = new Date(s); e.setDate(e.getDate() + 6)
        return s.toLocaleDateString("en-US", { month: "short", day: "numeric" }) + " – " +
               e.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
      }
      case "day": return d.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric" })
      case "year": return d.getFullYear()
      default: return "Calendar"
    }
  }

  renderContent() {
    switch (this.viewValue) {
      case "year":  return this.renderYear()
      case "month": return this.renderMonth()
      case "week":  return this.renderWeek()
      case "day":   return this.renderDay()
      default:      return "<p class='text-center py-20 text-gray-500'>Unknown view</p>"
    }
  }

  renderYear() {
    const year = new Date(this.anchorValue).getFullYear()
    let html = '<div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-4">'
    for (let m = 0; m < 12; m++) {
      html += `
        <button data-action="click->calendar#jumpToMonth" data-month="${m}"
                class="p-6 border rounded-xl hover:bg-indigo-50 hover:border-indigo-300 transition text-center">
          <div class="font-semibold text-lg">${new Date(year, m).toLocaleString("en-US", { month: "long" })}</div>
          <div class="text-sm text-gray-500 mt-1">${year}</div>
        </button>
      `
    }
    html += '</div>'
    return html
  }

  jumpToMonth(e) {
    const month = parseInt(e.currentTarget.dataset.month)
    const d = new Date(this.anchorValue)
    d.setMonth(month)
    d.setDate(1)
    this.anchorValue = d.toISOString().split("T")[0]
    this.viewValue = "month"
    this.refresh()
  }

  weekdayHeader() {
    return `
      <div class="grid grid-cols-7 text-center text-sm font-semibold text-gray-600 py-3 bg-gray-50 rounded-t-lg">
        <div>Mon</div><div>Tue</div><div>Wed</div><div>Thu</div>
        <div>Fri</div><div>Sat</div><div class="text-red-600">Sun</div>
      </div>
    `
  }

  dayCell(dateStr, dayNumber, height = "h-28", extra = "") {
    const isToday   = dateStr === this.today
    const selected  = this.isSelected(dateStr)
    const isStart   = dateStr === (this.dragStartValue || this.startDateValue)
    const isEnd     = dateStr === (this.dragEndValue   || this.endDateValue)

    let cellStyle = "bg-white hover:bg-indigo-50/60 border border-gray-200 relative overflow-hidden"
    if (isToday)   cellStyle += " bg-blue-50 border-2 border-blue-400 font-bold"
    if (selected)  cellStyle += " bg-indigo-100/70 border-indigo-200"
    if (isStart || isEnd) cellStyle += " bg-indigo-600 text-white shadow-md hover:bg-indigo-700"

    const dayEvents = this.events.filter(ev => ev.start?.split("T")[0] === dateStr)

    // Show up to 3 events with title + time
    const eventItems = dayEvents.slice(0, 3).map(ev => {
      let timeStr = ev.allDay ? "All day" : "";
      if (!ev.allDay && ev.start) {
        const startTime = new Date(ev.start).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        timeStr = startTime
        if (ev.end) {
          const endTime = new Date(ev.end).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
          timeStr += `–${endTime}`
        }
      }
      const color = ev.backgroundColor || ev.color || '#6366f1'
      return `
        <div class="text-xs truncate px-1.5 py-0.5 leading-tight" style="color: ${color};">
          <span class="font-medium">${ev.title}</span>
          ${timeStr ? ` <span class="opacity-75">(${timeStr})</span>` : ''}
        </div>
      `
    }).join("")

    const more = dayEvents.length > 3 ?
      `<div class="text-xs text-gray-500 px-1.5 mt-0.5">+${dayEvents.length - 3} more</div>` : ""

    return `
      <div class="${height} ${extra} ${cellStyle} flex flex-col items-start justify-start pt-1.5 text-base cursor-pointer select-none transition"
           data-date="${dateStr}"
           data-action="mousedown->calendar#onMouseDown mouseenter->calendar#onMouseEnter mouseup->calendar#onMouseUp click->calendar#onClick">
        <div class="w-full px-1.5 flex justify-between items-center">
          <span class="font-medium">${dayNumber}</span>
          ${isToday ? '<span class="text-xs bg-blue-600 text-white px-1.5 rounded-full">Today</span>' : ''}
        </div>

        <div class="w-full mt-1 flex flex-col overflow-hidden">
          ${eventItems}
          ${more}
        </div>
      </div>
    `
  }

  isSelected(dateStr) {
    if (!this.startDateValue) return false
    if (this.modeValue === "single") return dateStr === this.startDateValue

    const a = this.dragStartValue || this.startDateValue
    const b = this.dragEndValue   || this.endDateValue || a
    if (!a || !b) return false
    return (dateStr >= a && dateStr <= b) || (dateStr >= b && dateStr <= a)
  }

  renderMonth() {
    const d = new Date(this.anchorValue)
    const y = d.getFullYear(), m = d.getMonth()
    const first = new Date(y, m, 1)
    const daysInMonth = new Date(y, m + 1, 0).getDate()
    const startWeekday = first.getDay() || 7

    let html = this.weekdayHeader()
    html += '<div class="grid grid-cols-7 gap-2">'

    for (let i = 1; i < startWeekday; i++) html += '<div class="h-32 bg-gray-50/30"></div>'

    for (let day = 1; day <= daysInMonth; day++) {
      const date = `${y}-${String(m+1).padStart(2,'0')}-${String(day).padStart(2,'0')}`
      html += this.dayCell(date, day, "h-32")
    }

    const used = startWeekday - 1 + daysInMonth
    for (let i = used % 7; i > 0 && i < 7; i++) html += '<div class="h-32 bg-gray-50/30"></div>'

    html += '</div>'
    return html
  }

  renderWeek() {
    const d = new Date(this.anchorValue)
    d.setDate(d.getDate() - (d.getDay() || 7) + 1)

    let html = this.weekdayHeader()
    html += '<div class="grid grid-cols-7 gap-2">'

    for (let i = 0; i < 7; i++) {
      const dd = new Date(d)
      dd.setDate(dd.getDate() + i)
      const ds = dd.toISOString().split("T")[0]
      html += this.dayCell(ds, dd.getDate(), "h-64 md:h-80")
    }

    html += '</div>'
    return html
  }

  renderDay() {
    const ds = this.anchorValue
    const d = new Date(ds)
    return `
      ${this.weekdayHeader()}
      <div class="grid grid-cols-1 gap-2">
        ${this.dayCell(ds, d.getDate(), "min-h-[32rem]", "flex-col items-start justify-start p-6 text-left text-3xl font-bold")}
      </div>
    `
  }

  onMouseDown(e) {
    const date = e.currentTarget.dataset.date
    if (!date) return
    this.draggingValue = true
    this.dragStartValue = date
    this.dragEndValue = null
    e.preventDefault()
    this.updateSelectionStyle()
  }

  onMouseEnter(e) {
    if (!this.draggingValue) return
    const date = e.currentTarget.dataset.date
    if (date) this.dragEndValue = date
    this.updateSelectionStyle()
  }

  onMouseUp(event) {
    if (!this.draggingValue) return
    this.draggingValue = false

    let start = this.dragStartValue
    let end = this.dragEndValue || start

    if (start > end) [start, end] = [end, start]

    if (this.modeValue === "single") {
      this.startDateValue = start
      this.endDateValue = null
    } else {
      this.startDateValue = start
      this.endDateValue = end
    }

    this.dragStartValue = null
    this.dragEndValue = null

    this.renderAll()
    this.dispatch("calendar:change", {
      detail: this.endDateValue ? { start, end } : { date: start },
      bubbles: true
    })
  }

  onClick(e) {
    if (this.draggingValue) return
    const date = e.currentTarget.dataset.date
    if (!date) return

    this.startDateValue = date
    this.endDateValue = null
    this.dragStartValue = null
    this.dragEndValue = null

    this.renderAll()
    this.dispatch("calendar:change", { detail: { date }, bubbles: true })
  }

  updateSelectionStyle() {
    this.element.querySelectorAll("[data-date]").forEach(el => {
      const d = el.dataset.date
      const selected = this.isSelected(d)
      const isStart = d === (this.dragStartValue || this.startDateValue)
      const isEnd   = d === (this.dragEndValue   || this.endDateValue)

      el.classList.toggle("bg-indigo-100/70", selected && !isStart && !isEnd)
      el.classList.toggle("bg-indigo-600", isStart || isEnd)
      el.classList.toggle("text-white", isStart || isEnd)
      el.classList.toggle("hover:bg-indigo-700", isStart || isEnd)
      el.classList.toggle("hover:bg-indigo-50/60", !(isStart || isEnd))
    })
  }
}