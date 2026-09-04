import os
import glob
import re
import urllib.request
import time

def download_with_retry(url, dest_path):
    print(f"Pre-downloading {url} ...")
    headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'}
    req = urllib.request.Request(url, headers=headers)
    for i in range(5):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp, open(dest_path, 'wb') as f:
                f.write(resp.read())
            print(f"Successfully downloaded to {dest_path}")
            return True
        except Exception as e:
            print(f"Download attempt {i+1} failed: {e}")
            time.sleep(3)
    return False

def main():
    # 0. 配置 ~/.curlrc 强制 curl 使用 HTTP/1.1 并增加重试
    curlrc = os.path.expanduser('~/.curlrc')
    with open(curlrc, 'w') as f:
        f.write('http1.1\nretry = 5\nretry-delay = 2\n')

    # 0.1 预下载 BMKLocationKit 压缩包到本地
    bmk_zip = '/tmp/BMKLocationKitV2.1.4.zip'
    download_with_retry('https://lbsyun-baidu.cdn.bcebos.com/iossdk/location/2.1.4/BMKLocationKitV2.1.4.zip', bmk_zip)

    # A. 修补 zstandard_ios 本地的 podspec
    for ps in glob.glob('ios/.symlinks/plugins/zstandard_ios/**/*.podspec', recursive=True):
        with open(ps, 'r', encoding='utf-8') as f:
            content = f.read()
        content = re.sub(r's\.public_header_files\s*=\s*\[[^\]]*\]\s*', '', content, flags=re.DOTALL)
        content = re.sub(r's\.public_header_files\s*=\s*[^\n]*\n', '', content)
        content += "\ns.public_header_files = 'Classes/**/*Plugin*.h'\n"
        with open(ps, 'w', encoding='utf-8') as f:
            f.write(content)

    # B. 写入 Podfile（若存在预下载文件则优先使用本地 file:// 源）
    podfile_content = '''platform :ios, '17.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist."
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  pod 'SDWebImage', :modular_headers => true
  if File.exist?('/tmp/BMKLocationKitV2.1.4.zip')
    pod 'BMKLocationKit', :http => 'file:///tmp/BMKLocationKitV2.1.4.zip'
  end
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'

      if target.name.include?('zstandard_ios')
        config.build_settings['HEADER_SEARCH_PATHS'] ||= '$(inherited) '
        config.build_settings['HEADER_SEARCH_PATHS'] += ' "${PODS_TARGET_SRCROOT}/**" '
        config.build_settings['DEFINES_MODULE'] = 'NO'
      end
    end

    if target.name.include?('rust_lib_punklorde')
      target.build_phases.each do |phase|
        if phase.respond_to?(:output_paths)
          phase.output_paths.clear
        end
      end
    end
  end

  Dir.glob("#{installer.sandbox.root}/Target Support Files/zstandard_ios/*umbrella.h").each do |umb|
    if File.exist?(umb)
      lines = File.readlines(umb).reject { |l| l.include?('zstd.h') }
      File.open(umb, 'w') { |f| f.puts(lines) }
    end
  end
end
'''
    with open('ios/Podfile', 'w', encoding='utf-8') as f:
        f.write(podfile_content)

    # C. 修改 Xcode 项目属性与 Header 引用
    header_path = 'ios/Runner/Runner-Bridging-Header.h'
    if os.path.exists(header_path):
        with open(header_path, 'r', encoding='utf-8', errors='ignore') as f:
            h_content = f.read()
        h_content = re.sub(r'#import\s+[\"<]flutter_foreground_task/FlutterForegroundTaskPlugin\.h[\">]', '#import <flutter_foreground_task/FlutterForegroundTaskPlugin.h>', h_content)
        with open(header_path, 'w', encoding='utf-8') as f:
            f.write(h_content)

    pbx_path = 'ios/Runner.xcodeproj/project.pbxproj'
    with open(pbx_path, 'r', encoding='utf-8', errors='ignore') as f:
        pbx = f.read()

    pbx = re.sub(r'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;', 'IPHONEOS_DEPLOYMENT_TARGET = 17.0;', pbx)

    if 'DEVELOPMENT_TEAM =' in pbx:
        pbx = re.sub(r'DEVELOPMENT_TEAM = [^;]+;', 'DEVELOPMENT_TEAM = 1234567890;', pbx)
    else:
        pbx = re.sub(r'(buildSettings = \{)', r'\1\n\t\t\t\tDEVELOPMENT_TEAM = 1234567890;', pbx)

    if 'CODE_SIGNING_ALLOWED =' in pbx:
        pbx = re.sub(r'CODE_SIGNING_ALLOWED = [^;]+;', 'CODE_SIGNING_ALLOWED = NO;', pbx)
    else:
        pbx = re.sub(r'(buildSettings = \{)', r'\1\n\t\t\t\tCODE_SIGNING_ALLOWED = NO;', pbx)

    with open(pbx_path, 'w', encoding='utf-8') as f:
        f.write(pbx)

    override_flags = '\nDEVELOPMENT_TEAM=1234567890\nCODE_SIGNING_ALLOWED=NO\nCODE_SIGNING_REQUIRED=NO\nCODE_SIGN_IDENTITY=\nCLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES=YES\nENABLE_BITCODE=NO\nIPHONEOS_DEPLOYMENT_TARGET=17.0\n'
    for cfg in ['ios/Flutter/Generated.xcconfig', 'ios/Flutter/Release.xcconfig']:
        if os.path.exists(cfg):
            with open(cfg, 'a', encoding='utf-8') as f:
                f.write(override_flags)

if __name__ == '__main__':
    main()