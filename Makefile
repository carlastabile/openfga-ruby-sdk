BUNDLE_CMD=bundle exec

.PHONY: test
test: ## run tests
	@$(BUNDLE_CMD) rspec

.PHONY: lint
lint: ## lint files using Rubocop
	@$(BUNDLE_CMD) rubocop -A

.PHONY: start-openfga
start-openfga:
	@echo "Starting OpenFGA server..."
	@docker run -d --rm --name openfga-examples -p 8080:8080 openfga/openfga:latest run

.PHONY: stop-openfga
stop-openfga:
	@echo "Stopping OpenFGA server..."
	@docker stop openfga-examples || true

.PHONY: run-%
run-%: ## run example (e.g., make run-example1)
	@echo "Running example $*..."
	@ruby example/$*/main.rb
