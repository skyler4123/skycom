package com.example.skycomandroid

import android.os.Bundle
import android.view.View
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import com.google.android.material.bottomnavigation.BottomNavigationView
import dev.hotwire.core.turbo.webview.WebViewInfo
import dev.hotwire.core.turbo.webview.WebViewVersionCompatibility
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration
import dev.hotwire.navigation.tabs.HotwireBottomNavigationController
import dev.hotwire.navigation.tabs.HotwireBottomTab
import dev.hotwire.navigation.tabs.navigatorConfigurations
import dev.hotwire.navigation.util.applyDefaultImeWindowInsets

class MainActivity : HotwireActivity() {
    private val viewModel: MainActivityViewModel by viewModels()
    private lateinit var bottomNavigationController: HotwireBottomNavigationController

    private val tabs: List<HotwireBottomTab> by lazy { createTabs() }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_main)
        findViewById<View>(R.id.root).applyDefaultImeWindowInsets()

        bottomNavigationController = HotwireBottomNavigationController(
            activity = this,
            view = findViewById<BottomNavigationView>(R.id.bottom_nav),
            lazyLoadTabs = true
        )
        bottomNavigationController.load(tabs, viewModel.selectedTabIndex)
        bottomNavigationController.setOnTabSelectedListener { index, _ ->
            viewModel.selectedTabIndex = index
        }

        WebViewVersionCompatibility.displayUpdateDialogIfOutdated(
            activity = this,
            requiredVersion = WebViewInfo.REQUIRED_WEBVIEW_VERSION
        )
    }

    override fun navigatorConfigurations() = tabs.navigatorConfigurations

    private fun createTabs() = listOf(
        hotwireTab(
            titleResId = R.string.tab_home,
            iconResId = R.drawable.ic_tab_home,
            name = "home",
            navigatorHostId = R.id.home_navigator_host,
            path = "/mobile/home"
        ),
        hotwireTab(
            titleResId = R.string.tab_employee,
            iconResId = R.drawable.ic_tab_employee,
            name = "employee",
            navigatorHostId = R.id.employee_navigator_host,
            path = "/mobile/employee"
        ),
        hotwireTab(
            titleResId = R.string.tab_attendance,
            iconResId = R.drawable.ic_tab_attendance,
            name = "attendance",
            navigatorHostId = R.id.attendance_navigator_host,
            path = "/mobile/attendance_month"
        ),
        hotwireTab(
            titleResId = R.string.tab_payroll,
            iconResId = R.drawable.ic_tab_payroll,
            name = "payroll",
            navigatorHostId = R.id.payroll_navigator_host,
            path = "/mobile/payroll"
        ),
        hotwireTab(
            titleResId = R.string.tab_requests,
            iconResId = R.drawable.ic_tab_requests,
            name = "requests",
            navigatorHostId = R.id.requests_navigator_host,
            path = "/mobile/attendance_requests/new"
        )
    )

    private fun hotwireTab(
        titleResId: Int,
        iconResId: Int,
        name: String,
        navigatorHostId: Int,
        path: String
    ) = HotwireBottomTab(
        title = getString(titleResId),
        iconResId = iconResId,
        configuration = NavigatorConfiguration(
            name = name,
            navigatorHostId = navigatorHostId,
            startLocation = "${BuildConfig.BASE_URL}$path"
        )
    )
}
