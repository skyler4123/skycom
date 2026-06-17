# Order Processing V1 Pipeline Design

## Overview

Backend order processing pipeline for Skycom POS. Two endpoints handle the complete flow from checkout to payment with Redis-first architecture for high-traffic stock management.

## Architecture

### 7 Services under `OrderProcessingV1` module

| # | Service | Layer | Responsibility |
|---|---------|-------|---------------|
| 1 | `CheckAvailabilityService` | Redis (read) | Verify stock via Kredis counter |
| 2 | `CreateOrderService` | PostgreSQL | Create Order (pending) + OrderAppointments via `insert_all!` |
| 3 | `ReserveStockService` | Redis (DECRBY) | Atomic stock reserve with rollback |
| 4 | `ProcessPaymentService` | PostgreSQL | Create Invoice + Payment, mark Order paid |
| 5 | `WriteStockLedgerService` | PostgreSQL (insert_all!) | Bulk insert StockTransaction records |
| 6 | `UpdateStockBalancesService` | PostgreSQL (raw SQL) | UPDATE stocks SET quantity -= ?, reserved_quantity -= ? |
| 7 | `FinalizeOrderService` | PostgreSQL | Create StockExport documents |

### Controller

**Class**: `Companies::OrderProcessing::V1Controller`
**Routes**:
- `POST /companies/:id/order_processing/v1/checkout` → services 1-2
- `POST /companies/:id/order_processing/v1/pay` → services 3-4 (sync) + enqueue job for 5-7

### Flow

```
checkout → CheckAvailability (Redis read) → CreateOrder (Order + OrderAppointments)
pay → ReserveStock (Redis DECRBY) → ProcessPayment (Invoice + Payment + Order.paid) → FinalizeJob (async: ledger → balances → export)
```

### Background Job

`OrderProcessingV1::FinalizeJob` wraps services 5-7 in an `ActiveRecord::Base.transaction`.

### Redis Counter

Each Stock has a `kredis_integer :available_counter` synchronized on save. Read-only in `checkout`, atomic DECRBY in `pay`.

### Order Workflow Status

- `pending` (1) — after checkout
- `paid` (5) — after pay action
