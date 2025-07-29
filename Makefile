# Makefile for AWS Lambda + S3 + CloudWatch Terraform Module

.PHONY: help init plan apply destroy validate fmt lint clean test-example basic-example advanced-example

# Default target
help:
	@echo "Available targets:"
	@echo "  init           - Initialize Terraform"
	@echo "  plan           - Plan Terraform changes"
	@echo "  apply          - Apply Terraform changes"
	@echo "  destroy        - Destroy Terraform resources"
	@echo "  validate       - Validate Terraform configuration"
	@echo "  fmt            - Format Terraform code"
	@echo "  lint           - Lint Terraform code with tflint"
	@echo "  clean          - Clean up temporary files"
	@echo "  test-example   - Deploy test example"
	@echo "  basic-example  - Deploy basic example"
	@echo "  advanced-example - Deploy advanced example"

# Initialize Terraform
init:
	terraform init

# Plan Terraform changes
plan:
	terraform plan

# Apply Terraform changes
apply:
	terraform apply -auto-approve

# Destroy Terraform resources
destroy:
	terraform destroy -auto-approve

# Validate Terraform configuration
validate:
	terraform validate

# Format Terraform code
fmt:
	terraform fmt -recursive

# Lint Terraform code (requires tflint)
lint:
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init; \
		tflint; \
	else \
		echo "tflint not found. Install from https://github.com/terraform-linters/tflint"; \
	fi

# Clean up temporary files
clean:
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f *.tfstate
	rm -f *.tfstate.backup
	rm -f lambda_function.zip
	find . -name "*.tfstate*" -delete
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true

# Test example deployment
test-example:
	@echo "Deploying test example..."
	cd test && \
	terraform init && \
	terraform plan && \
	terraform apply -auto-approve

# Basic example deployment
basic-example:
	@echo "Deploying basic example..."
	cd examples/basic && \
	terraform init && \
	terraform plan && \
	terraform apply -auto-approve

# Advanced example deployment
advanced-example:
	@echo "Deploying advanced example..."
	cd examples/advanced && \
	terraform init && \
	terraform plan && \
	terraform apply -auto-approve

# Clean up test example
clean-test:
	@echo "Cleaning up test example..."
	cd test && terraform destroy -auto-approve

# Clean up basic example
clean-basic:
	@echo "Cleaning up basic example..."
	cd examples/basic && terraform destroy -auto-approve

# Clean up advanced example
clean-advanced:
	@echo "Cleaning up advanced example..."
	cd examples/advanced && terraform destroy -auto-approve

# Clean up all examples
clean-all: clean-test clean-basic clean-advanced

# Check prerequisites
check-prereqs:
	@echo "Checking prerequisites..."
	@command -v terraform >/dev/null 2>&1 || { echo "terraform is required but not installed. Aborting." >&2; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "aws CLI is required but not installed. Aborting." >&2; exit 1; }
	@echo "Prerequisites check passed."

# Install development tools
install-dev-tools:
	@echo "Installing development tools..."
	@if command -v brew >/dev/null 2>&1; then \
		brew install terraform tflint; \
	elif command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y terraform; \
		curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash; \
	else \
		echo "Please install terraform and tflint manually"; \
	fi

# Run all validations
validate-all: check-prereqs validate fmt lint
	@echo "All validations passed!"

# Show module outputs
outputs:
	terraform output

# Show module outputs for examples
outputs-test:
	cd test && terraform output

outputs-basic:
	cd examples/basic && terraform output

outputs-advanced:
	cd examples/advanced && terraform output

# Documentation
docs:
	@echo "Generating documentation..."
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table . > README.md.tmp && \
		mv README.md.tmp README.md; \
	else \
		echo "terraform-docs not found. Install with: go install github.com/terraform-docs/terraform-docs@latest"; \
	fi 