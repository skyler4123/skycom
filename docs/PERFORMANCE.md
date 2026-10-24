# Skycom Performance Backlog

> **Status**: Backlog — not scheduled work. An item leaves this doc only
> when its trigger is hit and the switch is implemented.

## Convention

Every item has the same four lines:

| Line | Meaning |
|------|---------|
| **Trigger** | The observable condition that promotes this from backlog to work |
| **Current cost** | What we pay today by not doing it |
| **Switch to** | The target design |
| **Cost of switching** | What the migration itself costs (code, data, ops) |

---

## 1. Comment image variants → async preprocessing

- **Trigger**: first view of a comment image stalls (variant is processed
  **synchronously on first request** today), or concurrent first-views
  saturate web workers with MiniMagick.
- **Current cost**: `image_attachment`'s `:display` variant
  (`app/models/company_ticket_comment.rb`) is built lazily — whoever first
  opens the thread (or receives the socket payload URL) pays the resize.
  Eager upload-time processing was deliberately rejected (see git history:
  variants were chosen over `prepared_upload` so no custom image code ships).
- **Switch to**: a Solid Queue job calling
  `comment.image_attachment.variant(:display).preprocessed` on create, so
  the variant exists before anyone views it.
- **Cost of switching**: adds a job + queue to monitor; socket payload URLs
  stay valid (same representation URL, just pre-generated).

## 2. Comment thread pagination

- **Trigger**: tickets with hundreds of comments/logs.
- **Current cost**: `format_ticket_detail` loads **all** comments + logs +
  attachments on every detail open (both company and admin show endpoints).
- **Switch to**: `?comment_page=`-style pagination on `ticket_comments` in
  both show endpoints; FE thread renders pages instead of the full list.
- **Cost of switching**: FE thread template gains paging state; socket-inject
  must insert into the visible page or bump an "N new" indicator.

## 3. Socket fan-out narrowing

- **Trigger**: high comment volume wakes every open detail page company-wide.
- **Current cost**: `company_ticket_commented` publishes on `company_<id>` —
  all subscribers in the company receive every comment event and filter
  client-side by ticket id.
- **Switch to**: per-ticket channel
  (`WEBSOCKET.channel_name(:company_ticket, id)`): BE publish ×2, FE
  subscribe ×2, JWT channel claims (`WebsocketConcern`, admin layout)
  extended to include the ticket channel.
- **Cost of switching**: channel-claim wiring on both layouts; admin pool
  detail must resolve the ticket's channel the same way the company side does.

## 4. Attachment delivery via CDN

- **Trigger**: attachment downloads become a bandwidth hotspot.
- **Current cost**: local/MinIO blob paths served through the app host with
  `disposition: attachment` (forced download).
- **Switch to**: CDN-signed representation URLs; revisit the forced-download
  policy per content type when the URL host changes.
- **Cost of switching**: storage/CDN config, signed-URL expiry handling in
  `format_attachment` on both controllers, socket payload compatibility.

## 5. Notification bell unread count

- **Trigger**: `GET .../notifications/unread_count` shows up slow in traces,
  or a 10-minute TTL expiry triggers a miss storm (every active employee
  recomputes at once).
- **Current cost**: `refreshBell()` (`companies/layout_controller.js`) fires
  on **every page navigation**, each hitting `Notifications::UnreadQuery`
  (`app/services/notifications/unread_query.rb`) — a subscribed-tag join +
  `created_at > last_read_all_at` + `NOT IN (reads)` + `DISTINCT` that grows
  with notification volume and the reads table. A 10-minute per-employee
  `sync_cache` (`notifications:unread:<id>`) absorbs the steady state, but
  every expiry recomputes the full query and socket `notification_created`
  only triggers yet another `GET`.
- **Switch to**: push-based badge — the `notification_created` payload
  carries the increment (or the new count) so the bell updates with **zero
  GETs**, falling back to the endpoint only on reconnect; and/or a
  materialized per-employee unread counter (increment on publish, decrement
  on read/mark-all) replacing the join-minus-reads query, with the 10-minute
  TTL replaced by write-through invalidation.
- **Cost of switching**: payload shape + per-employee fan-out in
  `Notifications::CreateService` (one count per subscriber vs one broadcast);
  counter table + backfill; read paths (`mark_all_read`, single reads) must
  keep the counter exact or the badge lies.

## 6. Record cache — current state and trade-offs

**Implemented**: `Session`, `User`, `Company`, `Employee` are cached in
`Rails.sync_cache` (unversioned keys, `refresh_cache`/`remove_cache`
invalidation, TTL backstop). `User`/`Company`/`Employee` are re-instantiated
from cached attributes via `Model.instantiate`, eliminating per-request DB
reads on cache hit; `Session` stays a compact hash.

**Trade-off**: `instantiate` allocates an ActiveRecord object and re-casts
attributes on every request. This is far cheaper than a DB round-trip and keeps
all existing callers (`current_company.shift_templates`, `current_user.companies`,
etc.) working without a refactor, but it is not zero-cost and still holds a full
AR instance in memory per request.

**Future improvement (hash-based, zero-DB, zero-instantiate)**: migrate callers
to raw, indexed FK queries (`ShiftTemplate.where(company_id: ...)`,
`current_user["system_role"] == "admin"`) and return compact hashes from
`current_user`/`current_company`/`current_employee` instead of AR objects.
See `/home/skyler/.opencode/plan/hash-based-records.md` for the field inventory
and migration recipe. Until that refactor lands, `instantiate` remains the
compatibility bridge.

## 7. Notification bell unread count → fold into page JSON

- **Trigger**: `GET .../notifications/unread_count` shows up in every
  page-load trace, or the bell becomes a latency hotspot on navigation.
- **Current cost**: each page load issues a separate request for the unread
  count (shell + data + bell = 3 requests). The count is already cached
  per employee (10-min TTL via `Notifications::UnreadQuery`), but a request
  still fires on every navigation and the cache miss recomputes the
  subscribed-tag join.
- **Switch to**: include the unread count in the page's JSON response at the
  same level as `pagination` (e.g. `unread_count` field on index/show
  payloads), so the bell updates from data already fetched. Drop the
  standalone `unread_count` request; fall back to the endpoint only on
  reconnect or when the field is absent.
- **Cost of switching**: add the field to the relevant controllers'
  JSON payloads and update the FE bell to read from the page data (or the
  client cache) instead of calling the endpoint. Keep the endpoint for
  backwards compatibility / reconnect recovery.

---

*See also: `docs/WEBSOCKET.md` (channels/events), `docs/CACHE.md` (tiers).*
