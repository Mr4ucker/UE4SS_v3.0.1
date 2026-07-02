NotifyOnNewObject("/Script/Dominion.BuildingDamageComponent", function(Object)
    ExecuteInGameThread(function()
        if Object and Object:IsValid() then
            Object:SetPropertyValue("bCanTakeDamage", false)
            local parent = Object:GetOwner() or Object:TryGetParentObject()
            if parent and parent:IsValid() then
                parent:SetPropertyValue("bCanBeDamaged", false)
            end
        end
    end)
end)
