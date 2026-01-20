# Kubernetes 1.31 Makefile

# 包含全局配置
include ../../configs/global.env

# 本地配置覆盖（如果存在）
-include .env

# 组件类型
COMPONENT := k8s
VERSION := 1.31

# 镜像列表文件
IMAGES_FILE := images.txt

# 检查是否需要生成 images.txt
.PHONY: check-images
check-images:
	@if [ ! -f $(IMAGES_FILE) ] || [ ! -s $(IMAGES_FILE) ]; then
		@echo "Generating images.txt for Kubernetes $(VERSION)..."
		@$(MAKE) generate-images
	fi

# 生成 Kubernetes 镜像列表
.PHONY: generate-images
generate-images:
	@echo "Generating images.txt for Kubernetes $(VERSION)..."
	# 从 kubeadm 获取镜像列表
	@echo "Getting images list from kubeadm..."
	@kubeadm config images list --kubernetes-version v$(VERSION).0 > $(IMAGES_FILE) 2>/dev/null || \
	(
		# 如果 kubeadm 不可用，使用默认镜像列表
		@echo "kubeadm not available, using default image list...";
		@cat > $(IMAGES_FILE) << 'EOF'
registry.k8s.io/kube-apiserver:v1.31.0
registry.k8s.io/kube-controller-manager:v1.31.0
registry.k8s.io/kube-scheduler:v1.31.0
registry.k8s.io/kube-proxy:v1.31.0
registry.k8s.io/pause:3.10
registry.k8s.io/etcd:3.5.10-0
registry.k8s.io/coredns/coredns:v1.11.1
EOF
	)
	# 去重排序
	@sort -u $(IMAGES_FILE) -o $(IMAGES_FILE)
	@echo "Generated $(IMAGES_FILE) with $(shell wc -l < $(IMAGES_FILE)) images"

# 拉取镜像
.PHONY: pull
pull:
	@$(MAKE) check-images
	@echo "Pulling Kubernetes $(VERSION) images from $(IMAGES_FILE)..."
	@while read -r IMAGE; do
		@echo "Pulling $$IMAGE..."
		docker pull "$$IMAGE"
	@done < $(IMAGES_FILE)

# 重命名镜像
.PHONY: tag
tag:
	@$(MAKE) check-images
	@echo "Tagging Kubernetes $(VERSION) images..."
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
	@echo "Pushing Kubernetes $(VERSION) images..."
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
	@echo "Cleaning Kubernetes $(VERSION) images..."
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
	@echo "Kubernetes $(VERSION) Image Sync Commands:" 
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