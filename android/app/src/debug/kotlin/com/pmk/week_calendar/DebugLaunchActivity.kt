package com.pmk.week_calendar

import android.app.Activity
import android.content.Intent
import android.os.Bundle

class DebugLaunchActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            action = intent.action
            intent.categories?.forEach { addCategory(it) }
            flags = intent.flags
            intent.extras?.let { putExtras(it) }
        }

        startActivity(launchIntent)
        overridePendingTransition(0, 0)
        finish()
    }
}
