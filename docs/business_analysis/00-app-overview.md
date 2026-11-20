# Skycom — application overview

> **Last audited:** 2026-11-20 · **Audit scope:** sidebar navigation, routes,
> module docs, operation consoles (audited separately), TODO roadmap, mobile
> feature matrix. Module status is based on routes, controllers, and module docs —
> not a page-by-page UI audit.
> **Who this is for:** a business analyst deciding where the next development
> phase goes.
> **Read first:** [README](README.md) · **Related:** every page document in this
> folder, `docs/TODO.md`, `docs/MOBILE_FEATURE_MATRIX.md`

---

## 1. What Skycom is

Skycom is a multi-tenant business management platform. A company signs up, gets
its own isolated workspace, and manages selling, stock, people, money, and
operations from one system. Every record belongs to exactly one company; branches
and warehouses are locations inside it.

The platform is built around three ideas that show up everywhere:

1. **Purpose-specific operations.** POS, Booking, Reception, Inventory, and Store
   Manager are consoles a person works in, not industry templates.
2. **One real source per concept.** Products, stock, orders, invoices, events, and
   attendance each have one owner; other screens read them.
3. **Atomic links.** Anything that connects two things (an event and a room, an
   employee and a department) is a small join table rather than a column on
   either side.

**Who buys it:** small and mid-sized businesses with more than one location and
more than one kind of work — retail chains, restaurants, hotels, clinics,
schools, gyms, and office/coworking operators.

**Industry fit:** the company has an industry setting (retail, restaurant,
hospital, education, hotel, fitness) but it is **seed-only**. It never changes
runtime behaviour. Two
different industries run the same consoles; what differs is their categories,
dynamic properties, location appointments, and access policies.

---

## 2. The five operation consoles

| Console | What it is for | Verdict | Why |
|---|---|---|---|
| [POS](02-pos.md) | Taking money at the counter | 🟢 | Tax/currency from config, services, server prices, discounts, void, receipt slip, real lock, persisted tabs; one company-wide tax rate |
| [Booking](03-booking.md) | Reserving rooms and spaces | 🟢 | Conflict-safe locking, click-to-inspect, real host/customer, extend/end/cancel, real category occupancy, run sheet |
| [Reception](04-reception.md) | Front desk, visitors, parcels | 🟢 | Guest-linked visits only, pre-registration, browser badge print, direct notifications, real shift/timers/polling |
| [Inventory](05-inventory.md) | Warehouse stock command screen | 🟢 | Four real KPIs, server-paged ledger, receive/transfer/export/adjust/reorder/count loops |
| [Store Manager](06-store-manager.md) | Retail floor command screen | 🔴 | Six dead tabs, invented shift, fabricated register names, UTC hourly chart |

POS, Booking and Reception are shippable. The remaining urgent work is POS
service sales and removing the fabricated panels from Inventory and Store
Manager. The dead tabs are the cheapest visible win.

[Operations landing and configuration](01-operations-landing.md) is the control
room for all five; it is 🟠 with one table defect.

---

## 3. The rest of the platform

The sidebar has **21 groups**. Status is the module-level view; where a page
document exists, it owns the detail.

| Group | Business purpose | Status | Detail |
|---|---|---|---|
| **My Profile** | Employee self-service: own record, attendance, payroll | Built | Web + mobile |
| **General** | Dashboard and Analytics | 🟠 Built; period gaps | [Dashboard](07-dashboard.md), [Analytics](08-analytics.md) |
| **Notification** | In-app messages and tags | Built | No mobile inbox, no push |
| **Catalog** | Products, brands, services, suppliers | Built | Supplies POS, Inventory, Purchases |
| **Sales** | Orders, customers, profiles, invoices, purchases, refunds, tickets, discounts | Built, depth varies | Orders and invoices are real; refunds are thin |
| **Organization** | Branches, departments, employees, groups, profiles, performance, facilities | Built | Core of tenancy and operations |
| **Exams** | Question bank, timed assessments, grading | Built | Web only, no mobile |
| **Platform** | Categories, dynamic properties, dynamic tables, workflows, documents, imports, migrations, payment methods | Built | The customization layer |
| **Operations** | Operation list and configs | 🟠 | [Landing](01-operations-landing.md) |
| **Storage** | Folders and storage statistics | Built | File storage |
| **Schedule** | Calendar, events, event configs | Built | Backbone of Booking and Reception |
| **Attendance** | Shift templates, shifts, attendance days, requests, configs, logs | Built; production job gap | Months are not refreshed by a scheduled job in production |
| **Inventory** | Warehouses, stocks, transfers, imports, exports, adjustments, pendings, suppliers | Built | Stock is the source of truth for every movement |
| **Tax** | Tax data and tax config | Built, **used by POS** | POS reads the Tax Config POS rate/name, snapshots it on the order/invoice, and prints it on the receipt (0% hides it). |
| **Payroll** | Payroll data and config | Partial | Money fields are seed-only; no results editor |
| **Authorization** | Roles, policies, permissions, logs | Built | ABAC is the only permission system |
| **Chat & Help Desk** | Support conversations | 💤 Coming soon | Group marked coming soon |
| **Email Marketing** | Campaigns | 💤 Coming soon | Group marked coming soon |
| **AI Assistant** | Assistant | 💤 Coming soon | Group marked coming soon |
| **Settings** | Company, quick links, dashboard config, analytics config | Built | Configuration only |
| **System** | Usage, top up, billing, help center | Built | Commercial surfaces |

**What is strong:** the data model. Stock movements, money flows, dynamic
properties, ABAC, and the atomic-link pattern are real, documented, and tested.
Most modules are CRUD over a sound domain.

**What is thin:** the last mile. Consoles look richer than they are; several
modules have a backend and a list page but no complete workflow (refunds,
payroll results, audit counts, production BOM).

---

## 4. How Skycom charges

There is **no subscription tier UI**. The commercial model is prepaid credits:

- A **company wallet** holds a main balance and a promo balance.
- Metered actions deduct credits through a controller-level filter
  (`CompanyCreditDeduction::*`), never from jobs, imports, seeds, or migrations.
- A **top-up** creates a company order, invoice, and transaction; the wallet is
  credited when the order completes.
- **Usage** shows the 7-day and monthly totals and the live counter; **Billing**
  shows the wallet snapshot and purchase history.
- A **suspended** company keeps read-only access to billing and usage so it can
  recover, but loses the rest of the app.
- **Promo campaigns** (admin) can grant capped promotional credits with a
  notification.

The practical consequence for the BA: every action has a unit cost, so a page
that makes the user refresh or retry often is also a revenue and trust problem.

---

## 5. What is genuinely not ready

A short honest list, without repeating `docs/TODO.md`:

1. **The five operation consoles** — see §2.
2. **Attendance in production** — monthly rows are not refreshed by a scheduled
   job; the HR check-out service exists but mobile only checks in.
3. **Payroll results** — the platform stores raw attendance and salary inputs;
   there is no editor for calculated money, and the calculation approach is an
   open decision (client-calculated vs server formula).
4. **Refunds and voids** — the refunds area exists but is not a complete till
   workflow.
5. **Cycle counts / stock audits** — not modelled; the Inventory card is honest
   about it.
6. **Production/BOM** — not modelled; the Inventory panel is not honest about it.
7. **Notifications on mobile** — no inbox, no unread badge, no push.
8. **Chat & Help Desk, Email Marketing, AI Assistant** — sidebar groups marked
   coming soon, no screens.
9. **Accounting core** — no general ledger, AP/AR automation, budgets, or assets
   (documented in the 100-item roadmap).
10. **Public API** — no supported REST/GraphQL surface for integrations.

---

## 6. Strongest demo story today

For a sales conversation, lead with what is real:

1. **Onboarding and structure** — create a company, branches, warehouses,
   departments, employees, roles.
2. **Catalog and stock** — products, services, categories, dynamic properties,
   stock imports, transfers, adjustments.
3. **Sell** — POS checkout with cash or QR (avoid tax and services), then the
   order, invoice, and receipt.
4. **Operate** — Store Manager overview only, Booking timeline plus one
   reservation, Reception walk-in and parcels, Inventory ledger and low stock.
5. **Review** — Dashboard and Analytics with real historical data.
6. **Admin** — dynamic properties, workflows, access policies, credits and usage.

Never demo a control or panel marked 🔴, 🗑️, ⛔, or 🔢 in the page documents.

---

## 7. Cross-cutting decisions for the BA

**APP-D1 — Which console ships first?**
- A. POS. Highest revenue impact; service sales remain. Effort M.
- B. Booking. **Shipped** — conflict-safe reservations, real inspector and desk
  actions are in place. Effort M.
- C. Reception. **Shipped** — guest-linked visits, pre-registration, browser
  badge print, direct notifications, shift/timers/search/polling. Effort M.
- *Recommendation:* A. Booking and Reception are already front-desk-safe; POS is
  the next revenue blocker.

**APP-D2 — Credits or subscriptions?**
- A. Keep prepaid credits. Effort S.
- B. Add plan tiers with included credits and overage. Effort L.
- *Recommendation:* A until a customer asks for a predictable monthly bill.

**APP-D3 — Which industry to sell to first?**
- A. Retail. POS and Store Manager are purpose-built for it. Effort S.
- B. Office/coworking. Booking and Reception now fit: reception has real
  pre-registration, badge print and host notifications. Effort S.
- C. Hospitality. Reception now uses neutral front-desk copy, not hotel-specific
  branding; the consoles are purpose-based. Effort M–L.
- *Recommendation:* A. The retail path needs the least new domain work.

**APP-D4 — Payroll: calculate or store?**
- A. Store client-calculated results (the documented direction). Effort M.
- B. Calculate in Skycom with configurable rates. Effort L and ongoing compliance.
- *Recommendation:* A. It matches the current data model and avoids tax-law
  maintenance.

**APP-D5 — Mobile scope?**
- A. Employee self-service plus operations read/write where it already works.
  Effort S (current).
- B. Full ERP parity. Effort L and a different product.
- *Recommendation:* A. Mobile is a companion, not the product.

**APP-D6 — Breadth or depth?**
- A. Finish the five consoles to 🟢 before adding modules. Effort M–L.
- B. Keep adding modules (projects, accounting, marketing). Effort L each.
- *Recommendation:* A. A platform with five broken front doors cannot be saved by
  a sixth module.

---

## 8. How to read this folder

| If you are deciding… | Read |
|---|---|
| Whether a console can be sold tomorrow | Its page doc §2 verdict, §7 decisions, §8 demo path |
| What to build next | Every page doc §6 gaps + §7 decisions, then `docs/TODO.md` |
| Why a number is wrong | The page doc §5 numbers table |
| What a button does | The page doc §4 control inventory |
| How the whole app fits together | This document §1–§5 |

**Suggested reading order for a BA:** this overview → Operations landing → POS →
Booking → Reception → Inventory → Store Manager → Dashboard → Analytics.

---

## 9. Engineering appendix

**Navigation source:** `app/javascript/controllers/companies/sidebar_items.js`
(21 groups, 77 links, 3 coming-soon groups).

**Operation catalog:** `OPERATION_TYPES` in `config/initializers/constants.rb`
(five types; appointments are seeded per location).

**Domain docs:** `docs/OPERATIONS.md`, `docs/ORDER_PROCESSING_V1.md`,
`docs/MONEY_FLOW.md`, `docs/STOCK.md`, `docs/PURCHASE_WORKFLOW.md`, `docs/HR.md`,
`docs/KPI.md`, `docs/EXAMS.md`, `docs/EVENTS.md`, `docs/DISCOUNTS.md`,
`docs/PAYMENT_METHODS.md`, `docs/CREDIT_DEDUCTION.md`, `docs/IMPORT.md`,
`docs/DATA_MIGRATION.md`, `docs/ABAC.md`.

**Commercial surfaces:** `Companies::BillingController`,
`Companies::UsageController`, `CompanyWallet`, `CompanyCreditDeduction::*`,
`Docs/CREDIT_DEDUCTION.md`.

**Platform scale at audit time:** 312 tables, 310 models, 149 controllers, 259
services, 336 Stimulus controllers, 808 spec files.

**Not covered here:** a page-by-page audit of the 69 non-operation sidebar pages.
Their status in §3 is module-level and based on routes, controllers, and module
docs.
