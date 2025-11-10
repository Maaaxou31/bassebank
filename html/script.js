let isATM = false;
let currentCash = 0;
let currentBank = 0;
let currentSavings = 0;
let transactions = [];
let players = [];

// Écouter les messages de NUI
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'openBank':
            openBank(data);
            break;
        case 'updateBalance':
            updateBalance(data.cash, data.bank);
            break;
        case 'forceClose':
            document.getElementById('bank-container').style.display = 'none';
            break;
    }
});

// Ouvrir la banque
function openBank(data) {
    isATM = data.isATM;
    currentCash = data.cash;
    currentBank = data.bank;
    currentSavings = data.savings;
    transactions = data.transactions || [];
    players = data.players || [];

    // Mettre à jour l'affichage
    updateBalance(currentCash, currentBank);
    updateSavingsDisplay(currentSavings);
    loadTransactions();
    loadPlayers();

    // Afficher/masquer l'avertissement ATM
    if (isATM) {
        document.getElementById('atm-warning').style.display = 'block';
        // Cacher l'onglet virement pour les ATM
        document.querySelectorAll('.tab-btn')[1].style.display = 'none';
    } else {
        document.getElementById('atm-warning').style.display = 'none';
        document.querySelectorAll('.tab-btn')[1].style.display = 'block';
    }

    // Afficher le container
    document.getElementById('bank-container').style.display = 'flex';
}

// Mettre à jour l'affichage des soldes
function updateBalance(cash, bank) {
    currentCash = cash;
    currentBank = bank;

    document.getElementById('cash-amount').textContent = formatMoney(cash);
    document.getElementById('bank-amount').textContent = formatMoney(bank);
}

// Mettre à jour l'affichage de l'épargne
function updateSavingsDisplay(amount) {
    currentSavings = amount;
    document.getElementById('savings-amount').textContent = formatMoney(amount);
}

// Charger les transactions
function loadTransactions() {
    const container = document.getElementById('transactions-list');
    container.innerHTML = '';

    if (transactions.length === 0) {
        container.innerHTML = '<div class="no-transactions">Aucune transaction récente</div>';
        return;
    }

    transactions.forEach(transaction => {
        const item = document.createElement('div');
        item.className = 'transaction-item';

        const isPositive = transaction.type.includes('recu') ||
                          transaction.type === 'depot' ||
                          transaction.type === 'interets' ||
                          transaction.type === 'epargne_retrait';

        const typeLabel = getTransactionTypeLabel(transaction.type);
        const date = new Date(transaction.date);
        const formattedDate = date.toLocaleDateString('fr-FR') + ' ' + date.toLocaleTimeString('fr-FR');

        item.innerHTML = `
            <div class="transaction-info">
                <div class="transaction-type">${typeLabel}</div>
                <div class="transaction-desc">${transaction.description || 'Aucune description'}</div>
                <div class="transaction-date">${formattedDate}</div>
            </div>
            <div class="transaction-amount ${isPositive ? 'positive' : 'negative'}">
                ${isPositive ? '+' : '-'}$${formatMoney(Math.abs(transaction.amount))}
            </div>
        `;

        container.appendChild(item);
    });
}

// Obtenir le label du type de transaction
function getTransactionTypeLabel(type) {
    const labels = {
        'depot': '💵 Dépôt',
        'retrait': '💸 Retrait',
        'virement': '💳 Virement envoyé',
        'virement_recu': '💳 Virement reçu',
        'epargne_depot': '📈 Dépôt épargne',
        'epargne_retrait': '📉 Retrait épargne',
        'interets': '💰 Intérêts'
    };

    return labels[type] || '📋 Transaction';
}

// Charger la liste des joueurs
function loadPlayers() {
    const select = document.getElementById('transfer-player');
    select.innerHTML = '<option value="">Sélectionnez un joueur</option>';

    players.forEach(player => {
        const option = document.createElement('option');
        option.value = player.id;
        option.textContent = player.name;
        select.appendChild(option);
    });
}

// Formater l'argent
function formatMoney(amount) {
    return amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// Fermer la banque
function closeBank() {
    document.getElementById('bank-container').style.display = 'none';
    $.post('https://bassebank/closeBank', JSON.stringify({}));
}

// Gérer les onglets
function showTab(tabName) {
    // Masquer tous les onglets
    document.querySelectorAll('.tab-pane').forEach(pane => {
        pane.classList.remove('active');
    });

    // Désactiver tous les boutons
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
    });

    // Activer l'onglet sélectionné
    document.getElementById(tabName + '-tab').classList.add('active');
    event.target.classList.add('active');
}

// Déposer de l'argent
function deposit() {
    const amount = parseInt(document.getElementById('deposit-amount').value);

    if (!amount || amount <= 0) {
        return;
    }

    $.post('https://bassebank/deposit', JSON.stringify({
        amount: amount
    }));

    document.getElementById('deposit-amount').value = '';
}

// Retirer de l'argent
function withdraw() {
    const amount = parseInt(document.getElementById('withdraw-amount').value);

    if (!amount || amount <= 0) {
        return;
    }

    $.post('https://bassebank/withdraw', JSON.stringify({
        amount: amount,
        isATM: isATM
    }));

    document.getElementById('withdraw-amount').value = '';
}

// Effectuer un virement
function transfer() {
    const target = parseInt(document.getElementById('transfer-player').value);
    const amount = parseInt(document.getElementById('transfer-amount').value);

    if (!target || !amount || amount <= 0) {
        return;
    }

    $.post('https://bassebank/transfer', JSON.stringify({
        target: target,
        amount: amount
    }));

    document.getElementById('transfer-player').value = '';
    document.getElementById('transfer-amount').value = '';
}

// Déposer sur le compte d'épargne
function savingsDeposit() {
    const amount = parseInt(document.getElementById('savings-deposit-amount').value);

    if (!amount || amount <= 0) {
        return;
    }

    $.post('https://bassebank/savingsDeposit', JSON.stringify({
        amount: amount
    }));

    document.getElementById('savings-deposit-amount').value = '';
}

// Retirer du compte d'épargne
function savingsWithdraw() {
    const amount = parseInt(document.getElementById('savings-withdraw-amount').value);

    if (!amount || amount <= 0) {
        return;
    }

    $.post('https://bassebank/savingsWithdraw', JSON.stringify({
        amount: amount
    }));

    document.getElementById('savings-withdraw-amount').value = '';
}

// Fermer avec la touche ESC
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeBank();
    }
});

// Empêcher le clic droit
document.addEventListener('contextmenu', function(event) {
    event.preventDefault();
});
