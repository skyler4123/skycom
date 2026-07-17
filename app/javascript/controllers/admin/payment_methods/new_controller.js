import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_PaymentMethods_NewController extends Admin_LayoutController {
  connect() {
    super.connect()

    poll(() => {
      if (this.hasContentTarget) {
        this.renderContent()
        return true
      }
      return false
    })
  }

  contentHTML() {
    const fields = `
      <div class="space-y-6">
        <h2 class="text-xl font-bold text-slate-900 dark:text-white">New Payment Method</h2>

        <div class="grid grid-cols-2 gap-4">
          <div class="col-span-2 space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Name</label>
            <input type="text" name="payment_method[name]" required placeholder="e.g. Credit Card"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Code</label>
            <input type="text" name="payment_method[code]" required placeholder="e.g. CREDIT_CARD"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm font-mono">
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Business Type</label>
            <select name="payment_method[business_type]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="b2c">B2C</option>
              <option value="b2b">B2B</option>
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Payment Mode</label>
            <select name="payment_method[payment_mode]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="">Select mode...</option>
              <option value="qr">QR Code</option>
              <option value="redirect">Redirect</option>
              <option value="cash">Cash</option>
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Country</label>
            <select name="payment_method[country]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="us">US</option>
              <option value="vn">VN</option>
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Strategy</label>
            <select name="payment_method[strategy]" required
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="">Select strategy...</option>
              <option value="cash">Cash</option>
              <option value="wallet_auto_debit">Wallet Auto-Debit</option>
              <option value="mock_qr_gateway">Mock QR Gateway</option>
              <option value="mock_redirect_gateway">Mock Redirect Gateway</option>
              <option value="stripe_gateway">Stripe Gateway</option>
              <option value="viet_qr_gateway">VietQR Gateway</option>
            </select>
          </div>

          <div class="space-y-1">
            <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Status</label>
            <select name="payment_method[lifecycle_status]"
              class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm">
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="archived">Archived</option>
            </select>
          </div>
        </div>

        <div class="col-span-2 space-y-1">
          <label class="text-[10px] font-bold text-slate-400 dark:text-slate-300 uppercase">Description</label>
          <textarea name="payment_method[description]" rows="3"
            class="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-sm"></textarea>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <a href="${Helpers.admin_payment_methods_path()}"
            class="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg cursor-pointer">
            Cancel
          </a>
          <button type="submit"
            class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-bold text-sm cursor-pointer">
            Save Payment Method
          </button>
        </div>
      </div>
    `

    return `
      <div class="p-6">
        ${form({
          action: Helpers.create_admin_payment_methods_path(),
          method: "POST",
          attributes: `class="p-6 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800" data-turbo="false"`,
          html: fields
        })}
      </div>
    `
  }
}
