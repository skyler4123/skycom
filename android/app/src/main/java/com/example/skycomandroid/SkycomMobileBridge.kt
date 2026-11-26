package com.example.skycomandroid

import android.webkit.JavascriptInterface
import android.webkit.WebView
import java.lang.ref.WeakReference
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Minimal JS bridge for the authenticated mobile shell.
 *
 * Android keeps one WebView per bottom tab. The browser language switch only
 * reloads the current WebView, so the other tabs keep their old rendered
 * language. JS calls [reloadTabs] after saving `localStorage.languageCode`;
 * [MainActivity] then refreshes every loaded tab's current destination.
 *
 * The origin check keeps the bridge inactive on external pages; SignInActivity
 * does not install it at all.
 */
class SkycomMobileBridge(activity: MainActivity, webView: WebView) {
    private val activityRef = WeakReference(activity)
    private val webViewRef = WeakReference(webView)

    @JavascriptInterface
    fun reloadTabs(): Boolean {
        val activity = activityRef.get() ?: return false
        val webView = webViewRef.get() ?: return false
        val latch = CountDownLatch(1)
        var handled = false

        // @JavascriptInterface runs on a WebView worker thread; URL reads and
        // navigation refreshes belong on the UI thread.
        activity.runOnUiThread {
            val url = webView.url
            if (url != null && CompanyUrl.isAppOrigin(url, BuildConfig.BASE_URL)) {
                activity.reloadTabsForLanguageChange()
                handled = true
            }
            latch.countDown()
        }

        latch.await(2, TimeUnit.SECONDS)
        return handled
    }
}
