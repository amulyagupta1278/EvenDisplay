PYTHON := /opt/homebrew/bin/python3.13

.PHONY: seo-sync seo-audit test

seo-sync:
	$(PYTHON) scripts/seo_sync.py

seo-audit:
	$(PYTHON) scripts/seo_audit.py

test:
	bash scripts/test_all.sh
