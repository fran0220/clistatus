#!/bin/bash
# Build and run CLI Status App
cd "$(dirname "$0")"
swift build && .build/debug/CLIStatusApp
