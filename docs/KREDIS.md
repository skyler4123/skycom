# Skycom Kredis Usage Rule

> **Status**: Active project convention. Enforced by review and the mechanical
> grep check below.

## The Rules

| # | Rule |
|---|------|
| 1 | **No low-level `Kredis.redis`** in application code (controllers, services, jobs). Infra exception: the cache/pub-sub wiring in `config/initializers/cache.rb`. |
| 2 | **Business code never touches kredis proxy built-ins directly** (`.value`, `.value=`, `.increment`, `.decrement`, `.set`, `.get`, ...) — not in services, controllers, or jobs. |
| 3 | **The owning model wraps them behind domain-named methods** (e.g., `Stock#available_count`, `Company#record_credit_usage!`, `Company#credit_usage_delta`). Callers use only those methods. |
| 4 | **Why**: a stable interface lets us swap Kredis ↔ DB *inside* the method when special business logic needs a different source of truth — callers never change. |

```ruby
# ✅ CORRECT — service talks to the domain method; storage is an implementation detail
stock.available_count
stock.reserve_stock!(qty)
company.record_credit_usage!(credits)

# ❌ FORBIDDEN — service reaches into the cache store directly
stock.available_counter.decrement(by: qty)
Kredis.redis.multi { |m| m.decrby("stock:#{id}:available", qty) }
```

## Reference Implementations

| Model | Declaration | Wrapper Methods |
|-------|-------------|-----------------|
| `app/models/stock.rb` | `kredis_counter :available_counter` | `available_count` (read + self-heal), `reserve_stock!`, `release_reserved!` |
| `app/models/company.rb` | `kredis_counter :credit_usage` | `record_credit_usage!`, `credit_usage_delta` |

### The Swap Pattern

Because every caller goes through the wrapper, moving the data source is a
one-method change with zero call-site churn:

```ruby
# Today: Redis hot counter, healed from DB when the key is missing
def available_count
  return available_counter.value if available_counter.exists?
  available_counter.increment(by: [ quantity - pending, 0 ].max)
end

# Tomorrow, if a business rule needs DB-direct reads instead:
def available_count
  [ quantity - pending, 0 ].max   # same interface, new internals
end
```

## Adding a New Counter

1. Declare the DSL on the owning model: `kredis_counter :thing_counter`
2. Write domain-named wrapper method(s) that hide the proxy entirely
3. Use atomic ops (`increment`/`decrement` return the post-op value) for
   check-and-act flows — never read-then-write across processes
4. Keep any DB fallback/healing logic inside the model, next to the counter

## Enforcement

```bash
# Must print nothing (no raw connections, no proxy calls outside models):
grep -rn "Kredis.redis" app/ --include="*.rb" | grep -v "config/initializers"
grep -rEn "(available_counter|credit_usage)\.(value|increment|decrement|set|get)" \
  app/ --include="*.rb" | grep -v "app/models/"
```

---

*See also: `docs/ATOMIC_PURPOSE.md` § Hot Path Rule (usage-counter drain pattern),
`docs/CACHE.md` §4 (when Redis global state is appropriate), `docs/ORDER_PROCESSING_V1.md` §7.*
