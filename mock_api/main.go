// mock_api/main.go

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"net/http"
	"time"
)

type PaymentRequest struct {
	Amount    int    `json:"amount"`
	InvoiceID string `json:"invoice_id"`
	Memo      string `json:"memo"`
}

var activeSessions = make(map[string]PaymentRequest)

func main() {
	// =========================================================================
	// ROUTE GROUP 0: DEPLOYMENT & NETWORK DIAGNOSTIC TOOLS
	// =========================================================================
	
	// New Connection Diagnostic Test Endpoint
	http.HandleFunc("/api/v1/ping", func(w http.ResponseWriter, r *http.Request) {
		/* 💬 What the Browser says: "Are you alive over there?" */
		/* 💬 What the Go Server thinks: "Let's log this network check and say hi to Skyler." */
		fmt.Printf("📡 [Diagnostic Alert] Received active ping test from client IP: %s\n", r.RemoteAddr)
		
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"status":       "online",
			"message":      "🚀 Skycom Mock API Engine is humming smoothly!",
			"current_time": time.Now().Format(time.RFC3339),
			"environment":  "local_development",
		})
	})

	// =========================================================================
	// ROUTE GROUP 1: BANKING SUITE (QR & REDIRECT FLOWS)
	// =========================================================================
	
	// QR Flow
	http.HandleFunc("/api/v1/bank/qr-generate", func(w http.ResponseWriter, r *http.Request) {
		var req PaymentRequest
		json.NewDecoder(r.Body).Decode(&req)
		txnID := fmt.Sprintf("TXN_QR_%d", time.Now().UnixNano())
		qrString := fmt.Sprintf("00020101021238580010A0000...%d...%s", req.Amount, req.Memo)

		go fireWebhookCallback(txnID, req.InvoiceID, req.Amount)

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "qr_string": qrString})
	})

	// Redirect Session Setup
	http.HandleFunc("/api/v1/bank/redirect-session", func(w http.ResponseWriter, r *http.Request) {
		var req PaymentRequest
		json.NewDecoder(r.Body).Decode(&req)
		sessionID := fmt.Sprintf("SESS_%d", time.Now().UnixNano())
		activeSessions[sessionID] = req
		redirectURL := fmt.Sprintf("http://localhost:4000/bank/hosted-checkout?session_id=%s", sessionID)

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{"success": true, "redirect_url": redirectURL})
	})

	// Hosted Checkout Page View
	http.HandleFunc("/bank/hosted-checkout", func(w http.ResponseWriter, r *http.Request) {
		sessionID := r.URL.Query().Get("session_id")
		sessionData, exists := activeSessions[sessionID]
		if !exists {
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
					<input type="text" value="Invoice Reference: {{.InvoiceID}}" disabled>
					<input type="text" name="amount" value="{{.Amount}}">
					<button type="submit">🔒 CONFIRM & SUBMIT</button>
				</form>
			</div>
		</body>
		</html>`

		t, _ := template.New("webpage").Parse(tmpl)
		t.Execute(w, map[string]interface{}{"SessionID": sessionID, "InvoiceID": sessionData.InvoiceID, "Amount": sessionData.Amount})
	})

	// Hosted Checkout Processing Submission
	http.HandleFunc("/bank/hosted-checkout/submit", func(w http.ResponseWriter, r *http.Request) {
		r.ParseForm()
		sessionID := r.FormValue("session_id")
		sessionData := activeSessions[sessionID]
		txnID := fmt.Sprintf("TXN_CARD_%d", time.Now().UnixNano())

		fireWebhookCallback(txnID, sessionData.InvoiceID, sessionData.Amount)
		delete(activeSessions, sessionID)

		http.Redirect(w, r, "http://localhost:3000/checkout/success", http.StatusSeeOther)
	})

	// Future extension hook spot examples:
	// http.HandleFunc("/api/v1/sms/send", func(...) {})
	// http.HandleFunc("/api/v1/shipping/calculate", func(...) {})

	fmt.Println("🚀 Multipurpose Mock API Engine running smoothly on port 4000...")
	http.ListenAndServe(":4000", nil)
}

func fireWebhookCallback(txnID string, invoiceID string, amount int) {
	webhookURL := "http://skycom-web:3000/webhooks/bank_payment"
	payload, _ := json.Marshal(map[string]interface{}{
		"event": "transaction.completed",
		"data":  map[string]interface{}{"transaction_id": txnID, "invoice_id": invoiceID, "amount": amount, "paid_at": time.Now().Format(time.RFC3339)},
	})
	req, _ := http.NewRequest("POST", webhookURL, bytes.NewBuffer(payload))
	req.Header.Set("X-Skycom-Bank-Signature", "local_secure_dev_secret")
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err == nil {
		defer resp.Body.Close()
	}
}