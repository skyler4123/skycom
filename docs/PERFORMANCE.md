# Skycom Performance Backlog

> **Status**: Backlog — not scheduled work. Same standing as the housekeeping
> items in `docs/TODO.md` and `docs/ROADMAP.md`. An item leaves this doc only
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

## 1. Comment image processing → async variants

- **Trigger**: p95 `POST /companies/:id/company_ticket_comments` / admin
  `POST .../comment` latency degrades, or concurrent-upload MiniMagick CPU
  saturates web workers.
- **Current cost**: `CompanyTicketComment.prepared_upload`
  (`app/models/company_ticket_comment.rb`, see the `NOTE` there) shell-outs
  to MiniMagick **synchronously inside the request** (~0.5–2s per 2MB photo).
  Eager by design — variants would store the 2MB original permanently.
- **Switch to**: Rails built-in
  `has_many_attached ... attachable.variant :display, resize_to_limit: TICKET_COMMENT_IMAGE_DIMENSIONS`
  + a Solid Queue job calling `.preprocessed` on create;
  `format_attachment` (both `Companies::CompanyTicketCommentsController` and
  `Admin::CompanyTicketsController`) emits
  `rails_representation_url(...variant...)` instead of `rails_blob_path`.
- **Cost of switching**: original 2MB blobs get stored permanently; socket
  payload shape changes (representation URLs in `comment.attachments`);
  needs a one-off backfill job to preprocess existing attachments; adds a
  job + queue to monitor.

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

---

*See also: `docs/TODO.md` (undecided/future work), `docs/ROADMAP.md`
(phases), `docs/WEBSOCKET.md` (channels/events), `docs/CACHE.md` (tiers).*
