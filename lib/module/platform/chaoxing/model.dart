import 'package:punklorde/module/platform/chaoxing/constant.dart' as constant;

/// 登录方式
enum ChaoxingLoginMethod {
  pwd, // 密码登录
  sms, // 短信登录
  qrcode, // 二维码登录
}

/// 登录配置
class ChaoxingLoginConfig {
  final ChaoxingLoginMethod method; // 登录方式
  final String phone; // 手机号
  final String value; // 密码或验证码或二维码token
  final ChaoxingDeviceConfig? deviceConfig; // 自定义设备信息

  const ChaoxingLoginConfig({
    required this.method,
    required this.phone,
    required this.value,
    this.deviceConfig,
  });
}

class ChaoxingDeviceConfig {
  final bool? isAndroid; // 是否为Android设备（反之则为iOS）
  final String? brand; // 设备品牌
  final String? board; // 设备board
  final String? model; // 设备型号
  final String? osVer; // 系统版本
  final String? resolution; // 屏幕分辨率

  const ChaoxingDeviceConfig({
    this.isAndroid,
    this.brand,
    this.board,
    this.model,
    this.osVer,
    this.resolution,
  });

  bool get hasCustomFields =>
      isAndroid != null ||
      brand != null ||
      board != null ||
      model != null ||
      osVer != null ||
      resolution != null;

  ChaoxingDeviceConfig copyWith({
    bool? isAndroid,
    String? brand,
    String? board,
    String? model,
    String? osVer,
    String? resolution,
  }) {
    return ChaoxingDeviceConfig(
      isAndroid: isAndroid ?? this.isAndroid,
      brand: brand ?? this.brand,
      board: board ?? this.board,
      model: model ?? this.model,
      osVer: osVer ?? this.osVer,
      resolution: resolution ?? this.resolution,
    );
  }
}

// 设备信息
class ChaoxingDeviceInfo {
  final String platform; // 平台
  final String appName; // 应用包名
  static final String appVer = constant.appVersion; // 应用版本
  static final String mediaDrmId = ""; // DRM ID，固定为空字符串
  final String cdtype; // 设备型号
  final String osName; // 系统名称
  final String osVer; // 系统版本
  final String osLang; // 系统语言
  final String cpuAr; // CPU架构
  final String resolution; // 屏幕分辨率
  final String dpi; // 屏幕DPI
  final String brand; // 设备品牌
  final String board; // 设备board
  final String hardware; // 设备硬件
  final String deviceId; // 设备ID
  final String oaid; // OAID

  const ChaoxingDeviceInfo({
    required this.platform,
    required this.appName,
    required this.cdtype,
    required this.osName,
    required this.osVer,
    required this.osLang,
    required this.cpuAr,
    required this.resolution,
    required this.dpi,
    required this.brand,
    required this.board,
    required this.hardware,
    required this.deviceId,
    required this.oaid,
  });

  factory ChaoxingDeviceInfo.fromJson(Map<String, dynamic> json) {
    return ChaoxingDeviceInfo(
      platform: json['platform'] as String,
      appName: json['app_name'] as String,
      cdtype: json['cdtype'] as String,
      osName: json['os_name'] as String,
      osVer: json['os_ver'] as String,
      osLang: json['os_lang'] as String,
      cpuAr: json['cpu_ar'] as String,
      resolution: json['resolution'] as String,
      dpi: json['dpi'] as String,
      brand: json['brand'] as String,
      board: json['board'] as String,
      hardware: json['hardware'] as String,
      deviceId: json['device_id'] as String,
      oaid: json['oaid'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'app_name': appName,
      'app_ver': appVer,
      'mediaDrmId': mediaDrmId,
      'cdtype': cdtype,
      'os_name': osName,
      'os_ver': osVer,
      'os_lang': osLang,
      'cpu_ar': cpuAr,
      'resolution': resolution,
      'dpi': dpi,
      'brand': brand,
      'board': board,
      'hardware': hardware,
      'device_id': deviceId,
      'oaid': oaid,
    };
  }
}
