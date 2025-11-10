ESX = exports["es_extended"]:getSharedObject()

print('^2[BasseBank] ^7==============================================')
print('^2[BasseBank] ^7Démarrage du système bancaire...')
print('^2[BasseBank] ^7==============================================')

-- Fonctions ultra-simples qui utilisent directement ESX
local function GetPlayerMoney(xPlayer)
    if not xPlayer then return 0 end

    -- Essayer getMoney (standard)
    local success, money = pcall(function()
        return xPlayer.getMoney()
    end)

    if success and money then
        print('^2[BasseBank] ^7GetPlayerMoney via getMoney(): ' .. money .. '$')
        return money
    end

    -- Essayer via money direct
    if xPlayer.money then
        print('^2[BasseBank] ^7GetPlayerMoney via money: ' .. xPlayer.money .. '$')
        return xPlayer.money
    end

    print('^1[BasseBank] ^7GetPlayerMoney ÉCHEC - retour 0$')
    return 0
end

local function GetPlayerBank(xPlayer)
    if not xPlayer then return 0 end

    -- Essayer getAccount (standard)
    local success, account = pcall(function()
        return xPlayer.getAccount('bank')
    end)

    if success and account and account.money then
        print('^2[BasseBank] ^7GetPlayerBank via getAccount(): ' .. account.money .. '$')
        return account.money
    end

    -- Essayer directement dans accounts
    if xPlayer.accounts then
        for k, v in pairs(xPlayer.accounts) do
            if v.name == 'bank' then
                print('^2[BasseBank] ^7GetPlayerBank via accounts: ' .. v.money .. '$')
                return v.money
            end
        end
    end

    print('^1[BasseBank] ^7GetPlayerBank ÉCHEC - retour 0$')
    return 0
end

local function AddPlayerMoney(xPlayer, amount)
    if not xPlayer or amount <= 0 then return false end

    local success = pcall(function()
        xPlayer.addMoney(amount)
    end)

    if success then
        print('^2[BasseBank] ^7AddPlayerMoney: +' .. amount .. '$ ajouté')
        return true
    end

    print('^1[BasseBank] ^7AddPlayerMoney ÉCHEC')
    return false
end

local function RemovePlayerMoney(xPlayer, amount)
    if not xPlayer or amount <= 0 then return false end

    local success = pcall(function()
        xPlayer.removeMoney(amount)
    end)

    if success then
        print('^2[BasseBank] ^7RemovePlayerMoney: -' .. amount .. '$ retiré')
        return true
    end

    print('^1[BasseBank] ^7RemovePlayerMoney ÉCHEC')
    return false
end

local function AddPlayerBank(xPlayer, amount)
    if not xPlayer or amount <= 0 then return false end

    local success = pcall(function()
        xPlayer.addAccountMoney('bank', amount)
    end)

    if success then
        print('^2[BasseBank] ^7AddPlayerBank: +' .. amount .. '$ ajouté')
        return true
    end

    print('^1[BasseBank] ^7AddPlayerBank ÉCHEC')
    return false
end

local function RemovePlayerBank(xPlayer, amount)
    if not xPlayer or amount <= 0 then return false end

    local success = pcall(function()
        xPlayer.removeAccountMoney('bank', amount)
    end)

    if success then
        print('^2[BasseBank] ^7RemovePlayerBank: -' .. amount .. '$ retiré')
        return true
    end

    print('^1[BasseBank] ^7RemovePlayerBank ÉCHEC')
    return false
end

print('^2[BasseBank] ^7Système de gestion d\'argent initialisé')
print('^2[BasseBank] ^7==============================================')

-- Callback pour obtenir les soldes
ESX.RegisterServerCallback('bassebank:getBalances', function(source, cb)
    print('^6[BasseBank] ^7==================== GET BALANCES ====================')

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        print('^1[BasseBank] ^7ERREUR: xPlayer non trouvé pour source ' .. source)
        cb({cash = 0, bank = 0})
        return
    end

    print('^6[BasseBank] ^7Joueur: ' .. xPlayer.getName() .. ' (ID: ' .. source .. ')')
    print('^6[BasseBank] ^7Identifier: ' .. xPlayer.identifier)

    local cash = GetPlayerMoney(xPlayer)
    local bank = GetPlayerBank(xPlayer)

    print('^3[BasseBank] ^7==========================================')
    print('^3[BasseBank] ^7RÉSULTAT FINAL => Cash: ' .. cash .. '$ | Bank: ' .. bank .. '$')
    print('^3[BasseBank] ^7==========================================')

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

    print('^5[BasseBank] ^7========== DÉPÔT ==========')
    print('^5[BasseBank] ^7Joueur ' .. _source .. ' veut déposer ' .. amount .. '$')

    if not xPlayer then
        print('^1[BasseBank] ^7ERREUR: xPlayer non trouvé')
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Erreur système')
        return
    end

    if not amount or amount <= 0 then
        print('^1[BasseBank] ^7ERREUR: Montant invalide')
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Montant invalide')
        return
    end

    local playerMoney = GetPlayerMoney(xPlayer)
    print('^5[BasseBank] ^7Le joueur a ' .. playerMoney .. '$ en cash')

    if amount > playerMoney then
        print('^1[BasseBank] ^7ERREUR: Pas assez d\'argent')
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Vous n\'avez pas assez d\'argent liquide (' .. playerMoney .. '$)')
        return
    end

    local fee = math.floor(amount * Config.DepositFee)
    local finalAmount = amount - fee

    print('^5[BasseBank] ^7Retrait de ' .. amount .. '$ cash...')
    local removed = RemovePlayerMoney(xPlayer, amount)

    if not removed then
        print('^1[BasseBank] ^7ERREUR: Impossible de retirer l\'argent cash')
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Erreur lors du retrait de l\'argent')
        return
    end

    print('^5[BasseBank] ^7Ajout de ' .. finalAmount .. '$ à la banque...')
    local added = AddPlayerBank(xPlayer, finalAmount)

    if not added then
        print('^1[BasseBank] ^7ERREUR: Impossible d\'ajouter à la banque, remboursement...')
        AddPlayerMoney(xPlayer, amount) -- Rembourser
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Erreur lors du dépôt')
        return
    end

    LogTransaction(xPlayer.identifier, 'depot', finalAmount, nil, nil, 'Dépôt en banque')

    print('^2[BasseBank] ^7✓ DÉPÔT RÉUSSI: ' .. finalAmount .. '$ déposé')
    print('^5[BasseBank] ^7===========================')

    TriggerClientEvent('bassebank:notify', _source, 'success', 'Vous avez déposé $' .. finalAmount)

    -- Attendre un peu avant de mettre à jour pour être sûr que ESX a bien mis à jour
    Wait(100)
    TriggerClientEvent('bassebank:updateBalance', _source)
end)

-- Retrait d'argent
RegisterNetEvent('bassebank:withdraw')
AddEventHandler('bassebank:withdraw', function(amount, isATM)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    print('^5[BasseBank] ^7========== RETRAIT ==========')
    print('^5[BasseBank] ^7Joueur ' .. _source .. ' veut retirer ' .. amount .. '$')

    if not xPlayer then
        print('^1[BasseBank] ^7ERREUR: xPlayer non trouvé')
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Erreur système')
        return
    end

    if not amount or amount <= 0 then
        print('^1[BasseBank] ^7ERREUR: Montant invalide')
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Montant invalide')
        return
    end

    if isATM and amount > Config.ATMWithdrawLimit then
        print('^1[BasseBank] ^7ERREUR: Limite ATM dépassée')
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Limite de retrait ATM: $' .. Config.ATMWithdrawLimit)
        return
    end

    local playerBank = GetPlayerBank(xPlayer)
    print('^5[BasseBank] ^7Le joueur a ' .. playerBank .. '$ en banque')

    if amount > playerBank then
        print('^1[BasseBank] ^7ERREUR: Pas assez d\'argent en banque')
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Fonds insuffisants (' .. playerBank .. '$)')
        return
    end

    local fee = math.floor(amount * Config.WithdrawFee)
    local finalAmount = amount - fee

    print('^5[BasseBank] ^7Retrait de ' .. amount .. '$ de la banque...')
    local removed = RemovePlayerBank(xPlayer, amount)

    if not removed then
        print('^1[BasseBank] ^7ERREUR: Impossible de retirer de la banque')
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Erreur lors du retrait')
        return
    end

    print('^5[BasseBank] ^7Ajout de ' .. finalAmount .. '$ en cash...')
    local added = AddPlayerMoney(xPlayer, finalAmount)

    if not added then
        print('^1[BasseBank] ^7ERREUR: Impossible d\'ajouter le cash, remboursement...')
        AddPlayerBank(xPlayer, amount) -- Rembourser
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Erreur lors de l\'ajout de l\'argent')
        return
    end

    LogTransaction(xPlayer.identifier, 'retrait', amount, nil, nil, isATM and 'Retrait ATM' or 'Retrait en banque')

    print('^2[BasseBank] ^7✓ RETRAIT RÉUSSI: ' .. finalAmount .. '$ retiré')
    print('^5[BasseBank] ^7===========================')

    TriggerClientEvent('bassebank:notify', _source, 'success', 'Vous avez retiré $' .. finalAmount)

    Wait(100)
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

-- Commande de debug pour voir les soldes
RegisterCommand('bankdebug', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        print('^1[BasseBank] ^7Debug: xPlayer non trouvé')
        return
    end

    local cash = GetPlayerMoney(xPlayer)
    local bank = GetPlayerBank(xPlayer)

    print('^6[BasseBank DEBUG] ^7======================')
    print('^6[BasseBank DEBUG] ^7Source: ' .. source)
    print('^6[BasseBank DEBUG] ^7Identifier: ' .. xPlayer.identifier)
    print('^6[BasseBank DEBUG] ^7Nom: ' .. xPlayer.getName())
    print('^6[BasseBank DEBUG] ^7Cash: ' .. cash .. '$')
    print('^6[BasseBank DEBUG] ^7Bank: ' .. bank .. '$')
    print('^6[BasseBank DEBUG] ^7======================')

    TriggerClientEvent('chat:addMessage', source, {
        color = {255, 255, 0},
        multiline = true,
        args = {"[BasseBank]", "Cash: $" .. cash .. " | Bank: $" .. bank}
    })
end, false)

-- Debug
if Config.Debug then
    print('^2[BasseBank] ^7Script démarré avec succès')
end
