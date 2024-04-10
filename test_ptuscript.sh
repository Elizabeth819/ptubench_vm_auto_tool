#!/bin/bash

# 设置一个标志文件的路径，用于检查Python是否已安装
INSTALL_FLAG="/var/tmp/python_installation_done"

# 检查标志文件是否存在，以判断Python是否已安装
if [ -e "$INSTALL_FLAG" ]; then
    echo "Python and pip are already installed."
else
    # 根据你的操作系统，选择合适的安装命令
    # 以下以Ubuntu为例
    echo "Installing Python and pip..."

    # 更新包列表并安装Python及pip 防止用户输入密码
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt install -y python3 python3-pip

    # 安装完成后，创建标志文件
    touch "$INSTALL_FLAG"

    echo "Installation completed."
fi

cd /home/azureuser/azure-openai-benchmark|| { echo "Directory change failed"; exit 1; }

REQUIREMENT_INSTALL_FLAG="/var/tmp/requirement_install_done"
# 检查标志文件是否存在，以判断Python是否已安装
if [ -e "$REQUIREMENT_INSTALL_FLAG" ]; then
    echo "pip install -r requirement are already installed."
else
    echo "Installing pip install requirement..."
    pip install -r requirements.txt;

    # 安装完成后，创建标志文件
    touch "$REQUIREMENT_INSTALL_FLAG"

    echo "Requirement installation completed.\n"
fi


# 设置环境变量
export OPENAI_API_KEY=""
export AZURE_ENDPOINT="https://gpt4-swedencentral-eliz.openai.azure.com"
export DEPLOYMENT_NAME="gpt-4-turbo-1106"
export MAX_TOKEN=800
export RPM=6
export PROMPT_TOKEN=8000
echo
echo "Start PTU testing..."
COMMAND=$(python3 -m benchmark.bench load  --deployment $DEPLOYMENT_NAME --clients 20 --rate $RPM  --context-generation-method generate --shape-profile custom --context-tokens $PROMPT_TOKEN --max-tokens $MAX_TOKEN    --duration 180  --aggregation-window 120  $AZURE_ENDPOINT --log-save-dir .  --output-format jsonl)
echo "Command output: $COMMAND"