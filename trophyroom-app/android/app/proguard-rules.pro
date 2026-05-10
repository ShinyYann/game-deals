# Keep AppWidgetProvider (system instantiates via reflection)
-keep class com.trophyroom.trophyroom.TrophyWidgetProvider { *; }

# Keep InstallReceiver (used by PackageInstaller)
-keep class com.trophyroom.trophyroom.InstallReceiver { *; }

# Keep all widget-related resources
-keepclassmembers class com.trophyroom.trophyroom.R$layout {
    public static final int trophy_widget;
}
-keepclassmembers class com.trophyroom.trophyroom.R$id {
    public static final int widget_*;
}
-keepclassmembers class com.trophyroom.trophyroom.R$drawable {
    public static final int widget_bg;
}
-keepclassmembers class com.trophyroom.trophyroom.R$xml {
    public static final int trophy_widget_info;
}
