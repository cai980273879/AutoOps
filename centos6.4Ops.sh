#!/bin/bash
#优化开始

#优化1  开机启动静态网卡，记得从此处需要修改IP地址以及DNS
cat >/etc/sysconfig/network-scripts/ifcfg-eth0<<EOF
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=192.168.x.x
NETMASK=255.255.255.0
GATEWAY=192.168.x.254
DNS1=x.x.x.x
DNS2=114.114.114.114
EOF

#优化2    更改hostname:xxx-demo这里需要修改
sed -i 's#HOSTNAME=\(.*\)#HOSTNAME=xxx-demo#g' /etc/sysconfig/network
hostname xxx-demo
sed -i 's#127\(.*\)#127\1\ xxx-demo#g' /etc/hosts
/etc/init.d/network restart

#最小化安装是没有安装wget工具的，必须在这里安装
yum -y install wget

#优化3 换163源
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget http://mirrors.163.com/.help/CentOS6-Base-163.repo  -O /etc/yum.repos.d/CentOS-Base.repo
#centos7 wget http://mirrors.163.com/.help/CentOS7-Base-163.repo  -O /etc/yum.repos.d/CentOS-Base.repo
#这个脚本可能不能使用在centos7上，由于centos6过度到centos7有部分系统修改
yum clean all
yum makecache
yum -y groupinstall "Base"
yum -y groupinstall "Compatibility libraries"
yum -y groupinstall "Debugging Tools"
yum -y groupinstall "Development tools"
yum -y install telnet dos2unix tree lftp
yum -y update


#优化4    关闭selinux
setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config

#优化5 清空iptables规则
iptables -F
/etc/init.d/iptables save
 
#优化6 精简开机启动服务
for service in `chkconfig --list|grep 3:on|awk '{print $1}'|grep -Ev "crond|network|rsyslog|sysstat|sshd|iptables|ip6tables"`
do chkconfig $service off
done
 
#优化7 更改ssh设置
sed -i 's/#Port\ 22/Port\ 52113/g' /etc/ssh/sshd_config
sed -i 's/#ListenAddress 0.0.0.0/ListenAddress\ 192.168.122.147/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin\ yes/PermitRootLogin\ no/g' /etc/ssh/sshd_config
sed -i 's/#GSSAPIAuthentication\ no/GSSAPIAuthentication\ no/g' /etc/ssh/sshd_config
sed -i 's/GSSAPIAuthentication\ yes/#GSSAPIAuthentication\ yes/g' /etc/ssh/sshd_config
sed -i 's/#UseDNS\ yes/UseDNS\ no/g' /etc/ssh/sshd_config
/etc/init.d/sshd restart



#优化8    添加普通用户并sudo授权普通用户:记得修改nobody
useradd nobody
echo "123456"|passwd --stdin nobody
history -c
echo "nobody  ALL=(ALL)       NOPASSWD: ALL" >>/etc/sudoers

#优化9  时间同步
echo "*/1 */1 * * * /usr/sbin/ntpdate ntp.api.bz  >/dev/null 2>&1 && /sbin/hwclock -w" >>/var/spool/cron/root

#优化10  加大服务器文件描述符
echo '* - nofile 65535' >> /etc/security/limits.conf

#优化11 内核调优
echo "net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.ip_local_port_range = 4000 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384
net.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_tcp_timeout_established = 180
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120" >>/etc/sysctl.conf
sysctl -p
 
#优化12 隐藏linux系统版本
:>/etc/issue
:>/etc/issue.net
 
#优化13 锁定系统关键文件
chattr +i /etc/passwd /etc/group /etc/shadow /etc/gshadow /etc/inittab
##将chattr改名
/bin/mv /usr/bin/chattr /usr/bin/badboy



#优化14 设置全局变量
##设置自动退出终端，防止非法关闭ssh客户端造成登录进程过多，可以设置大一些，单位为秒
echo "TMOUT=3600">> /etc/profile
##历史命令记录数量设置为10条
sed -i 's/HISTSIZE=1000/HISTSIZE=10/g' /etc/profile
##立即生效
source /etc/profile


#优化15 添加外部扩展源
yum install -y epel-release
yum -y update

#当然此处还很多很多很多的配置服务
#这里便按照个人需求写啦




#重启
reboot

