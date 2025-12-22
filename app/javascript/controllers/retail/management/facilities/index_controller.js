import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Facilities_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-gray-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Facility
              Management</h1>
            <p class="text-gray-500 dark:text-gray-400 text-base font-normal leading-normal">Manage physical
              infrastructure, equipment, and maintenance schedules.</p>
          </div>
        </div>

        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 mb-6">
          <div class="flex flex-wrap items-center gap-3 w-full sm:w-auto">
            <div class="relative min-w-[140px]">
              <select
                class="form-select w-full pl-3 pr-8 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:ring-blue-600 focus:border-blue-600">
                <option>Branch</option>
                <option>HQ - Downtown</option>
                <option>Logistics Center</option>
                <option>North Retail Outlet</option>
                <option>East Retail Outlet</option>
              </select>
            </div>
            <div class="relative min-w-[140px]">
              <select
                class="form-select w-full pl-3 pr-8 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:ring-blue-600 focus:border-blue-600">
                <option>Facility Type</option>
                <option>Room</option>
                <option>Equipment</option>
                <option>Vehicle</option>
                <option>Infrastructure</option>
              </select>
            </div>
            <div class="relative min-w-[140px]">
              <select
                class="form-select w-full pl-3 pr-8 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:ring-blue-600 focus:border-blue-600">
                <option>Status</option>
                <option>Available</option>
                <option>In Use</option>
                <option>Maintenance</option>
                <option>Out of Order</option>
              </select>
            </div>
          </div>
          <button
            class="flex items-center justify-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm shadow-sm whitespace-nowrap">
            <span class="material-symbols-outlined text-[20px]">add</span>
            Add New Facility
          </button>
        </div>

        <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 flex flex-col">
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-800/50 border-b border-gray-200 dark:border-gray-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Facility Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Type</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Branch/Location</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Capacity/Quantity</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 bg-cover bg-center border border-gray-200 dark:border-gray-700"
                        style='background-image: url("https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=100");'>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white text-base">Executive Conf. Room A</p>
                        <p class="text-xs text-gray-500 mt-0.5">ID: FAC-1002</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-medium">Room</td>
                  <td class="py-4 px-6 text-sm text-gray-900 dark:text-white">HQ - Floor 5</td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">12 Seats</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span>
                      Available
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit Facility">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="View Maintenance Log">
                        <span class="material-symbols-outlined text-[20px]">history</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 bg-cover bg-center border border-gray-200 dark:border-gray-700"
                        style='background-image: url("https://images.unsplash.com/photo-1542362567-b051c63b9a56?auto=format&fit=crop&q=80&w=100");'>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white text-base">Delivery Van #04</p>
                        <p class="text-xs text-gray-500 mt-0.5">ID: VEH-0045</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-medium">Vehicle</td>
                  <td class="py-4 px-6 text-sm text-gray-900 dark:text-white">Logistics Center</td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">1 Unit</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-yellow-500 dark:bg-yellow-400"></span>
                      Maintenance
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit Facility">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="View Maintenance Log">
                        <span class="material-symbols-outlined text-[20px]">history</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 bg-cover bg-center border border-gray-200 dark:border-gray-700"
                        style='background-image: url("https://images.unsplash.com/photo-1558494949-ef010cbdcc31?auto=format&fit=crop&q=80&w=100");'>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white text-base">Server Rack B2</p>
                        <p class="text-xs text-gray-500 mt-0.5">ID: IT-0089</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-medium">Equipment</td>
                  <td class="py-4 px-6 text-sm text-gray-900 dark:text-white">HQ - Server Room</td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">42 Units</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-blue-500 dark:bg-blue-400"></span>
                      In Use
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit Facility">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="View Maintenance Log">
                        <span class="material-symbols-outlined text-[20px]">history</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-4">
                      <div
                        class="w-10 h-10 rounded-lg bg-gray-100 dark:bg-gray-800 bg-cover bg-center border border-gray-200 dark:border-gray-700"
                        style='background-image: url("https://images.unsplash.com/photo-1581092160562-40aa08e78837?auto=format&fit=crop&q=80&w=100");'>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white text-base">Forklift XL-200</p>
                        <p class="text-xs text-gray-500 mt-0.5">ID: EQP-0102</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300 font-medium">Equipment</td>
                  <td class="py-4 px-6 text-sm text-gray-900 dark:text-white">Logistics Center</td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">1 Unit</td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span>
                      Active
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit Facility">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="View Maintenance Log">
                        <span class="material-symbols-outlined text-[20px]">history</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-gray-200 dark:border-gray-800 flex items-center justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Showing 1 to 4 of 32 facilities</span>
            <div class="flex items-center gap-2">
              <button
                class="px-3 py-1 text-sm border border-gray-200 dark:border-gray-700 rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800 disabled:opacity-50"
                disabled="">Previous</button>
              <button
                class="px-3 py-1 text-sm border border-gray-200 dark:border-gray-700 rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
