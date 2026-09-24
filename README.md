# 极光面板（自用）

本仓库固定正式版，不跟随上游更新。面板镜像保存在本仓库的 `image-archives` 分支，支持 AMD64 和 ARM64。

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
cd ~/aurora/ && docker compose up -d
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

一键脚本提供安装、启动、停止、备份、恢复和卸载等菜单操作。「更新」只重新加载本仓库固定的正式版；如果手动改过数据库用户名或密码，不要使用该菜单项。

```shell
bash <(curl -fsSL https://raw.githubusercontent.com/Taylor000/Aurora-panel/main/install.sh)
```

安装脚本会从本仓库下载对应架构的镜像分片，校验 SHA-256 后导入本机 Docker，再启动 Compose。安装机仍需访问 GitHub Raw、Docker 安装源和 Redis/PostgreSQL 镜像源。


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

### 2. 安装 Docker Compose（如尚未安装）

```shell
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -fL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version
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

1. 手动安装时可在**首次启动前**修改 `POSTGRES_USER`、`POSTGRES_PASSWORD`、`DATABASE_URL` 和 `ASYNC_DATABASE_URL`。已安装后不能只修改 Compose 文件来更换数据库密码。

2. Worker 默认启用 Sentry；不需要时可将 `ENABLE_SENTRY` 改为 `'no'`。首次安装后用一键脚本菜单修改默认安全密钥。

3. SSH 私钥挂载默认被注释。需要使用密钥连接被控机时，在 `docker-compose.yml` 中启用对应的 `volumes` 配置。


## 数据库备份与恢复

以下命令使用默认数据库名和用户名 `aurora`；如已修改，请替换相应参数。

### 备份
```shell
cd ~/aurora
docker compose exec -T postgres pg_dump -d aurora -U aurora --clean --if-exists > data.sql
```

### 恢复
```shell
cd ~/aurora
docker compose stop worker backend nginx
docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -d aurora -U aurora < data.sql
docker compose up -d
```

## 卸载面板

以下命令会同时删除数据库和应用数据卷。

```shell
cd ~/aurora
docker compose down
docker volume rm aurora_db-data aurora_app-data
```
