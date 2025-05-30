#!/bin/bash
set -eo pipefail

DEFAULT_CONFIG="config_trustiflux.yaml"

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
    yum install -y anolis-epao-release attestation-agent confidential-data-hub trusted-network-gateway wget unzip
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
}

decrypt_model() {
    local model_dir="${1}"
    local model_file="${2}"
    local password_file="${3}"
    local base_dir="/tmp/confidential-ai/rpm/trustiflux"
    local mount_dir="${base_dir}/mount"
    local cipher_dir="${mount_dir}/cipher"
    local plain_dir="${mount_dir}/plain"

    # 参数有效性验证
    [[ -z "${model_dir}" ]] && { echo "ERROR: Model directory required" >&2; return 1; }
    [[ -z "${model_file}" ]] && { echo "ERROR: Model file required" >&2; return 1; }
    [[ -z "${password_file}" ]] && { echo "ERROR: Password file required" >&2; return 1; }

    # 资源文件存在性检查
    [[ ! -d "$model_dir" ]] && { echo "ERROR: $model_dir dir not found" >&2; return 1; }
    
    # 初始化工作目录
    if [[ -d "${mount_dir}" ]]; then
        fusermount -u "${plain_dir}"
        rm -rf "${mount_dir}"
    fi
    mkdir -p "${base_dir}" || return 1
    mkdir -p "${mount_dir}" || return 1
    mkdir -p "${cipher_dir}" || return 1
    mkdir -p "${plain_dir}" || return 1

    # 解压和解密模型
    cat $(ls -v ${model_dir}/${MODEL_FILE}.part*) | tar xvzf - -C ${cipher_dir}
    gocryptfs -debug -passfile ${password_file} ${cipher_dir} ${plain_dir}

    echo "model decrypted to '${plain_dir}'"
}

# 用法: get_trustee_resource 密钥路径 信任服务地址 信任服务私钥 资源数据
get_trustee_resource() {
    local trustee_kbs_url="$1"
    local trustee_as_url="$2"
    local key_path="$3"
    local resource_file="$4"

    # 参数有效性验证
    [[ -z "${trustee_kbs_url}" ]] && { echo "ERROR: Trustee kbs url required" >&2; return 1; }
    [[ -z "${trustee_as_url}" ]] && { echo "ERROR: Trustee as url required" >&2; return 1; }
    [[ -z "${key_path}" ]] && { echo "ERROR: Key path required" >&2; return 1; }
    [[ -z "${resource_file}" ]] && { echo "ERROR: Resource file required" >&2; return 1; }

    # 目录存在性检查，不存在时创建
    local directory=$(dirname "$resource_file")
    [[ ! -d "$directory" ]] && { mkdir -p "$directory" || return 1; }

    # 执行核心操作
    ## run AA
    (
        sed -i "/\[token_configs\.kbs$$/,/^$$/ s|^url = .*|url = \"$trustee_kbs_url\"|" /etc/trustiflux/attestation-agent.toml
        sed -i "/\[token_configs\.coco_as$$/,/^$$/ s|^url = .*|url = \"$trustee_as_url\"|" /etc/trustiflux/attestation-agent.toml
        attestation-agent -c /etc/trustiflux/attestation-agent.toml
    ) &
    ## run CDH and get resource
    sed -i 's|\(url\s*=\s*"\)[^"]*|\1'"$trustee_kbs_url"'|' /etc/trustiflux/confidential-data-hub.toml
    blob=$(confidential-data-hub -c /etc/trustiflux/confidential-data-hub.toml get-resource --resource-uri "kbs:///${key_path}")
    echo "blob: $blob"
    echo "$blob" | base64 -d > "$resource_file"

    echo "资源 [$key_path] 已成功下载到路径 [$resource_file]"
}

get_secret() {
    local config_file="$1"

    # 参数有效性验证
    [[ -z "$config_file" ]] && { echo "ERROR: Config file required" >&2; return 1; }

    # 获取 secret_reader 数组长度
    local array_length=$(yq e '.secret_reader | length' "$config_file")
    
    # Iterate through index
    for ((i=0; i<array_length; i++)); do
        # Extract reader
        local reader=$(yq e ".secret_reader[$i]" "$config_file")
        local reader_type=$(yq e ".secret_reader[$i].type" "$config_file")

        # Check if type is 'trustee'
        if [ "$reader_type" = "trustee" ]; then
            # Extract parameters (adjust based on your actual config structure)
            local trustee_kbs_url=$(echo "$reader" | yq e '.params.kbs_addr')
            local trustee_as_url=$(echo "$reader" | yq e '.params.as_addr')
            local key_path=$(echo "$reader" | yq e '.params.path')
            local resource_file=$(echo "$reader" | yq e '.params.resource_file')

            # Call get_trustee_resource with extracted parameters
            get_trustee_resource "$trustee_kbs_url" "$trustee_as_url" "$key_path" "$resource_file"
        else
            echo "未知的密钥写入类型：$reader_type" >&2
            return 1
        fi
    done

    echo "密钥写入完成"
}

get_file_from_service() {
    local url="$1"
    local directory="$2"
    
    # 参数有效性验证
    [[ -z "${url}" ]] && { echo "ERROR: URL required" >&2; return 1; }
    [[ -z "${directory}" ]] && { echo "ERROR: Directory required" >&2; return 1; }

    # 目录存在性检查，存在时删除，不存在时创建
    [[ -d "$directory" ]] && { rm -rf ${directory}; }
    [[ ! -d "$directory" ]] && { mkdir -p "$directory" || return 1; }

    wget -c --tries=30 --timeout=30 --waitretry=15 -r --progress=dot:giga --show-progress -np -nH -R "index.html*" --cut-dirs=1 -P "${directory}" "${url}"
}

get_resource() {
    local config_file="$1"

    # 参数有效性验证
    [[ -z "$config_file" ]] && { echo "ERROR: Config file required" >&2; return 1; }


    # 获取 resource_reader 数组长度
    local array_length=$(yq e '.resource_reader | length' "$config_file")
    
    # Iterate through index
    for ((i=0; i<array_length; i++)); do
        # Extract reader
        local reader=$(yq e ".resource_reader[$i]" "$config_file")
        local reader_type=$(yq e ".resource_reader[$i].type" "$config_file")

        # Check if type is 'web_file'
        if [ "$reader_type" = "web_file" ]; then
            # Extract parameters (adjust based on your actual config structure)
            local url=$(echo "$reader" | yq e '.params.url')
            local directory=$(echo "$reader" | yq e '.params.directory')
            
            # Call get_file_from_service with extracted parameters
            get_file_from_service "$url" "$directory"
        else
            echo "未知的资源读取类型：$reader_type" >&2
            return 1
        fi
    done

    echo "资源读取完成"
}

main() {
    # 0. Prepare environment
    initialize_environment

    # Parse config
    parse_arguments "$@"

    # 1. Get Secret (get password to KBS through RCAR procedure)
    get_secret ${CONFIG_FILE}

    # 2. Get Resource (get encrypted model from web service)
    get_resource ${CONFIG_FILE}

    # 3. Decrypt model
    # Extract parameters from 'model' named resource_reader and secret_reader
    MODEL_DIR=$(yq e '.resource_reader[] | select(.name == "model") | .params.directory' "$CONFIG_FILE")
    MODEL_FILE=$(yq e '.resource_reader[] | select(.name == "model") | .params.model_file' "$CONFIG_FILE")
    MODEL_PASSWORD=$(yq e '.secret_reader[] | select(.name == "model_password") | .params.resource_file' "$CONFIG_FILE")

    decrypt_model ${MODEL_DIR} ${MODEL_FILE} ${MODEL_PASSWORD}
}

# 执行主函数
main "$@"