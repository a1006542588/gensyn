#!/bin/bash
# RL-Swarm 一键部署脚本
# 使用方法: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/rl-swarm/main/one_click_deploy.sh | bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║            RL-Swarm 一键部署脚本                          ║
║            Gensyn 分布式强化学习训练                      ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# 检查 Git
echo -e "${BLUE}[1/6] 检查依赖...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git 未安装${NC}"
    echo ""
    echo -e "${YELLOW}请按以下步骤安装 Git:${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${BLUE}macOS 用户:${NC}"
        echo "  1. 打开终端"
        echo "  2. 运行: xcode-select --install"
        echo "  3. 按照提示完成安装"
        echo ""
        echo "或使用 Homebrew 安装: brew install git"
    else
        echo -e "${BLUE}Linux 用户:${NC}"
        echo "  Ubuntu/Debian: sudo apt-get update && sudo apt-get install git"
        echo "  CentOS/RHEL:   sudo yum install git"
        echo "  Fedora:        sudo dnf install git"
    fi
    echo ""
    echo "安装完成后，请重新运行此脚本"
    exit 1
fi
echo -e "${GREEN}✅ Git 已安装${NC}"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装${NC}"
    echo ""
    echo -e "${YELLOW}请按以下步骤安装 Docker Desktop:${NC}"
    echo ""
    echo -e "${BLUE}步骤 1: 下载 Docker Desktop${NC}"
    echo "  访问: https://www.docker.com/products/docker-desktop"
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${BLUE}步骤 2: macOS 安装${NC}"
        echo "  1. 下载 Docker.dmg"
        echo "  2. 双击打开 Docker.dmg"
        echo "  3. 将 Docker 拖动到 Applications 文件夹"
        echo "  4. 打开 Docker Desktop"
        echo "  5. 等待 Docker 启动完成（顶部菜单栏会显示鲸鱼图标）"
    else
        echo -e "${BLUE}步骤 2: Linux 安装${NC}"
        echo "  请访问官方文档: https://docs.docker.com/engine/install/"
        echo "  选择你的 Linux 发行版并按照说明安装"
    fi
    echo ""
    echo -e "${BLUE}步骤 3: 配置 Docker 内存（重要！）${NC}"
    echo "  1. 打开 Docker Desktop"
    echo "  2. 点击右上角设置图标 ⚙️"
    echo "  3. 选择 Resources → Advanced"
    echo "  4. 将 Memory 滑块调整到至少 16GB"
    echo "  5. 点击 Apply & Restart"
    echo ""
    echo "安装并启动 Docker Desktop 后，请重新运行此脚本"
    exit 1
fi
echo -e "${GREEN}✅ Docker 已安装${NC}"

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker 未运行${NC}"
    echo ""
    echo -e "${YELLOW}请启动 Docker Desktop:${NC}"
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  1. 打开 Applications 文件夹"
        echo "  2. 双击 Docker 图标"
        echo "  3. 等待顶部菜单栏出现鲸鱼图标"
        echo "  4. 确保鲸鱼图标不再跳动（表示已启动完成）"
    else
        echo "  1. 启动 Docker 服务: sudo systemctl start docker"
        echo "  2. 或启动 Docker Desktop 应用"
    fi
    echo ""
    echo "Docker 启动后，请重新运行此脚本"
    exit 1
fi
echo -e "${GREEN}✅ Docker 正在运行${NC}"

# 检查 Docker 内存
echo -e "${BLUE}[2/6] 检查 Docker 内存配置...${NC}"
DOCKER_MEM=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3}' | sed 's/GiB//')
if [ ! -z "$DOCKER_MEM" ]; then
    echo -e "${BLUE}📊 Docker 可用内存: ${DOCKER_MEM}GB${NC}"
    
    if (( $(echo "$DOCKER_MEM < 12" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${RED}⚠️  警告: Docker 内存不足（当前 ${DOCKER_MEM}GB < 12GB）${NC}"
        echo ""
        echo -e "${YELLOW}训练需要至少 12GB 内存，推荐 16GB 以避免 OOM (Out of Memory) 错误${NC}"
        echo ""
        echo -e "${BLUE}如何调整 Docker 内存:${NC}"
        echo "  1. 打开 Docker Desktop"
        echo "  2. 点击右上角设置图标 ⚙️"
        echo "  3. 选择 Resources → Advanced"
        echo "  4. 将 Memory 滑块拖动到 16GB"
        echo "  5. 点击 Apply & Restart"
        echo "  6. 等待 Docker 重启完成"
        echo ""
        echo -e "${YELLOW}当前内存配置下，训练可能会频繁被系统 Kill${NC}"
        echo ""
        read -p "是否仍要继续部署？[y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}请调整 Docker 内存后重新运行此脚本${NC}"
            exit 1
        fi
        echo -e "${YELLOW}⚠️  继续部署（内存可能不足）${NC}"
    else
        echo -e "${GREEN}✅ Docker 内存配置充足（${DOCKER_MEM}GB ≥ 12GB）${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  无法检测 Docker 内存配置${NC}"
    echo -e "${YELLOW}   请确保 Docker Desktop 内存设置为 16GB${NC}"
fi

# 克隆项目
echo -e "${BLUE}[3/6] 克隆项目...${NC}"
PROJECT_DIR="$HOME/rl-swarm"

if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}⚠️  目录 $PROJECT_DIR 已存在${NC}"
    echo ""
    echo "选项:"
    echo "  [1] 删除并重新克隆（推荐，获取最新版本）"
    echo "  [2] 保留现有目录并更新代码"
    echo "  [3] 取消部署"
    echo ""
    read -p "请选择 [1-3]: " -n 1 -r
    echo
    case $REPLY in
        1)
            echo -e "${BLUE}删除现有目录...${NC}"
            rm -rf "$PROJECT_DIR"
            ;;
        2)
            cd "$PROJECT_DIR"
            echo -e "${BLUE}拉取最新代码...${NC}"
            git fetch origin
            git pull origin main || echo -e "${YELLOW}⚠️  更新失败，使用现有代码${NC}"
            ;;
        *)
            echo -e "${RED}部署已取消${NC}"
            exit 1
            ;;
    esac
fi

if [ ! -d "$PROJECT_DIR" ]; then
    # 从优化的 fork 仓库克隆
    REPO_URL="https://github.com/a1006542588/gensyn.git"
    echo -e "${BLUE}从 $REPO_URL 克隆项目...${NC}"
    echo -e "${YELLOW}提示: 首次克隆约需下载 13MB${NC}"
    
    if git clone "$REPO_URL" "$PROJECT_DIR"; then
        echo -e "${GREEN}✅ 克隆成功${NC}"
    else
        echo -e "${RED}❌ 克隆失败${NC}"
        echo ""
        echo -e "${YELLOW}可能的原因:${NC}"
        echo "  1. 网络连接问题"
        echo "  2. GitHub 访问受限"
        echo ""
        echo -e "${BLUE}解决方案:${NC}"
        echo "  1. 检查网络连接"
        echo "  2. 配置代理: export https_proxy=http://your-proxy:port"
        echo "  3. 或手动克隆: git clone $REPO_URL $PROJECT_DIR"
        exit 1
    fi
fi

cd "$PROJECT_DIR"
echo -e "${GREEN}✅ 项目已准备就绪: $PROJECT_DIR${NC}"

# 选择配置
echo -e "${BLUE}[4/6] 选择配置方案...${NC}"
echo ""
echo -e "${YELLOW}训练配置说明:${NC}"
echo ""
echo "配置方案对比:"
echo "┌────────────┬────────────┬────────────┬─────────────┐"
echo "│   方案     │  内存需求  │  训练速度  │   适用场景  │"
echo "├────────────┼────────────┼────────────┼─────────────┤"
echo "│ 默认配置   │   ~20GB    │    最快    │ GPU/32GB+   │"
echo "│ 优化配置   │ ~10-12GB   │    良好    │ CPU/16GB    │"
echo "└────────────┴────────────┴────────────┴─────────────┘"
echo ""
echo -e "${BLUE}优化配置包含:${NC}"
echo "  • bfloat16 精度 (减少 50% 内存)"
echo "  • 梯度检查点 (减少 20-50% 内存)"
echo "  • batch_size=1, max_new_tokens=96"
echo "  • 总计减少约 60-70% 内存使用"
echo ""
echo "请选择配置方案:"
echo "  [1] 默认配置"
echo "  [2] 优化配置（推荐）"
echo ""
read -p "请选择 [1/2] (默认: 2): " config_choice
config_choice=${config_choice:-2}

case $config_choice in
    2)
        echo -e "${GREEN}✅ 使用优化配置${NC}"
        mkdir -p user/{configs,keys,logs,modal-login}
        
        if [ -f "user/configs/code-gen-swarm.yaml" ]; then
            echo -e "${YELLOW}配置文件已存在，跳过${NC}"
        else
            echo -e "${BLUE}创建优化配置文件...${NC}"
            cat > user/configs/code-gen-swarm.yaml << 'YAML_EOF'
log_dir: ${oc.env:ROOT,.}/logs

hydra:
  run:
    dir: ${log_dir}
  job_logging:
    handlers:
      console:
        level: INFO
    root:
      level: DEBUG

training:
  max_round: 1000000
  max_stage: 1
  hf_push_frequency: 1
  num_generations: 2  # GRPO 要求至少2 (必须 > 1)
  num_transplant_trees: 1
  seed: 42
  dtype: 'bfloat16'  # 减少 50% 内存
  max_new_tokens: 96  # 16GB 内存可支持 96 tokens

reward_config:
  ollama_model: qwen2.5-coder:1.5b-instruct
  temperature: 0.0
  num_predict: 256

blockchain:
  alchemy_url: "https://gensyn-testnet.g.alchemy.com/public"
  swarm_contract_address: ${oc.env:SWARM_CONTRACT,null}
  org_id: ${oc.env:ORG_ID,null}
  mainnet_chain_id: 685685
  modal_proxy_url: "http://localhost:3000/api/"
  swarm_coordinator_abi_path: "code_gen_exp/contracts/SwarmCoordinator_0.4.2.json"

eval:
  judge_base_url: "https://codezero-judge.gensyn.ai"

game_manager:
  _target_: code_gen_exp.src.manager.SwarmGameManager
  max_stage: ${training.max_stage}
  max_round: ${training.max_round}
  log_dir: ${log_dir}
  hf_token: ${oc.env:HUGGINGFACE_ACCESS_TOKEN,null}
  hf_push_frequency: ${training.hf_push_frequency}
  rewards_ollama_model: ${reward_config.ollama_model}
  run_mode: "train_and_evaluate"
  game_state: 
    _target_: genrl.state.game_state.GameState
    round: 0
    stage: 0
  trainer:
    _target_: code_gen_exp.src.trainer.GRPOTrainerModule
    models:
      - _target_: transformers.AutoModelForCausalLM.from_pretrained
        pretrained_model_name_or_path: ${oc.env:MODEL_NAME, ${gpu_model_choice:${default_large_model_pool},${default_small_model_pool}}} 
    config:
      _target_: genrl.trainer.grpo_trainer.GRPOTrainerConfig
      dtype: ${training.dtype}
      epsilon: 0.2
      epsilon_high: 0.28
      max_new_tokens: ${training.max_new_tokens}
      num_generations: ${training.num_generations}
      enable_gradient_checkpointing: true  # 节省 20-50% 内存
      gradient_accumulation_steps: 2
      learning_rate: 1e-6  # 16GB 内存可用更高学习率
      minibatch_size: 1
    log_with: wandb
    log_dir: ${log_dir}
    judge_base_url: ${eval.judge_base_url}
  reward_manager:
    _target_: genrl.rewards.DefaultRewardManager
    reward_fn_store:
      _target_: genrl.rewards.reward_store.RewardFnStore
      max_rounds: ${training.max_round}
      reward_fn_stores:
        - _target_: genrl.rewards.reward_store.RoundRewardFnStore
          num_stages: ${training.max_stage}
          reward_fns:
            - _target_: code_gen_exp.src.solver_rewards.CodeGenerationRewards
              solver_tokenizer_path: ${game_manager.trainer.models.0.pretrained_model_name_or_path}
              solver_token_lim: ${training.max_new_tokens}
              ollama_config:
                _target_: code_gen_exp.src.solver_rewards.RewardsOllamaConfig
                model: ${reward_config.ollama_model}
                temperature: ${reward_config.temperature}
                num_predict: ${reward_config.num_predict}
  data_manager:
    _target_: code_gen_exp.src.solver_data.CodeGenerationDataManager
    system_prompt: 'solver'
    batch_size: 1
    local_batch_size: 1
    proposer_batch_size: 0
    num_generations: ${training.num_generations}
    num_transplant_trees: 1
  communication_kwargs:
    identity_path: ${oc.env:IDENTITY_PATH,/home/gensyn/rl_swarm/keys/swarm.pem}
    startup_timeout: 300
    beam_size: 10
    get_retries: 3
  coordinator:
    _target_: code_gen_exp.src.coordinator.ModalSwarmCoordinator
    web3_url: ${blockchain.alchemy_url}
    contract_address: ${blockchain.swarm_contract_address}
    org_id: ${blockchain.org_id}
    modal_proxy_url: ${blockchain.modal_proxy_url}
    swarm_coordinator_abi_json: ${blockchain.swarm_coordinator_abi_path}

default_large_model_pool: 
  - deepseek-ai/deepseek-coder-1.3b-instruct
  - Qwen/Qwen2.5-Coder-1.5B-Instruct

default_small_model_pool:
  - Qwen/Qwen2.5-Coder-0.5B-Instruct

proposer:
  _target_: code_gen_exp.src.proposer_service.ProposerService
  service_config:
    _target_: code_gen_exp.src.proposer_service.ProposerServiceConfig
    model: ${oc.env:MODEL_NAME, ${gpu_model_choice:${default_large_model_pool},${default_small_model_pool}}} 
    num_proposals: 2
    train_batch_size: 1
    identity_path: ${oc.env:IDENTITY_PATH,/home/gensyn/rl_swarm/keys/swarm.pem}
    startup_timeout: 120
    beam_size: 10
    get_retries: 0
  ppo_config:
    _target_: code_gen_exp.src.proposer.PPOConfig
  vllm_config:
    _target_: code_gen_exp.src.proposer.VllmConfig
  coordinator:
    _target_: code_gen_exp.src.coordinator.ModalSwarmCoordinator
    web3_url: ${blockchain.alchemy_url}
    contract_address: ${blockchain.swarm_contract_address}
    org_id: ${blockchain.org_id}
    modal_proxy_url: ${blockchain.modal_proxy_url}
    swarm_coordinator_abi_json: ${blockchain.swarm_coordinator_abi_path}
YAML_EOF
            echo -e "${GREEN}✅ 优化配置已创建${NC}"
        fi
        USE_OPTIMIZED=true
        ;;
    *)
        echo -e "${GREEN}✅ 使用默认配置${NC}"
        mkdir -p user/{configs,keys,logs,modal-login}
        USE_OPTIMIZED=false
        ;;
esac

# 拉取 Docker 镜像
echo -e "${BLUE}[5/6] 准备 Docker 环境...${NC}"
echo ""
echo -e "${YELLOW}首次运行需要构建 Docker 镜像${NC}"
echo -e "${YELLOW}• 下载基础镜像: ~1GB${NC}"
echo -e "${YELLOW}• 安装 Python 依赖: ~1GB${NC}"
echo -e "${YELLOW}• 预计耗时: 5-10 分钟（取决于网络速度）${NC}"
echo ""
echo -e "${BLUE}请耐心等待...${NC}"

# 显示启动信息
echo ""
echo -e "${BLUE}[6/6] 启动训练节点...${NC}"
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}║              🚀 RL-Swarm 训练节点启动中                  ║${NC}"
echo -e "${GREEN}║                                                           ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}接下来会发生什么:${NC}"
echo ""
echo "  1️⃣  Docker 构建镜像（首次运行需要 5-10 分钟）"
echo "  2️⃣  容器启动，显示欢迎界面"
echo "  3️⃣  提示打开浏览器访问 ${BLUE}http://localhost:3000${NC}"
echo "  4️⃣  在浏览器中创建以太坊钱包（自动生成）"
echo "  5️⃣  钱包创建完成后，训练自动开始"
echo "  6️⃣  看到类似 \"Starting round: XXXX/1000000\" 表示训练成功"
echo ""
echo -e "${YELLOW}重要提示:${NC}"
echo "  • 浏览器打开 ${BLUE}http://localhost:3000${NC} 完成钱包创建"
echo "  • 钱包信息会保存在 user/modal-login/ 目录"
echo "  • 按 ${RED}Ctrl+C${NC} 可随时停止训练"
echo "  • 训练日志在 user/logs/ 目录"
echo ""
echo -e "${GREEN}准备启动...${NC}"
sleep 3

# 启动容器
echo -e "${BLUE}正在启动 Docker 容器...${NC}"
echo ""
docker-compose run --rm -Pit swarm-cpu

# 如果容器退出，显示提示
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}训练已停止${NC}"
echo ""
echo -e "${BLUE}常用命令:${NC}"
echo "  • 重新启动: cd ~/rl-swarm && docker-compose run --rm -Pit swarm-cpu"
echo "  • 查看日志: cd ~/rl-swarm && tail -f user/logs/wandb/latest-run/files/output.log"
echo "  • 清理容器: cd ~/rl-swarm && docker-compose down"
echo ""
echo -e "${BLUE}获取帮助:${NC}"
echo "  • 查看文档: cat ~/rl-swarm/ONE_CLICK_DEPLOY_README.md"
echo "  • 问题反馈: https://github.com/a1006542588/gensyn/issues"
echo -e "${YELLOW}═══════════════════════════════════════════════════${NC}"
