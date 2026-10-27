package com.example.skycomandroid

import android.content.Context

/**
 * Persists the company the signed-in employee belongs to. This is only a
 * routing hint: every server request is still authorized against the session.
 */
object CompanyStore {
    private const val PREFS = "skycom_mobile"
    private const val KEY_COMPANY_ID = "company_id"

    fun read(context: Context): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_COMPANY_ID, null)

    fun write(context: Context, companyId: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_COMPANY_ID, companyId)
            .apply()
    }

    fun clear(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_COMPANY_ID)
            .apply()
    }
}
