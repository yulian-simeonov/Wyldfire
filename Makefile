APP=Wyldfire
APP_DIR=$(HOME)/Downloads
PROFILE_DIR=$(HOME)/Library/MobileDevice/Provisioning Profiles
PROFILE_NAME=$(shell xcodebuild -showBuildSettings|grep 'PROVISIONING_PROFILE ='|awk '{print $$3}')
DEVELOPER=iPhone Distribution: Wyldfire, Inc. (T5ZMA3JM5N)
SDK=iphoneos7.0
CONFIG=Release
PLIST=$(APP)/Settings.bundle/Root.plist
BUILD_DATE=$(shell date +%Y%m%d)
BUILD_NUM=$(shell git describe --all --long | awk -F- '{ print $$3 }')

all: version app

app:
	/usr/bin/xcodebuild clean -configuration $(CONFIG)
	/usr/bin/xcodebuild -target $(APP) -sdk $(SDK) -configuration $(CONFIG)
	/usr/bin/xcrun -sdk iphoneos PackageApplication "build/$(CONFIG)-iphoneos/$(APP).app" -o "$(APP_DIR)/$(APP).ipa" --sign "$(DEVELOPER)" --embed "$(PROFILE_DIR)/$(PROFILE_NAME).mobileprovision"

version:
	/usr/libexec/PlistBuddy -c "Set :PreferenceSpecifiers:0:Title $(APP)" $(PLIST)
	/usr/libexec/PlistBuddy -c "Set :PreferenceSpecifiers:1:DefaultValue $(BUILD_DATE).$(BUILD_NUM)" $(PLIST)

copy:
	gsync -vpr --progress "$(APP_DIR)/$(APP).ipa" drive://Downloads/$(APP).ipa

hipchat:
	curl -d "room_id=Wyldfire&from=BuildBot&color=yellow&messageformat=html&notify=1&message=New+Wyldfire+App+$(BUILD_DATE).$(BUILD_NUM)+build+published: <a+href=https://googledrive.com/host/0B3-n81pJeM9ZQ0R4bmNNSnJWdFk/Wyldfire.html>Install</a>" https://api.hipchat.com/v1/rooms/message?auth_token=b2bed58b182b0d684508b853ae0ff4

clean:
	/usr/bin/xcodebuild clean -configuration $(CONFIG)
	rm -rf build

