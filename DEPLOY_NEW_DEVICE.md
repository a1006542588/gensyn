# 新设备部署指南

## 前提条件
- Docker Desktop 已安装并运行
- Docker 内存分配至少 **12GB** (推荐 16GB)
- Git 已安装
- 稳定的网络连接

## 部署步骤

### 1. 克隆项目
```bash
git clone https://github.com/gensyn-ai/rl-swarm.git
cd rl-swarm
```

### 2. 配置 Docker Desktop 内存
1. 打开 Docker Desktop
2. 点击右上角设置图标 ⚙️
3. 选择 **Resources** → **Advanced**
4. 将 **Memory** 滑块设置为 **16GB**
5. 点击 **Apply & Restart**
6. 等待 Docker 重启完成

### 3. 应用优化配置（可选但推荐）
如果你有 16GB 内存限制,应用以下优化配置:

```bash
# 复制优化配置模板
cp code_gen_exp/config/code-gen-swarm.yaml user/configs/code-gen-swarm.yaml
```

然后编辑 `user/configs/code-gen-swarm.yaml`,添加以下优化:

```yaml
training:
  dtype: 'bfloat16'  # 减少 50% 内存
  max_new_tokens: 96  # 平衡质量和内存
  num_generations: 2  # GRPO 最小要求
  num_transplant_trees: 1

game_manager:
  trainer:
    config:
      enable_gradient_checkpointing: true  # 节省 20-50% 内存
      gradient_accumulation_steps: 2
      learning_rate: 1e-6
      minibatch_size: 1
  
  data_manager:
    batch_size: 1
    proposer_batch_size: 0
    
proposer:
  service_config:
    num_proposals: 2
    train_batch_size: 1
```

### 4. 启动训练
```bash
docker-compose run --rm -Pit swarm-cpu
```

### 5. 完成 Modal 登录
1. 容器启动后,浏览器打开 **http://localhost:3000**
2. 使用 **新的钱包地址** 完成注册(不会影响其他设备)
3. 登录完成后,训练自动开始

### 6. 监控训练状态
训练成功启动后,你会看到:
```
[INFO] - 🐝 Hello [节点名称] [节点ID]!
[INFO] - Using Model: Qwen/Qwen2.5-Coder-0.5B-Instruct
[INFO] - Starting round: XXXX/1000000
```

## 关键配置文件说明

### 自动生成的文件（每台设备独立）
- `user/modal-login/userData.json` - 钱包和 API 密钥
- `user/keys/swarm.pem` - DHT 节点身份密钥
- `user/logs/` - 训练日志

### 可复用的配置文件
- `user/configs/code-gen-swarm.yaml` - 训练超参数配置

## 多设备运行说明

✅ **可以同时运行**: 每台设备会:
- 生成独立的钱包地址
- 获得独立的节点 ID
- 独立计算奖励和积分

✅ **配置文件可复用**: 
- `user/configs/code-gen-swarm.yaml` 可以复制到新设备
- 优化参数在所有设备上通用

❌ **不要共享的文件**:
- `user/modal-login/` 目录（包含钱包私钥）
- `user/keys/swarm.pem`（节点身份）

## 常见问题

### Q: 内存不足被 Kill
**A**: 增加 Docker Desktop 内存到 16GB,并应用上述优化配置

### Q: DHT 连接失败 "failed to connect to bootstrap peers"
**A**: 
1. 检查网络连接
2. 增加 `startup_timeout: 300`
3. 确保防火墙允许 Docker 访问外网

### Q: 训练速度慢
**A**: 
- CPU 模式较慢是正常的
- 考虑使用 `swarm-gpu` 服务（需要 NVIDIA GPU）
- 或使用云 GPU 实例

## 停止训练
```bash
# 在容器内按 Ctrl+C
# 或在另一个终端
docker-compose down
```

## 清理数据（可选）
如果需要重置账号:
```bash
rm -rf user/modal-login/*.json
rm -rf user/keys/swarm.pem
```

## 技术支持
- GitHub Issues: https://github.com/gensyn-ai/rl-swarm/issues
- 官方文档: 查看 README.md
