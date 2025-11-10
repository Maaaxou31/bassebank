# 🧪 GUIDE DE TEST - BasseBank

## 🚀 Installation rapide

### 1. SQL
Dans phpMyAdmin, exécutez `clean_install.sql` ou `bassebank.sql`

### 2. Redémarrage
```
restart bassebank
```

### 3. Vérification
Cherchez dans la console :
```
[BasseBank] ==============================================
[BasseBank] Démarrage du système bancaire...
[BasseBank] ==============================================
[BasseBank] Système de gestion d'argent initialisé
[BasseBank] ==============================================
[BasseBank] Script démarré avec succès
```

## 🧪 Tests à faire

### Test 1: Vérifier les soldes
```
/bankdebug
```

**Ce que vous devriez voir dans la console:**
```
[BasseBank DEBUG] ======================
[BasseBank DEBUG] Source: 1
[BasseBank DEBUG] Identifier: char1:xxx...
[BasseBank DEBUG] Nom: Votre Nom
[BasseBank DEBUG] Cash: XXXXX$
[BasseBank DEBUG] Bank: XXXXX$
[BasseBank DEBUG] ======================
```

**Et dans le chat:**
```
[BasseBank] Cash: $XXX | Bank: $XXX
```

✅ **Si ça affiche vos soldes = PARFAIT**
❌ **Si ça affiche 0$ = PROBLÈME avec ESX/jaksam_inventory**

---

### Test 2: Ouvrir la banque
```
/bank
```

**Ce que vous devriez voir dans la console:**
```
[BasseBank] ==================== GET BALANCES ====================
[BasseBank] Joueur: Votre Nom (ID: 1)
[BasseBank] Identifier: char1:xxx...
[BasseBank] GetPlayerMoney via getMoney(): XXXX$
[BasseBank] GetPlayerBank via getAccount(): XXXX$
[BasseBank] ==========================================
[BasseBank] RÉSULTAT FINAL => Cash: XXXX$ | Bank: XXXX$
[BasseBank] ==========================================
```

✅ **Si l'interface s'ouvre avec vos soldes = PARFAIT**
❌ **Si les soldes sont à 0$ = Regardez quelle méthode échoue dans les logs**

---

### Test 3: Déposer de l'argent
1. Ouvrez la banque (`/bank`)
2. Entrez un montant (ex: 1000)
3. Cliquez sur "Déposer"

**Ce que vous devriez voir dans la console:**
```
[BasseBank] ========== DÉPÔT ==========
[BasseBank] Joueur 1 veut déposer 1000$
[BasseBank] Le joueur a XXXX$ en cash
[BasseBank] Retrait de 1000$ cash...
[BasseBank] RemovePlayerMoney: -1000$ retiré
[BasseBank] Ajout de 1000$ à la banque...
[BasseBank] AddPlayerBank: +1000$ ajouté
[BasseBank] ✓ DÉPÔT RÉUSSI: 1000$ déposé
[BasseBank] ===========================
```

✅ **Si vous voyez "DÉPÔT RÉUSSI" = PARFAIT**
❌ **Si vous voyez "ERREUR" = Regardez quelle ligne échoue**

---

### Test 4: Retirer de l'argent
1. Ouvrez la banque (`/bank`)
2. Entrez un montant (ex: 500)
3. Cliquez sur "Retirer"

**Ce que vous devriez voir dans la console:**
```
[BasseBank] ========== RETRAIT ==========
[BasseBank] Joueur 1 veut retirer 500$
[BasseBank] Le joueur a XXXX$ en banque
[BasseBank] Retrait de 500$ de la banque...
[BasseBank] RemovePlayerBank: -500$ retiré
[BasseBank] Ajout de 500$ en cash...
[BasseBank] AddPlayerMoney: +500$ ajouté
[BasseBank] ✓ RETRAIT RÉUSSI: 500$ retiré
[BasseBank] ===========================
```

✅ **Si vous voyez "RETRAIT RÉUSSI" = PARFAIT**
❌ **Si vous voyez "ERREUR" = Regardez quelle ligne échoue**

---

### Test 5: Fermer sans être bloqué
1. Ouvrez la banque (`/bank`)
2. Appuyez sur **ESC** ou cliquez sur le **X**
3. Essayez de bouger votre personnage

✅ **Si vous pouvez bouger = PARFAIT**
❌ **Si vous êtes bloqué = Appuyez sur F8 et tapez `restart bassebank`**

---

## 🐛 En cas de problème

### Problème: Les soldes sont à 0$
**Envoyez-moi les logs complets de:**
```
/bankdebug
```

**Je dois voir:**
- Si `getMoney()` fonctionne
- Si `getAccount()` fonctionne
- Si `accounts` existe

### Problème: "Montant invalide"
**Vérifiez:**
1. Que vous avez tapé un chiffre (pas de texte)
2. Que le montant est > 0
3. Les logs dans la console pour voir où ça bloque

### Problème: "Pas assez d'argent" alors que j'en ai
**Cela signifie que GetPlayerMoney/Bank retourne 0$**

**Envoyez-moi les logs de:**
```
[BasseBank] GetPlayerMoney via getMoney(): ...
[BasseBank] GetPlayerBank via getAccount(): ...
```

### Problème: Erreur "ÉCHEC"
**Cela signifie que les fonctions ESX ne fonctionnent pas.**

**Possibilités:**
1. jaksam_inventory bloque les fonctions ESX standard
2. ESX n'est pas bien configuré
3. Le joueur n'existe pas dans la base de données

---

## 📧 Ce que j'ai besoin pour vous aider

Si ça ne fonctionne toujours pas, envoyez-moi:

1. **Les logs complets** de `/bankdebug`
2. **Les logs complets** d'une tentative de dépôt
3. **La version d'ESX** que vous utilisez
4. **La version de jaksam_inventory**

Avec ces infos, je pourrai vous aider à 100% !

---

## ✅ Ce qui DOIT fonctionner maintenant

- ✅ Ouverture/fermeture sans blocage
- ✅ Affichage des soldes
- ✅ Dépôts (si ESX fonctionne)
- ✅ Retraits (si ESX fonctionne)
- ✅ Logs ultra-détaillés
- ✅ Messages d'erreur précis
- ✅ Protection contre les bugs (remboursement automatique)

**Le script est maintenant ULTRA-SIMPLE et ULTRA-ROBUSTE.**

**Si ça ne fonctionne pas, c'est un problème d'intégration ESX/jaksam_inventory, PAS du script BasseBank.**

Les logs vous diront EXACTEMENT où est le problème ! 🔍
