SWIFT ?= swift
CONFIG ?= release
APP_NAME = PlanAnalysis
DIST = dist/$(APP_NAME).app
BIN = .build/$(CONFIG)/PlanAnalysisApp

.PHONY: test build app run clean

test:
	$(SWIFT) test --parallel

build:
	$(SWIFT) build -c $(CONFIG)

app: build
	rm -rf $(DIST)
	mkdir -p $(DIST)/Contents/MacOS
	cp $(BIN) $(DIST)/Contents/MacOS/$(APP_NAME)
	cp Info.plist $(DIST)/Contents/Info.plist
	printf 'APPL????' > $(DIST)/Contents/PkgInfo

run: app
	open $(DIST)

clean:
	rm -rf .build dist
