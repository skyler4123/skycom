import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Products_IndexController extends Retail_Management_LayoutController {

  contentHTML() {
    return `
      <div class="p-8 overflow-y-auto">
        <div class="flex flex-col md:flex-row items-center justify-between gap-4 mb-6">
          <div class="flex-1 w-full md:w-auto">
            <div class="flex flex-col md:flex-row items-center gap-4">
              <div class="relative w-full md:w-auto flex-grow">
                <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                  <span class="material-symbols-outlined text-gray-500">search</span>
                </div>
                <input
                  class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-indigo-600 focus:border-indigo-600 dark:bg-gray-800 dark:border-gray-600 dark:text-white h-10"
                  placeholder="Search products..." type="text" />
              </div>
              <div class="flex items-center gap-4 w-full md:w-auto">
                <div class="relative w-full md:w-auto">
                  <select
                    class="appearance-none w-full md:w-auto pl-3 pr-8 py-2 border border-gray-300 rounded-lg focus:ring-indigo-600 focus:border-indigo-600 dark:bg-gray-800 dark:border-gray-600 dark:text-white">
                    <option>All Categories</option>
                    <option>Apparel</option>
                    <option>Electronics</option>
                    <option>Home Goods</option>
                    <option>Accessories</option>
                  </select>
                </div>
                <div class="relative w-full md:w-auto">
                  <select
                    class="appearance-none w-full md:w-auto pl-3 pr-8 py-2 border border-gray-300 rounded-lg focus:ring-indigo-600 focus:border-indigo-600 dark:bg-gray-800 dark:border-gray-600 dark:text-white">
                    <option>All Stock</option>
                    <option>In Stock</option>
                    <option>Low Stock</option>
                    <option>Out of Stock</option>
                  </select>
                </div>
                <div class="relative w-full md:w-auto">
                  <select
                    class="appearance-none w-full md:w-auto pl-3 pr-8 py-2 border border-gray-300 rounded-lg focus:ring-indigo-600 focus:border-indigo-600 dark:bg-gray-800 dark:border-gray-600 dark:text-white">
                    <option>Tags</option>
                    <option>New Arrival</option>
                    <option>Best Seller</option>
                    <option>Sale</option>
                  </select>
                </div>
                <div class="relative w-full md:w-auto">
                  <select
                    class="appearance-none w-full md:w-auto pl-3 pr-8 py-2 border border-gray-300 rounded-lg focus:ring-indigo-600 focus:border-indigo-600 dark:bg-gray-800 dark:border-gray-600 dark:text-white">
                    <option>Status</option>
                    <option>Published</option>
                    <option>Draft</option>
                    <option>Archived</option>
                  </select>
                </div>
              </div>
            </div>
          </div>
          <div class="flex-shrink-0">
            <button
              class="inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-600 h-10">
              <span class="material-symbols-outlined">add</span>
              <span>Add New Product</span>
            </button>
          </div>
        </div>
        <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 overflow-hidden">
          <div class="overflow-x-auto">
            <table class="w-full text-left">
              <thead>
                <tr
                  class="text-sm text-gray-500 dark:text-gray-400 border-b border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50">
                  <th class="py-3 px-6 font-medium">Product Name</th>
                  <th class="py-3 px-6 font-medium">SKU</th>
                  <th class="py-3 px-6 font-medium">Price</th>
                  <th class="py-3 px-6 font-medium">Stock</th>
                  <th class="py-3 px-6 font-medium">Status</th>
                  <th class="py-3 px-6 font-medium text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-12 h-12 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBKqYQ-lFCKRgrfI4EPnefW878hsy7gNRqQPqj8s8E5Ge1-_XBtng98qY0IAC49HZtbBQbq_Xmm4WmqZTwnBA_u537-Oo3_Bo4ROEj9ufUtCi4z9_rT-JasRis5CI7aU-r4EgoVDyUSSL43L90Fx5kY6QLXVMw6PuhYB_Wpdku2jGXGTXlkeOHm_Q2XgxRygRF4fkXUKJxzjygS0_ITnoHauhzBh15UCG0VN28rIU4wC0Q1FFpiLqZxefa17HrnD0ReSRauHALa7YI")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">Vintage Leather
                        Jacket</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Apparel</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">VLJ-001</td>
                  <td class="py-4 px-6">$149.99</td>
                  <td class="py-4 px-6">50</td>
                  <td class="py-4 px-6"><span
                      class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2.5 py-1 rounded-full">In
                      Stock</span></td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-12 h-12 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbXVPxwq9gR05ET4Kg0zCkBedYQjSJZmR3DH8SdyUnxZGoM_metNxBWCUUuSnCOssD-X8VxfXiG9Yn8EfI7K0CBy89bmtD6VOri4Otu7fyWyW17ze__SksK4FO4Nm3RhWu-tuH6YoqZe3BrXGRN0eEcf4YPYy9ZVCVUjpcTsQ7vITeB-vBntfVqWXHEoBs6-F3MNAfRrD6TPd_ulew3ZSwkPOR99c991viv5iDIKdMeoP5NnXZHRFkvdpt45KCw-xhpWJaokfXO-4")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">Wireless Headphones
                      </div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Electronics</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">WH-203</td>
                  <td class="py-4 px-6">$89.99</td>
                  <td class="py-4 px-6">120</td>
                  <td class="py-4 px-6"><span
                      class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2.5 py-1 rounded-full">In
                      Stock</span></td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-12 h-12 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC0-OZADNa-IOAewhuFRea32GhnTvSizf8IS7oJQCoW7uVPOToTNdbnfTGSgQdK2_aazL5e3yrXwWx9ytQRzabYngl2KRa100dLvLcWHTf8YH24sSOeI_cUDKZTq154ssb9O_ltPlYsH_elSHIo5jkwQ8hYYdKSESjp5-M_aY2blXiJ1y-xpC-Q0x7GWNq3JGWv52TwBe_bbUyVrAmWaRkl5zg1G8ld4KFLDZxeB_IGkorYr_4N8EAD49G9_7E9KOu9S0MyWLhLHXs")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">Modern Art Print</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Home Goods</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">MAP-056</td>
                  <td class="py-4 px-6">$29.99</td>
                  <td class="py-4 px-6">8</td>
                  <td class="py-4 px-6"><span
                      class="bg-yellow-100 text-yellow-700 dark:bg-yellow-900/50 dark:text-yellow-400 text-xs font-medium px-2.5 py-1 rounded-full">Low
                      Stock</span></td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-12 h-12 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbXVPxwq9gR05ET4Kg0zCkBedYQjSJZmR3DH8SdyUnxZGoM_metNxBWCUUuSnCOssD-X8VxfXiG9Yn8EfI7K0CBy89bmtD6VOri4Otu7fyWyW17ze__SksK4FO4Nm3RhWu-tuH6YoqZe3BrXGRN0eEcf4YPYy9ZVCVUjpcTsQ7vITeB-vBntfVqWXHEoBs6-F3MNAfRrD6TPd_ulew3ZSwkPOR99c991viv5iDIKdMeoP5NnXZHRFkvdpt45KCw-xhpWJaokfXO-4")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">Organic Green Tea
                      </div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Groceries</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">OGT-0012</td>
                  <td class="py-4 px-6">$12.50</td>
                  <td class="py-4 px-6">0</td>
                  <td class="py-4 px-6"><span
                      class="bg-red-100 text-red-700 dark:bg-red-900/50 dark:text-red-400 text-xs font-medium px-2.5 py-1 rounded-full">Out
                      of Stock</span></td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-12 h-12 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC_yRDDWRHorUiz0qbFEELV1j4CH5u7Pi8lNcqwN_NtNOzzmmXcLVj1axHQygvNQtzXQuDy_WkVr48kqu5bnmVmaRknP1wRgyFHJ0ERmHZ1ExwN-9Wqgojlr03kwVw9G0tQZ1LAdNn1qJJqPVvUwb4YiQRrkrevxFplJFS3LWtv2j3JA8GtCWs8wVtXw44pdWfb7d68qYZ-F37TizWABbG75ItHnbVZC8XlKJTD_otQmgkGtRdNZeoKOiYLoBJNe3JIPJHtx766U-8")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">Handcrafted Ceramic
                        Mug</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Home Goods</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">HCM-110</td>
                  <td class="py-4 px-6">$22.00</td>
                  <td class="py-4 px-6">35</td>
                  <td class="py-4 px-6"><span
                      class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2.5 py-1 rounded-full">In
                      Stock</span></td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
                <tr class="text-sm">
                  <td class="py-4 px-6 flex items-center gap-4">
                    <div class="w-12 h-12 rounded-lg bg-gray-100 dark:bg-gray-800 flex-shrink-0 bg-cover bg-center"
                      style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBKqYQ-lFCKRgrfI4EPnefW878hsy7gNRqQPqj8s8E5Ge1-_XBtng98qY0IAC49HZtbBQbq_Xmm4WmqZTwnBA_u537-Oo3_Bo4ROEj9ufUtCi4z9_rT-JasRis5CI7aU-r4EgoVDyUSSL43L90Fx5kY6QLXVMw6PuhYB_Wpdku2jGXGTXlkeOHm_Q2XgxRygRF4fkXUKJxzjygS0_ITnoHauhzBh15UCG0VN28rIU4wC0Q1FFpiLqZxefa17HrnD0ReSRauHALa7YI")'>
                    </div>
                    <div>
                      <div class="font-medium text-gray-900 dark:text-white">Minimalist Gold Watch
                      </div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">Accessories</div>
                    </div>
                  </td>
                  <td class="py-4 px-6">MGW-004</td>
                  <td class="py-4 px-6">$250.00</td>
                  <td class="py-4 px-6">15</td>
                  <td class="py-4 px-6"><span
                      class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2.5 py-1 rounded-full">In
                      Stock</span></td>
                  <td class="py-4 px-6 text-right">
                    <div class="flex justify-end gap-2">
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">edit</span></button>
                      <button
                        class="p-2 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 text-gray-500 dark:text-gray-400"><span
                          class="material-symbols-outlined text-xl">delete</span></button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="flex items-center justify-between p-4 border-t border-gray-200 dark:border-gray-700">
            <span class="text-sm text-gray-600 dark:text-gray-400">Showing 1 to 6 of 24 products</span>
            <div class="flex items-center gap-2">
              <button
                class="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-50"
                disabled="">Previous</button>
              <button
                class="px-3 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-100 dark:hover:bg-gray-800">Next</button>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
