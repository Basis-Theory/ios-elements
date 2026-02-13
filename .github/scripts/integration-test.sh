#!/bin/bash

set -eo pipefail

cat <<EOT > ./IntegrationTester/Env.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>btApiKey</key>
	<string>${DEV_BT_API_KEY}</string>
	<key>privateBtApiKey</key>
	<string>${DEV_PRIVATE_BT_API_KEY}</string>
	<key>proxyKey</key>
	<string>Y9CGfBNG6rAVnxN7fTiZMb</string>
	<key>proxyKeyNoAuth</key>
	<string>Ce3V4ygt9K8snVqSevZEis</string>
	<key>prodBtApiKey</key>
	<string>prodBTAPIKey</string>
	<key>privateProdBtApiKey</key>
	<string>privateProdBTAPIKey</string>
</dict>
</plist>
EOT

# Try to find iPhone 17 Pro first, fall back to iPhone 16 Pro
DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone 17 Pro (" | tail -1 | grep -oE '[A-F0-9-]{36}')

if [ -z "$DEVICE_ID" ]; then
    echo "iPhone 17 Pro not found, trying iPhone 16 Pro..."
    DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone 16 Pro (" | tail -1 | grep -oE '[A-F0-9-]{36}')
fi

if [ -z "$DEVICE_ID" ]; then
    echo "Error: No iPhone 17 Pro or iPhone 16 Pro simulator found"
    xcrun simctl list devices available
    exit 1
fi

echo "Using device ID: $DEVICE_ID"

xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true

xcodebuild clean test \
    -project ./IntegrationTester/IntegrationTester.xcodeproj \
    -scheme IntegrationTester \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$DEVICE_ID" \
    ONLY_ACTIVE_ARCH=NO \
    | xcpretty
