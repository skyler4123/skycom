// Slack-style sidebar renderer: a Favourites section (star toggles) + collapsible
// <details> groups. Structural data comes from controllers/companies/sidebar_items;
// per-company favourites + open-group state live in controllers/companies/sidebar_storage.
// FE-only — no server calls, no client-cache coupling (docs/SIDEBAR.md).
import { Controller } from "@hotwired/stimulus"
import { SIDEBAR_ITEMS, SIDEBAR_GROUPS } from "controllers/companies/sidebar_items"
import {
  favourites, isFavourite, toggleFavourite, isGroupOpen, setGroupOpen
} from "controllers/companies/sidebar_storage"

export default class Companies_Sidebars_ShowController extends Controller {
  connect() {
    this.render()
  }

  companyId() {
    return currentCompany()?.id
  }

  groupConfig(groupKey) {
    return SIDEBAR_GROUPS.find(g => g.key === groupKey)
  }

  // Regular items are starable: not coming-soon and not in a locked (System) group.
  starable(item) {
    return !item.comingSoon && !this.groupConfig(item.group)?.locked
  }

  toggleStar(event) {
    const key = event.currentTarget.dataset.sidebarStar
    toggleFavourite(this.companyId(), key)
    this.render()
  }

  groupToggled(event) {
    const key = event.currentTarget.dataset.sidebarGroup
    setGroupOpen(this.companyId(), key, event.currentTarget.open)
  }

  render() {
    this.element.innerHTML = this.sidebarHTML()
    this.markCurrentPath()
  }

  // Re-apply current-page highlighting after a re-render (star click) wipes the
  // DOM nodes that the aside's open controller had marked on connect.
  markCurrentPath() {
    const currentPath = window.location.pathname
    this.element.querySelectorAll("a[data-sidebar-link]").forEach((link) => {
      if (link.href && new URL(link.href).pathname === currentPath) {
        link.setAttribute("open", "")
      } else {
        link.removeAttribute("open")
      }
    })
  }

  sidebarHTML() {
    return `
      ${this.favouritesHTML()}
      ${SIDEBAR_GROUPS.map(g => this.groupHTML(g)).join("\n")}
    `
  }

  favouritesHTML() {
    const cid = this.companyId()
    const favItems = favourites(cid)
      .map(key => SIDEBAR_ITEMS.find(i => i.key === key))
      .filter(Boolean)

    const body = favItems.length > 0
      ? favItems.map(item => this.itemHTML(item)).join("\n")
      : `<p class="px-3 py-2 text-xs text-slate-400 dark:text-slate-500">${translate("Click the star on any item to pin it here")}</p>`

    return `
      <div class="flex flex-col gap-1 pb-2 mb-2 border-b border-gray-200 dark:border-gray-700" data-sidebar-favourites>
        <p class="px-3 pt-1 pb-1 text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 flex items-center gap-1">
          <span class="material-symbols-outlined text-[14px] text-amber-500" style="font-variation-settings: 'FILL' 1">star</span>
          ${translate("Favourites")}
        </p>
        ${body}
      </div>
    `
  }

  groupHTML(groupConfig) {
    const items = SIDEBAR_ITEMS.filter(i => i.group === groupConfig.key)
    const isOpen = isGroupOpen(this.companyId(), groupConfig.key)

    return `
      <details
        class="flex flex-col"
        data-sidebar-group="${groupConfig.key}"
        ${isOpen ? "open" : ""}
        data-action="toggle->${this.identifier}#groupToggled"
      >
        <summary class="flex items-center justify-between gap-2 px-3 py-2 rounded-lg cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-800 select-none list-none [&::-webkit-details-marker]:hidden">
          <span class="text-[10px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500 flex items-center gap-1"
            ${groupConfig.comingSoon ? tooltip({ html: translate("Coming soon"), position: "right" }) : ""}>
            ${translate(groupConfig.label)}
            ${groupConfig.comingSoon ? `<span class="material-symbols-outlined text-[14px] text-amber-500 dark:text-amber-400">error</span>` : ""}
          </span>
          <span class="text-[10px] text-slate-400 dark:text-slate-500">${items.length}</span>
        </summary>
        <div class="flex flex-col gap-1 pt-1">
          ${items.map(item => this.itemHTML(item)).join("\n")}
        </div>
      </details>
    `
  }

  itemHTML(item) {
    const cid = this.companyId()
    if (item.comingSoon) {
      return `
        <span class="flex items-center gap-3 px-3 py-2 rounded-lg cursor-not-allowed"
          ${tooltip({ html: translate("Coming soon"), position: "right" })}>
          <span class="material-symbols-outlined">${item.icon}</span>
          <p class="text-sm font-medium leading-normal flex items-center gap-1">${translate(item.label)}
            <span class="material-symbols-outlined text-[14px] text-amber-500 dark:text-amber-400">error</span>
          </p>
        </span>
      `
    }

    const starred = isFavourite(cid, item.key)
    const star = this.starable(item) ? `
      <button
        type="button"
        data-sidebar-star="${item.key}"
        data-sidebar-starred="${starred}"
        data-action="click->${this.identifier}#toggleStar"
        class="ml-auto flex items-center justify-center p-1 rounded-md shrink-0 cursor-pointer ${starred ? "text-amber-500 hover:text-amber-600 hover:bg-amber-50 dark:hover:bg-amber-900/20" : "text-slate-300 dark:text-slate-600 hover:text-amber-500 hover:bg-amber-50 dark:hover:bg-amber-900/20"}"
        ${tooltip({ html: translate(starred ? "Click to remove from favourites" : "Click to favourite"), position: "right" })}
      >
        <span class="material-symbols-outlined text-[18px]" ${starred ? `style="font-variation-settings: 'FILL' 1"` : ""}>star</span>
      </button>
    ` : ""

    return `
      <a
        class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-800 open:bg-blue-100 open:text-blue-600"
        href="${item.href(cid)}"
        data-sidebar-link
        ${openByPathname()}
      >
        <span class="material-symbols-outlined">${item.icon}</span>
        <p class="text-sm font-medium leading-normal min-w-0 truncate">${translate(item.label)}</p>
        ${star}
      </a>
    `
  }
}
