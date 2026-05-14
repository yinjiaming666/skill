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
#
# 直连模式:
#   ./remote-mysql.sh --direct                 不走 SSH，直接连接 MySQL
#   ./remote-mysql.sh --direct "SELECT 1"      直连执行单条 SQL

set -euo pipefail

# ============================================================
# 连接模式（建议直接在此处配置）
# ============================================================
# tunnel: 通过 SSH 隧道连接（默认）
# direct: 直接连接 MySQL（不走 SSH）
#
# 说明:
# - 默认请直接修改 *_DEFAULT 变量，把直连/隧道开关、IP/用户名/密码写在脚本里
# - 仍然保留环境变量覆盖能力（例如 CI 或临时切换环境时）
# - 不建议把真实密码提交到 Git（可只在本地改或用环境变量覆盖）
MYSQL_CONNECT_MODE_DEFAULT="tunnel"

# ============================================================
# SSH 连接配置（仅 tunnel 模式需要）
# ============================================================
SSH_HOST_DEFAULT=""
SSH_PORT_DEFAULT="22"
SSH_USER_DEFAULT="root"
SSH_PASS_DEFAULT=""          # 留空则尝试使用 SSH key 认证

# ============================================================
# MySQL 连接配置（远程服务器上的 MySQL）
# ============================================================
MYSQL_HOST_DEFAULT=""   # tunnel: 远端 MySQL 主机（通常为 127.0.0.1）；direct: MySQL 主机/IP
MYSQL_PORT_DEFAULT="3306"
MYSQL_USER_DEFAULT=""
MYSQL_PASS_DEFAULT=""   # 可直接写在脚本里；留空则 mysql 会提示输入密码
MYSQL_DB_DEFAULT=""     # 默认库，可留空

# 直连示例（把下面改成你的真实配置即可）:
# MYSQL_CONNECT_MODE_DEFAULT="direct"
# MYSQL_HOST_DEFAULT="127.0.0.1"
# MYSQL_PORT_DEFAULT="3306"
# MYSQL_USER_DEFAULT="root"
# MYSQL_PASS_DEFAULT="your_password"
# MYSQL_DB_DEFAULT="server"

# ============================================================
# 本地隧道端口（一般无需修改）
# ============================================================
LOCAL_PORT_DEFAULT="3307"

# ============================================================
# 运行时配置（可用环境变量覆盖 *_DEFAULT）
# ============================================================
MYSQL_CONNECT_MODE="${MYSQL_CONNECT_MODE:-$MYSQL_CONNECT_MODE_DEFAULT}"

SSH_HOST="${SSH_HOST:-$SSH_HOST_DEFAULT}"
SSH_PORT="${SSH_PORT:-$SSH_PORT_DEFAULT}"
SSH_USER="${SSH_USER:-$SSH_USER_DEFAULT}"
SSH_PASS="${SSH_PASS:-$SSH_PASS_DEFAULT}"

MYSQL_HOST="${MYSQL_HOST:-$MYSQL_HOST_DEFAULT}"
MYSQL_PORT="${MYSQL_PORT:-$MYSQL_PORT_DEFAULT}"
MYSQL_USER="${MYSQL_USER:-$MYSQL_USER_DEFAULT}"
MYSQL_PASS="${MYSQL_PASS:-$MYSQL_PASS_DEFAULT}"
MYSQL_DB="${MYSQL_DB:-$MYSQL_DB_DEFAULT}"

LOCAL_PORT="${LOCAL_PORT:-$LOCAL_PORT_DEFAULT}"

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

    if [[ "$MYSQL_CONNECT_MODE" == "tunnel" ]]; then
        [[ -z "$SSH_HOST" ]] && missing+=("SSH_HOST")
        [[ -z "$SSH_USER" ]] && missing+=("SSH_USER")
        [[ -z "$MYSQL_HOST" ]] && MYSQL_HOST="127.0.0.1"
    elif [[ "$MYSQL_CONNECT_MODE" == "direct" ]]; then
        [[ -z "$MYSQL_HOST" ]] && missing+=("MYSQL_HOST")
    else
        log_error "未知 MYSQL_CONNECT_MODE: $MYSQL_CONNECT_MODE (仅支持 tunnel/direct)"
        exit 1
    fi

    [[ -z "$MYSQL_USER" ]] && missing+=("MYSQL_USER")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "以下配置项未填写，请在脚本顶部填写对应 *_DEFAULT（或用环境变量/参数传入）:"
        for m in "${missing[@]}"; do
            echo "  - $m"
        done
        echo ""
        log_info "也可通过环境变量或参数传入配置（示例）:"
        echo "  MYSQL_CONNECT_MODE=direct MYSQL_HOST=127.0.0.1 MYSQL_USER=root bash $0"
        echo "  bash $0 --direct --mysql-host 127.0.0.1 --mysql-user root"
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
# 构建 mysql 客户端参数
# ============================================================
build_mysql_args() {
    local host=""
    local port=""

    if [[ "$MYSQL_CONNECT_MODE" == "tunnel" ]]; then
        host="127.0.0.1"
        port="$LOCAL_PORT"
    else
        host="$MYSQL_HOST"
        port="$MYSQL_PORT"
    fi

    MYSQL_ARGS=(mysql -h "$host" -P "$port" -u "$MYSQL_USER" --default-character-set=utf8mb4)
    if [[ -n "$MYSQL_PASS" ]]; then
        MYSQL_ARGS+=("-p$MYSQL_PASS")
    else
        MYSQL_ARGS+=("-p")
    fi
    [[ -n "$MYSQL_DB" ]] && MYSQL_ARGS+=("$MYSQL_DB")
}

# ============================================================
# 执行 SQL
# ============================================================
run_sql() {
    local sql="$1"
    build_mysql_args
    printf '%s\n' "$sql" | "${MYSQL_ARGS[@]}"
}

run_sql_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_error "SQL 文件不存在: $file"
        exit 1
    fi
    log_info "执行 SQL 文件: $file"
    build_mysql_args
    "${MYSQL_ARGS[@]}" < "$file"
}

# ============================================================
# 交互模式
# ============================================================
run_interactive() {
    log_info "进入交互模式，输入 exit 或按 Ctrl+D 退出"
    build_mysql_args
    "${MYSQL_ARGS[@]}"
}

# ============================================================
# 打印连接信息
# ============================================================
print_connection_info() {
    echo ""
    if [[ "$MYSQL_CONNECT_MODE" == "tunnel" ]]; then
        log_info "隧道信息:"
        echo "  本地地址: 127.0.0.1:$LOCAL_PORT"
        echo "  远程地址: $MYSQL_HOST:$MYSQL_PORT"
        if [[ -n "${SSH_PID:-}" ]]; then
            echo "  SSH PID:  $SSH_PID"
        fi
    else
        log_info "直连信息:"
        echo "  MySQL 地址: $MYSQL_HOST:$MYSQL_PORT"
    fi
    echo "  数据库:   ${MYSQL_DB:-(未指定)}"
    echo ""
}

# ============================================================
# 主流程
# ============================================================
main() {
    local sql_file=""
    local sql_cmd=""
    local db_override=""
    local mysql_host_override=""
    local mysql_port_override=""
    local mysql_user_override=""
    local mysql_pass_override=""

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --direct)
                MYSQL_CONNECT_MODE="direct"
                shift
                ;;
            --tunnel)
                MYSQL_CONNECT_MODE="tunnel"
                shift
                ;;
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
            --mysql-host)
                mysql_host_override="$2"
                shift 2
                ;;
            --mysql-port)
                mysql_port_override="$2"
                shift 2
                ;;
            --mysql-user)
                mysql_user_override="$2"
                shift 2
                ;;
            --mysql-pass)
                mysql_pass_override="$2"
                shift 2
                ;;
            -h|--help)
                echo "用法: $0 [选项] [SQL语句]"
                echo ""
                echo "选项:"
                echo "  -f, --file <file>     执行 SQL 文件"
                echo "  -d, --database <db>   指定数据库"
                echo "  -p, --port <port>     本地隧道端口 (默认 3307)"
                echo "      --direct          直连 MySQL（不建立 SSH 隧道）"
                echo "      --tunnel          强制使用 SSH 隧道（默认）"
                echo "      --mysql-host <h>  覆盖 MYSQL_HOST"
                echo "      --mysql-port <p>  覆盖 MYSQL_PORT"
                echo "      --mysql-user <u>  覆盖 MYSQL_USER"
                echo "      --mysql-pass <p>  覆盖 MYSQL_PASS（留空则交互输入更安全）"
                echo "  -h, --help            帮助信息"
                echo ""
                echo "示例:"
                echo "  $0                             交互模式"
                echo "  $0 'SELECT 1'                  执行单条 SQL"
                echo "  $0 -f ./migration.sql          执行 SQL 文件"
                echo "  $0 -d mydb 'SHOW TABLES'       指定库执行"
                echo "  $0 --direct --mysql-host 127.0.0.1 --mysql-user root 'SELECT 1'"
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
    [[ -n "$mysql_host_override" ]] && MYSQL_HOST="$mysql_host_override"
    [[ -n "$mysql_port_override" ]] && MYSQL_PORT="$mysql_port_override"
    [[ -n "$mysql_user_override" ]] && MYSQL_USER="$mysql_user_override"
    [[ -n "$mysql_pass_override" ]] && MYSQL_PASS="$mysql_pass_override"

    check_config

    if [[ "$MYSQL_CONNECT_MODE" == "tunnel" ]]; then
        start_tunnel
    fi

    print_connection_info

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
