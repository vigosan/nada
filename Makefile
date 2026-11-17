export PATH := $(HOME)/.cargo/bin:$(PATH)
FILTERS_DIR := $(HOME)/Library/Application Support/Nada/filters
SIGN_ID ?= -
LISTS := .build/lists/easylist.txt .build/lists/easyprivacy.txt

.PHONY: build test run filters app web web-dev

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

app: build
	rm -rf dist/Nada.app dist/AppIcon.iconset
	mkdir -p dist/Nada.app/Contents/MacOS dist/Nada.app/Contents/Resources
	cp .build/release/Nada dist/Nada.app/Contents/MacOS/Nada
	cp App/Info.plist dist/Nada.app/Contents/Info.plist
	cp -R "$(FILTERS_DIR)" dist/Nada.app/Contents/Resources/filters
	swift scripts/make-icon.swift dist/AppIcon.iconset
	iconutil -c icns dist/AppIcon.iconset -o dist/Nada.app/Contents/Resources/AppIcon.icns
	rm -rf dist/AppIcon.iconset
	codesign --force --options runtime --entitlements App/Nada.entitlements --sign "$(SIGN_ID)" dist/Nada.app

web:
	cd web && npm ci && npm test && npm run build

web-dev:
	cd web && npm run dev
