//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <desktop_webview_window/desktop_webview_window_plugin.h>
#include <flutter_lite_camera/flutter_lite_camera_plugin_c_api.h>
#include <record_windows/record_windows_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  DesktopWebviewWindowPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DesktopWebviewWindowPlugin"));
  FlutterLiteCameraPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterLiteCameraPluginCApi"));
  RecordWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("RecordWindowsPluginCApi"));
}
