package com.pmk.week_calendar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.PackageManager.ComponentEnabledSetting
import android.os.Build
import java.util.Calendar
import java.util.Locale

internal object LauncherIconManager {
    const val settingsName = "week_calendar_settings"

    private const val updateAction = "com.pmk.week_calendar.UPDATE_LAUNCHER_ICON"
    private const val pendingIconChangeKey = "pendingLauncherIconChange"
    private const val pendingIconNameKey = "pendingLauncherIconName"
    private const val alarmRequestCode = 5301

    private var isActivityResumed = false

    fun onActivityResumed() {
        isActivityResumed = true
    }

    fun onActivityStopped(context: Context) {
        isActivityResumed = false
        tryApplyPendingLauncherIcon(context)
    }

    fun requestLauncherIcon(context: Context, iconName: String?) {
        val preferences = context.getSharedPreferences(settingsName, Context.MODE_PRIVATE)
        preferences.edit()
            .putBoolean(pendingIconChangeKey, true)
            .apply {
                if (iconName == null) {
                    remove(pendingIconNameKey)
                } else {
                    putString(pendingIconNameKey, iconName)
                }
            }
            .apply()

        if (!isActivityResumed) {
            tryApplyPendingLauncherIcon(context)
        }
    }

    fun updateCurrentWeekIcon(context: Context) {
        val preferences = context.getSharedPreferences(settingsName, Context.MODE_PRIVATE)
        if (!preferences.getBoolean("showWeekNumberInIcon", false)) {
            cancelScheduledUpdate(context)
            return
        }

        requestLauncherIcon(context, "icon_${currentIsoWeekNumber()}")
        scheduleNextUpdate(context)
    }

    fun configureSchedule(context: Context) {
        val preferences = context.getSharedPreferences(settingsName, Context.MODE_PRIVATE)
        if (preferences.getBoolean("showWeekNumberInIcon", false)) {
            scheduleNextUpdate(context)
        } else {
            cancelScheduledUpdate(context)
        }
    }

    private fun applyPendingLauncherIcon(context: Context) {
        val preferences = context.getSharedPreferences(settingsName, Context.MODE_PRIVATE)
        if (!preferences.getBoolean(pendingIconChangeKey, false)) {
            return
        }

        val iconName = preferences.getString(pendingIconNameKey, null)
        val selectedComponent = launcherComponent(context, iconName)
        val debugLauncherComponent = debugLauncherComponentOrNull(context)
        val selectedComponents = mutableSetOf(selectedComponent)
        if (iconName == null && debugLauncherComponent != null) {
            selectedComponents.add(debugLauncherComponent)
        }

        val launcherComponents = mutableListOf(launcherComponent(context, null)).apply {
            addAll((1..53).map { launcherComponent(context, "icon_$it") })
            if (debugLauncherComponent != null) {
                add(debugLauncherComponent)
            }
        }.distinct()

        updateLauncherComponents(context, selectedComponents, launcherComponents)
        preferences.edit()
            .remove(pendingIconChangeKey)
            .remove(pendingIconNameKey)
            .apply()
    }

    private fun tryApplyPendingLauncherIcon(context: Context) {
        try {
            applyPendingLauncherIcon(context)
        } catch (_: IllegalArgumentException) {
            // Keep the pending request for a later retry on launcher-specific failures.
        } catch (_: SecurityException) {
            // Some managed devices forbid component changes.
        }
    }

    private fun updateLauncherComponents(
        context: Context,
        selectedComponents: Set<ComponentName>,
        launcherComponents: List<ComponentName>,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val flags = PackageManager.DONT_KILL_APP or PackageManager.SYNCHRONOUS
            context.packageManager.setComponentEnabledSettings(
                launcherComponents.map { component ->
                    ComponentEnabledSetting(
                        component,
                        if (selectedComponents.contains(component)) {
                            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                        } else {
                            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                        },
                        flags,
                    )
                },
            )
            return
        }

        launcherComponents.forEach { component ->
            context.packageManager.setComponentEnabledSetting(
                component,
                if (selectedComponents.contains(component)) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                },
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private fun scheduleNextUpdate(context: Context) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(
            AlarmManager.RTC_WAKEUP,
            nextIsoWeekStartMillis(),
            updatePendingIntent(context),
        )
    }

    private fun cancelScheduledUpdate(context: Context) {
        val alarmManager =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(updatePendingIntent(context))
    }

    private fun updatePendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, LauncherIconUpdateReceiver::class.java).apply {
            action = updateAction
        }
        return PendingIntent.getBroadcast(
            context,
            alarmRequestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun currentIsoWeekNumber(): Int {
        return isoCalendar().get(Calendar.WEEK_OF_YEAR).coerceIn(1, 53)
    }

    private fun nextIsoWeekStartMillis(): Long {
        return isoCalendar().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            val daysUntilMonday =
                (Calendar.MONDAY - get(Calendar.DAY_OF_WEEK) + 7) % 7
            add(Calendar.DAY_OF_YEAR, if (daysUntilMonday == 0) 7 else daysUntilMonday)
        }.timeInMillis
    }

    private fun isoCalendar(): Calendar {
        return Calendar.getInstance(Locale.ROOT).apply {
            firstDayOfWeek = Calendar.MONDAY
            minimalDaysInFirstWeek = 4
        }
    }

    private fun launcherComponent(context: Context, iconName: String?): ComponentName {
        val className = if (iconName == null) {
            "${context.packageName}.DEFAULT"
        } else {
            "${context.packageName}.$iconName"
        }
        return ComponentName(context.packageName, className)
    }

    private fun debugLauncherComponentOrNull(context: Context): ComponentName? {
        val component = ComponentName(
            context.packageName,
            "${context.packageName}.DebugLaunchActivity",
        )
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getActivityInfo(
                    component,
                    PackageManager.ComponentInfoFlags.of(
                        PackageManager.MATCH_DISABLED_COMPONENTS.toLong(),
                    ),
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getActivityInfo(
                    component,
                    PackageManager.MATCH_DISABLED_COMPONENTS,
                )
            }
            component
        } catch (_: PackageManager.NameNotFoundException) {
            null
        }
    }
}
