# Skycom Development Roadmap

> Living document — track progress as you build. Last updated: 2026-07-09.

**Key**: 🔴 P0 = Must Do | 🟡 P1 = Core Features | 🟢 P2 = Polish | 🔵 P3 = Stretch

---

## 🔴 P0 — Must Do (Billing/Feature System Completeness)

### #1 — Wire up feature gating (backend)
**Status**: ⬜ Not started  
**Complexity**: M  
**Dependencies**: None  
**Done when**: `Companies::FeatureGatingConcern` with `feature_key` declaration + `before_action :check_feature_enabled!` declared on all gatable controllers. Disabled features return 403 JSON / redirect to billing.

### #2 — Add billing_contract to client cache
**Status**: ⬜ Not started  
**Complexity**: S  
**Dependencies**: None  
**Done when**: `/client_cache` endpoint includes `billing_contract` with `enabled_features` so the frontend knows what's enabled.

### #3 — Wire up feature gating (frontend)
**Status**: ⬜ Not started  
**Complexity**: M  
**Dependencies**: #2  
**Done when**: `featureEnabled(key)` helper exists in `auth_helpers.js`, sidebar items in `layout_controller.js` are conditionally rendered, disabled pages show upgrade prompt.

### #4 — Feature Store toggles
**Status**: ⬜ Not started  
**Complexity**: M  
**Dependencies**: #2  
**Done when**: Billing dashboard has enable/disable toggles for add-on features. PATCH endpoint to toggle `ContractFeature`.

### #5 — Top-up flow
**Status**: ✅ Done (partial — auto-credit, no payment gateway)  
**Complexity**: M  
**Dependencies**: None  
**Done when**: POST endpoint + UI for wallet top-ups. Bank transfer instructions, manual confirmation, balance update.
**Note**: Currently auto-credits the wallet directly without payment collection. Full payment gateway integration tracked in P1 #11.

### #6 — SyncSuspensionJob spec
**Status**: ⬜ Not started  
**Complexity**: S  
**Dependencies**: None  
**Done when**: `spec/jobs/billing/sync_suspension_job_spec.rb` exists with test for the midnight suspension cron.

---

## 🟡 P1 — Core Business Features

### #7 — Multi-branch switcher
**Status**: ⬜ Not started  
**Complexity**: L  
**Dependencies**: #1  
**Done when**: Branch selector in header, data scoped by branch, cross-branch visibility for owner.

### #8 — Analytics dashboard
**Status**: ⬜ Not started  
**Complexity**: L  
**Dependencies**: None  
**Done when**: Profit margins, inventory velocity, staff performance, CLV charts.

### #9 — Commission engine
**Status**: ⬜ Not started  
**Complexity**: M  
**Dependencies**: None  
**Done when**: `hrm_payroll_commissions` feature. Employees tied to order line items, auto-calculated commissions per sale.

### #10 — Loyalty program
**Status**: ⬜ Not started  
**Complexity**: L  
**Dependencies**: None  
**Done when**: `crm_loyalty` feature. Points, tiers (Silver/Gold/Platinum), reward catalog, redemption.

### #11 — Payment gateway integration
**Status**: ⬜ Not started  
**Complexity**: L  
**Dependencies**: None  
**Done when**: MoMo, ZaloPay, VNPay. QR code generation per invoice, refund flow.

### #12 — Automation engine
**Status**: ⬜ Not started  
**Complexity**: XL  
**Dependencies**: None  
**Done when**: Rule-based triggers ("stock < 10 → create PO"), customer reminders, webhook config.

### #13 — Audit log viewer
**Status**: ⬜ Not started  
**Complexity**: M  
**Dependencies**: None  
**Done when**: Version history with before/after diffs on resource changes for `audit_logs` feature.

### #14 — Open API
**Status**: ⬜ Not started  
**Complexity**: XL  
**Dependencies**: #13  
**Done when**: Public REST API with token management, rate limiting, developer docs.

---

## 🟢 P2 — Enhancements & Polish

### #15 — Usage guardrails
**Status**: ⬜ Not started  
**Complexity**: S  
**Dependencies**: #2  
**Done when**: 80%/95% allowance warnings in sidebar, low-balance toasts and emails.

### #16 — Meter remaining resources
**Status**: ⬜ Not started  
**Complexity**: S  
**Dependencies**: None  
**Done when**: `metered_as :storage_mb` on file uploads, `api_calls` on API, `stock_mutations` on stock changes.

### #17 — Soft debt threshold enforcement
**Status**: ⬜ Not started  
**Complexity**: S  
**Dependencies**: None  
**Done when**: `debt_ceiling_reached?` checked at runtime, auto-suspend when threshold exceeded.

### #18 — Subscription plan management
**Status**: ⬜ Not started  
**Complexity**: M  
**Dependencies**: #4, #5  
**Done when**: Plan upgrade/downgrade flow, mid-cycle proration UI, contract type changes.

### #19 — `hide_billing_alerts` wiring
**Status**: ⬜ Not started  
**Complexity**: S  
**Dependencies**: None  
**Done when**: Flash warning suppressed when `hide_billing_alerts` is true.

### #20 — Feature gating integration tests
**Status**: ⬜ Not started  
**Complexity**: M  
**Dependencies**: #1  
**Done when**: System specs verify gated pages return 403, sidebar hides disabled features.

---

## 🔵 P3 — Stretch / Later

| # | Task | Complexity | Depends On | Notes |
|---|------|-----------|------------|-------|
| 21 | SSO/SAML (Okta, Azure AD, Google) | XL | — | Identity provider management |
| 22 | Multi-market pricing templates | M | — | Country-specific prices |
| 23 | Enterprise contract management | M | — | Custom contracts, unlimited allowances |
| 24 | Check-in/out mobile API | M | — | REST endpoints with GPS validation |
| 25 | QR code check-in | M | — | Per-branch QR for attendance |
| 26 | Payroll integration | M | #9 | Link attendance_months to commissions |
| 27 | Employee self-service | M | — | Employee-facing attendance dashboard |
| 28 | Attendance policies UI | M | — | CRUD for per-branch geofence config |
| 29 | Nightly SyncAttendanceJob | M | — | Auto-close stale sessions, aggregate |

---

## Quick Stats

| Priority | Count | Est. Effort |
|----------|-------|-------------|
| 🔴 P0 | 6 | ~3 weeks |
| 🟡 P1 | 8 | ~8 weeks |
| 🟢 P2 | 6 | ~2 weeks |
| 🔵 P3 | 9 | ~8 weeks |

---

## Progress Tracker

| Date | Item | Status | Notes |
|------|------|--------|-------|
| 2026-07-09 | #1 — Wire up feature gating (backend) | ✅ Done | `FeatureGatingConcern` + `feature_key` on 20 controllers |
| 2026-07-09 | #2 — Add billing_contract to client cache | ✅ Done | `/client_cache` now includes `enabled_features` |
| 2026-07-09 | #3 — Wire up feature gating (frontend) | ✅ Done | `featureEnabled(key)` helper + sidebar gating in `layout_controller.js` |
| 2026-07-09 | #4 — Feature Store toggles | ✅ Done | Toggle switches on billing dashboard, `POST /billing/toggle_feature` |
| 2026-07-09 | #5 — Top-up flow | ✅ Done | `POST /billing/top_up` + wallet modal UI |
| 2026-07-09 | #6 — SyncSuspensionJob spec | ✅ Done | 8 examples covering all edge cases |

---

*End of document*
