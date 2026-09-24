# 极光面板

目前，全部端口转发功能均已支持 `IPV6` 。除 `iptables` 以外的转发方式，如果中转机器本身同时具备 `IPV4` 和 `IPV6` 网络访问能力，可以借助端口转发实现 `IPV4 to IPV6` 或 `IPV6 to IPV4`。

#### 面板（主控机）支持：

- 操作系统
- [x] CentOS 7+
- [x] Debian 8+
- [x] Ubuntu 18+
- CPU 架构
- [x] AMD64
- [x] ARM64
- 网络类型
- [x] IPV4
- [X] IPV6

特别说明：由于 docker 默认不开启 IPV6，如果需要在面板通过 IPV6 连接被控机 SSH，请在面板机器的配置文件中开启 `ipv6` 选项，并使用 `ip6tables` 命令为容器添加 IPV6 NAT，**命令中的 IPV6 地址不需要做任何更改**：

```shell
# 1. docker-compose.yml 配置开启 ipv6 选项，该配置文件默认在 ~/aurora/ 目录下
# 找到 enable_ipv6: false 该行，将 false 改为 true，重建容器
cd ~/aurora/ && docker-compose up -d
# 2. ip6tables 命令，直接复制粘贴回车即可（注意，重启系统会导致 ip6tables 规则被重置，需要手动重新添加）
ip6tables -t nat -A POSTROUTING -s fd00:ea23:9c80:4a54:e242:5f97::/96 -j MASQUERADE
```

#### 中转机器（被控机）支持：

- 操作系统
- [x] CentOS 7+
- [x] Debian 8+
- [x] Ubuntu 18+
- CPU 架构
- [x] AMD64
- [x] ARM64
- 网络类型
- [x] IPV4
- [X] IPV6

## 一键脚本

**使用一键脚本安装后，如果仍需使用一脚脚本更新，请勿更改数据库用户名和密码，否则会使得更新后无法同步更改后的数据库用户名和密码，导致数据库连接出错。**

```shell
bash <(curl -fsSL https://raw.githubusercontent.com/Taylor000/Aurora-panel/main/install.sh)
```

正式版前后端镜像的 AMD64/ARM64 归档保存在本仓库的 `image-archives` 分支。安装脚本会从该分支下载对应架构的分片，校验 SHA-256 后导入本机 Docker，再启动 Compose。


## 手动安装 — 面板主控机

如果一键脚本提示不支持当前系统版本时，可以尝试使用手动安装的方式。

### 1. 安装 docker（必须）

```shell
curl -fsSL https://get.docker.com | sudo bash -s docker && sudo systemctl enable --now docker

# 如果当前执行安装命令的不是 root 用户，请执行下面部分
# =================非root用户执行==================
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
# =================非root用户执行==================
```

### 2. 安装 docker-compose（必须）

```shell
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose

# 如果 /usr/local/bin 不在环境变量 PATH 里
# ============================可选================================
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
# ============================可选================================
```

### 3. 生成 SSH 密钥（建议，非必须）

此步操作目的为让面板服务器通过密钥连接被控机 ssh ，**可以提高被控机安全性，非必须步骤**，如果不采用密钥连接方式，后续在面板添加被控机使可以选择使用密码连接的方式。

```shell
# 如果面板服务器并没有已经生成好的 ssh 密钥
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
# 后面一直回车，跳过设置 passphase 即可
# 然后还需要将面板服务器 ~/.ssh/id_rsa.pub 里面的内容复制到每一台被控机的 ~/.ssh/authorized_keys 文件中去。
```

### 4. 安装并启动面板（必须）

```shell
mkdir -p ~/aurora && cd ~/aurora
wget https://raw.githubusercontent.com/Taylor000/Aurora-panel/main/docker-compose.yml -O docker-compose.yml
wget https://raw.githubusercontent.com/Taylor000/Aurora-panel/main/load-images.sh -O load-images.sh
bash load-images.sh
docker compose up -d
# 创建管理员用户（密码必须设置8位以上，否则无法登陆）
docker compose exec backend python app/initial_data.py
```
之后可以访问 `http://你的IP:8000` 进入面板。

## 配置说明

1. 修改所有的 `POSTGRES_USER` 和 `POSTGRES_PASSWORD` ，以及相应的 `DATABASE_URL` ，虽然数据库不公开，但使用默认的数据库用户和密码并不安全！

2. 后端默认会发送错误信息到 Sentry （**建议使用测试版本不要关闭，方便排查错误**），可能会导致信息泄漏，移除 `ENABLE_SENTRY: 'yes'` 就好。

3. 默认挂载 `~/.ssh/id_rsa` 作为连接服务器的密钥，如使用其他密钥或者不使用密钥可以删除配置文件中的 `- $HOME/.ssh/id_rsa:/app/ansible/env/ssh_key` 。


## 数据库备份与恢复

### 备份
```shell
docker-compose exec -T postgres pg_dump -d aurora -U [数据库用户名，默认aurora] -c > data.sql
```

### 恢复
```shell
# 首先先把所有服务停下
docker-compose down
# 只启动数据库服务
docker-compose up -d postgres
# 执行数据恢复
docker-compose exec -T postgres psql -d aurora -U [数据库用户名，默认aurora] < data.sql
# 然后正常启动所有服务
docker-compose up -d
```

## 卸载面板
```shell
docker-compose down
docker volume rm aurora_db-data
docker volume rm aurora_app-data
```

