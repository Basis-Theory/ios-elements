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

xcodebuild clean test \
    -project ./IntegrationTester/IntegrationTester.xcodeproj \
    -scheme IntegrationTester \
    -configuration Debug \
    -destination platform="iOS Simulator,OS=18.6,name=iPhone 16 Pro" \
    | xcpretty
