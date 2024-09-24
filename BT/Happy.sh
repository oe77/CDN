#!/bin/bash
LANG=en_US.UTF-8
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

echo "
+----------------------------------------------------------------------
| Bt-WebPanel-Happy FOR CentOS
+----------------------------------------------------------------------
| 本脚本用于宝塔面板7.7版本的一键开心，因为脚本造成的问题请自行负责！
+----------------------------------------------------------------------
| 安装脚本：curl -sSO https://cdn.jsdelivr.net/gh/ztkink/bthappy@latest/install_panel.sh && bash install_panel.sh
+----------------------------------------------------------------------
"

# 检查是否为root用户
if [ "$(whoami)" != "root" ]; then
    echo "请使用root权限执行命令！"
    exit 1
fi

# 确认操作
while true; do
    read -p "请确认你已经安装的版本是7.7，请确认你将开心的宝塔面板用于学习！(y/n): " go
    [[ "$go" == "y" || "$go" == "n" ]] && break
done
[[ "$go" == "n" ]] && exit

# 备份文件
backup_files() {
    for file in "$@"; do
        if [ -f "$file" ]; then
            backup_file="${file}_$(date +%F).bak"
            if [ -f "$backup_file" ]; then
                echo "备份已存在，跳过: $backup_file"
            else
                cp "$file" "$backup_file" && echo "已备份: $file"
            fi
        else
            echo "文件不存在: $file"
        fi
    done
}

backup_files \
    "/www/server/panel/BTPanel/static/js/index.js" \
    "/www/server/panel/data/plugin.json" \
    "/www/server/panel/data/repair.json" \
    "/www/server/panel/data/bind.pl" \
    "/www/server/panel/BTPanel/templates/default/layout.html" \
    "/www/server/panel/BTPanel/static/bt.js"
    

# 去除宝塔面板强制绑定账号
remove_binding() {
    if grep -q "bind_user == 'XXXX'" /www/server/panel/BTPanel/static/js/index.js; then
        echo "绑定账号已修改，跳过."
    else
        sed -i "s|bind_user == 'True'|bind_user == 'XXXX'|" /www/server/panel/BTPanel/static/js/index.js
        echo "已去除宝塔面板强制绑定账号."
    fi
    sleep 3
}


# 删除强制绑定手机文件
rm -rf /www/server/panel/data/bind.pl
echo "删除强制绑定手机文件."
sleep 3

# 修改plugin.json
modify_plugin_json() {
    local plugin_file="/www/server/panel/data/plugin.json"
    chattr -i "$plugin_file" 2>/dev/null
    rm -rf "$plugin_file"
    curl -sSO https://cdn.jsdelivr.net/gh/oe77/CDN@latest/BT/plugin.json -o "$plugin_file"
    chattr +i "$plugin_file"
    echo "plugin.json修改完成."
    sleep 3
}

# 防修改repair.json
modify_repair_json() {
    local repair_file="/www/server/panel/data/repair.json"
    chattr -i "$repair_file" 2>/dev/null
    rm -rf "$repair_file"
    curl -sSO https://cdn.jsdelivr.net/gh/oe77/CDN@latest/BT/repair.json -o "$repair_file"
    chattr +i "$repair_file"
    echo "文件防修改完成."
    sleep 3
}

# 去除计算题与延时等待
remove_calculations() {
    local layout_file="/www/server/panel/BTPanel/templates/default/layout.html"
    local js_file="/www/server/panel/BTPanel/static/bt.js"
    local js_url="https://cdn.jsdelivr.net/gh/oe77/CDN@latest/BT/bt.js"

    # 检查是否已经添加了脚本引用
    if ! grep -q "<script src=\"/static/bt.js\"></script>" "$layout_file"; then
        sed -i '/{% block scripts %} {% endblock %}/a <script src="/static/bt.js"></script>' "$layout_file"
    fi

    # 检查当前文件的哈希值
    local current_hash=$(curl -s "$js_url" | md5sum | cut -d ' ' -f 1)
    local existing_hash=$(md5sum "$js_file" 2>/dev/null | cut -d ' ' -f 1)

    # 如果文件内容不同，则下载新文件
    if [ "$current_hash" != "$existing_hash" ]; then
        curl -sSO "$js_url" -o "$js_file"
        echo "已更新bt.js文件."
    else
        echo "bt.js文件已是最新，无需更新."
    fi

    echo "已去除各种计算题与延时等待."
    sleep 3
}


# 删除自动创建的垃圾文件
remove_garbage_files() {
    local modified=false
    for file in ".htaccess" "index.html" "404.html"; do
        # 检查是否已经修改过
        if grep -q "${file} = self.sitePath+'\/${file}'" /www/server/panel/class/panelSite.py; then
            sed -i "/${file} = self.sitePath+'\/${file}'/, /public.ExecShell('chown -R www:www ' + ${file})/d" /www/server/panel/class/panelSite.py
            modified=true
        fi
    done

    if $modified; then
        echo "已去除创建网站自动创建的垃圾文件."
    else
        echo "垃圾文件已被去除，无需再次修改."
    fi
    sleep 3
}


# 关闭未绑定域名提示页面
close_unbound_domain_warning() {
    local modified=false
    for conf_file in "/www/server/panel/class/panelSite.py" "/www/server/panel/vhost/nginx/0.default.conf"; do
        if [ -f "$conf_file" ]; then
            if grep -q "root /www/server/nginx/html" "$conf_file"; then
                sed -i "s|root /www/nginx/html|return 400|" "$conf_file"
                modified=true
            fi
        fi
    done

    if $modified; then
        echo "已关闭未绑定域名提示页面."
    else
        echo "未绑定域名提示页面已被关闭，无需再次修改."
    fi
    sleep 3
}


# 关闭安全入口登录提示页面
close_security_login_prompt() {
    if grep -q "return render_template('autherr.html')" /www/server/panel/BTPanel/__init__.py; then
        sed -i "s|return render_template('autherr.html')|return abort(404)|" /www/server/panel/BTPanel/__init__.py
        echo "已关闭安全入口登录提示页面."
    else
        echo "安全入口登录提示页面已被关闭，无需再次修改."
    fi
}

# 去除消息推送与文件校验
remove_notifications() {
    if grep -q "p = threading.Thread(target=check_files_panel)" /www/server/panel/task.py; then
        sed -i "/p = threading.Thread(target=check_files_panel)/, /p.start()/d" /www/server/panel/task.py
        sed -i "/p = threading.Thread(target=check_panel_msg)/, /p.start()/d" /www/server/panel/task.py
        echo "已去除消息推送与文件校验."
    else
        echo "消息推送与文件校验已被去除，无需再次修改."
    fi
    sleep 3
}

# 去除面板日志与绑定域名上报
remove_logging_and_reporting() {
    if grep -q "^logs_analysis()" /www/server/panel/script/site_task.py; then
        sed -i "/^logs_analysis()/d" /www/server/panel/script/site_task.py
        sed -i "s/run_thread(cloud_check_domain,(domain,))/return/" /www/server/panel/class/public.py
        echo "已去除面板日志与绑定域名上报."
    else
        echo "面板日志与绑定域名上报已被去除，无需再次修改."
    fi
    sleep 3
}

# 关闭活动推荐与在线客服
disable_recommendations() {
    for file in "not_recommend.pl" "not_workorder.pl"; do
        if [ ! -f "/www/server/panel/data/$file" ]; then
            echo "True" > "/www/server/panel/data/$file"
        else
            echo "$file 已存在，无需再次创建."
        fi
    done
    echo "已关闭活动推荐与在线客服."
}


# 重启服务
restart_service() {
    sleep 3
    /etc/init.d/bt restart
    sleep 3
    bt default
    sleep 2 
    echo -e "宝塔面板开心结束！"
}

# 执行所有功能
remove_binding
modify_plugin_json
modify_repair_json
remove_calculations
remove_garbage_files
close_unbound_domain_warning
close_security_login_prompt
remove_notifications
remove_logging_and_reporting
disable_recommendations
restart_service

