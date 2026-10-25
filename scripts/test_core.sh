#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
BIN="$(mktemp -d)/devbench-smoke"
trap 'rm -rf "$(dirname "$BIN")"' EXIT
swiftc -o "$BIN" DevBench/Core/ToolDefinition.swift DevBench/Core/JSONTools.swift \
 DevBench/Core/CSVTools.swift DevBench/Core/XMLTools.swift DevBench/Core/ModelGenerator.swift \
 DevBench/Core/ToolEngine.swift Tests/CoreSmokeTests.swift
"$BIN"
