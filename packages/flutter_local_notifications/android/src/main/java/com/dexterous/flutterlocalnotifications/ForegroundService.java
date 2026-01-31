package com.dexterous.flutterlocalnotifications;

import android.app.Notification;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.os.Handler;
import android.os.Looper;

import androidx.core.app.NotificationManagerCompat;

import java.util.ArrayList;
import java.util.Locale;

import org.json.JSONObject;

import com.dexterous.flutterlocalnotifications.models.NotificationDetails;

public class ForegroundService extends Service {
  private static final long PAUSE_UPDATE_INTERVAL_MS = 30000;
  private final Handler handler = new Handler(Looper.getMainLooper());
  private Runnable pauseTicker;
  private NotificationDetails currentNotificationDetails;
  private Long pauseEndEpochMs;

  @Override
  @SuppressWarnings("deprecation")
  public int onStartCommand(Intent intent, int flags, int startId) {
    ForegroundServiceStartParameter parameter;
    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
      parameter =
          (ForegroundServiceStartParameter)
              intent.getSerializableExtra(
                  ForegroundServiceStartParameter.EXTRA, ForegroundServiceStartParameter.class);
    } else {
      parameter =
          (ForegroundServiceStartParameter)
              intent.getSerializableExtra(ForegroundServiceStartParameter.EXTRA);
    }

    currentNotificationDetails = parameter.notificationData;
    pauseEndEpochMs = extractPauseEndEpochMs(currentNotificationDetails.payload);
    updatePauseTitleIfNeeded();
    Notification notification =
        FlutterLocalNotificationsPlugin.createNotification(this, currentNotificationDetails);
    if (parameter.foregroundServiceTypes != null
        && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      startForeground(
          currentNotificationDetails.id,
          notification,
          orCombineFlags(parameter.foregroundServiceTypes));
    } else {
      startForeground(currentNotificationDetails.id, notification);
    }
    schedulePauseTicker();
    return parameter.startMode;
  }

  private void schedulePauseTicker() {
    if (pauseTicker != null) {
      handler.removeCallbacks(pauseTicker);
      pauseTicker = null;
    }
    if (pauseEndEpochMs == null || currentNotificationDetails == null) {
      return;
    }
    pauseTicker =
        new Runnable() {
          @Override
          public void run() {
            updatePauseTitleIfNeeded();
            Notification notification =
                FlutterLocalNotificationsPlugin.createNotification(
                    ForegroundService.this, currentNotificationDetails);
            NotificationManagerCompat.from(ForegroundService.this)
                .notify(currentNotificationDetails.id, notification);
            handler.postDelayed(this, PAUSE_UPDATE_INTERVAL_MS);
          }
        };
    handler.post(pauseTicker);
  }

  private void updatePauseTitleIfNeeded() {
    if (pauseEndEpochMs == null || currentNotificationDetails == null) {
      return;
    }
    long diffMs = System.currentTimeMillis() - pauseEndEpochMs;
    String sign = diffMs < 0 ? "-" : "+";
    long minutes =
        diffMs < 0
            ? (long) Math.floor((Math.abs(diffMs) + 59999) / 60000.0)
            : (long) Math.floor(diffMs / 60000.0);
    if (minutes > 99) {
      minutes = 99;
    }
    String label = String.format(Locale.getDefault(), "%s%02d", sign, minutes);
    currentNotificationDetails.title = "⏳ " + label;
  }

  private Long extractPauseEndEpochMs(String payload) {
    if (payload == null || payload.isEmpty()) {
      return null;
    }
    try {
      JSONObject json = new JSONObject(payload);
      if (!json.has("pauseEndEpochMs")) {
        return null;
      }
      return json.getLong("pauseEndEpochMs");
    } catch (Exception e) {
      return null;
    }
  }

  private static int orCombineFlags(ArrayList<Integer> flags) {
    int flag = flags.get(0);
    for (int i = 1; i < flags.size(); i++) {
      flag |= flags.get(i);
    }
    return flag;
  }

  @Override
  public IBinder onBind(Intent intent) {
    return null;
  }

  @Override
  public void onDestroy() {
    if (pauseTicker != null) {
      handler.removeCallbacks(pauseTicker);
      pauseTicker = null;
    }
    super.onDestroy();
  }
}
