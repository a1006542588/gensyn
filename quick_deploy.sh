#!/bin/bash
# 新设备快速部署脚本

echo "==================================="
echo "RL-Swarm 新设备部署脚本"
echo "==================================="
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker Desktop"
    exit 1
fi

echo "✅ Docker 已安装"

# 检查 Docker 内存
DOCKER_MEM=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3}')
echo "📊 Docker 可用内存: ${DOCKER_MEM}GiB"

if [ ! -z "$DOCKER_MEM" ]; then
    MEM_NUM=$(echo $DOCKER_MEM | sed 's/GiB//')
    if (( $(echo "$MEM_NUM < 12" | bc -l) )); then
        echo "⚠️  警告: Docker 内存少于 12GB，建议调整到 16GB"
        echo "   路径: Docker Desktop → Settings → Resources → Memory"
    fi
fi

echo ""
echo "部署选项:"
echo "1. 使用默认配置（适合 GPU 或大内存）"
echo "2. 使用优化配置（推荐，适合 16GB 内存）"
echo ""
read -p "请选择 [1/2]: " choice

case $choice in
    1)
        echo "✅ 使用默认配置"
        CONFIG_PATH="code_gen_exp/config"
        ;;
    2)
        echo "✅ 使用优化配置"
        # 检查优化配置是否存在
        if [ ! -f "user/configs/code-gen-swarm.yaml" ]; then
            echo "📝 复制优化配置..."
            mkdir -p user/configs
            cp code_gen_exp/config/code-gen-swarm.yaml user/configs/
            echo "⚠️  请编辑 user/configs/code-gen-swarm.yaml 应用内存优化"
            echo "   参考: DEPLOY_NEW_DEVICE.md"
        fi
        CONFIG_PATH="configs"
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

echo ""
echo "�� 启动容器..."
echo "📝 启动后请在浏览器打开: http://localhost:3000"
echo ""

docker-compose run --rm -Pit swarm-cpu
