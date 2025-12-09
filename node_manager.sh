#!/bin/bash
# RL-Swarm 节点管理脚本
# 用于启动、停止、重启和查看训练节点状态

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_DIR="${PROJECT_DIR:-$HOME/rl-swarm}"

# 显示帮助信息
show_help() {
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║              RL-Swarm 节点管理工具                        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo "使用方法: $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  start     - 启动训练节点"
    echo "  stop      - 停止训练节点"
    echo "  restart   - 重启训练节点"
    echo "  status    - 查看节点状态"
    echo "  logs      - 查看训练日志"
    echo "  stats     - 查看资源使用情况"
    echo "  clean     - 清理 Docker 容器和镜像"
    echo "  help      - 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 start         # 启动节点"
    echo "  $0 stop          # 停止节点"
    echo "  $0 logs          # 查看日志"
    echo ""
}

# 检查项目目录
check_project_dir() {
    if [ ! -d "$PROJECT_DIR" ]; then
        echo -e "${RED}❌ 项目目录不存在: $PROJECT_DIR${NC}"
        echo ""
        echo "请先运行部署脚本:"
        echo "  curl -fsSL https://raw.githubusercontent.com/a1006542588/gensyn/main/one_click_deploy.sh | bash"
        exit 1
    fi
    cd "$PROJECT_DIR"
}

# 启动节点
start_node() {
    echo -e "${BLUE}[启动节点]${NC}"
    check_project_dir
    
    echo -e "${YELLOW}检查 Docker 服务...${NC}"
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker 未运行${NC}"
        echo "请启动 Docker Desktop 后重试"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker 运行正常${NC}"
    echo ""
    echo -e "${BLUE}启动训练节点...${NC}"
    echo ""
    echo -e "${YELLOW}提示:${NC}"
    echo "  • 首次启动需要构建 Docker 镜像（5-10 分钟）"
    echo "  • 启动后在浏览器打开 ${BLUE}http://localhost:3000${NC}"
    echo "  • 完成钱包创建后训练自动开始"
    echo "  • 按 ${RED}Ctrl+C${NC} 可停止训练"
    echo ""
    sleep 2
    
    docker-compose run --rm -Pit swarm-cpu
}

# 停止节点
stop_node() {
    echo -e "${BLUE}[停止节点]${NC}"
    check_project_dir
    
    echo -e "${YELLOW}正在停止所有容器...${NC}"
    docker-compose down
    
    echo -e "${GREEN}✅ 节点已停止${NC}"
    echo ""
    echo "重新启动: $0 start"
}

# 重启节点
restart_node() {
    echo -e "${BLUE}[重启节点]${NC}"
    stop_node
    echo ""
    sleep 2
    start_node
}

# 查看状态
show_status() {
    echo -e "${BLUE}[节点状态]${NC}"
    check_project_dir
    
    echo ""
    echo -e "${YELLOW}=== Docker 容器状态 ===${NC}"
    if docker ps -a --filter "name=rl-swarm" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "rl-swarm"; then
        docker ps -a --filter "name=rl-swarm" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo -e "${YELLOW}⚠️  没有运行中的容器${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}=== 网络端口 ===${NC}"
    if lsof -i :3000 &> /dev/null; then
        echo -e "${GREEN}✅ 端口 3000 已占用（Modal 登录服务）${NC}"
        lsof -i :3000 | grep LISTEN || true
    else
        echo -e "${YELLOW}⚠️  端口 3000 未使用${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}=== 钱包状态 ===${NC}"
    if [ -f "$PROJECT_DIR/user/modal-login/userData.json" ]; then
        echo -e "${GREEN}✅ 钱包已创建${NC}"
        if command -v jq &> /dev/null; then
            ORG_ID=$(cat "$PROJECT_DIR/user/modal-login/userData.json" | jq -r '.orgId' 2>/dev/null || echo "unknown")
            echo "   Organization ID: $ORG_ID"
        fi
    else
        echo -e "${YELLOW}⚠️  钱包未创建（需要访问 http://localhost:3000 创建）${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}=== 节点身份 ===${NC}"
    if [ -f "$PROJECT_DIR/user/keys/swarm.pem" ]; then
        echo -e "${GREEN}✅ 节点密钥已生成${NC}"
    else
        echo -e "${YELLOW}⚠️  节点密钥未生成${NC}"
    fi
    
    echo ""
}

# 查看日志
show_logs() {
    echo -e "${BLUE}[训练日志]${NC}"
    check_project_dir
    
    echo ""
    echo "选择日志类型:"
    echo "  [1] 实时日志（Docker 容器）"
    echo "  [2] WandB 训练日志"
    echo "  [3] 最近 50 行日志"
    echo ""
    read -p "请选择 [1-3]: " log_choice
    
    case $log_choice in
        1)
            echo -e "${BLUE}实时日志（按 Ctrl+C 退出）:${NC}"
            echo ""
            CONTAINER=$(docker ps --filter "name=rl-swarm" --format "{{.Names}}" | head -1)
            if [ -z "$CONTAINER" ]; then
                echo -e "${YELLOW}⚠️  没有运行中的容器${NC}"
                exit 1
            fi
            docker logs -f "$CONTAINER"
            ;;
        2)
            LATEST_RUN=$(ls -t "$PROJECT_DIR/user/logs/wandb/" 2>/dev/null | grep -E "^offline-run|^run-" | head -1)
            if [ -z "$LATEST_RUN" ]; then
                echo -e "${YELLOW}⚠️  没有找到训练日志${NC}"
                exit 1
            fi
            LOG_FILE="$PROJECT_DIR/user/logs/wandb/$LATEST_RUN/files/output.log"
            if [ -f "$LOG_FILE" ]; then
                echo -e "${BLUE}WandB 日志（按 Ctrl+C 退出）:${NC}"
                echo ""
                tail -f "$LOG_FILE"
            else
                echo -e "${YELLOW}⚠️  日志文件不存在: $LOG_FILE${NC}"
            fi
            ;;
        3)
            CONTAINER=$(docker ps -a --filter "name=rl-swarm" --format "{{.Names}}" | head -1)
            if [ -z "$CONTAINER" ]; then
                echo -e "${YELLOW}⚠️  没有运行中的容器${NC}"
                exit 1
            fi
            echo -e "${BLUE}最近 50 行日志:${NC}"
            echo ""
            docker logs --tail 50 "$CONTAINER"
            ;;
        *)
            echo -e "${RED}❌ 无效选择${NC}"
            exit 1
            ;;
    esac
}

# 查看资源使用
show_stats() {
    echo -e "${BLUE}[资源使用情况]${NC}"
    check_project_dir
    
    echo ""
    echo -e "${YELLOW}=== Docker 容器资源 ===${NC}"
    CONTAINER=$(docker ps --filter "name=rl-swarm" --format "{{.Names}}" | head -1)
    if [ -z "$CONTAINER" ]; then
        echo -e "${YELLOW}⚠️  没有运行中的容器${NC}"
    else
        docker stats --no-stream "$CONTAINER" --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    fi
    
    echo ""
    echo -e "${YELLOW}=== Docker 总体资源 ===${NC}"
    docker system df
    
    echo ""
    echo -e "${YELLOW}=== 磁盘使用 ===${NC}"
    du -sh "$PROJECT_DIR" 2>/dev/null || echo "无法计算"
    if [ -d "$PROJECT_DIR/user/logs" ]; then
        echo "日志目录: $(du -sh $PROJECT_DIR/user/logs 2>/dev/null | cut -f1)"
    fi
    
    echo ""
}

# 清理资源
clean_resources() {
    echo -e "${BLUE}[清理资源]${NC}"
    check_project_dir
    
    echo ""
    echo -e "${YELLOW}清理选项:${NC}"
    echo "  [1] 停止并删除容器（保留日志和配置）"
    echo "  [2] 清理 Docker 镜像缓存"
    echo "  [3] 清理训练日志（保留最新的）"
    echo "  [4] 完全清理（删除所有数据，包括钱包）"
    echo "  [5] 取消"
    echo ""
    read -p "请选择 [1-5]: " clean_choice
    
    case $clean_choice in
        1)
            echo -e "${YELLOW}停止并删除容器...${NC}"
            docker-compose down
            docker ps -a --filter "name=rl-swarm" --format "{{.Names}}" | xargs -r docker rm -f
            echo -e "${GREEN}✅ 容器已清理${NC}"
            ;;
        2)
            echo -e "${YELLOW}清理 Docker 镜像缓存...${NC}"
            docker system prune -a -f
            echo -e "${GREEN}✅ 镜像缓存已清理${NC}"
            ;;
        3)
            echo -e "${YELLOW}清理旧日志...${NC}"
            cd "$PROJECT_DIR/user/logs/wandb"
            # 保留最新的 3 个运行日志
            ls -t | grep -E "^offline-run|^run-" | tail -n +4 | xargs -r rm -rf
            echo -e "${GREEN}✅ 旧日志已清理（保留最新 3 个）${NC}"
            ;;
        4)
            echo -e "${RED}⚠️  警告: 将删除所有数据，包括钱包密钥！${NC}"
            echo ""
            read -p "确认删除？输入 'yes' 继续: " confirm
            if [ "$confirm" = "yes" ]; then
                docker-compose down
                docker ps -a --filter "name=rl-swarm" --format "{{.Names}}" | xargs -r docker rm -f
                rm -rf "$PROJECT_DIR/user/modal-login/"*.json
                rm -rf "$PROJECT_DIR/user/keys/"*.pem
                rm -rf "$PROJECT_DIR/user/logs/"
                echo -e "${GREEN}✅ 已完全清理${NC}"
                echo ""
                echo -e "${YELLOW}下次启动将创建新的钱包和节点身份${NC}"
            else
                echo -e "${YELLOW}已取消${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}已取消${NC}"
            ;;
    esac
    
    echo ""
}

# 主逻辑
main() {
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    case "$1" in
        start)
            start_node
            ;;
        stop)
            stop_node
            ;;
        restart)
            restart_node
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        stats)
            show_stats
            ;;
        clean)
            clean_resources
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
