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
    echo -e "${RED}❌ Git 未安装，请先安装 Git${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Git 已安装${NC}"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装${NC}"
    echo -e "${YELLOW}请访问 https://www.docker.com/products/docker-desktop 安装 Docker Desktop${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker 已安装${NC}"

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker 未运行，请启动 Docker Desktop${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker 正在运行${NC}"

# 检查 Docker 内存
echo -e "${BLUE}[2/6] 检查 Docker 内存配置...${NC}"
DOCKER_MEM=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3}' | sed 's/GiB//')
if [ ! -z "$DOCKER_MEM" ]; then
    echo -e "${BLUE}📊 Docker 可用内存: ${DOCKER_MEM}GB${NC}"
    
    if (( $(echo "$DOCKER_MEM < 12" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "${YELLOW}⚠️  警告: Docker 内存少于 12GB（当前 ${DOCKER_MEM}GB）${NC}"
        echo -e "${YELLOW}   强烈建议调整到 16GB 以避免 OOM${NC}"
        echo -e "${YELLOW}   设置路径: Docker Desktop → Settings → Resources → Memory${NC}"
        echo ""
        read -p "是否继续部署？[y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}部署已取消${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ Docker 内存配置充足${NC}"
    fi
fi

# 克隆项目
echo -e "${BLUE}[3/6] 克隆项目...${NC}"
PROJECT_DIR="$HOME/rl-swarm"

if [ -d "$PROJECT_DIR" ]; then
    echo -e "${YELLOW}⚠️  目录 $PROJECT_DIR 已存在${NC}"
    read -p "是否删除并重新克隆？[y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_DIR"
    else
        cd "$PROJECT_DIR"
        echo -e "${BLUE}使用现有目录，拉取最新代码...${NC}"
        git pull origin main
    fi
fi

if [ ! -d "$PROJECT_DIR" ]; then
    # 默认从官方仓库克隆，用户可以修改为自己的 fork
    REPO_URL="https://github.com/gensyn-ai/rl-swarm.git"
    echo -e "${BLUE}从 $REPO_URL 克隆...${NC}"
    git clone "$REPO_URL" "$PROJECT_DIR"
fi

cd "$PROJECT_DIR"
echo -e "${GREEN}✅ 项目已准备就绪${NC}"

# 选择配置
echo -e "${BLUE}[4/6] 选择配置方案...${NC}"
echo ""
echo "请选择配置方案:"
echo "  1) 默认配置（适合 GPU 或 32GB+ 内存）"
echo "  2) 优化配置（推荐，适合 16GB 内存的 CPU 训练）"
echo ""
read -p "请选择 [1/2]: " config_choice

case $config_choice in
    2)
        echo -e "${GREEN}✅ 使用优化配置${NC}"
        mkdir -p user/configs
        
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
        USE_OPTIMIZED=false
        ;;
esac

# 拉取 Docker 镜像
echo -e "${BLUE}[5/6] 准备 Docker 环境...${NC}"
echo -e "${YELLOW}提示: 首次运行需要下载约 2GB 镜像，请耐心等待${NC}"

# 显示启动信息
echo -e "${BLUE}[6/6] 启动训练节点...${NC}"
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  启动后请在浏览器打开: ${BLUE}http://localhost:3000${GREEN}     ║${NC}"
echo -e "${GREEN}║  完成钱包创建后，训练将自动开始                          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}提示: 按 Ctrl+C 可以停止训练${NC}"
echo ""
sleep 2

# 启动容器
docker-compose run --rm -Pit swarm-cpu
