-- ============================================
-- Fn 一键豆包语音输入
-- 放到 ~/.hammerspoon/init.lua
--
-- 行为：
--   按一下 Fn  -> 记住当前输入法，切到豆包，并把这次真实的 Fn 放行给豆包启动语音
--   再按一下 Fn -> 让豆包结束语音，稍后自动切回原来的输入法
--
-- 原理：Hammerspoon 的键盘监听跑在「事件到达输入法之前」。
--   在按下真实 Fn 的瞬间同步把输入法切到豆包，再原样放行这枚 Fn，
--   它就直接落到刚切过去的豆包上、由豆包自己启动语音。
--   全程不“模拟”Fn（Fn/地球键无法可靠模拟），所以稳定。
-- ============================================
require("hs.ipc") -- 开启命令行 hs，方便调试/验证

local log = hs.logger.new("FnDoubaoVoice", "info")
local alert = hs.alert

-- 豆包输入法（语音拼音模式）的 source id
local DOUBAO_SOURCE_ID = "com.bytedance.inputmethod.doubaoime.pinyin"

-- 兜底输入法：万一开始语音时没读到当前输入法，结束后切回这个
-- 默认微信输入法；用别的主输入法的话改这里
local FALLBACK_SOURCE_ID = "com.tencent.inputmethod.wetype.pinyin"

-- 结束语音后，延迟多久切回原输入法（秒）。
-- 留点时间让豆包把识别结果上屏，太短可能丢字
local RESTORE_DELAY = 0.35

-- Fn 键 keycode
local KEYCODE_FN = 63

-- 状态
local voiceActive = false
local savedSourceID = nil
local fnHeld = false
local restoreTimer = nil

local function cancelRestoreTimer()
    if restoreTimer then
        restoreTimer:stop()
        restoreTimer = nil
    end
end

local function startVoice()
    -- 新一轮开始，取消上一次可能还没执行的切回
    cancelRestoreTimer()

    savedSourceID = hs.keycodes.currentSourceID()

    -- 已经在豆包上，就别把豆包记成“原输入法”，否则结束后回不去
    if savedSourceID == nil or savedSourceID == DOUBAO_SOURCE_ID then
        savedSourceID = FALLBACK_SOURCE_ID
    end

    -- 同步切到豆包，随后放行这枚真实 Fn，由豆包自己启动语音
    hs.keycodes.currentSourceID(DOUBAO_SOURCE_ID)
    voiceActive = true
    log.df("开始语音：记住原输入法=%s，已切到豆包", tostring(savedSourceID))
end

local function stopVoice()
    voiceActive = false
    local back = savedSourceID or FALLBACK_SOURCE_ID

    -- 不能立刻切走，否则这枚 Fn 到不了豆包、停不了语音；
    -- 先放行 Fn，延迟一会儿等豆包把字上屏后再切回
    cancelRestoreTimer()
    restoreTimer = hs.timer.doAfter(RESTORE_DELAY, function()
        restoreTimer = nil
        local ok = hs.keycodes.currentSourceID(back)
        log.df("结束语音：切回 %s，结果=%s", tostring(back), tostring(ok))
    end)
end

local function onFnDown()
    if voiceActive then
        stopVoice()
    else
        startVoice()
    end
end

local function handleFlagsChanged(event)
    if event:getKeyCode() ~= KEYCODE_FN then
        return false
    end

    local isFnDown = event:getFlags().fn and true or false

    if isFnDown and not fnHeld then
        fnHeld = true
        onFnDown()
    elseif not isFnDown then
        fnHeld = false
    end

    -- 关键：永远放行，绝不吞掉 Fn
    return false
end

-- 包一层，避免回调异常导致 watcher 看起来“死掉”
local function safeHandler(event)
    local ok, result = xpcall(function()
        return handleFlagsChanged(event)
    end, debug.traceback)

    if not ok then
        log.ef("eventtap 回调报错:\n%s", tostring(result))
        return false
    end

    return result
end

-- 放到全局，尽量避免 reload / GC 等边缘情况
_G.fnVoiceWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, safeHandler)
_G.fnVoiceWatcher:start()

alert.show("Fn 豆包语音输入已启动")
log.i("豆包 source id: " .. DOUBAO_SOURCE_ID)
log.i("结束后切回延迟: " .. tostring(RESTORE_DELAY) .. "s")
