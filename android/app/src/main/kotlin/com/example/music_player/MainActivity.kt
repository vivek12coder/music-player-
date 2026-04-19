package com.example.music_player

import android.media.audiofx.Equalizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "pulseplay/equalizer"
    private var equalizer: Equalizer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(true)
                "init" -> {
                    val sessionId = call.argument<Int>("sessionId") ?: 0
                    initEqualizer(sessionId)
                    result.success(true)
                }
                "setEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    equalizer?.enabled = enabled
                    result.success(true)
                }
                "getBandLevelRange" -> {
                    val range = equalizer?.bandLevelRange
                    result.success(listOf(range?.get(0)?.toInt() ?: -1500, range?.get(1)?.toInt() ?: 1500))
                }
                "getBandFrequencies" -> {
                    val eq = equalizer
                    if (eq == null) {
                        result.success(emptyList<Int>())
                    } else {
                        val values = mutableListOf<Int>()
                        for (band in 0 until eq.numberOfBands) {
                            values.add(eq.getCenterFreq(band.toShort()) / 1000)
                        }
                        result.success(values)
                    }
                }
                "getBandLevels" -> {
                    val eq = equalizer
                    if (eq == null) {
                        result.success(emptyList<Int>())
                    } else {
                        val values = mutableListOf<Int>()
                        for (band in 0 until eq.numberOfBands) {
                            values.add(eq.getBandLevel(band.toShort()).toInt())
                        }
                        result.success(values)
                    }
                }
                "setBandLevel" -> {
                    val band = call.argument<Int>("band") ?: 0
                    val level = call.argument<Int>("level") ?: 0
                    equalizer?.setBandLevel(band.toShort(), level.toShort())
                    result.success(true)
                }
                "getPresets" -> {
                    val eq = equalizer
                    if (eq == null) {
                        result.success(emptyList<String>())
                    } else {
                        val presets = mutableListOf<String>()
                        for (preset in 0 until eq.numberOfPresets) {
                            presets.add(eq.getPresetName(preset.toShort()))
                        }
                        result.success(presets)
                    }
                }
                "usePreset" -> {
                    val preset = call.argument<Int>("preset") ?: 0
                    equalizer?.usePreset(preset.toShort())
                    result.success(true)
                }
                "release" -> {
                    equalizer?.release()
                    equalizer = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun initEqualizer(sessionId: Int) {
        equalizer?.release()
        equalizer = Equalizer(0, sessionId).apply {
            enabled = true
        }
    }
}

