// app/javascript/controllers/companies/calendar_availability_rules/availability_form.js
//
// Shared field builder for the Working hours new/edit forms, so the two can
// never drift on field names or layout.

export const inputClass = "w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm"
export const labelClass = "text-[10px] font-bold text-slate-400 uppercase"

/** ISO weekday number -> translated label. 1 = Monday .. 7 = Sunday. */
export const WEEKDAYS = [
  [ 1, "Monday" ], [ 2, "Tuesday" ], [ 3, "Wednesday" ], [ 4, "Thursday" ],
  [ 5, "Friday" ], [ 6, "Saturday" ], [ 7, "Sunday" ]
]

/** Owner toggle + the two mutually exclusive selects.
 *  A rule belongs to EITHER a practitioner OR a location, so the inactive select
 *  is `disabled` — a disabled control is not submitted, which keeps the BE's
 *  "exactly one owner" check satisfied. */
export const ownerPickerHTML = ({ owner, practitioners, locations, practitionerId, locationId, identifier }) => {
  const chip = (value, label) => {
    const active = owner === value
    return `<button type="button" data-action="companies--calendar-availability-rules--${identifier}#switchOwner" data-owner="${value}"
      class="px-3 py-1 text-xs rounded-lg border cursor-pointer ${active
        ? "bg-blue-600 text-white border-blue-600"
        : "bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-slate-700"}">
      ${translate(label)}
    </button>`
  }

  return `
    <div class="col-span-2 space-y-1">
      <label class="${labelClass}">${translate("Applies To")}</label>
      <div class="flex gap-2 mb-2">
        ${chip("practitioner", "Practitioner")}
        ${chip("location", "Room / Location")}
      </div>
      <select name="calendar_availability_rule[calendar_practitioner_id]" ${owner === "location" ? "disabled" : ""} class="${inputClass}">
        <option value="">${translate("Select a practitioner")}</option>
        ${(practitioners || []).map((p) => `<option value="${p.id}" ${String(p.id) === String(practitionerId) ? "selected" : ""}>${p.name}</option>`).join("")}
      </select>
      <select name="calendar_availability_rule[calendar_location_id]" ${owner === "practitioner" ? "disabled" : ""} class="${inputClass}">
        <option value="">${translate("Select a room")}</option>
        ${(locations || []).map((l) => `<option value="${l.id}" ${String(l.id) === String(locationId) ? "selected" : ""}>${l.name}</option>`).join("")}
      </select>
    </div>
  `
}

export const weekdayPickerHTML = (selected) => {
  const ids = (selected || []).map(Number)
  return `
    <div class="col-span-2 space-y-1">
      <label class="${labelClass}">${translate("Days")}</label>
      <div class="flex flex-wrap gap-2">
        ${WEEKDAYS.map(([value, label]) => `
          <label class="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 text-xs cursor-pointer">
            <input type="checkbox" name="calendar_availability_rule[days_of_week][]" value="${value}"
              ${ids.includes(value) ? "checked" : ""}
              class="w-3.5 h-3.5 rounded border-slate-300 text-blue-600">
            ${translate(label)}
          </label>
        `).join("")}
      </div>
    </div>
  `
}

/** @param {Object} ctx
 *  @param {Object|null} ctx.rule       - existing rule, or null when creating
 *  @param {Object} ctx.practitioners
 *  @param {Object} ctx.locations
 *  @param {string} ctx.owner           - "practitioner" | "location"
 *  @param {boolean} ctx.isNew */
export const availabilityFieldsHTML = ({ rule, practitioners, locations, owner, isNew }) => {
  const r = rule || {}
  const selectedDays = r.days_of_week || [ 1, 2, 3, 4, 5 ]

  return `
    <div class="space-y-6">
      <h2 class="text-xl font-bold text-slate-900 dark:text-white">
        ${translate(isNew ? "New Working hours" : "Edit Working hours")}
      </h2>
      <div class="grid grid-cols-2 gap-4">
        <div class="space-y-1">
          <label class="${labelClass}">${translate("Name")}</label>
          <input type="text" name="calendar_availability_rule[name]"
            value="${(r.name || "").replace(/"/g, "&quot;")}" placeholder="e.g. Weekday hours"
            class="${inputClass}">
        </div>
        <div class="space-y-1">
          <label class="${labelClass}">${translate("Timezone")}</label>
          <input type="text" name="calendar_availability_rule[timezone]"
            value="${r.timezone || "UTC"}" required class="${inputClass}">
        </div>

        ${ownerPickerHTML({
          owner,
          practitioners,
          locations,
          practitionerId: r.calendar_practitioner_id,
          locationId: r.calendar_location_id,
          identifier: isNew ? "new" : "edit"
        })}

        ${weekdayPickerHTML(selectedDays)}

        <div class="space-y-1">
          <label class="${labelClass}">${translate("Start Time")}</label>
          <input type="time" name="calendar_availability_rule[start_time]"
            value="${r.start_time || "09:00"}" required class="${inputClass}">
        </div>
        <div class="space-y-1">
          <label class="${labelClass}">${translate("End Time")}</label>
          <input type="time" name="calendar_availability_rule[end_time]"
            value="${r.end_time || "17:00"}" required class="${inputClass}">
        </div>

        <div class="col-span-2 flex items-center gap-2">
          <label class="${labelClass}">${translate("Blackout")}</label>
          <input type="hidden" name="calendar_availability_rule[is_unavailable]" value="0">
          <input type="checkbox" name="calendar_availability_rule[is_unavailable]" value="1"
            ${r.is_unavailable ? "checked" : ""}
            class="w-4 h-4 rounded border-slate-300 text-blue-600">
          <span class="text-xs text-slate-400">${translate("A blackout subtracts from availability (e.g. leave).")}</span>
        </div>
      </div>
    </div>
  `
}
