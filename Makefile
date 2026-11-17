export PATH := $(HOME)/.cargo/bin:$(PATH)
FILTERS_DIR := $(HOME)/Library/Application Support/Nada/filters
LISTS := .build/lists/easylist.txt .build/lists/easyprivacy.txt

.PHONY: build test run filters web web-dev

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

web:
	cd web && npm ci && npm test && npm run build

web-dev:
	cd web && npm run dev
