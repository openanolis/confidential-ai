#!/bin/bash
set -eo pipefail

DEFAULT_CONFIG="config_trustee.yaml"

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --config-file)
            CONFIG_FILE="$2"
            shift 2  # 跳过参数和值
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "错误: 未知选项 $1"
            show_help
            exit 1
            ;;
        esac
    done

    CONFIG_FILE="${CONFIG_FILE:-$DEFAULT_CONFIG}"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "错误: 配置文件 $CONFIG_FILE 不存在"
        exit 1
    fi
}

show_help() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  --config-file <路径>  指定 YAML 配置文件路径"
    echo "  --help                显示帮助信息"
}

initialize_environment() {
    yum install -y anolis-epao-release trustee trusted-network-gateway wget pkg-config openssl-devel
    yum clean all && rm -rf /var/cache/yum

    # install yq
    wget https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_amd64 -O /usr/local/bin/yq
    chmod +x /usr/local/bin/yq

    # install gocryptfs-v2.4
    mkdir gocryptfs && cd gocryptfs && \
        wget https://github.com/rfjakob/gocryptfs/releases/download/v2.4.0/gocryptfs_v2.4.0_linux-static_amd64.tar.gz && \
        tar xf gocryptfs_v2.4.0_linux-static_amd64.tar.gz && \
        install -m 0755 ./gocryptfs /usr/local/bin && \
        cd .. && rm -rf gocryptfs

    # build and install trustee-client
    export RUSTUP_DIST_SERVER='https://mirrors.ustc.edu.cn/rust-static' && \
        export RUSTUP_UPDATE_ROOT='https://mirrors.ustc.edu.cn/rust-static/rustup' && \
        curl --proto '=https' --tlsv1.2 -sSf https://mirrors.aliyun.com/repo/rust/rustup-init.sh | \
        sh  -s -- -y
    export PATH="/root/.cargo/bin:${PATH}" && \
        export RUSTUP_DIST_SERVER='https://mirrors.ustc.edu.cn/rust-static' && \
        export RUSTUP_UPDATE_ROOT='https://mirrors.ustc.edu.cn/rust-static/rustup' && \
        rustup toolchain install 1.79.0-x86_64-unknown-linux-gnu
    printf '[source.crates-io]\nreplace-with = "aliyun"\n\n[source.aliyun]\nregistry = "sparse+https://mirrors.aliyun.com/crates.io-index/"\n' > ~/.cargo/config.toml
    mkdir -p tmp && cd tmp && git clone --branch v1.1.1 https://github.com/openanolis/trustee.git && cd trustee && \
        cargo build -p kbs-client --locked --release --no-default-features --features sample_only && \
        cp target/release/kbs-client /usr/local/bin/trustee-client && cd .. && rm -rf trustee && cd .. && rm -rf tmp
}

download_and_encrypt_model() {
    local model_type="${1}"
    local model_dir="${2}"
    local password_file="${3}"
    local base_dir="/tmp/confidential-ai/rpm/trustee"
    local mount_dir="${base_dir}/mount"
    local cipher_dir="${mount_dir}/cipher"
    local plain_dir="${mount_dir}/plain"

    # 模型URL映射
    declare -A model_urls=(
        ["DeepSeek-R1-Chat"]="https://modelscope.cn/models/unsloth/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/master/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf"
        ["Qwen-7B-Instruct"]="https://modelscope.cn/models/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/master/qwen2.5-7b-instruct-q4_k_m.gguf"
    )
    local wget_opts="--progress=dot:giga --show-progress --tries=30 --timeout=300 --waitretry=15"

    # 参数有效性验证
    [[ -z "${model_type}" ]] && { echo "ERROR: Model type required" >&2; return 1; }
    [[ -z "${model_dir}" ]] && { echo "ERROR: Model directory required" >&2; return 1; }
    [[ -z "${password_file}" ]] && { echo "ERROR: Password file required" >&2; return 1; }
    [[ ! -v model_urls[$model_type] ]] && { echo "ERROR: Unsupported model: ${model_type}" >&2; return 1; }

    # 资源文件存在性检查
    [[ ! -f "$password_file" ]] && { echo "ERROR: $password_file file not found" >&2; return 1; }
    
    # 动态加载模型配置
    local url="${model_urls[$model_type]}"
    local filename="$(basename "$url")"
    local target_file="${plain_dir}/${filename}"

    echo url: ${url}
    echo filename: ${filename}
    echo target_file: ${target_file}
    
    # 初始化工作目录
    mkdir -p "${base_dir}" || return 1

    # 初始化加密文件系统（无中间密码文件）
    (
        local password=$(cat ${password_file})
        cd "${base_dir}" || exit 1
        if [[ -d "${mount_dir}" ]]; then
            fusermount -u "${plain_dir}"
            rm -rf "${mount_dir}"
        fi
        mkdir -p "${mount_dir}" || exit 1
        
        if [[ ! -d "${cipher_dir}" ]]; then
            mkdir -p "${cipher_dir}" "${plain_dir}" || exit 1
            echo ${password} | gocryptfs -init ${cipher_dir} || exit 1
            echo ${password} | gocryptfs ${cipher_dir} ${plain_dir} || exit 1
        fi
    ) || { echo "Filesystem initialization failed"; return 1; }

    # 下载模型文件
    if [[ ! -f "${target_file}" ]]; then
        echo "Downloading ${model_type} model..."
        wget ${wget_opts} -O "${target_file}.tmp" "${url}" \
            && mv "${target_file}.tmp" "${target_file}" \
            || { echo "Download failed"; rm -f "${target_file}.tmp"; return 1; }
    fi

    # 打包加密数据
    (
        cd "${cipher_dir}" || exit 1
        mkdir -p "${model_dir}" || exit 1
        tar cvzf - . | split -d -b 1G - "${model_dir}/${model_type}-encrypted.tar.gz.part"
    ) || { echo "Packaging failed"; return 1; }
}

# 用法: set_trustee_resource 密钥路径 信任服务地址 信任服务私钥 资源数据
set_trustee_resource() {
    local key_path="$1"
    local trustee_url="$2"
    local trustee_pk_file="$3"
    local resource_file="$4"
    local policy_file="$5"

    # 参数有效性验证
    [[ -z "${key_path}" ]] && { echo "ERROR: Key path required" >&2; return 1; }
    [[ -z "${trustee_url}" ]] && { echo "ERROR: Trustee url required" >&2; return 1; }
    [[ -z "${trustee_pk_file}" ]] && { echo "ERROR: Trustee pk file required" >&2; return 1; }
    [[ -z "${resource_file}" ]] && { echo "ERROR: Resource file required" >&2; return 1; }
    [[ -z "${policy_file}" ]] && { echo "ERROR: Policy file required" >&2; return 1; }

    # 资源文件存在性检查
    [[ ! -f "$trustee_pk_file" ]] && { echo "ERROR: $trustee_pk_file file not found" >&2; return 1; }
    [[ ! -f "$resource_file" ]] && { echo "ERROR: $resource_file file not found" >&2; return 1; }
    [[ ! -f "$policy_file" ]] && { echo "ERROR: $policy_file file not found" >&2; return 1; }

    # 执行核心操作
    if ! trustee-client --url "$trustee_url" config \
         --auth-private-key "$trustee_pk_file" \
         set-resource \
         --path "$key_path" \
         --resource-file "$resource_file"; then
        echo "错误：上传资源失败" >&2
        return 1
    fi

    echo "资源 [$resource_file] 已成功上传到 [$trustee_url] 路径 [$key_path]"

    if ! trustee-client --url "$trustee_url" config \
         --auth-private-key "$trustee_pk_file" \
         set-resource-policy \
         --policy-file "$policy_file"; then
        echo "错误：上传策略失败" >&2
        return 1
    fi

    echo "策略 [$policy_file] 已成功上传到 [$trustee_url]"
}

set_secret() {
    local config_file="$1"

    # 参数有效性验证
    [[ -z "$config_file" ]] && { echo "ERROR: Config file required" >&2; return 1; }

    # 获取 secret_writer 数组长度
    local array_length=$(yq e '.secret_writer | length' "$config_file")
    
    # Iterate through index
    for ((i=0; i<array_length; i++)); do
        # Extract writer
        local writer=$(yq e ".secret_writer[$i]" "$config_file")
        local writer_type=$(yq e ".secret_writer[$i].type" "$config_file")

        # Check if type is 'trustee'
        if [ "$writer_type" = "trustee" ]; then
            # Extract parameters (adjust based on your actual config structure)
            local key_path=$(echo "$writer" | yq e '.params.path')
            local trustee_url=$(echo "$writer" | yq e '.params.kbs_addr')
            local trustee_pk_file=$(echo "$writer" | yq e '.params.private_key_file')
            local resource_file=$(echo "$writer" | yq e '.params.resource_file')
            local policy_file=$(echo "$writer" | yq e '.params.policy_file')
            
            # Call set_trustee_resource with extracted parameters
            set_trustee_resource "$key_path" "$trustee_url" "$trustee_pk_file" "$resource_file" "$policy_file"
        else
            echo "未知的密钥写入类型：$writer_type" >&2
            return 1
        fi
    done

    echo "密钥写入完成"
}

set_web_file_service() {
    local port="$1"
    local directory="$2"
    local bind_address="$3"
    
    # 参数有效性验证
    [[ -z "${port}" ]] && { echo "ERROR: Port required" >&2; return 1; }
    [[ -z "${directory}" ]] && { echo "ERROR: Directory required" >&2; return 1; }
    [[ -z "${bind_address}" ]] && { echo "ERROR: Bind address required" >&2; return 1; }

    # 目录存在性检查
    [[ ! -d "$directory" ]] && { echo "ERROR: "$directory" Directory not found" >&2; return 1; }

    # 自动检测Python环境
    if ! command -v python3 &>/dev/null; then
        echo "错误：未找到可用的Python3环境" >&2
        return 1
    fi
    
    # 启动后台服务
    (
        cd "$directory" || return 1
        # 启动HTTP服务并获取PID
        python3 -m http.server "$port" --bind "$bind_address" >/dev/null 2>&1 &
        local server_pid=$!
        
        # 设置30分钟超时关闭
        (
            sleep $((30 * 60 + 1))  # 30分钟
            # 双重验证机制
            if [[ -d "/proc/$server_pid" ]] && \
               ps -p $server_pid -o etime= | awk -F: '{t=0; for(i=NF; i>0; i--) t=t*60+$i; exit t>1800}'
            then
                kill -9 "$server_pid" 2>/dev/null && \
                echo "[!] 服务已超时自动关闭 (PID: $server_pid)"
            fi
        ) &
        local timeout_pid=$!

        # 记录进程信息
        echo "[+] Starting Temporary Web Service:"
        echo "    Directory: $(realpath "$directory")"
        echo "    Address: http://${bind_address}:${port}"
        echo "    Stop: kill -9 $server_pid"
        echo "    Auto Shutdown: 30 mins later (process PID: $timeout_pid)"
        
        # 进程分离处理
        disown "$server_pid" "$timeout_pid" 2>/dev/null
    ) &
}

set_resource() {
    local config_file="$1"

    # 参数有效性验证
    [[ -z "$config_file" ]] && { echo "ERROR: Config file required" >&2; return 1; }


    # 获取 resource_writer 数组长度
    local array_length=$(yq e '.resource_writer | length' "$config_file")
    
    # Iterate through index
    for ((i=0; i<array_length; i++)); do
        # Extract writer
        local writer=$(yq e ".resource_writer[$i]" "$config_file")
        local writer_type=$(yq e ".resource_writer[$i].type" "$config_file")

        # Check if type is 'web_file'
        if [ "$writer_type" = "web_file" ]; then
            # Extract parameters (adjust based on your actual config structure)
            local port=$(echo "$writer" | yq e '.params.port')
            local directory=$(echo "$writer" | yq e '.params.directory')
            local bind_address=$(echo "$writer" | yq e '.params.bind_address')
            
            # Call set_web_file_service with extracted parameters
            set_web_file_service "$port" "$directory" "$bind_address"
        else
            echo "未知的资源写入类型：$writer_type" >&2
            return 1
        fi
    done

    echo "资源写入完成"
}

main() {
    # 0. Prepare environment
    initialize_environment

    # 1. Download and encrypt model
    # Parse config
    parse_arguments "$@"
    # Extract parameters from 'model' named resource_writer
    MODEL_TYPE=$(yq e '.resource_writer[] | select(.name == "model") | .params.model_type' "$CONFIG_FILE")
    DIRECTORY=$(yq e '.resource_writer[] | select(.name == "model") | .params.directory' "$CONFIG_FILE")
    # Keep password from secret_writer as before
    PASSWORD=$(yq e '.secret_writer[] | select(.name == "model_password") | .params.resource_file' "$CONFIG_FILE")

    download_and_encrypt_model ${MODEL_TYPE} ${DIRECTORY} ${PASSWORD}

    # 2. Set Secret (upload password to KBS and set KBS policy)
    set_secret ${CONFIG_FILE}

    # 3. Set Resource (open encrypted model for web access)
    set_resource ${CONFIG_FILE}

    # 4. Wait for all background processes to complete
    wait
}

# 执行主函数
main "$@"