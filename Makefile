# Makefile pengganti perintah Tuist manual.
# Jalankan `make help` untuk melihat daftar perintah.

# Gunakan versi Tuist yang di-pin di .mise.toml jika mise tersedia.
TUIST       ?= $(if $(shell command -v mise 2>/dev/null),mise exec -- tuist,tuist)
APP_NAME    := TryTuist
WORKSPACE   := $(APP_NAME).xcworkspace
ENV         ?= Dev
SCHEME      ?= $(APP_NAME)-$(ENV)
CONFIG      ?= $(ENV)
DESTINATION ?= generic/platform=iOS Simulator

.DEFAULT_GOAL := help
.PHONY: help setup install generate open edit build clean graph reset

help: ## Tampilkan daftar perintah
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

setup: ## Install Tuist sesuai .mise.toml (butuh mise)
	mise install

gen: close install generate open

# Close xcode
close:
	killall Xcode || true

# Install CocoaPods dependencies with dynamic frameworks
pods:
	pod install

install: ## Resolve dependency SPM (tuist install)
	$(TUIST) install
	

generate: install ## Generate project & workspace tanpa membuka Xcode
	$(TUIST) generate --no-open

open: install ## Generate lalu buka workspace di Xcode
	$(TUIST) generate

edit: ## Edit manifest Tuist (Project.swift, Package.swift)
	$(TUIST) edit

build: generate ## Build app untuk simulator via xcodebuild
	xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) -configuration $(CONFIG) -destination '$(DESTINATION)' build

graph: ## Generate graph dependency (graph.png)
	$(TUIST) graph --format png --no-open

clean: ## Bersihkan cache & artefak Tuist
	$(TUIST) clean

# Clean Xcode DerivedData
clean-derived:
	rm -rf ~/Library/Developer/Xcode/DerivedData
	@echo "DerivedData cleaned."

reset: clean ## Hapus project/workspace hasil generate
	rm -rf $(APP_NAME).xcodeproj $(WORKSPACE) Derived
