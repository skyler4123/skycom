package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"net/http"
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
// STRUCTS & SCHEMAS FOR BANK SYSTEM 2: HOSTED REDIRECT PORTAL
// =========================================================================

type RedirectSessionRequest struct {
	AmountCents     int    `json:"amount_cents"`      // Custom naming format
	InvoiceUUID     string `json:"invoice_uuid"`      // Custom naming format
	TxnChannelToken string `json:"txn_channel_token"` // Custom naming format
	RedirectURL     string `json:"redirect_url"`      // Dynamic return URL requested by user
	CallbackWebhook string `json:"callback_webhook"`   // Dedicated webhooks destination
	CancelURL       string `json:"cancel_url,omitempty"`
}

type RedirectSessionResponse struct {
	SessionID   string    `json:"session_id"`
	CheckoutURL string    `json:"checkout_url"`
	ExpiresAt   time.Time `json:"expires_at"`
}

// Memory store tracking the structured session data for System 2
var activeSessions = make(map[string]RedirectSessionRequest)

// =========================================================================
// MAIN ENGINE
// =========================================================================

func main() {
	hostedCheckoutBase := fmt.Sprintf("http://%s%s", BaseIP, ServerPort)

	// -------------------------------------------------------------------------
	// ROUTE 0: DIAGNOSTICS
	// -------------------------------------------------------------------------
	http.HandleFunc("/api/v1/ping", func(w http.ResponseWriter, r *http.Request) {
		logAction("PING", fmt.Sprintf("Active ping test from client IP: %s", r.RemoteAddr))
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":  "online",
			"message": "🚀 Skycom Multi-Bank Gateway Sandbox is humming smoothly!",
		})
	})

	// -------------------------------------------------------------------------
	// ROUTE 1: QR GENERATE (Bank System 1 - Unchanged behavior)
	// -------------------------------------------------------------------------
	http.HandleFunc("/api/v1/bank/qr-generate", func(w http.ResponseWriter, r *http.Request) {
		logAction("BANK_1_QR", "Received generation request")
		var req QRPaymentRequest
		
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			logError("BANK_1_QR", fmt.Sprintf("Failed to decode JSON: %v", err))
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		if req.Amount <= 0 || req.InvoiceID == "" || req.TransactionToken == "" {
			logWarn("BANK_1_QR", "Validation Failed. Missing critical fields.")
			w.WriteHeader(http.StatusBadRequest)
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]interface{}{
				"success": false,
				"error":   "Missing required fields (amount, invoice_id, or transaction_token)",
			})
			return
		}

		txnID := fmt.Sprintf("TXN_QR_%d", time.Now().UnixNano())
		qrString := fmt.Sprintf("00020101021238580010A0000|AMT:%d|INV:%s|TOKEN:%s|TXN:%s", req.Amount, req.InvoiceID, req.TransactionToken, txnID)
		
		logSuccess("BANK_1_QR", fmt.Sprintf("Generated Txn: %s for Rails Token: %s", txnID, req.TransactionToken))

		// Fire dedicated Bank 1 pipeline callback
		go func() {
			time.Sleep(MockQRWebhookDelay)
			targetURL := req.WebhookURL
			if targetURL == "" {
				targetURL = "http://" + BaseIP + ":3000/webhooks/bank_payment" // Fallback fallback route
			}
			fireBank1QRWebhook(txnID, req.InvoiceID, req.TransactionToken, req.Amount, targetURL)
		}()

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(QRPaymentResponse{
			Success:  true,
			QRString: qrString,
			Received: req,
		})
	})

	// -------------------------------------------------------------------------
	// ROUTE 2: REDIRECT SESSION SETUP (Bank System 2 - Accepts redirect_url)
	// -------------------------------------------------------------------------
	http.HandleFunc("/api/v1/bank/redirect-session", func(w http.ResponseWriter, r *http.Request) {
		logAction("BANK_2_RED", "Setting up unique checkout session")
		var req RedirectSessionRequest
		
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			logError("BANK_2_RED", fmt.Sprintf("Failed to decode JSON: %v", err))
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		// Validation checking the newly added dynamic redirect_url parameter
		if req.AmountCents <= 0 || req.InvoiceUUID == "" || req.TxnChannelToken == "" || req.RedirectURL == "" || req.CallbackWebhook == "" {
			logWarn("BANK_2_RED", "Validation Failed. Missing unique checkout or routing params.")
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		sessionID := fmt.Sprintf("SESS_%d", time.Now().UnixNano())
		activeSessions[sessionID] = req 
		
		redirectURL := fmt.Sprintf("%s/bank/hosted-checkout?session_id=%s", hostedCheckoutBase, sessionID)
		logSuccess("BANK_2_RED", fmt.Sprintf("Created Session for Token %s -> Redirect: %s", req.TxnChannelToken, redirectURL))

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(RedirectSessionResponse{
			SessionID:   sessionID,
			CheckoutURL: redirectURL,
			ExpiresAt:   time.Now().Add(15 * time.Minute),
		})
	})

	// -------------------------------------------------------------------------
	// ROUTE 3: HOSTED CHECKOUT PAGE (HTML)
	// -------------------------------------------------------------------------
	http.HandleFunc("/bank/hosted-checkout", func(w http.ResponseWriter, r *http.Request) {
		sessionID := r.URL.Query().Get("session_id")
		logAction("BANK_2_WEB", fmt.Sprintf("Serving Checkout Page for Session: %s", sessionID))
		
		sessionData, exists := activeSessions[sessionID]
		if !exists {
			logError("BANK_2_WEB", fmt.Sprintf("Session ID %s not found in memory!", sessionID))
			http.Error(w, "Invalid Payment Session", http.StatusBadRequest)
			return
		}

		tmpl := `<!DOCTYPE html>
		<html>
		<head>
			<title>🏦 Mock Hosted Checkout</title>
			<style>
				body { font-family: sans-serif; background: #1e1e2e; color: #cdd6f4; padding: 50px; text-align: center; }
				.card { background: #313244; padding: 30px; border-radius: 8px; display: inline-block; width: 400px; }
				input { width: 90%; padding: 10px; margin: 10px 0; background: #11111b; color: #fff; border: 1px solid #45475a; }
				button { background: #a6e3a1; color: #11111b; border: 0; padding: 12px 20px; font-weight: bold; width: 95%; cursor: pointer; }
			</style>
		</head>
		<body>
			<div class="card">
				<h2>🔒 SECURE HOSTED PORTAL</h2>
				<form action="/bank/hosted-checkout/submit" method="POST">
					<input type="hidden" name="session_id" value="{{.SessionID}}">
					<input type="text" value="Invoice Reference: {{.InvoiceUUID}}" disabled>
					<input type="text" value="Transaction Token: {{.TxnChannelToken}}" disabled>
					<input type="text" value="Amount: {{.Amount}} cents" disabled>
					<button type="submit">🔒 CONFIRM & SUBMIT</button>
				</form>
			</div>
		</body>
		</html>`

		t, _ := template.New("webpage").Parse(tmpl)
		t.Execute(w, map[string]interface{}{
			"SessionID":        sessionID, 
			"InvoiceUUID":      sessionData.InvoiceUUID, 
			"TxnChannelToken":  sessionData.TxnChannelToken,
			"Amount":           sessionData.AmountCents,
		})
	})

	// -------------------------------------------------------------------------
	// ROUTE 4: FORM SUBMISSION PROCESSOR (Redirects to client custom dynamic URL)
	// -------------------------------------------------------------------------
	http.HandleFunc("/bank/hosted-checkout/submit", func(w http.ResponseWriter, r *http.Request) {
		logAction("BANK_2_SUBMIT", "Processing browser payment submission")
		r.ParseForm()
		sessionID := r.FormValue("session_id")
		
		sessionData, exists := activeSessions[sessionID]
		if !exists {
			logError("BANK_2_SUBMIT", fmt.Sprintf("Submitted with expired Session ID: %s", sessionID))
			http.Error(w, "Session expired", http.StatusBadRequest)
			return
		}

		txnID := fmt.Sprintf("BANK2_REDR_%d", time.Now().UnixNano())
		logSuccess("BANK_2_SUBMIT", fmt.Sprintf("Processed Card. Rails Token: %s -> Bank Txn ID: %s", sessionData.TxnChannelToken, txnID))

		// Fire dedicated Bank 2 pipeline callback asynchronous engine
		go fireBank2RedirectWebhook(txnID, sessionData.InvoiceUUID, sessionData.TxnChannelToken, sessionData.AmountCents, sessionData.CallbackWebhook)
		
		destinationURL := sessionData.RedirectURL
		delete(activeSessions, sessionID)
		logAction("DATABASE", fmt.Sprintf("Cleaned up session %s from active memory map.", sessionID))

		logAction("REDIRECT", fmt.Sprintf("Redirecting user back to customized dynamic app page: %s", destinationURL))
		http.Redirect(w, r, destinationURL, http.StatusSeeOther)
	})

	fmt.Printf("🚀 Multi-Banking Interface Architecture Server running on port %s...\n", ServerPort)
	http.ListenAndServe(ServerPort, nil)
}

// =========================================================================
// BANK PIPELINE 1: DISPATCHER (QR PAYMENTS payload layout structure)
// =========================================================================

func fireBank1QRWebhook(txnID string, invoiceID string, transactionToken string, amount int, webhookURL string) {
	logAction("CB_BANK_1", fmt.Sprintf("Preparing dispatch payload for Txn: %s", txnID))

	// Traditional original format structure maintained completely
	payload, _ := json.Marshal(map[string]interface{}{
		"event": "transaction.completed",
		"data": map[string]interface{}{
			"transaction_id":    txnID, 
			"invoice_id":        invoiceID, 
			"transaction_token": transactionToken, 
			"amount":            amount, 
			"paid_at":           time.Now().Format(time.RFC3339),
		},
	})
	
	executePostRequest(webhookURL, payload, "X-Skycom-Bank-Signature")
}

// =========================================================================
// BANK PIPELINE 2: DISPATCHER (HOSTED REDIRECT entirely unique payload structure)
// =========================================================================

func fireBank2RedirectWebhook(referenceID string, referenceUUID string, channelToken string, values int, targetURL string) {
	logAction("CB_BANK_2", fmt.Sprintf("Preparing distinct system webhooks structure for ref: %s", referenceID))

	// Totally unique JSON schema structure for Bank system 2 scaling verification
	payload, _ := json.Marshal(map[string]interface{}{
		"bank_code":         "VIET_BANK_DIRECT_2026",
		"reference_code":    referenceID,
		"associated_uuid":   referenceUUID,
		"authorized_token":  channelToken,
		"settlement_amount": values,
		"status":            "SUCCESS_PAID",
		"timestamp_epoch":   time.Now().Unix(),
	})

	// Different custom header signature token to isolate security context completely
	executePostRequest(targetURL, payload, "X-Skycom-RedirectBank-Signature")
}

// =========================================================================
// GLOBAL COMMUNICATOR MIDDLEWARE
// =========================================================================

func executePostRequest(targetURL string, payload []byte, securityHeader string) {
	req, _ := http.NewRequest("POST", targetURL, bytes.NewBuffer(payload))
	req.Header.Set(securityHeader, WebhookSecureSecret)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: WebhookClientTimeout}
	resp, err := client.Do(req)
	if err != nil {
		logError("NET_POST", fmt.Sprintf("Failed to contact webhook handler endpoint: %v\n", err))
		return
	}
	defer resp.Body.Close()

	logSuccess("NET_POST", fmt.Sprintf("Target processed payload event. Status code received: %s\n", resp.Status))
}

// =========================================================================
// LOGGING UTILITIES
// =========================================================================

func logAction(context string, message string)  { fmt.Printf("📥 [%-14s] %s\n", context, message) }
func logSuccess(context string, message string) { fmt.Printf("🟢 [%-14s] SUCCESS: %s\n", context, message) }
func logWarn(context string, message string)    { fmt.Printf("⚠️  [%-14s] WARNING: %s\n", context, message) }
func logError(context string, message string)   { fmt.Printf("❌ [%-14s] ERROR: %s\n", context, message) }