# 节点管理指南

## 快速命令参考

### 基本操作
```bash
cd ~/rl-swarm

# 启动节点
./node_manager.sh start

# 停止节点
./node_manager.sh stop

# 重启节点
./node_manager.sh restart

# 查看状态
./node_manager.sh status

# 查看日志
./node_manager.sh logs

# 查看资源使用
./node_manager.sh stats

# 清理资源
./node_manager.sh clean
```

## 详细说明

### 1. 启动节点 (start)

启动训练节点,会自动:
- 检查 Docker 是否运行
- 构建镜像(首次运行)
- 启动容器
- 等待 Modal 登录

**使用方法:**
```bash
cd ~/rl-swarm
./node_manager.sh start
```

**启动后:**
1. 浏览器打开 http://localhost:3000
2. 创建以太坊钱包(首次运行)
3. 等待训练开始
4. 看到 "Starting round: XXXX/1000000" 表示成功

**注意事项:**
- 首次启动需要 5-10 分钟构建镜像
- 按 `Ctrl+C` 可停止训练
- 停止后数据会保存,下次启动继续训练

---

### 2. 停止节点 (stop)

安全停止所有运行中的容器。

**使用方法:**
```bash
cd ~/rl-swarm
./node_manager.sh stop
```

**停止后:**
- 所有容器被停止并删除
- 训练数据、日志、钱包信息都会保留
- 可随时重新启动

**等效命令:**
```bash
docker-compose down
```

---

### 3. 重启节点 (restart)

先停止后启动,用于应用新配置。

**使用方法:**
```bash
cd ~/rl-swarm
./node_manager.sh restart
```

**使用场景:**
- 修改配置文件后
- 更新代码后
- 容器出现问题时

---

### 4. 查看状态 (status)

查看节点当前状态,包括:
- Docker 容器运行状态
- 网络端口占用情况
- 钱包创建状态
- 节点身份密钥状态

**使用方法:**
```bash
cd ~/rl-swarm
./node_manager.sh status
```

**输出示例:**
```
=== Docker 容器状态 ===
NAMES                    STATUS              PORTS
rl-swarm-ollama-1       Up 2 hours          0.0.0.0:11434->11434/tcp

=== 网络端口 ===
✅ 端口 3000 已占用（Modal 登录服务）

=== 钱包状态 ===
✅ 钱包已创建
   Organization ID: 0x1234...

=== 节点身份 ===
✅ 节点密钥已生成
```

---

### 5. 查看日志 (logs)

查看训练日志,支持三种模式:

**使用方法:**
```bash
cd ~/rl-swarm
./node_manager.sh logs
```

**选项:**
1. **实时日志** - Docker 容器输出(推荐)
2. **WandB 日志** - 训练详细日志
3. **最近 50 行** - 快速查看

**日志位置:**
- Docker 日志: `docker logs <container_name>`
- WandB 日志: `user/logs/wandb/latest-run/files/output.log`

**查看训练进度:**
```bash
# 实时查看
./node_manager.sh logs
# 选择 [1]

# 查找关键信息
grep "Starting round" user/logs/wandb/*/files/output.log
grep "loss" user/logs/wandb/*/files/output.log
```

---

### 6. 查看资源使用 (stats)

监控资源使用情况:
- CPU 使用率
- 内存使用量
- 磁盘占用
- Docker 缓存大小

**使用方法:**
```bash
cd ~/rl-swarm
./node_manager.sh stats
```

**输出示例:**
```
=== Docker 容器资源 ===
CONTAINER      CPU %    MEM USAGE / LIMIT     MEM %
rl-swarm-1     85.2%    10.5GiB / 16GiB      65.6%

=== 磁盘使用 ===
项目目录: 3.2G
日志目录: 1.5G
```

**内存监控:**
如果内存使用接近 100%,可能需要:
- 增加 Docker 内存限制
- 应用更激进的优化配置
- 清理日志和缓存

---

### 7. 清理资源 (clean)

清理不需要的数据,释放磁盘空间。

**使用方法:**
```bash
cd ~/rl-swarm
./node_manager.sh clean
```

**清理选项:**

**[1] 停止并删除容器**
- 删除: 运行中的容器
- 保留: 日志、配置、钱包

**[2] 清理 Docker 镜像缓存**
- 删除: 未使用的镜像和构建缓存
- 可释放: 1-2GB 空间
- 下次启动需重新构建

**[3] 清理训练日志**
- 保留: 最新 3 个训练日志
- 删除: 旧的日志文件
- 可释放: 数百 MB 到几 GB

**[4] 完全清理（危险）**
- 删除: **所有数据，包括钱包！**
- 下次启动需要重新创建钱包
- ⚠️ 谨慎使用！

---

## 常见操作场景

### 场景 1: 每日启动和停止
```bash
# 早上启动
cd ~/rl-swarm
./node_manager.sh start

# 晚上停止
./node_manager.sh stop
```

### 场景 2: 修改配置后重启
```bash
# 编辑配置
vim ~/rl-swarm/user/configs/code-gen-swarm.yaml

# 重启应用配置
./node_manager.sh restart
```

### 场景 3: 查看训练是否正常
```bash
# 查看状态
./node_manager.sh status

# 查看实时日志
./node_manager.sh logs
# 选择 [1]

# 查看资源使用
./node_manager.sh stats
```

### 场景 4: 磁盘空间不足
```bash
# 清理旧日志
./node_manager.sh clean
# 选择 [3]

# 查看清理后的空间
./node_manager.sh stats
```

### 场景 5: 出现问题需要重置
```bash
# 完全重置（会删除钱包！）
./node_manager.sh clean
# 选择 [4]

# 重新部署
curl -fsSL https://raw.githubusercontent.com/a1006542588/gensyn/main/one_click_deploy.sh | bash
```

---

## 故障排除

### 问题 1: 启动失败
```bash
# 检查 Docker 状态
./node_manager.sh status

# 查看错误日志
./node_manager.sh logs

# 重启 Docker Desktop 后重试
./node_manager.sh restart
```

### 问题 2: 内存不足
```bash
# 查看内存使用
./node_manager.sh stats

# 停止节点
./node_manager.sh stop

# 调整 Docker 内存到 16GB
# Docker Desktop → Settings → Resources → Memory

# 重新启动
./node_manager.sh start
```

### 问题 3: 端口被占用
```bash
# 查看端口状态
./node_manager.sh status

# 停止其他占用 3000 端口的服务
lsof -i :3000 | grep LISTEN
kill <PID>

# 重新启动
./node_manager.sh start
```

### 问题 4: 日志过多占用磁盘
```bash
# 查看磁盘使用
./node_manager.sh stats

# 清理旧日志
./node_manager.sh clean
# 选择 [3]
```

---

## 高级用法

### 后台运行节点

如果想让节点在后台持续运行:

```bash
# 使用 screen 或 tmux
screen -S rl-swarm
cd ~/rl-swarm
./node_manager.sh start

# 按 Ctrl+A, D 退出 screen
# 恢复 screen: screen -r rl-swarm
```

### 自动启动脚本

创建自动启动脚本:

```bash
cat > ~/start_rl_swarm.sh << 'SCRIPT'
#!/bin/bash
cd ~/rl-swarm
./node_manager.sh start
SCRIPT

chmod +x ~/start_rl_swarm.sh
```

### 监控训练进度

实时监控训练轮次:

```bash
# 查看最新日志中的训练轮次
watch -n 10 "tail -100 ~/rl-swarm/user/logs/wandb/*/files/output.log | grep 'Starting round'"
```

---

## 文件位置参考

| 文件/目录 | 位置 | 说明 |
|----------|------|------|
| 项目目录 | `~/rl-swarm` | 所有代码和配置 |
| 配置文件 | `user/configs/code-gen-swarm.yaml` | 训练超参数 |
| 钱包数据 | `user/modal-login/userData.json` | 钱包和 API 密钥 |
| 节点密钥 | `user/keys/swarm.pem` | DHT 节点身份 |
| 训练日志 | `user/logs/wandb/` | WandB 日志 |
| 管理脚本 | `node_manager.sh` | 本脚本 |

---

## 获取帮助

```bash
# 显示帮助信息
./node_manager.sh help

# 查看完整文档
cat ~/rl-swarm/NODE_MANAGEMENT.md

# 在线问题反馈
# https://github.com/a1006542588/gensyn/issues
```
