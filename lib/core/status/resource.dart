import 'package:dio/dio.dart';
import 'package:punklorde/core/resource/cache.dart';
import 'package:punklorde/core/resource/manager.dart';
import 'package:punklorde/core/resource/model.dart';
import 'package:punklorde/core/storage/mmkv.dart';
import 'package:punklorde/core/storage/storage.dart';
import 'package:signals/signals_flutter.dart';

/// 默认源列表（硬编码兜底）
final _defaultSources = <Source>[
  Source(
    id: 'default',
    baseUrl: 'https://cdn.jsdelivr.net/gh/zrurf/PunklordeAssets@main/',
  ),
];

// 资源管理器
late final ResourceManager resourceManager;

/// 缓存键
const _sourcesStorageKey = 'resource_sources';

/// 初始化资源管理器
/// [sources] 仅在无持久化数据时作为默认值使用
Future<void> setupResourceManager({
  required Dio dio,
  List<Source>? sources,
}) async {
  final cacheService = CacheService();
  await cacheService.init();

  resourceManager = ResourceManager(dio: dio, cacheService: cacheService);
  resourceManager.sourcesSignal.value = sources ?? _defaultSources;
}

/// 从持久化存储加载源列表，覆盖当前信号值
Future<void> loadResourceStatus() async {
  try {
    final storage = StorageService();
    final rawList = await storage.getList(
      _sourcesStorageKey,
      instance: resourceMMKV,
    );

    if (rawList == null || rawList.isEmpty) return;

    final sources = rawList.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return Source(
        id: map['id'] as String,
        baseUrl: map['baseUrl'] as String,
        priority: map['priority'] as int? ?? 0,
        enabled: map['enabled'] as bool? ?? true,
      );
    }).toList();

    if (sources.isNotEmpty) {
      resourceManager.sourcesSignal.value = sources;
    }
  } catch (e) {
    print('Failed to load resource sources: $e');
  }
}

/// 启用自动持久化：源列表变更时自动保存
void initResourceStatus() {
  effect(() {
    storeResourceStatus();
  });
}

/// 将当前源列表序列化到 MMKV
void storeResourceStatus() {
  try {
    final storage = StorageService();
    final sources = resourceManager.sourcesSignal.value;

    final data = sources
        .map(
          (s) => {
            'id': s.id,
            'baseUrl': s.baseUrl,
            'priority': s.priority,
            'enabled': s.enabled,
          },
        )
        .toList();

    storage.putList(_sourcesStorageKey, data, instance: resourceMMKV);
  } catch (e) {
    print('Failed to store resource sources: $e');
  }
}
