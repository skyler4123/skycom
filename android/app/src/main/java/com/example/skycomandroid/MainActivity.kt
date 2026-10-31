package com.example.skycomandroid

import android.content.Intent
import android.os.Bundle
import android.view.View
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import dev.hotwire.core.turbo.errors.HttpError
import dev.hotwire.core.turbo.errors.VisitError
import dev.hotwire.core.turbo.webview.WebViewInfo
import dev.hotwire.core.turbo.webview.WebViewVersionCompatibility
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.Navigator
import dev.hotwire.navigation.navigator.NavigatorConfiguration
import dev.hotwire.navigation.tabs.HotwireBottomNavigationController
import dev.hotwire.navigation.tabs.HotwireBottomTab
import dev.hotwire.navigation.util.applyDefaultImeWindowInsets

class MainActivity : HotwireActivity(), MobileWebListener {
    private val viewModel: MainActivityViewModel by viewModels()
    private lateinit var bottomNavigationController: HotwireBottomNavigationController
    private var companyId: String? = null
    private var transitioning = false

    override fun onCreate(savedInstanceState: Bundle?) {
        companyId = intent.getStringExtra(EXTRA_COMPANY_ID) ?: CompanyStore.read(this)

        if (companyId == null) {
            super.onCreate(savedInstanceState)
            startSignInActivity()
            return
        }

        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_main)
        findViewById<View>(R.id.root).applyDefaultImeWindowInsets()

        val id = companyId!!
        bottomNavigationController = HotwireBottomNavigationController(
            activity = this,
            view = findViewById(R.id.bottom_nav),
            lazyLoadTabs = true,
            initialVisibility = HotwireBottomNavigationController.Visibility.HIDDEN
        )
        // Hide immediately; the first company-scoped visit will reveal it.
        bottomNavigationController.view.visibility = View.GONE
        bottomNavigationController.load(buildTabs(id), viewModel.selectedTabIndex)
        bottomNavigationController.setOnTabSelectedListener { index, _ ->
            if (viewModel.selectedTabIndex == PROFILE_TAB_INDEX && index != PROFILE_TAB_INDEX) {
                clearProfileStack()
            }
            viewModel.selectedTabIndex = index
        }

        WebViewVersionCompatibility.displayUpdateDialogIfOutdated(
            activity = this,
            requiredVersion = WebViewInfo.REQUIRED_WEBVIEW_VERSION
        )
    }

    override fun navigatorConfigurations(): List<NavigatorConfiguration> {
        val id = companyId
            ?: return listOf(
                NavigatorConfiguration(
                    name = "sign_in",
                    startLocation = "${BuildConfig.BASE_URL}/mobile/sign_in",
                    navigatorHostId = R.id.home_navigator_host
                )
            )

        return buildTabs(id).map { it.configuration }
    }

    override fun onNavigatorReady(navigator: Navigator) {
        if (::bottomNavigationController.isInitialized) {
            updateTabsVisibility(navigator.session.webView.url)
        }
    }

    override fun onMobileWebLocationChanged(url: String?) {
        if (transitioning) return

        if (CompanyUrl.isSignIn(url) || CompanyUrl.isMobileHome(url)) {
            if (::bottomNavigationController.isInitialized) {
                bottomNavigationController.visibility =
                    HotwireBottomNavigationController.Visibility.HIDDEN
            }
            startSignInActivity()
            return
        }

        val id = CompanyUrl.companyId(url) ?: return

        if (id != companyId) {
            companyId = id
            CompanyStore.write(this, id)
            if (::bottomNavigationController.isInitialized) {
                bottomNavigationController.load(buildTabs(id), viewModel.selectedTabIndex)
                delegate.resetNavigators()
            }
        }

        if (::bottomNavigationController.isInitialized) {
            bottomNavigationController.visibility =
                HotwireBottomNavigationController.Visibility.DEFAULT
        }
    }

    override fun onMobileWebError(error: VisitError) {
        if (error is HttpError && error.statusCode == 404) {
            if (::bottomNavigationController.isInitialized) {
                bottomNavigationController.visibility =
                    HotwireBottomNavigationController.Visibility.HIDDEN
            }
            startSignInActivity()
        }
    }

    override fun onStop() {
        // Payroll lives inside the Profile tab. Do not leave it visible when
        // the app goes to the background or another employee picks up the device.
        if (::bottomNavigationController.isInitialized) {
            clearProfileStack()
        }
        super.onStop()
    }

    private fun updateTabsVisibility(url: String?) {
        if (url == null) return

        val visible = CompanyUrl.companyId(url) != null
        bottomNavigationController.visibility =
            if (visible) {
                HotwireBottomNavigationController.Visibility.DEFAULT
            } else {
                HotwireBottomNavigationController.Visibility.HIDDEN
            }
    }

    private fun startSignInActivity() {
        if (transitioning) return
        transitioning = true
        CompanyStore.clear(this)

        startActivity(
            Intent(this, SignInActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            )
        )
        finish()
    }

    private fun clearProfileStack() {
        delegate.findNavigatorHost(R.id.employee_navigator_host)?.navigator?.clearAll()
    }

    private fun buildTabs(companyId: String): List<HotwireBottomTab> {
        val root = "/mobile/companies/$companyId"
        return listOf(
            hotwireTab(
                titleResId = R.string.tab_home,
                iconResId = R.drawable.ic_tab_home,
                name = "home",
                navigatorHostId = R.id.home_navigator_host,
                path = "$root/home"
            ),
            hotwireTab(
                titleResId = R.string.tab_notifications,
                iconResId = R.drawable.ic_tab_notifications,
                name = "notifications",
                navigatorHostId = R.id.notifications_navigator_host,
                path = "$root/notifications"
            ),
            hotwireTab(
                titleResId = R.string.tab_profile,
                iconResId = R.drawable.ic_tab_employee,
                name = "employee",
                navigatorHostId = R.id.employee_navigator_host,
                path = "$root/employee"
            ),
            hotwireTab(
                titleResId = R.string.tab_attendance,
                iconResId = R.drawable.ic_tab_attendance,
                name = "attendance",
                navigatorHostId = R.id.attendance_navigator_host,
                path = "$root/attendance_month"
            ),
            hotwireTab(
                titleResId = R.string.tab_operations,
                iconResId = R.drawable.ic_tab_operations,
                name = "operations",
                navigatorHostId = R.id.operations_navigator_host,
                path = "$root/operations"
            )
        )
    }

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

    companion object {
        const val EXTRA_COMPANY_ID = "company_id"
        private const val PROFILE_TAB_INDEX = 2
    }
}
