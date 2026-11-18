DELIMITER $$

DROP TRIGGER IF EXISTS trg_wallet_transaction_no_update$$
CREATE TRIGGER trg_wallet_transaction_no_update
BEFORE UPDATE ON wallet_transaction
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'wallet transaction ledger is immutable';
END$$

DROP TRIGGER IF EXISTS trg_wallet_transaction_no_delete$$
CREATE TRIGGER trg_wallet_transaction_no_delete
BEFORE DELETE ON wallet_transaction
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'wallet transaction ledger is immutable';
END$$

DELIMITER ;
