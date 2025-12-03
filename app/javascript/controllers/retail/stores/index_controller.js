import Retail_LayoutController from "controllers/retail/layout_controller"
// import { computePosition } from "@floating-ui/dom";
import {computePosition} from 'https://cdn.jsdelivr.net/npm/@floating-ui/dom@1.7.4/+esm';

export default class Retail_Stores_IndexController extends Retail_LayoutController {

  init() {
    const button = document.querySelector('#button');
    const tooltip = document.querySelector('#tooltip');
    computePosition(button, tooltip, {
      placement: 'right',
    }).then(({ x, y }) => {
      Object.assign(tooltip.style, {
        left: `${x}px`,
        top: `${y}px`,
      });
    });
  }

  contentHTML() {
    return `
    <button id="button">Click Me for Tooltip</button>

<div id="tooltip" style="display: none;">
  Tooltip Content
</div>
















      <div class="p-8 overflow-y-auto">
        <div class="flex flex-wrap justify-between gap-3 mb-8">
          <div class="flex flex-col gap-1">
            <p class="text-gray-900 dark:text-white text-3xl font-bold leading-tight tracking-tight">Welcome back,
              Manager!</p>
            <p class="text-gray-500 dark:text-gray-400 text-base font-normal leading-normal">Here's what's happening at
              your store today.</p>
          </div>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div
            class="flex flex-col gap-2 rounded-xl p-6 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
            <p class="text-gray-600 dark:text-gray-300 text-base font-medium leading-normal">Total Sales</p>
            <p class="text-gray-900 dark:text-white tracking-light text-3xl font-bold leading-tight">$45,231.89</p>
            <p class="text-green-600 dark:text-green-500 text-sm font-medium leading-normal">+12.5% this month</p>
          </div>
          <div
            class="flex flex-col gap-2 rounded-xl p-6 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
            <p class="text-gray-600 dark:text-gray-300 text-base font-medium leading-normal">Active Customers</p>
            <p class="text-gray-900 dark:text-white tracking-light text-3xl font-bold leading-tight">3,241</p>
            <p class="text-green-600 dark:text-green-500 text-sm font-medium leading-normal">+8.2% this month</p>
          </div>
          <div
            class="flex flex-col gap-2 rounded-xl p-6 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
            <p class="text-gray-600 dark:text-gray-300 text-base font-medium leading-normal">Inventory Count</p>
            <p class="text-gray-900 dark:text-white tracking-light text-3xl font-bold leading-tight">1,892</p>
            <p class="text-red-600 dark:text-red-500 text-sm font-medium leading-normal">23 items low on stock</p>
          </div>
          <div
            class="flex flex-col gap-2 rounded-xl p-6 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800">
            <p class="text-gray-600 dark:text-gray-300 text-base font-medium leading-normal">New Orders</p>
            <p class="text-gray-900 dark:text-white tracking-light text-3xl font-bold leading-tight">178</p>
            <p class="text-green-600 dark:text-green-500 text-sm font-medium leading-normal">+5 since yesterday</p>
          </div>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div class="lg:col-span-2 flex flex-col gap-8">
            <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
              <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight mb-4">Quick
                Actions</h2>
              <div class="grid grid-cols-2 sm:grid-cols-3 gap-4">
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-primary/10 dark:bg-primary/20 hover:bg-primary/20 dark:hover:bg-primary/30 text-primary transition-colors">
                  <span class="material-symbols-outlined text-3xl">add_shopping_cart</span>
                  <span class="text-sm font-medium">New Sale</span>
                </button>
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                  <span class="material-symbols-outlined text-3xl">add_box</span>
                  <span class="text-sm font-medium">Add Product</span>
                </button>
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                  <span class="material-symbols-outlined text-3xl">person_add</span>
                  <span class="text-sm font-medium">Add Customer</span>
                </button>
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                  <span class="material-symbols-outlined text-3xl">calendar_add_on</span>
                  <span class="text-sm font-medium">New Booking</span>
                </button>
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                  <span class="material-symbols-outlined text-3xl">receipt_long</span>
                  <span class="text-sm font-medium">Create Invoice</span>
                </button>
                <button
                  class="flex flex-col items-center justify-center gap-2 p-4 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors">
                  <span class="material-symbols-outlined text-3xl">bar_chart</span>
                  <span class="text-sm font-medium">View Reports</span>
                </button>
              </div>
            </div>
            <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
              <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight mb-4">Recent
                Orders</h2>
              <div class="overflow-x-auto">
                <table class="w-full text-left">
                  <thead>
                    <tr class="text-sm text-gray-500 dark:text-gray-400 border-b border-gray-200 dark:border-gray-700">
                      <th class="py-3 px-4 font-medium">Customer Name</th>
                      <th class="py-3 px-4 font-medium">Product</th>
                      <th class="py-3 px-4 font-medium">Date</th>
                      <th class="py-3 px-4 font-medium">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                      <td class="py-3 px-4 flex items-center gap-3">
                        <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full size-8"
                          data-alt="avatar of Olivia Martin"
                          style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBKqYQ-lFCKRgrfI4EPnefW878hsy7gNRqQPqj8s8E5Ge1-_XBtng98qY0IAC49HZtbBQbq_Xmm4WmqZTwnBA_u537-Oo3_Bo4ROEj9ufUtCi4z9_rT-JasRis5CI7aU-r4EgoVDyUSSL43L90Fx5kY6QLXVMw6PuhYB_Wpdku2jGXGTXlkeOHm_Q2XgxRygRF4fkXUKJxzjygS0_ITnoHauhzBh15UCG0VN28rIU4wC0Q1FFpiLqZxefa17HrnD0ReSRauHALa7YI");'>
                        </div>
                        Olivia Martin
                      </td>
                      <td class="py-3 px-4">Vintage Leather Jacket</td>
                      <td class="py-3 px-4">2024-07-21</td>
                      <td class="py-3 px-4"><span
                          class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2 py-1 rounded-full">Shipped</span>
                      </td>
                    </tr>
                    <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                      <td class="py-3 px-4 flex items-center gap-3">
                        <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full size-8"
                          data-alt="avatar of Liam Johnson"
                          style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbXVPxwq9gR05ET4Kg0zCkBedYQjSJZmR3DH8SdyUnxZGoM_metNxBWCUUuSnCOssD-X8VxfXiG9Yn8EfI7K0CBy89bmtD6VOri4Otu7fyWyW17ze__SksK4FO4Nm3RhWu-tuH6YoqZe3BrXGRN0eEcf4YPYy9ZVCVUjpcTsQ7vITeB-vBntfVqWXHEoBs6-F3MNAfRrD6TPd_ulew3ZSwkPOR99c991viv5iDIKdMeoP5NnXZHRFkvdpt45KCw-xhpWJaokfXO-4");'>
                        </div>
                        Liam Johnson
                      </td>
                      <td class="py-3 px-4">Wireless Headphones</td>
                      <td class="py-3 px-4">2024-07-20</td>
                      <td class="py-3 px-4"><span
                          class="bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400 text-xs font-medium px-2 py-1 rounded-full">Delivered</span>
                      </td>
                    </tr>
                    <tr class="border-b border-gray-200 dark:border-gray-800 text-sm">
                      <td class="py-3 px-4 flex items-center gap-3">
                        <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full size-8"
                          data-alt="avatar of Noah Williams"
                          style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC0-OZADNa-IOAewhuFRea32GhnTvSizf8IS7oJQCoW7uVPOToTNdbnfTGSgQdK2_aazL5e3yrXwWx9ytQRzabYngl2KRa100dLvLcWHTf8YH24sSOeI_cUDKZTq154ssb9O_ltPlYsH_elSHIo5jkwQ8hYYdKSESjp5-M_aY2blXiJ1y-xpC-Q0x7GWNq3JGWv52TwBe_bbUyVrAmWaRkl5zg1G8ld4KFLDZxeB_IGkorYr_4N8EAD49G9_7E9KOu9S0MyWLhLHXs");'>
                        </div>
                        Noah Williams
                      </td>
                      <td class="py-3 px-4">Organic Green Tea</td>
                      <td class="py-3 px-4">2024-07-19</td>
                      <td class="py-3 px-4"><span
                          class="bg-yellow-100 text-yellow-700 dark:bg-yellow-900/50 dark:text-yellow-400 text-xs font-medium px-2 py-1 rounded-full">Processing</span>
                      </td>
                    </tr>
                    <tr class="text-sm">
                      <td class="py-3 px-4 flex items-center gap-3">
                        <div class="bg-center bg-no-repeat aspect-square bg-cover rounded-full size-8"
                          data-alt="avatar of Emma Brown"
                          style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC_yRDDWRHorUiz0qbFEELV1j4CH5u7Pi8lNcqwN_NtNOzzmmXcLVj1axHQygvNQtzXQuDy_WkVr48kqu5bnmVmaRknP1wRgyFHJ0ERmHZ1ExwN-9Wqgojlr03kwVw9G0tQZ1LAdNn1qJJqPVvUwb4YiQRrkrevxFplJFS3LWtv2j3JA8GtCWs8wVtXw44pdWfb7d68qYZ-F37TizWABbG75ItHnbVZC8XlKJTD_otQmgkGtRdNZeoKOiYLoBJNe3JIPJHtx766U-8");'>
                        </div>
                        Emma Brown
                      </td>
                      <td class="py-3 px-4">Modern Art Print</td>
                      <td class="py-3 px-4">2024-07-18</td>
                      <td class="py-3 px-4"><span
                          class="bg-red-100 text-red-700 dark:bg-red-900/50 dark:text-red-400 text-xs font-medium px-2 py-1 rounded-full">Cancelled</span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
          <div class="lg:col-span-1 flex flex-col gap-8">
            <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
              <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight mb-4">Top Selling
                Products</h2>
              <div class="flex flex-col gap-4">
                <div class="flex gap-4 items-center">
                  <div class="w-16 h-16 rounded-lg bg-gray-100 dark:bg-gray-800 flex shrink-0 bg-cover bg-center"
                    style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuBKqYQ-lFCKRgrfI4EPnefW878hsy7gNRqQPqj8s8E5Ge1-_XBtng98qY0IAC49HZtbBQbq_Xmm4WmqZTwnBA_u537-Oo3_Bo4ROEj9ufUtCi4z9_rT-JasRis5CI7aU-r4EgoVDyUSSL43L90Fx5kY6QLXVMw6PuhYB_Wpdku2jGXGTXlkeOHm_Q2XgxRygRF4fkXUKJxzjygS0_ITnoHauhzBh15UCG0VN28rIU4wC0Q1FFpiLqZxefa17HrnD0ReSRauHALa7YI")'>
                  </div>
                  <div>
                    <h3 class="font-semibold text-gray-800 dark:text-gray-100">Vintage Leather Jacket</h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400">124 sold</p>
                  </div>
                </div>
                <div class="flex gap-4 items-center">
                  <div class="w-16 h-16 rounded-lg bg-gray-100 dark:bg-gray-800 flex shrink-0 bg-cover bg-center"
                    style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuAbXVPxwq9gR05ET4Kg0zCkBedYQjSJZmR3DH8SdyUnxZGoM_metNxBWCUUuSnCOssD-X8VxfXiG9Yn8EfI7K0CBy89bmtD6VOri4Otu7fyWyW17ze__SksK4FO4Nm3RhWu-tuH6YoqZe3BrXGRN0eEcf4YPYy9ZVCVUjpcTsQ7vITeB-vBntfVqWXHEoBs6-F3MNAfRrD6TPd_ulew3ZSwkPOR99c991viv5iDIKdMeoP5NnXZHRFkvdpt45KCw-xhpWJaokfXO-4")'>
                  </div>
                  <div>
                    <h3 class="font-semibold text-gray-800 dark:text-gray-100">Wireless Headphones</h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400">98 sold</p>
                  </div>
                </div>
                <div class="flex gap-4 items-center">
                  <div class="w-16 h-16 rounded-lg bg-gray-100 dark:bg-gray-800 flex shrink-0 bg-cover bg-center"
                    style='background-image: url("https://lh3.googleusercontent.com/aida-public/AB6AXuC0-OZADNa-IOAewhuFRea32GhnTvSizf8IS7oJQCoW7uVPOToTNdbnfTGSgQdK2_aazL5e3yrXwWx9ytQRzabYngl2KRa100dLvLcWHTf8YH24sSOeI_cUDKZTq154ssb9O_ltPlYsH_elSHIo5jkwQ8hYYdKSESjp5-M_aY2blXiJ1y-xpC-Q0x7GWNq3JGWv52TwBe_bbUyVrAmWaRkl5zg1G8ld4KFLDZxeB_IGkorYr_4N8EAD49G9_7E9KOu9S0MyWLhLHXs")'>
                  </div>
                  <div>
                    <h3 class="font-semibold text-gray-800 dark:text-gray-100">Modern Art Print</h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400">72 sold</p>
                  </div>
                </div>
              </div>
            </div>
            <div class="bg-white dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-800 p-6">
              <h2 class="text-gray-900 dark:text-white text-xl font-bold leading-tight tracking-tight mb-4">Sales Trends
              </h2>
              <div class="flex items-end justify-between h-48 gap-3">
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-primary/20 dark:bg-primary/30 rounded-t-md" style="height: 60%;"></div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">Feb</span>
                </div>
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-primary/20 dark:bg-primary/30 rounded-t-md" style="height: 75%;"></div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">Mar</span>
                </div>
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-primary/20 dark:bg-primary/30 rounded-t-md" style="height: 50%;"></div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">Apr</span>
                </div>
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-primary/20 dark:bg-primary/30 rounded-t-md" style="height: 85%;"></div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">May</span>
                </div>
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-primary/20 dark:bg-primary/30 rounded-t-md" style="height: 65%;"></div>
                  <span class="text-xs text-gray-500 dark:text-gray-400">Jun</span>
                </div>
                <div class="flex flex-col items-center justify-end h-full gap-2">
                  <div class="w-8 bg-primary rounded-t-md" style="height: 95%;"></div>
                  <span class="text-xs text-primary font-semibold">Jul</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    `
  }

}
