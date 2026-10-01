# git-gui 简体中文翻译（Git for Windows）

让 Git 自带的图形界面 **Git Gui** 显示简体中文。

Git for Windows 官方**不编译任何 git-gui 翻译**，`share/git-gui/lib/msgs` 目录默认不存在。本仓库提供已编译好的 `zh_cn.msg`，放进去即可生效。

| 项目 | 值 |
|------|-----|
| 适用 Git for Windows | **2.55.0.windows.5** |
| 适用 git-gui | **0.21.GITGUI** |
| 翻译条目 | 605 条 |
| 运行时 msgid 覆盖 | 557 个，其中 551 已译 |
| 未译 6 条 | 格式片段（` - %s:`、`%s (%s):`）与品牌名（`Git Gui`、`Git Bash`、`URL`），属合理保留 |
| 许可证 | GPL-2.0 |

---

## 一、安装

以**管理员身份**打开 PowerShell，进入本仓库目录执行：

```powershell
$dst = 'C:\Program Files\Git\mingw64\share\git-gui\lib\msgs'
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item .\messages\zh_cn.msg $dst -Force
```

重启 Git Gui 即可。入口通常在开始菜单，或命令行 `git gui`。

> [!note] 为什么需要管理员
> `C:\Program Files\` 需要提权写入。目录 `msgs` 由本安装步骤创建，Git for Windows 升级时可能被清除，届时重新执行一次即可。

### 验证安装

```powershell
& 'C:\Program Files\Git\mingw64\bin\tclsh86.exe' tools\final_check.tcl
```

期望输出 `loaded=1`、`translated: 551`。

---

## 二、切回英文

任选一种：

**方式 A —— 改环境变量（推荐，无需提权）**

```cmd
setx LANG en_US.UTF-8
```

git-gui 按 `LC_ALL` → `LC_MESSAGES` → `LANG` 选择 locale，查不到对应 `.msg` 文件时 `mc` 原样返回英文原文，因此设成 `en_US.UTF-8`（`en_us.msg` 不存在）即回落英文。改回中文用 `setx LANG zh_CN.UTF-8`，恢复默认用：

```powershell
[Environment]::SetEnvironmentVariable('LANG',$null,'User')
```

> 设完需注销重登或重启 `explorer.exe`，因为桌面进程持有的是旧环境变量快照。

**方式 B —— 改名 msg 文件**

```
zh_cn.msg  →  zh_cn.msg.off
```

**原理**：三个环境变量全空时，msgcat 读注册表 `PreferredUILanguages`（`zh-CN`）→ 加载 `zh_cn.msg`。

---

## 三、Git 升级后怎么办

Git for Windows 升级通常**整目录替换**，`zh_cn.msg` 会被清除；且 git-gui 的界面字符串可能增减，旧翻译未必覆盖新版。

复用步骤：

1. **重新提取运行时 msgid**
   ```bash
   tclsh tools/extract3.tcl          # 输出 tools/runtime3.txt
   ```
   源码路径非标准时：`GITGUI_SRC_ROOT=/path/to/mingw64 tclsh tools/extract3.tcl`

2. **与现有译文求差** → 只有新增/改动的字符串需要翻译（`source/translations.py` 是翻译记忆库，可在此基础上增补）

3. **编译出新 msg**
   ```bash
   tclsh po2msg.sh source/zh_cn.po out/zh_cn.msg
   ```

4. **校验**
   ```bash
   tclsh tools/final_check.tcl       # 占位符与覆盖率
   tclsh tools/smoke3.tcl            # 真实菜单串冒烟
   ```

5. **重新安装**（同第一节）

> [!warning] 注意
> - `git-gui.tcl` 行号会随版本漂移，以逻辑为准
> - 若新版 Git for Windows 开始自带官方翻译，应先判断能否直接用官方的
> - `msgcat` 升级可能改变 locale 判定逻辑（低概率）

---

## 四、目录结构

```
.
├── README.md
├── LICENSE                  GPL-2.0 全文
├── messages/
│   └── zh_cn.msg            安装产物，605 条，纯 ASCII（非 ASCII 以 \uXXXX 表示）
├── source/
│   ├── translations.py      自译补丁 245 条（翻译记忆库）
│   └── zh_cn.po             git 上游官方简中翻译（2007/2008，366 条）
├── tools/
│   ├── extract3.tcl         从 git-gui 源码提取运行时真实 msgid
│   ├── final_check.tcl      覆盖率 + 加载校验
│   ├── smoke3.tcl           真实菜单/按钮串冒烟测试
│   ├── runtime3.txt         msgid 基线（base64 每行一条，升级后 diff 用）
│   └── checked_final.txt    校验明细（生成物，已 gitignore）
└── po2msg.sh                git 上游官方编译脚本（纯 Tcl，可当 msgfmt 用）
```

### 工具依赖

- `tclsh`（Linux 直接用系统包；Windows 用 `C:\Program Files\Git\mingw64\bin\tclsh86.exe`）
- **不需要 `msgfmt`** —— `po2msg.sh` 是替代品

> [!tip] 跨平台注意
> 脚本用 `[info script]` 定位自身，可在任意工作目录运行。但 WSL 的 `tclsh` 访问不了 `C:/` 路径，**校验步骤必须用 Windows 侧的 `tclsh86.exe`**。

---

## 五、原理（TL;DR）

1. `git-gui.tcl:310` `package require msgcat` → 触发 `msgcat::Init`
2. `Init` 按 `LC_ALL` → `LC_MESSAGES` → `LANG` 取第一个非空且合法的值，`ConvertLocale` 丢掉 `.UTF-8` 后 `mclocale` 转小写 → `zh_cn`
3. 三级全空则读注册表 `HKCU\Control Panel\Desktop\PreferredUILanguages` → `zh-CN` → `zh_cn`
4. `GetPreferences` 生成回退链 `zh_cn → zh → {}`，`msgcat::Load` 依次找 `<locale>.msg`（空 locale 对应 `ROOT.msg`）
5. `git-gui.tcl:351` `::msgcat::mcload $oguimsg`，`oguirel` 硬编码 `{1}` → 目录固定为 `mingw64/share/git-gui/lib/msgs`
6. 查不到 msgid 时 `mc` **原样返回英文**，所以文件缺失 = 自动英文界面

---

## 六、许可证与致谢

- 本项目整体采用 **GPL-2.0**（见 [LICENSE](LICENSE)），与 git-gui 本身一致。
- `source/zh_cn.po` 与 `po2msg.sh` 来自 [git/git](https://github.com/git/git) 的 `git-gui/` 目录：
  - `zh_cn.po` — `Copyright (C) 2007 Shawn Pearce`，原译者 Xudong Guan、Eric Miao 等，文件头声明 *"distributed under the same license as the git-gui package"*
  - `po2msg.sh` — git 官方脚本，作为 `msgfmt` 的替代品
- 简体中文补译基于上述官方翻译扩展而来，故同样以 GPL-2.0 发布。
- 繁体中文方案参考：[etcaa429/git-gui-2-zh-tw](https://github.com/etcaa429/git-gui-2-zh-tw)

### 术语表（沿用官方 po 头部约定）

repository 版本库 ｜ commit 提交 ｜ branch 分支 ｜ tag 标签 ｜ merge 合并 ｜ stage 缓存 ｜ amend 修正 ｜ reset 复位
