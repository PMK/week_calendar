package com.pmk.week_calendar

import android.Manifest
import android.content.ContentUris
import android.content.ContentValues
import android.content.ComponentName
import android.content.pm.PackageManager
import android.content.pm.PackageManager.ComponentEnabledSetting
import android.os.Build
import android.provider.CalendarContract
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val channelName = "week_calendar/calendar"
    private val settingsName = "week_calendar_settings"
    private val calendarPermissionRequestCode = 4021
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDavx5Installed" -> result.success(isDavx5Installed())
                "hasCalendarPermission" -> result.success(hasCalendarPermission())
                "requestCalendarPermission" -> requestCalendarPermission(result)
                "getCalendars" -> getCalendars(result)
                "getAppSettings" -> result.success(getAppSettings())
                "saveAppSettings" -> {
                    saveAppSettings(call.arguments as? Map<*, *>, result)
                }
                "setLauncherIcon" -> {
                    setLauncherIcon(call.arguments as? Map<*, *>, result)
                }
                "getCalendarEvents" -> {
                    val startMillis = call.argument<Long>("startMillis")
                    val endMillis = call.argument<Long>("endMillis")

                    if (startMillis == null || endMillis == null) {
                        result.error(
                            "INVALID_ARGUMENT",
                            "startMillis and endMillis are required.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    getCalendarEvents(startMillis, endMillis, result)
                }
                "createCalendarEvent" -> {
                    createCalendarEvent(call.arguments as? Map<*, *>, result)
                }
                "updateCalendarEvent" -> {
                    updateCalendarEvent(call.arguments as? Map<*, *>, result)
                }
                "deleteCalendarEvent" -> {
                    deleteCalendarEvent(call.arguments as? Map<*, *>, result)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun getAppSettings(): Map<String, Any?> {
        val preferences = getSharedPreferences(settingsName, MODE_PRIVATE)
        val hasEnabledCalendarIds = preferences.contains("enabledCalendarIds")

        return mapOf(
            "weekStartDay" to preferences.getString("weekStartDay", null),
            "themePreference" to preferences.getString("themePreference", null),
            "showEndTimeDisplay" to preferences.getBoolean("showEndTimeDisplay", false),
            "showWeekNumberInIcon" to preferences.getBoolean("showWeekNumberInIcon", false),
            "defaultAlertOption" to preferences.getString("defaultAlertOption", null),
            "hasEnabledCalendarIds" to hasEnabledCalendarIds,
            "enabledCalendarIds" to preferences.getStringSet("enabledCalendarIds", emptySet())!!.toList(),
        )
    }

    private fun saveAppSettings(arguments: Map<*, *>?, result: MethodChannel.Result) {
        if (arguments == null) {
            result.error("INVALID_ARGUMENT", "Settings payload is required.", null)
            return
        }

        val enabledCalendarIds = (arguments["enabledCalendarIds"] as? List<*>)
            ?.mapNotNull { it?.toString() }
            ?.toSet()
            ?: emptySet()

        getSharedPreferences(settingsName, MODE_PRIVATE)
            .edit()
            .putString("weekStartDay", arguments["weekStartDay"]?.toString())
            .putString("themePreference", arguments["themePreference"]?.toString())
            .putBoolean("showEndTimeDisplay", arguments["showEndTimeDisplay"] == true)
            .putBoolean("showWeekNumberInIcon", arguments["showWeekNumberInIcon"] == true)
            .putString("defaultAlertOption", arguments["defaultAlertOption"]?.toString())
            .putStringSet("enabledCalendarIds", enabledCalendarIds)
            .apply()

        result.success(true)
    }

    private fun setLauncherIcon(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val iconName = arguments?.get("iconName")?.toString()?.takeIf { it.isNotBlank() }
        if (iconName != null && !Regex("""icon_([1-9]|[1-4][0-9]|5[0-3])""").matches(iconName)) {
            result.error("INVALID_ARGUMENT", "Unsupported launcher icon: $iconName.", null)
            return
        }

        val selectedComponent = launcherComponent(iconName)
        val debugLauncherComponent = debugLauncherComponentOrNull()
        val selectedComponents = mutableSetOf(selectedComponent)
        if (iconName == null && debugLauncherComponent != null) {
            selectedComponents.add(debugLauncherComponent)
        }

        val launcherComponents = mutableListOf(launcherComponent(null)).apply {
            addAll((1..53).map { launcherComponent("icon_$it") })
            if (debugLauncherComponent != null) {
                add(debugLauncherComponent)
            }
        }.distinct()

        try {
            updateLauncherComponents(selectedComponents, launcherComponents)

            result.success(true)
        } catch (error: IllegalArgumentException) {
            result.error("ICON_CHANGE_FAILED", error.message, null)
        }
    }

    private fun updateLauncherComponents(
        selectedComponents: Set<ComponentName>,
        launcherComponents: List<ComponentName>,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val flags = PackageManager.DONT_KILL_APP or PackageManager.SYNCHRONOUS
            packageManager.setComponentEnabledSettings(
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
            packageManager.setComponentEnabledSetting(
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

    private fun launcherComponent(iconName: String?): ComponentName {
        val className = if (iconName == null) {
            "$packageName.DEFAULT"
        } else {
            "$packageName.$iconName"
        }
        return ComponentName(packageName, className)
    }

    private fun debugLauncherComponentOrNull(): ComponentName? {
        val component = ComponentName(packageName, "$packageName.DebugLaunchActivity")
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getActivityInfo(
                    component,
                    PackageManager.ComponentInfoFlags.of(
                        PackageManager.MATCH_DISABLED_COMPONENTS.toLong(),
                    ),
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getActivityInfo(
                    component,
                    PackageManager.MATCH_DISABLED_COMPONENTS,
                )
            }
            component
        } catch (_: PackageManager.NameNotFoundException) {
            null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != calendarPermissionRequestCode) {
            return
        }

        pendingPermissionResult?.success(
            grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED },
        )
        pendingPermissionResult = null
    }

    private fun isDavx5Installed(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(
                    "at.bitfire.davdroid",
                    PackageManager.PackageInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo("at.bitfire.davdroid", 0)
            }
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun hasCalendarPermission(): Boolean {
        return if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            true
        } else {
            checkSelfPermission(Manifest.permission.READ_CALENDAR) ==
                PackageManager.PERMISSION_GRANTED &&
                checkSelfPermission(Manifest.permission.WRITE_CALENDAR) ==
                PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestCalendarPermission(result: MethodChannel.Result) {
        if (hasCalendarPermission()) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("PERMISSION_PENDING", "A calendar permission request is already pending.", null)
            return
        }

        pendingPermissionResult = result
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            requestPermissions(
                arrayOf(
                    Manifest.permission.READ_CALENDAR,
                    Manifest.permission.WRITE_CALENDAR,
                ),
                calendarPermissionRequestCode,
            )
        } else {
            pendingPermissionResult = null
            result.success(true)
        }
    }

    private fun getCalendars(result: MethodChannel.Result) {
        if (!hasCalendarPermission()) {
            result.error("PERMISSION_DENIED", "Calendar permission is required.", null)
            return
        }

        thread(name = "calendar-list-query") {
            val calendars = mutableListOf<Map<String, Any?>>()
            val projection = arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.ACCOUNT_NAME,
                CalendarContract.Calendars.ACCOUNT_TYPE,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                CalendarContract.Calendars.CALENDAR_COLOR,
                CalendarContract.Calendars.VISIBLE,
            )

            try {
                contentResolver.query(
                    CalendarContract.Calendars.CONTENT_URI,
                    projection,
                    null,
                    null,
                    "${CalendarContract.Calendars.ACCOUNT_NAME} ASC, ${CalendarContract.Calendars.ACCOUNT_TYPE} ASC, ${CalendarContract.Calendars.CALENDAR_DISPLAY_NAME} ASC",
                )?.use { cursor ->
                    val idIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars._ID)
                    val accountNameIndex = cursor.getColumnIndexOrThrow(
                        CalendarContract.Calendars.ACCOUNT_NAME,
                    )
                    val accountTypeIndex = cursor.getColumnIndexOrThrow(
                        CalendarContract.Calendars.ACCOUNT_TYPE,
                    )
                    val nameIndex = cursor.getColumnIndexOrThrow(
                        CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                    )
                    val colorIndex = cursor.getColumnIndexOrThrow(
                        CalendarContract.Calendars.CALENDAR_COLOR,
                    )
                    val visibleIndex = cursor.getColumnIndexOrThrow(CalendarContract.Calendars.VISIBLE)

                    while (cursor.moveToNext()) {
                        val accountType = cursor.getString(accountTypeIndex).orEmpty()
                        val color = cursor.getInt(colorIndex).toLong() and 0xffffffffL

                        calendars.add(
                            mapOf(
                                "id" to cursor.getLong(idIndex).toString(),
                                "accountName" to cursor.getString(accountNameIndex).orEmpty(),
                                "accountType" to accountType,
                                "name" to cursor.getString(nameIndex).orEmpty(),
                                "color" to color,
                                "enabled" to (cursor.getInt(visibleIndex) != 0),
                            ),
                        )
                    }
                }

                runOnUiThread { result.success(calendars) }
            } catch (error: SecurityException) {
                runOnUiThread {
                    result.error("PERMISSION_DENIED", "Calendar permission is required.", null)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("CALENDAR_QUERY_FAILED", error.message, null)
                }
            }
        }
    }

    private fun getCalendarEvents(
        startMillis: Long,
        endMillis: Long,
        result: MethodChannel.Result,
    ) {
        if (!hasCalendarPermission()) {
            result.error("PERMISSION_DENIED", "Calendar permission is required.", null)
            return
        }

        thread(name = "calendar-provider-query") {
            val events = mutableListOf<Map<String, Any?>>()
            val projection = arrayOf(
                CalendarContract.Instances.EVENT_ID,
                CalendarContract.Instances.CALENDAR_ID,
                CalendarContract.Instances.BEGIN,
                CalendarContract.Instances.END,
                CalendarContract.Events.TITLE,
                CalendarContract.Events.ALL_DAY,
                CalendarContract.Events.DISPLAY_COLOR,
                CalendarContract.Events.EVENT_LOCATION,
                CalendarContract.Events.DESCRIPTION,
                CalendarContract.Events.RRULE,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            )

            try {
                CalendarContract.Instances.query(
                    contentResolver,
                    projection,
                    startMillis,
                    endMillis,
                )?.use { cursor ->
                    val eventIdIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID)
                    val calendarIdIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.CALENDAR_ID)
                    val beginIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN)
                    val endIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.END)
                    val titleIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.TITLE)
                    val allDayIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.ALL_DAY)
                    val colorIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.DISPLAY_COLOR)
                    val locationIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.EVENT_LOCATION)
                    val notesIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.DESCRIPTION)
                    val rruleIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.RRULE)
                    val calendarNameIndex = cursor.getColumnIndexOrThrow(
                        CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                    )

                    while (cursor.moveToNext()) {
                        val eventId = cursor.getLong(eventIdIndex)
                        val begin = cursor.getLong(beginIndex)
                        val end = cursor.getLong(endIndex)
                        val allDay = cursor.getInt(allDayIndex) == 1
                        val color = cursor.getInt(colorIndex).toLong() and 0xffffffffL
                        val reminders = getReminderMinutes(eventId)
                        val startCalendar = Calendar.getInstance(
                            if (allDay) TimeZone.getTimeZone("UTC") else TimeZone.getDefault(),
                        )
                        startCalendar.timeInMillis = begin
                        val endCalendar = Calendar.getInstance(
                            if (allDay) TimeZone.getTimeZone("UTC") else TimeZone.getDefault(),
                        )
                        endCalendar.timeInMillis = end

                        events.add(
                            mapOf(
                                "id" to eventId.toString(),
                                "calendarId" to cursor.getLong(calendarIdIndex).toString(),
                                "startMillis" to begin,
                                "endMillis" to end,
                                "startYear" to startCalendar.get(Calendar.YEAR),
                                "startMonth" to startCalendar.get(Calendar.MONTH) + 1,
                                "startDay" to startCalendar.get(Calendar.DAY_OF_MONTH),
                                "startHour" to startCalendar.get(Calendar.HOUR_OF_DAY),
                                "startMinute" to startCalendar.get(Calendar.MINUTE),
                                "endYear" to endCalendar.get(Calendar.YEAR),
                                "endMonth" to endCalendar.get(Calendar.MONTH) + 1,
                                "endDay" to endCalendar.get(Calendar.DAY_OF_MONTH),
                                "endHour" to endCalendar.get(Calendar.HOUR_OF_DAY),
                                "endMinute" to endCalendar.get(Calendar.MINUTE),
                                "title" to cursor.getString(titleIndex).orEmpty(),
                                "allDay" to allDay,
                                "color" to color,
                                "location" to cursor.getString(locationIndex).orEmpty(),
                                "notes" to cursor.getString(notesIndex).orEmpty(),
                                "rrule" to cursor.getString(rruleIndex).orEmpty(),
                                "alertMinutes" to reminders.getOrNull(0),
                                "secondAlertMinutes" to reminders.getOrNull(1),
                                "calendarName" to cursor.getString(calendarNameIndex).orEmpty(),
                            ),
                        )
                    }
                }

                runOnUiThread { result.success(events) }
            } catch (error: SecurityException) {
                runOnUiThread {
                    result.error("PERMISSION_DENIED", "Calendar permission is required.", null)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("CALENDAR_QUERY_FAILED", error.message, null)
                }
            }
        }
    }

    private fun createCalendarEvent(arguments: Map<*, *>?, result: MethodChannel.Result) {
        if (!hasCalendarPermission()) {
            result.error("PERMISSION_DENIED", "Calendar write permission is required.", null)
            return
        }

        if (arguments == null) {
            result.error("INVALID_ARGUMENT", "Event payload is required.", null)
            return
        }

        val calendarId = arguments["calendarId"]?.toString()?.toLongOrNull()
        val title = arguments["title"]?.toString()?.trim()
        val startMillis = longArgument(arguments["startMillis"])
        val endMillis = longArgument(arguments["endMillis"])

        if (calendarId == null || title.isNullOrEmpty() || startMillis == null || endMillis == null) {
            result.error(
                "INVALID_ARGUMENT",
                "calendarId, title, startMillis and endMillis are required.",
                null,
            )
            return
        }

        val allDay = arguments["allDay"] == true
        val location = arguments["location"]?.toString()?.trim().orEmpty()
        val notes = arguments["notes"]?.toString()?.trim().orEmpty()
        val rrule = arguments["rrule"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        val alertMinutes = intArgument(arguments["alertMinutes"])
        val secondAlertMinutes = intArgument(arguments["secondAlertMinutes"])

        thread(name = "calendar-event-insert") {
            try {
                val startEnd = if (allDay) {
                    allDayUtcBounds(startMillis, endMillis)
                } else {
                    Pair(startMillis, endMillis)
                }
                val timezoneId = if (allDay) {
                    TimeZone.getTimeZone("UTC").id
                } else {
                    TimeZone.getDefault().id
                }
                val durationMillis = (startEnd.second - startEnd.first).coerceAtLeast(60_000L)
                val eventValues = ContentValues().apply {
                    put(CalendarContract.Events.CALENDAR_ID, calendarId)
                    put(CalendarContract.Events.TITLE, title)
                    put(CalendarContract.Events.DTSTART, startEnd.first)
                    put(CalendarContract.Events.EVENT_TIMEZONE, timezoneId)
                    put(CalendarContract.Events.EVENT_END_TIMEZONE, timezoneId)
                    put(CalendarContract.Events.ALL_DAY, if (allDay) 1 else 0)

                    if (location.isNotEmpty()) {
                        put(CalendarContract.Events.EVENT_LOCATION, location)
                    }
                    if (notes.isNotEmpty()) {
                        put(CalendarContract.Events.DESCRIPTION, notes)
                    }

                    if (rrule == null) {
                        put(CalendarContract.Events.DTEND, startEnd.second)
                    } else {
                        put(CalendarContract.Events.RRULE, rrule)
                        put(CalendarContract.Events.DURATION, durationForMillis(durationMillis, allDay))
                    }
                }

                val eventUri = contentResolver.insert(
                    CalendarContract.Events.CONTENT_URI,
                    eventValues,
                ) ?: throw IllegalStateException("Calendar provider did not return an event URI.")

                val eventId = ContentUris.parseId(eventUri)
                val reminders = listOfNotNull(alertMinutes, secondAlertMinutes).distinct()
                for (minutes in reminders) {
                    contentResolver.insert(
                        CalendarContract.Reminders.CONTENT_URI,
                        ContentValues().apply {
                            put(CalendarContract.Reminders.EVENT_ID, eventId)
                            put(CalendarContract.Reminders.MINUTES, minutes)
                            put(
                                CalendarContract.Reminders.METHOD,
                                CalendarContract.Reminders.METHOD_ALERT,
                            )
                        },
                    )
                }

                runOnUiThread { result.success(eventId.toString()) }
            } catch (error: SecurityException) {
                runOnUiThread {
                    result.error("PERMISSION_DENIED", "Calendar write permission is required.", null)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("CALENDAR_INSERT_FAILED", error.message, null)
                }
            }
        }
    }

    private fun updateCalendarEvent(arguments: Map<*, *>?, result: MethodChannel.Result) {
        if (!hasCalendarPermission()) {
            result.error("PERMISSION_DENIED", "Calendar write permission is required.", null)
            return
        }

        if (arguments == null) {
            result.error("INVALID_ARGUMENT", "Event payload is required.", null)
            return
        }

        val eventId = arguments["eventId"]?.toString()?.toLongOrNull()
        val calendarId = arguments["calendarId"]?.toString()?.toLongOrNull()
        val title = arguments["title"]?.toString()?.trim()
        val startMillis = longArgument(arguments["startMillis"])
        val endMillis = longArgument(arguments["endMillis"])

        if (eventId == null || calendarId == null || title.isNullOrEmpty() || startMillis == null || endMillis == null) {
            result.error(
                "INVALID_ARGUMENT",
                "eventId, calendarId, title, startMillis and endMillis are required.",
                null,
            )
            return
        }

        val allDay = arguments["allDay"] == true
        val location = arguments["location"]?.toString()?.trim().orEmpty()
        val notes = arguments["notes"]?.toString()?.trim().orEmpty()
        val rrule = arguments["rrule"]?.toString()?.trim()?.takeIf { it.isNotEmpty() }
        val alertMinutes = intArgument(arguments["alertMinutes"])
        val secondAlertMinutes = intArgument(arguments["secondAlertMinutes"])

        thread(name = "calendar-event-update") {
            try {
                val eventUri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId)
                val startEnd = if (allDay) {
                    allDayUtcBounds(startMillis, endMillis)
                } else {
                    Pair(startMillis, endMillis)
                }
                val timezoneId = if (allDay) {
                    TimeZone.getTimeZone("UTC").id
                } else {
                    TimeZone.getDefault().id
                }
                val durationMillis = (startEnd.second - startEnd.first).coerceAtLeast(60_000L)
                val eventValues = ContentValues().apply {
                    put(CalendarContract.Events.CALENDAR_ID, calendarId)
                    put(CalendarContract.Events.TITLE, title)
                    put(CalendarContract.Events.DTSTART, startEnd.first)
                    put(CalendarContract.Events.EVENT_TIMEZONE, timezoneId)
                    put(CalendarContract.Events.EVENT_END_TIMEZONE, timezoneId)
                    put(CalendarContract.Events.ALL_DAY, if (allDay) 1 else 0)
                    put(CalendarContract.Events.EVENT_LOCATION, location)
                    put(CalendarContract.Events.DESCRIPTION, notes)

                    if (rrule == null) {
                        put(CalendarContract.Events.DTEND, startEnd.second)
                        putNull(CalendarContract.Events.RRULE)
                        putNull(CalendarContract.Events.DURATION)
                    } else {
                        putNull(CalendarContract.Events.DTEND)
                        put(CalendarContract.Events.RRULE, rrule)
                        put(CalendarContract.Events.DURATION, durationForMillis(durationMillis, allDay))
                    }
                }

                val updated = contentResolver.update(eventUri, eventValues, null, null)
                if (updated <= 0) {
                    throw IllegalStateException("Calendar provider did not update the event.")
                }

                contentResolver.delete(
                    CalendarContract.Reminders.CONTENT_URI,
                    "${CalendarContract.Reminders.EVENT_ID} = ?",
                    arrayOf(eventId.toString()),
                )

                val reminders = listOfNotNull(alertMinutes, secondAlertMinutes).distinct()
                for (minutes in reminders) {
                    contentResolver.insert(
                        CalendarContract.Reminders.CONTENT_URI,
                        ContentValues().apply {
                            put(CalendarContract.Reminders.EVENT_ID, eventId)
                            put(CalendarContract.Reminders.MINUTES, minutes)
                            put(
                                CalendarContract.Reminders.METHOD,
                                CalendarContract.Reminders.METHOD_ALERT,
                            )
                        },
                    )
                }

                runOnUiThread { result.success(true) }
            } catch (error: SecurityException) {
                runOnUiThread {
                    result.error("PERMISSION_DENIED", "Calendar write permission is required.", null)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("CALENDAR_UPDATE_FAILED", error.message, null)
                }
            }
        }
    }

    private fun deleteCalendarEvent(arguments: Map<*, *>?, result: MethodChannel.Result) {
        if (!hasCalendarPermission()) {
            result.error("PERMISSION_DENIED", "Calendar write permission is required.", null)
            return
        }

        if (arguments == null) {
            result.error("INVALID_ARGUMENT", "Event payload is required.", null)
            return
        }

        val eventId = arguments["eventId"]?.toString()?.toLongOrNull()
        val calendarId = arguments["calendarId"]?.toString()?.toLongOrNull()
        val startMillis = longArgument(arguments["startMillis"])
        val endMillis = longArgument(arguments["endMillis"])
        val allDay = arguments["allDay"] == true
        val deleteScope = arguments["deleteScope"]?.toString().orEmpty()

        if (eventId == null) {
            result.error("INVALID_ARGUMENT", "eventId is required.", null)
            return
        }

        thread(name = "calendar-event-delete") {
            try {
                val eventUri = ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId)
                val eventInfo = getEventDeleteInfo(eventId)

                when (deleteScope) {
                    "thisOnly" -> {
                        if (calendarId == null || startMillis == null || endMillis == null || eventInfo?.rrule.isNullOrEmpty()) {
                            deleteEventUri(eventUri)
                        } else {
                            insertCanceledException(
                                calendarId = calendarId,
                                eventId = eventId,
                                startMillis = startMillis,
                                endMillis = endMillis,
                                allDay = allDay,
                                timezoneId = eventInfo?.timezoneId ?: TimeZone.getDefault().id,
                            )
                        }
                    }
                    "future" -> {
                        if (eventInfo?.rrule.isNullOrEmpty() || startMillis == null) {
                            deleteEventUri(eventUri)
                        } else if (startMillis <= eventInfo!!.startMillis) {
                            deleteEventUri(eventUri)
                        } else {
                            val updatedRrule = rruleEndingBefore(eventInfo.rrule, startMillis, allDay)
                            val updated = contentResolver.update(
                                eventUri,
                                ContentValues().apply {
                                    put(CalendarContract.Events.RRULE, updatedRrule)
                                },
                                null,
                                null,
                            )
                            if (updated <= 0) {
                                throw IllegalStateException("Calendar provider did not update the event.")
                            }
                        }
                    }
                    else -> deleteEventUri(eventUri)
                }

                runOnUiThread { result.success(true) }
            } catch (error: SecurityException) {
                runOnUiThread {
                    result.error("PERMISSION_DENIED", "Calendar write permission is required.", null)
                }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error("CALENDAR_DELETE_FAILED", error.message, null)
                }
            }
        }
    }

    private data class EventDeleteInfo(
        val startMillis: Long,
        val timezoneId: String,
        val rrule: String?,
    )

    private fun getEventDeleteInfo(eventId: Long): EventDeleteInfo? {
        contentResolver.query(
            ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, eventId),
            arrayOf(
                CalendarContract.Events.DTSTART,
                CalendarContract.Events.EVENT_TIMEZONE,
                CalendarContract.Events.RRULE,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) {
                return null
            }

            val startIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.DTSTART)
            val timezoneIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.EVENT_TIMEZONE)
            val rruleIndex = cursor.getColumnIndexOrThrow(CalendarContract.Events.RRULE)

            return EventDeleteInfo(
                startMillis = cursor.getLong(startIndex),
                timezoneId = cursor.getString(timezoneIndex) ?: TimeZone.getDefault().id,
                rrule = cursor.getString(rruleIndex)?.trim()?.takeIf { it.isNotEmpty() },
            )
        }

        return null
    }

    private fun deleteEventUri(eventUri: android.net.Uri) {
        val deleted = contentResolver.delete(eventUri, null, null)
        if (deleted <= 0) {
            throw IllegalStateException("Calendar provider did not delete the event.")
        }
    }

    private fun insertCanceledException(
        calendarId: Long,
        eventId: Long,
        startMillis: Long,
        endMillis: Long,
        allDay: Boolean,
        timezoneId: String,
    ) {
        val timezone = if (allDay) TimeZone.getTimeZone("UTC").id else timezoneId
        val exceptionValues = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId)
            put(CalendarContract.Events.ORIGINAL_ID, eventId)
            put(CalendarContract.Events.ORIGINAL_INSTANCE_TIME, startMillis)
            put(CalendarContract.Events.DTSTART, startMillis)
            put(CalendarContract.Events.DTEND, endMillis)
            put(CalendarContract.Events.EVENT_TIMEZONE, timezone)
            put(CalendarContract.Events.EVENT_END_TIMEZONE, timezone)
            put(CalendarContract.Events.ALL_DAY, if (allDay) 1 else 0)
            put(CalendarContract.Events.STATUS, CalendarContract.Events.STATUS_CANCELED)
            put(CalendarContract.Events.TITLE, "")
        }

        contentResolver.insert(
            CalendarContract.Events.CONTENT_EXCEPTION_URI,
            exceptionValues,
        ) ?: throw IllegalStateException("Calendar provider did not create the recurring-event exception.")
    }

    private fun rruleEndingBefore(rrule: String, startMillis: Long, allDay: Boolean): String {
        val boundaryMillis = if (allDay) {
            startMillis - 86_400_000L
        } else {
            startMillis - 1_000L
        }
        val until = if (allDay) {
            SimpleDateFormat("yyyyMMdd", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }.format(Date(boundaryMillis))
        } else {
            SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US).apply {
                timeZone = TimeZone.getTimeZone("UTC")
            }.format(Date(boundaryMillis))
        }
        val filteredParts = rrule
            .split(";")
            .filterNot {
                val key = it.substringBefore("=").uppercase(Locale.US)
                key == "UNTIL" || key == "COUNT"
            }

        return (filteredParts + "UNTIL=$until").joinToString(";")
    }

    private fun getReminderMinutes(eventId: Long): List<Int> {
        val reminders = mutableListOf<Int>()
        contentResolver.query(
            CalendarContract.Reminders.CONTENT_URI,
            arrayOf(CalendarContract.Reminders.MINUTES),
            "${CalendarContract.Reminders.EVENT_ID} = ?",
            arrayOf(eventId.toString()),
            "${CalendarContract.Reminders.MINUTES} ASC",
        )?.use { cursor ->
            val minutesIndex = cursor.getColumnIndexOrThrow(CalendarContract.Reminders.MINUTES)
            while (cursor.moveToNext()) {
                reminders.add(cursor.getInt(minutesIndex))
            }
        }
        return reminders
    }

    private fun longArgument(value: Any?): Long? {
        return when (value) {
            is Long -> value
            is Int -> value.toLong()
            is Number -> value.toLong()
            else -> value?.toString()?.toLongOrNull()
        }
    }

    private fun intArgument(value: Any?): Int? {
        return when (value) {
            is Int -> value
            is Long -> value.toInt()
            is Number -> value.toInt()
            else -> value?.toString()?.toIntOrNull()
        }
    }

    private fun allDayUtcBounds(startMillis: Long, endMillis: Long): Pair<Long, Long> {
        val localStart = Calendar.getInstance()
        localStart.timeInMillis = startMillis
        val localEnd = Calendar.getInstance()
        localEnd.timeInMillis = endMillis

        val utcStart = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            clear()
            set(
                localStart.get(Calendar.YEAR),
                localStart.get(Calendar.MONTH),
                localStart.get(Calendar.DAY_OF_MONTH),
            )
        }
        val utcEnd = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            clear()
            set(
                localEnd.get(Calendar.YEAR),
                localEnd.get(Calendar.MONTH),
                localEnd.get(Calendar.DAY_OF_MONTH),
            )
            add(Calendar.DAY_OF_MONTH, 1)
        }

        if (!utcEnd.after(utcStart)) {
            utcEnd.timeInMillis = utcStart.timeInMillis
            utcEnd.add(Calendar.DAY_OF_MONTH, 1)
        }

        return Pair(utcStart.timeInMillis, utcEnd.timeInMillis)
    }

    private fun durationForMillis(durationMillis: Long, allDay: Boolean): String {
        return if (allDay) {
            val days = (durationMillis / 86_400_000L).coerceAtLeast(1)
            "P${days}D"
        } else {
            val seconds = (durationMillis / 1_000L).coerceAtLeast(60)
            "PT${seconds}S"
        }
    }
}
