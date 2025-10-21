local VORPcore = exports.vorp_core:GetCore()

RegisterNetEvent("rs_pedmenu:attack")

AddEventHandler("rs_pedmenu:attack", function(target, entity)
	TriggerClientEvent("rs_pedmenu:attack", target, source, entity)
end)

RegisterServerEvent("rs_pedmenu:requestPed")
AddEventHandler("rs_pedmenu:requestPed", function(pedName)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local playerName = Character.firstname .. " " .. Character.lastname
    local identifier = Character.charIdentifier

    exports.oxmysql:insert(
        "INSERT INTO ped_requests (identifier, playerName, ped) VALUES (?,?,?)",
        {identifier, playerName, pedName},
        function()
            TriggerClientEvent("vorp:TipRight", _source, Config.Text.Notify.SentAdmin, 4000)
        end
    )
end)

RegisterServerEvent("rs_pedmenu:getPendingRequests")
AddEventHandler("rs_pedmenu:getPendingRequests", function()
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    if Character.group ~= "admin" then
        TriggerClientEvent("vorp:TipRight", _source, Config.Text.Notify.NotPermission,  4000)
        return
    end

    exports.oxmysql:execute("SELECT id, playerName, ped FROM ped_requests WHERE status='pending'", {}, function(result)
        if #result == 0 then
        end
        TriggerClientEvent("rs_pedmenu:returnPendingRequests", _source, result)
    end)
end)

RegisterServerEvent("rs_pedmenu:authorizePed")
AddEventHandler("rs_pedmenu:authorizePed", function(requestId)
    local _source = source
    exports.oxmysql:execute("SELECT * FROM ped_requests WHERE id = ? AND status='pending'", {requestId}, function(result)
        if result[1] then
            local req = result[1]
            exports.oxmysql:insert("INSERT INTO user_peds (identifier, playerName, ped) VALUES (?,?,?)", {
                req.identifier, req.playerName, req.ped
            })
            exports.oxmysql:execute("DELETE FROM ped_requests WHERE id = ?", {requestId})

            TriggerClientEvent("vorp:TipRight", _source, Config.Text.Notify.AuthorizedCorrected, 4000)
        else
            TriggerClientEvent("vorp:TipRight", _source, Config.Text.Notify.AuthorizedError, 4000)
        end
    end)
end)

RegisterServerEvent("rs_pedmenu:rejectPed")
AddEventHandler("rs_pedmenu:rejectPed", function(requestId)
    local _source = source
    exports.oxmysql:execute("DELETE FROM ped_requests WHERE id = ?", {requestId}, function(affected)
        if affected and affected.affectedRows > 0 then
            TriggerClientEvent("vorp:TipRight", _source, Config.Text.Notify.DeleteCorrected, 4000)
        else
            TriggerClientEvent("vorp:TipRight", _source, Config.Text.Notify.DeleteError, 4000)
        end
    end)
end)

RegisterServerEvent("rs_pedmenu:getMyPeds")
AddEventHandler("rs_pedmenu:getMyPeds", function()
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local identifier = Character.charIdentifier

    exports.oxmysql:execute("SELECT ped FROM user_peds WHERE identifier = ?", {identifier}, function(result)
        local peds = {}
        for _, row in ipairs(result) do table.insert(peds, row.ped) end
        TriggerClientEvent("rs_pedmenu:returnMyPeds", _source, peds)
    end)
end)

RegisterServerEvent("rs_pedmenu:getUserPeds")
AddEventHandler("rs_pedmenu:getUserPeds", function()
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    if Character.group ~= "admin" then
        TriggerClientEvent("vorp:TipRight", _source, Config.Text.Notify.NotPermission, 4000)
        return
    end

    exports.oxmysql:execute("SELECT identifier, playerName, ped FROM user_peds", {}, function(result)
        if #result == 0 then
        end
        TriggerClientEvent("rs_pedmenu:returnUserPeds", _source, result)
    end)
end)

RegisterServerEvent("rs_pedmenu:removePed")
AddEventHandler("rs_pedmenu:removePed", function(playerName, pedName)
    local _source = source
    exports.oxmysql:execute("DELETE FROM user_peds WHERE playerName = ? AND ped = ?", {playerName, pedName}, function(affected)
        if affected and affected.affectedRows > 0 then
            TriggerClientEvent("vorp:TipRight", _source, Config.Text.Notify.DeletePedCorrected, 4000)
        else
            TriggerClientEvent("vorp:TipRight", _source, Config.Text.Notify.DeletePedError, 4000)
        end
    end)
end)

RegisterCommand(Config.Command.Admin, function(source)
    local user = VORPcore.getUser(source).getUsedCharacter
    if user.group == "admin" then
        TriggerClientEvent("rs_pedmenu:openAdminMenu", source)
    else
        TriggerClientEvent("vorp:TipRight", source, Config.Text.Notify.NotPermission, 4000)
    end
end)