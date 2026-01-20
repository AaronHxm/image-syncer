# Image Sync Tool - 云原生镜像同步工具

一个标准化、工程化、可扩展的镜像同步工具，用于将国外镜像批量同步到国内镜像仓库，支持离线部署、内网环境、受限网络场景。

## 项目背景

在私有化部署云原生组件（如 Kubernetes、ArgoCD、Istio、Prometheus 等）时，经常因为网络限制，无法直接从国外镜像仓库（Docker Hub、gcr.io、k8s.gcr.io、quay.io 等）拉取镜像。因此需要一个可靠的镜像同步工具，将国外镜像批量同步到国内镜像仓库（如阿里云、腾讯云、自建 Harbor）。

## 核心目标

- 自动获取指定版本组件所需的全部镜像列表
- 将镜像从国外仓库批量同步至国内仓库
- 所有操作统一通过 Makefile 标准入口管理
- 每一个版本/组件都有独立目录，便于版本隔离与维护
- 支持镜像路径“扁平化”以适配阿里云个人仓库
- 可配置镜像源、目标仓库、账号密码
- 支持在根目录一键同步所有子项目
- 支持自动化生成新版本目录结构

## 目录结构

```
image-sync/
├── generator/           # 版本目录生成器
├── configs/             # 全局配置
│   └── global.env       # 目标仓库、账号密码等配置
├── k8s/                 # Kubernetes 镜像
│   ├── 1.31/            # 版本目录
│   └── 1.32/
├── argocd/              # ArgoCD 镜像
│   ├── 2.10/
│   └── 2.11/
├── docker/              # Docker 镜像
│   └── redis/
│       └── 7.0.0/
└── Makefile             # 根目录统一入口
```

## 快速开始

### 1. 配置目标仓库

编辑 `configs/global.env` 文件，配置目标仓库信息：

```env
# 目标仓库地址
TARGET_REGISTRY=registry.cn-hangzhou.aliyuncs.com

# 命名空间
TARGET_NAMESPACE=your-namespace

# 仓库账号
TARGET_USERNAME=your-username

# 仓库密码
TARGET_PASSWORD=your-password

# 是否开启目录扁平化（适配阿里云个人仓库）
FLATTEN_PATH=true
```

### 2. 创建版本目录

使用 generator 自动创建版本目录：

```bash
# 创建 Kubernetes 1.33 版本目录
make create TARGET=k8s VERSION=1.33

# 创建 ArgoCD 2.12 版本目录
make create TARGET=argocd VERSION=2.12

# 创建 Redis 7.2.0 版本目录
make create TARGET=docker/redis VERSION=7.2.0
```

### 3. 生成镜像列表

自动生成 `images.txt` 文件：

```bash
# 生成所有版本的 images.txt
make generate

# 或者进入特定目录单独生成
cd k8s/1.33 && make generate-images
```

### 4. 同步镜像

```bash
# 同步所有镜像（拉取、重命名、推送）
make sync

# 并发同步，使用 8 个并行任务
make sync PARALLEL=8

# 只同步特定组件
cd argocd/2.12 && make sync

# 预览同步操作，不实际执行
make sync DRY_RUN=true
```

## 核心功能

### 1. 自动生成 images.txt

- **Kubernetes**：从 kubeadm 获取镜像列表或使用默认列表
- **ArgoCD**：从官方 install.yaml 解析或使用默认列表
- **单 Docker 服务**：直接指定源镜像
- 自动去重和排序

### 2. 镜像同步流程

```
拉取镜像 → 重命名镜像 → 推送至目标仓库
```

#### 主要命令

| 命令 | 描述 | 执行范围 |
|------|------|----------|
| `make pull` | 拉取镜像 | 当前目录或所有子目录 |
| `make tag` | 重命名镜像 | 当前目录或所有子目录 |
| `make push` | 推送镜像 | 当前目录或所有子目录 |
| `make sync` | 完整同步流程 | 当前目录或所有子目录 |
| `make clean` | 清理本地镜像 | 当前目录或所有子目录 |

### 3. 镜像路径扁平化

当 `FLATTEN_PATH=true` 时，自动将镜像路径扁平化，替换 `/`、`.`、`_` 为 `-`，适配阿里云个人仓库不支持多级目录的限制。

**示例**：
- 原镜像：`registry.k8s.io/kube-apiserver:v1.31.0`
- 扁平化后：`registry_cn-hangzhou_aliyuncs_com/your-namespace/registry_k8s_io_kube-apiserver:v1.31.0`

### 4. 版本目录管理

- 每个版本对应一个独立目录
- 目录自动生成，包含：
  - `Makefile`：组件特定的同步逻辑
  - `images.txt`：自动生成的镜像列表
  - `.env.example`：本地配置示例

### 5. 并发执行

支持并发同步多个版本的镜像，提高同步效率：

```bash
# 使用 4 个并行任务（默认）
make sync

# 使用 8 个并行任务
make sync PARALLEL=8
```

### 6. Dry-Run 模式

预览同步操作，不实际执行，便于验证配置：

```bash
make sync DRY_RUN=true
make pull DRY_RUN=true
make generate DRY_RUN=true
```

## 详细使用指南

### 根目录命令

| 命令 | 描述 | 示例 |
|------|------|------|
| `make help` | 显示帮助信息 | `make help` |
| `make sync` | 同步所有镜像 | `make sync PARALLEL=8` |
| `make pull` | 拉取所有镜像 | `make pull DRY_RUN=true` |
| `make tag` | 重命名所有镜像 | `make tag` |
| `make push` | 推送所有镜像 | `make push` |
| `make generate` | 生成所有 images.txt | `make generate` |
| `make clean` | 清理所有本地镜像 | `make clean` |
| `make create` | 创建新版本目录 | `make create TARGET=k8s VERSION=1.33` |
| `make recursive` | 执行自定义命令 | `make recursive COMMAND=help` |

### 子目录命令

进入特定版本目录（如 `k8s/1.33`）后，可以执行：

| 命令 | 描述 |
|------|------|
| `make` | 默认执行 `sync` |
| `make help` | 显示组件特定帮助 |
| `make pull` | 拉取当前版本镜像 |
| `make tag` | 重命名当前版本镜像 |
| `make push` | 推送当前版本镜像 |
| `make sync` | 同步当前版本镜像 |
| `make clean` | 清理当前版本本地镜像 |
| `make generate-images` | 生成当前版本 images.txt |

## 配置说明

### 全局配置

位于 `configs/global.env`，适用于所有组件和版本：

| 配置项 | 描述 | 默认值 |
|--------|------|--------|
| `TARGET_REGISTRY` | 目标镜像仓库地址 | `registry.cn-hangzhou.aliyuncs.com` |
| `TARGET_NAMESPACE` | 目标仓库命名空间 | `your-namespace` |
| `TARGET_USERNAME` | 目标仓库用户名 | `your-username` |
| `TARGET_PASSWORD` | 目标仓库密码 | `your-password` |
| `FLATTEN_PATH` | 是否开启路径扁平化 | `true` |

### 本地配置

在每个版本目录下创建 `.env` 文件，可以覆盖全局配置：

```env
# 示例：本地覆盖配置
TARGET_REGISTRY=your-local-registry
TARGET_NAMESPACE=local-namespace
FLATTEN_PATH=false
```

## 组件支持

### 已支持的组件

| 组件 | 版本 | 镜像获取方式 |
|------|------|--------------|
| Kubernetes | 1.31, 1.32, 1.33+ | kubeadm 或默认列表 |
| ArgoCD | 2.10, 2.11, 2.12+ | 官方 install.yaml 或默认列表 |
| Redis | 7.0.0, 7.2.0+ | 直接指定源镜像 |

### 扩展支持

可以通过以下方式添加新组件：

1. 创建组件目录：`mkdir -p component-name/version`
2. 创建 Makefile，实现 `generate-images` 目标
3. 或者使用 `make create TARGET=component-name VERSION=version` 自动创建

## 最佳实践

1. **版本隔离**：每个版本使用独立目录，便于管理和回滚
2. **配置分离**：全局配置和本地配置分离，便于不同环境使用
3. **定期同步**：定期执行 `make sync` 保持镜像最新
4. **使用 Dry-Run**：在生产环境执行前，先使用 `DRY_RUN=true` 预览
5. **合理设置并发数**：根据网络情况调整 `PARALLEL` 参数
6. **清理本地镜像**：使用 `make clean` 清理不再需要的本地镜像

## 常见问题

### 1. 镜像拉取失败

**原因**：网络问题或源镜像不存在
**解决方法**：
- 检查网络连接
- 确认源镜像是否存在
- 手动修改 `images.txt` 中的镜像地址

### 2. 推送镜像失败

**原因**：目标仓库配置错误或权限不足
**解决方法**：
- 检查 `configs/global.env` 中的配置
- 确认仓库账号密码正确
- 确认有推送权限

### 3. 扁平化路径不生效

**原因**：配置未正确设置
**解决方法**：
- 检查 `FLATTEN_PATH` 配置是否为 `true`
- 确认本地 `.env` 文件没有覆盖全局配置

### 4. kubeadm 不可用

**原因**：未安装 kubeadm 或版本不匹配
**解决方法**：
- 工具会自动使用默认镜像列表
- 可以手动安装对应版本的 kubeadm

## 版本更新日志

### v1.2
- 支持自动生成 images.txt
- 新增扁平化路径功能
- 支持并发同步
- 新增 Dry-Run 模式
- 支持自动化生成版本目录

### v1.1
- 支持 Kubernetes 镜像同步
- 支持 ArgoCD 镜像同步
- 支持单 Docker 服务镜像同步
- 统一 Makefile 入口

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 联系方式

如有问题或建议，欢迎通过 GitHub Issue 反馈。# image-syncer
