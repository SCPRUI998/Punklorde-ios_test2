import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart';
import 'package:flutter_bmflocation/flutter_bmflocation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:punklorde/app/main.dart';
import 'package:punklorde/core/account/pkld_file_handler.dart';
import 'package:punklorde/core/service/widget_service.dart';
import 'package:punklorde/core/status/app.dart';
import 'package:punklorde/core/status/auth.dart';
import 'package:punklorde/core/status/device.dart';
import 'package:punklorde/core/status/experiment.dart';
import 'package:punklorde/core/status/map.dart';
import 'package:punklorde/core/status/resource.dart';
import 'package:punklorde/core/status/schedule.dart';
import 'package0/core/storage/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';
import 'package:punklorde/env.dart';
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/feature/chaoxing/index.dart';
import 'package:punklorde/module/service/lbs/location.dart';
import 'package:punklorde/module/service/lbs/map.dart';
import 'package:punklorde/src/rust/frb_generated.dart';
import 'package:punklorde/utils/etc/style.dart';
import 'package:punklorde/utils/notification.dart';
import 'package:punklorde/utils/permission.dart';

Future<void> main() async {
  // 初始化 Rust lib
  await RustLib.init();

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  pkldFileHandler.init();
  applySystemUiStyle(
    isDark:
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark,
  );

  // 初始化设备状态
  await initDeviceStatus();

  // 初始化存储服务
  await StorageService().init();
  await initMMKV(Env.keyMmkv);
  await initStatus();

  // 初始化 i18n（应用持久化的语言设置）
  applyStoredLocale();

  // 初始化资源管理器
  await setupResourceManager(dio: Dio());

  // 加载持久化的源列表（覆盖默认值）
  await loadResourceStatus();

  // ==================== iOS 百度地图 SDK 初始化 (已修正 API) ====================
  if (Platform.isIOS) {
    // 1. 设置同意隐私政策
    BMFMapSDK.setAgreePrivacy(true);
    
    // LocationFlutterPlugin 的 setAgreePrivacy 为实例方法
    LocationFlutterPlugin locationPlugin = LocationFlutterPlugin();
    locationPlugin.setAgreePrivacy(true);

    // 2. 注入 iOS AK (第二个参数为空字符串或指定类型)
    BMFMapSDK.setApiKey('w4Lshb3n8IIHdPyYkKL91SQ1TxltmOtC', '');
  }
  // =======================================================================

  // 初始化服务
  await initMapService();
  initLocationService();

  // 初始化通知插件
  initNoticationPlugin();

  // 获取权限
  requestPermission();

  // 加载状态
  await loadStatus().then((v) {
    // 同步状态
    syncStatus();
  });

  if (kDebugMode) {
    await setDebugger();
  }

  FlutterNativeSplash.remove();
  runApp(TranslationProvider(child: MainMobileApp()));
}

// 初始化状态
Future<void> initStatus() async {
  try {
    loadAppStatus();
    await loadAuthStatus();
    await loadExperimentStatus();
  } catch (e) {
    print(e);
  }

  initAppStatus();
  initAuthStatus();
  initExperimentStatus();
  initResourceStatus();
  loadMapProvider();
  initMapStatus();
}

// 加载状态
Future<void> loadStatus() async {
  try {
    await loadSemester();
    await loadScheduleStatus();
  } catch (e) {
    print(e);
  }
  initScheduleStatus();

  initChaoxingServices();
}

// 同步状态
Future<void> syncStatus() async {
  // 刷新所有已过时的凭据
  await authManager.refreshAllOutDated();
  if (lastScheduleUpdateTimeSignal.value == null ||
      DateTime.now().difference(
            lastScheduleUpdateTimeSignal.value ?? DateTime.now(),
          ) >=
          const Duration(days: 1)) {
    await pullSchedule();
  }
  // 更新小组件
  await ScheduleWidgetService.updateWidget();
}

Future<void> requestPermission() async {
  await checkAndRequestPermission(PermissionType.notice);
  await checkAndRequestPermission(PermissionType.microphone);
}

Future<void> setDebugger() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  PlatformInAppWebViewController.debugLoggingSettings.enabled = true;
}