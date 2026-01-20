# 子目录 Makefile

# 包含全局配置
include ../../configs/global.env

# 本地配置覆盖（如果存在）
-include .env

# 镜像列表文件
IMAGES_FILE := images.txt

# 检查是否需要生成 images.txt
.PHONY: check-images
theck-images:
	@if [ ! -f $(IMAGES_FILE) ] || [ ! -s $(IMAGES_FILE) ]; then
		@echo "Generating images.txt..."
		@$(MAKE) generate-images
	fi

# 生成镜像列表（占位符，实际实现根据组件类型）
.PHONY: generate-images
generate-images:
	@echo "Generating images.txt for $(TARGET) $(VERSION)..."
	# 这里根据不同组件类型实现不同的镜像获取逻辑
	# 例如：对于 Kubernetes，从 kubeadm 获取镜像列表
	# 对于 ArgoCD，从官方 install.yaml 解析
	# 对于单 Docker 服务，从配置获取
	@echo "k8s.gcr.io/kube-apiserver:v$(VERSION).0" > $(IMAGES_FILE)
	@echo "k8s.gcr.io/kube-controller-manager:v$(VERSION).0" >> $(IMAGES_FILE)
	@echo "k8s.gcr.io/kube-scheduler:v$(VERSION).0" >> $(IMAGES_FILE)
	@echo "k8s.gcr.io/kube-proxy:v$(VERSION).0" >> $(IMAGES_FILE)
	@echo "k8s.gcr.io/pause:3.9" >> $(IMAGES_FILE)
	@echo "coredns/coredns:v1.10.1" >> $(IMAGES_FILE)
	# 去重排序
	@sort -u $(IMAGES_FILE) -o $(IMAGES_FILE)

# 拉取镜像
.PHONY: pull
pull:
	@$(MAKE) check-images
	@echo "Pulling images from $(IMAGES_FILE)..."
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
	@echo "Tagging images..."
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
	@echo "Pushing images..."
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
	@echo "Cleaning local images..."
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

# 默认目标
.DEFAULT_GOAL := sync
