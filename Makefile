LUA      ?= .lua/bin/lua
BUSTED   ?= .lua/bin/busted
LUACHECK ?= .lua/bin/luacheck
PY       ?= python3

.PHONY: setup fmt fmt-check lint deps test unit golden golden-update build verify ci
setup:     ; ./tools/setup_dev.sh
fmt:       ; stylua src tests tools
fmt-check: ; stylua --check src tests
lint:      ; $(LUACHECK) src tests
deps:      ; $(PY) tools/check_deps.py
unit:      ; $(BUSTED) --lua=$(LUA) tests/unit
golden:    ; $(BUSTED) --lua=$(LUA) tests/golden
golden-update: ; $(LUA) tools/golden.lua --write
test: unit golden
build:     ; $(PY) tools/build.py
verify:    ; $(PY) tools/build.py --verify
ci: fmt-check lint deps test verify
