import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Tasks_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 flex flex-col flex-1 overflow-hidden">
        <div class="flex-shrink-0 flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-slate-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Tickets & Tasks
            </h1>
            <p class="text-slate-500 dark:text-slate-400 text-base font-normal leading-normal">Manage project workflows,
              track progress, and assign responsibilities.</p>
          </div>
          <div class="flex items-center gap-3">
            <button
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors text-sm font-medium shadow-md">
              <span class="material-symbols-outlined text-[20px]">add</span>
              Add New Task
            </button>
          </div>
        </div>

        <div class="flex-shrink-0 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6 mb-8">
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col justify-between gap-4 shadow-sm hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start">
              <div class="flex flex-col gap-1">
                <p class="text-sm font-medium text-slate-500 dark:text-slate-400">Total Open</p>
                <h3 class="text-2xl font-bold text-slate-900 dark:text-white">42</h3>
              </div>
              <div class="p-2 bg-blue-50 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400 rounded-lg">
                <span class="material-symbols-outlined">assignment</span>
              </div>
            </div>
            <div class="flex items-center gap-2 text-sm">
              <span class="text-slate-400 dark:text-slate-500">24 High Priority</span>
            </div>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col justify-between gap-4 shadow-sm hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start">
              <div class="flex flex-col gap-1">
                <p class="text-sm font-medium text-slate-500 dark:text-slate-400">In Progress</p>
                <h3 class="text-2xl font-bold text-slate-900 dark:text-white">18</h3>
              </div>
              <div class="p-2 bg-purple-50 dark:bg-purple-900/40 text-purple-600 dark:text-purple-400 rounded-lg">
                <span class="material-symbols-outlined">pending_actions</span>
              </div>
            </div>
            <div class="flex items-center gap-2 text-sm">
              <span
                class="flex items-center gap-1 text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-900/40 px-2 py-0.5 rounded-full font-medium text-xs">
                <span class="material-symbols-outlined text-sm">trending_up</span> +4
              </span>
              <span class="text-slate-400 dark:text-slate-500">since yesterday</span>
            </div>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col justify-between gap-4 shadow-sm hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start">
              <div class="flex flex-col gap-1">
                <p class="text-sm font-medium text-slate-500 dark:text-slate-400">Overdue</p>
                <h3 class="text-2xl font-bold text-slate-900 dark:text-white">5</h3>
              </div>
              <div class="p-2 bg-red-50 dark:bg-red-900/40 text-red-600 dark:text-red-400 rounded-lg">
                <span class="material-symbols-outlined">warning</span>
              </div>
            </div>
            <div class="flex items-center gap-2 text-sm">
              <span
                class="flex items-center gap-1 text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/40 px-2 py-0.5 rounded-full font-medium text-xs">Requires
                Action</span>
            </div>
          </div>
          <div
            class="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col justify-between gap-4 shadow-sm hover:shadow-md transition-shadow">
            <div class="flex justify-between items-start">
              <div class="flex flex-col gap-1">
                <p class="text-sm font-medium text-slate-500 dark:text-slate-400">Completed Today</p>
                <h3 class="text-2xl font-bold text-slate-900 dark:text-white">12</h3>
              </div>
              <div class="p-2 bg-green-50 dark:bg-green-900/40 text-green-600 dark:text-green-400 rounded-lg">
                <span class="material-symbols-outlined">check_circle</span>
              </div>
            </div>
            <div class="flex items-center gap-2 text-sm">
              <span
                class="flex items-center gap-1 text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-900/40 px-2 py-0.5 rounded-full font-medium text-xs">
                <span class="material-symbols-outlined text-sm">trending_up</span> 95%
              </span>
              <span class="text-slate-400 dark:text-slate-500">Success rate</span>
            </div>
          </div>
        </div>

        <div class="flex-1 overflow-x-auto overflow-y-hidden pb-2">
          <div class="min-w-[1200px] h-full grid grid-cols-4 gap-6">
            <div
              class="flex flex-col h-full bg-slate-100 dark:bg-slate-800/50 rounded-xl p-4 border border-slate-200 dark:border-slate-800">
              <div class="flex items-center justify-between mb-4 px-1">
                <h3 class="font-bold text-slate-700 dark:text-slate-200 flex items-center gap-2">
                  <div class="w-2 h-2 rounded-full bg-slate-400"></div> To Do
                </h3>
                <span
                  class="bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300 px-2.5 py-0.5 rounded-full text-xs font-semibold">5</span>
              </div>
              <div class="flex-1 overflow-y-auto kanban-col flex flex-col gap-3 pr-1">
                <div
                  class="bg-white dark:bg-slate-900 p-4 rounded-lg border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md cursor-pointer group transition-all">
                  <div class="flex justify-between items-start mb-2">
                    <span
                      class="px-2 py-1 rounded bg-red-50 dark:bg-red-900/40 text-red-600 dark:text-red-400 text-xs font-medium border border-red-100 dark:border-red-900/30">High
                      Priority</span>
                    <button
                      class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 opacity-0 group-hover:opacity-100 transition-opacity">
                      <span class="material-symbols-outlined text-[18px]">more_horiz</span>
                    </button>
                  </div>
                  <h4 class="text-slate-900 dark:text-white font-semibold text-sm mb-3 leading-snug">Update homepage
                    hero section for Summer Sale</h4>
                  <div class="flex items-center justify-between mt-auto">
                    <div class="flex items-center gap-1.5 text-slate-500 dark:text-slate-400 text-xs">
                      <span class="material-symbols-outlined text-[16px]">calendar_today</span>
                      <span>Tomorrow</span>
                    </div>
                    <div class="flex -space-x-2">
                      <div
                        class="w-7 h-7 rounded-full bg-indigo-100 text-indigo-600 flex items-center justify-center text-xs font-bold border-2 border-white dark:border-slate-900">
                        JD</div>
                    </div>
                  </div>
                </div>
                <div
                  class="bg-white dark:bg-slate-900 p-4 rounded-lg border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md cursor-pointer group transition-all">
                  <div class="flex justify-between items-start mb-2">
                    <span
                      class="px-2 py-1 rounded bg-blue-50 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400 text-xs font-medium border border-blue-100 dark:border-blue-900/30">Low
                      Priority</span>
                    <button
                      class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 opacity-0 group-hover:opacity-100 transition-opacity">
                      <span class="material-symbols-outlined text-[18px]">more_horiz</span>
                    </button>
                  </div>
                  <h4 class="text-slate-900 dark:text-white font-semibold text-sm mb-3 leading-snug">Research competitor
                    pricing models</h4>
                  <div class="flex items-center justify-between mt-auto">
                    <div class="flex items-center gap-1.5 text-slate-500 dark:text-slate-400 text-xs">
                      <span class="material-symbols-outlined text-[16px]">calendar_today</span>
                      <span>July 24</span>
                    </div>
                    <div class="flex -space-x-2">
                      <div
                        class="w-7 h-7 rounded-full bg-pink-100 text-pink-600 flex items-center justify-center text-xs font-bold border-2 border-white dark:border-slate-900">
                        AL</div>
                    </div>
                  </div>
                </div>
              </div>
              <button
                class="mt-3 w-full py-2 flex items-center justify-center gap-2 text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200 hover:bg-white dark:hover:bg-slate-900 rounded-lg text-sm transition-colors border border-transparent hover:border-slate-200 dark:hover:border-slate-700">
                <span class="material-symbols-outlined text-[18px]">add</span>
                Add Task
              </button>
            </div>

            <div
              class="flex flex-col h-full bg-slate-100 dark:bg-slate-800/50 rounded-xl p-4 border border-slate-200 dark:border-slate-800">
              <div class="flex items-center justify-between mb-4 px-1">
                <h3 class="font-bold text-slate-700 dark:text-slate-200 flex items-center gap-2">
                  <div class="w-2 h-2 rounded-full bg-blue-600"></div> In Progress
                </h3>
                <span
                  class="bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300 px-2.5 py-0.5 rounded-full text-xs font-semibold">3</span>
              </div>
              <div class="flex-1 overflow-y-auto kanban-col flex flex-col gap-3 pr-1">
                <div
                  class="bg-white dark:bg-slate-900 p-4 rounded-lg border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md cursor-pointer group transition-all">
                  <div class="flex justify-between items-start mb-2">
                    <span
                      class="px-2 py-1 rounded bg-amber-50 dark:bg-amber-900/40 text-amber-600 dark:text-amber-400 text-xs font-medium border border-amber-100 dark:border-amber-900/30">Medium
                      Priority</span>
                    <button
                      class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 opacity-0 group-hover:opacity-100 transition-opacity">
                      <span class="material-symbols-outlined text-[18px]">more_horiz</span>
                    </button>
                  </div>
                  <h4 class="text-slate-900 dark:text-white font-semibold text-sm mb-3 leading-snug">Prepare Q3
                    financial report draft</h4>
                  <div class="flex items-center justify-between mt-auto">
                    <div class="flex items-center gap-1.5 text-amber-600 dark:text-amber-400 text-xs font-medium">
                      <span class="material-symbols-outlined text-[16px]">schedule</span>
                      <span>2 days left</span>
                    </div>
                    <div
                      class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-7 w-7 border-2 border-white dark:border-slate-900"
                      style='background-image: url("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-1.2.1&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80");'>
                    </div>
                  </div>
                  <div class="mt-3 w-full bg-slate-100 dark:bg-slate-800 rounded-full h-1.5 overflow-hidden">
                    <div class="bg-blue-600 h-full rounded-full" style="width: 65%"></div>
                  </div>
                </div>
                <div
                  class="bg-white dark:bg-slate-900 p-4 rounded-lg border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md cursor-pointer group transition-all">
                  <div class="flex justify-between items-start mb-2">
                    <span
                      class="px-2 py-1 rounded bg-red-50 dark:bg-red-900/40 text-red-600 dark:text-red-400 text-xs font-medium border border-red-100 dark:border-red-900/30">High
                      Priority</span>
                    <button
                      class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 opacity-0 group-hover:opacity-100 transition-opacity">
                      <span class="material-symbols-outlined text-[18px]">more_horiz</span>
                    </button>
                  </div>
                  <h4 class="text-slate-900 dark:text-white font-semibold text-sm mb-3 leading-snug">Fix critical login
                    bug on mobile</h4>
                  <div class="flex items-center justify-between mt-auto">
                    <div class="flex items-center gap-1.5 text-red-500 text-xs font-medium">
                      <span class="material-symbols-outlined text-[16px]">error</span>
                      <span>Overdue</span>
                    </div>
                    <div class="flex -space-x-2">
                      <div
                        class="w-7 h-7 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center text-xs font-bold border-2 border-white dark:border-slate-900">
                        RK</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div
              class="flex flex-col h-full bg-slate-100 dark:bg-slate-800/50 rounded-xl p-4 border border-slate-200 dark:border-slate-800">
              <div class="flex items-center justify-between mb-4 px-1">
                <h3 class="font-bold text-slate-700 dark:text-slate-200 flex items-center gap-2">
                  <div class="w-2 h-2 rounded-full bg-purple-500"></div> In Review
                </h3>
                <span
                  class="bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300 px-2.5 py-0.5 rounded-full text-xs font-semibold">2</span>
              </div>
              <div class="flex-1 overflow-y-auto kanban-col flex flex-col gap-3 pr-1">
                <div
                  class="bg-white dark:bg-slate-900 p-4 rounded-lg border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md cursor-pointer group transition-all">
                  <div class="flex justify-between items-start mb-2">
                    <span
                      class="px-2 py-1 rounded bg-amber-50 dark:bg-amber-900/40 text-amber-600 dark:text-amber-400 text-xs font-medium border border-amber-100 dark:border-amber-900/30">Medium
                      Priority</span>
                    <button
                      class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 opacity-0 group-hover:opacity-100 transition-opacity">
                      <span class="material-symbols-outlined text-[18px]">more_horiz</span>
                    </button>
                  </div>
                  <h4 class="text-slate-900 dark:text-white font-semibold text-sm mb-3 leading-snug">New employee
                    onboarding flow designs</h4>
                  <div class="flex items-center justify-between mt-auto">
                    <div class="flex items-center gap-1.5 text-slate-500 dark:text-slate-400 text-xs">
                      <span class="material-symbols-outlined text-[16px]">calendar_today</span>
                      <span>July 26</span>
                    </div>
                    <div class="flex -space-x-2">
                      <div
                        class="w-7 h-7 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center text-xs font-bold border-2 border-white dark:border-slate-900">
                        MS</div>
                    </div>
                  </div>
                  <div class="mt-3 flex gap-2">
                    <span
                      class="text-[10px] bg-slate-100 dark:bg-slate-800 px-1.5 py-0.5 rounded text-slate-500">Design</span>
                    <span
                      class="text-[10px] bg-slate-100 dark:bg-slate-800 px-1.5 py-0.5 rounded text-slate-500">HR</span>
                  </div>
                </div>
              </div>
            </div>

            <div
              class="flex flex-col h-full bg-slate-100 dark:bg-slate-800/50 rounded-xl p-4 border border-slate-200 dark:border-slate-800">
              <div class="flex items-center justify-between mb-4 px-1">
                <h3 class="font-bold text-slate-700 dark:text-slate-200 flex items-center gap-2">
                  <div class="w-2 h-2 rounded-full bg-green-500"></div> Done
                </h3>
                <span
                  class="bg-slate-200 dark:bg-slate-700 text-slate-600 dark:text-slate-300 px-2.5 py-0.5 rounded-full text-xs font-semibold">12</span>
              </div>
              <div class="flex-1 overflow-y-auto kanban-col flex flex-col gap-3 pr-1">
                <div
                  class="bg-white dark:bg-slate-900 p-4 rounded-lg border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md cursor-pointer group transition-all opacity-70 hover:opacity-100">
                  <div class="flex justify-between items-start mb-2">
                    <span
                      class="px-2 py-1 rounded bg-blue-50 dark:bg-blue-900/40 text-blue-600 dark:text-blue-400 text-xs font-medium border border-blue-100 dark:border-blue-900/30">Low
                      Priority</span>
                    <div class="text-green-500 flex items-center">
                      <span class="material-symbols-outlined text-[20px]">check_circle</span>
                    </div>
                  </div>
                  <h4
                    class="text-slate-900 dark:text-white font-semibold text-sm mb-3 leading-snug line-through text-slate-500">
                    Weekly server maintenance</h4>
                  <div class="flex items-center justify-between mt-auto">
                    <div class="flex items-center gap-1.5 text-slate-500 dark:text-slate-400 text-xs">
                      <span class="material-symbols-outlined text-[16px]">event_available</span>
                      <span>Yesterday</span>
                    </div>
                    <div class="flex -space-x-2">
                      <div
                        class="w-7 h-7 rounded-full bg-teal-100 text-teal-600 flex items-center justify-center text-xs font-bold border-2 border-white dark:border-slate-900">
                        IT</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div
              class="col-span-4 mt-4 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
              <table class="w-full text-left text-sm">
                <thead class="bg-slate-50 dark:bg-slate-800 text-slate-500 uppercase text-xs">
                  <tr>
                    <th class="px-6 py-3 font-medium">Task</th>
                    <th class="px-6 py-3 font-medium">Status</th>
                    <th class="px-6 py-3 font-medium">Due Date</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                  <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td class="px-6 py-4 font-medium text-slate-900 dark:text-white">Example Task Row</td>
                    <td class="px-6 py-4 text-blue-600">Active</td>
                    <td class="px-6 py-4 text-slate-500">2024-07-25</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
