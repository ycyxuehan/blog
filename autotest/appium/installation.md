# 安装appium

本安装文档仅在appium1.21上测试通过。

## 配置运行环境

### 运行环境依赖项目

环境|版本|说明
--|--|--
MAC OS |11.4|
xcode|9.4.3
nodejs|12
python|3.5.8
Homebrew|3.2.1|

### 安装依赖

#### Homebrew

官方安装方法

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

由于官方地址通常会被墙，建议使用gitee上的

```
/bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
```

#### nodejs

使用`brew`安装

```
brew install nodejs
```

下载官方二进制包

```
cd /opt
sudo wget https://nodejs.org/dist/v14.17.3/node-v14.17.3-darwin-x64.tar.gz
sudo tar node-v14.17.3-darwin-x64.tar.gz
sudo ln -s node-v14.17.3-darwin-x64 node
sudo echo 'PATH=$PATH:/opt/node/bin' >> /etc/profile
```

#### appium

下载官方版本安装

```
https://github.com/appium/appium-desktop/releases/download/v1.21.0/Appium-mac-1.21.0.dmg
```

#### appium-doctor

使用npm安装

```
npm install -g appium-doctor
```

#### 其他依赖

暂时还没统计。

### 配置环境

使用 `appium-doctor --ios`检测，确保每项都是`√`

