# Doubao IME Hammerspoon

把豆包输入法留给它最有价值的部分：免费、好用的语音输入。  
把你真正顺手的输入法，继续留作主输入法。

这个项目提供一份 [Hammerspoon](https://www.hammerspoon.org/) 配置和一个一键安装脚本，用来在 macOS 上自动处理：

- 切换到豆包输入法
- 唤起豆包语音输入
- 在操作结束后切回原输入法

目标很直接：不把豆包输入法当主输入法用，但把它当成主力语音输入工具来用。

## 为什么做这个项目

豆包输入法的 macOS 版本目前有一个很明显的矛盾：

- 它的常规输入法能力偏弱，不太适合当主输入法。
- 它的语音识别能力却不错，而且免费，单独拿来做语音输入很有价值。
- 但官方的产品形态更偏向“占住输入法入口”，导致日常使用上必须反复切换，体验并不顺。

“按一个键，立刻开始豆包语音输入，说完后回到原来的输入法”

## 它做了什么

仓库内有两个核心文件：

- [install-remote.sh](./install-remote.sh)：一行命令安装入口
- [install.sh](./install.sh)：安装脚本
- [init.lua](./init.lua)：Hammerspoon 配置

安装脚本会：

- 使用 `brew install --cask hammerspoon` 安装 Hammerspoon
- 把仓库里的 `init.lua` 复制到 `~/.hammerspoon/init.lua`
- 如果目标位置已有配置：
  - 内容相同则跳过
  - 内容不同则中文询问是否替换
  - 传入 `--force` 时直接覆盖
- 在覆盖前自动备份旧配置

## 一行命令安装

直接复制下面这条命令到终端执行：

```bash
curl -fsSL https://raw.githubusercontent.com/Paxxs/Doubao-ime-hammerspoon/main/install-remote.sh | bash
```

如果你明确要覆盖现有的 `~/.hammerspoon/init.lua`，可以用：

```bash
curl -fsSL https://raw.githubusercontent.com/Paxxs/Doubao-ime-hammerspoon/main/install-remote.sh | bash -s -- --force
```

这条命令会：

- 下载本仓库的安装包到临时目录
- 自动执行安装脚本
- 安装 Hammerspoon
- 复制 `init.lua` 到 `~/.hammerspoon/init.lua`

## 从仓库安装

如果你更希望先把仓库拉到本地，再手动执行安装脚本，也可以这样做：

```bash
git clone https://github.com/Paxxs/Doubao-ime-hammerspoon.git
cd Doubao-ime-hammerspoon
chmod +x ./install.sh
./install.sh
```

如果你明确要覆盖现有的 `~/.hammerspoon/init.lua`，可以用：

```bash
./install.sh --force
```

## 安装后怎么用

1. 打开 Hammerspoon。
2. 第一次运行时，为 Hammerspoon 授予 macOS 的“辅助功能”权限。
3. 在 Hammerspoon 菜单栏图标中点击 `Reload Config`。
4. 在任意输入框里**按一下 `Fn`**（地球键）：自动切到豆包并开始语音输入，开始说话。
5. 说完**再按一下 `Fn`**：豆包结束识别上屏，并自动切回你原本的输入法。

## 当前默认行为

当前 [init.lua](./init.lua) 的逻辑是：

- 监听 `Fn`（地球键）
- 第一次按 `Fn`：记住当前输入法 → 同步切到豆包 → 把这枚真实的 `Fn` 原样放行给豆包启动语音
- 第二次按 `Fn`：放行 `Fn` 让豆包结束语音 → 延迟一会儿（等识别结果上屏）后切回原输入法

> 关键点：脚本**不“模拟” `Fn`**。`Fn`/地球键无法被可靠地模拟，豆包能分辨真假。
> 这里利用的是「键盘监听早于输入法收到事件」——在你按下真实 `Fn` 的瞬间把输入法切到豆包，
> 再原样放行这枚 `Fn`，它就直接落到刚切过去的豆包上、由豆包自己启动语音，所以稳定。
>
> 你这版豆包的语音触发是「按一次 `Fn`」。如果你的豆包是别的快捷键（比如双击某键），
> 需要相应调整；可在豆包设置里把语音唤起方式设为「按一次 `Fn`」。

## 适合谁

- 不想把豆包输入法设成主输入法
- 又想高频使用它的免费语音输入
- 希望整个过程尽量像“按一个键就开说”
- 不想每次都手动切换输入法、再切回来

## 注意事项

- 只支持 macOS。
- 需要你已经安装豆包输入法，并把语音唤起方式设为「按一次 `Fn`」。
- 需要 Hammerspoon 获得“辅助功能”权限，否则无法监听 `Fn`、切换输入法。
- 安装脚本不会自动合并你原有的 Hammerspoon 配置，只会替换或保留现有 `~/.hammerspoon/init.lua`。
- 如果你已有自己的 Hammerspoon 配置，建议先看清提示；脚本在覆盖前会自动备份。

## 输入法 ID

当前配置按**输入法 source id** 切换（而不是按显示名），因为豆包/微信都会注册两个同名的输入源，按名字切容易切到“裸键盘”那个、而不是带语音的拼音模式。默认使用：

```lua
local TARGET_SOURCE_ID = "com.bytedance.inputmethod.doubaoime.pinyin"
```

如果你机器上的输入法 ID 不一致，可以这样查到真实 ID（在 Hammerspoon 控制台执行）：

```lua
print(hs.keycodes.currentSourceID())   -- 先手动切到豆包，再执行这行看它的 id
```

把得到的 id 填回 [init.lua](./init.lua) 的 `DOUBAO_SOURCE_ID`，然后在 Hammerspoon 中重新加载配置。

配置里还有两个可调项：

- `FALLBACK_SOURCE_ID`：兜底输入法（默认微信输入法 `com.tencent.inputmethod.wetype.pinyin`），仅在开始语音时没读到当前输入法的极端情况下，结束后切回它。用别的主输入法就改这里。
- `RESTORE_DELAY`：结束语音后多久切回原输入法（默认 `0.35` 秒）。如果偶尔发现识别结果还没上屏就被切走、丢字，把它调大一点。

## 可以继续自定义的地方

你可以按自己的习惯继续改：

- 触发按键（默认 `Fn`，keycode 63）
- 目标豆包输入法 `DOUBAO_SOURCE_ID`、兜底输入法 `FALLBACK_SOURCE_ID`
- 结束语音后切回的延迟 `RESTORE_DELAY`
- 与你现有 Hammerspoon 配置的整合方式
