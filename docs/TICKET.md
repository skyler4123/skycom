# Skycom Ticket Feature

## Overview

**Scope note:** A `Ticket` is an **internal service of a Company** — employees use it to track
internal work (issues, requests, procurement) *inside* the company. It is **not** an external
support ticket to Skycom; that is `CompanyTicket` (Help Center). `CompanyTicket` and `Ticket`
share workflow machinery but serve different audiences.

A `Ticket` is an internal issue tracker for employees. It combines:
- **Purchase-style workflow binding**: a Ticket belongs to a `Category`; the category owns a `Workflow` (default 4 steps: *To Do → In Progress → Review → Done*). Transitions go through `Workflows::AdvanceService` with ABAC `can?(:update, Ticket)` (Jira-style, no per-step roles).
- **Real-time collaboration**: assignee (Employee), comments (`TicketComment`), and a dedicated `TicketLog` for ticket lifecycle events.

## Permission model

Same as Purchase: a workflow transition requires update permission on the subject — `employee.can?(:update, Ticket)`. ABAC is the only permission system. Every transition is audited by `WorkflowStepLog` (generic) and a `TicketLog` entry.

## Data model

- `Ticket` → `tickets` (company, employee creator, assigned_employee, category, property_mapping, workflow_step, name, description, priority, lifecycle/workflow status, property_* slots).
- `TicketComment` → `ticket_comments` (company, ticket, employee, message).
- `TicketLog` → `ticket_logs` (company, ticket, actor, action, from_status, to_status, note).

## Workflow

Category is the bridge. `Ticket#bind_category_workflow` runs on create and binds the category's default `ticket_process` workflow (first step + `pending`). No workflow → `draft`. Pointer moves only via `POST .../tickets/:id/advance`.

## Real-time

WebSocket events: `ticket_created`, `ticket_commented`, `ticket_workflow_step_changed`, `ticket_assigned`.

## Seeding

Init services create `tickets` categories and a 4-step workflow per category. Role grants mirror CompanyTicket (Admin/Manager full CRUD; employees create/read/update Ticket).

## Seeding

Enriched companies seed ~6 internal `Ticket` rows (round-robin across the `tickets`
categories) plus `TicketComment` threads, with workflow states spread across phases
(completed / rejected / reworked / pending), mirroring
`Seed::CompanyTicketService.create_sample_thread`.

## File reference

- `app/models/ticket.rb`, `ticket_comment.rb`, `ticket_log.rb`
- `app/controllers/companies/tickets_controller.rb`, `ticket_comments_controller.rb`, `ticket_logs_controller.rb`
- `app/policies/companies/tickets_policy.rb`, `ticket_comments_policy.rb`, `ticket_logs_policy.rb`
- `app/services/seed/ticket_service.rb`, `ticket_comment_service.rb`
- `app/javascript/controllers/companies/tickets/*`
- `spec/models/ticket*_spec.rb`, `spec/features/companies/tickets/*`
- `docs/TICKET.md`