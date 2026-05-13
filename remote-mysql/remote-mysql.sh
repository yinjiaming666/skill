#!/bin/bash
#
# 远程 MySQL 连接工具
# 通过 SSH 隧道连接远程 MySQL 并执行 SQL
#
# 用法:
#   ./remote-mysql.sh                          交互模式
#   ./remote-mysql.sh "SELECT 1"               执行单条 SQL
#   ./remote-mysql.sh -f ./migration.sql       执行 SQL 文件
#   ./remote-mysql.sh -d mydb "SHOW TABLES"    指定数据库

set -euo pipefail

# ============================================================
# SSH 连接配置
# ============================================================
SSH_HOST=""
SSH_PORT="22"
SSH_USER="root"
SSH_PASS=""          # 留空则尝试使用 SSH key 认证

# ============================================================
# MySQL 连接配置（远程服务器上的 MySQL）
# ============================================================
MYSQL_HOST=""   # 通常远程 MySQL 监听在 127.0.0.1
MYSQL_PORT="3306"
MYSQL_USER=""
MYSQL_PASS=""
MYSQL_DB=""              # 默认库，可留空

# ============================================================
# 本地隧道端口（一般无需修改）
# ============================================================
LOCAL_PORT="3307"

# ============================================================
# 颜色输出
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

cleanup() {
    if [[ -n "${SSH_PID:-}" ]] && kill -0 "$SSH_PID" 2>/dev/null; then
        log_info "关闭 SSH 隧道 (pid: $SSH_PID)..."
        kill "$SSH_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# ============================================================
# 校验必要参数
# ============================================================
check_config() {
    local missing=()
    [[ -z "$SSH_HOST" ]]   && missing+=("SSH_HOST")
    [[ -z "$SSH_USER" ]]   && missing+=("SSH_USER")
    [[ -z "$MYSQL_USER" ]] && missing+=("MYSQL_USER")
    [[ -z "$MYSQL_PASS" ]] && missing+=("MYSQL_PASS")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "以下配置项未填写，请编辑脚本填写:"
        for m in "${missing[@]}"; do
            echo "  - $m"
        done
        exit 1
    fi
}

# ============================================================
# 建立 SSH 隧道
# ============================================================
start_tunnel() {
    log_info "建立 SSH 隧道: 127.0.0.1:$LOCAL_PORT -> $MYSQL_HOST:$MYSQL_PORT"

    local ssh_opts="-o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes -N -L $LOCAL_PORT:$MYSQL_HOST:$MYSQL_PORT -p $SSH_PORT $SSH_USER@$SSH_HOST"

    if [[ -n "$SSH_PASS" ]]; then
        if ! command -v sshpass &>/dev/null; then
            log_error "已配置 SSH_PASS 但未安装 sshpass，请执行: brew install sshpass"
            exit 1
        fi
        sshpass -p "$SSH_PASS" ssh $ssh_opts &
    else
        ssh $ssh_opts &
    fi

    SSH_PID=$!

    # 等待隧道就绪（最多等 10 秒）
    local waited=0
    while true; do
        if command -v nc &>/dev/null; then
            nc -z 127.0.0.1 "$LOCAL_PORT" 2>/dev/null && break
        elif bash -c "true <>/dev/tcp/127.0.0.1/$LOCAL_PORT" 2>/dev/null; then
            break
        fi
        sleep 0.5
        waited=$((waited + 1))
        if [[ $waited -gt 20 ]]; then
            log_error "SSH 隧道建立超时，请检查 SSH 连接信息"
            kill "$SSH_PID" 2>/dev/null || true
            exit 1
        fi
    done
    log_info "隧道已就绪"
}

# ============================================================
# 构建 mysql 客户端命令
# ============================================================
build_mysql_cmd() {
    local cmd="mysql -h 127.0.0.1 -P $LOCAL_PORT -u $MYSQL_USER"
    cmd+=" -p\"$MYSQL_PASS\""
    [[ -n "$MYSQL_DB" ]] && cmd+=" $MYSQL_DB"
    cmd+=" --default-character-set=utf8mb4"
    echo "$cmd"
}

# ============================================================
# 执行 SQL
# ============================================================
run_sql() {
    local sql="$1"
    local mysql_cmd
    mysql_cmd="$(build_mysql_cmd)"
    echo "$sql" | eval "$mysql_cmd"
}

run_sql_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "SQL 文件不存在: $file"
        exit 1
    fi
    log_info "执行 SQL 文件: $file"
    local mysql_cmd
    mysql_cmd="$(build_mysql_cmd)"
    eval "$mysql_cmd" < "$file"
}

# ============================================================
# 交互模式
# ============================================================
run_interactive() {
    log_info "进入交互模式，输入 exit 或按 Ctrl+D 退出"
    local mysql_cmd
    mysql_cmd="$(build_mysql_cmd)"
    eval "$mysql_cmd"
}

# ============================================================
# 打印当前隧道端口（方便外部直连）
# ============================================================
print_tunnel_info() {
    echo ""
    log_info "隧道信息:"
    echo "  本地地址: 127.0.0.1:$LOCAL_PORT"
    echo "  远程地址: $MYSQL_HOST:$MYSQL_PORT"
    echo "  数据库:   ${MYSQL_DB:-(未指定)}"
    if [[ -n "${SSH_PID:-}" ]]; then
        echo "  SSH PID:  $SSH_PID"
    fi
    echo ""
}

# ============================================================
# 主流程
# ============================================================
main() {
    check_config
    start_tunnel

    local sql_file=""
    local sql_cmd=""
    local db_override=""

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--file)
                sql_file="$2"
                shift 2
                ;;
            -d|--database)
                db_override="$2"
                shift 2
                ;;
            -p|--port)
                LOCAL_PORT="$2"
                shift 2
                ;;
            -h|--help)
                echo "用法: $0 [选项] [SQL语句]"
                echo ""
                echo "选项:"
                echo "  -f, --file <file>     执行 SQL 文件"
                echo "  -d, --database <db>   指定数据库"
                echo "  -p, --port <port>     本地隧道端口 (默认 3307)"
                echo "  -h, --help            帮助信息"
                echo ""
                echo "示例:"
                echo "  $0                             交互模式"
                echo "  $0 'SELECT 1'                  执行单条 SQL"
                echo "  $0 -f ./migration.sql          执行 SQL 文件"
                echo "  $0 -d mydb 'SHOW TABLES'       指定库执行"
                exit 0
                ;;
            -*)
                log_error "未知选项: $1"
                exit 1
                ;;
            *)
                sql_cmd="$1"
                shift
                ;;
        esac
    done

    [[ -n "$db_override" ]] && MYSQL_DB="$db_override"

    print_tunnel_info

    if [[ -n "$sql_file" ]]; then
        run_sql_file "$sql_file"
    elif [[ -n "$sql_cmd" ]]; then
        log_info "执行: $sql_cmd"
        run_sql "$sql_cmd"
    else
        run_interactive
    fi
}

main "$@"
