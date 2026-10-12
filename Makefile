APP := build/Build/Products/Release/AIUsage.app

# Team ID = OU of the first "Apple Development" certificate in the Keychain.
# Override with: make install TEAM_ID=XXXXXXXXXX
TEAM_ID ?= $(shell security find-certificate -c "Apple Development" -p 2>/dev/null \
	| openssl x509 -noout -subject 2>/dev/null | sed -n 's/.*OU *= *\([A-Z0-9]*\).*/\1/p')
export TEAM_ID

.PHONY: check gen build run install release clean

check:
	@xcodebuild -version >/dev/null 2>&1 || { echo "✗ Falta Xcode completo (App Store) y: sudo xcode-select -s /Applications/Xcode.app"; exit 1; }
	@command -v xcodegen >/dev/null || { echo "✗ Falta xcodegen: brew install xcodegen"; exit 1; }
	@[ -n "$(TEAM_ID)" ] || { echo "✗ No hay certificado 'Apple Development'. Xcode → Settings → Accounts → añade tu Apple ID → Manage Certificates → + Apple Development"; exit 1; }
	@security find-generic-password -s "Claude Code-credentials" >/dev/null 2>&1 || echo "⚠︎ No encuentro la sesión de Claude Code; instálalo y haz login (claude) para ver datos."
	@echo "✓ Team ID: $(TEAM_ID)"

gen: check
	xcodegen generate

# A new build number every time: chronod caches widget descriptors per
# CFBundleVersion, so a reused number keeps serving the old widget config.
build: gen
	xcodebuild -project AIUsage.xcodeproj -scheme AIUsage -configuration Release \
		-derivedDataPath build -quiet build CURRENT_PROJECT_VERSION=$(shell date +%Y%m%d%H%M%S)

install: build
	pkill -x AIUsage || true
	# The widget extension outlives the app; without this the desktop keeps rendering the old binary.
	pkill -x AIUsageWidget || true
	rm -rf ~/Applications/AIUsage.app
	mkdir -p ~/Applications
	cp -R $(APP) ~/Applications/
	open ~/Applications/AIUsage.app
	@echo "✓ Instalado. Añade el widget: clic derecho en el escritorio → Editar widgets → AI Usage"

run: install

release:
	./scripts/release.sh

clean:
	rm -rf build AIUsage.xcodeproj
