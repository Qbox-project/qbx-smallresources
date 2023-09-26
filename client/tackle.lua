lib.addKeybind({
    name = 'tackle',
    description = 'Tackle',
    defaultKey = 'E',
    onReleased = function(self)
        if cache.vehicle then return end
        if QBXore.Functions.GetPlayerData().metadata["ishandcuffed"] and not IsPedRagdoll(PlayerPedId()) then return end   
        if IsPedSprinting(PlayerPedId()) or IsPedRunning(PlayerPedId()) then
            local coords = GetEntityCoords(PlayerPedId())
            local targetId, targetPed, _ = lib.getClosestPlayer(coords, 1.6, false)
            if not targetPed then return end
            if IsPedInAnyVehicle(targetPed, true) then return end
            self:disable(true)
            TriggerServerEvent('tackle:server:TacklePlayer', GetPlayerServerId(targetId))
            lib.requestAnimDict('swimming@first_person@diving')
            TaskPlayAnim(PlayerPedId(), 'swimming@first_person@diving', 'dive_run_fwd_-45_loop', 3.0, 3.0, -1, 49, 0, false, false, false)
            Wait(250)
            ClearPedTasks(PlayerPedId())
            SetPedToRagdoll(PlayerPedId(), 150, 150, 0, 0, 0, 0)
            RemoveAnimDict('swimming@first_person@diving')
            SetTimeout(1000, function ()
                self:disable(false)
            end)
        end
    end
})

RegisterNetEvent('tackle:client:GetTackled', function()
	SetPedToRagdoll(PlayerPedId(), 7000, 7000, 0, 0, 0, 0)
end)
