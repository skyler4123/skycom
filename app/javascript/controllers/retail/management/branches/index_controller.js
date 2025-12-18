import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Branches_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="mb-8">
          <h1 class="text-slate-900 dark:text-white text-3xl font-extrabold tracking-tight">Branch Management</h1>
          <p class="text-slate-500 dark:text-slate-400 mt-1">Oversee performance and details for all company locations.
          </p>
        </div>

        <div
          class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          <div
            class="p-6 border-b border-slate-200 dark:border-slate-800 flex flex-col xl:flex-row xl:items-center justify-between gap-4">
            <h2 class="text-slate-900 dark:text-white text-xl font-bold">All Branches</h2>
            <div class="flex flex-wrap items-center gap-3">
              <select
                class="rounded-lg border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-sm text-slate-600 dark:text-slate-300 focus:ring-blue-500">
                <option>Status: All</option>
              </select>
              <select
                class="rounded-lg border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 text-sm text-slate-600 dark:text-slate-300 focus:ring-blue-500">
                <option>Region: All</option>
              </select>
              <button
                class="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors font-semibold text-sm">
                <span class="material-symbols-outlined text-lg">add</span>
                Add New Branch
              </button>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full text-left">
              <thead
                class="bg-slate-50 dark:bg-slate-800/50 border-b border-slate-200 dark:border-slate-700 text-slate-500 dark:text-slate-400 text-xs font-semibold uppercase tracking-wider">
                <tr>
                  <th class="py-4 px-6">Branch Name</th>
                  <th class="py-4 px-6">Address</th>
                  <th class="py-4 px-6">Contact</th>
                  <th class="py-4 px-6">Manager</th>
                  <th class="py-4 px-6">Status</th>
                  <th class="py-4 px-6 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-200 dark:divide-slate-800 text-sm">
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors">
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                        <span class="material-symbols-outlined">store</span></div>
                      <div>
                        <p class="font-bold text-slate-900 dark:text-white">Downtown Flagship</p>
                        <p class="text-xs text-slate-400">ID: #BR-001</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-slate-600 dark:text-slate-300">123 Market St, San Francisco, CA 94103</td>
                  <td class="py-4 px-6 text-slate-600 dark:text-slate-300">(415) 555-0123</td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-2">
                      <div class="h-8 w-8 rounded-full bg-slate-200 bg-cover"
                        style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuBKqYQ-lFCKRgrfI4EPnefW878hsy7gNRqQPqj8s8E5Ge1-_XBtng98qY0IAC49HZtbBQbq_Xmm4WmqZTwnBA_u537-Oo3_Bo4ROEj9ufUtCi4z9_rT-JasRis5CI7aU-r4EgoVDyUSSL43L90Fx5kY6QLXVMw6PuhYB_Wpdku2jGXGTXlkeOHm_Q2XgxRygRF4fkXUKJxzjygS0_ITnoHauhzBh15UCG0VN28rIU4wC0Q1FFpiLqZxefa17HrnD0ReSRauHALa7YI');">
                      </div>
                      <span class="font-medium text-slate-900 dark:text-white">Olivia Martin</span>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span
                      class="px-2.5 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">Active</span>
                  </td>
                  <td class="py-4 px-6 text-right space-x-1">
                    <button class="p-2 text-slate-400 hover:text-blue-600 transition-colors"><span
                        class="material-symbols-outlined text-lg">edit</span></button>
                    <button class="p-2 text-slate-400 hover:text-red-600 transition-colors"><span
                        class="material-symbols-outlined text-lg">delete</span></button>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors">
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                        <span class="material-symbols-outlined">shopping_bag</span></div>
                      <div>
                        <p class="font-bold text-slate-900 dark:text-white">Westside Mall</p>
                        <p class="text-xs text-slate-400">ID: #BR-002</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-slate-600 dark:text-slate-300">4500 Westfield Dr, Los Angeles, CA 90008</td>
                  <td class="py-4 px-6 text-slate-600 dark:text-slate-300">(323) 555-0892</td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-2">
                      <div class="h-8 w-8 rounded-full bg-slate-200 bg-cover"
                        style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuAbXVPxwq9gR05ET4Kg0zCkBedYQjSJZmR3DH8SdyUnxZGoM_metNxBWCUUuSnCOssD-X8VxfXiG9Yn8EfI7K0CBy89bmtD6VOri4Otu7fyWyW17ze__SksK4FO4Nm3RhWu-tuH6YoqZe3BrXGRN0eEcf4YPYy9ZVCVUjpcTsQ7vITeB-vBntfVqWXHEoBs6-F3MNAfRrD6TPd_ulew3ZSwkPOR99c991viv5iDIKdMeoP5NnXZHRFkvdpt45KCw-xhpWJaokfXO-4');">
                      </div>
                      <span class="font-medium text-slate-900 dark:text-white">Liam Johnson</span>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span
                      class="px-2.5 py-1 rounded-full text-xs font-semibold bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800">Active</span>
                  </td>
                  <td class="py-4 px-6 text-right space-x-1">
                    <button class="p-2 text-slate-400 hover:text-blue-600 transition-colors"><span
                        class="material-symbols-outlined text-lg">edit</span></button>
                    <button class="p-2 text-slate-400 hover:text-red-600 transition-colors"><span
                        class="material-symbols-outlined text-lg">delete</span></button>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors">
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                        <span class="material-symbols-outlined">local_shipping</span></div>
                      <div>
                        <p class="font-bold text-slate-900 dark:text-white">North Distribution</p>
                        <p class="text-xs text-slate-400">ID: #BR-003</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-slate-600 dark:text-slate-300">88 Industrial Pkwy, Seattle, WA 98101</td>
                  <td class="py-4 px-6 text-slate-600 dark:text-slate-300">(206) 555-9981</td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-2">
                      <div class="h-8 w-8 rounded-full bg-slate-200 bg-cover"
                        style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuC0-OZADNa-IOAewhuFRea32GhnTvSizf8IS7oJQCoW7uVPOToTNdbnfTGSgQdK2_aazL5e3yrXwWx9ytQRzabYngl2KRa100dLvLcWHTf8YH24sSOeI_cUDKZTq154ssb9O_ltPlYsH_elSHIo5jkwQ8hYYdKSESjp5-M_aY2blXiJ1y-xpC-Q0x7GWNq3JGWv52TwBe_bbUyVrAmWaRkl5zg1G8ld4KFLDZxeB_IGkorYr_4N8EAD49G9_7E9KOu9S0MyWLhLHXs');">
                      </div>
                      <span class="font-medium text-slate-900 dark:text-white">Noah Williams</span>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span
                      class="px-2.5 py-1 rounded-full text-xs font-semibold bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400 border border-yellow-200 dark:border-yellow-800">Maintenance</span>
                  </td>
                  <td class="py-4 px-6 text-right space-x-1">
                    <button class="p-2 text-slate-400 hover:text-blue-600 transition-colors"><span
                        class="material-symbols-outlined text-lg">edit</span></button>
                    <button class="p-2 text-slate-400 hover:text-red-600 transition-colors"><span
                        class="material-symbols-outlined text-lg">delete</span></button>
                  </td>
                </tr>
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors">
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-3">
                      <div
                        class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center text-slate-500">
                        <span class="material-symbols-outlined">storefront</span></div>
                      <div>
                        <p class="font-bold text-slate-900 dark:text-white">Eastside Pop-up</p>
                        <p class="text-xs text-slate-400">ID: #BR-004</p>
                      </div>
                    </div>
                  </td>
                  <td class="py-4 px-6 text-slate-600 dark:text-slate-300">200 Broadway, New York, NY 10038</td>
                  <td class="py-4 px-6 text-slate-600 dark:text-slate-300">(212) 555-4421</td>
                  <td class="py-4 px-6">
                    <div class="flex items-center gap-2">
                      <div class="h-8 w-8 rounded-full bg-slate-200 bg-cover"
                        style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuC_yRDDWRHorUiz0qbFEELV1j4CH5u7Pi8lNcqwN_NtNOzzmmXcLVj1axHQygvNQtzXQuDy_WkVr48kqu5bnmVmaRknP1wRgyFHJ0ERmHZ1ExwN-9Wqgojlr03kwVw9G0tQZ1LAdNn1qJJqPVvUwb4YiQRrkrevxFplJFS3LWtv2j3JA8GtCWs8wVtXw44pdWfb7d68qYZ-F37TizWABbG75ItHnbVZC8XlKJTD_otQmgkGtRdNZeoKOiYLoBJNe3JIPJHtx766U-8');">
                      </div>
                      <span class="font-medium text-slate-900 dark:text-white">Emma Brown</span>
                    </div>
                  </td>
                  <td class="py-4 px-6">
                    <span
                      class="px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400 border border-slate-200 dark:border-slate-700">Inactive</span>
                  </td>
                  <td class="py-4 px-6 text-right space-x-1">
                    <button class="p-2 text-slate-400 hover:text-blue-600 transition-colors"><span
                        class="material-symbols-outlined text-lg">edit</span></button>
                    <button class="p-2 text-slate-400 hover:text-red-600 transition-colors"><span
                        class="material-symbols-outlined text-lg">delete</span></button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div
            class="p-4 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between bg-slate-50/50 dark:bg-slate-800/30">
            <span class="text-xs text-slate-500 font-medium uppercase tracking-wider">Showing 4 of 12 branches</span>
            <div class="flex items-center gap-2">
              <button
                class="px-4 py-1.5 text-xs font-bold border border-slate-300 dark:border-slate-700 rounded-lg text-slate-500 hover:bg-white dark:hover:bg-slate-800 disabled:opacity-50"
                disabled>Prev</button>
              <button
                class="px-4 py-1.5 text-xs font-bold border border-slate-300 dark:border-slate-700 rounded-lg text-slate-500 hover:bg-white dark:hover:bg-slate-800">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
