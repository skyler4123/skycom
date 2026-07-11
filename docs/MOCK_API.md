# Mock API Server

## 1. Overview

The Mock API Server is a lightweight Go HTTP server that simulates external APIs during local development. Instead of connecting to real banking gateways, SMS providers, or shipping carriers, the Rails app talks to this server — making development fully offline, deterministic, and free of third-party dependencies.

| Aspect | Detail |
|--------|--------|
| **Language** | Go (no external dependencies — standard `net/http`) |
| **File** | `mock_api/main.go` |
| **Port** | `4000` |
| **Start method** | Docker Compose service (`mock-api`) |
| **Hostname (from Rails)** | `mock-api:4000` inside the Docker network; `localhost:4000` from the host |

---

## 2. How It Starts

The `mock-api` service is defined in `docker-compose.yml`:

```yaml
mock-api:
  image: golang:1.22-alpine
  working_dir: /go/src/app
  volumes:
    - ./mock_api:/go/src/app
  command: go run main.go
  ports:
    - "4000:4000"
```

It mounts `mock_api/main.go` into the container and runs it with `go run`. Any change to `main.go` requires a restart:

```bash
docker compose restart mock-api
```

---

## 3. Architecture

The server uses Go's standard `net/http` package. All routes are registered in `func main()` via `http.HandleFunc`. It has three layers:

```
HTTP Request
    │
    ▼
Handler func ──► decode JSON body (optional)
    │
    ├── process logic (compute, generate IDs, etc.)
    ├── optionally: fire async webhook callback
    │
    └── encode JSON response (or render HTML)
```

### Shared State

A global `activeSessions` map (`map[string]PaymentRequest`) holds in-memory state for the redirect checkout flow. This is ephemeral — lost on restart. For most routes this is fine (mocking stateless APIs). If you need persistent mock state, use the in-memory map pattern.

### Webhook Callback

After certain actions (e.g., processing a payment), the mock server fires an async HTTP POST to the Rails app:

```
mock_api
  └─ goroutine: POST http://skycom-web:3000/webhooks/bank_payment
       headers:
         X-Skycom-Bank-Signature: local_secure_dev_secret
         Content-Type: application/json
       body:
         { "event": "transaction.completed",
           "data": { "transaction_id": "...", "invoice_id": "...", ... } }
```

The `fireWebhookCallback` helper sends this with a 5-second timeout. It silently ignores errors (no retry) — the mock is best-effort.

> **Important**: The inbound webhook endpoint (`/webhooks/bank_payment`) must exist in the Rails app for the webhook to be received. If the endpoint doesn't exist yet, it needs to be implemented alongside the mock route.

---

## 4. Current Routes

| Group | Method | Path | Purpose | Request | Response |
|-------|--------|------|---------|---------|----------|
| Diagnostic | `GET` | `/api/v1/ping` | Health check | — | `{ status, message, current_time, environment }` |
| Banking | `POST` | `/api/v1/bank/qr-generate` | Generate QR payment code | `{ amount, invoice_id, memo }` | `{ success, qr_string }` + fires webhook |
| Banking | `POST` | `/api/v1/bank/redirect-session` | Create hosted checkout session | `{ amount, invoice_id, memo }` | `{ success, redirect_url }` |
| Banking | `GET` | `/bank/hosted-checkout` | Render mock checkout form (HTML) | `?session_id=` | Renders HTML page with form |
| Banking | `POST` | `/bank/hosted-checkout/submit` | Process checkout form submission | `session_id`, `amount` (form) | Redirects to `/checkout/success` + fires webhook |

---

## 5. How to Add a New External API

Every new external API follows the same pattern.

### Step 1: Add a Request Struct (if needed)

If the API accepts a JSON body with multiple fields, define a struct near the top of `main.go`:

```go
type SMSRequest struct {
	Phone   string `json:"phone"`
	Message string `json:"message"`
}
```

For simple requests (e.g., a single query param), inline parsing is fine.

### Step 2: Register the Handler

Add a `http.HandleFunc` call inside `main()`. Group related routes under a comment header:

```go
// =========================================================================
// ROUTE GROUP N: SMS SERVICE
// =========================================================================

http.HandleFunc("/api/v1/sms/send", func(w http.ResponseWriter, r *http.Request) {
	var req SMSRequest
	json.NewDecoder(r.Body).Decode(&req)

	// Simulate SMS sending
	fmt.Printf("📱 [Mock SMS] Sent to %s: %s\n", req.Phone, req.Message)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message_id": fmt.Sprintf("SMS_%d", time.Now().UnixNano()),
	})
})
```

### Step 3: Add a Webhook Callback (if the real API would send one)

If the external API normally sends a webhook on completion, call `fireWebhookCallback` in a goroutine:

```go
go fireWebhookCallback(txnID, invoiceID, amount)
```

The helper is already defined at the bottom of `main.go`. If your webhook needs a different payload shape, you can either:
- Extend `fireWebhookCallback` to accept a custom payload
- Write a new inline goroutine in the handler

### Step 4: Restart the Mock Server

```bash
docker compose restart mock-api
```

The server logs activity to stdout, so check the logs to verify:

```bash
docker compose logs mock-api
```

---

## 6. Template: Adding a Simple GET/POST API

### Minimal JSON endpoint

```go
http.HandleFunc("/api/v1/external/lookup", func(w http.ResponseWriter, r *http.Request) {
	// Optional: read request
	id := r.URL.Query().Get("id")

	// Optional: log
	fmt.Printf("🔍 [Lookup] id=%s\n", id)

	// Respond
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"found":  true,
		"name":   "Mock Item",
		"status": "available",
	})
})
```

### Endpoint with webhook callback

```go
http.HandleFunc("/api/v1/external/process", func(w http.ResponseWriter, r *http.Request) {
	var req SomeRequest
	json.NewDecoder(r.Body).Decode(&req)

	resultID := fmt.Sprintf("RES_%d", time.Now().UnixNano())

	// Fire webhook asynchronously
	go fireWebhookCallback(resultID, req.Reference, req.Amount)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"id":      resultID,
	})
})
```

---

## 7. Route Organization Conventions

- Add a `ROUTE GROUP` comment header for each domain (e.g., `BANKING SUITE`, `SMS SERVICE`, `SHIPPING`)
- Keep the group number sequential (0, 1, 2, ...)
- Place the `future extension hook spot` comment at the end of `main()` so new routes can be added before it
- Use emoji prefixes in log messages for quick visual scanning (e.g., `📡` for diagnostics, `📱` for SMS, `📦` for shipping)

---

## 8. Troubleshooting

| Problem | Likely Cause | Fix |
|---------|-------------|-----|
| `connection refused` on port 4000 | Mock API container not running | `docker compose up -d mock-api` |
| Changes not reflected | `go run main.go` doesn't auto-reload | `docker compose restart mock-api` |
| Rails can't reach `mock-api:4000` | Wrong hostname in config | Inside Docker network, use `mock-api`; from host, use `localhost` |
| Webhook not received by Rails | Inbound endpoint missing | Check Rails routes for the webhook path |

---

## 9. File Reference

| File | Purpose |
|------|---------|
| `mock_api/main.go` | All mock server code (routes, structs, helpers) |
| `docker-compose.yml:140-149` | Mock API Docker Compose service definition |

---

*End of document*
