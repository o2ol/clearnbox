# 净匣 CleanBox

[English](./README_EN.md) · [Releases](https://github.com/o2ol/clearnbox/releases) · [MIT](./LICENSE)

TrollStore 工具：安全清理系统/用户 App 可回收缓存，释放空间。

- **作者：** [o2ol](https://github.com/o2ol)
- **版本：** 0.0.1
- **Bundle：** `com.o2ol.cleanbox`

## 支持

| 项目 | 要求 |
|------|------|
| 系统 | iOS / iPadOS 15.0+ |
| 架构 | arm64 |
| 设备 | iPhone / iPad |
| 安装 | TrollStore |

## 功能

- 储存概览与可释放扫描
- 系统/用户 App 列表、搜索、筛选、排序
- 单项 / 批量安全清理
- 深浅色、URL Scheme

## 安全

默认可清：`Caches`（跳过登录相关）、`tmp`、`Logs`、快照、可选 App Group。

不清理：`Documents`、`Preferences`、Cookies、钥匙串、WebKit/HTTP 存储、App 本体。

## 安装

1. 从 [Releases](https://github.com/o2ol/clearnbox/releases) 下载 `.tipa` / `.ipa`
2. 用 TrollStore 安装
3. 打开 → 扫描 → 清理

## 构建

```bash
export THEOS=/path/to/theos
./scripts/build_ipa.sh
```

```bash
./scripts/publish_github_release.sh   # 需 gh auth login
```

## Scheme

```
cleanbox://list
cleanbox://settings
cleanbox://app?bundle=com.apple.MobileSMS
```

## 免责

仅供个人维护使用，风险自负。
