// Shared form fields for the new/edit tax code modals.
// Depends on BE: Companies::TaxCodesController#create/update
export function taxCodeFormHTML({ taxCode = null } = {}) {
  const code = taxCode || {}
  const kind = code.kind || "vat"
  const inclusive = code.inclusive === true
  const rate = code.rate_percent ?? ""

  return `
    <div class="space-y-5">
      <div>
        <h2 class="text-xl font-bold text-foreground">${taxCode ? translate("Edit tax code") : translate("Add tax code")}</h2>
        <p class="text-sm text-muted-foreground mt-1">${translate("Tax codes are the rates you charge on products and services.")}</p>
      </div>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div class="space-y-1 sm:col-span-2">
          <label class="text-xs font-medium text-muted-foreground" for="tax_code_name">${translate("Name")}</label>
          <input id="tax_code_name" type="text" name="tax_code[name]" value="${escapeHtml(code.name || "")}" required
            placeholder="${translate("e.g. VAT 10%")}"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground" />
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground" for="tax_code_code">${translate("Code")}</label>
          <input id="tax_code_code" type="text" name="tax_code[code]" value="${escapeHtml(code.code || "")}"
            placeholder="VAT10" maxlength="32"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground" />
          <p class="text-[11px] text-muted-foreground">${translate("Short identifier used in reports. Leave blank to generate.")}</p>
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground" for="tax_code_kind">${translate("Tax type")}</label>
          <select id="tax_code_kind" name="tax_code[kind]"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
            <option value="vat" ${kind === "vat" ? "selected" : ""}>VAT</option>
            <option value="gst" ${kind === "gst" ? "selected" : ""}>GST</option>
            <option value="sales" ${kind === "sales" ? "selected" : ""}>${translate("Sales tax")}</option>
          </select>
        </div>

        <div class="space-y-1">
          <label class="text-xs font-medium text-muted-foreground" for="tax_code_rate">${translate("Tax rate (%)")}</label>
          <input id="tax_code_rate" type="number" name="tax_code[rate_percent]" value="${rate}" min="0" max="100" step="0.01" required
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground" />
        </div>

        <div class="space-y-1 sm:col-span-2">
          <label class="text-xs font-medium text-muted-foreground" for="tax_code_inclusive">${translate("Price treatment")}</label>
          <select id="tax_code_inclusive" name="tax_code[is_inclusive]"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">
            <option value="false" ${inclusive ? "" : "selected"}>${translate("Add this tax on top of the price")}</option>
            <option value="true" ${inclusive ? "selected" : ""}>${translate("Prices include this tax")}</option>
          </select>
          <p class="text-[11px] text-muted-foreground">${translate("Checkout uses this choice to decide whether tax is added to the total or already inside the price.")}</p>
        </div>

        <div class="space-y-1 sm:col-span-2">
          <label class="text-xs font-medium text-muted-foreground" for="tax_code_description">${translate("Description")}</label>
          <textarea id="tax_code_description" name="tax_code[description]" rows="2"
            class="w-full px-3 py-2 border border-line rounded-lg bg-card text-sm text-foreground">${escapeHtml(code.description || "")}</textarea>
        </div>
      </div>

      <div class="rounded-xl border border-line bg-muted p-3 text-[11px] text-muted-foreground space-y-1">
        <p class="font-semibold text-foreground">${translate("How the rate applies")}</p>
        <p>${translate("Added on top: a 100,000 price becomes 110,000 at 10%.")}</p>
        <p>${translate("Included: a 110,000 price contains 10,000 tax and 100,000 net.")}</p>
      </div>

      <div class="flex justify-end gap-3 pt-2">
        <button type="button" data-action="click->modal#close"
          class="px-4 py-2 text-sm font-medium text-muted-foreground hover:bg-muted rounded-lg">
          ${translate("Cancel")}
        </button>
        <button type="submit"
          class="px-6 py-2 bg-primary hover:bg-primary/90 text-primary-foreground rounded-lg font-bold text-sm">
          ${translate("Save tax code")}
        </button>
      </div>
    </div>
  `
}
