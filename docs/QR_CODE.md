# Skycom QR Code System

## 1. Overview

Skycom uses the `qrcode` npm package (importmap pinned) to generate QR code images entirely client-side. The `renderQrCode()` helper accepts a container element and payload text, then auto-sizes the QR image to fill the container.

## 2. The renderQrCode Helper

**File**: `app/javascript/controllers/helpers/ui_helpers.js:844`

### Signature

```javascript
renderQrCode(element, text)
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `element` | `HTMLElement` | Yes | — | Container element (e.g., a `<div>` with explicit width) |
| `text` | `string` | No | `"https://skycom.vn"` | The payload to encode in the QR code |

### Technical Details

| Property | Value |
|----------|-------|
| QR Type | 4 (33×33 module grid) |
| Error Correction | M (medium — ~15% recovery) |
| Sizing | `containerWidth / 37`, minimum 2px per module |
| Margin | 2 modules |
| Output | Injected `<img>` tag scaled to 100% container width |

## 3. Global Access

The helper is exposed globally via `application.js`:

```javascript
// Available anywhere
window.renderQrCode(element, text)

// Or imported directly
import { renderQrCode } from "controllers/helpers/ui_helpers"
```

The `qrcode` package is pinned in `config/importmap.rb`:

```ruby
pin "qrcode" # @5.39.0
```

## 4. Usage Example

```javascript
// In a Stimulus controller
import { Controller } from "@hotwired/stimulus"

export default class Companies_Invoices_ShowController extends Controller {
  static targets = ["qrContainer"]

  connect() {
    renderQrCode(this.qrContainerTarget, "https://skycom.vn/receipts/INV-1025")
  }
}
```

The container element needs an explicit width via Tailwind:

```html
<div data-target="invoices--show.qrContainer" class="w-48"></div>
```

## 5. Best Practices

1. **Container must have an explicit width** — the helper reads `element.clientWidth` to compute module size. Without `w-*` or `max-w-*`, the result may be unpredictable.
2. **Keep payloads reasonable** — Type 4 QR encodes ~100 alphanumeric or ~50 numeric characters. Larger payloads require bumping `typeNumber`.
3. **Use environment-appropriate payloads** — For bank transfers use raw VietQR strings; for receipts use short URLs.
4. **Container should be empty** — `renderQrCode` clears `innerHTML` before injecting the image.

---

*End of file*
