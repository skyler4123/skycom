package com.example.skycomandroid

import dev.hotwire.core.turbo.errors.VisitError
import dev.hotwire.navigation.destinations.HotwireDestinationDeepLink
import dev.hotwire.navigation.fragments.HotwireWebFragment

/**
 * Reports the final WebView URL to the hosting activity. Read the WebView URL
 * instead of the visit location so Rails redirects (sign-in, auth expiry) are
 * observed after Turbo follows them.
 */
@HotwireDestinationDeepLink(uri = "hotwire://fragment/web")
class SkycomWebFragment : HotwireWebFragment() {
    override fun onColdBootPageCompleted(location: String) {
        super.onColdBootPageCompleted(location)
        notifyLocation(location)
    }

    override fun onVisitRendered(location: String) {
        super.onVisitRendered(location)
        notifyLocation(location)
    }

    override fun onVisitCompleted(location: String, completedOffline: Boolean) {
        super.onVisitCompleted(location, completedOffline)
        notifyLocation(location)
    }

    override fun onVisitErrorReceived(location: String, error: VisitError) {
        super.onVisitErrorReceived(location, error)
        (activity as? MobileWebListener)?.onMobileWebError(error)
    }

    private fun notifyLocation(fallback: String) {
        val url = navigator.session.webView.url ?: fallback
        (activity as? MobileWebListener)?.onMobileWebLocationChanged(url)
    }
}
