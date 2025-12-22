import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Documents_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-slate-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Document
              Management</h1>
            <p class="text-slate-500 dark:text-slate-400 text-base font-normal leading-normal">Centralized hub for all
              company contracts, reports, and digital assets.</p>
          </div>
        </div>
        <div class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col">
          <div
            class="p-6 border-b border-slate-200 dark:border-slate-800 flex flex-col xl:flex-row xl:items-center justify-between gap-4">
            <h2 class="text-slate-900 dark:text-white text-xl font-bold leading-tight tracking-tight">All Documents</h2>
            <div class="flex flex-wrap items-center gap-3">
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Category: All</option>
                  <option value="financial">Financial</option>
                  <option value="hr">HR & Policy</option>
                  <option value="marketing">Marketing</option>
                  <option value="legal">Legal</option>
                </select>
              </div>
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">File Type: All</option>
                  <option value="pdf">PDF</option>
                  <option value="image">Image</option>
                  <option value="spreadsheet">Spreadsheet</option>
                  <option value="doc">Document</option>
                </select>
              </div>
              <div class="relative">
                <select
                  class="form-select pl-3 pr-10 py-2 text-sm border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300 focus:border-blue-600 focus:ring-blue-600 w-full sm:w-auto">
                  <option selected="">Owner: All</option>
                  <option value="olivia">Olivia Martin</option>
                  <option value="liam">Liam Johnson</option>
                  <option value="noah">Noah Williams</option>
                </select>
              </div>
              <button
                class="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-medium text-sm whitespace-nowrap">
                <span class="material-symbols-outlined text-[20px]">upload_file</span>
                Upload New Document
              </button>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr
                  class="text-sm text-slate-500 dark:text-slate-400 bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700">
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Document Name</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Category</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Uploaded Date</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Size</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Owner</th>
                  <th class="py-4 px-6 font-medium whitespace-nowrap">Status</th>
                  <th class="py-4 px-6 font-medium text-right whitespace-nowrap">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-red-100 dark:bg-red-900/30 flex items-center justify-center text-red-600 dark:text-red-400">
                        <span class="material-symbols-outlined">picture_as_pdf</span>
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white">Q3 Financial Report.pdf</p>
                        <p class="text-xs text-slate-500">Version 2.0</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Financial
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Oct 24, 2023
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    2.4 MB
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-8 w-8"
                        style='background-image: url("https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=64&h=64&fit=crop");'>
                      </div>
                      <span class="text-slate-900 dark:text-white">Olivia Martin</span>
                    </div>
                  </td>
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
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Download">
                        <span class="material-symbols-outlined text-[20px]">download</span>
                      </button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Delete">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 dark:text-blue-400">
                        <span class="material-symbols-outlined">description</span>
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white">Employee Handbook 2024.docx</p>
                        <p class="text-xs text-slate-500">Draft</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    HR & Policy
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Sep 15, 2023
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    1.1 MB
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-8 w-8"
                        style='background-image: url("https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=64&h=64&fit=crop");'>
                      </div>
                      <span class="text-slate-900 dark:text-white">Liam Johnson</span>
                    </div>
                  </td>
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
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Download">
                        <span class="material-symbols-outlined text-[20px]">download</span>
                      </button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Delete">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-green-100 dark:bg-green-900/30 flex items-center justify-center text-green-600 dark:text-green-400">
                        <span class="material-symbols-outlined">table_view</span>
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white">Project Alpha Budget.xlsx</p>
                        <p class="text-xs text-slate-500">Internal Only</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Financial
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Nov 01, 2023
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    850 KB
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-8 w-8"
                        style='background-image: url("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=64&h=64&fit=crop");'>
                      </div>
                      <span class="text-slate-900 dark:text-white">Noah Williams</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800">
                      <span class="w-1.5 h-1.5 rounded-full bg-yellow-600 dark:bg-yellow-400"></span>
                      Review
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Download">
                        <span class="material-symbols-outlined text-[20px]">download</span>
                      </button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Delete">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center text-orange-600 dark:text-orange-400">
                        <span class="material-symbols-outlined">folder_zip</span>
                      </div>
                      <div>
                        <p class="font-medium text-slate-900 dark:text-white">Brand Assets 2022.zip</p>
                        <p class="text-xs text-slate-500">Deprecated</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Marketing
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    Aug 20, 2022
                  </td>
                  <td class="py-4 px-6 text-sm text-slate-600 dark:text-slate-300">
                    15.2 MB
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <div class="flex items-center gap-3">
                      <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full h-8 w-8"
                        style='background-image: url("https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=64&h=64&fit=crop");'>
                      </div>
                      <span class="text-slate-900 dark:text-white">Emma Brown</span>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-sm">
                    <span
                      class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-slate-500 dark:bg-slate-400"></span>
                      Archived
                    </span>
                  </td>
                  <td class="py-4 px-6 text-sm text-right">
                    <div class="flex items-center justify-end gap-2">
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Download">
                        <span class="material-symbols-outlined text-[20px]">download</span>
                      </button>
                      <button
                        class="p-2 text-slate-500 hover:text-blue-600 hover:bg-blue-600/10 rounded-lg transition-colors"
                        title="Edit">
                        <span class="material-symbols-outlined text-[20px]">edit</span>
                      </button>
                      <button
                        class="p-2 text-slate-500 hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                        title="Delete">
                        <span class="material-symbols-outlined text-[20px]">delete</span>
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
            <span class="text-sm text-slate-500 dark:text-slate-400">Showing 1 to 4 of 48 documents</span>
            <div class="flex items-center gap-2">
              <button
                class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 disabled:opacity-50"
                disabled="">Previous</button>
              <button
                class="px-3 py-1 text-sm border border-slate-200 dark:border-slate-700 rounded-lg text-slate-500 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
