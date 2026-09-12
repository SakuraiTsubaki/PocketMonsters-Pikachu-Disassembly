PYTHON ?= python3

.PHONY: help check-policy releases targets status

help:
	@echo "Pocket Monsters Pikachu / Pokemon Yellow disassembly"
	@echo
	@echo "Bootstrap targets:"
	@echo "  make check-policy  Verify that no ROM images or base-ROM INCBIN dependencies are tracked"
	@echo "  make releases      List verified reference releases"
	@echo "  make targets       List the nine planned source-build targets and defines"
	@echo "  make status        Show current reconstruction status"
	@echo
	@echo "Full RGBDS per-release build recipes are enabled only after their source dependencies are reconstructed."

check-policy:
	@$(PYTHON) tools/check_repository_policy.py

releases:
	@$(PYTHON) -c 'import json; d=json.load(open("config/releases.json", encoding="utf-8")); [print("{:12} {}  {}".format(r["id"], r["sha1"], r["name"])) for r in d["releases"]]'

targets:
	@$(PYTHON) -c 'import json; d=json.load(open("config/build_targets.json", encoding="utf-8")); [print("{:12} {:13} {:26} {}".format(t["id"], t["family"], ",".join(t["defines"]), t["output"])) for t in d["targets"]]'

status:
	@$(PYTHON) -c 'import json; d=json.load(open("config/releases.json", encoding="utf-8")); [print("{:12} {}".format(r["id"], r["build_status"])) for r in d["releases"]]'
