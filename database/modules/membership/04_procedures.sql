DELIMITER $$

DROP PROCEDURE IF EXISTS sp_issue_promotion_coupons$$
CREATE PROCEDURE sp_issue_promotion_coupons(
    IN p_promotion_id BIGINT UNSIGNED,
    IN p_user_id BIGINT UNSIGNED,
    IN p_quantity INT UNSIGNED,
    IN p_now DATETIME(3)
)
BEGIN
    DECLARE v_missing TINYINT DEFAULT 0;
    DECLARE v_promotion_status VARCHAR(32);
    DECLARE v_valid_from DATETIME(3);
    DECLARE v_valid_until DATETIME(3);
    DECLARE v_face_amount DECIMAL(14,2);
    DECLARE v_minimum_spend DECIMAL(14,2);
    DECLARE v_issue_limit INT UNSIGNED;
    DECLARE v_issued_count INT UNSIGNED;
    DECLARE v_per_user_limit INT UNSIGNED;
    DECLARE v_user_status VARCHAR(32);
    DECLARE v_user_coupon_count INT UNSIGNED;
    DECLARE v_index INT UNSIGNED DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_missing = 1;

    IF p_quantity IS NULL OR p_quantity < 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'quantity must be positive';
    END IF;

    SELECT status, valid_from, valid_until, face_amount, minimum_spend,
           issue_limit, issued_count, per_user_limit
      INTO v_promotion_status, v_valid_from, v_valid_until, v_face_amount,
           v_minimum_spend, v_issue_limit, v_issued_count, v_per_user_limit
      FROM promotion
     WHERE promotion_id = p_promotion_id
     FOR UPDATE;

    IF v_missing = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'promotion not found';
    END IF;
    IF v_promotion_status <> 'active' OR p_now < v_valid_from OR p_now >= v_valid_until THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'promotion is not claimable';
    END IF;
    IF v_issued_count + p_quantity > v_issue_limit THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'promotion issue limit exceeded';
    END IF;

    SET v_missing = 0;
    SELECT status INTO v_user_status
      FROM app_user
     WHERE user_id = p_user_id
     FOR UPDATE;
    IF v_missing = 1 OR v_user_status <> 'active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'active user not found';
    END IF;

    SELECT COUNT(*) INTO v_user_coupon_count
      FROM user_coupon
     WHERE promotion_id = p_promotion_id AND user_id = p_user_id;
    IF v_user_coupon_count + p_quantity > v_per_user_limit THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'per-user coupon limit exceeded';
    END IF;

    UPDATE promotion
       SET issued_count = issued_count + p_quantity
     WHERE promotion_id = p_promotion_id;

    WHILE v_index < p_quantity DO
        INSERT INTO user_coupon (
            promotion_id, user_id, received_at, expires_at,
            face_amount_snapshot, minimum_spend_snapshot, status
        ) VALUES (
            p_promotion_id, p_user_id, p_now, v_valid_until,
            v_face_amount, v_minimum_spend, 'available'
        );
        SET v_index = v_index + 1;
    END WHILE;
END$$

DELIMITER ;
