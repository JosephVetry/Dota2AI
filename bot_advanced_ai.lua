-- Backward-compatibility shim.
-- Runtime bot scripts should use: require(GetScriptDirectory()..'/FunLib/advanced_bot_ai')

if GetScriptDirectory ~= nil then
    return require(GetScriptDirectory() .. '/FunLib/advanced_bot_ai')
end

return require('bots.FunLib.advanced_bot_ai')
