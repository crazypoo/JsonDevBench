#!/usr/bin/env bash
# Run cross-platform checks and, on macOS, a real Xcode build.
set -euo pipefail
cd "$(dirname "$0")/.."

echo '==> Validate platform imports and known SwiftUI type-check regressions'
python3 - <<'PY'
from pathlib import Path
xml = Path('DevBench/Core/XMLTools.swift').read_text()
assert '#if os(Linux)\n' in xml and 'import FoundationXML\n#endif' in xml, \
    'FoundationXML must only be imported for Linux builds'
for p in Path('DevBench').rglob('*.swift'):
    text = p.read_text()
    assert '.system(size: 13, design: .monospaced, weight:' not in text, f'{p}: invalid Font argument order'
print('PASS: platform guards + SwiftUI Font parameters')
PY

echo '==> Swift core regression tests'
bash scripts/test_core.sh

echo '==> Compile generated Codable model fixtures'
model_tmpdir="$(mktemp -d)"
swiftc -o "$model_tmpdir/generate_models" DevBench/Core/ToolDefinition.swift \
  DevBench/Core/JSONTools.swift DevBench/Core/ModelGenerator.swift Tests/GenerateModel.swift
DEVBENCH_MODEL_OUTPUT_DIR="$model_tmpdir" "$model_tmpdir/generate_models" >/dev/null
for model in "$model_tmpdir"/devbench_model_{0,1,2,3}.swift; do
  swiftc -typecheck "$model"
done
rm -rf "$model_tmpdir"
echo 'PASS: four generated Codable model variants compile'

echo '==> Parse every Swift source file'
swiftc -frontend -parse $(find DevBench -name '*.swift' -print | sort)

echo '==> Verify all Swift sources are referenced by the Xcode project'
python3 - <<'PY'
from pathlib import Path
p = Path('DevBench.xcodeproj/project.pbxproj').read_text()
from xml.etree import ElementTree as ET
scheme = Path('DevBench.xcodeproj/xcshareddata/xcschemes/DevBench.xcscheme')
assert scheme.is_file(), 'Missing shared Xcode scheme'
ET.parse(scheme)
for f in Path('DevBench').rglob('*.swift'):
    assert f'path = "{f.name}";' in p, f'{f} missing from Xcode project'
print('PASS: all Swift sources in pbxproj')
PY

if command -v plutil >/dev/null 2>&1; then
  plutil -lint -- DevBench.xcodeproj/project.pbxproj
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  if ! command -v xcodebuild >/dev/null 2>&1; then
    echo 'ERROR: macOS detected but xcodebuild is unavailable. Select full Xcode with xcode-select.' >&2
    exit 1
  fi
  echo '==> Xcode Debug build: macOS App'
  xcodebuild -project DevBench.xcodeproj -scheme DevBench -configuration Debug \
    -destination 'platform=macOS' -derivedDataPath .derivedData \
    CODE_SIGNING_ALLOWED=NO build
  echo '==> Xcode Release build: macOS App'
  xcodebuild -project DevBench.xcodeproj -scheme DevBench -configuration Release \
    -destination 'platform=macOS' -derivedDataPath .derivedData \
    CODE_SIGNING_ALLOWED=NO build
  test -d '.derivedData/Build/Products/Release/DevBench.app'
  echo 'PASS: macOS Xcode Debug + Release builds'
else
  echo 'NOTE: Linux verification completed; macOS GUI typechecking/build requires Xcode on macOS.'
fi
