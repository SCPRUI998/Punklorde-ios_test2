/// 资源源定义
class Source {
  final String id;
  final String baseUrl;
  final int priority; // 优先级，数字越小优先级越高
  final bool enabled;

  Source({
    required this.id,
    required this.baseUrl,
    this.priority = 0,
    this.enabled = true,
  });
}

/// 缓存文件条目信息
class CacheEntry {
  final String key;
  final String filePath;
  final int size; // 字节
  final DateTime lastModified;
  final DateTime? lastAccessed;

  CacheEntry({
    required this.key,
    required this.filePath,
    required this.size,
    required this.lastModified,
    this.lastAccessed,
  });

  /// 是否在指定时间窗口内过期
  bool isExpired(Duration expiry) =>
      DateTime.now().difference(lastModified) >= expiry;
}

/// 资源状态
enum ResourceStatus { initial, loading, localLoaded, remoteLoaded, error }

class ResourceState {
  final ResourceStatus status;
  final String? localPath; // 本地缓存路径
  final String? error;
  final double progress; // 下载进度 0.0 - 1.0

  ResourceState({
    this.status = ResourceStatus.initial,
    this.localPath,
    this.error,
    this.progress = 0.0,
  });

  ResourceState copyWith({
    ResourceStatus? status,
    String? localPath,
    String? error,
    double? progress,
  }) {
    return ResourceState(
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }
}
