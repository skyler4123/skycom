package com.example.skycomandroid

import android.app.Application
import dev.hotwire.core.config.Hotwire
import dev.hotwire.core.logging.HotwireLogLevel
import dev.hotwire.core.turbo.config.PathConfiguration
import dev.hotwire.navigation.config.defaultFragmentDestination
import dev.hotwire.navigation.config.registerFragmentDestinations
import dev.hotwire.navigation.fragments.HotwireWebBottomSheetFragment

class SkycomApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        Hotwire.config.webViewDebuggingEnabled = BuildConfig.DEBUG
        Hotwire.config.logger.logLevel = if (BuildConfig.DEBUG) {
            HotwireLogLevel.DEBUG
        } else {
            HotwireLogLevel.NONE
        }

        // The custom fragment reports final WebView URLs so the activities can
        // keep tabs off the sign-in screen and return to sign-in when auth ends.
        Hotwire.defaultFragmentDestination = SkycomWebFragment::class
        Hotwire.registerFragmentDestinations(
            SkycomWebFragment::class,
            HotwireWebBottomSheetFragment::class
        )

        Hotwire.loadPathConfiguration(
            context = this,
            location = PathConfiguration.Location(
                assetFilePath = "json/path-configuration.json",
                remoteFileUrl = "${BuildConfig.BASE_URL}/configurations/android_v1.json"
            )
        )
    }
}
