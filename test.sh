#!/bin/sh

travis=0
if [ "$1" = travis ]; then
    travis=1
fi

set -e -o pipefail

if (( $travis )); then

    # note: Couldn't get this to test on TravisCI, but builds, anyway.
    #
    #  Assertion failed: (*shader), function xglCompileShader, file /BuildRoot/Library/Caches/com.apple.xbs/Sources/Jet/Jet-2.6.1/Jet/xgl_utils.mm, line 24.
    #  2016-09-21 17:13:00.353 xcodebuild[1406:4641] Error Domain=IDETestOperationsObserverErrorDomain Code=5 "Early unexpected exit, operation never finished bootstrapping - no restart will be attempted" UserInfo={NSLocalizedDescription=Early unexpected exit, operation never finished bootstrapping - no restart will be attempted}
    #  Test target macOS-Tests encountered an error (Early unexpected exit, operation never finished bootstrapping - no restart will be attempted)
    #  The command "./test.sh" exited with 65.
    #
    # The failed assertion seems to have something to do with trying
    # to run SpriteKit on a virtual machine.  This makes me hope it's
    # a problem that will be fixed in the next release of the SDK.
    #
    # Here are some things I tried before giving up:
    #
    #     -sdk macosx10.12 \
    #     -destination 'platform=macOS' \
    #     ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO \
    #
    xcodebuild clean build \
               -workspace Example/HLSpriteKit.xcworkspace \
               -scheme macOS \
        | xcpretty

else

    xcodebuild clean build test \
               -workspace Example/HLSpriteKit.xcworkspace \
               -scheme macOS \
        | xcpretty

fi

sdk_iphonesimulator=iphonesimulator
# note: TravisCI seems to need a verison-specified SDK.  Match it to
# the osx_image in .travis.yml.  Reference:
#   https://docs.travis-ci.com/user/osx-ci-environment
# But the TravisCI failure was just the generic "Test target iOS-Tests
# encountered an error", on a day with operational troubles, so it
# might be a transient thing.  For now, specify.
#if (( $travis )); then
#    sdk_iphonesimulator=iphonesimulator10.3
#fi

# note: xcpretty has a hard time handling output from multiple (concurrent)
# destinations (see https://github.com/supermarin/xcpretty/issues/295).
# So it's just an aesthetic issue, but -disable-concurrent-destination-testing.
# Travis CI currently defaulting to osx_image xcode9.4, but the option doesn't
# exist until Xcode 10.0.  So disable the option for now in Travis, but add it
# in once the default xcode in Travis CI changes.
if (( $travis )); then
    xcode_build_options=""
else
    xcode_build_options=-disable-concurrent-destination-testing
fi
xcodebuild clean build test \
           -workspace Example/HLSpriteKit.xcworkspace \
           -scheme iOS \
           -sdk $sdk_iphonesimulator \
           $xcode_build_options \
           -destination 'platform=iOS Simulator,OS=8.4,name=iPhone 5s' \
           -destination 'platform=iOS Simulator,OS=9.3,name=iPad 2' \
           -destination 'platform=iOS Simulator,OS=latest,name=iPhone 6' \
           ONLY_ACTIVE_ARCH=NO \
    | xcpretty

# note: Framework project (for Carthage) not currently configured for
# testing; just build.
xcodebuild clean build \
           -project HLSpriteKit.xcodeproj \
           -scheme HLSpriteKit \
           -sdk $sdk_iphonesimulator \
           ONLY_ACTIVE_ARCH=NO \
    | xcpretty
