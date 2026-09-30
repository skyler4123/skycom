// app/javascript/controllers/companies/calendar_events/booking_form.js
//
// Shared field builder for the Appointments new/edit forms, so the two can
// never drift on field names or layout. The server reads bracket-notation names
// (calendar_event[starts_at], practitioner_ids[] ...), so a rename here is a
// breaking change in two places at once — keep them in lockstep.

/** @typedef {{id: string, name: string}} CalendarEventOption */

/** @param {CalendarEventOption[]} options @param {string|null} selected */
export const optionsHTML = (options, selected) => {
  if (!options || options.length === 0) return ""
  return options.map((o) =>
    `<option value="${o.id}" ${String(o.id) === String(selected) ? "selected" : ""}>${o.name}</option>`
  ).join("")
}

/** @param {CalendarEventOption[]} options @param {string[]} selected */
export const optionsSelectedHTML = (options, selected = []) => {
  if (!options || options.length === 0) return ""
  const ids = selected.map(String)
  return options.map((o) =>
    `<option value="${o.id}" ${ids.includes(String(o.id)) ? "selected" : ""}>${o.name}</option>`
  ).join("")
}

export const inputClass = "w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm"
export const labelClass = "text-[10px] font-bold text-slate-400 uppercase"

/** datetime-local wants "YYYY-MM-DDTHH:mm" in the *browser's* local time. */
export const toDatetimeLocal = (iso) => {
  if (!iso) return ""
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return ""
  const pad = (n) => String(n).padStart(2, "0")
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

/** Fields shared by the new and edit forms.
 *  @param {Object} ctx
 *  @param {Object|null} ctx.event        - existing event, or null when creating
 *  @param {Object} ctx.options          - { procedures, practitioners, locations, equipment, participants }
 *  @param {boolean} ctx.isNew */
export const bookingFieldsHTML = ({ event, options, isNew }) => {
  const e = event || {}
  const procedures = options?.procedures || []
  const practitioners = options?.practitioners || []
  const locations = options?.locations || []
  const equipment = options?.equipment || []
  const participants = options?.participants || []

  const selectedProcedure = e.calendar_procedure_id || ""
  const procedure = procedures.find((p) => String(p.id) === String(selectedProcedure)) || null

  return `
    <div class="space-y-6">
      <h2 class="text-xl font-bold text-slate-900 dark:text-white">
        ${translate(isNew ? "New Appointment" : "Edit Appointment")}
      </h2>

      <div class="grid grid-cols-2 gap-4">
        <div class="col-span-2 space-y-1">
          <label class="${labelClass}" for="calendar_event_procedure_id">${translate("Procedure")}</label>
          <select id="calendar_event_procedure_id" name="calendar_event[calendar_procedure_id]" required
            class="${inputClass}">
            <option value="">${translate("Select a procedure")}</option>
            ${optionsHTML(procedures, selectedProcedure)}
          </select>
        </div>

        <div class="col-span-2 space-y-1">
          <label class="${labelClass}" for="calendar_event_title">${translate("Title")}</label>
          <input id="calendar_event_title" type="text" name="calendar_event[title]" value="${(e.title || "").replace(/"/g, "&quot;")}"
            placeholder="${translate("Leave blank to use the procedure name")}"
            class="${inputClass}">
        </div>

        <div class="space-y-1">
          <label class="${labelClass}" for="calendar_event_starts_at">${translate("Starts At")}</label>
          <input id="calendar_event_starts_at" type="datetime-local" name="calendar_event[starts_at]" required
            value="${toDatetimeLocal(e.starts_at)}" class="${inputClass}">
        </div>

        <div class="space-y-1">
          <label class="${labelClass}" for="calendar_event_ends_at">${translate("Ends At")}</label>
          <input id="calendar_event_ends_at" type="datetime-local" name="calendar_event[ends_at]" required
            value="${toDatetimeLocal(e.ends_at)}" class="${inputClass}">
        </div>

        <div class="space-y-1">
          <label class="${labelClass}" for="calendar_event_status">${translate("Status")}</label>
          <select id="calendar_event_status" name="calendar_event[status]" class="${inputClass}">
            ${["pending", "confirmed", "in_progress", "completed", "cancelled", "no_show"].map((s) =>
              `<option value="${s}" ${s === (e.status || "pending") ? "selected" : ""}>${Helpers.capitalize(s.replace("_", " "))}</option>`
            ).join("")}
          </select>
        </div>

        <div class="space-y-1">
          <label class="${labelClass}" for="calendar_event_location">${translate("Room / Location")}</label>
          <select id="calendar_event_location" name="location_ids[]" class="${inputClass}">
            <option value="">${translate("None")}</option>
            ${optionsSelectedHTML(locations, (e.locations || []).map((l) => l.id))}
          </select>
        </div>

        <div class="col-span-2 space-y-1">
          <label class="${labelClass}" for="calendar_event_practitioners">${translate("Practitioners")}</label>
          <select id="calendar_event_practitioners" name="practitioner_ids[]" multiple size="4" class="${inputClass}">
            ${optionsSelectedHTML(practitioners, (e.practitioners || []).map((p) => p.id))}
          </select>
          <p class="text-[10px] text-slate-400">${translate("The first selection is the lead; the rest are assistants.")}</p>
        </div>

        <div class="col-span-2 space-y-1">
          <label class="${labelClass}" for="calendar_event_equipment">${translate("Equipment")}</label>
          <select id="calendar_event_equipment" name="equipment_ids[]" multiple size="3" class="${inputClass}">
            ${optionsSelectedHTML(equipment, (e.equipment || []).map((x) => x.id))}
          </select>
        </div>

        <div class="col-span-2 space-y-1">
          <label class="${labelClass}" for="calendar_event_participants">${translate("Patient / Participant")}</label>
          <select id="calendar_event_participants" name="participant_ids[]" multiple size="3" class="${inputClass}">
            ${optionsSelectedHTML(participants, (e.participants || []).map((p) => p.id))}
          </select>
        </div>

        <div class="col-span-2 space-y-1">
          <label class="${labelClass}" for="calendar_event_notes">${translate("Notes")}</label>
          <textarea id="calendar_event_notes" name="calendar_event[notes]" rows="3" class="${inputClass}">${e.notes || ""}</textarea>
        </div>
      </div>

      <div data-${isNew ? "companies--calendar-events--new" : "companies--calendar-events--edit"}-target="conflicts" class="hidden"></div>
    </div>
  `
}
