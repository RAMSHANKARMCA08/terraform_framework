SHELL := /bin/bash

ENV ?= dev
TF ?= terraform
ENV_DIR := environments/$(ENV)
WORKLOAD_DIR := workloads/$(ENV)

.PHONY: help fmt validate lint security docs init plan apply destroy workload-init workload-plan workload-apply workload-destroy

help:
	@echo "Usage: make <target> ENV=<dev|stage|prod>"
	@echo "Platform: init plan apply destroy"
	@echo "Workloads: workload-init workload-plan workload-apply workload-destroy"

fmt:
	$(TF) fmt -recursive

init:
	cd $(ENV_DIR) && $(TF) init -upgrade

validate: init
	cd $(ENV_DIR) && $(TF) validate

lint:
	tflint --recursive

security:
	tfsec .

docs:
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/vpc > cloud/aws/modules/vpc/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/eks > cloud/aws/modules/eks/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/eks-node-group > cloud/aws/modules/eks-node-group/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/iam > cloud/aws/modules/iam/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/security-groups > cloud/aws/modules/security-groups/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/alb-controller > cloud/aws/modules/alb-controller/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/ecr > cloud/aws/modules/ecr/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/app > cloud/aws/modules/app/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/cluster-autoscaler > cloud/aws/modules/cluster-autoscaler/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/external-dns > cloud/aws/modules/external-dns/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/route53-zone > cloud/aws/modules/route53-zone/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/terraform-state > cloud/aws/modules/terraform-state/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/vpc-endpoints > cloud/aws/modules/vpc-endpoints/README.md
	terraform-docs markdown table --config .terraform-docs.yml cloud/aws/modules/waf > cloud/aws/modules/waf/README.md

plan: init
	cd $(ENV_DIR) && $(TF) plan -var-file=terraform.tfvars

apply: init
	cd $(ENV_DIR) && $(TF) apply -var-file=terraform.tfvars

destroy: init
	cd $(ENV_DIR) && $(TF) destroy -var-file=terraform.tfvars

workload-init:
	cd $(WORKLOAD_DIR) && $(TF) init

workload-plan: workload-init
	cd $(WORKLOAD_DIR) && $(TF) plan -var-file=../../environments/$(ENV)/terraform.tfvars

workload-apply: workload-init
	cd $(WORKLOAD_DIR) && $(TF) apply -var-file=../../environments/$(ENV)/terraform.tfvars

workload-destroy: workload-init
	cd $(WORKLOAD_DIR) && $(TF) destroy -var-file=../../environments/$(ENV)/terraform.tfvars
