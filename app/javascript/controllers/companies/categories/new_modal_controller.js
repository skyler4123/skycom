import { Controller } from "@hotwired/stimulus"

export default class Companies_Categories_NewModalController extends Controller {
  connect() {
    this.element.innerHTML = this.modalHTML()
  }

  modalHTML() {
    const resourceOptions = (Enums()?.category?.resource_names || []).map(r => ({
      name: r.charAt(0).toUpperCase() + r.slice(1),
      value: r
    }))

    const propertyFields = this.renderPropertyFields()

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">New Category</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Name</label>
            <input type="text" name="category[name]" required placeholder="e.g. Cosmetics"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Resource Name</label>
            <select name="category[resource_name]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white">
              <option value="">Select Resource</option>
              ${resourceOptions.map(opt => `<option value="${opt.value}">${opt.name}</option>`).join('')}
            </select>
          </div>
        </div>

        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Description</label>
          <textarea name="category[description]" rows="2" placeholder="Optional description..."
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm text-slate-900 dark:text-white"></textarea>
        </div>

        ${propertyFields}

        <div class="flex justify-end gap-3 pt-2">
          <button type="button" data-action="click->modal#close"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg dark:text-slate-300 dark:hover:bg-slate-800 cursor-pointer">
            Cancel
          </button>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            Save Category
          </button>
        </div>
      </div>
    `

    return form({
      action: Helpers.company_categories_path(currentCompany().id),
      method: "POST",
      attributes: `
        class="p-8 bg-white dark:bg-slate-800 rounded-2xl w-full max-w-[75vw] shadow-2xl"
        data-action="submit->form#submit"
      `,
      html: fields
    })
  }

  renderPropertyFields() {
    const sections = []

    const stringFields = []
    for (let i = 1; i <= 20; i++) {
      const placeholder = i <= 3 ? `Label (e.g. ${['Skin Type', 'Key Ingredients', 'Formulation'][i-1]})` : 'Label'
      stringFields.push(`
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">String ${i}</label>
          <input type="text" name="category[property_string_${i}]" placeholder="${placeholder}"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-xs text-slate-900 dark:text-white">
        </div>
      `)
    }

    const textFields = []
    for (let i = 1; i <= 5; i++) {
      const placeholder = i === 1 ? 'Label (e.g. Full Description)' : 'Label'
      textFields.push(`
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">Text ${i}</label>
          <input type="text" name="category[property_text_${i}]" placeholder="${placeholder}"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-xs text-slate-900 dark:text-white">
        </div>
      `)
    }

    const integerFields = []
    for (let i = 1; i <= 20; i++) {
      const placeholder = i === 1 ? 'Label (e.g. Volume in ml)' : 'Label'
      integerFields.push(`
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">Integer ${i}</label>
          <input type="text" name="category[property_integer_${i}]" placeholder="${placeholder}"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-xs text-slate-900 dark:text-white">
        </div>
      `)
    }

    const decimalFields = []
    for (let i = 1; i <= 10; i++) {
      const placeholder = i === 1 ? 'Label (e.g. Weight in Grams)' : 'Label'
      decimalFields.push(`
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">Decimal ${i}</label>
          <input type="text" name="category[property_decimal_${i}]" placeholder="${placeholder}"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-xs text-slate-900 dark:text-white">
        </div>
      `)
    }

    const booleanFields = []
    for (let i = 1; i <= 20; i++) {
      const placeholder = i === 1 ? 'Label (e.g. Is Organic)' : 'Label'
      booleanFields.push(`
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">Boolean ${i}</label>
          <input type="text" name="category[property_boolean_${i}]" placeholder="${placeholder}"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-xs text-slate-900 dark:text-white">
        </div>
      `)
    }

    const datetimeFields = []
    for (let i = 1; i <= 10; i++) {
      const placeholder = i === 1 ? 'Label (e.g. Start Date)' : 'Label'
      datetimeFields.push(`
        <div class="space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase">DateTime ${i}</label>
          <input type="text" name="category[property_datetime_${i}]" placeholder="${placeholder}"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-xs text-slate-900 dark:text-white">
        </div>
      `)
    }

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-4">
        <h3 class="text-sm font-bold text-slate-700 dark:text-slate-300 mb-4">Property String Fields (1-20)</h3>
        <p class="text-xs text-slate-500 dark:text-slate-400 mb-4">Define what each property_string column represents in the UI</p>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${stringFields.join('')}
        </div>
      </div>
    `)

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h3 class="text-sm font-bold text-slate-700 dark:text-slate-300 mb-4">Property Text Fields (1-5)</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          ${textFields.join('')}
        </div>
      </div>
    `)

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h3 class="text-sm font-bold text-slate-700 dark:text-slate-300 mb-4">Property Integer Fields (1-20)</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${integerFields.join('')}
        </div>
      </div>
    `)

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h3 class="text-sm font-bold text-slate-700 dark:text-slate-300 mb-4">Property Decimal Fields (1-10)</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${decimalFields.join('')}
        </div>
      </div>
    `)

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h3 class="text-sm font-bold text-slate-700 dark:text-slate-300 mb-4">Property Boolean Fields (1-20)</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${booleanFields.join('')}
        </div>
      </div>
    `)

    sections.push(`
      <div class="border-t border-slate-200 dark:border-gray-800 pt-6">
        <h3 class="text-sm font-bold text-slate-700 dark:text-slate-300 mb-4">Property DateTime Fields (1-10)</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          ${datetimeFields.join('')}
        </div>
      </div>
    `)

    return sections.join('')
  }
}