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

    this.renderAll()
    this.fetchEvents()
  }

  // ──────────────────────────────────────
  // Data fetching
  // ──────────────────────────────────────
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

  // ──────────────────────────────────────
  // Navigation
  // ──────────────────────────────────────
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

  // ──────────────────────────────────────
  // Render entry points (clean & short)
  // ──────────────────────────────────────
  renderAll() {
    this.element.innerHTML = this.mainContainerHTML()
  }

  renderContent() {
    switch (this.viewValue) {
      case "year":  return this.yearViewHTML()
      case "month": return this.monthViewHTML()
      case "week":  return this.weekViewHTML()
      case "day":   return this.dayViewHTML()
      default:      return "<p class='text-center py-20 text-gray-500'>Unknown view</p>"
    }
  }

  // ──────────────────────────────────────
  // HTML Templates – fully separated
  // ──────────────────────────────────────

  mainContainerHTML() {
    return `
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="bg-white rounded-2xl shadow-xl overflow-hidden border border-gray-200 relative">

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
    return `
      <div class="px-6 py-5 border-b bg-gradient-to-r from-indigo-50 to-blue-50">
        <div class="flex flex-col sm:flex-row justify-between items-center gap-4">
          <div class="flex items-center gap-6">
            <button data-action="click->calendar#prev" class="flex items-center justify-center w-12 h-12 rounded-lg hover:bg-white/80 transition">
              <svg class="h-6 w-6"><use href="#arrow-left"></use></svg>
            </button>
            <h1 class="text-2xl font-bold text-gray-900">${this.getTitle()}</h1>
            <button data-action="click->calendar#next" class="flex items-center justify-center w-12 h-12 rounded-lg hover:bg-white/80 transition">
              <svg class="h-6 w-6"><use href="#arrow-right"></use></svg>
            </button>
          </div>
          <div class="flex gap-2 flex-wrap">
            <button data-action="click->calendar#month" class="px-4 py-2 text-sm rounded-lg transition ${this.viewValue==='month' ? 'bg-indigo-600 text-white shadow' : 'bg-white border hover:bg-gray-50'}">Month</button>
            <button data-action="click->calendar#week"  class="px-4 py-2 text-sm rounded-lg transition ${this.viewValue==='week'  ? 'bg-indigo-600 text-white shadow' : 'bg-white border hover:bg-gray-50'}">Week</button>
            <button data-action="click->calendar#day"   class="px-4 py-2 text-sm rounded-lg transition ${this.viewValue==='day'   ? 'bg-indigo-600 text-white shadow' : 'bg-white border hover:bg-gray-50'}">Day</button>
            <button data-action="click->calendar#year"  class="px-4 py-2 text-sm rounded-lg transition ${this.viewValue==='year'  ? 'bg-indigo-600 text-white shadow' : 'bg-white border hover:bg-gray-50'}">Year</button>
          </div>
        </div>
      </div>
    `
  }

  loadingSpinnerHTML() {
    if (!this.isLoading) return ''
    return `
      <div class="absolute inset-0 bg-white/60 flex items-center justify-center z-10">
        <div class="animate-spin h-12 w-12 border-4 border-indigo-500 rounded-full border-t-transparent"></div>
      </div>
    `
  }

  selectionFeedbackHTML() {
    return `
      <div class="mt-4 text-center text-sm text-gray-600">
        Selected: <strong class="text-indigo-700">${this.formatSelection()}</strong>
      </div>
    `
  }

  // ──────────────────────────────────────
  // Views
  // ──────────────────────────────────────

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
        if (!ev.start) return false
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
        <div class="grid grid-cols-7 gap-0.5 text-xs font-medium text-gray-500 mb-1.5">
          <div class="text-center">M</div><div>T</div><div>W</div><div>T</div><div>F</div><div>S</div><div class="text-red-500">S</div>
        </div>
        <div class="grid grid-cols-7 gap-0.5">
      `

      for (let i = 1; i < startWeekday; i++) {
        miniGrid += '<div class="h-7 bg-gray-50/40 rounded"></div>'
      }

      for (let day = 1; day <= daysInMonth; day++) {
        const dateStr = `${currentYear}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
        const isToday = dateStr === todayStr
        const dayEvents = eventsByDay[day] || []

        let dotsHtml = ''
        if (dayEvents.length > 0) {
          dotsHtml = dayEvents.slice(0, 3).map(ev => `
            <div class="w-1.5 h-1.5 rounded-full mx-auto" style="background: ${ev.backgroundColor || ev.color || '#6366f1'}"></div>
          `).join('')
          if (dayEvents.length > 3) {
            dotsHtml += `<div class="text-[9px] text-gray-400 text-center">+${dayEvents.length - 3}</div>`
          }
        }

        miniGrid += `
          <div class="h-7 flex flex-col items-center justify-center text-sm relative ${isToday ? 'font-bold text-blue-600' : 'text-gray-700'} hover:bg-indigo-50/50 rounded transition">
            ${day}
            <div class="flex flex-col gap-0.5 mt-0.5 w-4">${dotsHtml}</div>
            ${isToday ? '<div class="absolute -top-0.5 -right-0.5 w-2 h-2 bg-blue-600 rounded-full border-2 border-white"></div>' : ''}
          </div>
        `
      }

      const totalCells = startWeekday - 1 + daysInMonth
      const remaining = (7 - totalCells % 7) % 7
      for (let i = 0; i < remaining; i++) {
        miniGrid += '<div class="h-7 bg-gray-50/40 rounded"></div>'
      }

      miniGrid += '</div>'

      monthCards += `
        <button data-action="click->calendar#jumpToMonth" data-month="${month}"
                class="border border-gray-200 rounded-xl p-4 hover:shadow-lg hover:border-indigo-300 transition-all duration-200 w-full text-left bg-white">
          <div class="font-semibold text-lg mb-3 text-gray-800">${monthName}</div>
          ${miniGrid}
        </button>
      `
    }

    return `<div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">${monthCards}</div>`
  }

  monthViewHTML() {
    const d = new Date(this.anchorValue)
    const y = d.getFullYear(), m = d.getMonth()
    const first = new Date(y, m, 1)
    const daysInMonth = new Date(y, m + 1, 0).getDate()
    const startWeekday = first.getDay() || 7

    let html = this.weekdayHeaderHTML()
    html += '<div class="grid grid-cols-7 gap-2">'

    for (let i = 1; i < startWeekday; i++) html += '<div class="h-32 bg-gray-50/30 rounded-lg"></div>'

    for (let day = 1; day <= daysInMonth; day++) {
      const date = `${y}-${String(m+1).padStart(2,'0')}-${String(day).padStart(2,'0')}`
      html += this.dayCellHTML(date, day, "h-32")
    }

    const used = startWeekday - 1 + daysInMonth
    for (let i = used % 7; i > 0 && i < 7; i++) html += '<div class="h-32 bg-gray-50/30 rounded-lg"></div>'

    html += '</div>'
    return html
  }

  weekViewHTML() {
    const d = new Date(this.anchorValue)
    d.setDate(d.getDate() - (d.getDay() || 7) + 1)

    const days = []
    for (let i = 0; i < 7; i++) {
      const dayDate = new Date(d)
      dayDate.setDate(dayDate.getDate() + i)
      days.push({
        dateStr: dayDate.toISOString().split("T")[0],
        dayNumber: dayDate.getDate(),
        isToday: dayDate.toISOString().split("T")[0] === this.today
      })
    }

    const eventsByDay = {}
    days.forEach(day => {
      eventsByDay[day.dateStr] = this.events.filter(ev => ev.start?.split("T")[0] === day.dateStr)
    })

    let allDayHtml = ''
    days.forEach(day => {
      const allDayEvents = eventsByDay[day.dateStr].filter(ev => ev.allDay)
      if (allDayEvents.length > 0) {
        allDayHtml += `
          <div class="bg-gray-100 border-b border-gray-300 p-1.5 min-h-[60px] flex flex-col gap-1">
            ${allDayEvents.map(ev => `
              <div class="text-xs font-medium rounded px-2 py-1 truncate" style="background: ${ev.backgroundColor || ev.color || '#e5e7eb'}; color: white;">
                ${ev.title}
              </div>
            `).join('')}
          </div>
        `
      } else {
        allDayHtml += '<div class="bg-gray-100 border-b border-gray-300 p-1.5 min-h-[60px]"></div>'
      }
    })

    const timeSlots = []
    for (let hour = 0; hour < 24; hour++) {
      const timeLabel = `${hour.toString().padStart(2, '0')}:00`
      let rowHtml = `<div class="text-right text-xs text-gray-500 pr-3 pt-1 border-t border-gray-200">${timeLabel}</div>`

      days.forEach(day => {
        const dayEvents = eventsByDay[day.dateStr].filter(ev => !ev.allDay)
        const overlapping = dayEvents.filter(ev => {
          if (!ev.start || !ev.end) return false
          const start = new Date(ev.start)
          const end = new Date(ev.end)
          const slotStart = new Date(day.dateStr + 'T' + timeLabel + ':00')
          const slotEnd = new Date(slotStart.getTime() + 60*60*1000)
          return start < slotEnd && end > slotStart
        })

        let cellContent = ''
        if (overlapping.length > 0) {
          cellContent = overlapping.map(ev => {
            const start = new Date(ev.start)
            const duration = (new Date(ev.end) - start) / (1000 * 60)
            const heightPercent = Math.min(duration / 60 * 100, 100)
            return `
              <div class="absolute inset-x-1 top-0 rounded-md shadow-sm p-1 text-xs text-white flex flex-col justify-between overflow-hidden"
                   style="background: ${ev.backgroundColor || ev.color || '#6366f1'}; height: ${heightPercent}%; min-height: 40px;">
                <div class="font-medium truncate">${ev.title}</div>
                <div class="text-xs opacity-90">${start.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</div>
              </div>
            `
          }).join('')
        }

        rowHtml += `
          <div class="relative border-l border-gray-200 min-h-[60px] bg-white hover:bg-gray-50 transition">
            ${cellContent}
          </div>
        `
      })

      timeSlots.push(`<div class="grid grid-cols-8 gap-0">${rowHtml}</div>`)
    }

    return `
      <div class="border rounded-lg overflow-hidden">
        <div class="grid grid-cols-8 bg-gray-100 border-b">
          <div class="p-3 text-sm font-semibold text-gray-600 text-right">Time</div>
          ${days.map(day => `
            <div class="p-3 text-center text-sm font-semibold ${day.isToday ? 'bg-blue-100 text-blue-800' : ''}">
              ${new Date(day.dateStr).toLocaleString('en-US', { weekday: 'short' })} ${day.dayNumber}
            </div>
          `).join('')}
        </div>

        <div class="grid grid-cols-8">
          <div class="p-2 text-xs text-gray-600 font-medium border-r border-gray-200 bg-gray-50">All-day</div>
          ${allDayHtml}
        </div>

        ${timeSlots.join('')}
      </div>
    `
  }

  dayViewHTML() {
    const dateStr = this.anchorValue
    const dateObj = new Date(dateStr)
    const isToday = dateStr === this.today

    const dayEvents = this.events.filter(ev => ev.start?.split("T")[0] === dateStr)

    const allDayEvents = dayEvents.filter(ev => ev.allDay)
    let allDayHtml = ''
    if (allDayEvents.length > 0) {
      allDayHtml = `
        <div class="bg-gray-100 border-b border-gray-300 p-3 flex flex-wrap gap-2 min-h-[60px]">
          ${allDayEvents.map(ev => `
            <div class="text-sm font-medium rounded px-3 py-1.5" style="background: ${ev.backgroundColor || ev.color || '#e5e7eb'}; color: white;">
              ${ev.title}
            </div>
          `).join('')}
        </div>
      `
    } else {
      allDayHtml = '<div class="bg-gray-100 border-b border-gray-300 p-3 min-h-[60px]"></div>'
    }

    const timeSlots = []
    for (let hour = 0; hour < 24; hour++) {
      const timeLabel = `${hour.toString().padStart(2, '0')}:00`
      const slotStart = new Date(dateStr + 'T' + timeLabel + ':00')
      const slotEnd = new Date(slotStart.getTime() + 60*60*1000)

      const overlapping = dayEvents.filter(ev => !ev.allDay && ev.start && ev.end).filter(ev => {
        const evStart = new Date(ev.start)
        const evEnd = new Date(ev.end)
        return evStart < slotEnd && evEnd > slotStart
      })

      let cellContent = ''
      if (overlapping.length > 0) {
        cellContent = overlapping.map(ev => {
          const evStart = new Date(ev.start)
          const duration = (new Date(ev.end) - evStart) / (1000 * 60)
          const heightPercent = Math.min(duration / 60 * 100, 100)
          return `
            <div class="absolute inset-x-2 top-0 rounded-lg shadow-md p-2 text-sm text-white flex flex-col justify-between overflow-hidden"
                 style="background: ${ev.backgroundColor || ev.color || '#6366f1'}; height: ${heightPercent}%; min-height: 50px;">
              <div class="font-semibold truncate">${ev.title}</div>
              <div class="text-xs opacity-90">
                ${evStart.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                ${ev.end ? ` – ${new Date(ev.end).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}` : ''}
              </div>
            </div>
          `
        }).join('')
      }

      timeSlots.push(`
        <div class="grid grid-cols-[80px_1fr] border-t border-gray-200">
          <div class="text-right pr-4 pt-2 text-xs text-gray-600 font-medium bg-gray-50">${timeLabel}</div>
          <div class="relative min-h-[60px] bg-white hover:bg-gray-50 transition">
            ${cellContent}
          </div>
        </div>
      `)
    }

    return `
      <div class="border rounded-lg overflow-hidden">
        <div class="bg-gray-100 p-4 border-b text-center font-bold text-lg ${isToday ? 'bg-blue-100 text-blue-800' : ''}">
          ${dateObj.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", year: "numeric" })}
          ${isToday ? '<span class="ml-2 text-blue-600">(Today)</span>' : ''}
        </div>

        ${allDayHtml}

        ${timeSlots.join('')}
      </div>
    `
  }

  weekdayHeaderHTML() {
    return `
      <div class="grid grid-cols-7 text-center text-sm font-semibold text-gray-600 py-3 bg-gray-50 rounded-t-lg">
        <div>Mon</div><div>Tue</div><div>Wed</div><div>Thu</div>
        <div>Fri</div><div>Sat</div><div class="text-red-600">Sun</div>
      </div>
    `
  }

  dayCellHTML(dateStr, dayNumber, height = "h-28", extra = "") {
    const isToday   = dateStr === this.today
    const selected  = this.isSelected(dateStr)
    const isStart   = dateStr === (this.dragStartValue || this.startDateValue)
    const isEnd     = dateStr === (this.dragEndValue   || this.endDateValue)

    let cellStyle = "bg-white hover:bg-indigo-50/60 border border-gray-200 relative overflow-hidden rounded-lg"
    if (isToday)   cellStyle += " bg-blue-50 border-2 border-blue-400 font-bold"
    if (selected)  cellStyle += " bg-indigo-100/70 border-indigo-200"
    if (isStart || isEnd) cellStyle += " bg-indigo-600 text-white shadow-md hover:bg-indigo-700"

    const dayEvents = this.events.filter(ev => ev.start?.split("T")[0] === dateStr)

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

  // ──────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────
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

  jumpToMonth(e) {
    const month = parseInt(e.currentTarget.dataset.month)
    const d = new Date(this.anchorValue)
    d.setMonth(month)
    d.setDate(1)
    this.anchorValue = d.toISOString().split("T")[0]
    this.viewValue = "month"
    this.refresh()
  }

  isSelected(dateStr) {
    if (!this.startDateValue) return false
    if (this.modeValue === "single") return dateStr === this.startDateValue

    const a = this.dragStartValue || this.startDateValue
    const b = this.dragEndValue   || this.endDateValue || a
    if (!a || !b) return false
    return (dateStr >= a && dateStr <= b) || (dateStr >= b && dateStr <= a)
  }

  // ──────────────────────────────────────
  // Drag & click selection
  // ──────────────────────────────────────
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