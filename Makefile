PYTHON ?= python3

.PHONY: help check-policy bank01-check bank02-check bank03-check bank04-check releases targets status

help:
	@echo "Pocket Monsters Pikachu / Pokemon Yellow disassembly"
	@echo
	@echo "Bootstrap targets:"
	@echo "  make check-policy  Verify that no ROM images or base-ROM INCBIN dependencies are tracked"
	@echo "  make bank01-check  Validate Bank 01 source inventory, include order, and family matrices"
	@echo "  make bank02-check  Validate Bank 02 audio source reconstruction, Music 1 blobs, and revision tails"
	@echo "  make bank03-check  Validate Bank 03 survey, 28-module source population, provenance, and tail wiring"
	@echo "  make bank04-check  Validate Bank 04 survey, 14-source family population, provenance, placement, and tails"
	@echo "  make releases      List verified reference releases"
	@echo "  make targets       List the nine planned source-build targets and defines"
	@echo "  make status        Show current reconstruction status"
	@echo
	@echo "Full RGBDS per-release build recipes are enabled only after their source dependencies are reconstructed."

check-policy:
	@$(PYTHON) tools/check_repository_policy.py

bank01-check:
	@$(PYTHON) tools/check_bank01_sources.py

bank02-check:
	@$(PYTHON) tools/check_bank02_survey.py
	@$(PYTHON) tools/check_bank02_music1.py

bank03-check:
	@$(PYTHON) tools/check_bank03_survey.py
	@$(PYTHON) tools/check_bank03_sources.py

bank04-check:
	@$(PYTHON) tools/check_bank04_survey.py
	@$(PYTHON) tools/check_bank04_sources.py

releases:
	@$(PYTHON) -c 'import json; d=json.load(open("config/releases.json", encoding="utf-8")); [print("{:12} {}  {}".format(r["id"], r["sha1"], r["name"])) for r in d["releases"]]'

targets:
	@$(PYTHON) -c 'import json; d=json.load(open("config/build_targets.json", encoding="utf-8")); [print("{:12} {:13} {:26} {}".format(t["id"], t["family"], ",".join(t["defines"]), t["output"])) for t in d["targets"]]'

status:
	@$(PYTHON) -c 'import json; d=json.load(open("config/releases.json", encoding="utf-8")); [print("{:12} {}".format(r["id"], r["build_status"])) for r in d["releases"]]'
