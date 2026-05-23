@echo off
REM 设置 Flutter 国内镜像（解决 storage.googleapis.com 被墙）
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
set PUB_HOSTED_URL=https://pub.flutter-io.cn

REM 启动 Android Studio
start "" "C:\Program Files\Android\Android Studio\bin\studio64.exe"

echo Flutter 镜像已设置：
echo   FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
echo   PUB_HOSTED_URL=https://pub.flutter-io.cn
echo.
echo 已启动 Android Studio，点 Run 即可。
pause
