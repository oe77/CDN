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
    "/www/server/panel/BTPanel/static/bt.js" \
    "/www/server/panel/class/panelSite.py" \
    "/www/server/panel/task.py" \
    "/www/server/panel/script/site_task.py" \
    "/www/server/panel/class/public.py" \
    "/www/server/panel/data/not_recommend.pl" \
    "/www/server/panel/data/not_workorder.pl"

# 去除宝塔面板强制绑定账号
remove_binding() {
    if grep -q "bind_user == 'REMOVED'" /www/server/panel/BTPanel/static/js/index.js; then
        echo "绑定账号已修改，跳过."
    else
        sed -i "s|bind_user == 'True'|bind_user == 'REMOVED'|" /www/server/panel/BTPanel/static/js/index.js
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
    
    if [ -f "$plugin_file" ]; then
        chattr -i "$plugin_file" 2>/dev/null
        rm -rf "$plugin_file"
    fi
    
    curl -s -o "$plugin_file" https://raw.githubusercontent.com/oe77/CDN/main/BT/plugin.json
    
    if [ -f "$plugin_file" ]; then
        chattr +i "$plugin_file"
        echo "plugin.json修改完成."
    else
        echo "下载plugin.json失败，请检查网络或URL."
    fi
    sleep 3
}

modify_repair_json() {
    local repair_file="/www/server/panel/data/repair.json"
    
    if [ -f "$repair_file" ]; then
        chattr -i "$repair_file" 2>/dev/null
        rm -rf "$repair_file"
    fi
    
    curl -s -o "$repair_file" https://raw.githubusercontent.com/oe77/CDN/main/BT/repair.json
    
    if [ -f "$repair_file" ]; then
        chattr +i "$repair_file"
        echo "repair.json修改完成."
    else
        echo "下载repair.json失败，请检查网络或URL."
    fi
    sleep 3
}


# 去除计算题与延时等待
Layout_file="/www/server/panel/BTPanel/templates/default/layout.html";
JS_file="/www/server/panel/BTPanel/static/bt.js";
if [ `grep -c "<script src=\"/static/bt.js\"></script>" $Layout_file` -eq '0' ];then
	sed -i '/{% block scripts %} {% endblock %}/a <script src="/static/bt.js"></script>' $Layout_file;
fi;
wget -q https://raw.githubusercontent.com/oe77/CDN/main/BT/bt.js -O $JS_file;
echo "已去除各种计算题与延时等待."



sed -i "/htaccess = self.sitePath+'\/.htaccess'/, /public.ExecShell('chown -R www:www ' + htaccess)/d" /www/server/panel/class/panelSite.py
sed -i "/index = self.sitePath+'\/index.html'/, /public.ExecShell('chown -R www:www ' + index)/d" /www/server/panel/class/panelSite.py
sed -i "/doc404 = self.sitePath+'\/404.html'/, /public.ExecShell('chown -R www:www ' + doc404)/d" /www/server/panel/class/panelSite.py
echo "已去除创建网站自动创建的垃圾文件."



sed -i "s/root \/www\/server\/nginx\/html/return 400/" /www/server/panel/class/panelSite.py
if [ -f /www/server/panel/vhost/nginx/0.default.conf ]; then
	sed -i "s/root \/www\/server\/nginx\/html/return 400/" /www/server/panel/vhost/nginx/0.default.conf
fi
echo "已关闭未绑定域名提示页面."

sed -i "s/return render_template('autherr.html')/return abort(404)/" /www/server/panel/BTPanel/__init__.py
echo "已关闭安全入口登录提示页面."


sed -i "/p = threading.Thread(target=check_files_panel)/, /p.start()/d" /www/server/panel/task.py
sed -i "/p = threading.Thread(target=check_panel_msg)/, /p.start()/d" /www/server/panel/task.py
echo "已去除消息推送与文件校验."

sed -i "/^logs_analysis()/d" /www/server/panel/script/site_task.py
sed -i "s/run_thread(cloud_check_domain,(domain,))/return/" /www/server/panel/class/public.py
echo "已去除面板日志与绑定域名上报."

if [ ! -f /www/server/panel/data/not_recommend.pl ]; then
	echo "True" > /www/server/panel/data/not_recommend.pl
fi
if [ ! -f /www/server/panel/data/not_workorder.pl ]; then
	echo "True" > /www/server/panel/data/not_workorder.pl
fi
echo "已关闭活动推荐与在线客服."

/www/server/panel/pyenv/bin/pip install -U Flask==2.1.2

# 定义要写入的条目
entries=(
    "127.0.0.1 dg2.bt.cn"
    "127.0.0.1 dg1.bt.cn"
    "127.0.0.1 45.76.53.20"
    "127.0.0.1 128.1.164.196"
    "127.0.0.1 38.34.185.130"
    "127.0.0.1 103.224.251.67"
    "127.0.0.1 113.107.111.78"
    "127.0.0.1 download.bt.cn"
    "127.0.0.1 123.129.198.197"
    "127.0.0.1 120.206.184.160"
    "127.0.0.1 36.133.1.8"
    "127.0.0.1 node.aapanel.com"
    "127.0.0.1 125.90.93.52"
    "127.0.0.1 125.88.182.172"
    "127.0.0.1 119.188.210.21"
    "127.0.0.1 116.213.43.206"
)


# 逐个检查并添加条目
for entry in "${entries[@]}"; do
    if ! grep -q "$entry" /etc/hosts; then
        echo "$entry" | sudo tee -a /etc/hosts > /dev/null
        echo "已添加: $entry"
    else
        echo "条目已存在: $entry"
    fi
done

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
restart_service
