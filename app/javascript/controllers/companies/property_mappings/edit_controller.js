import Companies_LayoutController from "controllers/companies/layout_controller"

// Property Mapping editor.
// Type-first property picker (no raw property_* keys in the UI), expandable
// per-type Setup panels, enum choice editor, and advanced extra columns.
// Depends on BE: Companies::PropertyMappingsController#show (JSON hydration),
//               Companies::PropertyMappingsController#update (form PATCH +
//               metadata normalization).
// Docs: docs/CATEGORY_DYNAMIC_SCHEMA.md
export default class Companies_PropertyMappings_EditController extends Companies_LayoutController {
  /** @type {any | null} */
  mapping = null

  /** @type {Array<object>} */
  propertyMetadata = []

  /** @type {Array<object>} */
  extraColumns = []

  /** @type {string | null} */
  expandedKey = null

  /** @type {string | null} */
  newPropertyType = null

  /** @type {string | null} */
  newExtraType = "string"

  /** Keys freed in this editing session so they are not reused before saving. */
  /** @type {string[]} */
  sessionUsedKeys = []

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const mappingId = pathParts[4]
    const companyId = pathParts[2]

    try {
      const response = await fetchJson(`${Helpers.company_property_mapping_path(companyId, mappingId)}.json`)
      this.mapping = response.property_mapping
      this.propertyMetadata = (this.mapping?.metadata?.properties || []).map((entry) => ({ ...entry }))
      this.extraColumns = (this.mapping?.metadata?.extra_columns || []).map((entry) => ({ ...entry }))
      this.newPropertyType = this.defaultNewPropertyType()

      poll(() => {
        if (this.hasContentTarget) {
          this.renderContent()
          return true
        }
        return false
      })
    } catch (error) {
      const detail = error.errors?.join(", ") || error.message
      poll(() => {
        if (this.hasContentTarget) {
          this.contentTarget.innerHTML = `<div class="p-8 text-center text-danger">${translate("Failed to load property mapping.")}${detail ? ` ${escapeHtml(detail)}` : ""}</div>`
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

    const fields = `
      <input type="hidden" name="property_mapping[metadata][properties_submitted]" value="1">
      <input type="hidden" name="property_mapping[metadata][extra_columns_submitted]" value="1">

      <div class="space-y-6">
        <div>
          <h2 class="text-xl font-bold text-foreground">${translate("Edit Property Mapping")}</h2>
          <p class="mt-1 text-sm text-muted-foreground">${translate("Define the extra fields your team can fill in for this category. The storage key is assigned automatically — you only choose a type and a display name.")}</p>
        </div>

        ${this.helpCardHTML()}
        ${this.mappingDetailsHTML(m)}
        ${this.propertiesSectionHTML()}
        ${this.extraColumnsSectionHTML()}

        <div class="flex flex-col-reverse gap-3 border-t border-line pt-6 sm:flex-row sm:justify-end">
          <a href="${Helpers.company_property_mapping_path(companyId, m.id)}"
            class="inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted cursor-pointer"
            ${tooltip(translate("Leave without saving. Unsaved changes are lost."))}>
            ${translate("Cancel")}
          </a>
          <button type="submit"
            class="inline-flex items-center justify-center gap-2 rounded-lg bg-primary px-6 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90 cursor-pointer"
            ${tooltip(translate("Applies all property, setup, and extra column changes. Table columns are updated automatically."))}>
            <span class="material-symbols-outlined text-[18px]!">save</span>
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
          attributes: `class="p-6 bg-card rounded-xl border border-line" data-turbo="false" novalidate data-action="submit->${this.identifier}#handleSubmit"`,
          html: fields
        })}
      </div>
    `
  }

  helpCardHTML() {
    return `
      <div class="rounded-xl border border-line bg-muted/40 p-4">
        <div class="flex items-start gap-3">
          <div class="flex size-9 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
            <span class="material-symbols-outlined text-[20px]!">help</span>
          </div>
          <div class="min-w-0 flex-1">
            <h3 class="text-sm font-bold text-foreground">${translate("How properties work")}</h3>
            <p class="mt-1 text-sm text-muted-foreground">${translate("Properties are extra fields for this category. Your team fills them in when creating or editing records. Pick a type, give it a clear name, and configure choices if needed.")}</p>

            <div class="mt-3 grid gap-2 sm:grid-cols-3">
              ${this.helpStepHTML("1", "Add a property", "Choose a type. The storage key is assigned automatically.")}
              ${this.helpStepHTML("2", "Name it", "Use words your team understands, e.g. Skin type or Volume (ml).")}
              ${this.helpStepHTML("3", "Configure it", "Add choices, limits, or display options. Nothing is saved until you click Save Changes.")}
            </div>

            <p class="mt-3 text-xs text-muted-foreground">
              <span class="font-bold text-foreground">${translate("Example")}:</span>
              ${translate("Choice list “Membership tier” with 1 = Gold, 2 = Silver, 3 = Bronze.")}
            </p>
          </div>
        </div>
      </div>
    `
  }

  helpStepHTML(number, title, description) {
    return `
      <div class="rounded-lg border border-line bg-card p-3">
        <div class="flex items-center gap-2">
          <span class="flex size-5 items-center justify-center rounded-full bg-primary/10 text-[10px] font-black text-primary">${number}</span>
          <p class="text-xs font-bold text-foreground">${translate(title)}</p>
        </div>
        <p class="mt-1 text-xs text-muted-foreground">${translate(description)}</p>
      </div>
    `
  }

  mappingDetailsHTML(m) {
    const categoryName = currentCategories().find((category) => category.id === m.category_id)?.name || ""

    return `
      <div class="border-t border-line pt-6">
        <div class="mb-4 flex items-center gap-2">
          <h3 class="text-sm font-bold uppercase tracking-wider text-muted-foreground">${translate("Mapping details")}</h3>
          <span class="inline-flex cursor-help text-muted-foreground" ${tooltip(translate("These details identify the mapping. The category and resource are fixed after creation."))}>
            <span class="material-symbols-outlined text-[16px]!">info</span>
          </span>
        </div>

        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div class="space-y-1 sm:col-span-2">
            <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground"
              ${tooltip(translate("A short internal name for this configuration. Example: Cosmetics mapping."))}
            >${translate("Mapping name")}</label>
            <input type="text" name="property_mapping[name]" value="${escapeHtml(m.name || "")}" required
              class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary outline-none"
              ${tooltip(translate("A short internal name for this configuration. Example: Cosmetics mapping."))}>
          </div>

          <div class="space-y-1 sm:col-span-2">
            <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground"
              ${tooltip(translate("Optional note for admins. This is not shown in tables or forms."))}
            >${translate("Description")}</label>
            <textarea name="property_mapping[description]" rows="2"
              class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary outline-none"
              ${tooltip(translate("Optional note for admins. This is not shown in tables or forms."))}>${escapeHtml(m.description || "")}</textarea>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground"
              ${tooltip(translate("Fixed for this mapping. To use a different category, create a new property mapping."))}
            >${translate("Category")}</label>
            <input type="text" value="${escapeHtml(categoryName)}" disabled
              class="w-full rounded-lg border border-line bg-background px-3 py-2 text-sm text-muted-foreground"
              ${tooltip(translate("Fixed for this mapping. To use a different category, create a new property mapping."))}>
            <input type="hidden" name="property_mapping[category_id]" value="${escapeHtml(m.category_id)}">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground"
              ${tooltip(translate("Fixed for this mapping. The category determines which records these properties belong to."))}
            >${translate("Resource")}</label>
            <input type="text" value="${escapeHtml(m.resource_name || "")}" disabled
              class="w-full rounded-lg border border-line bg-background px-3 py-2 text-sm text-muted-foreground"
              ${tooltip(translate("Fixed for this mapping. The category determines which records these properties belong to."))}>
            <input type="hidden" name="property_mapping[resource_name]" value="${escapeHtml(m.resource_name || "")}">
          </div>
        </div>
      </div>
    `
  }

  propertiesSectionHTML() {
    return `
      <div class="border-t border-line pt-6">
        <div class="mb-4 flex flex-col gap-1 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h3 class="text-sm font-bold uppercase tracking-wider text-muted-foreground">${translate("Property Fields")}</h3>
            <p class="mt-1 text-xs text-muted-foreground">${translate("Fields shown in tables and forms for this category. The storage key is assigned automatically and never shown.")}</p>
          </div>
          <span class="inline-flex items-center gap-1 self-start rounded-full border border-line bg-muted px-2.5 py-1 text-[11px] font-bold text-muted-foreground sm:self-auto"
            ${tooltip(translate("Each property uses one typed storage slot. The slot name stays hidden."))}>
            <span class="material-symbols-outlined text-[14px]!">database</span>
            ${this.propertyMetadata.length} ${translate("of")} ${Helpers.PROPERTY_SLOTS.length}
          </span>
        </div>

        <div class="overflow-x-auto rounded-lg border border-line">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="border-b border-line bg-muted text-xs text-muted-foreground">
                <th class="px-4 py-3 font-medium"
                  ${tooltip(translate("The name your team sees in tables, forms, and reports. Use clear words, e.g. Skin type or Volume (ml)."))}
                >${translate("Display Name")}</th>
                <th class="px-4 py-3 font-medium"
                  ${tooltip(translate("Controls what values this property accepts. To change a type, remove the property and add a new one."))}
                >${translate("Type")}</th>
                <th class="px-4 py-3 font-medium"
                  ${tooltip(translate("Extra configuration for this property. For a choice list, this is where you define the choices."))}
                >${translate("Setup")}</th>
                <th class="px-4 py-3 text-right font-medium"
                  ${tooltip(translate("Remove this property. The change is applied when you click Save Changes."))}
                >${translate("Actions")}</th>
              </tr>
            </thead>
            <tbody id="property-fields-body">
              ${this.propertyRowsHTML()}
            </tbody>
          </table>
        </div>

        <div id="add-property-area">
          ${this.addPropertyAreaHTML()}
        </div>
      </div>
    `
  }

  propertyRowsHTML() {
    if (this.propertyMetadata.length === 0) {
      return `
        <tr>
          <td colspan="4" class="px-4 py-10 text-center">
            <span class="material-symbols-outlined text-3xl text-muted-foreground">inventory_2</span>
            <p class="mt-2 text-sm font-semibold text-foreground">${translate("No properties yet")}</p>
            <p class="mt-1 text-xs text-muted-foreground">${translate("Add your first property below to start collecting extra information for this category.")}</p>
          </td>
        </tr>
      `
    }

    return this.propertyMetadata.map((entry, index) => (
      this.propertyRowHTML(entry, index) + this.propertySettingsRowHTML(entry, index)
    )).join("")
  }

  propertyRowHTML(entry, index) {
    const uiType = Helpers.uiTypeForEntry(entry)
    const expanded = this.expandedKey === entry.key
    const summary = Helpers.propertySettingsSummary(entry)
    const configureLabel = uiType === "enum" ? translate("Edit choices") : translate("Configure")

    return `
      <tr class="border-b border-line align-top last:border-0" data-property-key="${escapeHtml(entry.key)}">
        <td class="px-4 py-3">
          <input type="hidden" name="property_mapping[metadata][properties][${index}][key]" value="${escapeHtml(entry.key)}">
          <input type="hidden" name="property_mapping[metadata][properties][${index}][type]" value="${escapeHtml(entry.type || Helpers.storageTypeFor(uiType))}">
          ${uiType === "enum" ? `<input type="hidden" name="property_mapping[metadata][properties][${index}][input_type]" value="select">` : ""}
          <input type="text" name="property_mapping[metadata][properties][${index}][name]" value="${escapeHtml(entry.name || "")}" required
            data-property-field="name"
            placeholder="${translate("e.g. Skin type")}"
            class="w-full min-w-[180px] rounded-lg border border-line bg-card px-3 py-2 text-sm font-medium text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"
            ${tooltip(translate("The name your team sees in tables, forms, and reports. Example: Skin type or Volume (ml)."))}>
        </td>

        <td class="px-4 py-3">
          <span class="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2.5 py-1 text-xs font-bold text-primary"
            ${tooltip(Helpers.propertyTypeTooltip(uiType))}>
            <span class="material-symbols-outlined text-[14px]!">${Helpers.propertyTypeIcon(uiType)}</span>
            ${Helpers.propertyTypeLabel(uiType)}
          </span>
        </td>

        <td class="px-4 py-3">
          <div class="flex flex-col items-start gap-1">
            <span class="text-xs text-muted-foreground">${escapeHtml(summary)}</span>
            <button type="button"
              data-action="click->${this.identifier}#toggleSettings"
              data-key="${escapeHtml(entry.key)}"
              aria-expanded="${expanded ? "true" : "false"}"
              class="inline-flex items-center gap-1 rounded-lg px-2 py-1 text-xs font-bold text-primary hover:bg-primary/10 cursor-pointer"
              ${tooltip(translate("Open the setup panel for this property."))}>
              <span class="material-symbols-outlined text-[15px]!">tune</span>
              ${configureLabel}
            </button>
          </div>
        </td>

        <td class="px-4 py-3 text-right">
          <button type="button"
            data-action="click->${this.identifier}#removeProperty"
            data-key="${escapeHtml(entry.key)}"
            class="inline-flex items-center justify-center rounded-lg p-2 text-danger hover:bg-danger/10 cursor-pointer"
            ${tooltip(translate("Remove this property. Existing data stays in the database but will no longer be shown. The change is applied when you save."))}>
            <span class="material-symbols-outlined text-[18px]!">delete</span>
          </button>
        </td>
      </tr>
    `
  }

  propertySettingsRowHTML(entry, index) {
    const expanded = this.expandedKey === entry.key

    return `
      <tr class="border-b border-line bg-muted/30 last:border-0 ${expanded ? "" : "hidden"}"
        data-property-settings-row="${escapeHtml(entry.key)}">
        <td colspan="4" class="px-4 py-4">
          ${this.propertySettingsPanelHTML(entry, index)}
        </td>
      </tr>
    `
  }

  propertySettingsPanelHTML(entry, index) {
    const uiType = Helpers.uiTypeForEntry(entry)

    return `
      <div class="rounded-lg border border-line bg-card p-4" data-property-settings="${escapeHtml(entry.key)}">
        <div class="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div class="flex items-center gap-2">
            <span class="material-symbols-outlined text-[18px]! text-muted-foreground">${Helpers.propertyTypeIcon(uiType)}</span>
            <div>
              <h4 class="text-sm font-bold text-foreground">${translate("Settings for")} ${escapeHtml(entry.name || translate("this property"))}</h4>
              <p class="text-xs text-muted-foreground">${Helpers.propertyTypeLabel(uiType)}</p>
            </div>
          </div>
          <button type="button"
            data-action="click->${this.identifier}#closeSettings"
            data-key="${escapeHtml(entry.key)}"
            class="inline-flex items-center gap-1 self-start rounded-lg px-2 py-1 text-xs font-bold text-muted-foreground hover:bg-muted cursor-pointer"
            ${tooltip(translate("Hide this setup panel. Your changes are kept until you save or cancel."))}>
            <span class="material-symbols-outlined text-[15px]!">keyboard_arrow_up</span>
            ${translate("Done")}
          </button>
        </div>

        ${uiType === "enum" ? this.enumSettingsHTML(entry, index) : this.standardSettingsHTML(entry, index, uiType)}

        <p class="mt-3 flex items-start gap-1 text-[11px] text-muted-foreground">
          <span class="material-symbols-outlined text-[14px]!">info</span>
          ${translate("These settings are saved with the property. They are used by forms that support them.")}
        </p>
      </div>
    `
  }

  standardSettingsHTML(entry, index, uiType) {
    const settings = Helpers.propertySettingsFor(uiType)
    if (settings.length === 0) {
      return `<p class="text-sm text-muted-foreground">${translate("No extra settings")}</p>`
    }

    return `
      <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
        ${settings.map((setting) => this.settingInputHTML(setting, entry, index)).join("")}
      </div>
    `
  }

  settingInputHTML(setting, entry, index) {
    const name = `property_mapping[metadata][properties][${index}][${setting.key}]`
    const rawValue = entry[setting.key]
    const value = rawValue === undefined || rawValue === null ? "" : rawValue
    const inputClass = "w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"
    const labelTooltip = tooltip(translate(setting.tooltip))

    let control = ""

    if (setting.kind === "select") {
      control = `
        <select name="${name}" data-setting="${setting.key}"
          class="${inputClass}" ${labelTooltip}>
          ${(setting.options || []).map((option) => `
            <option value="${escapeHtml(option.value)}" ${String(value) === String(option.value) ? "selected" : ""}>${translate(option.label)}</option>
          `).join("")}
        </select>
      `
    } else if (setting.kind === "number") {
      control = `
        <input type="number" name="${name}" data-setting="${setting.key}"
          value="${escapeHtml(value)}"
          step="${setting.step || "1"}"
          ${setting.min !== undefined ? `min="${setting.min}"` : ""}
          ${setting.max !== undefined ? `max="${setting.max}"` : ""}
          placeholder="${translate(setting.placeholder || "")}"
          class="${inputClass}" ${labelTooltip}>
      `
    } else if (setting.kind === "datetime-local") {
      control = `
        <input type="datetime-local" name="${name}" data-setting="${setting.key}"
          value="${escapeHtml(this.datetimeLocalValue(value))}"
          class="${inputClass}" ${labelTooltip}>
      `
    } else {
      control = `
        <input type="text" name="${name}" data-setting="${setting.key}"
          value="${escapeHtml(value)}"
          placeholder="${translate(setting.placeholder || "")}"
          class="${inputClass}" ${labelTooltip}>
      `
    }

    return `
      <div class="space-y-1">
        <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground"
          ${labelTooltip}>${translate(setting.label)}</label>
        ${control}
      </div>
    `
  }

  enumSettingsHTML(entry, index) {
    const options = Helpers.enumOptionsFor(entry)
    const lastOption = options.length <= 1
    const defaultOptions = options.map((option) => `
      <option value="${escapeHtml(option.value)}" ${String(entry.default) === String(option.value) ? "selected" : ""}>${escapeHtml(option.label || option.value)}</option>
    `).join("")

    return `
      <div class="space-y-4">
        <div class="rounded-lg border border-line bg-muted/30 p-3">
          <div class="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p class="text-xs font-bold uppercase tracking-wider text-muted-foreground"
                ${tooltip(translate("Define the options users can pick. The number is stored in the database; the label is shown to users."))}
              >${translate("Choices")}</p>
              <p class="text-[11px] text-muted-foreground">${translate("Example: 1 = Gold, 2 = Silver, 3 = Bronze.")}</p>
            </div>
            <button type="button"
              data-action="click->${this.identifier}#addEnumOption"
              data-key="${escapeHtml(entry.key)}"
              class="inline-flex items-center gap-1 self-start rounded-lg bg-primary px-3 py-1.5 text-xs font-bold text-primary-foreground hover:bg-primary/90 cursor-pointer"
              ${tooltip(translate("Adds another choice. The next number is filled in automatically."))}>
              <span class="material-symbols-outlined text-[15px]!">add</span>
              ${translate("Add option")}
            </button>
          </div>

          <div class="mt-3 grid grid-cols-[88px_1fr_auto] gap-2 px-1 text-[10px] font-bold uppercase tracking-wider text-muted-foreground">
            <span>${translate("Value")}</span>
            <span>${translate("Label")}</span>
            <span></span>
          </div>

          <div class="mt-1 space-y-2">
            ${options.length === 0 ? `
              <p class="rounded-lg border border-dashed border-line bg-card px-3 py-4 text-center text-xs text-muted-foreground">${translate("No choices yet")}</p>
            ` : options.map((option, optionIndex) => this.enumOptionRowHTML(entry, index, option, optionIndex, lastOption)).join("")}
          </div>
        </div>

        <div class="space-y-1">
          <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground"
            ${tooltip(translate("Optional. The choice selected automatically on new records."))}
          >${translate("Default choice")}</label>
          <select name="property_mapping[metadata][properties][${index}][default]" data-setting="default"
            class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary outline-none"
            ${tooltip(translate("Optional. The choice selected automatically on new records."))}>
            <option value="">${translate("No default")}</option>
            ${defaultOptions}
          </select>
        </div>
      </div>
    `
  }

  enumOptionRowHTML(entry, index, option, optionIndex, lastOption) {
    return `
      <div class="grid grid-cols-[88px_1fr_auto] items-center gap-2" data-enum-option-row>
        <input type="number" step="1"
          name="property_mapping[metadata][properties][${index}][options][${optionIndex}][value]"
          value="${escapeHtml(option.value ?? "")}"
          data-option-field="value"
          placeholder="1"
          class="w-full rounded-lg border border-line bg-card px-2 py-1.5 text-sm text-foreground focus:ring-2 focus:ring-primary outline-none"
          ${tooltip(translate("The whole number stored in the database. It must be unique for this property. Example: 1."))}>

        <input type="text"
          name="property_mapping[metadata][properties][${index}][options][${optionIndex}][label]"
          value="${escapeHtml(option.label || "")}"
          data-option-field="label"
          placeholder="${translate("e.g. Gold")}"
          class="w-full rounded-lg border border-line bg-card px-2 py-1.5 text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"
          ${tooltip(translate("The text users see. Example: Gold."))}>

        <button type="button"
          data-action="click->${this.identifier}#removeEnumOption"
          data-key="${escapeHtml(entry.key)}"
          data-option-index="${optionIndex}"
          ${lastOption ? "disabled" : ""}
          class="inline-flex items-center justify-center rounded-lg p-2 ${lastOption ? "cursor-not-allowed text-muted-foreground/40" : "text-danger hover:bg-danger/10 cursor-pointer"}"
          ${tooltip(translate(lastOption ? "At least one choice is required. Edit this choice instead." : "Remove this choice. Existing records keep their stored number."))}>
          <span class="material-symbols-outlined text-[17px]!">delete</span>
        </button>
      </div>
    `
  }

  addPropertyAreaHTML() {
    const types = Helpers.PROPERTY_TYPES.map((type) => ({
      ...type,
      remaining: Helpers.slotsRemaining(type.value, this.propertyMetadata, this.usedPropertyKeys())
    }))
    const available = types.filter((type) => type.remaining > 0)

    if (available.length === 0) {
      const message = this.propertyMetadata.length === 0
        ? translate("All property slots have been used before. Create a new category mapping to start fresh.")
        : translate("All property slots are in use.")

      return `
        <div class="mt-4 rounded-lg border border-line bg-muted p-4 text-sm text-muted-foreground"
          ${tooltip(message)}>
          ${message}
        </div>
      `
    }

    const selectedType = available.some((type) => type.value === this.newPropertyType)
      ? this.newPropertyType
      : available[0].value
    this.newPropertyType = selectedType

    return `
      <div class="mt-4 rounded-lg border border-dashed border-line bg-muted/30 p-4">
        <div class="flex flex-col gap-3 sm:flex-row sm:items-end">
          <div class="min-w-0 flex-1 space-y-1">
            <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground"
              ${tooltip(translate("Pick what kind of value this property stores. The storage key is assigned automatically."))}
            >${translate("Property type")}</label>
            <select id="new-property-type"
              data-action="change->${this.identifier}#onNewPropertyTypeChange"
              class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary outline-none"
              ${tooltip(translate("Choose the type of value this new property will store."))}>
              ${types.map((type) => `
                <option value="${type.value}" ${type.remaining === 0 ? "disabled" : ""} ${type.value === selectedType ? "selected" : ""}>${Helpers.propertyTypeLabel(type.value)}${type.remaining === 0 ? ` — ${translate("full")}` : ""}</option>
              `).join("")}
            </select>
            <p id="new-property-hint" class="text-xs text-muted-foreground">${this.addPropertyHintHTML(selectedType)}</p>
          </div>

          <button type="button"
            data-action="click->${this.identifier}#addProperty"
            class="inline-flex items-center justify-center gap-2 rounded-lg bg-primary px-4 py-2 text-sm font-bold text-primary-foreground hover:bg-primary/90 cursor-pointer"
            ${tooltip(translate("Adds this property to the list. Nothing is saved until you click Save Changes."))}>
            <span class="material-symbols-outlined text-[18px]!">add</span>
            ${translate("Add Property")}
          </button>
        </div>
      </div>
    `
  }

  addPropertyHintHTML(type) {
    const remaining = Helpers.slotsRemaining(type, this.propertyMetadata, this.usedPropertyKeys())
    const total = Helpers.propertySlotsForType(type).length
    return `${Helpers.propertyTypeDescription(type)} ${Helpers.propertyTypeExample(type)} ${remaining} ${translate("of")} ${total} ${translate("slots left")}.`
  }

  extraColumnsSectionHTML() {
    return `
      <div class="border-t border-line pt-6">
        <div class="mb-4 flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <h3 class="text-sm font-bold uppercase tracking-wider text-muted-foreground">${translate("Extra Columns (advanced)")}</h3>
            <p class="mt-1 text-xs text-muted-foreground">${translate("Advanced display-only columns outside the normal dynamic slots. They are not stored on records or indexed for search.")}</p>
          </div>
          <span class="inline-flex cursor-help items-center gap-1 self-start rounded-full border border-line bg-muted px-2.5 py-1 text-[11px] font-bold text-muted-foreground"
            ${tooltip(translate("Extra columns can be shown in tables but do not store record data."))}>
            <span class="material-symbols-outlined text-[14px]!">info</span>
            ${translate("Advanced")}
          </span>
        </div>

        <div class="overflow-x-auto rounded-lg border border-line">
          <table class="w-full text-left border-collapse">
            <thead>
              <tr class="border-b border-line bg-muted text-xs text-muted-foreground">
                <th class="px-4 py-3 font-medium"
                  ${tooltip(translate("The name shown in the table. Extra columns do not store record values."))}
                >${translate("Display Name")}</th>
                <th class="px-4 py-3 font-medium"
                  ${tooltip(translate("How the extra column is displayed. It does not store record values."))}
                >${translate("Type")}</th>
                <th class="px-4 py-3 text-right font-medium"
                  ${tooltip(translate("Remove this extra column. The change is applied when you save."))}
                >${translate("Actions")}</th>
              </tr>
            </thead>
            <tbody id="extra-columns-body">
              ${this.extraColumnRowsHTML()}
            </tbody>
          </table>
        </div>

        <div id="add-extra-column-area">
          ${this.addExtraColumnAreaHTML()}
        </div>
      </div>
    `
  }

  extraColumnRowsHTML() {
    if (this.extraColumns.length === 0) {
      return `
        <tr>
          <td colspan="3" class="px-4 py-8 text-center text-sm text-muted-foreground">${translate("No extra columns.")}</td>
        </tr>
      `
    }

    return this.extraColumns.map((entry, index) => this.extraColumnRowHTML(entry, index)).join("")
  }

  extraColumnRowHTML(entry, index) {
    return `
      <tr class="border-b border-line last:border-0" data-extra-row="${index}">
        <td class="px-4 py-3">
          <input type="hidden" name="property_mapping[metadata][extra_columns][${index}][key]" value="${escapeHtml(entry.key || "")}">
          <input type="text" name="property_mapping[metadata][extra_columns][${index}][name]" value="${escapeHtml(entry.name || "")}"
            data-extra-field="name"
            placeholder="${translate("e.g. Internal note")}"
            class="w-full min-w-[180px] rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary outline-none placeholder:text-muted-foreground"
            ${tooltip(translate("The name shown in the table for this advanced column."))}>
        </td>
        <td class="px-4 py-3">
          <select name="property_mapping[metadata][extra_columns][${index}][type]" data-extra-field="type"
            class="w-full min-w-[150px] rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary outline-none"
            ${tooltip(translate("How the extra column is displayed. It does not store record values."))}>
            ${Helpers.EXTRA_COLUMN_TYPES.map((type) => `
              <option value="${type.value}" ${type.value === (entry.type || "string") ? "selected" : ""}>${Helpers.propertyTypeLabel(type.value)}</option>
            `).join("")}
          </select>
        </td>
        <td class="px-4 py-3 text-right">
          <button type="button"
            data-action="click->${this.identifier}#removeExtraColumn"
            data-index="${index}"
            class="inline-flex items-center justify-center rounded-lg p-2 text-danger hover:bg-danger/10 cursor-pointer"
            ${tooltip(translate("Remove this extra column. The change is applied when you save."))}>
            <span class="material-symbols-outlined text-[18px]!">delete</span>
          </button>
        </td>
      </tr>
    `
  }

  addExtraColumnAreaHTML() {
    return `
      <div class="mt-4 rounded-lg border border-dashed border-line bg-muted/30 p-4">
        <div class="flex flex-col gap-3 sm:flex-row sm:items-end">
          <div class="min-w-0 flex-1 space-y-1">
            <label class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground"
              ${tooltip(translate("Extra columns are advanced. They are not stored on records or indexed for search."))}
            >${translate("Extra column type")}</label>
            <select id="new-extra-column-type"
              class="w-full rounded-lg border border-line bg-card px-3 py-2 text-sm text-foreground focus:ring-2 focus:ring-primary outline-none"
              ${tooltip(translate("Choose how the new extra column is displayed."))}>
              ${Helpers.EXTRA_COLUMN_TYPES.map((type) => `
                <option value="${type.value}" ${type.value === this.newExtraType ? "selected" : ""}>${Helpers.propertyTypeLabel(type.value)}</option>
              `).join("")}
            </select>
          </div>

          <button type="button"
            data-action="click->${this.identifier}#addExtraColumn"
            class="inline-flex items-center justify-center gap-2 rounded-lg border border-line bg-card px-4 py-2 text-sm font-bold text-foreground hover:bg-muted cursor-pointer"
            ${tooltip(translate("Adds an advanced display-only column. Nothing is saved until you click Save Changes."))}>
            <span class="material-symbols-outlined text-[18px]!">add</span>
            ${translate("Add Extra Column")}
          </button>
        </div>
      </div>
    `
  }

  usedPropertyKeys() {
    const saved = this.mapping?.metadata?.used_property_keys
    return [
      ...(Array.isArray(saved) ? saved : []),
      ...this.sessionUsedKeys
    ]
  }

  defaultNewPropertyType() {
    const type = Helpers.PROPERTY_TYPES.find((candidate) => (
      Helpers.slotsRemaining(candidate.value, this.propertyMetadata, this.usedPropertyKeys()) > 0
    ))
    return type?.value || null
  }

  onNewPropertyTypeChange(event) {
    this.newPropertyType = event.currentTarget.value
    const hint = document.getElementById("new-property-hint")
    if (hint) hint.innerHTML = this.addPropertyHintHTML(this.newPropertyType)
  }

  addProperty(event) {
    const select = event?.currentTarget?.parentElement?.querySelector("#new-property-type") || document.getElementById("new-property-type")
    const type = select?.value || this.newPropertyType
    if (!type) return

    this.captureDOMState()

    const slot = Helpers.nextAvailableSlot(type, this.propertyMetadata, this.usedPropertyKeys())
    if (!slot) {
      toast({ type: "error", message: translate("All slots for this type have been used. Remove a property or create a new category mapping.") })
      return
    }

    const entry = {
      key: slot.key,
      type: Helpers.storageTypeFor(type),
      name: ""
    }

    if (type === "enum") {
      entry.input_type = "select"
      entry.options = [{ value: 1, label: "" }]
    }

    this.propertyMetadata.push(entry)
    this.newPropertyType = type
    this.expandedKey = slot.key
    this.rerenderProperties()
    this.focusPropertyName(slot.key)
  }

  removeProperty(event) {
    const key = event.currentTarget.getAttribute("data-key")
    if (!key) return

    this.captureDOMState()
    this.propertyMetadata = this.propertyMetadata.filter((entry) => entry.key !== key)
    this.sessionUsedKeys.push(key)
    if (this.expandedKey === key) this.expandedKey = null
    this.rerenderProperties()
  }

  toggleSettings(event) {
    const key = event.currentTarget.getAttribute("data-key")
    if (!key) return

    const panel = document.querySelector(`[data-property-settings-row="${key}"]`)
    if (!panel) return

    const willOpen = panel.classList.contains("hidden")
    document.querySelectorAll("[data-property-settings-row]").forEach((row) => row.classList.add("hidden"))
    if (willOpen) panel.classList.remove("hidden")

    this.expandedKey = willOpen ? key : null
    document.querySelectorAll(`[data-action*="toggleSettings"][data-key="${key}"]`).forEach((button) => {
      button.setAttribute("aria-expanded", willOpen ? "true" : "false")
    })
  }

  closeSettings(event) {
    const key = event.currentTarget.getAttribute("data-key")
    const panel = key ? document.querySelector(`[data-property-settings-row="${key}"]`) : null
    if (panel) panel.classList.add("hidden")
    document.querySelectorAll(`[data-action*="toggleSettings"][data-key="${key}"]`).forEach((button) => {
      button.setAttribute("aria-expanded", "false")
    })
    this.expandedKey = null
  }

  addEnumOption(event) {
    const key = event.currentTarget.getAttribute("data-key")
    if (!key) return

    this.captureDOMState()
    const entry = this.propertyMetadata.find((candidate) => candidate.key === key)
    if (!entry) return

    if (!Array.isArray(entry.options)) entry.options = []
    entry.options.push({ value: Helpers.nextEnumValue(entry), label: "" })
    this.expandedKey = key
    this.rerenderProperties()

    const index = this.propertyMetadata.indexOf(entry)
    const optionIndex = entry.options.length - 1
    requestAnimationFrame(() => {
      const input = document.querySelector(`[name="property_mapping[metadata][properties][${index}][options][${optionIndex}][label]"]`)
      input?.focus()
    })
  }

  removeEnumOption(event) {
    const key = event.currentTarget.getAttribute("data-key")
    const optionIndex = Number.parseInt(event.currentTarget.getAttribute("data-option-index"), 10)
    if (!key || Number.isNaN(optionIndex)) return

    this.captureDOMState()
    const entry = this.propertyMetadata.find((candidate) => candidate.key === key)
    if (!entry || !Array.isArray(entry.options)) return

    if (entry.options.length <= 1) {
      toast({ type: "error", message: translate("At least one choice is required.") })
      return
    }

    const removed = entry.options[optionIndex]
    entry.options.splice(optionIndex, 1)
    if (removed && String(entry.default) === String(removed.value)) delete entry.default
    this.expandedKey = key
    this.rerenderProperties()
  }

  addExtraColumn(event) {
    const select = event?.currentTarget?.parentElement?.querySelector("#new-extra-column-type") || document.getElementById("new-extra-column-type")
    const type = select?.value || this.newExtraType || "string"

    this.captureDOMState()
    this.extraColumns.push({ key: "", name: "", type })
    this.newExtraType = type
    this.rerenderExtraColumns()
    this.focusExtraName(this.extraColumns.length - 1)
  }

  removeExtraColumn(event) {
    const index = Number.parseInt(event.currentTarget.getAttribute("data-index"), 10)
    if (Number.isNaN(index)) return

    this.captureDOMState()
    this.extraColumns.splice(index, 1)
    this.rerenderExtraColumns()
  }

  captureDOMState() {
    this.capturePropertyState()
    this.captureExtraState()
  }

  capturePropertyState() {
    this.propertyMetadata = this.propertyMetadata.map((entry) => {
      const row = document.querySelector(`[data-property-key="${entry.key}"]`)
      if (!row) return entry

      const updated = { ...entry }
      const nameInput = row.querySelector('[data-property-field="name"]')
      if (nameInput) updated.name = nameInput.value

      const panel = document.querySelector(`[data-property-settings="${entry.key}"]`)
      if (panel) {
        panel.querySelectorAll("[data-setting]").forEach((input) => {
          updated[input.dataset.setting] = input.value
        })

        if (Helpers.uiTypeForEntry(entry) === "enum") {
          updated.options = Array.from(panel.querySelectorAll("[data-enum-option-row]")).map((optionRow) => ({
            value: optionRow.querySelector('[data-option-field="value"]')?.value ?? "",
            label: optionRow.querySelector('[data-option-field="label"]')?.value ?? ""
          }))
        }
      }

      return updated
    })
  }

  captureExtraState() {
    this.extraColumns = this.extraColumns.map((entry, index) => {
      const row = document.querySelector(`[data-extra-row="${index}"]`)
      if (!row) return entry

      return {
        ...entry,
        name: row.querySelector('[data-extra-field="name"]')?.value ?? "",
        type: row.querySelector('[data-extra-field="type"]')?.value ?? entry.type
      }
    })
  }

  validate() {
    const errors = []
    const mappingName = document.querySelector('input[name="property_mapping[name]"]')
    if (!mappingName?.value.trim()) {
      errors.push(translate("Every mapping needs a name."))
    }

    this.propertyMetadata.forEach((entry) => {
      if (!String(entry.name || "").trim()) {
        errors.push(translate("Every property needs a display name."))
      }

      if (Helpers.uiTypeForEntry(entry) !== "enum") {
        if (this.isPresent(entry.min) && this.isPresent(entry.max) && Number(entry.min) > Number(entry.max)) {
          errors.push(translate("Minimum cannot be greater than maximum."))
        }

        if (this.isPresent(entry.precision)) {
          const precision = Number(entry.precision)
          if (!Number.isInteger(precision) || precision < 0 || precision > 4) {
            errors.push(translate("Decimal places must be a whole number between 0 and 4."))
          }
        }
        return
      }

      const options = Helpers.enumOptionsFor(entry)
      if (options.length === 0) {
        errors.push(translate("Every choice list needs at least one choice."))
        return
      }

      const values = []
      options.forEach((option) => {
        if (!this.isWholeNumber(option.value)) {
          errors.push(translate("Option values must be whole numbers."))
        } else {
          values.push(String(Number(option.value)))
        }

        if (!String(option.label || "").trim()) {
          errors.push(translate("Option labels are required."))
        }
      })

      if (new Set(values).size !== values.length) {
        errors.push(translate("Option values must be unique."))
      }

      if (this.isWholeNumber(entry.default) && !values.includes(String(Number(entry.default)))) {
        errors.push(translate("Default choice must match one of the choices."))
      }
    })

    this.extraColumns.forEach((entry) => {
      if (!String(entry.name || "").trim()) {
        errors.push(translate("Every extra column needs a display name."))
      }
    })

    return [...new Set(errors)]
  }

  handleSubmit(event) {
    event.preventDefault()
    this.captureDOMState()

    const errors = this.validate()
    if (errors.length > 0) {
      toast({ type: "error", message: errors.join(". ") })
      this.focusFirstInvalid()
      return
    }

    event.target.submit()
  }

  focusFirstInvalid() {
    const mappingName = document.querySelector('input[name="property_mapping[name]"]')
    if (mappingName && !mappingName.value.trim()) {
      mappingName.focus()
      return
    }

    const blankPropertyName = Array.from(document.querySelectorAll('[data-property-field="name"]'))
      .find((input) => !input.value.trim())
    if (blankPropertyName) {
      blankPropertyName.focus()
      return
    }

    const blankOptionLabel = Array.from(document.querySelectorAll('[data-option-field="label"]'))
      .find((input) => !input.value.trim())
    blankOptionLabel?.focus()
  }

  isPresent(value) {
    return value !== undefined && value !== null && String(value).trim() !== ""
  }

  isWholeNumber(value) {
    return this.isPresent(value) && /^[+-]?\d+$/.test(String(value).trim())
  }

  datetimeLocalValue(value) {
    if (!value) return ""
    const match = String(value).match(/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2})/)
    return match ? match[1] : String(value)
  }

  rerenderProperties() {
    const tbody = document.getElementById("property-fields-body")
    if (tbody) tbody.innerHTML = this.propertyRowsHTML()

    const addArea = document.getElementById("add-property-area")
    if (addArea) addArea.innerHTML = this.addPropertyAreaHTML()
  }

  rerenderExtraColumns() {
    const tbody = document.getElementById("extra-columns-body")
    if (tbody) tbody.innerHTML = this.extraColumnRowsHTML()

    const addArea = document.getElementById("add-extra-column-area")
    if (addArea) addArea.innerHTML = this.addExtraColumnAreaHTML()
  }

  focusPropertyName(key) {
    requestAnimationFrame(() => {
      const row = document.querySelector(`[data-property-key="${key}"]`)
      row?.scrollIntoView({ block: "nearest" })
      row?.querySelector('[data-property-field="name"]')?.focus()
    })
  }

  focusExtraName(index) {
    requestAnimationFrame(() => {
      const row = document.querySelector(`[data-extra-row="${index}"]`)
      row?.scrollIntoView({ block: "nearest" })
      row?.querySelector('[data-extra-field="name"]')?.focus()
    })
  }
}
