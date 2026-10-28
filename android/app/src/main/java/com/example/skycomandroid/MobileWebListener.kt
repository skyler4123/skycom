package com.example.skycomandroid

import dev.hotwire.core.turbo.errors.VisitError

/** Implemented by activities that host [SkycomWebFragment]. */
interface MobileWebListener {
    fun onMobileWebLocationChanged(url: String?)

    fun onMobileWebError(error: VisitError) {}
}
