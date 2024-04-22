local recoils = require 'qbx_recoils.config'

CreateThread(function()
    while true do
        if IsPedShooting(cache.ped) and not IsPedDoingDriveby(cache.ped) then
            local _, wep = GetCurrentPedWeapon(cache.ped, true)
            if recoils[wep] and recoils[wep] ~= 0 then
                -- luacheck: ignore
                local tv = 0
                if GetFollowPedCamViewMode() ~= 4 then
                    repeat
                        Wait(0)
                        local p = GetGameplayCamRelativePitch()
                        SetGameplayCamRelativePitch(p + 0.1, 0.2)
                        tv += 0.1
                    until tv >= recoils[wep]
                else
                    repeat
                        Wait(0)
                        local p = GetGameplayCamRelativePitch()
                        if recoils[wep] > 0.1 then
                            SetGameplayCamRelativePitch(p + 0.6, 1.2)
                            tv += 0.6
                        else
                            SetGameplayCamRelativePitch(p + 0.016, 0.333)
                            tv += 0.1
                        end
                    until tv >= recoils[wep]
                end
            end
        end
        Wait(350)
    end
end)
