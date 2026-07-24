package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"net/http"
	"sync"
	"time"
)

// =========================================================================
// GLOBAL CONFIGURATION (Constants)
// =========================================================================
const (
	ServerPort = ":4000"
	BaseIP     = "192.168.0.100"

	WebhookSecureSecret  = "local_secure_dev_secret"
	WebhookClientTimeout = 5 * time.Second
	MockQRWebhookDelay   = 1 * time.Second
)

// =========================================================================
// STRUCTS & SCHEMAS FOR BANK SYSTEM 1: INSTANT QR PAYMENTS
// =========================================================================

type QRPaymentRequest struct {
	Amount           int    `json:"amount"`
	InvoiceID        string `json:"invoice_id"`
	TransactionToken string `json:"transaction_token"`
	Memo             string `json:"memo"`
	ReturnURL        string `json:"return_url,omitempty"`
	WebhookURL       string `json:"webhook_url,omitempty"`
}

type QRPaymentResponse struct {
	Success  bool             `json:"success"`
	QRString string           `json:"qr_string"`
	Received QRPaymentRequest `json:"received"`
}

// =========================================================================
// STRUCTS & SCHEMAS FOR BANK SYSTEM 2: AUTO-REDIRECT PORTAL
// =========================================================================

type RedirectSessionRequest struct {
	AmountCents     int    `json:"amount_cents"`
	InvoiceUUID     string `json:"invoice_uuid"`
	TxnChannelToken string `json:"txn_channel_token"`
	RedirectURL     string `json:"redirect_url"`
	CallbackWebhook string `json:"callback_webhook"`
	CancelURL       string `json:"cancel_url,omitempty"`
}

type RedirectSessionResponse struct {
	SessionID   string    `json:"session_id"`
	CheckoutURL string    `json:"checkout_url"`
	ExpiresAt   time.Time `json:"expires_at"`
}

// Memory store tracking the structured session data for System 2
var (
	activeSessions = make(map[string]RedirectSessionRequest)
	sessionsMu     sync.RWMutex
)

// =========================================================================
// MAIN ENGINE
// =========================================================================

func main() {
	hostedCheckoutBase := fmt.Sprintf("http://%s%s", BaseIP, ServerPort)

	// -------------------------------------------------------------------------
	// ROUTE 0: DIAGNOSTICS
	// -------------------------------------------------------------------------
	http.HandleFunc("/api/v1/ping", func(w http.ResponseWriter, r *http.Request) {
		startTime := time.Now()
		logAction("PING", fmt.Sprintf("Inbound Ping | Client: %s | Method: %s | User-Agent: %s", r.RemoteAddr, r.Method, r.UserAgent()))

		respData := map[string]interface{}{
			"status":  "online",
			"message": "🚀 Skycom Auto-Redirect Multi-Bank Sandbox is active!",
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(respData)
		logVerbose("PING_RESP", respData)
		logSuccess("PING", fmt.Sprintf("Ping responded in %v", time.Since(startTime)))
	})

	// -------------------------------------------------------------------------
	// ROUTE 1: QR GENERATE (Bank System 1)
	// -------------------------------------------------------------------------
	http.HandleFunc("/api/v1/bank/qr-generate", func(w http.ResponseWriter, r *http.Request) {
		startTime := time.Now()
		logAction("BANK_1_QR", fmt.Sprintf("Request received from %s", r.RemoteAddr))

		var req QRPaymentRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			logError("BANK_1_QR", fmt.Sprintf("Failed to parse JSON body: %v", err))
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		logVerbose("BANK_1_QR_REQ", req)

		if req.Amount <= 0 || req.InvoiceID == "" || req.TransactionToken == "" {
			logWarn("BANK_1_QR", fmt.Sprintf("Validation failed! Missing critical fields. Amount: %d, InvoiceID: '%s', Token: '%s'", req.Amount, req.InvoiceID, req.TransactionToken))
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"success": false,
				"error":   "Missing required fields (amount, invoice_id, or transaction_token)",
			})
			return
		}

		txnID := fmt.Sprintf("TXN_QR_%d", time.Now().UnixNano())
		qrString := fmt.Sprintf("00020101021238580010A0000|AMT:%d|INV:%s|TOKEN:%s|TXN:%s", req.Amount, req.InvoiceID, req.TransactionToken, txnID)

		logSuccess("BANK_1_QR", fmt.Sprintf("Generated TxnID: %s | QR String: %s", txnID, qrString))

		targetURL := req.WebhookURL
		if targetURL == "" {
			targetURL = fmt.Sprintf("http://%s:3000/webhooks/bank_payment", BaseIP)
			logAction("BANK_1_QR", fmt.Sprintf("No WebhookURL passed in payload. Defaulting to: %s", targetURL))
		} else {
			logAction("BANK_1_QR", fmt.Sprintf("Custom WebhookURL specified in request: %s", targetURL))
		}

		go func(tID, invID, token string, amt int, url string) {
			logAction("BANK_1_QR", fmt.Sprintf("Scheduling webhook dispatch in %v...", MockQRWebhookDelay))
			time.Sleep(MockQRWebhookDelay)
			fireBank1QRWebhook(tID, invID, token, amt, url)
		}(txnID, req.InvoiceID, req.TransactionToken, req.Amount, targetURL)

		respPayload := QRPaymentResponse{
			Success:  true,
			QRString: qrString,
			Received: req,
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(respPayload)
		logVerbose("BANK_1_QR_RESP", respPayload)
		logSuccess("BANK_1_QR", fmt.Sprintf("Response dispatched to client in %v", time.Since(startTime)))
	})

	// -------------------------------------------------------------------------
	// ROUTE 2: REDIRECT SESSION SETUP (Bank System 2)
	// -------------------------------------------------------------------------
	http.HandleFunc("/api/v1/bank/redirect-session", func(w http.ResponseWriter, r *http.Request) {
		startTime := time.Now()
		logAction("BANK_2_RED", fmt.Sprintf("Session setup requested by %s", r.RemoteAddr))

		var req RedirectSessionRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			logError("BANK_2_RED", fmt.Sprintf("Failed to decode JSON request: %v", err))
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		logVerbose("BANK_2_RED_REQ", req)

		if req.AmountCents <= 0 || req.InvoiceUUID == "" || req.TxnChannelToken == "" || req.RedirectURL == "" || req.CallbackWebhook == "" {
			logWarn("BANK_2_RED", fmt.Sprintf("Validation failed! Checking fields: AmountCents=%d, InvoiceUUID='%s', TxnChannelToken='%s', RedirectURL='%s', CallbackWebhook='%s'",
				req.AmountCents, req.InvoiceUUID, req.TxnChannelToken, req.RedirectURL, req.CallbackWebhook))
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		sessionID := fmt.Sprintf("SESS_%d", time.Now().UnixNano())

		sessionsMu.Lock()
		activeSessions[sessionID] = req
		sessionsMu.Unlock()

		logSuccess("BANK_2_RED", fmt.Sprintf("Stored Session [%s] in active memory map.", sessionID))

		redirectURL := fmt.Sprintf("%s/bank/hosted-checkout?session_id=%s", hostedCheckoutBase, sessionID)
		expiresAt := time.Now().Add(15 * time.Minute)

		resp := RedirectSessionResponse{
			SessionID:   sessionID,
			CheckoutURL: redirectURL,
			ExpiresAt:   expiresAt,
		}

		logSuccess("BANK_2_RED", fmt.Sprintf("Created Session ID: %s | Checkout URL: %s", sessionID, redirectURL))
		logVerbose("BANK_2_RED_RESP", resp)

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(resp)
		logSuccess("BANK_2_RED", fmt.Sprintf("Completed session creation in %v", time.Since(startTime)))
	})

	// -------------------------------------------------------------------------
	// ROUTE 3: HOSTED CHECKOUT PAGE
	// -------------------------------------------------------------------------
	http.HandleFunc("/bank/hosted-checkout", func(w http.ResponseWriter, r *http.Request) {
		startTime := time.Now()
		sessionID := r.URL.Query().Get("session_id")

		logAction("BANK_2_WEB", fmt.Sprintf("Browser hit hosted checkout | Full URL: %s | Query Session ID: '%s'", r.URL.String(), sessionID))

		if sessionID == "" {
			logError("BANK_2_WEB", "Missing 'session_id' query parameter in request URL!")
			http.Error(w, "Missing session_id parameter", http.StatusBadRequest)
			return
		}

		sessionsMu.Lock()
		sessionData, exists := activeSessions[sessionID]
		if exists {
			delete(activeSessions, sessionID) // Clear session on access
		}
		sessionsMu.Unlock()

		if !exists {
			logError("BANK_2_WEB", fmt.Sprintf("Session ID '%s' NOT FOUND in active memory map (or already used/expired)!", sessionID))
			http.Error(w, "Invalid or Expired Payment Session", http.StatusBadRequest)
			return
		}

		logSuccess("BANK_2_WEB", fmt.Sprintf("Session [%s] located successfully.", sessionID))
		logVerbose("BANK_2_WEB_SESS_DATA", sessionData)

		txnID := fmt.Sprintf("BANK2_AUTO_%d", time.Now().UnixNano())
		logAction("BANK_2_WEB", fmt.Sprintf("Triggering background webhook to: %s", sessionData.CallbackWebhook))

		go fireBank2RedirectWebhook(txnID, sessionData.InvoiceUUID, sessionData.TxnChannelToken, sessionData.AmountCents, sessionData.CallbackWebhook)

		tmpl := `<!DOCTYPE html>
		<html>
		<head>
			<title>🏦 Bank Auto Redirecting...</title>
			<style>
				body { font-family: sans-serif; background: #1e1e2e; color: #cdd6f4; padding: 100px; text-align: center; }
				.box { background: #313244; padding: 40px; border-radius: 8px; display: inline-block; min-width: 350px; }
				.spinner { border: 4px solid rgba(255,255,255,0.1); width: 36px; height: 36px; border-radius: 50%; border-left-color: #a6e3a1; animation: spin 1s linear infinite; margin: 20px auto; }
				@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
			</style>
			<script>
				window.onload = function() {
					setTimeout(function() {
						window.location.href = "{{.RedirectURL}}";
					}, 800);
				};
			</script>
		</head>
		<body>
			<div class="box">
				<h2>🏦 BANK SIMULATOR PORTAL</h2>
				<p style="color: #a6e3a1; font-weight: bold;">✓ PAYMENT AUTHORIZED SUCCESSFULLY</p>
				<p>Securing connection pipe, transferring back to Skycom...</p>
				<div class="spinner"></div>
			</div>
		</body>
		</html>`

		t, err := template.New("webpage").Parse(tmpl)
		if err != nil {
			logError("BANK_2_WEB", fmt.Sprintf("HTML template parsing error: %v", err))
			http.Error(w, "Template Render Error", http.StatusInternalServerError)
			return
		}

		t.Execute(w, map[string]interface{}{
			"RedirectURL": sessionData.RedirectURL,
		})

		logSuccess("BANK_2_WEB", fmt.Sprintf("Rendered auto-redirect HTML page pointing to '%s' in %v", sessionData.RedirectURL, time.Since(startTime)))
	})

	fmt.Printf("🚀 Multi-Banking Interface Architecture Server running on port %s...\n\n", ServerPort)
	http.ListenAndServe(ServerPort, nil)
}

// =========================================================================
// BANK PIPELINE 1: DISPATCHER (QR PAYMENTS)
// =========================================================================

func fireBank1QRWebhook(txnID string, invoiceID string, transactionToken string, amount int, webhookURL string) {
	logAction("CB_BANK_1", fmt.Sprintf("Building webhook payload for TxnID: %s", txnID))

	payloadMap := map[string]interface{}{
		"event": "transaction.completed",
		"data": map[string]interface{}{
			"transaction_id":    txnID,
			"invoice_id":        invoiceID,
			"transaction_token": transactionToken,
			"amount":            amount,
			"paid_at":           time.Now().Format(time.RFC3339),
		},
	}

	payload, err := json.Marshal(payloadMap)
	if err != nil {
		logError("CB_BANK_1", fmt.Sprintf("Failed to marshal webhook payload: %v", err))
		return
	}

	executePostRequest(webhookURL, payload, "X-Skycom-Bank-Signature", "CB_BANK_1")
}

// =========================================================================
// BANK PIPELINE 2: DISPATCHER (HOSTED REDIRECT)
// =========================================================================

func fireBank2RedirectWebhook(referenceID string, referenceUUID string, channelToken string, values int, targetURL string) {
	logAction("CB_BANK_2", fmt.Sprintf("Building redirect webhook payload for RefID: %s", referenceID))

	payloadMap := map[string]interface{}{
		"bank_code":         "VIET_BANK_DIRECT_2026",
		"reference_code":    referenceID,
		"associated_uuid":   referenceUUID,
		"authorized_token":  channelToken,
		"settlement_amount": values,
		"status":            "SUCCESS_PAID",
		"timestamp_epoch":   time.Now().Unix(),
	}

	payload, err := json.Marshal(payloadMap)
	if err != nil {
		logError("CB_BANK_2", fmt.Sprintf("Failed to marshal webhook payload: %v", err))
		return
	}

	executePostRequest(targetURL, payload, "X-Skycom-RedirectBank-Signature", "CB_BANK_2")
}

// =========================================================================
// GLOBAL COMMUNICATOR MIDDLEWARE
// =========================================================================

func executePostRequest(targetURL string, payload []byte, securityHeader string, tag string) {
	startTime := time.Now()
	logAction(tag, fmt.Sprintf("Preparing HTTP POST request to URL: %s", targetURL))
	logVerbose(tag+"_PAYLOAD", json.RawMessage(payload))

	req, err := http.NewRequest("POST", targetURL, bytes.NewBuffer(payload))
	if err != nil {
		logError(tag, fmt.Sprintf("Failed to initialize HTTP request object: %v", err))
		return
	}

	req.Header.Set(securityHeader, WebhookSecureSecret)
	req.Header.Set("Content-Type", "application/json")

	logAction(tag, fmt.Sprintf("Headers set -> [%s: %s, Content-Type: application/json]", securityHeader, WebhookSecureSecret))

	client := &http.Client{Timeout: WebhookClientTimeout}
	resp, err := client.Do(req)
	if err != nil {
		logError(tag, fmt.Sprintf("NETWORK ERROR dispatching webhook to '%s': %v (took %v)", targetURL, err, time.Since(startTime)))
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		logSuccess(tag, fmt.Sprintf("Webhook delivered to '%s' | Status: %s | Elapsed: %v", targetURL, resp.Status, time.Since(startTime)))
	} else {
		logWarn(tag, fmt.Sprintf("Webhook delivered to '%s' BUT returned non-2xx status: %s | Elapsed: %v", targetURL, resp.Status, time.Since(startTime)))
	}
}

// =========================================================================
// LOGGING UTILITIES
// =========================================================================

func logAction(context string, message string)  { fmt.Printf("📥 [%-14s] %s\n", context, message) }
func logSuccess(context string, message string) { fmt.Printf("🟢 [%-14s] SUCCESS: %s\n", context, message) }
func logWarn(context string, message string)    { fmt.Printf("⚠️  [%-14s] WARNING: %s\n", context, message) }
func logError(context string, message string)   { fmt.Printf("❌ [%-14s] ERROR: %s\n", context, message) }

// Pretty prints structs, maps, or JSON payloads
func logVerbose(context string, data interface{}) {
	prettyJSON, err := json.MarshalIndent(data, "               │ ", "  ")
	if err != nil {
		fmt.Printf("🔍 [%-14s] RAW: %+v\n", context, data)
		return
	}
	fmt.Printf("🔍 [%-14s] DATA:\n               │ %s\n", context, string(prettyJSON))
}