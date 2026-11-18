export PATH := $(HOME)/.cargo/bin:$(PATH)
FILTERS_DIR := $(HOME)/Library/Application Support/Nada/filters
SIGN_ID ?= -
VERSION ?= 0.1.0
BUILD ?= 1
APP := dist/Nada.app
PRODUCTS := .build/out/Products/Release
SPARKLE := $(APP)/Contents/Frameworks/Sparkle.framework
SIGN := --force --timestamp --options runtime --sign "$(SIGN_ID)"
RELEASES := https://github.com/vigosan/nada/releases/download
LISTS := .build/lists/easylist.txt .build/lists/easyprivacy.txt

.PHONY: build test run filters app archive notarize appcast web web-dev

build:
	swift build -c release

test:
	swift test
	cargo test --manifest-path filters/Cargo.toml

run: build
	.build/release/Nada

filters:
	mkdir -p .build/lists
	curl -fsSL -o .build/lists/easylist.txt https://easylist.to/easylist/easylist.txt
	curl -fsSL -o .build/lists/easyprivacy.txt https://easylist.to/easylist/easyprivacy.txt
	rm -rf "$(FILTERS_DIR)"
	cargo run --release --manifest-path filters/Cargo.toml -- "$(FILTERS_DIR)" $(LISTS)

app:
	swift build -c release --arch arm64 --arch x86_64
	rm -rf dist/Nada.app dist/AppIcon.iconset
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources $(APP)/Contents/Frameworks
	cp $(PRODUCTS)/Nada $(APP)/Contents/MacOS/Nada
	install_name_tool -add_rpath @executable_path/../Frameworks $(APP)/Contents/MacOS/Nada
	cp -R $(PRODUCTS)/Sparkle.framework $(APP)/Contents/Frameworks/
	cp App/Info.plist $(APP)/Contents/Info.plist
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(VERSION)" -c "Set :CFBundleVersion $(BUILD)" $(APP)/Contents/Info.plist
	cp -R "$(FILTERS_DIR)" $(APP)/Contents/Resources/filters
	swift scripts/make-icon.swift dist/AppIcon.iconset
	iconutil -c icns dist/AppIcon.iconset -o $(APP)/Contents/Resources/AppIcon.icns
	rm -rf dist/AppIcon.iconset
	codesign $(SIGN) $(SPARKLE)/Versions/B/XPCServices/Installer.xpc
	codesign $(SIGN) --preserve-metadata=entitlements $(SPARKLE)/Versions/B/XPCServices/Downloader.xpc
	codesign $(SIGN) $(SPARKLE)/Versions/B/Autoupdate
	codesign $(SIGN) $(SPARKLE)/Versions/B/Updater.app
	codesign $(SIGN) $(SPARKLE)
	codesign $(SIGN) --entitlements App/Nada.entitlements $(APP)

archive: app
	rm -rf dist/release
	mkdir -p dist/release
	ditto -c -k --keepParent $(APP) dist/release/Nada.zip

notarize: archive
	xcrun notarytool submit dist/release/Nada.zip --key "$(NOTARY_KEY)" --key-id "$(NOTARY_KEY_ID)" --issuer "$(NOTARY_ISSUER)" --wait
	xcrun stapler staple $(APP)
	rm dist/release/Nada.zip
	ditto -c -k --keepParent $(APP) dist/release/Nada.zip

appcast:
	.build/artifacts/sparkle/Sparkle/bin/generate_appcast --download-url-prefix "$(RELEASES)/v$(VERSION)/" --link https://nada.vicent.io -o web/public/appcast.xml dist/release

web:
	cd web && npm ci && npm test && npm run build

web-dev:
	cd web && npm run dev
