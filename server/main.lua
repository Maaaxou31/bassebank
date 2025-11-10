ESX = exports["es_extended"]:getSharedObject()

-- Fonction pour enregistrer une transaction
local function LogTransaction(identifier, type, amount, fromIdentifier, toIdentifier, description)
    MySQL.insert('INSERT INTO bank_transactions (identifier, type, amount, from_identifier, to_identifier, description) VALUES (?, ?, ?, ?, ?, ?)', {
        identifier, type, amount, fromIdentifier, toIdentifier, description
    })
end

-- Fonction pour obtenir l'historique des transactions
ESX.RegisterServerCallback('bassebank:getTransactions', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.query('SELECT * FROM bank_transactions WHERE identifier = ? OR from_identifier = ? OR to_identifier = ? ORDER BY date DESC LIMIT 50', {
        xPlayer.identifier, xPlayer.identifier, xPlayer.identifier
    }, function(result)
        cb(result)
    end)
end)

-- Fonction pour obtenir le solde du compte d'épargne
ESX.RegisterServerCallback('bassebank:getSavings', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.query('SELECT * FROM bank_savings WHERE identifier = ?', {
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

    if amount <= 0 then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Montant invalide')
        return
    end

    if amount > xPlayer.getMoney() then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Vous n\'avez pas assez d\'argent liquide')
        return
    end

    local fee = math.floor(amount * Config.DepositFee)
    local finalAmount = amount - fee

    xPlayer.removeMoney(amount)
    xPlayer.addAccountMoney('bank', finalAmount)

    LogTransaction(xPlayer.identifier, 'depot', finalAmount, nil, nil, 'Dépôt en banque')

    TriggerClientEvent('bassebank:notify', _source, 'success', 'Vous avez déposé $' .. finalAmount)
    TriggerClientEvent('bassebank:updateBalance', _source)
end)

-- Retrait d'argent
RegisterNetEvent('bassebank:withdraw')
AddEventHandler('bassebank:withdraw', function(amount, isATM)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if amount <= 0 then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Montant invalide')
        return
    end

    if isATM and amount > Config.ATMWithdrawLimit then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Limite de retrait ATM dépassée ($' .. Config.ATMWithdrawLimit .. ')')
        return
    end

    if amount > xPlayer.getAccount('bank').money then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Fonds insuffisants')
        return
    end

    local fee = math.floor(amount * Config.WithdrawFee)
    local finalAmount = amount - fee

    xPlayer.removeAccountMoney('bank', amount)
    xPlayer.addMoney(finalAmount)

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

    if totalAmount > xPlayer.getAccount('bank').money then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Fonds insuffisants (montant + frais: $' .. totalAmount .. ')')
        return
    end

    xPlayer.removeAccountMoney('bank', totalAmount)
    xTarget.addAccountMoney('bank', amount)

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

    if amount < Config.MinSavingsDeposit then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Montant minimum: $' .. Config.MinSavingsDeposit)
        return
    end

    if amount > xPlayer.getAccount('bank').money then
        TriggerClientEvent('bassebank:notify', _source, 'error', 'Fonds insuffisants')
        return
    end

    xPlayer.removeAccountMoney('bank', amount)

    MySQL.query('SELECT * FROM bank_savings WHERE identifier = ?', {
        xPlayer.identifier
    }, function(result)
        if result[1] then
            MySQL.update('UPDATE bank_savings SET amount = amount + ? WHERE identifier = ?', {
                amount, xPlayer.identifier
            })
        else
            MySQL.insert('INSERT INTO bank_savings (identifier, amount) VALUES (?, ?)', {
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

    MySQL.query('SELECT * FROM bank_savings WHERE identifier = ?', {
        xPlayer.identifier
    }, function(result)
        if not result[1] or result[1].amount < amount then
            TriggerClientEvent('bassebank:notify', _source, 'error', 'Fonds insuffisants sur le compte d\'épargne')
            return
        end

        MySQL.update('UPDATE bank_savings SET amount = amount - ? WHERE identifier = ?', {
            amount, xPlayer.identifier
        })

        xPlayer.addAccountMoney('bank', amount)

        LogTransaction(xPlayer.identifier, 'epargne_retrait', amount, nil, nil, 'Retrait du compte d\'épargne')
        TriggerClientEvent('bassebank:notify', _source, 'success', 'Retrait de $' .. amount .. ' de votre compte d\'épargne')
        TriggerClientEvent('bassebank:updateBalance', _source)
    end)
end)

-- Système d'intérêts sur compte d'épargne
CreateThread(function()
    while true do
        Wait(Config.SavingsInterestInterval)

        MySQL.query('SELECT * FROM bank_savings WHERE amount > 0', {}, function(results)
            for _, account in ipairs(results) do
                local interest = math.floor(account.amount * Config.SavingsInterestRate)

                if interest > 0 then
                    MySQL.update('UPDATE bank_savings SET amount = amount + ?, last_interest = NOW() WHERE identifier = ?', {
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
