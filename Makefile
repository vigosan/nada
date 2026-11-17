.PHONY: build test run

build:
	swift build -c release

test:
	swift test

run: build
	.build/release/NoBrowser
