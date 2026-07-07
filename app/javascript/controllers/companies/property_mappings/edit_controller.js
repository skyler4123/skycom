import Companies_LayoutController from "controllers/companies/layout_controller"

export default class Companies_PropertyMappings_EditController extends Companies_LayoutController {
  /** @type {any | null} */
  mapping = null

  /** @type {Array<{key: string, name: string}>} */
  propertyMetadata = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const mappingId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_property_mapping_path(companyId, mappingId)}.json`)
      this.mapping = response.property_mapping
      this.propertyMetadata = this.mapping?.property_metadata || []

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
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-red-600">${translate("Failed to load property mapping.")}</div>`
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const m = this.mapping
    if (!m) return `<div class="p-8 text-center">${translate("Property mapping not found.")}</div>`

    const companyId = window.location.pathname.split("/")[2]
    const usedKeys = new Set(this.propertyMetadata.map(f => f.key))
    const allPropertyKeys = this.allPropertySlots()
    const availableSlots = allPropertyKeys.filter(s => !usedKeys.has(s.key))

    const rowsHTML = this.propertyMetadata.map((field, index) => `
      <tr class="border-b border-slate-100 dark:border-gray-800 last:border-0">
        <td class="py-3 px-4 text-sm">
          <span class="font-mono text-xs bg-slate-100 dark:bg-slate-800 px-2 py-1 rounded text-slate-600 dark:text-slate-400">${field.key}</span>
          <input type="hidden" name="property_mapping[property_metadata][${index}][key]" value="${field.key}">
        </td>
        <td class="py-3 px-4">
          <input type="text" name="property_mapping[property_metadata][${index}][name]" value="${field.name || ''}"
            placeholder="Display Name"
            class="w-full px-2 py-1 text-sm border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-3 px-4">
          <textarea name="property_mapping[property_metadata][${index}][validates]" rows="3"
            class="w-full min-w-[200px] px-2 py-1 text-xs font-mono border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white resize-y">${JSON.stringify(field.validates || {}, null, 2)}</textarea>
        </td>
        <td class="py-3 px-4 text-right">
          <button type="button" data-action="click->${this.identifier}#removeProperty" data-index="${index}"
            class="inline-flex items-center justify-center p-1.5 text-red-500 hover:text-red-700 hover:bg-red-50 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">delete</span>
          </button>
        </td>
      </tr>
    `).join('')

    const addDropdownHTML = availableSlots.length > 0 ? `
      <div class="flex items-center gap-2 mt-3">
        <select id="new-property-slot" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
          ${availableSlots.map(s => `<option value="${s.key}">${s.key} (${s.type})</option>`).join('')}
        </select>
        <button type="button" data-action="click->${this.identifier}#addProperty"
          class="px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium transition-colors cursor-pointer">
          ${translate("Add Property")}
        </button>
      </div>
    ` : `<p class="text-sm text-slate-400 mt-3">${translate("All property slots are in use.")}</p>`

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">${translate("Edit Property Mapping")}</h2>
        <p class="text-sm text-slate-500">${translate("Add, remove, update, or add validation rules for columns of this category.")}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Name")}</label>
            <input type="text" name="property_mapping[name]" value="${m.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
          </div>

          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Description")}</label>
            <textarea name="property_mapping[description]" rows="2"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">${m.description || ''}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Category")}</label>
            <input type="text" value="${currentCategories().find(c => c.id === m.category_id)?.name || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
            <input type="hidden" name="property_mapping[category_id]" value="${m.category_id}">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase tracking-wider">${translate("Resource")}</label>
            <input type="text" value="${m.resource_name || ''}" disabled
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-slate-700 text-sm text-slate-400">
            <input type="hidden" name="property_mapping[resource_name]" value="${m.resource_name}">
          </div>
        </div>

        <div class="border-t border-slate-200 dark:border-gray-800 pt-6 mt-6">
          <h3 class="text-sm font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">${translate("Property Fields")}</h3>

          <div class="overflow-x-auto rounded-lg border border-slate-200 dark:border-gray-800">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-gray-800">
                  <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Key")}</th>
                  <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Name")}</th>
                  <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Name")}</th>
                  <th class="py-3 px-4 font-medium whitespace-nowrap">${translate("Validates")}</th>
                  <th class="py-3 px-4 font-medium text-right whitespace-nowrap">${translate("Actions")}</th>
                </tr>
              </thead>
              <tbody id="property-fields-body">
                ${rowsHTML}
              </tbody>
            </table>
          </div>

          <div id="add-property-area">
            ${addDropdownHTML}
          </div>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.company_property_mapping_path(companyId, m.id)}"
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
          action: Helpers.company_property_mapping_path(companyId, m.id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }

  addProperty() {
    const select = document.getElementById('new-property-slot')
    if (!select || !select.value) return

    this.propertyMetadata.push({
      key: select.value,
      name: '',
      validates: '{}'
    })

    this.rerenderEditor()
  }

  removeProperty(event) {
    const index = parseInt(event.currentTarget.getAttribute('data-index'))
    if (isNaN(index)) return

    this.propertyMetadata.splice(index, 1)
    this.rerenderEditor()
  }

  rerenderEditor() {
    const tbody = document.getElementById('property-fields-body')
    const addArea = document.getElementById('add-property-area')
    if (!tbody || !addArea) return

    const usedKeys = new Set(this.propertyMetadata.map(f => f.key))
    const allKeys = this.allPropertySlots()
    const availableSlots = allKeys.filter(s => !usedKeys.has(s.key))

    tbody.innerHTML = this.propertyMetadata.map((field, index) => `
      <tr class="border-b border-slate-100 dark:border-gray-800 last:border-0">
        <td class="py-3 px-4 text-sm">
          <span class="font-mono text-xs bg-slate-100 dark:bg-slate-800 px-2 py-1 rounded text-slate-600 dark:text-slate-400">${field.key}</span>
          <input type="hidden" name="property_mapping[property_metadata][${index}][key]" value="${field.key}">
        </td>
        <td class="py-3 px-4">
          <input type="text" name="property_mapping[property_metadata][${index}][name]" value="${field.name || ''}"
            placeholder="Display Name"
            class="w-full px-2 py-1 text-sm border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white">
        </td>
        <td class="py-3 px-4">
          <textarea name="property_mapping[property_metadata][${index}][validates]" rows="3"
            class="w-full min-w-[200px] px-2 py-1 text-xs font-mono border border-slate-200 dark:border-slate-600 rounded bg-white dark:bg-slate-800 text-slate-900 dark:text-white resize-y">${JSON.stringify(field.validates || {}, null, 2)}</textarea>
        </td>
        <td class="py-3 px-4 text-right">
          <button type="button" data-action="click->${this.identifier}#removeProperty" data-index="${index}"
            class="inline-flex items-center justify-center p-1.5 text-red-500 hover:text-red-700 hover:bg-red-50 rounded-lg cursor-pointer">
            <span class="material-symbols-outlined text-[18px]">delete</span>
          </button>
        </td>
      </tr>
    `).join('')

    addArea.innerHTML = availableSlots.length > 0 ? `
      <div class="flex items-center gap-2 mt-3">
        <select id="new-property-slot" class="pl-3 pr-10 py-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300">
          ${availableSlots.map(s => `<option value="${s.key}">${s.key} (${s.type})</option>`).join('')}
        </select>
        <button type="button" data-action="click->${this.identifier}#addProperty"
          class="px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-medium transition-colors cursor-pointer">
          ${translate("Add Property")}
        </button>
      </div>
    ` : `<p class="text-sm text-slate-400 mt-3">${translate("All property slots are in use.")}</p>`
  }

  allPropertySlots() {
    const slots = []
    for (let i = 1; i <= 10; i++) slots.push({ key: `property_string_${i}`, type: 'string' })
    for (let i = 1; i <= 5; i++) slots.push({ key: `property_text_${i}`, type: 'text' })
    for (let i = 1; i <= 20; i++) slots.push({ key: `property_integer_${i}`, type: 'integer' })
    for (let i = 1; i <= 10; i++) slots.push({ key: `property_decimal_${i}`, type: 'decimal' })
    for (let i = 1; i <= 10; i++) slots.push({ key: `property_boolean_${i}`, type: 'boolean' })
    for (let i = 1; i <= 10; i++) slots.push({ key: `property_datetime_${i}`, type: 'datetime' })
    return slots
  }
}
