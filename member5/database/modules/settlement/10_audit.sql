-- Additive migration. Existing V1.4 business tables and financial records stay intact.
CREATE TABLE IF NOT EXISTS settlement_audit_event (
    event_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    object_type VARCHAR(32) NOT NULL,
    object_id BIGINT UNSIGNED NOT NULL,
    action VARCHAR(64) NOT NULL,
    actor_id BIGINT UNSIGNED NOT NULL,
    object_version INT UNSIGNED NULL,
    before_state JSON NULL,
    after_state JSON NULL,
    note VARCHAR(1000) NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    KEY ix_settlement_audit_object (object_type, object_id, event_id),
    CONSTRAINT fk_settlement_audit_actor FOREIGN KEY (actor_id)
      REFERENCES sys_account(account_id) ON DELETE RESTRICT ON UPDATE RESTRICT
);
