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
import 'package:punklorde/core/storage/mmkv.dart';
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
  // 1. 最優先初始化 Flutter 框架綁定
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 2. 初始化 Rust lib
  // 加 try/catch：Rust 庫加載失敗時記錄錯誤並繼續啟動，
  // 避免未處理異常卡死啟動畫面（依賴 Rust 的功能在使用時才報錯）
  try {
    await RustLib.init();
  } catch (e) {
    debugPrint('RustLib init failed: $e');
  }

  pkldFileHandler.init();
  applySystemUiStyle(
    isDark:
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark,
  );

  // 初始化設備狀態
  await initDeviceStatus();

  // 初始化存儲服務
  await StorageService().init();
  await initMMKV(Env.keyMmkv);
  await initStatus();

  // 初始化 i18n（應用持久化的語言設置）
  applyStoredLocale();

  // 初始化資源管理器
  // 加超時保護：默認 Dio 無超時，cdn.jsdelivr.net 在部分網絡（尤其蜂窩網絡）
  // 不可達時 TCP 連接會掛起數分鐘，導致卡在啟動畫面
  await setupResourceManager(
    dio: Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 20),
      ),
    ),
  );

  // 加載持久化的源列表（覆蓋預設值）
  await loadResourceStatus();

  // ==================== iOS 百度地圖 SDK 初始化 ====================
  if (!kIsWeb && Platform.isIOS) {
    // 1. 設置同意隱私政策
    BMFMapSDK.setAgreePrivacy(true);
    
    // LocationFlutterPlugin 的 setAgreePrivacy 為實例方法
    LocationFlutterPlugin locationPlugin = LocationFlutterPlugin();
    locationPlugin.setAgreePrivacy(true);
  }
  // =======================================================================

  // 初始化服務
  await initMapService();
  initLocationService();

  // 初始化通知插件
  initNoticationPlugin();

  // 獲取權限
  await requestPermission();

  // 加載與同步狀態（修復非同步等待）
  // 加超時預算：即使學校服務器響應慢，也不能無限期阻塞啟動畫面
  try {
    await loadStatus().timeout(const Duration(seconds: 30));
    await syncStatus().timeout(const Duration(seconds: 60));
  } catch (e) {
    debugPrint('Load or sync status failed: $e');
  }

  if (kDebugMode) {
    await setDebugger();
  }

  // 移除 Splash 畫面並啟動 App
  FlutterNativeSplash.remove();
  runApp(TranslationProvider(child: MainMobileApp()));
}

// 初始化狀態
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

// 加載狀態
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

// 同步狀態
Future<void> syncStatus() async {
  // 刷新所有已過期的憑據
  await authManager.refreshAllOutDated();
  if (lastScheduleUpdateTimeSignal.value == null ||
      DateTime.now().difference(
            lastScheduleUpdateTimeSignal.value ?? DateTime.now(),
          ) >=
          const Duration(days: 1)) {
    await pullSchedule();
  }
  // 更新小組件
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