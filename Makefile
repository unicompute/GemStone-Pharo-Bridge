.PHONY: help core-only original original-tests bootstrap-smoke full verify graph-artifacts artifact-freshness original-drift

PHARO_IMAGE ?= /Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean/Pharo 13.0 - clean.image
PHARO_WORK_DIR ?= /Users/tariq/Documents/Pharo/images/Pharo 13.0 - clean

help:
	@printf "%s\n" \
		"GemStone-Pharo-Bridge lanes" \
		"" \
		"  make core-only" \
		"    Load only the Smalltalk core and run GemStone-Pharo-Core-Tests." \
		"" \
		"  make original" \
		"    Load only the original/base production packages and prove the base production layer reloads cleanly." \
		"" \
		"  make original-tests" \
		"    Load only the original/base production and original/base tests." \
		"    The live lane runs only when GS_USER and GS_PASS are set." \
		"" \
		"  make bootstrap-smoke" \
		"    Prove the micro-bootstrap path loads helper classes and the requested load group into a clean image." \
		"" \
		"  make full" \
		"    Run the full clean reload and regression lane." \
		"    The live lane runs only when GS_USER and GS_PASS are set." \
		"" \
		"  make verify" \
		"    Run core-only, bootstrap-smoke, original, original-drift, original-tests, full, artifact-freshness, then the summary-renderer smoke check." \
		"" \
		"  make graph-artifacts" \
		"    Regenerate package-graph and verification-lane artifacts in doc/." \
		"" \
		"  make artifact-freshness" \
		"    Verify that generated contract artifacts in doc/ are up to date." \
		"" \
		"  make original-drift" \
		"    Show the remaining drift in the original package roots relative to 56b6db3." \
		"" \
		"Variables:" \
		"  PHARO_IMAGE=$(PHARO_IMAGE)" \
		"  PHARO_WORK_DIR=$(PHARO_WORK_DIR)" \
		"  Optional live env: GS_USER GS_PASS GS_STONE GS_SERVICE GS_NETLDI_HOST GS_NETLDI_NAME_OR_PORT GEMSTONE"

core-only:
	bash ./scripts/run_core_only_clean_reload.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

original:
	bash ./scripts/run_original_clean_reload.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

original-tests:
	bash ./scripts/run_original_tests_clean_reload.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

bootstrap-smoke:
	bash ./scripts/run_bootstrap_smoke.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

full:
	./scripts/run_clean_reload_and_regressions.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

verify:
	bash ./scripts/run_verify.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

graph-artifacts:
	bash ./scripts/run_generate_contract_artifacts.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

artifact-freshness:
	bash ./scripts/run_verify_contract_artifacts.sh "$(PHARO_IMAGE)" "$(PHARO_WORK_DIR)"

original-drift:
	bash ./scripts/run_original_drift.sh
