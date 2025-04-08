BUNDLE_CMD=bundle exec

.PHONY: test
test: ## run tests
	@$(BUNDLE_CMD) rspec

.PHONY: lint
lint: ## lint files using Rubocop
	@$(BUNDLE_CMD) rubocop -A
	