FROM browser-use-agent-mcp-server-base

WORKDIR /home/headless/app

COPY . .

COPY ./dockerstartup/startup.sh /dockerstartup/startup.sh
RUN chmod +x /dockerstartup/startup.sh

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# RUN chown -R headless:headless /app
# USER headless

CMD ["/dockerstartup/startup.sh"]
