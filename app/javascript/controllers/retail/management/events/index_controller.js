import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Events_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-gray-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Event Management
            </h1>
            <p class="text-gray-500 dark:text-gray-400 text-base font-normal leading-normal">Manage company-wide events,
              workshops, and seminars.</p>
          </div>
        </div>
        <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 flex flex-col">
          <div
            class="p-6 border-b border-gray-200 dark:border-gray-800 flex flex-col xl:flex-row xl:items-center justify-between gap-4">
            <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight">All Events</h2>
            <div class="flex flex-wrap items-center gap-3">
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Category: All</option>
                  <option value="workshop">Workshop</option>
                  <option value="seminar">Seminar</option>
                  <option value="social">Social</option>
                  <option value="corporate">Corporate</option>
                </select>
              </div>
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Status: All</option>
                  <option value="upcoming">Upcoming</option>
                  <option value="ongoing">Ongoing</option>
                  <option value="completed">Completed</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Location: All</option>
                  <option value="hq">Main HQ</option>
                  <option value="branch-a">Branch A</option>
                  <option value="remote">Remote</option>
                </select>
              </div>
              <button
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
                <span class="material-symbols-outlined text-[20px]">add_circle</span>
                Create New Event
              </button>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-gray-800/50 border-b border-gray-200 dark:border-gray-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Event Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Category</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Date & Time</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Location</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Participants</th>
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
                        <span class="material-symbols-outlined">school</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Leadership Workshop</p>
                        <p class="text-xs text-gray-500">For Managers</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Workshop
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Oct 25, 2023 • 09:00 AM
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">location_on</span>
                      Conf. Room A
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    24 / 30
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 border border-blue-200 dark:border-blue-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-blue-600 dark:bg-blue-400"></span>
                      Upcoming
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
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
                        <span class="material-symbols-outlined">present_to_all</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Annual Tech Summit</p>
                        <p class="text-xs text-gray-500">Open to all</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Seminar
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Oct 24, 2023 • 10:00 AM
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">location_on</span>
                      Main Auditorium
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    145 / 200
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400 border border-amber-200 dark:border-amber-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-amber-600 dark:bg-amber-400"></span>
                      Ongoing
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
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
                        <p class="font-medium text-gray-900 dark:text-white">Friday Social Mixer</p>
                        <p class="text-xs text-gray-500">Networking</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Social
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Oct 20, 2023 • 05:00 PM
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">location_on</span>
                      Rooftop Lounge
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    45 / 50
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-green-600 dark:bg-green-400"></span>
                      Completed
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
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
                        <span class="material-symbols-outlined">business_center</span>
                      </div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Corporate Review</p>
                        <p class="text-xs text-gray-500">Executive Team</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Corporate
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    Oct 24, 2023 • 02:00 PM
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    <div class="flex items-center gap-2">
                      <span class="material-symbols-outlined text-lg text-gray-400">location_on</span>
                      Boardroom
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-gray-600 dark:text-gray-300">
                    8 / 10
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-400 border border-gray-200 dark:border-gray-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-gray-500 dark:bg-gray-400"></span>
                      Cancelled
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="View Details">
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
            <span class="text-sm text-gray-500 dark:text-gray-400">Showing 1 to 4 of 32 events</span>
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
