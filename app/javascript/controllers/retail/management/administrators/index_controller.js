
import Retail_Management_LayoutController from "controllers/retail/management/layout_controller"

export default class Retail_Management_Administrators_IndexController extends Retail_Management_LayoutController {

  connect() {
    // console.log(Helpers.randomId())
    this.openPermissionGroup = Helpers.randomId()
    // 1. Let the parent class setup retail/companyGroups
    super.connect();

    // 2. Fetch the permissions only once when the controller connects
    if (this.retail) {
      this.fetchData();
    }
  }

  // STOP: Do NOT override the render() method. 
  // The parent class render() already calls this.contentHTML()

  async fetchData() {
    try {
      const url = Helpers.retail_management_permissions_path(this.retail.id);
      const response = await window.fetchJson(url);
      
      // Store the data
      this.permissions = response?.permissions || [];
      
      // 3. Trigger a re-render now that the data is loaded
      this.render(); 
    } catch (error) {
      console.error("Failed to load permissions:", error);
      this.permissions = [];
      this.render();
    }
  }

  // Helper to generate the table for a specific role
  renderRoleTable(roleKey, roleData) {
    // 1. Group policies by resource
    const resources = {};
    roleData.policies.forEach(policy => {
      if (!resources[policy.resource]) {
        resources[policy.resource] = { create: false, read: false, update: false, delete: false };
      }
      resources[policy.resource][policy.action] = true;
    });

    const title = roleKey.split('_').map(w => Helpers.capitalize(w)).join(' ');

    return `
      <div
        class="hidden bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 open:flex flex-col overflow-hidden shadow-sm"
        ${Helpers.openListener(this.openPermissionGroup, roleKey)}
      >
        <div class="p-4 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center bg-slate-50 dark:bg-slate-800/50">
          <h2 class="text-base font-bold text-slate-900 dark:text-white">Permissions for: <span class="text-blue-600">${title}</span></h2>
          <button class="px-4 py-1.5 bg-slate-900 text-white dark:bg-white dark:text-slate-900 text-sm font-medium rounded-lg">Save Changes</button>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse">
            <thead class="bg-slate-50 dark:bg-slate-800 border-b border-slate-200 dark:border-slate-800">
              <tr>
                <th class="p-4 text-slate-500 text-xs uppercase w-1/3">Resource Name</th>
                <th class="p-4 text-slate-500 text-xs uppercase text-center">Create</th>
                <th class="p-4 text-slate-500 text-xs uppercase text-center">Read</th>
                <th class="p-4 text-slate-500 text-xs uppercase text-center">Update</th>
                <th class="p-4 text-slate-500 text-xs uppercase text-center">Delete</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 dark:divide-slate-800">
              ${Object.entries(resources).map(([resName, actions]) => `
                <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                  <td class="p-4 text-sm font-medium flex items-center gap-2">
                    <span class="material-symbols-outlined text-slate-400 text-[20px]">${this.getResourceIcon(resName)}</span>
                    ${resName}
                  </td>
                  <td class="p-4 text-center">${this.checkbox(actions.create)}</td>
                  <td class="p-4 text-center">${this.checkbox(actions.read)}</td>
                  <td class="p-4 text-center">${this.checkbox(actions.update)}</td>
                  <td class="p-4 text-center">${this.checkbox(actions.delete)}</td>
                </tr>
              `).join("")}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }

  checkbox(checked) {
    return `<input type="checkbox" ${checked ? 'checked' : ''} class="rounded border-slate-300 text-blue-600 h-5 w-5 pointer-events-none" />`;
  }

  getResourceIcon(name) {
    const icons = { 'Order': 'shopping_bag', 'Product': 'inventory_2', 'Employee': 'badge', 'Customer': 'group' };
    return icons[name] || 'description';
  }

  contentHTML() {
    // 4. Handle the "Wait" state. If data hasn't arrived, show a loader.
    if (!this.permissions) {
      return `
        <div class="p-8 flex items-center justify-center h-full">
          <div class="animate-pulse text-slate-500 font-medium">Loading RBAC Policies...</div>
        </div>
      `;
    }

    // 5. Data is ready! Render your full template

    return `
      <div class="p-8 h-full flex flex-col">
        <div class="flex flex-wrap justify-between items-end gap-4 mb-8">
          <div class="flex flex-col gap-1">
            <h1 class="text-slate-900 dark:text-white text-3xl font-bold tracking-tight">Role & Policy Management</h1>
            <p class="text-slate-500 dark:text-slate-400 text-base">Configure RBAC rules and permissions.</p>
          </div>
          <div class="flex items-center gap-3">
            <div class="relative">
              <span class="absolute inset-y-0 left-0 flex items-center pl-3 text-slate-400">
                <span class="material-symbols-outlined text-[20px]">search</span>
              </span>
              <input
                class="pl-10 pr-4 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-sm focus:ring-blue-600 focus:border-blue-600 w-64"
                placeholder="Filter roles..." type="text" />
            </div>
            <button
              class="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 transition-colors shadow-sm">
              <span class="material-symbols-outlined text-[18px]">add</span> Add New Role
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-4 gap-6 flex-1 min-h-0">
          <div
            class="lg:col-span-1 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 flex flex-col overflow-hidden shadow-sm">
            <div class="p-4 border-b border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-800/50">
              <h2 class="text-xs font-bold uppercase text-slate-500 tracking-wider">Defined Roles</h2>
            </div>
            <div class="overflow-y-auto flex-1 p-2 space-y-1">
              ${
                Object.entries(this.permissions).map(([key, value]) => `
                  <button
                    class="w-full flex items-center justify-between p-3 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300"
                    ${Helpers.openTrigger(this.openPermissionGroup, key)}
                  >
                    <div class="flex items-center gap-3">
                      <span class="material-symbols-outlined">shield_person</span>
                      <div class="text-left">
                        <p class="font-medium text-sm">${key}</p>
                        <p class="text-xs opacity-70">14 Active Users</p>
                      </div>
                    </div>
                    <span class="material-symbols-outlined text-[18px]">chevron_right</span>
                  </button>
                `).join("")
              }
            </div>
          </div>

          <div class="lg:col-span-3 flex flex-col gap-8">
            ${Object.entries(this.permissions).map(([roleKey, roleData]) => this.renderRoleTable(roleKey, roleData)).join("")}
          </div>
        </div>
      </div>
    `
  }

}