# Redis 7.0.0 Makefile

# 包含全局配置
include ../../../configs/global.env

# 本地配置覆盖（如果存在）
-include .env

# 组件类型
COMPONENT := docker/redis
VERSION := 7.0.0

# 镜像列表文件
IMAGES_FILE := images.txt

# 源镜像
SOURCE_IMAGE := redis:$(VERSION)

# 检查是否需要生成 images.txt
.PHONY: check-images
check-images:
	@if [ ! -f $(IMAGES_FILE) ] || [ ! -s $(IMAGES_FILE) ]; then
		@echo "Generating images.txt for Redis $(VERSION)..."
		@$(MAKE) generate-images
	fi

# 生成 Redis 镜像列表（单一镜像）
.PHONY: generate-images
generate-images:
	@echo "Generating images.txt for Redis $(VERSION)..."
	@echo "$(SOURCE_IMAGE)" > $(IMAGES_FILE)
	@echo "Generated $(IMAGES_FILE) with 1 image"

# 拉取镜像
.PHONY: pull
pull:
	@$(MAKE) check-images
	@echo "Pulling Redis $(VERSION) image..."
	@docker pull "$(SOURCE_IMAGE)"

# 重命名镜像
.PHONY: tag
tag:
	@$(MAKE) check-images
	@echo "Tagging Redis $(VERSION) image..."
	
	# 提取镜像名称和标签
	IMAGE_NAME="$(SOURCE_IMAGE)"
	IMAGE_TAG="$(VERSION)"
	
	# 根据 FLATTEN_PATH 决定新镜像名称
	if [ "$(FLATTEN_PATH)" = "true" ]; then
		# 扁平化：替换 / . _ 为 -
		NEW_IMAGE_NAME="redis"
	else
		# 保持原有结构
		NEW_IMAGE_NAME="redis"
	fi
	
	# 构建新镜像路径
	NEW_IMAGE="$(TARGET_REGISTRY)/$(TARGET_NAMESPACE)/$(NEW_IMAGE_NAME):$(IMAGE_TAG)"
	
	@echo "Tagging $(SOURCE_IMAGE) -> $(NEW_IMAGE)"
	@docker tag "$(SOURCE_IMAGE)" "$(NEW_IMAGE)"

# 推送镜像
.PHONY: push
push:
	@$(MAKE) tag
	@echo "Pushing Redis $(VERSION) image..."
	@docker login -u $(TARGET_USERNAME) -p $(TARGET_PASSWORD) $(TARGET_REGISTRY) || true
	
	# 构建新镜像路径
	if [ "$(FLATTEN_PATH)" = "true" ]; then
		NEW_IMAGE_NAME="redis"
	else
		NEW_IMAGE_NAME="redis"
	fi
	NEW_IMAGE="$(TARGET_REGISTRY)/$(TARGET_NAMESPACE)/$(NEW_IMAGE_NAME):$(VERSION)"
	
	@echo "Pushing $(NEW_IMAGE)"
	@docker push "$(NEW_IMAGE)"

# 同步镜像（拉取、重命名、推送）
.PHONY: sync
sync:
	@$(MAKE) pull tag push

# 清理本地镜像
.PHONY: clean
clean:
	@echo "Cleaning Redis $(VERSION) images..."
	@docker rmi -f "$(SOURCE_IMAGE)" 2>/dev/null || true
	
	# 清理标签镜像
	if [ "$(FLATTEN_PATH)" = "true" ]; then
		NEW_IMAGE_NAME="redis"
	else
		NEW_IMAGE_NAME="redis"
	fi
	NEW_IMAGE="$(TARGET_REGISTRY)/$(TARGET_NAMESPACE)/$(NEW_IMAGE_NAME):$(VERSION)"
	@docker rmi -f "$(NEW_IMAGE)" 2>/dev/null || true

# 帮助信息
.PHONY: help
help:
	@echo "Redis $(VERSION) Image Sync Commands:" 
	@echo "  make              Sync images (pull, tag, push)"
	@echo "  make pull         Pull image"
	@echo "  make tag          Tag image"
	@echo "  make push         Push image"
	@echo "  make generate-images  Generate images.txt"
	@echo "  make clean        Clean local images"
	@echo "  make help         Show this help message"
	@echo ""
	@echo "Images: $$(shell [ -f $(IMAGES_FILE) ] && wc -l < $(IMAGES_FILE) || echo 0) images in $(IMAGES_FILE)"
	@echo ""