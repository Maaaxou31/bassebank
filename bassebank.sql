-- BasseBank - Tables SQL

-- Table pour les transactions bancaires
CREATE TABLE IF NOT EXISTS `bank_transactions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `type` VARCHAR(50) NOT NULL,
    `amount` INT(11) NOT NULL,
    `from_identifier` VARCHAR(60) NULL,
    `to_identifier` VARCHAR(60) NULL,
    `description` TEXT NULL,
    `date` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `identifier` (`identifier`),
    KEY `from_identifier` (`from_identifier`),
    KEY `to_identifier` (`to_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table pour les comptes d'épargne
CREATE TABLE IF NOT EXISTS `bank_savings` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `amount` INT(11) NOT NULL DEFAULT 0,
    `last_interest` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table pour les cartes bancaires (optionnel, pour évolution future)
CREATE TABLE IF NOT EXISTS `bank_cards` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(60) NOT NULL,
    `card_number` VARCHAR(16) NOT NULL,
    `pin` VARCHAR(4) NOT NULL,
    `status` ENUM('active', 'blocked', 'expired') DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `card_number` (`card_number`),
    KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
