-- Permission registry supplement. Run after the fixed six sys_role rows and base seed.
-- Codes are namespaced resource actions; role codes remain the six V1.4 values.
INSERT INTO sys_permission (permission_code, permission_name) VALUES
('auth.account.read', '查看账号'),
('auth.account.manage', '管理账号、角色及范围'),
('auth.role.read', '查看角色'),
('auth.permission.read', '查看权限'),
('membership.profile.read', '查看本人档案'),
('membership.profile.update', '修改本人档案'),
('membership.user.read', '查看车主档案'),
('membership.user.verify', '模拟实名审核'),
('membership.user.manage', '管理车主档案'),
('membership.vehicle.read', '查看车辆'),
('membership.vehicle.manage', '管理车辆绑定'),
('membership.promotion.read', '查看活动'),
('membership.promotion.manage', '创建和修改活动'),
('membership.promotion.review', '审核活动'),
('membership.coupon.read', '查看优惠券'),
('membership.coupon.claim', '领取优惠券'),
('membership.coupon.issue', '定向发放优惠券'),
('membership.coupon.manage', '管理优惠券'),
('membership.fleet.read', '查看车队'),
('membership.fleet.manage', '管理车队'),
('membership.fleet_card.read', '查看车队卡'),
('membership.fleet_card.manage', '管理车队卡'),
('membership.fleet_authorization.read', '查看车队授权'),
('membership.fleet_authorization.manage', '管理车队授权'),
('membership.fleet_quota.manage', '管理车队额度'),
('membership.wallet.read', '查看本人余额流水'),
('membership.wallet.topup', '开发环境模拟充值'),
('membership.feedback.read', '查看评价'),
('membership.feedback.create', '创建本人订单评价')
ON DUPLICATE KEY UPDATE permission_name = VALUES(permission_name);

-- Platform administrators receive the full current permission registry.
INSERT IGNORE INTO sys_role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM sys_role AS r CROSS JOIN sys_permission AS p
WHERE r.role_code = 'platform_admin';

-- Self-service owner actions are still restricted to the authenticated owner's resources.
INSERT IGNORE INTO sys_role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM sys_role AS r JOIN sys_permission AS p ON p.permission_code IN (
    'membership.profile.read', 'membership.profile.update',
    'membership.vehicle.read', 'membership.vehicle.manage',
    'membership.promotion.read', 'membership.coupon.read', 'membership.coupon.claim',
    'membership.wallet.read', 'membership.wallet.topup',
    'membership.feedback.read', 'membership.feedback.create'
)
WHERE r.role_code = 'vehicle_owner';

-- Customer service may verify users and review customer-facing records.
INSERT IGNORE INTO sys_role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM sys_role AS r JOIN sys_permission AS p ON p.permission_code IN (
    'membership.user.read', 'membership.user.verify', 'membership.vehicle.read',
    'membership.promotion.read', 'membership.coupon.read',
    'membership.feedback.read'
)
WHERE r.role_code = 'customer_service';

-- Fleet administrators can operate only resources in sys_account_fleet.
INSERT IGNORE INTO sys_role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM sys_role AS r JOIN sys_permission AS p ON p.permission_code IN (
    'membership.fleet.read', 'membership.fleet.manage',
    'membership.fleet_card.read', 'membership.fleet_card.manage',
    'membership.fleet_authorization.read', 'membership.fleet_authorization.manage',
    'membership.fleet_quota.manage', 'membership.vehicle.read'
)
WHERE r.role_code = 'fleet_admin';
