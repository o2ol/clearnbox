#!/bin/bash
set -euo pipefail
# Usage: ./scripts/publish_to_icloud.sh [version] [changelog-note]
# 固定目录形态对齐 toolbox / switchbox：
#   插件/cleanbox/
#   ├── README.md
#   ├── CURRENT
#   ├── latest/          # 固定文件名，覆盖更新
#   ├── versions/X.Y.Z/  # 只增不改
#   └── source/          # 说明文档（可选源码）

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VER="${1:-}"
NOTE="${2:-}"
if [[ -z "$VER" ]]; then
  VER=$(grep '^Version:' control | awk '{print $2}')
fi

IPA="$ROOT/CleanBox_${VER}.ipa"
TIPA="$ROOT/CleanBox_${VER}.tipa"
if [[ ! -f "$IPA" ]]; then
  echo "Missing $IPA — run ./scripts/build_ipa.sh first" >&2
  exit 1
fi
[[ -f "$TIPA" ]] || cp -f "$IPA" "$TIPA"

# 校验 IPA 结构
python3 - "$IPA" <<'PY'
import sys, zipfile
p = sys.argv[1]
z = zipfile.ZipFile(p)
names = z.namelist()
need = ("Payload/CleanBox.app/CleanBox", "Payload/CleanBox.app/Info.plist")
for n in need:
    if n not in names:
        raise SystemExit(f"invalid IPA: missing {n}")
print("IPA structure OK")
PY

ICLOUD_ROOT="/Users/macmini/Library/Mobile Documents/com~apple~CloudDocs/插件"
DEST="$ICLOUD_ROOT/cleanbox"
VDIR="$DEST/versions/$VER"

mkdir -p "$VDIR" "$DEST/latest" "$DEST/source"

cp -f "$IPA"  "$VDIR/CleanBox_${VER}.ipa"
cp -f "$TIPA" "$VDIR/CleanBox_${VER}.tipa"
cp -f "$IPA"  "$DEST/latest/CleanBox.ipa"
cp -f "$TIPA" "$DEST/latest/CleanBox.tipa"

cat > "$VDIR/README.txt" <<READ
净匣 CleanBox ${VER}

桌面名：净匣
Bundle：com.o2ol.cleanbox

安装：TrollStore 安装本目录 ipa/tipa，或使用 ../../latest/

功能：安全清理系统/用户 App 的 Caches、tmp、Logs、快照等，释放空间。
默认不删除 Documents / Preferences / Cookies。
READ

if [[ -n "$NOTE" ]]; then
  {
    echo "$VER"
    echo "$NOTE"
  } > "$VDIR/CHANGELOG.txt"
else
  cat > "$VDIR/CHANGELOG.txt" <<CHG
${VER}
- 系统/用户 App 列表、搜索、筛选
- 分类扫描与清理（Caches/tmp/Logs/快照/WebKit/Group）
- 批量一键清理 · 清理前确认/结束进程
- 深浅色外观 · 使用说明/版本/关于
CHG
fi

cp -f "$VDIR/README.txt"    "$DEST/latest/README.txt"
cp -f "$VDIR/CHANGELOG.txt" "$DEST/latest/CHANGELOG.txt"
printf '%s\n' "$VER" > "$DEST/CURRENT"

# 根目录固定说明（与 toolbox 一致）
cat > "$DEST/README.md" <<'MD'
# cleanbox（iCloud 固定目录）

路径：`iCloud Drive/插件/cleanbox`

## 目录结构

```
cleanbox/
├── README.md              # 本说明
├── CURRENT                # 当前稳定版本号（纯文本）
├── latest/                # 永远指向当前可安装包（覆盖更新）
│   ├── CleanBox.ipa
│   ├── CleanBox.tipa
│   ├── README.txt
│   └── CHANGELOG.txt
├── versions/              # 历史版本，只增不改
│   └── 1.0.0/
│       ├── CleanBox_1.0.0.ipa
│       ├── CleanBox_1.0.0.tipa
│       ├── README.txt
│       ├── CHANGELOG.txt
│       └── CleanBox_1.0.0.zip
└── source/                # 可选：说明 / 源码摘要
    └── README.md
```

## 版本规则

1. 每次发版新建 `versions/X.Y.Z/`，**不覆盖**旧版本目录
2. 发版同时更新 `latest/` 内文件（固定文件名，方便手机侧永远装 latest）
3. 更新 `CURRENT` 为 `X.Y.Z`
4. 桌面显示名：**净匣**（Bundle: `com.o2ol.cleanbox`）
5. 安装优先：`latest/CleanBox.tipa` 或 `latest/CleanBox.ipa`
6. 避免 301：等 iCloud 下完 → 拷到「我的 iPhone」→ TrollStore 安装

## 发版检查清单

- [ ] 编译 arm64 only
- [ ] IPA 内含 `Payload/CleanBox.app/CleanBox` + `Info.plist`
- [ ] `versions/X.Y.Z/` 写入 ipa/tipa/README/CHANGELOG
- [ ] `latest/` 覆盖为最新
- [ ] `CURRENT` 更新
- [ ] `source/README.md` 同步

## 产品说明

纯巨魔 TrollStore App：安全清理系统/用户 App 容器内可回收缓存。  
默认不删除 Documents / Preferences / Cookies，不卸载系统 App。
MD

# source 说明（对齐 switchbox/source）
cat > "$DEST/source/README.md" <<'SRC'
# CleanBox 净匣

纯 **TrollStore（巨魔）** App：安全清理 **系统 App / 用户 App** 容器内可回收数据，释放空间。

## 原理

1. 通过 LaunchServices 枚举已装 App 及数据容器路径  
2. 扫描 `Library/Caches`、`tmp`、`Logs`、快照等可回收目录体积  
3. 可选结束进程后删除目录内容（保留容器结构）  
4. **默认不碰** `Documents` / `Preferences` / `Cookies` / 钥匙串  

## 使用

1. 打开净匣 → 右上角 **扫描**  
2. 分段筛选：全部 / 系统 / 用户 / 可清理  
3. 点进 App → 勾选分类 → **清理所选**  
4. 或左上角 **一键清理** 当前列表中已扫描可清理项  
5. 列表内 **长按** 可快速安全清理  

## 安全策略

| 默认可清 | 不会动 |
|----------|--------|
| Caches / tmp / Logs | Documents |
| 启动快照 / 状态缓存 | Preferences |
| WebKit（设置可关） | Cookies |
| App Group 缓存 | 钥匙串 / App 本体 |
| HTTP 存储（默认关） | 不卸载系统 App |

## URL Scheme

```
cleanbox://list
cleanbox://settings
cleanbox://app?bundle=com.apple.MobileSMS
```

## 构建

源码工程：本机 `~/work/CleanBox`  
发版：`./scripts/build_ipa.sh && ./scripts/publish_to_icloud.sh`
SRC

(
  cd "$VDIR"
  zip -qr "CleanBox_${VER}.zip" \
    "CleanBox_${VER}.ipa" "CleanBox_${VER}.tipa" README.txt CHANGELOG.txt
)

echo "Published ${VER} -> $DEST"
echo "CURRENT=$(cat "$DEST/CURRENT")"
echo "---- tree ----"
find "$DEST" -maxdepth 3 \( -type f -o -type d \) | sort
ls -la "$DEST/latest"
ls -la "$VDIR"
