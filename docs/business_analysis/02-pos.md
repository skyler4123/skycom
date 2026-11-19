# POS

> **Last audited:** 2026-11-19 · **Audit scope:** frontend controller, POS
> controller payload, order-processing V1 create/pay path, receipt endpoint,
> feature and request specs. No live browser run.
> **Ship readiness:** 🔴 not shippable — three dead controls, a hardcoded 10% tax
> shown as if it were the company's tax, and services that cannot be sold.
> **Who this is for:** the cashier at the counter.
> **Mobile:** same console, mounted through the Hotwire shell.
> **Read first:** [README](README.md) · **Related:** [00-app-overview](00-app-overview.md),
> [06-store-manager](06-store-manager.md), [04-reception](04-reception.md)

---

## 1. What this page is for

The POS console is the cashier's till. A customer walks up, the cashier scans or
taps products into a cart, optionally attaches the customer to the sale, takes
payment by cash or QR, and hands over a receipt. Multiple customers can be
served in parallel through tabs.

"Done" means the payment is confirmed and the receipt is on screen. The page is
the only place in Skycom where money changes hands face to face.

The console is deliberately a full-screen surface with no sidebar: a cashier
should not be able to wander into payroll mid-sale.

---

## 2. Who uses it

**The person:** a cashier or counter clerk, standing, often on a tablet, working
fast with a barcode scanner.

**Their goal:** take the money correctly, in under a minute, without a manager.

**What they can do here today:**

- Scan a barcode (F1 focuses the field) or search by product name or code.
- Filter the catalog by category.
- Add products and services to a cart, change quantities, remove lines.
- Run several customers in parallel through tabs.
- Attach a registered customer by ID, phone, or name.
- Take cash (with change calculation) or QR payment.
- Print the receipt with the browser's print dialog.
- Start a new sale.

**What they must do elsewhere:**

- Apply a discount or promo code — no field exists.
- Refund, void, or exchange a paid sale.
- Open the cash drawer or count the float.
- Park a sale for later (tabs live only in memory).
- Look up past sales — a link to the Orders list is the only history.

**Access:** the POS operation must be active at the branch, the payment method
must be appointed to the branch, and the employee's role must be allowed.

---

## 3. The screen, in words

**Header:** Skycom POS mark, branch name, a Register/Orders switch, the signed-in
user, a dark-mode toggle, and a lock button.

**Left column (catalog):**

- A row of customer tabs, each with an item count and a close button, plus
  **New Customer**.
- A single search field that doubles as the barcode input, marked **F1**.
- Category pills: All, then one per catalog category.
- A **Products Gallery** grid with grid/list toggle buttons.
- A **Retail Services** list below the products.

**Right column (the sale):** the current order header with item count and
**Clear Cart**, a customer card with lookup, the cart lines with quantity
steppers, and the payment block: subtotal, "Tax (10%)", total, payment-method
buttons, the cash panel (received, quick amounts, change due), and the primary
action (**ORDER**, then **COMPLETE PAYMENT**). Below that: **Print Receipt** and
**Open Drawer**.

**States**

- *Empty cart:* "Cart is empty"; ORDER warns "Cart is empty".
- *Services only in the cart:* ORDER warns "No stock-tracked items in cart" —
  services cannot be checked out.
- *Order created:* cart locks, ORDER becomes Cancel / COMPLETE PAYMENT.
- *QR awaiting payment:* QR code, "Waiting for payment confirmation…", Cancel.
- *Receipt:* items, subtotal, tax, total, payment method, New Sale.
- *Load failure:* a full-screen red "Failed to load cashier screen."
- *Responsive:* catalog and sale stack on phones; the sale panel is sticky on
  desktop.

---

## 4. Control inventory

29 interactive controls.

| ID | Area | Control | What it does today | Status | If shipped as-is |
|---|---|---|---|---|---|
| POS-01 | Header | Orders link | Opens the orders list | ✅ | Leaves the till |
| POS-02 | Header | Dark-mode toggle | Switches theme | ✅ | — |
| POS-03 | Header | Lock Terminal | Nothing at all | ⛔ | A cashier believes the till can be locked; it cannot |
| POS-04 | Tabs | New Customer | Adds a parallel cart tab | ✅ | — |
| POS-05 | Tabs | Switch tab | Activates that cart | ✅ | — |
| POS-06 | Tabs | Close tab | Closes the cart; refuses when only one is open | ✅ | Cart contents are lost without confirmation |
| POS-07 | Catalog | Search / barcode input | Filters products and services; Enter adds an exact barcode match | ✅ | — |
| POS-08 | Catalog | Category pills | Filters both lists by category | ✅ | — |
| POS-09 | Catalog | Grid-view button | Nothing at all | ⛔ | Decorative control |
| POS-10 | Catalog | List-view button | Nothing at all | ⛔ | Decorative control |
| POS-11 | Catalog | Product card | Adds one unit; repeats increment quantity | ✅ | — |
| POS-12 | Catalog | Service card | Adds a service at 0.00 | 🟡 | It enters the cart but can never be ordered (see §5) |
| POS-13 | Sale | Clear Cart | Empties the active cart | ✅ | No confirmation |
| POS-14 | Sale | Customer lookup input | Enter searches by ID, phone, or name | ✅ | — |
| POS-15 | Sale | Find customer | Same search | ✅ | Warns when not found |
| POS-16 | Sale | Change customer | Focuses the lookup field; does not clear the customer | 🟡 | Label promises a reset; it only refocuses |
| POS-17 | Cart | Quantity minus | Decrements; removes at zero | ✅ | — |
| POS-18 | Cart | Quantity plus | Increments | ✅ | No stock ceiling |
| POS-19 | Cart | Remove line | Deletes the line | ✅ | — |
| POS-20 | Payment | Payment-method buttons | Selects cash or QR | ✅ | Methods come from branch appointments |
| POS-21 | Payment | Cash received input | Computes change due live | ✅ | — |
| POS-22 | Payment | Quick-cash buttons | Fills received with a rounded amount | ✅ | — |
| POS-23 | Payment | Cancel (after ORDER) | Discards the created order locally | 🟡 | The order already exists in the database |
| POS-24 | Payment | COMPLETE PAYMENT | Pays the created order; QR waits for confirmation | ✅ | — |
| POS-25 | Payment | ORDER | Creates the order from the cart | ✅ | Services are dropped |
| POS-26 | Receipt | New Sale | Clears the receipt and cart lock | ✅ | — |
| POS-27 | Payment | Cancel (awaiting QR) | Cancels the pending transaction, then the order | ✅ | — |
| POS-28 | Payment | Print Receipt | Opens the browser print dialog on the whole page | 🟡 | Not a receipt-formatted printout |
| POS-29 | Payment | Open Drawer | Toast: "Cash drawer is not connected." | 🗑️ | Cash handling is incomplete |

**Count by status:** ✅ 23 · 🟡 4 · ⛔ 3 · 🗑️ 1 · 💤 0 · 🔢 0. Fabricated
figures are in §5, not in the controls.

---

## 5. Numbers on screen

| Claim on screen | What it appears to mean | Where it actually comes from | Verdict |
|---|---|---|---|
| Product price (`$xx.xx`) | The selling price | The product's current price at load time | ✅ value; 🟡 the `$` symbol is hardcoded, so a non-dollar company sees the wrong currency |
| "N in stock" | Units available at this branch | One stock row, from the first matching warehouse | 🟡 ignores other warehouses serving the branch |
| "N in cart" badge | Units of this product in the active cart | Local cart count | ✅ |
| Subtotal | Sum of cart lines | Client-side arithmetic on the prices shown | ✅ matches the screen, 🟡 it is also what the server records (see §9) |
| **"Tax (10%)"** | The company's sales tax | A hardcoded 10% of the subtotal | 🔢 no tax configuration is read; the number is invented |
| Total Amount | What the customer owes | Subtotal plus the invented 10% | 🔢 |
| Change Due | Cash back | Received minus the invented total | 🔢 derived |
| Quick-cash amounts | Convenient notes | Total rounded up to 5 / 50 / 100 | ✅ derived from the displayed total |
| Receipt subtotal | Invoice price | The invoice price, or line totals when no invoice exists | ✅ |
| Receipt "Tax (10%)" | Tax charged | Hardcoded 10% of the subtotal | 🔢 |
| Receipt total | Amount paid | Subtotal + hardcoded tax | 🔢 |
| Receipt discount line | — | The receipt payload carries a discount amount, but the POS receipt **never displays it** | 🚧 a discounted sale shows a total that ignores the discount |
| Membership chip | The customer's plan | The customer's membership record | ✅ |

**The tax problem in one line:** the company has Tax Data and Tax Config pages,
but POS neither reads them nor sends a tax to the server — it shows 10% on screen
and the receipt repeats the same 10%, so the two agree with each other and
disagree with the company's actual tax settings.

---

## 6. Gaps by user job

### G1 — "Sell me this service."
Services appear in the catalog at 0.00 and cannot be checked out: the order
builder keeps only lines with a stock ID, and services have none.

- Smallest real version: hide the services section until services can be sold (S).
- Better: create service-only order lines with their configured price (M).
- Full version: price services per branch/category with tax (M–L).

### G2 — "Apply the customer's discount."
The discount engine exists (codes, campaign groups, reservation at payment), but
POS has no field to enter a code, and the receipt would not display the result.

- Smallest real version: a discount-code field on the payment block (M).
- Full version: automatic membership discounts at cart level (L).

### G3 — "The tax is wrong."
POS invents 10% and the receipt repeats it. Any company whose tax is not 10% is
mis-selling, and the invoice may disagree with the screen.

- Smallest real version: read the company's tax configuration and display it (M).
- Alternative: remove the tax line until tax is wired, showing a tax-inclusive
  total (S).

### G4 — "I took the wrong payment / the customer changed their mind."
There is no refund, void, or exchange from the till. A cashier must leave POS
and find the order elsewhere.

- Smallest real version: a "Void this sale" action before the drawer closes (M).
- Full version: refunds and exchanges with reason codes (L).

### G5 — "Hold this sale, the customer is coming back."
Carts live in memory. A page refresh, a crash, or a tablet restart loses every
open tab.

- Smallest real version: persist tabs locally (S).
- Better: server-side held sales with a resume list (M).

### G6 — "Open the drawer."
The drawer button is a toast, and there is no float, no shift open/close, and no
cash count. The Store Manager console already tells managers to come here for
cash management, and here there is none.

- Smallest real version: remove the button (S).
- Full version: shift open/close with float and cash count (L).

### G7 — "Print a receipt."
Print opens the browser dialog for the whole page, not a receipt layout.

- Smallest real version: a print stylesheet for the receipt block (S).
- Better: thermal-printer integration (L).

### G8 — "Why can't I find my product?"
The catalog is capped at 50 products and 50 services per branch, with no
pagination, no "more" indicator, and no message when the cap is hit.

- Smallest real version: show a "showing 50 of N" notice (S).
- Better: load more / search on the server (M).

### G9 — "Which stock is this?"
Stock is taken from one warehouse row per product, while a branch can be served
by several warehouses. The number can be wrong, and the sale deducts from
whichever stock the server picks.

- Smallest real version: label the number with its warehouse (S).
- Better: resolve stock through the branch's warehouse priority (M).

### G10 — "This price is wrong."
There is no price override and no manual/open item. A manager cannot sell a
one-off item or correct a price at the till.

- Full version: manager-approved price override with an audit trail (M).

### G11 — "The scanner beeped but nothing happened."
The barcode field accepts only an exact product code. Weight-embedded barcodes,
unknown codes, and service codes do nothing and show no message.

- Smallest real version: show "code not found" feedback (S).
- Better: support weight/price-embedded barcodes (M).

### G12 — "The internet is down."
Every action is an HTTP call; there is no offline mode, no local queue, and no
recovery. A network drop stops selling.

- Full version: offline cart and deferred sync (L).

---

## 7. Decisions for the BA

**POS-D1 — Can services be sold?**
- A. Hide services until they are sellable. Effort S.
- B. Add service order lines at their configured price. Effort M.
- *Recommendation:* A now, B next. Showing a service card that cannot be sold is
  worse than not showing it.

**POS-D2 — What happens to the hardcoded tax?**
- A. Remove the tax line and show the total as configured. Effort S.
- B. Read Tax Config and compute both UI and server tax from it. Effort M.
- *Recommendation:* B before any paying customer, A if a release is needed this
  week.

**POS-D3 — Is a discount code in the first release?**
- A. No; cashiers call a manager. Effort S.
- B. Discount-code field at payment. Effort M.
- *Recommendation:* B — the engine is built and the receipt already carries the
  amount; only the cashier surface is missing.

**POS-D4 — Void and refund from the till?**
- A. No; refunds are handled from Orders. Effort S.
- B. Void before payment, refunds from Orders. Effort M.
- *Recommendation:* B. The most common till error is "wrong payment method", and
  it should be fixable in seconds.

**POS-D5 — Held sales?**
- A. Accept that refresh loses carts, and say so. Effort S.
- B. Persist tabs in the browser. Effort S–M.
- C. Server-side held sales. Effort M.
- *Recommendation:* B. Cheap, and removes a support call.

**POS-D6 — Cash management: remove or build?**
- A. Remove the drawer button and the lock button. Effort S.
- B. Add shift open/close and float count. Effort L.
- *Recommendation:* A now; B belongs with the Store Manager shift close
  (SM-D3), not in POS alone.

**POS-D7 — Catalog cap: show it or remove it?**
- A. Show "first 50" honestly. Effort S.
- B. Server-side search and pagination. Effort M.
- *Recommendation:* B for stores with more than a few hundred SKUs; A otherwise.

**POS-D8 — Price integrity: who sets the price?**
- A. Keep client-supplied prices (current). Effort S. Risk: a tampered client can
  sell at any price.
- B. Server re-prices every line from the product/stock record and rejects
  mismatches. Effort M.
- *Recommendation:* B. A till that trusts the browser is a revenue leak, not a
  feature.

**POS-D9 — Receipt printing?**
- A. Browser print of the page. Effort S.
- B. Print stylesheet for the receipt block. Effort S.
- C. Thermal printer integration. Effort L.
- *Recommendation:* B now, C only when a customer has the hardware.

**POS-D10 — Currency display?**
- A. Keep the hardcoded `$`. Effort S.
- B. Format every amount through the company currency. Effort S.
- *Recommendation:* B. The payload already carries the currency; this is a
  display fix.

---

## 8. Safe demo path

1. Open **Operations** → **POS** for a branch with products and a cash payment
   method.
2. Scan or search a product, add it, change quantity.
3. Open **New Customer**, look up a customer, show the membership chip.
4. Choose **Cash**, type the received amount, show the change.
5. Press **ORDER**, then **COMPLETE PAYMENT**, show the receipt.
6. Press **New Sale**.

**Do not demo:**

- A service — it will sit in the cart at 0.00 and then refuse to order.
- The tax line as "your tax" — it is always 10%.
- Any discount or promo code — there is no field.
- Refund, void, hold, float, or cash drawer.
- The lock, grid, or list buttons.
- Multi-currency — the `$` is hardcoded.
- A large catalog — only the first 50 products load.

---

## 9. Engineering appendix

**Routes**

- `GET /companies/:company_id/operations/pos/:operation_id` (HTML + `.json`)
- `GET …/pos/:operation_id/customer_lookup?q=`
- `POST /companies/:company_id/order_processing_v1/checkout`
- `POST /companies/:company_id/order_processing_v1/pay`
- `POST /companies/:company_id/order_processing_v1/pay_cancel`
- `GET /companies/:company_id/orders/:id/receipt`

**Backend:** `Companies::Operations::PosController#show` and
`#customer_lookup` (payload built inline; there is no POS console service),
`Companies::OrderProcessing::V1Controller`, `Companies::OrdersController#receipt`.

**Order path:** `OrderProcessingV1::CreateOrderService` sums
`quantity × unit_price` from the request, writes `Order` + line appointments,
then `pay` records the transaction. **The client supplies `unit_price`; the
server does not re-price.**

**Frontend:** `app/javascript/controllers/companies/operations/pos/show_controller.js`
(`Companies_Operations_Pos_ShowController`). F1 focuses `#barcode-input`;
QR payments subscribe to the `pos_payment_completed` websocket event.

**Money gaps in code:**

- `getTax()` returns `getSubtotal() * 0.10`; the receipt endpoint repeats
  `subtotal * 0.10` and totals `subtotal + tax`. Neither reads tax config.
- `initiateOrder` filters `items.filter((item) => item.stockId)` — services have
  no `stock_id`, so they are silently dropped.
- The receipt payload includes `discount_amount`, but the receipt renderer never
  shows it.
- Currency is rendered as a literal `$` in the catalog, cart, payments and
  receipt, although `product.currency` exists in the payload.
- `OrdersController#receipt` computes `tax` and `total` independently of the
  invoice's stored amounts.

**Source tables:** `products`, `services`, `stocks`, `orders`,
`order_product_appointments`, `order_service_appointments`, `invoices`,
`transactions`, `payment_methods`, `branch_payment_method_appointments`,
`customers`.

**Proof:** `spec/features/companies/operations/pos_spec.rb`,
`spec/requests/companies/operations/pos_spec.rb`, plus the order-processing and
receipt specs.

**Not covered by tests:** service checkout, tax correctness, discount display,
dead controls, currency formatting, and the 50-item cap.
