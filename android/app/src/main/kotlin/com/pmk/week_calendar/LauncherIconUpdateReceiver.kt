package com.pmk.week_calendar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class LauncherIconUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        LauncherIconManager.updateCurrentWeekIcon(context)
    }
}
