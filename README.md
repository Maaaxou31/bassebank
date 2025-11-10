# 🏦 BasseBank - Système Bancaire pour FiveM

Un système bancaire complet et moderne pour FiveM avec intégration ESX.

## 📋 Fonctionnalités

- ✅ Système de compte bancaire complet
- 💵 Dépôt et retrait d'argent
- 💳 Virements entre joueurs
- 📱 Compatible avec les scripts de téléphone
- 🎨 Interface UI moderne (NUI)
- 🔄 Intégration ESX complète
- 📜 Historique détaillé des transactions
- 📈 Comptes d'épargne avec intérêts (5% par heure)
- 🏧 Distributeurs automatiques (ATM)
- 💎 Design moderne et responsive

## 📦 Prérequis

- [es_extended](https://github.com/esx-framework/esx-legacy)
- [oxmysql](https://github.com/overextended/oxmysql)
- Un serveur FiveM configuré

## 🔧 Installation

### 1. Téléchargement
Téléchargez le script et placez-le dans votre dossier `resources`.

### 2. Base de données

**⚠️ IMPORTANT:** Si vous avez déjà un autre système bancaire installé, utilisez `clean_install.sql` pour éviter les conflits.

**Option A - Installation propre (recommandée) :**
Exécutez le fichier `clean_install.sql` dans votre base de données MySQL. Ce fichier supprime les anciennes tables BasseBank si elles existent et crée les nouvelles avec le préfixe `bassebank_` :
```sql
-- Dans phpMyAdmin ou MySQL, importez le fichier clean_install.sql
```

**Option B - Installation simple (si pas d'autres scripts bancaires) :**
Exécutez le fichier `bassebank.sql` :
```sql
-- Importez le fichier bassebank.sql
```

### 3. Configuration du serveur
Ajoutez dans votre `server.cfg` :
```
ensure bassebank
```

### 4. Configuration
Modifiez le fichier `config.lua` selon vos besoins :
- Frais bancaires
- Taux d'intérêt
- Positions des banques
- Limites de transaction
- etc.

## 🎮 Utilisation

### Pour les joueurs

#### Banques
- Rendez-vous dans l'une des banques marquées sur la carte
- Appuyez sur `E` pour ouvrir l'interface

#### ATM (Distributeurs)
- Approchez-vous d'un distributeur
- Appuyez sur `E` pour accéder aux fonctions de base
- Limite de retrait : $50,000

#### Commande
```
/bank - Ouvre l'interface bancaire
```

### Fonctionnalités disponibles

#### 💵 Opérations
- **Déposer** : Transférez votre argent liquide sur votre compte
- **Retirer** : Retirez de l'argent de votre compte

#### 💳 Virements
- Envoyez de l'argent à d'autres joueurs
- Frais de transaction : 2%
- Montant maximum : $1,000,000

#### 📈 Compte d'épargne
- Déposez de l'argent (minimum $1,000)
- Gagnez 5% d'intérêts toutes les heures
- Retirez quand vous voulez

#### 📜 Historique
- Consultez vos 50 dernières transactions
- Détails complets de chaque opération

## 🔨 Configuration avancée

### Modifier les frais
Dans `config.lua` :
```lua
Config.TransferFee = 0.02 -- 2% de frais sur les virements
Config.WithdrawFee = 0 -- Pas de frais sur les retraits
Config.DepositFee = 0 -- Pas de frais sur les dépôts
```

### Modifier les taux d'intérêt
```lua
Config.SavingsInterestRate = 0.05 -- 5% d'intérêt
Config.SavingsInterestInterval = 3600000 -- Toutes les heures (en ms)
```

### Ajouter des banques
```lua
Config.Banks = {
    {
        name = "Ma Banque",
        coords = vector3(x, y, z),
        blip = true
    }
}
```

### Modifier les modèles d'ATM
```lua
Config.ATMModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`
}
```

## 🔌 Intégration avec d'autres scripts

### Téléphone
Pour intégrer avec un script de téléphone, utilisez l'export :
```lua
-- Ouvrir la banque depuis un téléphone
exports['bassebank']:OpenBankUI(false)
```

### API disponibles

#### Client Side
```lua
-- Ouvrir l'interface bancaire
exports['bassebank']:OpenBankUI(isATM)
```

#### Server Side
```lua
-- Les événements sont disponibles pour être écoutés
-- bassebank:deposit
-- bassebank:withdraw
-- bassebank:transfer
-- bassebank:savingsDeposit
-- bassebank:savingsWithdraw
```

## 📊 Structure de la base de données

### Table `bank_transactions`
Stocke l'historique de toutes les transactions bancaires.

### Table `bank_savings`
Gère les comptes d'épargne des joueurs.

### Table `bank_cards`
(Optionnel) Pour évolution future avec système de cartes.

## 🎨 Personnalisation de l'interface

Les fichiers de l'interface se trouvent dans le dossier `html/` :
- `index.html` - Structure HTML
- `style.css` - Styles et design
- `script.js` - Logique JavaScript

Vous pouvez modifier ces fichiers pour personnaliser l'apparence de votre banque.

## 🐛 Dépannage

### La banque ne s'ouvre pas
- Vérifiez que ESX est bien démarré
- Vérifiez les logs du serveur pour les erreurs
- Assurez-vous que oxmysql est installé et configuré

### Les transactions ne fonctionnent pas
- Vérifiez que les tables SQL sont bien créées
- Vérifiez les permissions de la base de données
- Activez le mode debug dans `config.lua` : `Config.Debug = true`

### Les intérêts ne sont pas versés
- Vérifiez l'intervalle dans la configuration
- Vérifiez que le serveur reste en ligne pendant l'intervalle

## 🔄 Évolutions futures possibles

- Système de prêts bancaires
- Cartes bancaires avec code PIN
- Limite de découvert autorisé
- Comptes d'entreprise
- Investissements
- Coffres-forts
- Historique de connexion bancaire
- Notifications par email (téléphone)
- Multi-devises

## 📝 Support

Pour toute question ou problème, ouvrez une issue sur GitHub.

## 📄 Licence

Ce script est fourni "tel quel" pour une utilisation libre. N'hésitez pas à le modifier selon vos besoins.

## 🙏 Crédits

Développé par BasseBank pour la communauté FiveM.

---

**Bon jeu ! 🎮**
