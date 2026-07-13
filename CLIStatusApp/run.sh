#!/bin/bash
# Quick debug run without Finder Sync (SwiftPM only).
# For the full app with Finder right-click extension, use: ./build-app.sh && open .build/cliadmin.app
cd "$(dirname "$0")"
swift build && .build/debug/CLIStatusApp
