import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_PaymentMethods_EditController extends Admin_LayoutController {
  /** @type {Object | null} */ paymentMethod = null

  async connect() {
    super.connect()

    const pathParts = window.location.pathname.split("/")
    const id = pathParts[3]

    try {
      const response = await fetchJson(`${Helpers.edit_admin_payment_method_path(id)}.json`)
      this.paymentMethod = response.payment_method

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
          this.contentTarget.innerHTML = '<div class="p-8 text-center text-red-600">Failed to load payment method.</div>'
          return true
        }
        return false
      })
    }
  }

  contentHTML() {
    const pm = this.paymentMethod
    if (!pm) return '<div class="p-8 text-center">Payment method not found.</div>'

    const pathParts = window.location.pathname.split("/")
    const id = pathParts[3]

    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">Edit Payment Method</h2>
        <p class="text-sm text-slate-500">${pm.code}</p>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Name</label>
            <input type="text" name="payment_method[name]" value="${pm.name || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Code</label>
            <input type="text" name="payment_method[code]" value="${pm.code || ''}" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm font-mono">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Business Type</label>
            <select name="payment_method[business_type]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="b2c" ${pm.business_type === 'b2c' ? 'selected' : ''}>B2C</option>
              <option value="b2b" ${pm.business_type === 'b2b' ? 'selected' : ''}>B2B</option>
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Payment Mode</label>
            <select name="payment_method[payment_mode]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="qr" ${pm.payment_mode === 'qr' ? 'selected' : ''}>QR Code</option>
              <option value="redirect" ${pm.payment_mode === 'redirect' ? 'selected' : ''}>Redirect</option>
              <option value="cash" ${pm.payment_mode === 'cash' ? 'selected' : ''}>Cash</option>
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Country</label>
            <select name="payment_method[country]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="us" ${pm.country === 'us' ? 'selected' : ''}>US</option>
              <option value="vn" ${pm.country === 'vn' ? 'selected' : ''}>VN</option>
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Status</label>
            <select name="payment_method[lifecycle_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="active" ${pm.lifecycle_status === 'active' ? 'selected' : ''}>Active</option>
              <option value="inactive" ${pm.lifecycle_status === 'inactive' ? 'selected' : ''}>Inactive</option>
              <option value="archived" ${pm.lifecycle_status === 'archived' ? 'selected' : ''}>Archived</option>
            </select>
          </div>
        </div>

        <div class="col-span-2 space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Description</label>
          <textarea name="payment_method[description]" rows="3"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">${pm.description || ''}</textarea>
        </div>

        <div class="col-span-2 space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Gateway URL</label>
          <input type="url" name="payment_method[gateway_url]" value="${pm.gateway_url || ''}" placeholder="e.g. http://localhost:4000/api/v1/bank/redirect-session"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm font-mono">
          <p class="text-[10px] text-slate-400">Required for QR and Redirect modes. Leave blank for Cash.</p>
        </div>

        <div class="col-span-2 space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Secret Key</label>
          <input type="password" name="payment_method[secret_key]" value="${pm.secret_key || ''}" placeholder="e.g. sk_test_..."
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm font-mono">
          <p class="text-[10px] text-slate-400">Encrypted at rest. Leave blank for Cash methods.</p>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.admin_payment_methods_path()}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg cursor-pointer">
            Cancel
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            Save Changes
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-6">
        ${form({
          action: Helpers.admin_payment_method_path(id),
          method: "PATCH",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false" novalidate`,
          html: fields
        })}
      </div>
    `
  }
}
