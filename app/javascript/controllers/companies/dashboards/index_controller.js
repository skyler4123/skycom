import Companies_LayoutController from "controllers/companies/layout_controller"
import ApexCharts from "apexcharts"
import { chartPalette, chartGridColor, chartLabelColor, tokenColor } from "controllers/helpers/chart_colors"

// Depends on BE: Companies::DashboardsController#index
// Endpoints: GET /companies/:company_id/dashboards.json
export default class Companies_Dashboards_IndexController extends Companies_LayoutController {
  /** @type {object | null} */ dashboardData = null
  /** @type {ApexCharts[]} */ charts = []
  loading = true
  /** @type {string | null} */ error = null

  async connect() {
    super.connect()

    poll(() => {
      if (currentCompany()) {
        this.loadData()
        return true
      }
      return false
    })
  }

  async loadData() {
    this.loading = true
    this.error = null

    try {
      const response = await fetchJson(`${Helpers.company_dashboards_path(currentCompany().id)}.json`)
      this.dashboardData = response
    } catch (error) {
      this.error = error.errors?.join(", ") || error.message
    } finally {
      this.loading = false
      poll(() => {
        if (this.hasContentTarget) {
          this.destroyCharts()
          this.renderContent()
          this.renderCharts()
          return true
        }
        return false
      })
    }
  }

  reload() {
    this.loadData()
  }

  canViewFinancials() {
    return this.dashboardData?.permissions?.can_view_financials === true
  }

  currency() {
    return this.dashboardData?.company?.currency || "usd"
  }

  contentHTML() {
    if (this.loading) return this.loadingHTML()
    if (this.error) return this.errorHTML()
    if (!this.dashboardData) return this.emptyHTML(translate("No dashboard data available"))

    return `
      <div class="p-4 overflow-y-auto space-y-4">
        ${this.headerHTML()}
        ${this.companyMetaHTML()}
        ${this.kpisHTML()}
        ${this.chartsHTML()}
        ${this.attentionHTML()}
        ${this.operationalGridHTML()}
        ${this.bottomRowHTML()}
      </div>
    `
  }

  headerHTML() {
    const companyId = currentCompany().id

    return `
      <div class="flex flex-col gap-3 xl:flex-row xl:items-center xl:justify-between">
        <div>
          <h1 class="text-2xl font-black text-foreground">${translate("Company health")}</h1>
          <p class="text-sm text-muted-foreground mt-1">${translate("What needs attention across your company right now.")}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-muted text-muted-foreground text-xs font-semibold">
            <span class="material-symbols-outlined text-[16px]">calendar_today</span>
            ${translate("This month")}
          </span>
          ${this.canViewFinancials() ? `
            <a href="${Helpers.company_analytics_path(companyId)}"
              class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-primary text-primary-foreground text-xs font-semibold hover:bg-primary/90">
              <span class="material-symbols-outlined text-[16px]">insights</span>
              ${translate("Open Analytics")}
            </a>
          ` : ""}
        </div>
      </div>
    `
  }

  companyMetaHTML() {
    const c = this.dashboardData.company || {}
    const owner = c.owner
    const ownerName = owner ? [ owner.first_name, owner.last_name ].filter(Boolean).join(" ") || owner.email : "—"
    const address = [ c.address_line_1, c.city, c.postal_code ].filter(Boolean).join(", ") || "—"
    const timezone = this.timezoneLabel(c.timezone)

    return `
      <div class="bg-card border border-line rounded-xl p-4">
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div class="flex items-center gap-3 min-w-0">
            <div class="size-11 shrink-0 rounded-xl bg-primary/10 text-primary flex items-center justify-center">
              <span class="material-symbols-outlined text-[24px]">business</span>
            </div>
            <div class="min-w-0">
              <h2 class="text-lg font-bold text-foreground truncate">${this.escape(c.name)}</h2>
              <div class="flex flex-wrap items-center gap-2 mt-1 text-xs text-muted-foreground">
                ${c.code ? `<span class="font-mono bg-muted px-2 py-0.5 rounded">${this.escape(c.code)}</span>` : ""}
                <span>${translate("Branches")}: ${c.branches_count || 0}</span>
                <span>${translate("Active employees")}: ${c.active_employees_count || 0}</span>
                <span>${(c.currency || "usd").toUpperCase()}</span>
              </div>
            </div>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            ${c.business_type ? Helpers.statusBadge(c.business_type) : ""}
            ${c.workflow_status ? Helpers.statusBadge(c.workflow_status) : ""}
          </div>
        </div>

        <details class="mt-3 pt-3 border-t border-line">
          <summary class="cursor-pointer text-xs font-semibold text-primary">${translate("Company details")}</summary>
          <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 mt-3">
            ${this.metaItem("location_on", translate("Address"), address)}
            ${this.metaItem("call", translate("Phone"), c.phone_number || "—")}
            ${this.metaItem("mail", translate("Email"), c.email || "—")}
            ${this.metaItem("language", translate("Website"), c.website || "—")}
            ${this.metaItem("person", translate("Owner"), ownerName)}
            ${this.metaItem("schedule", translate("Timezone"), timezone)}
            ${this.metaItem("calendar_today", translate("Created"), this.formatDate(c.created_at))}
          </div>
        </details>
      </div>
    `
  }

  metaItem(icon, label, value) {
    return `
      <div class="min-w-0">
        <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${label}</p>
        <p class="text-sm text-foreground flex items-center gap-1.5 min-w-0">
          <span class="material-symbols-outlined text-[15px] text-muted-foreground shrink-0">${icon}</span>
          <span class="truncate">${this.escape(value)}</span>
        </p>
      </div>
    `
  }

  kpisHTML() {
    const k = this.dashboardData.kpis || {}
    const financial = this.canViewFinancials()
    const cards = []

    if (financial) {
      cards.push(this.kpiCard("revenue", translate("Revenue"), Helpers.formatMoney(k.revenue_cents, this.currency()), "payments", this.deltaBadge(k.revenue_delta_pct)))
      cards.push(this.kpiCard("orders", translate("Orders"), k.orders_count ?? 0, "receipt_long", this.deltaBadge(k.orders_delta_pct)))
      cards.push(this.kpiCard("aov", translate("Average order value"), Helpers.formatMoney(k.avg_order_value_cents, this.currency()), "shopping_bag", this.deltaBadge(k.avg_order_value_delta_pct)))
      cards.push(this.kpiCard("margin", translate("Gross margin"), this.percent(k.gross_margin_pct), "pie_chart", `${this.percent(k.cost_coverage_pct)} ${translate("cost coverage")}`))
    } else {
      cards.push(this.kpiCard("orders", translate("Orders"), k.orders_count ?? 0, "receipt_long", this.deltaBadge(k.orders_delta_pct)))
    }

    cards.push(this.kpiCard("customers", translate("Active customers"), k.active_customers_count ?? 0, "group", `${k.new_customers_count ?? 0} ${translate("new")}`))
    cards.push(this.kpiCard("low-stock", translate("Low stock"), k.low_stock_count ?? 0, "warning", translate("Below safety threshold"), k.low_stock_count > 0 ? "danger" : "default"))
    cards.push(this.kpiCard("approvals", translate("Pending approvals"), k.pending_approvals_count ?? 0, "pending_actions", translate("Open inbox"), k.pending_approvals_count > 0 ? "warning" : "default"))

    if (financial) {
      cards.push(this.kpiCard("credits", translate("Credits remaining"), this.number(k.credits_total), "account_balance_wallet"))
    }

    return `<div class="grid grid-cols-2 xl:grid-cols-4 gap-3" data-dashboard-section="kpis">${cards.join("")}</div>`
  }

  kpiCard(key, label, value, icon, helper = "", tone = "default") {
    const toneClass = tone === "danger" ? "text-danger bg-danger/10" : tone === "warning" ? "text-warning bg-warning/10" : "text-primary bg-primary/10"

    return `
      <div data-kpi="${key}" class="bg-card border border-line rounded-xl p-3.5 flex flex-col justify-between min-h-[110px]">
        <div class="flex items-start justify-between gap-2">
          <div class="min-w-0">
            <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${label}</p>
            <p class="text-2xl font-black text-foreground mt-1 truncate">${value}</p>
          </div>
          <div class="size-9 rounded-lg ${toneClass} flex items-center justify-center shrink-0">
            <span class="material-symbols-outlined text-[20px]">${icon}</span>
          </div>
        </div>
        <div class="mt-2 pt-2 border-t border-line text-[11px] text-muted-foreground flex items-center justify-between gap-2">
          <span class="truncate">${helper}</span>
        </div>
      </div>
    `
  }

  chartsHTML() {
    if (!this.canViewFinancials()) return ""

    const mix = this.dashboardData.revenue_mix || []
    const trend = this.dashboardData.trend || []
    const mixLegend = mix.length
      ? mix.map((row, index) => `
          <div class="flex items-center justify-between gap-2 text-xs">
            <span class="flex items-center gap-1.5 min-w-0">
              <span class="size-2 rounded-full shrink-0" style="background:${chartPalette(Math.max(mix.length, 1))[index % Math.max(mix.length, 1)]}"></span>
              <span class="truncate text-foreground">${this.escape(row.name || translate("Unassigned"))}</span>
            </span>
            <span class="text-muted-foreground shrink-0">${this.percent(row.pct)}</span>
          </div>
        `).join("")
      : this.emptyInline(translate("No revenue yet"))

    return `
      <div class="grid grid-cols-1 xl:grid-cols-12 gap-4">
        <div class="xl:col-span-8 bg-card border border-line rounded-xl p-4">
          <div class="flex items-start justify-between gap-2 mb-2">
            <div>
              <h2 class="text-base font-bold text-foreground">${translate("Revenue & orders")}</h2>
              <p class="text-xs text-muted-foreground">${translate("Last 30 days")}</p>
            </div>
            <div class="flex flex-wrap items-center gap-3 text-[11px] text-muted-foreground">
              <span class="inline-flex items-center gap-1"><span class="size-2 rounded-full bg-primary"></span>${translate("Revenue")}</span>
              <span class="inline-flex items-center gap-1"><span class="size-2 rounded-full bg-success"></span>${translate("Orders")}</span>
            </div>
          </div>
          ${trend.length ? `<div data-dashboard-chart="trend" class="h-64"></div>` : this.emptyInline(translate("No orders yet"))}
        </div>

        <div class="xl:col-span-4 bg-card border border-line rounded-xl p-4">
          <div class="mb-2">
            <h2 class="text-base font-bold text-foreground">${translate("Sales channels")}</h2>
            <p class="text-xs text-muted-foreground">${translate("Revenue mix this month")}</p>
          </div>
          ${mix.length ? `<div data-dashboard-chart="mix" class="h-44"></div>` : this.emptyInline(translate("No revenue yet"))}
          <div class="space-y-2 mt-3">${mixLegend}</div>
        </div>
      </div>
    `
  }

  attentionHTML() {
    const attention = this.dashboardData.attention || {}
    const approvals = attention.approvals || {}
    const financial = this.canViewFinancials()
    const companyId = currentCompany().id
    const sections = []

    sections.push(`
      <div data-attention="low-stock" class="space-y-2">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-bold text-foreground flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[17px] text-danger">inventory_2</span>
            ${translate("Low stock")}
          </h3>
          <a href="${Helpers.company_stocks_path(companyId)}" class="text-[11px] font-semibold text-primary hover:underline">${translate("View stock")}</a>
        </div>
        ${(attention.low_stock || []).length ? attention.low_stock.map((row) => `
          <div class="p-2.5 rounded-lg bg-muted flex items-start justify-between gap-3">
            <div class="min-w-0">
              <p class="text-xs font-semibold text-foreground truncate">${this.escape(row.product_name || translate("Unknown product"))}</p>
              <p class="text-[11px] text-muted-foreground truncate">${this.escape(row.warehouse_name || "—")}</p>
            </div>
            <span class="text-xs font-bold text-danger shrink-0">${this.number(row.available)} ${translate("left")}</span>
          </div>
        `).join("") : this.emptyInline(translate("Stock levels look healthy"))}
      </div>
    `)

    sections.push(`
      <div data-attention="approvals" class="space-y-2">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-bold text-foreground flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[17px] text-warning">pending_actions</span>
            ${translate("Pending approvals")}
          </h3>
          <span class="text-[11px] font-bold text-warning">${approvals.total ?? 0}</span>
        </div>
        ${this.approvalRow(translate("Purchases"), approvals.purchases, Helpers.company_purchases_path(companyId))}
        ${this.approvalRow(translate("Tickets"), approvals.tickets, Helpers.company_tickets_path(companyId))}
        ${this.approvalRow(translate("Attendance requests"), approvals.attendance_requests, Helpers.company_attendance_requests_path(companyId))}
      </div>
    `)

    if (financial) {
      sections.push(`
        <div data-attention="overdue-invoices" class="space-y-2">
          <div class="flex items-center justify-between">
            <h3 class="text-sm font-bold text-foreground flex items-center gap-1.5">
              <span class="material-symbols-outlined text-[17px] text-danger">receipt_long</span>
              ${translate("Overdue invoices")}
            </h3>
            <a href="${Helpers.company_invoices_path(companyId)}" class="text-[11px] font-semibold text-primary hover:underline">${translate("View invoices")}</a>
          </div>
          ${(attention.overdue_invoices || []).length ? attention.overdue_invoices.map((row) => `
            <div class="p-2.5 rounded-lg bg-muted flex items-start justify-between gap-3">
              <div class="min-w-0">
                <p class="text-xs font-semibold text-foreground truncate">${this.escape(row.name)}</p>
                <p class="text-[11px] text-muted-foreground">${translate("Due")} ${this.formatDate(row.due_date)}</p>
              </div>
              <span class="text-xs font-bold text-danger shrink-0">${Helpers.formatMoney(row.price_cents, this.currency())}</span>
            </div>
          `).join("") : this.emptyInline(translate("No overdue invoices"))}
        </div>
      `)
    }

    sections.push(`
      <div data-attention="urgent-tickets" class="space-y-2">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-bold text-foreground flex items-center gap-1.5">
            <span class="material-symbols-outlined text-[17px] text-danger">confirmation_number</span>
            ${translate("Urgent tickets")}
          </h3>
          <a href="${Helpers.company_tickets_path(companyId)}" class="text-[11px] font-semibold text-primary hover:underline">${translate("View tickets")}</a>
        </div>
        ${(attention.urgent_tickets || []).length ? attention.urgent_tickets.map((row) => `
          <div class="p-2.5 rounded-lg bg-muted flex items-start justify-between gap-3">
            <div class="min-w-0">
              <p class="text-xs font-semibold text-foreground truncate">${this.escape(row.name)}</p>
              <p class="text-[11px] text-muted-foreground truncate">${this.escape(row.assigned_to || translate("Unassigned"))}</p>
            </div>
            ${Helpers.statusBadge(row.priority)}
          </div>
        `).join("") : this.emptyInline(translate("No urgent tickets"))}
      </div>
    `)

    return `
      <div data-dashboard-section="attention" class="bg-card border border-line rounded-xl p-4">
        <div class="flex items-center justify-between mb-3">
          <div>
            <h2 class="text-base font-bold text-foreground">${translate("Needs attention")}</h2>
            <p class="text-xs text-muted-foreground">${translate("Live exceptions across operations, money, and stock.")}</p>
          </div>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-4 gap-4">${sections.join("")}</div>
      </div>
    `
  }

  approvalRow(label, count, href) {
    return `
      <a href="${href}" class="p-2.5 rounded-lg bg-muted flex items-center justify-between gap-2 hover:bg-muted/70">
        <span class="text-xs text-foreground">${label}</span>
        <span class="text-xs font-bold ${count > 0 ? "text-warning" : "text-muted-foreground"}">${count ?? 0}</span>
      </a>
    `
  }

  operationalGridHTML() {
    const financial = this.canViewFinancials()
    const cards = [ this.recentOrdersHTML() ]
    if (financial) cards.push(this.topCustomersHTML())
    cards.push(this.staffTodayHTML())

    return `<div class="grid grid-cols-1 xl:grid-cols-3 gap-4">${cards.join("")}</div>`
  }

  recentOrdersHTML() {
    const orders = this.dashboardData.recent_orders || []
    const companyId = currentCompany().id
    const financial = this.canViewFinancials()

    return `
      <div data-dashboard-section="recent-orders" class="bg-card border border-line rounded-xl p-4">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Recent orders")}</h2>
          <a href="${Helpers.company_orders_path(companyId)}" class="text-[11px] font-semibold text-primary hover:underline">${translate("View all")}</a>
        </div>
        ${orders.length ? orders.map((order) => `
          <a href="${Helpers.company_order_path(companyId, order.id)}" class="flex items-center justify-between gap-3 p-2.5 rounded-lg bg-muted hover:bg-muted/70 mb-2 last:mb-0">
            <div class="min-w-0">
              <div class="flex items-center gap-1.5">
                <span class="text-xs font-semibold text-foreground truncate">${this.escape(order.code || order.name)}</span>
                ${Helpers.statusBadge(order.workflow_status)}
              </div>
              <p class="text-[11px] text-muted-foreground truncate">${this.escape(order.customer_name || "—")}${order.branch_name ? ` · ${this.escape(order.branch_name)}` : ""}</p>
            </div>
            <div class="text-right shrink-0">
              ${financial && order.total_cents != null ? `<p class="text-xs font-bold text-foreground">${Helpers.formatMoney(order.total_cents, this.currency())}</p>` : ""}
              <p class="text-[10px] text-muted-foreground">${this.formatDate(order.created_at, "MMM D, HH:mm")}</p>
            </div>
          </a>
        `).join("") : this.emptyInline(translate("No orders yet"))}
      </div>
    `
  }

  topCustomersHTML() {
    const customers = this.dashboardData.top_customers || []
    const companyId = currentCompany().id

    return `
      <div data-dashboard-section="top-customers" class="bg-card border border-line rounded-xl p-4">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Top customers")}</h2>
          <a href="${Helpers.company_customers_path(companyId)}" class="text-[11px] font-semibold text-primary hover:underline">${translate("View all")}</a>
        </div>
        ${customers.length ? customers.map((customer) => `
          <a href="${Helpers.company_customer_path(companyId, customer.customer_id)}" class="flex items-center justify-between gap-3 p-2.5 rounded-lg bg-muted hover:bg-muted/70 mb-2 last:mb-0">
            <div class="flex items-center gap-2 min-w-0">
              <div class="size-8 rounded-full bg-primary/10 text-primary flex items-center justify-center text-[11px] font-bold shrink-0">${this.initials(customer.name)}</div>
              <div class="min-w-0">
                <p class="text-xs font-semibold text-foreground truncate">${this.escape(customer.name || "—")}</p>
                <p class="text-[11px] text-muted-foreground">${customer.order_count ?? 0} ${translate("orders")}</p>
              </div>
            </div>
            <span class="text-xs font-bold text-primary shrink-0">${Helpers.formatMoney(customer.total_spent_cents, this.currency())}</span>
          </a>
        `).join("") : this.emptyInline(translate("No customer spend yet"))}
      </div>
    `
  }

  staffTodayHTML() {
    const staff = this.dashboardData.staff_today || {}
    const companyId = currentCompany().id

    return `
      <div data-dashboard-section="staff-today" class="bg-card border border-line rounded-xl p-4">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Staff today")}</h2>
          <a href="${Helpers.company_attendance_days_path(companyId)}" class="text-[11px] font-semibold text-primary hover:underline">${translate("View attendance")}</a>
        </div>
        <div class="grid grid-cols-3 gap-2 text-center">
          <div class="p-2 rounded-lg bg-muted" data-staff="present">
            <p class="text-xl font-black text-success">${staff.present ?? 0}</p>
            <p class="text-[10px] uppercase text-muted-foreground">${translate("Present")}</p>
          </div>
          <div class="p-2 rounded-lg bg-muted" data-staff="late">
            <p class="text-xl font-black text-warning">${staff.late ?? 0}</p>
            <p class="text-[10px] uppercase text-muted-foreground">${translate("Late")}</p>
          </div>
          <div class="p-2 rounded-lg bg-muted" data-staff="absent">
            <p class="text-xl font-black text-danger">${staff.absent ?? 0}</p>
            <p class="text-[10px] uppercase text-muted-foreground">${translate("Absent")}</p>
          </div>
        </div>
        <div class="mt-3 space-y-2 text-xs">
          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">${translate("Scheduled")}</span>
            <span class="font-semibold text-foreground">${staff.scheduled ?? 0}</span>
          </div>
          <div class="flex items-center justify-between">
            <span class="text-muted-foreground">${translate("Attendance rate")}</span>
            <span class="font-semibold text-foreground">${this.percent(staff.attendance_rate)}</span>
          </div>
          ${staff.missing_checkout ? `<div class="flex items-center justify-between"><span class="text-muted-foreground">${translate("Missing checkout")}</span><span class="font-semibold text-warning">${staff.missing_checkout}</span></div>` : ""}
        </div>
      </div>
    `
  }

  bottomRowHTML() {
    const financial = this.canViewFinancials()
    const events = this.dashboardData.upcoming_events || []
    const companyId = currentCompany().id

    const eventsHTML = `
      <div data-dashboard-section="events" class="bg-card border border-line rounded-xl p-4">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Upcoming events")}</h2>
          <a href="${Helpers.company_events_path(companyId)}" class="text-[11px] font-semibold text-primary hover:underline">${translate("View all")}</a>
        </div>
        ${events.length ? events.map((event) => `
          <a href="${Helpers.company_event_path(companyId, event.id)}" class="flex items-center justify-between gap-3 p-2.5 rounded-lg bg-muted hover:bg-muted/70 mb-2 last:mb-0">
            <div class="min-w-0">
              <p class="text-xs font-semibold text-foreground truncate">${this.escape(event.name)}</p>
              <p class="text-[11px] text-muted-foreground">${this.formatDate(event.start_at, "MMM D, HH:mm")}${event.branch_name ? ` · ${this.escape(event.branch_name)}` : ""}</p>
            </div>
            <span class="material-symbols-outlined text-[18px] text-muted-foreground shrink-0">event</span>
          </a>
        `).join("") : this.emptyInline(translate("No upcoming events"))}
      </div>
    `

    if (!financial) return `<div class="grid grid-cols-1 gap-4">${eventsHTML}</div>`

    const wallet = this.dashboardData.wallet || {}
    const walletHTML = `
      <div data-dashboard-section="wallet" class="bg-card border border-line rounded-xl p-4">
        <div class="flex items-center justify-between mb-3">
          <h2 class="text-base font-bold text-foreground">${translate("Company wallet")}</h2>
          <a href="${Helpers.new_company_top_up_path(companyId)}" class="text-[11px] font-semibold text-primary hover:underline">${translate("Top up")}</a>
        </div>
        <div class="p-3 rounded-lg bg-muted">
          <p class="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">${translate("Available credits")}</p>
          <p class="text-3xl font-black text-primary mt-1">${this.number(wallet.total_credit_balance)}</p>
          <div class="grid grid-cols-2 gap-2 mt-3 text-center">
            <div><p class="text-xs font-bold text-foreground">${this.number(wallet.main_credit_balance)}</p><p class="text-[10px] text-muted-foreground">${translate("Main")}</p></div>
            <div><p class="text-xs font-bold text-foreground">${this.number(wallet.promo_credit_balance)}</p><p class="text-[10px] text-muted-foreground">${translate("Promo")}</p></div>
          </div>
        </div>
        <div class="flex items-center justify-between mt-3 text-[11px] text-muted-foreground">
          <span>${translate("Used this month")}: ${this.number(wallet.used_this_month)}</span>
          <span>${translate("Access fee")}: ${this.number(wallet.access_cost)} ${translate("credits")}</span>
        </div>
        <p class="text-[10px] text-muted-foreground mt-1">${translate("Balance is shown before this visit's access fee.")}</p>
      </div>
    `

    return `<div class="grid grid-cols-1 xl:grid-cols-2 gap-4">${eventsHTML}${walletHTML}</div>`
  }

  renderCharts() {
    if (!this.canViewFinancials()) return

    const trendContainer = this.contentTarget.querySelector('[data-dashboard-chart="trend"]')
    const mixContainer = this.contentTarget.querySelector('[data-dashboard-chart="mix"]')
    const currency = this.currency()

    if (trendContainer && this.dashboardData.trend?.length) {
      const trend = this.dashboardData.trend
      const chart = new ApexCharts(trendContainer, {
        series: [
          { name: translate("Revenue"), type: "area", data: trend.map((row) => Helpers.chartAmount(row.revenue_cents, currency)) },
          { name: translate("Orders"), type: "line", data: trend.map((row) => row.orders_count) }
        ],
        chart: { height: 256, type: "line", toolbar: { show: false }, zoom: { enabled: false } },
        colors: [ tokenColor("primary"), tokenColor("success") ],
        stroke: { curve: "smooth", width: [ 3, 2 ] },
        fill: { type: [ "gradient", "solid" ], gradient: { opacityFrom: 0.35, opacityTo: 0.05 } },
        dataLabels: { enabled: false },
        grid: { borderColor: chartGridColor(), strokeDashArray: 4, xaxis: { lines: { show: false } } },
        xaxis: {
          categories: trend.map((row) => Helpers.timeFormat(row.date, "MMM D")),
          labels: { style: { colors: chartLabelColor(), fontSize: "10px" }, rotate: 0, hideOverlappingLabels: true },
          axisBorder: { show: false },
          axisTicks: { show: false }
        },
        yaxis: [
          { labels: { style: { colors: chartLabelColor(), fontSize: "10px" }, formatter: (value) => Helpers.formatCompactNumber(value, currency) } },
          { opposite: true, labels: { style: { colors: chartLabelColor(), fontSize: "10px" } } }
        ],
        legend: { show: false },
        tooltip: { shared: true, intersect: false }
      })
      chart.render()
      this.charts.push(chart)
    }

    if (mixContainer && this.dashboardData.revenue_mix?.length) {
      const mix = this.dashboardData.revenue_mix
      const chart = new ApexCharts(mixContainer, {
        series: mix.map((row) => Helpers.chartAmount(row.revenue_cents, currency)),
        labels: mix.map((row) => row.name || translate("Unassigned")),
        chart: { height: 176, type: "donut" },
        colors: chartPalette(mix.length),
        dataLabels: { enabled: false },
        legend: { show: false },
        plotOptions: { pie: { donut: { size: "70%" } } },
        tooltip: { y: { formatter: (value) => Helpers.formatMoney(value * (currency === "vnd" ? 1 : 100), currency) } }
      })
      chart.render()
      this.charts.push(chart)
    }
  }

  destroyCharts() {
    this.charts.forEach((chart) => chart.destroy())
    this.charts = []
  }

  disconnect() {
    super.disconnect()
    this.destroyCharts()
  }

  loadingHTML() {
    return `
      <div class="p-4 space-y-4">
        <div class="h-16 rounded-xl bg-muted animate-pulse"></div>
        <div class="grid grid-cols-2 xl:grid-cols-4 gap-3">
          ${Array.from({ length: 8 }, () => '<div class="h-28 rounded-xl bg-muted animate-pulse"></div>').join("")}
        </div>
        <div class="h-72 rounded-xl bg-muted animate-pulse"></div>
      </div>
    `
  }

  errorHTML() {
    return `
      <div class="p-6">
        <div class="bg-card border border-line rounded-xl p-8 text-center">
          <span class="material-symbols-outlined text-4xl text-danger">error</span>
          <h2 class="text-lg font-bold text-foreground mt-2">${translate("Failed to load dashboard")}</h2>
          <p class="text-sm text-muted-foreground mt-1">${this.escape(this.error)}</p>
          <button type="button" data-action="click->${this.identifier}#reload"
            class="mt-4 px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-semibold">
            ${translate("Try again")}
          </button>
        </div>
      </div>
    `
  }

  emptyHTML(message) {
    return `<div class="p-6">${this.emptyInline(message)}</div>`
  }

  emptyInline(message) {
    return `<div class="flex flex-col items-center justify-center py-8 text-center text-muted-foreground"><span class="material-symbols-outlined text-3xl mb-1">inbox</span><p class="text-xs">${message}</p></div>`
  }

  deltaBadge(value, suffix = "%") {
    if (value === null || value === undefined) return `<span class="text-muted-foreground">${translate("No baseline")}</span>`

    const numeric = Number(value)
    const positive = numeric > 0
    const negative = numeric < 0
    const icon = positive ? "trending_up" : negative ? "trending_down" : "trending_flat"
    const tone = positive ? "text-success" : negative ? "text-danger" : "text-muted-foreground"

    return `<span class="inline-flex items-center gap-0.5 font-semibold ${tone}"><span class="material-symbols-outlined text-[14px]">${icon}</span>${positive ? "+" : ""}${numeric}${suffix}</span>`
  }

  percent(value, digits = 1) {
    if (value === null || value === undefined || Number.isNaN(Number(value))) return "—"
    return `${Number(value).toFixed(digits)}%`
  }

  number(value) {
    return Number(value || 0).toLocaleString()
  }

  initials(name) {
    return (name || "?").split(/\s+/).filter(Boolean).slice(0, 2).map((part) => part[0]).join("").toUpperCase()
  }

  escape(value) {
    return Helpers.escapeHtml(value ?? "")
  }

  formatDate(value, format = "MMM D, YYYY") {
    return Helpers.timeFormat(value, format)
  }

  timezoneLabel(value) {
    if (!value) return "—"
    const minus = value.match(/minus_(\d+)/)
    if (minus) return `UTC-${minus[1]}`
    const plus = value.match(/plus_(\d+)/)
    if (plus) return `UTC+${plus[1]}`
    return value === "utc" ? "UTC" : value
  }
}
