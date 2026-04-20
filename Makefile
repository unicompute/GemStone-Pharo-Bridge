.PHONY: help core-only compatibility-only full verify graph-artifacts artifact-freshness

PHARO_IMAGE ?= /Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image
PHARO_WORK_DIR ?= /Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean

help:
	@printf "%s\n" \
		"GemStone-Pharo-Bridge lanes" \
		"" \
		"  make core-only" \
		"    Load only the Smalltalk core and run GemStone-Pharo-Core-Tests." \
		"" \
		"  make compatibility-only" \
		"    Load compatibility coverage and run GemStone-Pharo-Compatibility-Tests." \
		"" \
		"  make full" \
		"    Run the full clean reload and regression lane." \
		"    The live lane runs only when GS_USER and GS_PASS are set." \
		"" \
		"  make verify" \
		"    Run core-only, compatibility-only, then the full lane." \
		"" \
		"  make graph-artifacts" \
		"    Regenerate package-graph and verification-lane artifacts in doc/." \
		"" \
		"  make artifact-freshness" \
		"    Verify that generated contract artifacts in doc/ are up to date." \
		"" \
		"Variables:" \
		"  PHARO_IMAGE=$(PHARO_IMAGE)" \
		"  PHARO_WORK_DIR=$(PHARO_WORK_DIR)" \
		"  Optional live env: GS_USER GS_PASS GS_STONE GS_SERVICE GS_NETLDI_HOST GS_NETLDI_NAME_OR_PORT GEMSTONE"

core-only:
	bash ./scripts/run_core_only_clean_reload.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

compatibility-only:
	bash ./scripts/run_compatibility_clean_reload.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

full:
	./scripts/run_clean_reload_and_regressions.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

verify:
	$(MAKE) core-only PHARO_IMAGE="$(PHARO_IMAGE)" PHARO_WORK_DIR="$(PHARO_WORK_DIR)"
	$(MAKE) compatibility-only PHARO_IMAGE="$(PHARO_IMAGE)" PHARO_WORK_DIR="$(PHARO_WORK_DIR)"
	$(MAKE) full PHARO_IMAGE="$(PHARO_IMAGE)" PHARO_WORK_DIR="$(PHARO_WORK_DIR)"
	$(MAKE) artifact-freshness PHARO_IMAGE="$(PHARO_IMAGE)" PHARO_WORK_DIR="$(PHARO_WORK_DIR)"

graph-artifacts:
	bash ./scripts/run_generate_contract_artifacts.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

artifact-freshness:
	bash ./scripts/run_verify_contract_artifacts.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"
