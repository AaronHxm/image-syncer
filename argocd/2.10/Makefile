# ArgoCD 2.10 Makefile

# 包含全局配置
include ../../configs/global.env

# 本地配置覆盖（如果存在）
-include .env

# 组件类型
COMPONENT := argocd
VERSION := 2.10

# 镜像列表文件
IMAGES_FILE := images.txt

# ArgoCD 官方 install.yaml URL
ARGOCD_INSTALL_URL := https://raw.githubusercontent.com/argoproj/argo-cd/v$(VERSION).0/manifests/install.yaml

# 检查是否需要生成 images.txt
.PHONY: check-images
check-images:
	@if [ ! -f $(IMAGES_FILE) ] || [ ! -s $(IMAGES_FILE) ]; then
		@echo "Generating images.txt for ArgoCD $(VERSION)..."
		@$(MAKE) generate-images
	fi

# 生成 ArgoCD 镜像列表
.PHONY: generate-images
generate-images:
	@echo "Generating images.txt for ArgoCD $(VERSION)..."
	# 从官方 install.yaml 解析镜像列表
	@echo "Fetching ArgoCD install.yaml from $(ARGOCD_INSTALL_URL)..."
	@curl -sL $(ARGOCD_INSTALL_URL) | grep -oE 'image: "?([^"\s]+)' | awk -F'[ "]+' '{print $$2}' | grep -v '#' > $(IMAGES_FILE) 2>/dev/null || \
	(
		# 如果 curl 失败，使用默认镜像列表
		@echo "Failed to fetch install.yaml, using default image list...";
		@cat > $(IMAGES_FILE) << 'EOF'
quay.io/argoproj/argocd:v$(VERSION).0
quay.io/argoproj/argocd-applicationset:v$(VERSION).0
quay.io/argoproj/argocd-autopilot:v$(VERSION).0
quay.io/argoproj/argocd-cm:v$(VERSION).0
quay.io/argoproj/argocd-notifications:v$(VERSION).0
quay.io/argoproj/argocd-redis-ha:v$(VERSION).0
quay.io/argoproj/argocd-repo-server:v$(VERSION).0
quay.io/argoproj/argocd-server:v$(VERSION).0
quay.io/argoproj/argocd-dex-server:v$(VERSION).0
quay.io/argoproj/argocd-metrics-server:v$(VERSION).0
quay.io/argoproj/argocd-vault-plugin:v$(VERSION).0
quay.io/argoproj/argocd-image-updater:v$(VERSION).0
EOF
	)
	# 去重排序
	@sort -u $(IMAGES_FILE) -o $(IMAGES_FILE)
	@echo "Generated $(IMAGES_FILE) with $(shell wc -l < $(IMAGES_FILE)) images"

# 拉取镜像
.PHONY: pull
pull:
	@$(MAKE) check-images
	@echo "Pulling ArgoCD $(VERSION) images from $(IMAGES_FILE)..."
	# 登录源仓库（如果配置了源仓库账号密码）
	@if [ -n "$(SOURCE_USERNAME)" ] && [ -n "$(SOURCE_PASSWORD)" ]; then
		@echo "Logging in to source registry..."
		@docker login -u $(SOURCE_USERNAME) -p $(SOURCE_PASSWORD) $(SOURCE_REGISTRY) 2>/dev/null || true
	fi
	@while read -r IMAGE; do
		@echo "Pulling $$IMAGE..."
		docker pull "$$IMAGE"
	@done < $(IMAGES_FILE)

# 重命名镜像
.PHONY: tag
tag:
	@$(MAKE) check-images
	@echo "Tagging ArgoCD $(VERSION) images..."
	@while read -r IMAGE; do
		# 提取镜像名称和标签
		IMAGE_NAME="$$(echo $$IMAGE | cut -d':' -f1)"
		IMAGE_TAG="$$(echo $$IMAGE | cut -d':' -f2)"
		
		# 根据 FLATTEN_PATH 决定新镜像名称
		if [ "$(FLATTEN_PATH)" = "true" ]; then
			# 扁平化：替换 / . _ 为 -
			NEW_IMAGE_NAME="$$(echo $$IMAGE_NAME | sed 's/[\/._]/_/g')"
		else
			# 保持原有结构
			NEW_IMAGE_NAME="$$IMAGE_NAME"
		fi
		
		# 构建新镜像路径
		NEW_IMAGE="$(TARGET_REGISTRY)/$(TARGET_NAMESPACE)/$(NEW_IMAGE_NAME):$(IMAGE_TAG)"
		
		@echo "Tagging $$IMAGE -> $$NEW_IMAGE"
		docker tag "$$IMAGE" "$$NEW_IMAGE"
	@done < $(IMAGES_FILE)

# 推送镜像
.PHONY: push
push:
	@$(MAKE) tag
	@echo "Pushing ArgoCD $(VERSION) images..."
	@docker login -u $(TARGET_USERNAME) -p $(TARGET_PASSWORD) $(TARGET_REGISTRY) || true
	@while read -r IMAGE; do
		IMAGE_NAME="$$(echo $$IMAGE | cut -d':' -f1)"
		IMAGE_TAG="$$(echo $$IMAGE | cut -d':' -f2)"
		
		if [ "$(FLATTEN_PATH)" = "true" ]; then
			NEW_IMAGE_NAME="$$(echo $$IMAGE_NAME | sed 's/[\/._]/_/g')"
		else
			NEW_IMAGE_NAME="$$IMAGE_NAME"
		fi
		
		NEW_IMAGE="$(TARGET_REGISTRY)/$(TARGET_NAMESPACE)/$(NEW_IMAGE_NAME):$(IMAGE_TAG)"
		
		@echo "Pushing $$NEW_IMAGE"
		docker push "$$NEW_IMAGE"
	@done < $(IMAGES_FILE)

# 同步镜像（拉取、重命名、推送）
.PHONY: sync
sync:
	@$(MAKE) pull tag push

# 清理本地镜像
.PHONY: clean
clean:
	@$(MAKE) check-images
	@echo "Cleaning ArgoCD $(VERSION) images..."
	@while read -r IMAGE; do
		@echo "Removing $$IMAGE..."
		docker rmi -f "$$IMAGE" 2>/dev/null || true
		
		IMAGE_NAME="$$(echo $$IMAGE | cut -d':' -f1)"
		IMAGE_TAG="$$(echo $$IMAGE | cut -d':' -f2)"
		
		if [ "$(FLATTEN_PATH)" = "true" ]; then
			NEW_IMAGE_NAME="$$(echo $$IMAGE_NAME | sed 's/[\/._]/_/g')"
		else
			NEW_IMAGE_NAME="$$IMAGE_NAME"
		fi
		
		NEW_IMAGE="$(TARGET_REGISTRY)/$(TARGET_NAMESPACE)/$(NEW_IMAGE_NAME):$(IMAGE_TAG)"
		@echo "Removing $$NEW_IMAGE..."
		docker rmi -f "$$NEW_IMAGE" 2>/dev/null || true
	@done < $(IMAGES_FILE)

# 帮助信息
.PHONY: help
help:
	@echo "ArgoCD $(VERSION) Image Sync Commands:" 
	@echo "  make              Sync images (pull, tag, push)"
	@echo "  make pull         Pull images"
	@echo "  make tag          Tag images"
	@echo "  make push         Push images"
	@echo "  make generate-images  Generate images.txt"
	@echo "  make clean        Clean local images"
	@echo "  make help         Show this help message"
	@echo ""
	@echo "Images: $$(shell [ -f $(IMAGES_FILE) ] && wc -l < $(IMAGES_FILE) || echo 0) images in $(IMAGES_FILE)"
	@echo ""