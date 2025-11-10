ESX = exports["es_extended"]:getSharedObject()

local isUIOpen = false
local currentATM = nil
local inBank = false

-- Fonction pour afficher les notifications
RegisterNetEvent('bassebank:notify')
AddEventHandler('bassebank:notify', function(type, message)
    ESX.ShowNotification(message)
end)

-- Fonction pour mettre à jour le solde
RegisterNetEvent('bassebank:updateBalance')
AddEventHandler('bassebank:updateBalance', function()
    if isUIOpen then
        -- Demander au serveur les soldes à jour
        ESX.TriggerServerCallback('bassebank:getBalances', function(balances)
            SendNUIMessage({
                action = 'updateBalance',
                bank = balances.bank,
                cash = balances.cash
            })
        end)
    end
end)

-- Création des blips pour les banques
CreateThread(function()
    for _, bank in pairs(Config.Banks) do
        if bank.blip then
            local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
            SetBlipSprite(blip, Config.BlipSprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipColour(blip, Config.BlipColor)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(bank.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

-- Détection des banques
CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, bank in pairs(Config.Banks) do
            local distance = #(playerCoords - bank.coords)

            if distance < 15.0 then
                sleep = 0
                DrawMarker(1, bank.coords.x, bank.coords.y, bank.coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 1.5, 1.0, 0, 255, 0, 100, false, true, 2, false, nil, nil, false)

                if distance < 1.5 then
                    inBank = true
                    ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour accéder à la banque')

                    if IsControlJustReleased(0, 38) then -- E
                        OpenBankUI(false)
                    end
                else
                    if inBank then
                        inBank = false
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Détection des ATM
CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, model in pairs(Config.ATMModels) do
            local atm = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 1.5, model, false, false, false)

            if atm ~= 0 then
                sleep = 0
                local atmCoords = GetEntityCoords(atm)
                local distance = #(playerCoords - atmCoords)

                if distance < 1.5 then
                    currentATM = atm
                    ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour accéder à l\'ATM')

                    if IsControlJustReleased(0, 38) then -- E
                        OpenBankUI(true)
                    end
                else
                    if currentATM == atm then
                        currentATM = nil
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- Ouverture de l'interface bancaire
function OpenBankUI(isATM)
    if isUIOpen then return end

    ESX.TriggerServerCallback('bassebank:getBalances', function(balances)
        ESX.TriggerServerCallback('bassebank:getTransactions', function(transactions)
            ESX.TriggerServerCallback('bassebank:getSavings', function(savings)
                ESX.TriggerServerCallback('bassebank:getPlayers', function(players)
                    SetNuiFocus(true, true)
                    isUIOpen = true

                    SendNUIMessage({
                        action = 'openBank',
                        isATM = isATM,
                        bank = balances.bank,
                        cash = balances.cash,
                        savings = savings,
                        transactions = transactions,
                        players = players
                    })
                end)
            end)
        end)
    end)
end

-- Fermeture de l'interface
RegisterNUICallback('closeBank', function(data, cb)
    cb('ok')
    SetNuiFocus(false, false)
    isUIOpen = false

    -- Force la réactivation des contrôles
    SetTimeout(100, function()
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        DisplayRadar(true)
    end)
end)

-- Fermer avec ESC
CreateThread(function()
    while true do
        Wait(0)
        if isUIOpen then
            -- Désactiver les contrôles pendant que l'UI est ouverte
            DisableControlAction(0, 1, true) -- Disable mouse look
            DisableControlAction(0, 2, true) -- Disable mouse look
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride

            -- Vérifier si ESC est pressé
            if IsControlJustReleased(0, 322) or IsControlJustReleased(0, 177) then -- ESC ou BACKSPACE
                SendNUIMessage({
                    action = 'forceClose'
                })
                SetNuiFocus(false, false)
                isUIOpen = false
                SetNuiFocusKeepInput(false)
                DisplayRadar(true)
            end
        else
            Wait(500)
        end
    end
end)

-- Dépôt
RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('bassebank:deposit', tonumber(data.amount))
    cb('ok')
end)

-- Retrait
RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('bassebank:withdraw', tonumber(data.amount), data.isATM)
    cb('ok')
end)

-- Virement
RegisterNUICallback('transfer', function(data, cb)
    TriggerServerEvent('bassebank:transfer', tonumber(data.target), tonumber(data.amount))
    cb('ok')
end)

-- Dépôt épargne
RegisterNUICallback('savingsDeposit', function(data, cb)
    TriggerServerEvent('bassebank:savingsDeposit', tonumber(data.amount))
    cb('ok')
end)

-- Retrait épargne
RegisterNUICallback('savingsWithdraw', function(data, cb)
    TriggerServerEvent('bassebank:savingsWithdraw', tonumber(data.amount))
    cb('ok')
end)

-- Commande pour ouvrir la banque (debug ou pour téléphone)
RegisterCommand('bank', function()
    if not isUIOpen then
        OpenBankUI(false)
    end
end, false)

-- Export pour d'autres scripts (téléphone, etc.)
exports('OpenBankUI', OpenBankUI)

-- Nettoyage
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if isUIOpen then
            SetNuiFocus(false, false)
        end
    end
end)
