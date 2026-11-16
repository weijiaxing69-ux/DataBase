DROP PROCEDURE IF EXISTS sp_settlement_issue_operator_invoice;
DELIMITER $$
CREATE PROCEDURE sp_settlement_issue_operator_invoice(
    IN p_settlement_id BIGINT UNSIGNED,
    IN p_invoice_no VARCHAR(64),
    IN p_original_invoice_id BIGINT UNSIGNED,
    IN p_title VARCHAR(100),
    IN p_tax_no VARCHAR(30),
    IN p_amount DECIMAL(14,2),
    IN p_actor_id BIGINT UNSIGNED
)
SQL SECURITY INVOKER
MODIFIES SQL DATA
BEGIN
    DECLARE v_settlement_id BIGINT UNSIGNED DEFAULT NULL;
    DECLARE v_payable DECIMAL(14,2);
    DECLARE v_net DECIMAL(24,2);
    DECLARE v_original_amount DECIMAL(14,2) DEFAULT NULL;
    DECLARE v_red_total DECIMAL(24,2);

    -- Call inside an explicit transaction. Acquire the parent lock before reading invoice totals.
    SELECT settlement_id, payable_amount INTO v_settlement_id, v_payable
    FROM operator_settlement WHERE settlement_id = p_settlement_id FOR UPDATE;
    IF v_settlement_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SETTLEMENT_NOT_FOUND';
    END IF;
    IF p_amount IS NULL OR p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_INVOICE_AMOUNT';
    END IF;

    IF p_original_invoice_id IS NULL THEN
        SELECT COALESCE(SUM(CASE WHEN invoice_type = 'blue' THEN amount ELSE -amount END), 0)
          INTO v_net
        FROM operator_invoice WHERE settlement_id = p_settlement_id FOR UPDATE;
        IF v_net + p_amount > v_payable THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVOICE_EXCEEDS_SETTLEMENT';
        END IF;
    ELSE
        SELECT amount INTO v_original_amount
        FROM operator_invoice
        WHERE invoice_id = p_original_invoice_id AND settlement_id = p_settlement_id
          AND invoice_type = 'blue' AND status = 'issued'
        FOR UPDATE;
        IF v_original_amount IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RED_INVOICE_INVALID_ORIGINAL';
        END IF;

        SELECT COALESCE(SUM(amount), 0) INTO v_red_total
        FROM operator_invoice
        WHERE original_invoice_id = p_original_invoice_id AND invoice_type = 'red'
        FOR UPDATE;
        IF v_red_total + p_amount > v_original_amount THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RED_INVOICE_EXCEEDS_ORIGINAL';
        END IF;
    END IF;

    INSERT INTO operator_invoice
        (settlement_id, invoice_no, original_invoice_id, invoice_type, title,
         tax_no, amount, status, issued_at, issued_by)
    VALUES
        (p_settlement_id, p_invoice_no, p_original_invoice_id,
         IF(p_original_invoice_id IS NULL, 'blue', 'red'), p_title, p_tax_no, p_amount,
         IF(p_original_invoice_id IS NULL, 'issued', 'red_issued'), UTC_TIMESTAMP(3), p_actor_id);

    SELECT invoice_id, settlement_id, original_invoice_id, invoice_no, invoice_type,
           title, tax_no, amount, status, issued_at, issued_by
    FROM operator_invoice
    WHERE invoice_id = LAST_INSERT_ID();
END$$
DELIMITER ;
