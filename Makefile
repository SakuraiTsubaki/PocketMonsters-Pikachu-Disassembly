PYTHON ?= python3

.PHONY: help check-policy releases status

help:
	@echo "Pocket Monsters Pikachu / Pokemon Yellow disassembly"
	@echo
	@echo "Bootstrap targets:"
	@echo "  make check-policy  Verify that no ROM images or base-ROM INCBIN dependencies are tracked"
	@echo "  make releases      List verified reference releases"
	@echo "  make status        Show current reconstruction status"
	@echo
	@echo "Per-release build targets will be enabled as reconstruction reaches reproducible-build milestones."

check-policy:
	@$(PYTHON) tools/check_repository_policy.py

releases:
	@$(PYTHON) -c 'import json; d=json.load(open("config/releases.json", encoding="utf-8")); [print(f"{r[\"id\"]:12} {r[\"sha1\"]}  {r[\"name\"]}") for r in d["releases"]]'

status:
	@$(PYTHON) -c 'import json; d=json.load(open("config/releases.json", encoding="utf-8")); [print(f"{r[\"id\"]:12} {r[\"build_status\"]}") for r in d["releases"]]'
