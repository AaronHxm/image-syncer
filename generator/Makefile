# generator Makefile

# 默认目标
.DEFAULT_GOAL := help

# 创建版本目录
.PHONY: create
create:
	if [ -z "$(TARGET)" ] || [ -z "$(VERSION)" ]; then \
		echo "Error: TARGET and VERSION are required!"; \
		echo "Usage: make create TARGET=<target> VERSION=<version>"; \
		echo "Example: make create TARGET=k8s VERSION=1.31"; \
		exit 1; \
	fi
	./create.sh TARGET=$(TARGET) VERSION=$(VERSION)

# 帮助信息
.PHONY: help
help:
	echo "Generator Commands:"
	echo "  make create TARGET=<target> VERSION=<version>  Create a new version directory structure"
	echo "  make help                                     Show this help message"
	echo ""
	echo "Examples:"
	echo "  make create TARGET=k8s VERSION=1.31"
	echo "  make create TARGET=argocd VERSION=2.10"
	echo "  make create TARGET=docker/redis VERSION=7.0.0"
	echo ""