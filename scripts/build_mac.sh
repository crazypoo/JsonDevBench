#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "本脚本必须在安装完整 Xcode 的 macOS 设备上运行。" >&2
  exit 1
fi
xcodebuild -project DevBench.xcodeproj -scheme DevBench -configuration Release \
  -destination "platform=macOS" -derivedDataPath .derivedData CODE_SIGNING_ALLOWED=NO build
mkdir -p dist
cp -R .derivedData/Build/Products/Release/DevBench.app dist/DevBench.app
printf '\n完成: %s/dist/DevBench.app\n' "$(pwd)"
