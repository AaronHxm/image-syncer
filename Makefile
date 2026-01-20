# 根目录 Makefile

# 默认目标
.DEFAULT_GOAL := help

# 全局配置
CONFIG_DIR := configs
CONFIG_FILE := $(CONFIG_DIR)/global.env

# 并发数量（默认4）
PARALLEL ?= 4

# 是否开启 dry-run 模式
DRY_RUN ?= false

# 检查配置文件是否存在
ifeq ($(wildcard $(CONFIG_FILE)),)
    $(error Configuration file not found: $(CONFIG_FILE))
endif

# 包含全局配置
include $(CONFIG_FILE)

# 生成器目录
GENERATOR_DIR := generator

# 递归查找所有子目录的 Makefile，排除当前目录
SUB_DIRS := $(shell find . -mindepth 2 -name "Makefile" -not -path "./$(GENERATOR_DIR)/*" -not -path "./$(CONFIG_DIR)/*" -not -path "./.*" -exec dirname {} \; | sort -u)

# 递归执行子目录的 make 命令
.PHONY: recursive
recursive:
	if [ -z "$(COMMAND)" ]; then \
		echo "Error: COMMAND is required!"; \
		echo "Usage: make recursive COMMAND=<command>"; \
		echo "Example: make recursive COMMAND=pull"; \
		exit 1; \
	fi
	echo "Executing 'make $(COMMAND)' in all subdirectories..."
	if [ "$(DRY_RUN)" = "true" ]; then \
		for dir in $(SUB_DIRS); do \
			echo "[DRY-RUN] Would execute: cd $$dir && make $(COMMAND)"; \
		done; \
	else \
		if [ "$(PARALLEL)" -gt 1 ]; then \
			echo "Running in parallel mode with $(PARALLEL) jobs..."; \
			echo $(SUB_DIRS) | xargs -n 1 -P $(PARALLEL) sh -c 'echo "Processing $$0..."; cd $$0 && make $(COMMAND)'; \
		else \
			for dir in $(SUB_DIRS); do \
				echo "Processing $$dir..."; \
				cd $$dir && make $(COMMAND); \
			done; \
		fi; \
	fi

# 同步所有镜像（默认命令）
.PHONY: sync
sync:
	@$(MAKE) recursive COMMAND=sync

# 拉取所有镜像
.PHONY: pull
pull:
	@$(MAKE) recursive COMMAND=pull

# 重命名所有镜像
.PHONY: tag
tag:
	@$(MAKE) recursive COMMAND=tag

# 推送所有镜像
.PHONY: push
push:
	@$(MAKE) recursive COMMAND=push

# 生成所有镜像列表
.PHONY: generate
generate:
	@$(MAKE) recursive COMMAND=generate-images

# 清理所有本地镜像
.PHONY: clean
clean:
	@$(MAKE) recursive COMMAND=clean

# 调用 generator 创建版本目录
.PHONY: create
create:
	if [ -z "$(TARGET)" ] || [ -z "$(VERSION)" ]; then \
		echo "Error: TARGET and VERSION are required!"; \
		echo "Usage: make create TARGET=<target> VERSION=<version>"; \
		echo "Example: make create TARGET=k8s VERSION=1.31"; \
		exit 1; \
	fi
	echo "Creating version directory for $(TARGET)/$(VERSION)..."
	cd $(GENERATOR_DIR) && make create TARGET=$(TARGET) VERSION=$(VERSION)

# 帮助信息
.PHONY: help
help:
	@echo "Image Sync Tool - Root Makefile"
	@echo "=================================="
	@echo ""
	@echo "Global Options:"
	@echo "  PARALLEL=<number>  Number of parallel jobs (default: 4)"
	@echo "  DRY_RUN=true       Enable dry-run mode (show commands without executing)"
	@echo ""
	@echo "Main Commands:"
	@echo "  make sync          Sync all images (pull, tag, push)"
	@echo "  make pull          Pull all images"
	@echo "  make tag           Tag all images"
	@echo "  make push          Push all images"
	@echo "  make generate      Generate images.txt for all versions"
	@echo "  make clean         Clean all local images"
	@echo "  make create TARGET=<target> VERSION=<version>  Create a new version directory"
	@echo "  make help          Show this help message"
	@echo ""
	@echo "Recursive Commands:"
	@echo "  make recursive COMMAND=<command>  Execute any command in all subdirectories"
	@echo "  Example: make recursive COMMAND=pull PARALLEL=8 DRY_RUN=true"
	@echo ""
	@echo "Subdirectories Found: $(words $(SUB_DIRS))"
	@echo "$(SUB_DIRS)" | grep -q . && echo "  $(SUB_DIRS)" || true
	@echo ""
	@echo "Examples:"
	@echo "  # Sync all images in parallel with 8 jobs"
	@echo "  make sync PARALLEL=8"
	@echo ""
	@echo "  # Show what would happen without executing"
	@echo "  make sync DRY_RUN=true"
	@echo ""
	@echo "  # Create a new Kubernetes 1.32 directory"
	@echo "  make create TARGET=k8s VERSION=1.32"
	@echo ""
	@echo "  # Generate images.txt for all versions"
	@echo "  make generate"
	@echo ""