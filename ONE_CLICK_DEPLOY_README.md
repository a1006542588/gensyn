# 🚀 一键部署说明

## 使用方法

### 方式一: 在线一键部署（推荐）

在任何 macOS/Linux 设备上运行:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/rl-swarm/main/one_click_deploy.sh | bash
```

**替换 `YOUR_USERNAME` 为你的 GitHub 用户名**

### 方式二: 手动下载后运行

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/rl-swarm/main/one_click_deploy.sh

# 添加执行权限
chmod +x one_click_deploy.sh

# 运行
./one_click_deploy.sh
```

## 脚本功能

✅ **自动检查依赖**: Git, Docker, Docker 内存配置
✅ **智能克隆项目**: 自动处理已存在的目录
✅ **配置选择**: 默认配置 或 优化配置（16GB 内存）
✅ **一键启动**: 无需手动操作，直接启动训练

## 部署流程

1. **检查环境** - 验证 Git、Docker 是否安装
2. **检查内存** - 警告内存不足的情况
3. **克隆项目** - 从 GitHub 获取最新代码
4. **选择配置** - 默认 或 优化配置
5. **自动生成配置** - 如选择优化配置，自动创建配置文件
6. **启动训练** - 自动启动 Docker 容器

## 配置说明

### 默认配置（选项 1）
- 适合: GPU 训练或 32GB+ 内存
- 内存需求: ~20GB
- 性能: 最佳

### 优化配置（选项 2）
- 适合: CPU 训练，16GB 内存
- 内存需求: ~10-12GB
- 性能: 良好
- 优化项:
  - bfloat16 精度
  - batch_size=1
  - 梯度检查点
  - max_new_tokens=96

## 系统要求

### 必须
- Docker Desktop（内存建议 16GB+）
- Git
- 稳定网络连接

### 推荐
- macOS 或 Linux
- 16GB+ 系统内存
- 20GB+ 磁盘空间

## 常见问题

### Q: Docker 内存不足
**A**: 调整 Docker Desktop:
1. 打开 Docker Desktop
2. Settings → Resources → Memory
3. 调整到 16GB
4. Apply & Restart

### Q: 脚本下载失败
**A**: 检查网络连接，或手动克隆仓库后运行 `./one_click_deploy.sh`

### Q: 端口 3000 被占用
**A**: 停止占用 3000 端口的其他服务，或修改 docker-compose.yaml 中的端口映射

### Q: 想停止训练
**A**: 在容器内按 `Ctrl+C`，或在另一个终端运行:
```bash
cd ~/rl-swarm && docker-compose down
```

## 更新脚本

如果你修改了脚本或配置,在 GitHub 上更新后,用户只需重新运行一键部署命令即可获取最新版本。

## 多设备部署

每台设备都可以独立运行脚本:
- ✅ 自动生成独立的钱包地址
- ✅ 独立的节点 ID
- ✅ 互不冲突
- ✅ 独立获得奖励

## 技术支持

- GitHub Issues: https://github.com/gensyn-ai/rl-swarm/issues
- 官方文档: https://github.com/gensyn-ai/rl-swarm
