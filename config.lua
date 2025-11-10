Config = {}

-- Langue
Config.Locale = 'fr'

-- Paramètres généraux
Config.MaxTransactionAmount = 1000000 -- Montant maximum par transaction
Config.MinTransactionAmount = 1 -- Montant minimum par transaction

-- Frais bancaires
Config.TransferFee = 0.02 -- 2% de frais sur les virements
Config.WithdrawFee = 0 -- Pas de frais sur les retraits
Config.DepositFee = 0 -- Pas de frais sur les dépôts

-- Compte d'épargne
Config.SavingsInterestRate = 0.05 -- 5% d'intérêt par cycle
Config.SavingsInterestInterval = 3600000 -- Intérêt calculé toutes les heures (en ms)
Config.MinSavingsDeposit = 1000 -- Dépôt minimum pour le compte d'épargne

-- ATM
Config.ATMModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}

Config.ATMWithdrawLimit = 50000 -- Limite de retrait aux ATM

-- Banques (pour les opérations complètes)
Config.Banks = {
    {
        name = "Banque Fleeca",
        coords = vector3(149.9, -1040.5, 29.4),
        blip = true
    },
    {
        name = "Banque Fleeca",
        coords = vector3(314.2, -278.9, 54.2),
        blip = true
    },
    {
        name = "Banque Fleeca",
        coords = vector3(-350.8, -49.5, 49.0),
        blip = true
    },
    {
        name = "Banque Fleeca",
        coords = vector3(-1212.9, -330.8, 37.8),
        blip = true
    },
    {
        name = "Banque Fleeca",
        coords = vector3(-2962.5, 482.6, 15.7),
        blip = true
    },
    {
        name = "Banque Fleeca",
        coords = vector3(1175.0, 2706.6, 38.1),
        blip = true
    },
    {
        name = "Banque Principale",
        coords = vector3(241.7, 227.4, 106.3),
        blip = true
    }
}

-- Blips
Config.BlipSprite = 108
Config.BlipColor = 2
Config.BlipScale = 0.8

-- Notifications
Config.NotificationDuration = 5000

-- Debug mode
Config.Debug = true
