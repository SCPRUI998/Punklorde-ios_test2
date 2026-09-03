import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/core/status/device.dart' as device;
import 'package:punklorde/i18n/strings.g.dart';
import 'package:punklorde/module/platform/chaoxing/model.dart';

const _iosBrand = 'iPhone';
const _iosBoard = 'iPhone';
const _iosModel = 'iPhone15,2';
const _iosOsVer = '18.0';
const _iosResolution = '1170*2532';

const _androidResolution = '1080*2400';

class ChaoxingCustomDevicePage extends StatefulWidget {
  final ChaoxingDeviceConfig? initialConfig;

  const ChaoxingCustomDevicePage({super.key, this.initialConfig});

  @override
  State<ChaoxingCustomDevicePage> createState() =>
      _ChaoxingCustomDevicePageState();
}

class _ChaoxingCustomDevicePageState extends State<ChaoxingCustomDevicePage> {
  final _formKey = GlobalKey<FormState>();
  late bool _isAndroid;
  late final TextEditingController _brandController;
  late final TextEditingController _boardController;
  late final TextEditingController _modelController;
  late final TextEditingController _osVerController;
  late final TextEditingController _resolutionController;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    _isAndroid = config?.isAndroid ?? true;
    _brandController = TextEditingController(
      text: _isAndroid ? (config?.brand ?? device.deviceBrand) : _iosBrand,
    );
    _boardController = TextEditingController(
      text: _isAndroid ? (config?.board ?? device.deviceBoard) : _iosBoard,
    );
    _modelController = TextEditingController(
      text: _isAndroid
          ? (config?.model ?? device.deviceModel)
          : (config?.model ?? _iosModel),
    );
    _osVerController = TextEditingController(
      text: _isAndroid
          ? (config?.osVer ?? device.deviceOSVersion)
          : (config?.osVer ?? _iosOsVer),
    );
    _resolutionController = TextEditingController(
      text: _isAndroid
          ? (config?.resolution ?? _androidResolution)
          : (config?.resolution ?? _iosResolution),
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _boardController.dispose();
    _modelController.dispose();
    _osVerController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FHeader.nested(
                prefixes: [
                  FHeaderAction.x(onPress: () => Navigator.of(context).pop()),
                ],
                title: Text(t.action.custom_device_info),
                suffixes: [
                  FHeaderAction(
                    icon: Icon(LucideIcons.rotateCw),
                    onPress: _resetToDefault,
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: Column(
                    spacing: 8,
                    children: [
                      _buildPlatformSwitch(colors),
                      FTextFormField(
                        control: .managed(controller: _brandController),
                        label: Text(t.title.device_brand),
                        enabled: _isAndroid,
                        validator: _notEmptyValidator,
                      ),
                      FTextFormField(
                        control: .managed(controller: _boardController),
                        label: Text(t.title.device_board),
                        enabled: _isAndroid,
                        validator: _notEmptyValidator,
                      ),
                      FTextFormField(
                        control: .managed(controller: _modelController),
                        label: Text(t.title.device_model),
                        validator: _notEmptyValidator,
                      ),
                      FTextFormField(
                        control: .managed(controller: _osVerController),
                        label: Text(t.title.device_os_ver),
                        validator: _notEmptyValidator,
                      ),
                      FTextFormField(
                        control: .managed(controller: _resolutionController),
                        label: Text(t.title.device_resolution),
                        hint: '720*1280',
                        validator: _resolutionValidator,
                      ),
                      const FDivider(),
                      FButton(
                        variant: .primary,
                        size: .sm,
                        onPress: _onConfirm,
                        child: Text(t.notice.confirm),
                      ),
                      FButton(
                        variant: .secondary,
                        size: .sm,
                        onPress: _resetToDefault,
                        prefix: Icon(LucideIcons.rotateCw, size: 18),
                        child: Text(t.action.reset_device_info),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformSwitch(FColors colors) {
    return Row(
      spacing: 4,
      children: [
        Icon(
          _isAndroid ? Icons.android_rounded : Icons.apple_rounded,
          size: 24,
          color: colors.primary,
        ),
        Text(
          t.title.device_platform,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colors.foreground,
          ),
        ),
        const Spacer(),
        Text(
          'iOS',
          style: TextStyle(
            fontSize: 13,
            color: _isAndroid ? colors.mutedForeground : colors.primary,
            fontWeight: _isAndroid ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        Switch(
          value: _isAndroid,
          onChanged: (v) => setState(() {
            _isAndroid = v;
            if (!_isAndroid) {
              _brandController.text = _iosBrand;
              _boardController.text = _iosBoard;
            } else {
              _brandController.text = device.deviceBrand;
              _boardController.text = device.deviceBoard;
            }
          }),
        ),
        Text(
          'Android',
          style: TextStyle(
            fontSize: 13,
            color: _isAndroid ? colors.primary : colors.mutedForeground,
            fontWeight: _isAndroid ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String? _notEmptyValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return t.notice.field_required;
    }
    return null;
  }

  String? _resolutionValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return t.notice.field_required;
    }
    final pattern = RegExp(r'^\d{3,4}\*\d{3,4}$');
    if (!pattern.hasMatch(value.trim())) {
      return t.notice.invalid_resolution_format;
    }
    return null;
  }

  void _resetToDefault() {
    setState(() {
      if (_isAndroid) {
        _brandController.text = device.deviceBrand;
        _boardController.text = device.deviceBoard;
        _modelController.text = device.deviceModel;
        _osVerController.text = device.deviceOSVersion;
        _resolutionController.text = _androidResolution;
      } else {
        _brandController.text = _iosBrand;
        _boardController.text = _iosBoard;
        _modelController.text = _iosModel;
        _osVerController.text = _iosOsVer;
        _resolutionController.text = _iosResolution;
      }
    });
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final config = ChaoxingDeviceConfig(
      isAndroid: _isAndroid,
      brand: _brandController.text.trim(),
      board: _boardController.text.trim(),
      model: _modelController.text.trim(),
      osVer: _osVerController.text.trim(),
      resolution: _resolutionController.text.trim(),
    );
    Navigator.of(context).pop(config);
  }
}
