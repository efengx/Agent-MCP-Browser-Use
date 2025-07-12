#!/bin/bash
# 这是一个只运行一次的初始化脚本
set -e # 如果任何命令失败，脚本将立即退出

echo "--- Running one-time container initialization ---"

# --- 用户生成 (来自 startup.sh) ---
# 确保必要的函数库被引用
source /dockerstartup/user_generator.rc

if [[ -s "${STARTUPDIR}/.initial_sudo_password" ]] ; then
    echo "Generating container user..."
    generate_container_user
    if [[ "$?" != "0" ]] ; then
        echo "ERROR: Failed to generate user."
        exit 1
    fi
    echo "User generated successfully."
fi

# --- VNC 初始化 (来自 vnc_startup.rc) ---
# 检查关键环境变量
: ${DISPLAY?} ${VNC_PORT?} ${VNC_PW?} ${VNC_COL_DEPTH?} ${VNC_RESOLUTION?}

echo "Configuring VNC..."

# 创建 .vnc 目录
mkdir -p "${HOME}"/.vnc

# 设置VNC密码
passwd_path="${HOME}/.vnc/passwd"
echo "${VNC_PW}" | vncpasswd -f > "${passwd_path}"
chmod 600 "${passwd_path}"
echo "VNC password set."

# 创建VNC配置文件
echo "
rfbport=${VNC_PORT}
depth=${VNC_COL_DEPTH}
geometry=${VNC_RESOLUTION}
" > "${HOME}"/.vnc/config
echo "VNC config file created."

# 清理旧的VNC/X11锁文件
echo "Cleaning up old VNC/X11 locks..."
rm -rf /tmp/.X*-lock /tmp/.X11-unix > /dev/null 2>&1
if [[ -n "$(pidof xinit)" ]]; then
    kill "$(pidof xinit)" > /dev/null 2>&1
fi
echo "Cleanup complete."

echo "--- Initialization finished ---"