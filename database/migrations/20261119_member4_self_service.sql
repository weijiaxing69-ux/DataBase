-- Member 4 self-service extensions: wallet balance refunds and service appeals.
-- Run after the V1.4 base schema, seed data, and membership permission registry.

CREATE TABLE IF NOT EXISTS wallet_balance_refund_request (
  refund_request_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  reason VARCHAR(500) NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'pending_review',
  request_key VARCHAR(80) NOT NULL,
  reviewed_by_account_id BIGINT UNSIGNED NULL,
  review_note VARCHAR(500) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  reviewed_at DATETIME(3) NULL,
  completed_at DATETIME(3) NULL,
  PRIMARY KEY (refund_request_id),
  UNIQUE KEY uq_wallet_balance_refund_user_key (user_id, request_key),
  KEY ix_wallet_balance_refund_user_status (user_id, status, created_at),
  KEY ix_wallet_balance_refund_status_created (status, created_at),
  CONSTRAINT ck_wallet_balance_refund_amount CHECK (amount > 0),
  CONSTRAINT ck_wallet_balance_refund_status CHECK (status IN ('pending_review', 'processing', 'completed', 'rejected')),
  CONSTRAINT fk_wallet_balance_refund_user FOREIGN KEY (user_id) REFERENCES app_user (user_id),
  CONSTRAINT fk_wallet_balance_refund_reviewer FOREIGN KEY (reviewed_by_account_id) REFERENCES sys_account (account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS membership_service_appeal (
  appeal_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  order_id BIGINT UNSIGNED NULL,
  category VARCHAR(24) NOT NULL,
  subject VARCHAR(120) NOT NULL,
  description VARCHAR(2000) NOT NULL,
  status VARCHAR(24) NOT NULL DEFAULT 'submitted',
  request_key VARCHAR(80) NOT NULL,
  assigned_account_id BIGINT UNSIGNED NULL,
  last_response VARCHAR(1000) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  last_response_at DATETIME(3) NULL,
  PRIMARY KEY (appeal_id),
  UNIQUE KEY uq_membership_appeal_user_key (user_id, request_key),
  KEY ix_membership_appeal_user_created (user_id, created_at),
  KEY ix_membership_appeal_status_created (status, created_at),
  KEY ix_membership_appeal_order (order_id),
  CONSTRAINT ck_membership_appeal_category CHECK (category IN ('billing_dispute', 'charging_service', 'account_coupon', 'other')),
  CONSTRAINT ck_membership_appeal_status CHECK (status IN ('submitted', 'processing', 'resolved', 'rejected')),
  CONSTRAINT fk_membership_appeal_user FOREIGN KEY (user_id) REFERENCES app_user (user_id),
  CONSTRAINT fk_membership_appeal_order FOREIGN KEY (order_id) REFERENCES charging_order (order_id),
  CONSTRAINT fk_membership_appeal_assignee FOREIGN KEY (assigned_account_id) REFERENCES sys_account (account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS membership_service_appeal_event (
  appeal_event_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  appeal_id BIGINT UNSIGNED NOT NULL,
  actor_account_id BIGINT UNSIGNED NOT NULL,
  from_status VARCHAR(24) NULL,
  to_status VARCHAR(24) NOT NULL,
  message VARCHAR(1000) NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (appeal_event_id),
  KEY ix_membership_appeal_event_appeal (appeal_id, appeal_event_id),
  CONSTRAINT ck_membership_appeal_event_status CHECK (
    (from_status IS NULL OR from_status IN ('submitted', 'processing', 'resolved', 'rejected'))
    AND to_status IN ('submitted', 'processing', 'resolved', 'rejected')
  ),
  CONSTRAINT fk_membership_appeal_event_appeal FOREIGN KEY (appeal_id) REFERENCES membership_service_appeal (appeal_id),
  CONSTRAINT fk_membership_appeal_event_actor FOREIGN KEY (actor_account_id) REFERENCES sys_account (account_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
