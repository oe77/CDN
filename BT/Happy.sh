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

if [ $(whoami) != "root" ];then
	echo "请使用root权限执行命令！"
	exit 1;
fi

while [ "$go" != 'y' ] && [ "$go" != 'n' ]
do
	read -p "请确认你已经安装的版本是7.7，请确认你将开心的宝塔面板用于学习！(y/n): " go;
done

if [ "$go" == 'n' ];then
	exit;
fi

#备份修改的文件
cp   /www/server/panel/BTPanel/static/js/index.js   /www/server/panel/BTPanel/static/js/index.js_$(date +%F).bak
cp   /www/server/panel/data/plugin.json   /www/server/panel/data/plugin.json_$(date +%F).bak
cp   /www/server/panel/data/repair.json   /www/server/panel/data/repair.json_$(date +%F).bak


#去除宝塔面板强制绑定账号
sed -i "s|if (bind_user == 'True') {|if (bind_user == 'REMOVED') {|g" /www/server/panel/BTPanel/static/js/index.js
rm -rf /www/server/panel/data/bind.pl
echo "已去除宝塔面板强制绑定账号."
sleep 3
#1.修改所有付费插件为永不过期 2.修改宝塔标识为pro 3.给plugin.json文件上锁防止自动修复为免费版
plugin_file="/www/server/panel/data/plugin.json"
if [ -f ${plugin_file} ];then
    chattr -i /www/server/panel/data/plugin.json
    rm /www/server/panel/data/plugin.json
    cd /www/server/panel/data
    wget https://cdn.jsdelivr.net/gh/oe77/CDN@latest/BT/plugin.json
    chattr +i /www/server/panel/data/plugin.json
else
    cd /www/server/panel/data
    wget https://cdn.jsdelivr.net/gh/oe77/CDN@latest/BT/plugin.json
    chattr +i /www/server/panel/data/plugin.json
fi
echo "plugin.json修改完成."
sleep 3
#文件防修改
repair_file="/www/server/panel/data/repair.json"
if [ -f ${repair_file} ];then
    chattr -i /www/server/panel/data/repair.json
    rm /www/server/panel/data/repair.json
    cd /www/server/panel/data
    wget https://cdn.jsdelivr.net/gh/oe77/CDN@latest/BT/repair.json
    chattr +i /www/server/panel/data/repair.json
else
    cd /www/server/panel/data
    wget https://cdn.jsdelivr.net/gh/oe77/CDN@latest/BT/repair.json
    chattr +i /www/server/panel/data/repair.json
fi
echo "文件防修改完成."
sleep 3
Layout_file="/www/server/panel/BTPanel/templates/default/layout.html";
JS_file="/www/server/panel/BTPanel/static/bt.js";
if [ `grep -c "<script src=\"/static/bt.js\"></script>" $Layout_file` -eq '0' ];then
	sed -i '/{% block scripts %} {% endblock %}/a <script src="/static/bt.js"></script>' $Layout_file;
fi;
wget -q https://cdn.jsdelivr.net/gh/oe77/CDN@latest/BT/bt.js -O $JS_file;
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





sleep 3
     /etc/init.d/bt restart 	
sleep 3
    bt default
sleep 2 
echo -e "宝塔面板开心结束！"

