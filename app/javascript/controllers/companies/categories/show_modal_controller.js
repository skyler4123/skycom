import { Controller } from "@hotwired/stimulus"

export default class Companies_Categories_ShowModalController extends Controller {
  /** @type {Category | null} */
  category = null

  connect() {
    this.category = /** @type {any} */ (window.currentCategory)

    if (this.category) {
      this.element.innerHTML = this.html()
    }
  }

  html() {
    const c = this.category

    const resourceOptions = (Enums()?.category?.resource_names || []).map(r => ({
      name: r,
      value: r
    }))

    const propertyFields = this.renderPropertyFields(c)

    return `
      <div class="flex items-center justify-center">
        <div class="relative w-full max-w-[75vw] max-h-[90vh] overflow-y-auto overflow-x-hidden rounded-xl bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-800 shadow-2xl">

          <div class="flex items-center justify-between border-b border-slate-200 dark:border-gray-800 px-6 py-4 sticky top-0 bg-white dark:bg-gray-800 z-10">
            <h3 class="text-xl font-bold text-slate-900 dark:text-white">Category Details</h3>
            <button data-action="click->${this.identifier}#close" class="rounded-full p-2 text-slate-500 dark:text-gray-400 hover:bg-slate-100 dark:hover:bg-gray-800">
              <span class="material-symbols-outlined">close</span>
            </button>
          </div>

          <div class="p-6 space-y-6">

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">Name</label>
                ${editable({
                  dispatch: "updateCategory",
                  resource: "category",
                  name: "name",
                  id: c.id,
                  value: c.name || '',
                  url: Helpers.edit_company_category_path(currentCompany().id, c.id),
                  html: `<p class="text-lg font-semibold text-slate-900 dark:text-white">${c.name || 'N/A'}</p>`,
                  successMessage: "Category name updated!",
                  errorMessage: "Failed to update name!"
                })}
              </div>

              <div>
                <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">Resource Name</label>
                ${editable({
                  dispatch: "updateCategory",
                  resource: "category",
                  name: "resource_name",
                  id: c.id,
                  value: c.resource_name || '',
                  url: Helpers.edit_company_category_path(currentCompany().id, c.id),
                  type: "select",
                  options: resourceOptions,
                  html: `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-300">${c.resource_name || 'N/A'}</span>`,
                  successMessage: "Resource name updated!",
                  errorMessage: "Failed to update resource name!"
                })}
              </div>
            </div>

            <div>
              <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">Description</label>
              ${editable({
                dispatch: "updateCategory",
                resource: "category",
                name: "description",
                id: c.id,
                value: c.description || '',
                url: Helpers.edit_company_category_path(currentCompany().id, c.id),
                html: `<p class="text-sm text-slate-600 dark:text-slate-300">${c.description || 'No description'}</p>`,
                successMessage: "Description updated!",
                errorMessage: "Failed to update description!"
              })}
            </div>

            ${propertyFields}

          </div>

        </div>
      </div>
    `
  }

  renderPropertyFields(category) {
    const sections = []

    const stringFields = []
    for (let i = 1; i <= 20; i++) {
      const key = `property_string_${i}`
      const label = category[key] || `String ${i} (Label)`
      stringFields.push(this.renderField(category, key, label, 'text'))
    }

    const textFields = []
    for (let i = 1; i <= 5; i++) {
      const key = `property_text_${i}`
      const label = category[key] || `Text ${i} (Label)`
      textFields.push(this.renderField(category, key, label, 'textarea'))
    }

    const integerFields = []
    for (let i = 1; i <= 20; i++) {
      const key = `property_integer_${i}`
      const label = category[key] || `Integer ${i} (Label)`
      integerFields.push(this.renderField(category, key, label, 'number'))
    }

    const decimalFields = []
    for (let i = 1; i <= 10; i++) {
      const key = `property_decimal_${i}`
      const label = category[key] || `Decimal ${i} (Label)`
      decimalFields.push(this.renderField(category, key, label, 'decimal'))
    }

    const booleanFields = []
    for (let i = 1; i <= 20; i++) {
      const key = `property_boolean_${i}`
      const label = category[key] || `Boolean ${i} (Label)`
      booleanFields.push(this.renderField(category, key, label, 'boolean'))
    }

    const datetimeFields = []
    for (let i = 1; i <= 10; i++) {
      const key = `property_datetime_${i}`
      const label = category[key] || `DateTime ${i} (Label)`
      datetimeFields.push(this.renderField(category, key, label, 'datetime'))
    }

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h4 class="text-lg font-bold text-slate-900 dark:text-white mb-4">Property String Fields (1-20)</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${stringFields.join('')}
        </div>
      </div>
    `)

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h4 class="text-lg font-bold text-slate-900 dark:text-white mb-4">Property Text Fields (1-5)</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          ${textFields.join('')}
        </div>
      </div>
    `)

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h4 class="text-lg font-bold text-slate-900 dark:text-white mb-4">Property Integer Fields (1-20)</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${integerFields.join('')}
        </div>
      </div>
    `)

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h4 class="text-lg font-bold text-slate-900 dark:text-white mb-4">Property Decimal Fields (1-10)</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${decimalFields.join('')}
        </div>
      </div>
    `)

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h4 class="text-lg font-bold text-slate-900 dark:text-white mb-4">Property Boolean Fields (1-20)</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${booleanFields.join('')}
        </div>
      </div>
    `)

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h4 class="text-lg font-bold text-slate-900 dark:text-white mb-4">Property DateTime Fields (1-10)</h4>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${datetimeFields.join('')}
        </div>
      </div>
    `)

    return sections.join('')
  }

  renderField(category, key, label, type) {
    const value = category[key]

    if (type === 'boolean') {
      const boolValue = value === true || value === 'true'
      const hasValue = value !== null && value !== undefined && value !== ''

      return `
        <div class="flex items-center justify-between p-3 bg-slate-50 dark:bg-slate-800 rounded-lg ${!hasValue ? 'opacity-60' : ''}">
          <div class="flex flex-col">
            <span class="text-xs font-medium text-slate-500 dark:text-slate-400">${label}</span>
            ${!hasValue ? '<span class="text-[10px] text-slate-400 italic">Click to set value</span>' : ''}
          </div>
          ${editable({
            dispatch: "updateCategory",
            resource: "category",
            name: key,
            id: category.id,
            value: boolValue ? 'true' : 'false',
            url: Helpers.edit_company_category_path(currentCompany().id, category.id),
            type: "select",
            options: [
              { name: "True", value: "true" },
              { name: "False", value: "false" }
            ],
            html: `<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${boolValue ? 'bg-green-100 text-green-800 dark:bg-green-900/40 dark:text-green-400' : 'bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-300'}">${boolValue ? 'True' : (hasValue ? 'False' : 'Set')}</span>`,
            successMessage: `${key} updated!`,
            errorMessage: `Failed to update ${key}!`
          })}
        </div>
      `
    }

    const hasValue = value !== null && value !== undefined && value !== ''
    const displayValue = hasValue ? value : `<span class="text-slate-400 italic">Click to add label</span>`
    const inputType = type === 'decimal' ? 'number' : type

    return `
      <div class="p-3 bg-slate-50 dark:bg-slate-800 rounded-lg ${!hasValue ? 'opacity-60' : ''}">
        <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase mb-1 block">${label}</label>
        ${editable({
          dispatch: "updateCategory",
          resource: "category",
          name: key,
          id: category.id,
          value: value || '',
          url: Helpers.edit_company_category_path(currentCompany().id, category.id),
          type: type === 'textarea' ? 'text' : inputType,
          html: type === 'textarea'
            ? `<p class="text-sm text-slate-600 dark:text-slate-300 whitespace-pre-wrap">${displayValue}</p>`
            : `<p class="text-sm font-medium text-slate-900 dark:text-white">${displayValue}</p>`,
          successMessage: `${key} updated!`,
          errorMessage: `Failed to update ${key}!`
        })}
      </div>
    `
  }

  close(event) {
    event.preventDefault()
    closeModal()
  }
}