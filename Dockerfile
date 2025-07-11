FROM browser-use-mcp-server-base

COPY . /app

# Set Keyword Environment
ENV ANONYMIZED_TELEMETRY=false \
    PATH="/app/.venv/bin:$PATH" \
    DISPLAY=:0 \
    CHROME_BIN=/usr/bin/chromium \
    CHROMIUM_FLAGS="--no-sandbox --headless --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage"

# Combine VNC setup commands to reduce layers
RUN mkdir -p ~/.vnc && \
    printf '#!/bin/sh\nunset SESSION_MANAGER\nunset DBUS_SESSION_BUS_ADDRESS\nstartxfce4' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup
#     printf '#!/bin/bash\n\n# Use Docker secret for VNC password if available, else fallback to default\nif [ -f "/run/secrets/vnc_password" ]; then\n  cat /run/secrets/vnc_password | vncpasswd -f > /root/.vnc/passwd\nelse\n  cat /run/secrets/vnc_password_default | vncpasswd -f > /root/.vnc/passwd\nfi\n\nchmod 600 /root/.vnc/passwd\nvncserver -depth 24 -geometry 960x1080 -localhost no -PasswordFile /root/.vnc/passwd :0\nproxy-login-automator\npython /app/server --port 8000' > /app/boot.sh && \
#     chmod +x /app/boot.sh

# Set up working directory
WORKDIR /app

RUN apt-get update && apt-get install -y \
    fonts-wqy-microhei \
    fonts-noto-cjk && \
    # 在清理 apt 缓存之前，重建字体缓存
    fc-cache -fv && \
    rm -rf /var/lib/apt/lists/*

# --no-shell
RUN uv sync --frozen --no-install-project --no-dev \
    && uv run playwright install --with-deps chromium && uv tool install mcp-proxy
    # && cd /opt/web-ui/ && uv run playwright install --with-deps chromium

# Set up supervisor configuration
RUN mkdir -p /var/log/supervisor && mkdir -p /root/Downloads/browser-use \
    && mkdir -p /var/log && touch /var/log/x11vnc.log && chmod 666 /var/log/x11vnc.log

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 

EXPOSE 7788 6080 5901 9222 8000 8088

# supervisord -c /etc/supervisor/conf.d/supervisord.conf
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
