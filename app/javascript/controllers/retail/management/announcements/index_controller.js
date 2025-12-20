import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Announcements_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-gray-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Announcement
              Management</h1>
            <p class="text-gray-500 dark:text-gray-400 text-base font-normal leading-normal">Manage company-wide news,
              urgent alerts, and event updates across all verticals.</p>
          </div>
        </div>
        <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 flex flex-col">
          <div
            class="p-6 border-b border-gray-200 dark:border-gray-800 flex flex-col xl:flex-row xl:items-center justify-between gap-4">
            <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight">All Announcements
            </h2>
            <div class="flex flex-wrap items-center gap-3">
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Category: All</option>
                  <option value="general">General</option>
                  <option value="urgent">Urgent</option>
                  <option value="hr">HR</option>
                  <option value="event">Event</option>
                </select>
              </div>
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Status: All</option>
                  <option value="published">Published</option>
                  <option value="draft">Draft</option>
                  <option value="scheduled">Scheduled</option>
                </select>
              </div>
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Vertical: All</option>
                  <option value="retail">Retail</option>
                  <option value="education">Education</option>
                  <option value="healthcare">Healthcare</option>
                </select>
              </div>
              <button
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
                <span class="material-symbols-outlined text-[20px]">add_circle</span>
                Create New Announcement
              </button>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-800/50 border-b border-gray-200 dark:border-gray-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Title</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Category</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Published Date</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Author</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 dark:text-blue-400">
                        <span class="material-symbols-outlined">campaign</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Q4 All-Hands Meeting</p>
                        <p class="text-xs text-gray-500">Target: All Verticals</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    General
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Oct 24, 2023
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-8 w-8"
                        style='background-image: url("https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=100");'>
                      </div>
                      <span class="text-gray-900 dark:text-white">Olivia Martin</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span>
                      Published
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Delete">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-red-100 dark:bg-red-900/30 flex items-center justify-center text-red-600 dark:text-red-400">
                        <span class="material-symbols-outlined">warning</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Urgent: Server Maintenance</p>
                        <p class="text-xs text-gray-500">Target: Retail, Healthcare</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Urgent
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Nov 01, 2023
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-8 w-8"
                        style='background-image: url("https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&q=80&w=100");'>
                      </div>
                      <span class="text-gray-900 dark:text-white">Liam Johnson</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-blue-600 dark:bg-blue-400"></span>
                      Scheduled
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Delete">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center text-purple-600 dark:text-purple-400">
                        <span class="material-symbols-outlined">celebration</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Year-End Party Details</p>
                        <p class="text-xs text-gray-500">Target: All</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Event
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    -
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-8 w-8"
                        style='background-image: url("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=100");'>
                      </div>
                      <span class="text-gray-900 dark:text-white">Noah Williams</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400 border border-gray-200 dark:border-gray-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-gray-500 dark:bg-gray-400"></span>
                      Draft
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Delete">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-gray-50 dark:hover:bg-gray-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center text-orange-600 dark:text-orange-400">
                        <span class="material-symbols-outlined">diversity_3</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Updated Benefits 2024</p>
                        <p class="text-xs text-gray-500">Target: Full-time Employees</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    HR
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Sep 15, 2023
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-8 w-8"
                        style='background-image: url("https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=100");'>
                      </div>
                      <span class="text-gray-900 dark:text-white">Emma Brown</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span>
                      Published
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View">
                        <span class="material-symbols-outlined text-[20px]">visibility</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Delete">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-gray-200 dark:border-gray-800 flex items-center justify-between">
            <span class="text-sm text-gray-500 dark:text-gray-400">Showing 1 to 4 of 32 announcements</span>
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
