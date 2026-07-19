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

	ClientSuccessURL = "http://" + BaseIP + ":3000/checkout/success"

	WebhookTargetURL     = "http://" + BaseIP + ":3000/webhooks/bank_payment"
	WebhookSecureSecret  = "local_secure_dev_secret"
	WebhookClientTimeout = 5 * time.Second
	MockQRWebhookDelay   = 1 * time.Second
)

// =========================================================================
// TYPES & MEMORY STORE
// =========================================================================

// QR Flow Structs (UNCHANGED JSON mappings to match original behavior)
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

// Redirect Flow Structs (Distinct parameters and response structures)
type RedirectSessionRequest struct {
	Amount           int    `json:"amount_cents"`      // Custom parameter
	InvoiceUUID      string `json:"invoice_uuid"`      // Custom parameter
	TxnChannelToken  string `json:"txn_channel_token"` // Custom parameter
	CallbackWebhook  string `json:"callback_webhook,omitempty"`
	CancelURL        string `json:"cancel_url,omitempty"`
}

type RedirectSessionResponse struct {
	SessionID  string    `json:"session_id"`
	CheckoutURL string   `json:"checkout_url"`
	ExpiresAt  time.Time `json:"expires_at"`
}

// Memory store tracking the structured session data
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
			"message": "🚀 Skycom Mock API Engine is humming smoothly!",
		})
	})

	// -------------------------------------------------------------------------
	// ROUTE 1: QR GENERATE (Input & Output formats preserved)
	// -------------------------------------------------------------------------
	http.HandleFunc("/api/v1/bank/qr-generate", func(w http.ResponseWriter, r *http.Request) {
		logAction("QR FLOW", "Received generation request")
		var req QRPaymentRequest
		
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			logError("QR FLOW", fmt.Sprintf("Failed to decode JSON: %v", err))
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		if req.Amount <= 0 || req.InvoiceID == "" || req.TransactionToken == "" {
			logWarn("QR FLOW", "Validation Failed. Missing critical fields.")
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
		
		logSuccess("QR FLOW", fmt.Sprintf("Generated Txn: %s for Rails Token: %s", txnID, req.TransactionToken))

		go func() {
			time.Sleep(MockQRWebhookDelay)
			targetURL := req.WebhookURL
			if targetURL == "" {
				targetURL = WebhookTargetURL
			}
			fireWebhookCallback(txnID, req.InvoiceID, req.TransactionToken, req.Amount, targetURL)
		}()

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(QRPaymentResponse{
			Success:  true,
			QRString: qrString,
			Received: req,
		})
	})

	// -------------------------------------------------------------------------
	// ROUTE 2: REDIRECT SESSION SETUP (Completely new signature)
	// -------------------------------------------------------------------------
	http.HandleFunc("/api/v1/bank/redirect-session", func(w http.ResponseWriter, r *http.Request) {
		logAction("REDIRECT FLOW", "Setting up unique checkout session")
		var req RedirectSessionRequest
		
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			logError("REDIRECT FLOW", fmt.Sprintf("Failed to decode JSON: %v", err))
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		if req.Amount <= 0 || req.InvoiceUUID == "" || req.TxnChannelToken == "" {
			logWarn("REDIRECT FLOW", "Validation Failed. Missing unique checkout params.")
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		sessionID := fmt.Sprintf("SESS_%d", time.Now().UnixNano())
		activeSessions[sessionID] = req 
		
		redirectURL := fmt.Sprintf("%s/bank/hosted-checkout?session_id=%s", hostedCheckoutBase, sessionID)
		logSuccess("REDIRECT FLOW", fmt.Sprintf("Created Session for Token %s -> Redirect: %s", req.TxnChannelToken, redirectURL))

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
		logAction("WEB VIEW", fmt.Sprintf("Serving Checkout Page for Session: %s", sessionID))
		
		sessionData, exists := activeSessions[sessionID]
		if !exists {
			logError("WEB VIEW", fmt.Sprintf("Session ID %s not found in memory!", sessionID))
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
			"Amount":           sessionData.Amount,
		})
	})

	// -------------------------------------------------------------------------
	// ROUTE 4: FORM SUBMISSION PROCESSOR
	// -------------------------------------------------------------------------
	http.HandleFunc("/bank/hosted-checkout/submit", func(w http.ResponseWriter, r *http.Request) {
		logAction("FORM SUBMIT", "Processing browser payment submission")
		r.ParseForm()
		sessionID := r.FormValue("session_id")
		
		sessionData, exists := activeSessions[sessionID]
		if !exists {
			logError("FORM SUBMIT", fmt.Sprintf("Submitted with expired Session ID: %s", sessionID))
			http.Error(w, "Session expired", http.StatusBadRequest)
			return
		}

		txnID := fmt.Sprintf("TXN_CARD_%d", time.Now().UnixNano())
		logSuccess("FORM SUBMIT", fmt.Sprintf("Processed Card. Rails Token: %s -> Bank Txn ID: %s", sessionData.TxnChannelToken, txnID))

		targetURL := sessionData.CallbackWebhook
		if targetURL == "" {
			targetURL = WebhookTargetURL
		}
		go fireWebhookCallback(txnID, sessionData.InvoiceUUID, sessionData.TxnChannelToken, sessionData.Amount, targetURL)
		
		delete(activeSessions, sessionID)
		logAction("DATABASE", fmt.Sprintf("Cleaned up session %s from active memory map.", sessionID))

		logAction("REDIRECT", fmt.Sprintf("Redirecting user back to App Success Page: %s", ClientSuccessURL))
		http.Redirect(w, r, ClientSuccessURL, http.StatusSeeOther)
	})

	fmt.Printf("🚀 Multipurpose Mock API Engine running smoothly on port %s (IP: %s)...\n", ServerPort, BaseIP)
	http.ListenAndServe(ServerPort, nil)
}

// =========================================================================
// BACKGROUND WORKERS & HELPERS
// =========================================================================

func fireWebhookCallback(txnID string, invoiceID string, transactionToken string, amount int, webhookURL string) {
	logAction("WEBHOOK", fmt.Sprintf("Preparing dispatch payload for Txn: %s", txnID))

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
	
	req, _ := http.NewRequest("POST", webhookURL, bytes.NewBuffer(payload))
	req.Header.Set("X-Skycom-Bank-Signature", WebhookSecureSecret)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: WebhookClientTimeout}
	
	logAction("WEBHOOK", fmt.Sprintf("POSTing event to %s...", webhookURL))
	resp, err := client.Do(req)
	if err != nil {
		logError("WEBHOOK", fmt.Sprintf("Failed to reach consumer app: %v\n", err))
		return
	}
	defer resp.Body.Close()

	logSuccess("WEBHOOK", fmt.Sprintf("Target application processed event. Response Status: %s\n", resp.Status))
}

// =========================================================================
// UNIFIED LOGGING UTILITIES
// =========================================================================

func logAction(context string, message string)  { fmt.Printf("📥 [%-14s] %s\n", context, message) }
func logSuccess(context string, message string) { fmt.Printf("🟢 [%-14s] SUCCESS: %s\n", context, message) }
func logWarn(context string, message string)    { fmt.Printf("⚠️  [%-14s] WARNING: %s\n", context, message) }
func logError(context string, message string)   { fmt.Printf("❌ [%-14s] ERROR: %s\n", context, message) }