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

# The runner's Xcode moves with `latest-stable`, so its installed simulator
# runtimes move too. Pinning an OS version made the job fail during destination
# resolution — before building anything — as soon as that runtime was dropped.
# Naming only the device lets xcodebuild pick whichever runtime is installed.
DESTINATION="${IOS_TEST_DESTINATION:-platform=iOS Simulator,name=iPhone 16 Pro}"

echo "Available simulator destinations:"
xcrun simctl list devices available || true

# The raw xcodebuild output is kept: xcpretty hides runner crashes and other
# non-assertion failures, which is why a run could report every bundle at
# 0 failures and still exit non-zero with nothing in the log to explain it.
set +e
xcodebuild clean test \
    -project ./IntegrationTester/IntegrationTester.xcodeproj \
    -scheme IntegrationTester \
    -configuration Debug \
    -destination "$DESTINATION" \
    -resultBundlePath ./xcodebuild-result.xcresult \
    2>&1 | tee ./xcodebuild.log | xcpretty
status=${PIPESTATUS[0]}
set -e

if [ "$status" -ne 0 ]; then
    echo "::group::xcodebuild failure detail (raw output)"
    grep -nE "error:|Testing failed|Failing tests|failed to|crash|Restarting|unexpected exit|lost connection|\*\* TEST" ./xcodebuild.log | tail -60
    echo "::endgroup::"
fi

exit "$status"
