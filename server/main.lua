ESX = exports["es_extended"]:getSharedObject()

-- Détection de l'inventaire utilisé
local UseJaksamInventory = GetResourceState('jaksam_inventory') == 'started'

-- Fonctions helper pour la compatibilité avec jaksam_inventory
local function GetPlayerMoney(xPlayer)
    if UseJaksamInventory then
        return exports['jaksam_inventory']:GetMoney(xPlayer.source, 'money') or 0
    else
        return xPlayer.getMoney()
    end
end

local function GetPlayerBank(xPlayer)
    if UseJaksamInventory then
        return exports['jaksam_inventory']:GetMoney(xPlayer.source, 'bank') or 0
    else
        return xPlayer.getAccount('bank').money
    end
end

local function AddPlayerMoney(xPlayer, amount)
    if UseJaksamInventory then
        exports['jaksam_inventory']:AddMoney(xPlayer.source, 'money', amount)
    else
        xPlayer.addMoney(amount)
    end
end

local function RemovePlayerMoney(xPlayer, amount)
    if UseJaksamInventory then
        exports['jaksam_inventory']:RemoveMoney(xPlayer.source, 'money', amount)
    else
        xPlayer.removeMoney(amount)
    end
end

local function AddPlayerBank(xPlayer, amount)
    if UseJaksamInventory then
        exports['jaksam_inventory']:AddMoney(xPlayer.source, 'bank', amount)
    else
        xPlayer.addAccountMoney('bank', amount)
    end
end

local function RemovePlayerBank(xPlayer, amount)
    if UseJaksamInventory then
        exports['jaksam_inventory']:RemoveMoney(xPlayer.source, 'bank', amount)
    else
        xPlayer.removeAccountMoney('bank', amount)
    end
end

if UseJaksamInventory then
    print('^2[BasseBank] ^7Détection: jaksam_inventory utilisé')
else
    print('^2[BasseBank] ^7Détection: ESX standard utilisé')
end

-- Callback pour obtenir les soldes
ESX.RegisterServerCallback('bassebank:getBalances', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb({cash = 0, bank = 0})
        return
    end

    local cash = GetPlayerMoney(xPlayer)
    local bank = GetPlayerBank(xPlayer)

    cb({cash = cash, bank = bank})
end)

-- Fonction pour enregistrer une transaction
local function LogTransaction(identifier, type, amount, fromIdentifier, toIdentifier, description)
    MySQL.insert('INSERT INTO bassebank_transactions (identifier, type, amount, from_identifier, to_identifier, description) VALUES (?, ?, ?, ?, ?, ?)', {
        identifier, type, amount, fromIdentifier, toIdentifier, description
    })
end

-- Fonction pour obtenir l'historique des transactions
ESX.RegisterServerCallback('bassebank:getTransactions', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.query('SELECT * FROM bassebank_transactions WHERE identifier = ? OR from_identifier = ? OR to_identifier = ? ORDER BY date DESC LIMIT 50', {
        xPlayer.identifier, xPlayer.identifier, xPlayer.identifier
    }, function(result)
        cb(result)
    end)
end)

-- Fonction pour obtenir le solde du compte d'épargne
ESX.RegisterServerCallback('bassebank:getSavings', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.query('SELECT * FROM bassebank_savings WHERE identifier = ?', {
        xPlayer.identifier
    }, function(result)
        if result[1] then
            cb(result[1].amount)
        else
            cb(0)
        end
    end)
end)

-- Dépôt d'argent
RegisterNetEvent('bassebank:deposit')
AddEventHandler('bassebank:deposit', function(amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then return end

    if amount <= 0 then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Montant invalide')
        return
    end

    local playerMoney = GetPlayerMoney(xPlayer)

    if amount > playerMoney then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Vous n\'avez pas assez d\'argent liquide')
        return
    end

    local fee = math.floor(amount * Config.DepositFee)
    local finalAmount = amount - fee

    RemovePlayerMoney(xPlayer, amount)
    AddPlayerBank(xPlayer, finalAmount)

    LogTransaction(xPlayer.identifier, 'depot', finalAmount, nil, nil, 'Dépôt en banque')

    TriggerClientEvent('bassebank:notify', _source, 'success', 'Vous avez déposé $' .. finalAmount)
    TriggerClientEvent('bassebank:updateBalance', _source)
end)

-- Retrait d'argent
RegisterNetEvent('bassebank:withdraw')
AddEventHandler('bassebank:withdraw', function(amount, isATM)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then return end

    if amount <= 0 then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Montant invalide')
        return
    end

    if isATM and amount > Config.ATMWithdrawLimit then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Limite de retrait ATM dépassée ($' .. Config.ATMWithdrawLimit .. ')')
        return
    end

    local playerBank = GetPlayerBank(xPlayer)

    if amount > playerBank then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Fonds insuffisants')
        return
    end

    local fee = math.floor(amount * Config.WithdrawFee)
    local finalAmount = amount - fee

    RemovePlayerBank(xPlayer, amount)
    AddPlayerMoney(xPlayer, finalAmount)

    LogTransaction(xPlayer.identifier, 'retrait', amount, nil, nil, isATM and 'Retrait ATM' or 'Retrait en banque')

    TriggerClientEvent('bassebank:notify', _source, 'success', 'Vous avez retiré $' .. finalAmount)
    TriggerClientEvent('bassebank:updateBalance', _source)
end)

-- Virement entre joueurs
RegisterNetEvent('bassebank:transfer')
AddEventHandler('bassebank:transfer', function(target, amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local xTarget = ESX.GetPlayerFromId(target)

    if not xPlayer then return end

    if not xTarget then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Joueur introuvable')
        return
    end

    if amount <= 0 or amount < Config.MinTransactionAmount then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Montant invalide')
        return
    end

    if amount > Config.MaxTransactionAmount then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Montant trop élevé (max: $' .. Config.MaxTransactionAmount .. ')')
        return
    end

    local fee = math.floor(amount * Config.TransferFee)
    local totalAmount = amount + fee
    local playerBank = GetPlayerBank(xPlayer)

    if totalAmount > playerBank then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Fonds insuffisants (montant + frais: $' .. totalAmount .. ')')
        return
    end

    RemovePlayerBank(xPlayer, totalAmount)
    AddPlayerBank(xTarget, amount)

    LogTransaction(xPlayer.identifier, 'virement', amount, xPlayer.identifier, xTarget.identifier, 'Virement à ' .. xTarget.getName())
    LogTransaction(xTarget.identifier, 'virement_recu', amount, xPlayer.identifier, xTarget.identifier, 'Virement de ' .. xPlayer.getName())

    TriggerClientEvent('bassebank:notify', _source, 'success', 'Virement de $' .. amount .. ' effectué (frais: $' .. fee .. ')')
    TriggerClientEvent('bassebank:notify', target, 'success', 'Vous avez reçu $' .. amount .. ' de ' .. xPlayer.getName())
    TriggerClientEvent('bassebank:updateBalance', _source)
    TriggerClientEvent('bassebank:updateBalance', target)
end)

-- Dépôt sur compte d'épargne
RegisterNetEvent('bassebank:savingsDeposit')
AddEventHandler('bassebank:savingsDeposit', function(amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then return end

    if amount < Config.MinSavingsDeposit then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Montant minimum: $' .. Config.MinSavingsDeposit)
        return
    end

    local playerBank = GetPlayerBank(xPlayer)

    if amount > playerBank then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Fonds insuffisants')
        return
    end

    RemovePlayerBank(xPlayer, amount)

    MySQL.query('SELECT * FROM bassebank_savings WHERE identifier = ?', {
        xPlayer.identifier
    }, function(result)
        if result[1] then
            MySQL.update('UPDATE bassebank_savings SET amount = amount + ? WHERE identifier = ?', {
                amount, xPlayer.identifier
            })
        else
            MySQL.insert('INSERT INTO bassebank_savings (identifier, amount) VALUES (?, ?)', {
                xPlayer.identifier, amount
            })
        end

        LogTransaction(xPlayer.identifier, 'epargne_depot', amount, nil, nil, 'Dépôt sur compte d\'épargne')
        TriggerClientEvent('bassebank:notify', _source, 'success', 'Dépôt de $' .. amount .. ' sur votre compte d\'épargne')
        TriggerClientEvent('bassebank:updateBalance', _source)
    end)
end)

-- Retrait du compte d'épargne
RegisterNetEvent('bassebank:savingsWithdraw')
AddEventHandler('bassebank:savingsWithdraw', function(amount)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer then return end

    MySQL.query('SELECT * FROM bassebank_savings WHERE identifier = ?', {
        xPlayer.identifier
    }, function(result)
        if not result[1] or result[1].amount < amount then
            TriggerClientEvent('bassebank:notify', _source, 'error', 'Fonds insuffisants sur le compte d\'épargne')
            return
        end

        MySQL.update('UPDATE bassebank_savings SET amount = amount - ? WHERE identifier = ?', {
            amount, xPlayer.identifier
        })

        AddPlayerBank(xPlayer, amount)

        LogTransaction(xPlayer.identifier, 'epargne_retrait', amount, nil, nil, 'Retrait du compte d\'épargne')
        TriggerClientEvent('bassebank:notify', _source, 'success', 'Retrait de $' .. amount .. ' de votre compte d\'épargne')
        TriggerClientEvent('bassebank:updateBalance', _source)
    end)
end)

-- Système d'intérêts sur compte d'épargne
CreateThread(function()
    while true do
        Wait(Config.SavingsInterestInterval)

        MySQL.query('SELECT * FROM bassebank_savings WHERE amount > 0', {}, function(results)
            for _, account in ipairs(results) do
                local interest = math.floor(account.amount * Config.SavingsInterestRate)

                if interest > 0 then
                    MySQL.update('UPDATE bassebank_savings SET amount = amount + ?, last_interest = NOW() WHERE identifier = ?', {
                        interest, account.identifier
                    })

                    LogTransaction(account.identifier, 'interets', interest, nil, nil, 'Intérêts sur compte d\'épargne')

                    local xPlayer = ESX.GetPlayerFromIdentifier(account.identifier)
                    if xPlayer then
                        TriggerClientEvent('bassebank:notify', xPlayer.source, 'info', 'Vous avez reçu $' .. interest .. ' d\'intérêts')
                    end
                end
            end
        end)
    end
end)

-- Commande pour obtenir les joueurs en ligne (pour les virements)
ESX.RegisterServerCallback('bassebank:getPlayers', function(source, cb)
    local players = {}
    local xPlayers = ESX.GetExtendedPlayers()

    for _, xPlayer in pairs(xPlayers) do
        if xPlayer.source ~= source then
            table.insert(players, {
                id = xPlayer.source,
                name = xPlayer.getName(),
                identifier = xPlayer.identifier
            })
        end
    end

    cb(players)
end)

-- Debug
if Config.Debug then
    print('^2[BasseBank] ^7Script démarré avec succès')
end
