DROP TRIGGER IF EXISTS trg_settlement_invoice_guard;
DROP TRIGGER IF EXISTS trg_settlement_invoice_status;
DELIMITER $$
CREATE TRIGGER trg_settlement_invoice_guard
BEFORE INSERT ON operator_invoice
FOR EACH ROW
BEGIN
    DECLARE v_version INT UNSIGNED DEFAULT NULL;
    DECLARE v_status VARCHAR(32);
    DECLARE v_confirmed INT;

    -- Serialize invoice writes for this settlement. Locking reads see newly committed rows.
    SELECT version, status INTO v_version, v_status
    FROM operator_settlement WHERE settlement_id = NEW.settlement_id FOR UPDATE;
    IF v_version IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SETTLEMENT_NOT_FOUND';
    END IF;

    IF NEW.invoice_type = 'blue' THEN
        SELECT COUNT(*) INTO v_confirmed
        FROM reconciliation_confirmation
        WHERE settlement_id = NEW.settlement_id AND object_version = v_version
          AND is_current = 1 AND decision = 'confirmed'
          AND side IN ('platform', 'operator')
        FOR UPDATE;
        IF v_status NOT IN ('confirmed', 'invoiced') OR v_confirmed <> 2 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SETTLEMENT_CONFIRMATION_REQUIRED';
        END IF;

    END IF;
END$$

CREATE TRIGGER trg_settlement_invoice_status
AFTER INSERT ON operator_invoice
FOR EACH ROW
BEGIN
    IF NEW.invoice_type = 'blue' THEN
        UPDATE operator_settlement SET status = 'invoiced'
        WHERE settlement_id = NEW.settlement_id AND status = 'confirmed';
    END IF;
END$$
DELIMITER ;
