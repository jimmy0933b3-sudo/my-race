@tool
extends SceneTree

func _initialize() -> void:
 var java_path = OS.get_environment("JAVA_HOME")
 var sdk_path = OS.get_environment("ANDROID_HOME")
 if sdk_path.is_empty():
  sdk_path = OS.get_environment("ANDROID_SDK_ROOT")
 if java_path.is_empty() or sdk_path.is_empty():
  push_error("Missing Android SDK or Java 17")
  quit(1)
  return
 EditorInterface.get_editor_settings().set_setting("export/android/java_sdk_path", java_path)
 EditorInterface.get_editor_settings().set_setting("export/android/android_sdk_path", sdk_path)
 quit(0)
