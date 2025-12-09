# RL-Swarm 一键部署

> 基于 Gensyn 的分布式强化学习训练节点 - 优化版

## 🚀 快速开始（一行命令）

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/rl-swarm/main/one_click_deploy.sh | bash
```

**记得替换 `YOUR_USERNAME` 为你的 GitHub 用户名!**

## ✨ 特性

- ✅ **一键部署**: 自动检查环境、克隆项目、启动训练
- ✅ **内存优化**: 针对 16GB RAM 的 CPU 训练优化（减少 60-70% 内存使用）
- ✅ **自动配置**: 智能选择默认或优化配置
- ✅ **Docker 集成**: 完整的容器化部署
- ✅ **多设备支持**: 每台设备独立运行、独立奖励

## 📋 系统要求

### 必须
- **Docker Desktop** (内存配置 16GB+)
- **Git**
- **网络连接**

### 推荐
- macOS 或 Linux
- 16GB+ 系统内存
- 20GB+ 可用磁盘空间

## 📖 部署方式

### 方式 1: 在线一键部署（最简单）

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/rl-swarm/main/one_click_deploy.sh | bash
```

### 方式 2: 手动部署

```bash
git clone https://github.com/YOUR_USERNAME/rl-swarm.git
cd rl-swarm
./one_click_deploy.sh
```

### 方式 3: 快速部署（已克隆项目）

```bash
cd rl-swarm
./quick_deploy.sh
```

## 🔧 配置选项

### 默认配置
- 适合: GPU 训练或 32GB+ 内存
- 内存需求: ~20GB
- 训练速度: 最快

### 优化配置（推荐 16GB 内存用户）
- 适合: CPU 训练，16GB 内存
- 内存需求: ~10-12GB
- 训练速度: 良好
- 优化内容:
  - ✅ bfloat16 精度 (~50% 内存节省)
  - ✅ 梯度检查点 (20-50% 内存节省)
  - ✅ batch_size=1
  - ✅ max_new_tokens=96
  - ✅ gradient_accumulation_steps=2

## 📚 详细文档

- [一键部署说明](ONE_CLICK_DEPLOY_README.md) - 在线部署详细指南
- [手动部署指南](DEPLOY_NEW_DEVICE.md) - 逐步部署教程
- [内存优化方案](MEMORY_FIX.md) - Docker 内存配置

## 🎯 使用流程

1. **运行脚本** - 执行一键部署命令
2. **选择配置** - 根据硬件选择配置方案
3. **等待启动** - 自动下载镜像并启动容器
4. **完成登录** - 浏览器访问 http://localhost:3000
5. **开始训练** - 创建钱包后自动开始训练

## 🛠️ 常见问题

### Docker 内存不足
```bash
# 调整 Docker Desktop 内存
# Settings → Resources → Memory → 16GB
# Apply & Restart
```

### 端口 3000 被占用
```bash
# 停止其他占用 3000 端口的服务
# 或修改 docker-compose.yaml 中的端口映射
```

### 停止训练
```bash
# 方式 1: 在容器内按 Ctrl+C
# 方式 2: 在另一个终端
cd ~/rl-swarm
docker-compose down
```

### 查看训练日志
```bash
# 查看容器日志
docker logs rl-swarm-swarm-cpu-1 -f

# 或查看本地日志
tail -f ~/rl-swarm/user/logs/wandb/latest-run/files/output.log
```

## 📊 性能对比

| 配置 | 内存使用 | 训练速度 | 适用场景 |
|------|---------|---------|---------|
| 默认配置 | ~20GB | 最快 | GPU/32GB+ RAM |
| 优化配置 | ~10-12GB | 良好 | CPU/16GB RAM |

## 🔄 更新部署

重新运行一键部署命令会自动获取最新代码:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/rl-swarm/main/one_click_deploy.sh | bash
```

## 🌟 贡献

欢迎提交 Issue 和 Pull Request!

## 📝 许可证

查看原项目: [gensyn-ai/rl-swarm](https://github.com/gensyn-ai/rl-swarm)

## 🙏 致谢

- 基于 [Gensyn RL-Swarm](https://github.com/gensyn-ai/rl-swarm)
- 内存优化方案由社区贡献

---

**记得在推送到 GitHub 后,将 `YOUR_USERNAME` 替换为你的真实 GitHub 用户名!**
