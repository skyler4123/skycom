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
    this.today     = new Date().toISOString().split("T")[0]
    this.events    = []
    this.isLoading = false
    this.renderAll()
    this.fetchEvents()
  }

  // ... (Data fetching and Navigation logic remains unchanged)
  async fetchEvents() {
    if (this.isLoading) return
    this.isLoading = true
    this.renderAll()

    try {
      const range = this.getCurrentRange()
      const url = `${this.apiUrlValue}?start=${range.start}&end=${range.end}`
      const response = await fetch(url, { headers: { "Accept": "application/json" } })
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
      case "day": start = end = d; break
      case "year":
        start = new Date(d.getFullYear(), 0, 1)
        end   = new Date(d.getFullYear(), 11, 31)
        break
      default:
        start = new Date(d.getFullYear(), d.getMonth(), 1)
        end   = new Date(d.getFullYear(), d.getMonth() + 1, 0)
    }
    return { start: start.toISOString().split("T")[0], end: end.toISOString().split("T")[0] }
  }

  prev() { this.move(-1); this.refresh() }
  next() { this.move(+1); this.refresh() }
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
  refresh() { this.renderAll(); this.fetchEvents() }

  renderAll() { this.element.innerHTML = this.mainContainerHTML() }

  renderContent() {
    switch (this.viewValue) {
      case "year":  return this.yearViewHTML()
      case "month": return this.monthViewHTML()
      case "week":  return this.weekViewHTML()
      case "day":   return this.dayViewHTML()
      default:      return "<p class='text-center py-20 text-gray-500 dark:text-gray-400'>Unknown view</p>"
    }
  }

  // ──────────────────────────────────────
  // Updated HTML Templates with Dark Mode
  // ──────────────────────────────────────

  mainContainerHTML() {
    return `
      <div class="mx-auto">
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl overflow-hidden border border-gray-200 dark:border-gray-700 relative">
          ${this.headerHTML()}
          <div class="p-5 md:p-6 min-h-[500px] relative">
            ${this.loadingSpinnerHTML()}
            ${this.renderContent()}
          </div>
        </div>
        ${this.selectionFeedbackHTML()}
      </div>
    `
  }

  headerHTML() {
    const btnBase = "px-4 py-2 text-sm rounded-lg transition"
    const activeBtn = "bg-indigo-600 text-white shadow"
    const inactiveBtn = "bg-white dark:bg-gray-700 border dark:border-gray-600 text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-gray-600"

    return `
      <div class="px-6 py-5 border-b border-gray-200 dark:border-gray-700">
        <div class="flex flex-col sm:flex-row justify-between items-center gap-4">
          <div class="flex items-center gap-6">
            <button data-action="click->calendar#prev" class="flex items-center justify-center w-12 h-12 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition text-gray-600 dark:text-gray-400">
              <svg class="h-6 w-6"><use href="#arrow-left"></use></svg>
            </button>
            <h1 class="text-2xl font-bold text-gray-900 dark:text-white">${this.getTitle()}</h1>
            <button data-action="click->calendar#next" class="flex items-center justify-center w-12 h-12 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition text-gray-600 dark:text-gray-400">
              <svg class="h-6 w-6"><use href="#arrow-right"></use></svg>
            </button>
          </div>
          <div class="flex gap-2 flex-wrap">
            <button data-action="click->calendar#month" class="${btnBase} ${this.viewValue==='month' ? activeBtn : inactiveBtn}">Month</button>
            <button data-action="click->calendar#week"  class="${btnBase} ${this.viewValue==='week'  ? activeBtn : inactiveBtn}">Week</button>
            <button data-action="click->calendar#day"   class="${btnBase} ${this.viewValue==='day'   ? activeBtn : inactiveBtn}">Day</button>
            <button data-action="click->calendar#year"  class="${btnBase} ${this.viewValue==='year'  ? activeBtn : inactiveBtn}">Year</button>
          </div>
        </div>
      </div>
    `
  }

  loadingSpinnerHTML() {
    if (!this.isLoading) return ''
    return `
      <div class="absolute inset-0 bg-white/60 dark:bg-gray-800/60 flex items-center justify-center z-10 backdrop-blur-[1px]">
        <div class="animate-spin h-12 w-12 border-4 border-indigo-500 rounded-full border-t-transparent"></div>
      </div>
    `
  }

  selectionFeedbackHTML() {
    return `
      <div class="mt-4 text-center text-sm text-gray-600 dark:text-gray-400">
        Selected: <strong class="text-indigo-700 dark:text-indigo-400">${this.formatSelection()}</strong>
      </div>
    `
  }

  yearViewHTML() {
    const currentYear = new Date(this.anchorValue).getFullYear()
    const todayStr = this.today
    let monthCards = ''

    for (let month = 0; month < 12; month++) {
      const firstDay = new Date(currentYear, month, 1)
      const monthName = firstDay.toLocaleString("en-US", { month: "long" })
      const daysInMonth = new Date(currentYear, month + 1, 0).getDate()
      const startWeekday = firstDay.getDay() || 7

      const monthEvents = this.events.filter(ev => {
        const evDate = new Date(ev.start)
        return evDate.getFullYear() === currentYear && evDate.getMonth() === month
      })

      const eventsByDay = {}
      monthEvents.forEach(ev => {
        const day = new Date(ev.start).getDate()
        if (!eventsByDay[day]) eventsByDay[day] = []
        eventsByDay[day].push(ev)
      })

      let miniGrid = `
        <div class="grid grid-cols-7 gap-0.5 text-xs font-medium text-gray-500 dark:text-gray-400 mb-1.5">
          <div class="text-center">M</div><div>T</div><div>W</div><div>T</div><div>F</div><div>S</div><div class="text-red-500">S</div>
        </div>
        <div class="grid grid-cols-7 gap-0.5">
      `

      for (let i = 1; i < startWeekday; i++) {
        miniGrid += '<div class="h-7 bg-gray-50/40 dark:bg-gray-700/40 rounded"></div>'
      }

      for (let day = 1; day <= daysInMonth; day++) {
        const dateStr = `${currentYear}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
        const isToday = dateStr === todayStr
        const dayEvents = eventsByDay[day] || []
        let dotsHtml = dayEvents.slice(0, 3).map(ev => `<div class="w-1.5 h-1.5 rounded-full mx-auto" style="background: ${ev.backgroundColor || ev.color || '#6366f1'}"></div>`).join('')

        miniGrid += `
          <div class="h-7 flex flex-col items-center justify-center text-sm relative ${isToday ? 'font-bold text-blue-600 dark:text-blue-400' : 'text-gray-700 dark:text-gray-300'} hover:bg-indigo-50/50 dark:hover:bg-indigo-900/30 rounded transition">
            ${day}
            <div class="flex flex-col gap-0.5 mt-0.5 w-4">${dotsHtml}</div>
            ${isToday ? '<div class="absolute -top-0.5 -right-0.5 w-2 h-2 bg-blue-600 rounded-full border-2 border-white dark:border-gray-800"></div>' : ''}
          </div>
        `
      }

      const totalCells = startWeekday - 1 + daysInMonth
      for (let i = 0; i < (7 - totalCells % 7) % 7; i++) {
        miniGrid += '<div class="h-7 bg-gray-50/40 dark:bg-gray-700/40 rounded"></div>'
      }

      monthCards += `
        <button data-action="click->calendar#jumpToMonth" data-month="${month}"
                class="border border-gray-200 dark:border-gray-700 rounded-xl p-4 hover:shadow-lg hover:border-indigo-300 dark:hover:border-indigo-500 transition-all duration-200 w-full text-left bg-white dark:bg-gray-800">
          <div class="font-semibold text-lg mb-3 text-gray-800 dark:text-gray-100">${monthName}</div>
          ${miniGrid}
        </button>
      `
    }
    return `<div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">${monthCards}</div>`
  }

  monthViewHTML() {
    const d = new Date(this.anchorValue), y = d.getFullYear(), m = d.getMonth()
    const first = new Date(y, m, 1), daysInMonth = new Date(y, m + 1, 0).getDate(), startWeekday = first.getDay() || 7
    let html = this.weekdayHeaderHTML() + '<div class="grid grid-cols-7 gap-2">'
    for (let i = 1; i < startWeekday; i++) html += '<div class="h-32 bg-gray-50/30 dark:bg-gray-700/30 rounded-lg"></div>'
    for (let day = 1; day <= daysInMonth; day++) html += this.dayCellHTML(`${y}-${String(m+1).padStart(2,'0')}-${String(day).padStart(2,'0')}`, day, "h-32")
    const used = startWeekday - 1 + daysInMonth
    for (let i = used % 7; i > 0 && i < 7; i++) html += '<div class="h-32 bg-gray-50/30 dark:bg-gray-700/30 rounded-lg"></div>'
    return html + '</div>'
  }

  weekViewHTML() {
    const d = new Date(this.anchorValue); d.setDate(d.getDate() - (d.getDay() || 7) + 1)
    const days = Array.from({length: 7}, (_, i) => {
      const dayDate = new Date(d); dayDate.setDate(dayDate.getDate() + i)
      return { dateStr: dayDate.toISOString().split("T")[0], dayNumber: dayDate.getDate(), isToday: dayDate.toISOString().split("T")[0] === this.today }
    })

    const timeSlots = []
    for (let hour = 0; hour < 24; hour++) {
      const timeLabel = `${hour.toString().padStart(2, '0')}:00`
      let rowHtml = `<div class="text-right text-xs text-gray-500 dark:text-gray-400 pr-3 pt-1 border-t border-gray-200 dark:border-gray-700">${timeLabel}</div>`
      days.forEach(day => {
        const events = this.events.filter(ev => ev.start?.split("T")[0] === day.dateStr && !ev.allDay)
        const overlapping = events.filter(ev => {
          const start = new Date(ev.start), end = new Date(ev.end), sStart = new Date(day.dateStr + 'T' + timeLabel + ':00'), sEnd = new Date(sStart.getTime() + 3600000)
          return start < sEnd && end > sStart
        })
        rowHtml += `<div class="relative border-l border-gray-200 dark:border-gray-700 min-h-[60px] bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition">
          ${overlapping.map(ev => `<div class="absolute inset-x-1 top-0 rounded-md shadow-sm p-1 text-xs text-white overflow-hidden" style="background: ${ev.backgroundColor || ev.color || '#6366f1'}; height: ${Math.min((new Date(ev.end)-new Date(ev.start))/600, 100)}%; min-height: 40px;"><div class="font-medium truncate">${ev.title}</div></div>`).join('')}
        </div>`
      })
      timeSlots.push(`<div class="grid grid-cols-8 gap-0">${rowHtml}</div>`)
    }

    return `
      <div class="border dark:border-gray-700 rounded-lg overflow-hidden">
        <div class="grid grid-cols-8 bg-gray-100 dark:bg-gray-900 border-b dark:border-gray-700">
          <div class="p-3 text-sm font-semibold text-gray-600 dark:text-gray-400 text-right">Time</div>
          ${days.map(day => `<div class="p-3 text-center text-sm font-semibold ${day.isToday ? 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200' : 'dark:text-gray-300'}">${new Date(day.dateStr).toLocaleString('en-US', { weekday: 'short' })} ${day.dayNumber}</div>`).join('')}
        </div>
        ${timeSlots.join('')}
      </div>
    `
  }

  dayViewHTML() {
    const dateStr = this.anchorValue, isToday = dateStr === this.today, dayEvents = this.events.filter(ev => ev.start?.split("T")[0] === dateStr)
    const timeSlots = []
    for (let hour = 0; hour < 24; hour++) {
      const timeLabel = `${hour.toString().padStart(2, '0')}:00`, sStart = new Date(dateStr + 'T' + timeLabel + ':00'), sEnd = new Date(sStart.getTime() + 3600000)
      const overlapping = dayEvents.filter(ev => !ev.allDay && new Date(ev.start) < sEnd && new Date(ev.end) > sStart)
      timeSlots.push(`
        <div class="grid grid-cols-[80px_1fr] border-t border-gray-200 dark:border-gray-700">
          <div class="text-right pr-4 pt-2 text-xs text-gray-600 dark:text-gray-400 font-medium bg-gray-50 dark:bg-gray-900/50">${timeLabel}</div>
          <div class="relative min-h-[60px] bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition">
            ${overlapping.map(ev => `<div class="absolute inset-x-2 top-0 rounded-lg shadow-md p-2 text-sm text-white overflow-hidden" style="background: ${ev.backgroundColor || ev.color || '#6366f1'}; height: ${Math.min((new Date(ev.end)-new Date(ev.start))/600, 100)}%; min-height: 50px;"><div class="font-semibold truncate">${ev.title}</div></div>`).join('')}
          </div>
        </div>`)
    }
    return `
      <div class="border dark:border-gray-700 rounded-lg overflow-hidden">
        <div class="bg-gray-100 dark:bg-gray-900 p-4 border-b dark:border-gray-700 text-center font-bold text-lg ${isToday ? 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200' : 'dark:text-white'}">
          ${new Date(dateStr).toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric" })}
        </div>
        ${timeSlots.join('')}
      </div>`
  }

  weekdayHeaderHTML() {
    return `
      <div class="grid grid-cols-7 text-center text-sm font-semibold text-gray-600 dark:text-gray-400 py-3 bg-gray-50 dark:bg-gray-900/50 rounded-t-lg">
        <div>Mon</div><div>Tue</div><div>Wed</div><div>Thu</div>
        <div>Fri</div><div>Sat</div><div class="text-red-600 dark:text-red-400">Sun</div>
      </div>
    `
  }

  dayCellHTML(dateStr, dayNumber, height = "h-28", extra = "") {
    const isToday = dateStr === this.today, selected = this.isSelected(dateStr)
    const isEdge = dateStr === (this.dragStartValue || this.startDateValue) || dateStr === (this.dragEndValue || this.endDateValue)

    let cellStyle = "bg-white dark:bg-gray-800 hover:bg-indigo-50/60 dark:hover:bg-indigo-900/30 border border-gray-200 dark:border-gray-700 relative overflow-hidden rounded-lg transition"
    if (isToday)   cellStyle += " bg-blue-50 dark:bg-blue-900/20 border-2 border-blue-400 dark:border-blue-500 font-bold"
    if (selected)  cellStyle += " bg-indigo-100/70 dark:bg-indigo-900/40 border-indigo-200 dark:border-indigo-800"
    if (isEdge)    cellStyle += " bg-indigo-600 text-white shadow-md hover:bg-indigo-700"

    const dayEvents = this.events.filter(ev => ev.start?.split("T")[0] === dateStr)
    const eventItems = dayEvents.slice(0, 3).map(ev => `<div class="text-xs truncate px-1.5 py-0.5 leading-tight ${isEdge ? 'text-white' : ''}" style="${isEdge ? '' : `color: ${ev.backgroundColor || ev.color || '#6366f1'};`}"><span class="font-medium">${ev.title}</span></div>`).join("")

    return `
      <div class="${height} ${extra} ${cellStyle} flex flex-col items-start justify-start pt-1.5 text-base cursor-pointer select-none"
           data-date="${dateStr}"
           data-action="mousedown->calendar#onMouseDown mouseenter->calendar#onMouseEnter mouseup->calendar#onMouseUp click->calendar#onClick">
        <div class="w-full px-1.5 flex justify-between items-center ${isEdge ? 'text-white' : 'text-gray-900 dark:text-gray-200'}">
          <span class="font-medium">${dayNumber}</span>
          ${isToday ? `<span class="text-[10px] ${isEdge ? 'bg-white text-indigo-600' : 'bg-blue-600 text-white'} px-1.5 rounded-full uppercase">Today</span>` : ''}
        </div>
        <div class="w-full mt-1 flex flex-col overflow-hidden">${eventItems}</div>
      </div>`
  }

  // ──────────────────────────────────────
  // Updated Styles for Dragging
  // ──────────────────────────────────────
  updateSelectionStyle() {
    this.element.querySelectorAll("[data-date]").forEach(el => {
      const d = el.dataset.date
      const selected = this.isSelected(d)
      const isEdge = d === (this.dragStartValue || this.startDateValue) || d === (this.dragEndValue || this.endDateValue)

      // Light Mode Toggles
      el.classList.toggle("bg-indigo-100/70", selected && !isEdge)
      el.classList.toggle("bg-indigo-600", isEdge)
      el.classList.toggle("text-white", isEdge)
      
      // Dark Mode Toggles (Complementing the base classes)
      el.classList.toggle("dark:bg-indigo-900/40", selected && !isEdge)
      el.classList.toggle("dark:bg-indigo-500", isEdge)
    })
  }

  formatSelection() {
    if (!this.startDateValue) return "—"
    return (this.modeValue === "single" || !this.endDateValue) ? this.startDateValue : `${this.startDateValue} → ${this.endDateValue}`
  }

  getTitle() {
    const d = new Date(this.anchorValue)
    if (this.viewValue === "month") return d.toLocaleDateString("en-US", { month: "long", year: "numeric" })
    if (this.viewValue === "year") return d.getFullYear()
    if (this.viewValue === "day") return d.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric" })
    const s = new Date(d); s.setDate(s.getDate() - (s.getDay()||7) + 1); const e = new Date(s); e.setDate(e.getDate() + 6)
    return s.toLocaleDateString("en-US", { month: "short", day: "numeric" }) + " – " + e.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })
  }

  jumpToMonth(e) {
    const d = new Date(this.anchorValue); d.setMonth(parseInt(e.currentTarget.dataset.month)); d.setDate(1)
    this.anchorValue = d.toISOString().split("T")[0]; this.viewValue = "month"; this.refresh()
  }

  isSelected(dateStr) {
    if (!this.startDateValue) return false
    const a = this.dragStartValue || this.startDateValue, b = this.dragEndValue || this.endDateValue || a
    return (dateStr >= a && dateStr <= b) || (dateStr >= b && dateStr <= a)
  }

  onMouseDown(e) {
    this.draggingValue = true; this.dragStartValue = e.currentTarget.dataset.date; this.dragEndValue = null
    e.preventDefault(); this.updateSelectionStyle()
  }

  onMouseEnter(e) {
    if (this.draggingValue) { this.dragEndValue = e.currentTarget.dataset.date; this.updateSelectionStyle() }
  }

  onMouseUp() {
    if (!this.draggingValue) return
    this.draggingValue = false
    let start = this.dragStartValue, end = this.dragEndValue || start
    if (start > end) [start, end] = [end, start]
    this.startDateValue = start; this.endDateValue = this.modeValue === "single" ? null : end
    this.dragStartValue = this.dragEndValue = null
    this.renderAll()
    this.dispatch("calendar:change", { detail: this.endDateValue ? { start, end } : { date: start }, bubbles: true })
  }

  onClick(e) {
    if (this.draggingValue) return
    this.startDateValue = e.currentTarget.dataset.date; this.endDateValue = null
    this.renderAll(); this.dispatch("calendar:change", { detail: { date: this.startDateValue }, bubbles: true })
  }
}