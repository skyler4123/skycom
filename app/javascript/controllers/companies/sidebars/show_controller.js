// Slack-style sidebar renderer: a Favourites section (star toggles) + collapsible
// <details> groups. Static structure comes from controllers/companies/sidebar_items;
// custom (dynamic sidebar) groups come from controllers/companies/sidebar_custom
// (the active sidebar_groups CompanySetting in the client cache) and render ABOVE the static groups.
// Per-employee favourites + open-group state live in controllers/companies/sidebar_storage.
// FE-only — no server calls (docs/SIDEBAR.md).
import { Controller } from "@hotwired/stimulus"
import { SIDEBAR_ITEMS, SIDEBAR_GROUPS } from "controllers/companies/sidebar_items"
import { customSidebarGroups, customSidebarItems } from "controllers/companies/sidebar_custom"
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

  userId() {
    return (typeof currentUser === "function" ? currentUser()?.id : null) || null
  }

  groupConfig(groupKey) {
    return SIDEBAR_GROUPS.find(g => g.key === groupKey)
      || customSidebarGroups().find(g => g.key === groupKey)
  }

  // Regular items are starable: not coming-soon and not in a locked (System) group.
  starable(item) {
    return !item.comingSoon && !this.groupConfig(item.group)?.locked
  }

  toggleStar(event) {
    const key = event.currentTarget.dataset.sidebarStar
    toggleFavourite(this.companyId(), key, this.userId())
    this.render()
  }

  groupToggled(event) {
    const key = event.currentTarget.dataset.sidebarGroup
    setGroupOpen(this.companyId(), key, event.currentTarget.open, this.userId())
  }

  render() {
    this.element.innerHTML = this.sidebarHTML()
    this.markCurrentPath()
  }

  // Sidebar search (FE-only): filter the sidebar item pool by the typed
  // prefix (case-insensitive) and render matching items as clickable links.
  searchSidebar(event) {
    const input = event.currentTarget
    const query = (input?.value || "").toLowerCase().trim()
    const container = this.element.querySelector("[data-sidebar-search-results]")
    if (!container) return

    if (!query) {
      container.innerHTML = ""
      return
    }

    const pool = [...SIDEBAR_ITEMS, ...customSidebarItems()]
    const matches = pool.filter((item) => {
      const label = item.custom ? item.label : translate(item.label)
      return (label || "").toLowerCase().startsWith(query)
    })

    container.innerHTML = matches.map((item) => this.searchResultHTML(item)).join("\n")
  }

  searchResultHTML(item) {
    const cid = this.companyId()
    const labelHTML = item.custom ? escapeHtml(item.label) : translate(item.label)
    const href = item.custom ? escapeHtml(item.href(cid)) : item.href(cid)
    return `
      <a
        class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-muted"
        href="${href}"
        data-sidebar-link
        ${openByPathname()}
      >
        <span class="material-symbols-outlined">${item.icon}</span>
        <p class="text-sm font-medium leading-normal min-w-0 flex-1 truncate">${labelHTML}</p>
      </a>
    `
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
      ${this.searchHTML()}
      ${this.favouritesHTML()}
      ${customSidebarGroups().map(g => this.groupHTML(g)).join("\n")}
      ${SIDEBAR_GROUPS.map(g => this.groupHTML(g)).join("\n")}
    `
  }

  findItem(key) {
    return SIDEBAR_ITEMS.find(i => i.key === key)
      || customSidebarItems().find(i => i.key === key)
  }

  favouritesHTML() {
    const cid = this.companyId()
    const uid = this.userId()
    const favItems = favourites(cid, uid)
      .map(key => this.findItem(key))
      .filter(Boolean)

    const body = favItems.length > 0
      ? favItems.map(item => this.itemHTML(item)).join("\n")
      : `<p class="px-3 py-2 text-xs text-muted-foreground">${translate("Click the star on any item to pin it here")}</p>`

    return `
      <div class="flex flex-col gap-1 pb-2 mb-2 border-b border-line" data-sidebar-favourites>
        <p class="px-3 pt-1 pb-1 text-sm font-medium leading-normal text-foreground flex items-center gap-1">
          <span class="material-symbols-outlined text-[14px]! text-warning" style="font-variation-settings: 'FILL' 1">star</span>
          ${translate("Favourites")}
        </p>
        ${body}
      </div>
    `
  }

  // Search box rendered ABOVE the Favourites section. FE-only: filters the
  // sidebar item pool (static + custom) by a case-insensitive prefix and
  // renders the matches as clickable links.
  searchHTML() {
    return `
      <div class="flex flex-col gap-1 pb-2 mb-2 border-b border-line" data-sidebar-search>
        <label for="sidebar-search" class="sr-only">${translate("Search sidebar")}</label>
        <div class="flex items-center gap-2 px-2 py-1.5 rounded-lg bg-muted border border-line">
          <span class="material-symbols-outlined text-[18px] text-muted-foreground">search</span>
          <input
            id="sidebar-search"
            name="sidebar_search"
            type="search"
            class="flex-1 min-w-0 bg-transparent border-none outline-none text-sm text-foreground placeholder:text-muted-foreground"
            placeholder="${translate("Search sidebar items...")}"
            aria-label="${translate("Search sidebar")}"
            data-sidebar-search-input
            data-action="input->${this.identifier}#searchSidebar"
          />
        </div>
        <div data-sidebar-search-results class="flex flex-col gap-1"></div>
      </div>
    `
  }

  groupHTML(groupConfig) {
    const items = [
      ...SIDEBAR_ITEMS.filter(i => i.group === groupConfig.key),
      ...customSidebarItems().filter(i => i.group === groupConfig.key)
    ]
    const isOpen = isGroupOpen(this.companyId(), groupConfig.key, this.userId())

    return `
      <details
        class="flex flex-col"
        data-sidebar-group="${groupConfig.key}"
        ${isOpen ? "open" : ""}
        data-action="toggle->${this.identifier}#groupToggled"
      >
        <summary class="flex items-center justify-between gap-2 px-3 py-2 rounded-lg cursor-pointer hover:bg-muted select-none list-none [&::-webkit-details-marker]:hidden">
          <span class="text-sm font-medium leading-normal text-foreground flex items-center gap-1"
            ${groupConfig.comingSoon ? tooltip({ html: translate("Coming soon"), position: "right" }) : ""}>
            ${translate(groupConfig.label)}
            ${groupConfig.comingSoon ? `<span class="material-symbols-outlined text-[14px]! text-warning ">error</span>` : ""}
          </span>
          <span class="text-xs text-muted-foreground">${items.length}</span>
        </summary>
        <div class="flex flex-col gap-1 pt-1">
          ${items.map(item => this.itemHTML(item)).join("\n")}
        </div>
      </details>
    `
  }

  itemHTML(item) {
    const cid = this.companyId()
    // Custom (dynamic sidebar) labels + urls are user-controlled — escape them.
    // Static labels go through translate() (trusted dictionary strings).
    const labelHTML = item.custom ? escapeHtml(item.label) : translate(item.label)
    const href = item.custom ? escapeHtml(item.href(cid)) : item.href(cid)
    if (item.comingSoon) {
      return `
        <span class="flex items-center gap-3 px-3 py-2 rounded-lg cursor-not-allowed"
          ${tooltip({ html: translate("Coming soon"), position: "right" })}>
          <span class="material-symbols-outlined">${item.icon}</span>
          <p class="text-sm font-medium leading-normal flex items-center gap-1">${translate(item.label)}
            <span class="material-symbols-outlined text-[14px]! text-warning ">error</span>
          </p>
        </span>
      `
    }

    const starred = isFavourite(cid, item.key, this.userId())
    const star = this.starable(item) ? `
      <button
        type="button"
        data-sidebar-star="${item.key}"
        data-sidebar-starred="${starred}"
        data-action="click->${this.identifier}#toggleStar"
        class="ml-auto flex items-center justify-center p-1 rounded-md shrink-0 cursor-pointer ${starred ? "text-warning hover:text-warning hover:bg-warning/10 " : "text-muted-foreground/60 hover:text-warning hover:bg-warning/10 "}"
        ${tooltip({ html: translate(starred ? "Click to remove from favourites" : "Click to favourite"), position: "right" })}
      >
        <span class="material-symbols-outlined text-[18px]!" ${starred ? `style="font-variation-settings: 'FILL' 1"` : ""}>star</span>
      </button>
    ` : ""

    // Row wrapper: the star button is a sibling of the link — a <button> must
    // not be nested inside an <a> (starring would also navigate). The row
    // highlight follows the link's `open` attribute (set by markCurrentPath()
    // and the open controller's openByPathname targets).
    return `
      <div
        class="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-muted has-[a[open]]:bg-primary/10 has-[a[open]]:text-primary"
      >
        <a
          class="flex min-w-0 flex-1 items-center gap-3"
          href="${href}"
          data-sidebar-link
          ${openByPathname()}
        >
          <span class="material-symbols-outlined">${item.icon}</span>
          <p class="text-sm font-medium leading-normal min-w-0 flex-1 truncate">${labelHTML}</p>
        </a>
        ${star}
      </div>
    `
  }
}
