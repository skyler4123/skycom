import Admin_LayoutController from "controllers/admin/layout_controller"

export default class Admin_Companies_IndexController extends Admin_LayoutController {

  contentHTML() {
    return `
      <div class="max-w-[1400px] mx-auto flex flex-col gap-6">
        <div class="flex flex-col md:flex-row md:items-end justify-between gap-4">
          <div>
            <h1 class="text-2xl font-bold text-slate-900 dark:text-white tracking-tight">Branch Management</h1>
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">Manage physical locations, associate them with
              parent companies, and monitor status.</p>
          </div>
          <button
            class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 rounded-lg flex items-center gap-2 transition-all shadow-sm hover:shadow-md font-medium text-sm">
            <span class="material-symbols-outlined text-xl">add_location_alt</span> Add New Branch
          </button>
        </div>

        <div
          class="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm grid grid-cols-1 md:grid-cols-4 gap-4 items-center">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Branch
              Status</label>
            <div class="relative">
              <select
                class="w-full bg-slate-50 dark:bg-slate-800 border-none text-sm rounded-lg py-2.5 pl-3 pr-10 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-600/50 cursor-pointer">
                <option value="">All Statuses</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
                <option value="maintenance">Under Maintenance</option>
              </select>
              <span
                class="absolute right-3 top-2.5 pointer-events-none text-slate-500 material-symbols-outlined text-lg">expand_more</span>
            </div>
          </div>
          <div class="flex flex-col gap-1.5">
            <label
              class="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Associated
              Company</label>
            <div class="relative">
              <select
                class="w-full bg-slate-50 dark:bg-slate-800 border-none text-sm rounded-lg py-2.5 pl-3 pr-10 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-600/50 cursor-pointer">
                <option value="">All Companies</option>
                <option value="tech_retail">TechRetail Solutions</option>
                <option value="learn_fast">LearnFast Academy</option>
                <option value="city_gen">City General Hospital</option>
                <option value="quick_bites">QuickBites Inc</option>
                <option value="elite_fitness">Elite Fitness Chain</option>
              </select>
              <span
                class="absolute right-3 top-2.5 pointer-events-none text-slate-500 material-symbols-outlined text-lg">expand_more</span>
            </div>
          </div>
          <div class="flex flex-col gap-1.5">
            <label
              class="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Region/City</label>
            <div class="relative">
              <select
                class="w-full bg-slate-50 dark:bg-slate-800 border-none text-sm rounded-lg py-2.5 pl-3 pr-10 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-600/50 cursor-pointer">
                <option value="">All Regions</option>
                <option value="ny">New York, NY</option>
                <option value="sf">San Francisco, CA</option>
                <option value="ldn">London, UK</option>
                <option value="tyo">Tokyo, JP</option>
              </select>
              <span
                class="absolute right-3 top-2.5 pointer-events-none text-slate-500 material-symbols-outlined text-lg">expand_more</span>
            </div>
          </div>
          <div class="flex items-end justify-end h-full pb-0.5">
            <button
              class="text-blue-600 hover:text-blue-700 text-sm font-medium hover:underline flex items-center gap-1 transition-colors">
              <span class="material-symbols-outlined text-lg">filter_list_off</span> Clear Filters
            </button>
          </div>
        </div>

        <div
          class="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden shadow-sm flex-1">
          <div class="overflow-x-auto">
            <table class="w-full text-left text-sm whitespace-nowrap">
              <thead
                class="bg-slate-50 dark:bg-slate-800/50 text-slate-500 dark:text-slate-400 font-medium border-b border-slate-200 dark:border-slate-800">
                <tr>
                  <th class="px-6 py-4">Branch Name</th>
                  <th class="px-6 py-4">Associated Company</th>
                  <th class="px-6 py-4">Branch Manager</th>
                  <th class="px-6 py-4">Location</th>
                  <th class="px-6 py-4">Status</th>
                  <th class="px-6 py-4">Creation Date</th>
                  <th class="px-6 py-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-indigo-100 text-indigo-600 dark:bg-indigo-900/30 dark:text-indigo-400 flex items-center justify-center font-bold text-xs">
                        <span class="material-symbols-outlined text-lg">store</span>
                      </div>
                      <div>
                        <span class="font-medium text-slate-900 dark:text-white block">Downtown Tech Hub</span>
                        <span class="text-xs text-slate-500">ID: B-NY01</span>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-2">
                      <span class="w-2 h-2 rounded-full bg-slate-300"></span>
                      <span class="text-slate-700 dark:text-slate-300 font-medium">TechRetail Solutions</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-slate-900 dark:text-white">James Wilson</td>
                  <td class="px-6 py-4 text-slate-600 dark:text-slate-400">New York, NY</td>
                  <td class="px-6 py-4">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">Active</span>
                  </td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">Jan 15, 2024</td>
                  <td class="px-6 py-4">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-lg">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Edit Branch">
                        <span class="material-symbols-outlined text-lg">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate">
                        <span class="material-symbols-outlined text-lg">storefront</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-pink-100 text-pink-600 dark:bg-pink-900/30 dark:text-pink-400 flex items-center justify-center font-bold text-xs">
                        <span class="material-symbols-outlined text-lg">menu_book</span>
                      </div>
                      <div>
                        <span class="font-medium text-slate-900 dark:text-white block">LearnFast Campus A</span>
                        <span class="text-xs text-slate-500">ID: B-MA05</span>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-2">
                      <span class="w-2 h-2 rounded-full bg-slate-300"></span>
                      <span class="text-slate-700 dark:text-slate-300 font-medium">LearnFast Academy</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-slate-900 dark:text-white">Alice Smith</td>
                  <td class="px-6 py-4 text-slate-600 dark:text-slate-400">Boston, MA</td>
                  <td class="px-6 py-4">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400">Under
                      Maintenance</span>
                  </td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">Mar 20, 2024</td>
                  <td class="px-6 py-4">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-lg">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Edit Branch">
                        <span class="material-symbols-outlined text-lg">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate">
                        <span class="material-symbols-outlined text-lg">storefront</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400 flex items-center justify-center font-bold text-xs">
                        <span class="material-symbols-outlined text-lg">medical_services</span>
                      </div>
                      <div>
                        <span class="font-medium text-slate-900 dark:text-white block">Central City ER</span>
                        <span class="text-xs text-slate-500">ID: B-CH22</span>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-2">
                      <span class="w-2 h-2 rounded-full bg-slate-300"></span>
                      <span class="text-slate-700 dark:text-slate-300 font-medium">City General Hospital</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-slate-900 dark:text-white">Dr. House</td>
                  <td class="px-6 py-4 text-slate-600 dark:text-slate-400">Chicago, IL</td>
                  <td class="px-6 py-4">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">Active</span>
                  </td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">Feb 15, 2024</td>
                  <td class="px-6 py-4">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-lg">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Edit Branch">
                        <span class="material-symbols-outlined text-lg">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate">
                        <span class="material-symbols-outlined text-lg">storefront</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400 flex items-center justify-center font-bold text-xs">
                        <span class="material-symbols-outlined text-lg">fastfood</span>
                      </div>
                      <div>
                        <span class="font-medium text-slate-900 dark:text-white block">QuickBites Express</span>
                        <span class="text-xs text-slate-500">ID: B-WA88</span>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-2">
                      <span class="w-2 h-2 rounded-full bg-slate-300"></span>
                      <span class="text-slate-700 dark:text-slate-300 font-medium">QuickBites Inc</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-slate-900 dark:text-white">Bob Burger</td>
                  <td class="px-6 py-4 text-slate-600 dark:text-slate-400">Seattle, WA</td>
                  <td class="px-6 py-4">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400">Inactive</span>
                  </td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">Dec 10, 2023</td>
                  <td class="px-6 py-4">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-lg">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Edit Branch">
                        <span class="material-symbols-outlined text-lg">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate">
                        <span class="material-symbols-outlined text-lg">storefront</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/30 transition-colors group">
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-teal-100 text-teal-600 dark:bg-teal-900/30 dark:text-teal-400 flex items-center justify-center font-bold text-xs">
                        <span class="material-symbols-outlined text-lg">fitness_center</span>
                      </div>
                      <div>
                        <span class="font-medium text-slate-900 dark:text-white block">Elite Gym Downtown</span>
                        <span class="text-xs text-slate-500">ID: B-LA90</span>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4">
                    <div class="flex items-center gap-2">
                      <span class="w-2 h-2 rounded-full bg-slate-300"></span>
                      <span class="text-slate-700 dark:text-slate-300 font-medium">Elite Fitness Chain</span>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-slate-900 dark:text-white">Arnold S.</td>
                  <td class="px-6 py-4 text-slate-600 dark:text-slate-400">Los Angeles, CA</td>
                  <td class="px-6 py-4">
                    <span
                      class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400">Active</span>
                  </td>
                  <td class="px-6 py-4 text-slate-500 dark:text-slate-400">Apr 05, 2024</td>
                  <td class="px-6 py-4">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
                        <span class="material-symbols-outlined text-lg">visibility</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded-lg transition-colors"
                        title="Edit Branch">
                        <span class="material-symbols-outlined text-lg">edit</span>
                      </button>
                      <button
                        class="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Deactivate">
                        <span class="material-symbols-outlined text-lg">storefront</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div
            class="flex items-center justify-between px-6 py-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-200 dark:border-slate-800">
            <div class="text-xs text-slate-500 dark:text-slate-400">
              Showing <span class="font-medium">1</span> to <span class="font-medium">5</span> of <span
                class="font-medium">89</span> results
            </div>
            <div class="flex gap-2">
              <button
                class="px-3 py-1 text-xs font-medium bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-slate-400 cursor-not-allowed">Previous</button>
              <button
                class="px-3 py-1 text-xs font-medium bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-lg text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
