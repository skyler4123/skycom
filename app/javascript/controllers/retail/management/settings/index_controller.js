import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Settings_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-col lg:flex-row gap-8">
          <div class="w-full lg:w-64 flex-shrink-0">
            <nav class="flex flex-col gap-1">
              <button
                class="flex items-center gap-3 px-4 py-3 rounded-lg bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 border border-blue-200 dark:border-blue-800/50 text-left font-medium">
                <span class="material-symbols-outlined">tune</span> General Settings
              </button>
              <button
                class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-white dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors text-left font-medium">
                <span class="material-symbols-outlined">person</span> Profile Settings
              </button>
              <button
                class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-white dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors text-left font-medium">
                <span class="material-symbols-outlined">security</span> Security & Privacy
              </button>
              <button
                class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-white dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors text-left font-medium">
                <span class="material-symbols-outlined">notifications</span> Notifications
              </button>
              <button
                class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-white dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors text-left font-medium">
                <span class="material-symbols-outlined">credit_card</span> Billing
              </button>
              <button
                class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-white dark:hover:bg-gray-800 text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors text-left font-medium">
                <span class="material-symbols-outlined">integration_instructions</span> Integrations
              </button>
            </nav>
          </div>

          <div class="flex-1">
            <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6 lg:p-8">
              <div class="mb-8 border-b border-gray-200 dark:border-gray-800 pb-6">
                <h2 class="text-xl font-bold text-gray-900 dark:text-white mb-2">General Settings</h2>
                <p class="text-gray-500 dark:text-gray-400 text-sm">Update your basic platform settings and appearance
                  preferences.</p>
              </div>

              <div class="space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Platform Name</label>
                    <input
                      class="w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none p-2.5"
                      type="text" value="Urban Trends" />
                    <p class="mt-1 text-xs text-gray-500">This name will appear on the dashboard and emails.</p>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Business
                      Email</label>
                    <input
                      class="w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none p-2.5"
                      type="email" value="admin@urbantrends.com" />
                  </div>
                </div>

                <div class="border-t border-gray-200 dark:border-gray-800 pt-6">
                  <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Regional Settings</h3>
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Language</label>
                      <select
                        class="w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none p-2.5">
                        <option>English (United States)</option>
                        <option>Spanish</option>
                        <option>French</option>
                        <option>German</option>
                      </select>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Time Zone</label>
                      <select
                        class="w-full rounded-lg border border-gray-300 dark:border-gray-700 bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 outline-none p-2.5">
                        <option>(GMT-08:00) Pacific Time</option>
                        <option>(GMT-05:00) Eastern Time</option>
                        <option>(GMT+00:00) London</option>
                        <option>(GMT+01:00) Paris</option>
                      </select>
                    </div>
                  </div>
                </div>

                <div class="border-t border-gray-200 dark:border-gray-800 pt-6">
                  <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Display & Access</h3>
                  <div class="space-y-4">
                    <div class="flex items-center justify-between">
                      <div>
                        <h4 class="text-sm font-medium text-gray-900 dark:text-white">Maintenance Mode</h4>
                        <p class="text-xs text-gray-500">Temporarily disable access to the platform for users.</p>
                      </div>
                      <label class="relative inline-flex items-center cursor-pointer">
                        <input class="sr-only peer" type="checkbox" value="" />
                        <div
                          class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600">
                        </div>
                      </label>
                    </div>
                    <div class="flex items-center justify-between">
                      <div>
                        <h4 class="text-sm font-medium text-gray-900 dark:text-white">Allow Public Registration</h4>
                        <p class="text-xs text-gray-500">Let new users sign up without an invitation.</p>
                      </div>
                      <label class="relative inline-flex items-center cursor-pointer">
                        <input checked="" class="sr-only peer" type="checkbox" value="" />
                        <div
                          class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600">
                        </div>
                      </label>
                    </div>
                    <div class="flex items-center justify-between">
                      <div>
                        <h4 class="text-sm font-medium text-gray-900 dark:text-white">Show System Notifications</h4>
                        <p class="text-xs text-gray-500">Display system-wide alerts to all logged-in users.</p>
                      </div>
                      <label class="relative inline-flex items-center cursor-pointer">
                        <input checked="" class="sr-only peer" type="checkbox" value="" />
                        <div
                          class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600">
                        </div>
                      </label>
                    </div>
                  </div>
                </div>

                <div class="flex items-center justify-end gap-3 pt-6 border-t border-gray-200 dark:border-gray-800">
                  <button
                    class="px-5 py-2.5 rounded-lg border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 font-medium hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors">
                    Cancel
                  </button>
                  <button
                    class="px-5 py-2.5 rounded-lg bg-blue-600 text-white font-medium hover:bg-blue-700 transition-colors shadow-sm">
                    Save Changes
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
    `
  }

}
