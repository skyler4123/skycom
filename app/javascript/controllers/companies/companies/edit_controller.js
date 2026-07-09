import Companies_LayoutController from "controllers/companies/layout_controller"
import { TIMEZONES, CURRENCIE_CODES } from "controllers/constants"

export default class Companies_Companies_EditController extends Companies_LayoutController {
  /** @type {any | null} */
  company = null

  async connect() {
    super.connect()

    const companyId = window.location.pathname.split("/")[2]

    try {
      const response = await fetchJson(`${Helpers.edit_company_company_path(companyId, companyId)}.json`)
      this.company = response.company

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load company.")}</div>`
          return true
        }
        return false
      })
    }
  }

  timezoneOptions() {
    const labels = {
      minus_12: "UTC-12", minus_11: "UTC-11", minus_10: "UTC-10", minus_9: "UTC-9",
      minus_8: "UTC-8", minus_7: "UTC-7", minus_6: "UTC-6", minus_5: "UTC-5",
      minus_4: "UTC-4", minus_3: "UTC-3", minus_2: "UTC-2", minus_1: "UTC-1",
      utc: "UTC",
      plus_1: "UTC+1", plus_2: "UTC+2", plus_3: "UTC+3", plus_4: "UTC+4",
      plus_5: "UTC+5", plus_6: "UTC+6", plus_7: "UTC+7", plus_8: "UTC+8",
      plus_9: "UTC+9", plus_10: "UTC+10", plus_11: "UTC+11", plus_12: "UTC+12"
    }
    return Object.entries(labels).map(([value, name]) => ({ value, name }))
  }

  currencyOptions() {
    return [
      { value: "usd", name: "United States Dollar - USD" },
      { value: "vnd", name: "Vietnamese Dong - VND" }
    ]
  }

  contentHTML() {
    const c = this.company
    if (!c) return `<div class="p-8 text-center">${translate("Company not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const timezones = this.timezoneOptions()
    const currencies = this.currencyOptions()

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Company")}</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">${translate("Name")}</label>
            <input type="text" name="company[name]" value="${c.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">${translate("Description")}</label>
            <textarea name="company[description]" rows="3"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${c.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">${translate("Email")}</label>
            <input type="email" name="company[email]" value="${c.email || ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">${translate("Phone")}</label>
            <input type="tel" name="company[phone_number]" value="${c.phone_number || ''}"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">${translate("Website")}</label>
            <input type="url" name="company[website]" value="${c.website || ''}" placeholder="https://"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">${translate("Timezone")}</label>
            <select name="company[timezone]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${timezones.map(t => `
                <option value="${t.value}" ${c.timezone === t.value ? 'selected' : ''}>${t.name}</option>
              `).join('')}
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">${translate("Currency")}</label>
            <select name="company[currency_code]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              ${currencies.map(cur => `
                <option value="${cur.value}" ${c.currency_code === cur.value ? 'selected' : ''}>${cur.name}</option>
              `).join('')}
            </select>
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_dashboards_path(companyId)}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg cursor-pointer">
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            ${translate("Save Changes")}
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-4 overflow-y-auto">
        ${form({
          action: Helpers.company_company_path(companyId, companyId),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 mx-auto" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
