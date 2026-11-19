-- MySQL dump 10.13  Distrib 8.0.29, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: charging_platform_test
-- ------------------------------------------------------
-- Server version	8.0.29

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `action_item`
--

DROP TABLE IF EXISTS `action_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `action_item` (
  `item_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `postmortem_id` bigint unsigned NOT NULL COMMENT '来源复盘',
  `description` varchar(500) NOT NULL COMMENT '整改内容',
  `owner_account_id` bigint unsigned NOT NULL COMMENT '责任人',
  `due_date` date NOT NULL COMMENT '期限',
  `status` varchar(16) NOT NULL DEFAULT 'open' COMMENT '整改状态',
  `verified_at` datetime(3) DEFAULT NULL COMMENT '验收时间',
  `verified_by` bigint unsigned DEFAULT NULL COMMENT '验收账号',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`item_id`),
  KEY `ix_action_item_owner_status_due` (`owner_account_id`,`status`,`due_date`),
  KEY `fk_action_item_postmortem` (`postmortem_id`),
  KEY `fk_action_item_verifier` (`verified_by`),
  CONSTRAINT `fk_action_item_owner` FOREIGN KEY (`owner_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_action_item_postmortem` FOREIGN KEY (`postmortem_id`) REFERENCES `postmortem` (`postmortem_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_action_item_verifier` FOREIGN KEY (`verified_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_action_item_1` CHECK ((`status` in (_utf8mb4'open',_utf8mb4'done',_utf8mb4'verified',_utf8mb4'overdue'))),
  CONSTRAINT `ck_action_item_2` CHECK (((`status` <> _utf8mb4'verified') or ((`verified_by` is not null) and (`verified_at` is not null))))
) ENGINE=InnoDB AUTO_INCREMENT=922 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='整改项';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `action_item`
--

LOCK TABLES `action_item` WRITE;
/*!40000 ALTER TABLE `action_item` DISABLE KEYS */;
INSERT INTO `action_item` VALUES (901,901,'为 6 号场站加装模块温度联锁，并将散热风扇纳入季度更换计划',102,'2026-11-20','open',NULL,NULL,'2026-11-19 10:23:00.203','2026-11-19 10:23:00.203'),(902,911,'补充双路市电切换演练',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(903,912,'完成通信模块巡检标准化',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(904,913,'建立功率器件寿命台账',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(905,914,'补充协议栈兼容测试用例',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(906,915,'上线证书到期提醒',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(907,916,'与供电方建立通知渠道',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(908,917,'端子紧固纳入季度巡检',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(909,918,'完成弱电井信号复测',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(910,919,'统一枪线收纳标准',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(911,920,'增加计费队列积压告警',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(912,921,'补充异常登录审计规则',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(913,922,'地锁防松件全站排查',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(914,923,'更换全部到期浪涌器件',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(915,924,'交换机端口清洁专项',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(916,925,'散热风扇季度更换计划落地',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(917,926,'配置变更双人复核',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(918,927,'发布固件基线清单',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(919,928,'标识牌固定件补装',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(920,929,'雷雨季专项巡检预案',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572'),(921,930,'交换机模块备件预置',102,'2026-11-30','open',NULL,NULL,'2026-11-19 10:23:00.572','2026-11-19 10:23:00.572');
/*!40000 ALTER TABLE `action_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `alarm_rule`
--

DROP TABLE IF EXISTS `alarm_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alarm_rule` (
  `alarm_rule_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `rule_code` varchar(50) NOT NULL COMMENT '唯一规则码',
  `fault_code` varchar(32) DEFAULT NULL COMMENT '匹配设备故障码',
  `metric` varchar(32) NOT NULL COMMENT '判断指标',
  `threshold_value` decimal(12,3) DEFAULT NULL COMMENT '温度阈值或心跳秒数',
  `severity` varchar(32) NOT NULL COMMENT '告警等级',
  `response_seconds` int unsigned NOT NULL COMMENT '响应时限秒',
  `recovery_seconds` int unsigned NOT NULL COMMENT '连续正常观察秒',
  `enabled` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '是否启用',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`alarm_rule_id`),
  UNIQUE KEY `uq_alarm_rule_rule_code` (`rule_code`),
  CONSTRAINT `ck_alarm_rule_1` CHECK ((`metric` in (_utf8mb4'fault_code',_utf8mb4'temperature',_utf8mb4'heartbeat'))),
  CONSTRAINT `ck_alarm_rule_2` CHECK ((`severity` in (_utf8mb4'low',_utf8mb4'medium',_utf8mb4'high',_utf8mb4'critical'))),
  CONSTRAINT `ck_alarm_rule_3` CHECK ((`enabled` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=924 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alarm_rule`
--

LOCK TABLES `alarm_rule` WRITE;
/*!40000 ALTER TABLE `alarm_rule` DISABLE KEYS */;
INSERT INTO `alarm_rule` VALUES (1,'DEMO-E001','E001','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(2,'DEMO-E002','E002','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(3,'DEMO-E003','E003','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(4,'DEMO-E004','E004','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(5,'DEMO-E005','E005','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(6,'DEMO-E006','E006','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(7,'DEMO-E007','E007','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(8,'DEMO-E008','E008','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(9,'DEMO-E009','E009','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(10,'DEMO-E010','E010','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(11,'DEMO-E011','E011','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(12,'DEMO-E012','E012','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(13,'DEMO-E013','E013','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(14,'DEMO-E014','E014','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(15,'DEMO-E015','E015','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(16,'DEMO-E016','E016','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(17,'DEMO-E017','E017','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(18,'DEMO-E018','E018','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(19,'DEMO-E019','E019','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(20,'DEMO-E020','E020','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:52.877','2026-11-19 10:22:52.877'),(901,'SCN-CRIT-E101','E101','fault_code',NULL,'critical',300,120,1,'2026-11-19 10:22:53.335','2026-11-19 10:22:53.335'),(902,'SCN-HIGH-E102','E102','fault_code',NULL,'high',600,60,1,'2026-11-19 10:22:53.335','2026-11-19 10:22:53.335'),(903,'SCN-MED-E103','E103','fault_code',NULL,'medium',1800,300,1,'2026-11-19 10:22:53.335','2026-11-19 10:22:53.335'),(904,'SCN-LOW-E104','E104','fault_code',NULL,'low',7200,600,1,'2026-11-19 10:22:53.335','2026-11-19 10:22:53.335'),(905,'SCN-TEMP-70',NULL,'temperature',70.000,'high',600,60,1,'2026-11-19 10:22:53.335','2026-11-19 10:22:53.335'),(906,'SCN-HB-180',NULL,'heartbeat',180.000,'high',600,60,1,'2026-11-19 10:22:53.335','2026-11-19 10:22:53.335'),(907,'CHG-INTERRUPT','CHG01','fault_code',NULL,'high',1800,300,1,'2026-11-19 10:22:54.376','2026-11-19 10:22:54.376'),(908,'TEMP-065','TEMP01','temperature',65.000,'high',1800,300,1,'2026-11-19 10:22:54.431','2026-11-19 10:22:54.431'),(909,'MET-001','MET01','fault_code',NULL,'critical',600,120,1,'2026-11-19 10:22:54.443','2026-11-19 10:22:54.443');
/*!40000 ALTER TABLE `alarm_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `app_user`
--

DROP TABLE IF EXISTS `app_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_user` (
  `user_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `account_id` bigint unsigned DEFAULT NULL COMMENT '可选一对一账号',
  `display_name` varchar(50) NOT NULL COMMENT '显示姓名',
  `phone_cipher` varbinary(512) NOT NULL COMMENT '手机号密文',
  `phone_hash` binary(32) NOT NULL COMMENT '带密钥HMAC检索摘要',
  `real_name_status` varchar(32) NOT NULL DEFAULT 'unverified' COMMENT '实名状态',
  `registration_channel` varchar(32) NOT NULL DEFAULT 'web' COMMENT '注册渠道',
  `registered_at` datetime(3) NOT NULL COMMENT '注册时间',
  `member_level` varchar(32) NOT NULL DEFAULT 'normal' COMMENT '会员等级',
  `balance` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '余额缓存 与流水一致',
  `status` varchar(32) NOT NULL DEFAULT 'active' COMMENT '档案状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uq_app_user_phone_hash` (`phone_hash`),
  UNIQUE KEY `uq_app_user_account_id` (`account_id`),
  CONSTRAINT `fk_app_user_account_id` FOREIGN KEY (`account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_app_user_1` CHECK ((`balance` >= 0)),
  CONSTRAINT `ck_app_user_2` CHECK ((`real_name_status` in (_utf8mb4'unverified',_utf8mb4'verified',_utf8mb4'rejected'))),
  CONSTRAINT `ck_app_user_3` CHECK ((`member_level` in (_utf8mb4'normal',_utf8mb4'silver',_utf8mb4'gold'))),
  CONSTRAINT `ck_app_user_4` CHECK ((`status` in (_utf8mb4'active',_utf8mb4'disabled')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_user`
--

LOCK TABLES `app_user` WRITE;
/*!40000 ALTER TABLE `app_user` DISABLE KEYS */;
INSERT INTO `app_user` VALUES (1,1001,'演示车主01',_binary 'gAAAAABq9qidmn0GXE7MdY4hwh_Tn4uFmaqHt0GQGbQu2qXQjNGyzoSBBfz26-a0BtLcBRfLuuTD1BgA4RmJ2q-Y93kD69Jmyw==',_binary '\�<\�E@t\�e�\�)�\�=�I\'\�\�c�A�A.\�.\�G�','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(2,1002,'演示车主02',_binary 'gAAAAABq9qidHv8kw5GycxjhG2B8mMEQFmMoHN6lfeBTX8Nbk-hjetH3rsz10PQQe-LiiR98tR_oeCyYp6kigIoYjroaau0N0Q==',_binary '>i �$\Z\�[]��fR\�P�.e\�\�\�\�x��\�1&C','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(3,1003,'演示车主03',_binary 'gAAAAABq9qidBMA62y-V9o4OxsKkidBJtBWIModlQX7Wa288tdvLYTWUNL4_ABdqR9XUXoXlMheuN98VwsKIgLS1hdxsDBjAaQ==',_binary '�7l��c\r �-м�8�:_]�dh�\��\�}k\0��\�','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(4,1004,'演示车主04',_binary 'gAAAAABq9qidEa6wUXzIUiHAVpJjb4ooOk7HvBz4g6TOZVKQaoGF6-gR-ebEwkelpxZWbmn7gxZJSRO70WE8iMS3TTP7VsqWFw==',_binary 'N\Z�)/\�U\���ҟ\\[\�΢�Z\�\�7�S�\�G','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(5,1005,'演示车主05',_binary 'gAAAAABq9qidwWbmLHdNj9XkunoYntmzOC2I9l5rIwknkifdX7QRWx3y6YNY7-8ZUJ72uQ3aRO9bBx074es3rn6Z2P2iP59xfA==',_binary 'En�r�1��\"\�3\Z\�΋X��P\�+�\0}�','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(6,1006,'演示车主06',_binary 'gAAAAABq9qidUOF-m-4Q8x_iIbvrOb_BHHHqq5zD-re6XmfrUDUyGtc1iiL1JiTk0it_I2FZeL03YIqV7aa8aIJVs600QBYDSQ==',_binary '\��:uFg\��\�\�wv�Q	\r�mj�e\�\�\�\�9�pD','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(7,1007,'演示车主07',_binary 'gAAAAABq9qidvxqF8jjQRE-AQVwyhPAQ7NAjg5smwggHEwMeHycCJg_d05XnGPGpBFeBOmdryZiDq7-aSNJeEpQs7kGnFx-LHQ==',_binary 'hR7e�`\�+��H\�\�(%��\�\�Hh�K\�[','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(8,1008,'演示车主08',_binary 'gAAAAABq9qid17uA76LBB-SfxiIHYKXN-AY3PWggRznhzM1nEE34Cwm64EnFnAWeBReYueE7Zjj5LRclkWddM73BsM291g0xpw==',_binary '%\�R\�\�Y0$��\�\�\�\�&zZ\�Bp-\�6��=P\�\�\�i','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(9,1009,'演示车主09',_binary 'gAAAAABq9qidMA2YqnOxtfqxBGvd-ix3-N30umhJx7EN5zSRCH7AFs75ejuggLQBDYIgnYcROjPULc10WIkBHAse2hWcU1c-OA==',_binary 'x�\�s.\�9[\�\���\�b����B��3Tx#F�l','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(10,1010,'演示车主10',_binary 'gAAAAABq9qidapqzucqm5LiflEZFhgKcmR7sESXnL1aAu7MD1nHZD9tdGa_4DI6pT6NdRzj_4Jr1R8dTzn_4vH-ZMTWt0ba6BQ==',_binary '����r4�\�~���ƾY��\��T\�u�\�#ay\�J�','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(11,1011,'演示车主11',_binary 'gAAAAABq9qid6QAUFGo6CKEKtO20TYjfQXHGI8gixbXqmPshsdlhyuGrK9OSgBp8Vf1M2FO27v9n_mkB9FTwsBxZz5Sc-yemaw==',_binary 'C\�\�Jr�ran\�x͆�Z=�\�Э`�j9\��[�','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(12,1012,'演示车主12',_binary 'gAAAAABq9qidLCe9qDj4bSS4937CiJ_ptYVZLafCU9tUAVhx356V5TylcBUA3dzLFjkYfY06TUEQKQnMB1WjOZ4kY2wX5YqlaQ==',_binary 'p&D\�N�k\ZWa��\�\�b\�\�\�j\�JTڗ�\�\�\\\�','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(13,1013,'演示车主13',_binary 'gAAAAABq9qidbRf3Dl4zoa6v1AYqe0jR8qcM3llpv_VgfrgRjlwEe0fHhykxGkh1l87DSouvMDIOB95lWVao0BFLZth67L1sKw==',_binary '�Ŗ�!2\�\�\\xv`\0\�T�f*E�t\�?�\�','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(14,1014,'演示车主14',_binary 'gAAAAABq9qidkvUo7G5rir7RJKTOsHIe8END6i5mRZ2cQzA3a9EC6RO3Do58R1pUX448nir95N1TnpdmpwvKTam_0ROqT-YgfQ==',_binary '��\�\�h\�\�1�%�\�\�\�\�Zy<[\'O�(\��\�G��	','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(15,1015,'演示车主15',_binary 'gAAAAABq9qidcclGFdpDYLcMo_RGB_wEbWJ7YBEA-n0hg3e9mcFduGLq9ogAjlrIDiHSa8rJ2-qvtKqTXQZsIEvuRITqO7tC7g==',_binary ']�f���0xO�}B\�\�\�I{\�$�ዚw','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(16,1016,'演示车主16',_binary 'gAAAAABq9qidis5X1Jlp-RRIfig2ObVVBM0g8s__HXCH-QOTXgGFTZDBHqhGD7WOsI-J-MTOj0-gmYDNMjvg-SJVbrjP03dcOQ==',_binary 'z�3<6\�F��\�\�fw7��2j}�~�\�8�\�e\�','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(17,1017,'演示车主17',_binary 'gAAAAABq9qidGUBCrdOMUcyaPGklzU4ZzUksFkzvcRvrDt1yLzhDDWNBglGbFRhBbX1pQc00lzTuzNirLvNESve43V3rRfejHA==',_binary '�\�\�7?_A`�\�/��\����įx\�RX_�-=�\�','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(18,1018,'演示车主18',_binary 'gAAAAABq9qidtR7cycp2JZT5ECHV9ywj5mmDLZ0uwkNQ5UZmkJCanYT5LWiddPx1bnqiie21kk9hDvjG8YhAupPPAJLqlVIgqQ==',_binary '\�BS�M��\�9�TD\r+�r� \�\�q^UL�K��I��','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(19,1019,'演示车主19',_binary 'gAAAAABq9qidTtEw5LwjazbANcu7aViwTyW8KR6UDAJ2ATbJ4xJ5mR3IBr9D9K_VgM83NUMXmMxlIPLDkReLe7BIumOTPP3nnA==',_binary '�D\�*�$A�����;���\�\�8N\��ޟ�\�2M\�\�','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896'),(20,1020,'演示车主20',_binary 'gAAAAABq9qidWInnHhQX_vTCUHmbxt01nNUYL32ALMUuuh0wyDmTaowWjuLKssHV01BDD50T9qWC_iVoDxQaUfi2nmWYl_kGNQ==',_binary '�`ۅ\'�\�zjl\�i		?�\�^:Oɦ?@q\�<','verified','web','2026-09-15 01:00:00.000','normal',200.00,'active','2026-11-19 10:22:52.896','2026-11-19 10:22:52.896');
/*!40000 ALTER TABLE `app_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `billing_detail`
--

DROP TABLE IF EXISTS `billing_detail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `billing_detail` (
  `detail_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` bigint unsigned NOT NULL COMMENT '订单',
  `period_id` bigint unsigned NOT NULL COMMENT '普通时段依据',
  `price_id` bigint unsigned DEFAULT NULL COMMENT '车队专价 可空',
  `segment_start_at` datetime(3) NOT NULL COMMENT '分段开始',
  `segment_end_at` datetime(3) NOT NULL COMMENT '分段结束',
  `energy_kwh` decimal(14,3) NOT NULL COMMENT '本段电量',
  `electricity_rate` decimal(12,4) NOT NULL COMMENT '实际电价快照',
  `service_rate` decimal(12,4) NOT NULL COMMENT '实际服务单价快照 免费时为0',
  `electricity_amount` decimal(14,2) NOT NULL COMMENT '本段电费',
  `service_amount` decimal(14,2) NOT NULL COMMENT '本段服务费',
  `price_source` varchar(32) NOT NULL COMMENT '采用来源',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`detail_id`),
  UNIQUE KEY `uq_billing_detail_order_id_segment_start_at_segment_end_at` (`order_id`,`segment_start_at`,`segment_end_at`),
  KEY `fk_billing_detail_period_id` (`period_id`),
  KEY `fk_billing_detail_price_id` (`price_id`),
  CONSTRAINT `fk_billing_detail_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_billing_detail_period_id` FOREIGN KEY (`period_id`) REFERENCES `pricing_period` (`period_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_billing_detail_price_id` FOREIGN KEY (`price_id`) REFERENCES `fleet_price` (`price_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_billing_detail_1` CHECK ((`segment_end_at` > `segment_start_at`)),
  CONSTRAINT `ck_billing_detail_2` CHECK ((`energy_kwh` >= 0)),
  CONSTRAINT `ck_billing_detail_3` CHECK ((((`price_source` = _utf8mb4'fleet') and (`price_id` is not null)) or ((`price_source` = _utf8mb4'ordinary') and (`price_id` is null)))),
  CONSTRAINT `ck_billing_detail_4` CHECK ((`price_source` in (_utf8mb4'ordinary',_utf8mb4'fleet')))
) ENGINE=InnoDB AUTO_INCREMENT=1021 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `billing_detail`
--

LOCK TABLES `billing_detail` WRITE;
/*!40000 ALTER TABLE `billing_detail` DISABLE KEYS */;
INSERT INTO `billing_detail` VALUES (1,1,12,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',11.000,0.6000,0.2500,6.60,2.75,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(2,2,22,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',12.000,0.6000,0.2500,7.20,3.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(3,3,32,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',13.000,0.6000,0.2500,7.80,3.25,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(4,4,42,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',14.000,0.6000,0.2500,8.40,3.50,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(5,5,52,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',15.000,0.6000,0.2500,9.00,3.75,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(6,6,62,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',16.000,0.6000,0.2500,9.60,4.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(7,7,72,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',17.000,0.6000,0.2500,10.20,4.25,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(8,8,82,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',18.000,0.6000,0.2500,10.80,4.50,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(9,9,92,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',19.000,0.6000,0.2500,11.40,4.75,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(10,10,102,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',20.000,0.6000,0.2500,12.00,5.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(11,11,112,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',21.000,0.6000,0.2500,12.60,5.25,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(12,12,122,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',22.000,0.6000,0.2500,13.20,5.50,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(13,13,132,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',23.000,0.6000,0.2500,13.80,5.75,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(14,14,142,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',24.000,0.6000,0.2500,14.40,6.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(15,15,152,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',25.000,0.6000,0.2500,15.00,6.25,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(16,16,162,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',26.000,0.6000,0.2500,15.60,6.50,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(17,17,172,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',27.000,0.6000,0.2500,16.20,6.75,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(18,18,182,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',28.000,0.6000,0.2500,16.80,7.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(19,19,192,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',29.000,0.6000,0.2500,17.40,7.25,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(20,20,202,NULL,'2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',30.000,0.6000,0.2500,18.00,7.50,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(101,101,12,1,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',9.000,0.5500,0.2000,4.95,1.80,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(102,102,22,2,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',10.000,0.5500,0.2000,5.50,2.00,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(103,103,32,3,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',11.000,0.5500,0.2000,6.05,2.20,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(104,104,42,4,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',12.000,0.5500,0.2000,6.60,2.40,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(105,105,52,5,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',13.000,0.5500,0.2000,7.15,2.60,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(106,106,62,6,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',14.000,0.5500,0.2000,7.70,2.80,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(107,107,72,7,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',15.000,0.5500,0.2000,8.25,3.00,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(108,108,82,8,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',16.000,0.5500,0.2000,8.80,3.20,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(109,109,92,9,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',17.000,0.5500,0.2000,9.35,3.40,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(110,110,102,10,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',18.000,0.5500,0.2000,9.90,3.60,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(111,111,112,11,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',19.000,0.5500,0.2000,10.45,3.80,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(112,112,122,12,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',20.000,0.5500,0.2000,11.00,4.00,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(113,113,132,13,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',21.000,0.5500,0.2000,11.55,4.20,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(114,114,142,14,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',22.000,0.5500,0.2000,12.10,4.40,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(115,115,152,15,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',23.000,0.5500,0.2000,12.65,4.60,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(116,116,162,16,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',24.000,0.5500,0.2000,13.20,4.80,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(117,117,172,17,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',25.000,0.5500,0.2000,13.75,5.00,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(118,118,182,18,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',26.000,0.5500,0.2000,14.30,5.20,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(119,119,192,19,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',27.000,0.5500,0.2000,14.85,5.40,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(120,120,202,20,'2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',28.000,0.5500,0.2000,15.40,5.60,'fleet','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1001,1001,12,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1002,1002,22,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1003,1003,32,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1004,1004,42,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1005,1005,52,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1006,1006,62,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1007,1007,72,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1008,1008,82,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1009,1009,92,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1010,1010,102,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1011,1011,112,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1012,1012,122,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1013,1013,132,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1014,1014,142,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1015,1015,152,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1016,1016,162,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1017,1017,172,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1018,1018,182,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1019,1019,192,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971'),(1020,1020,202,NULL,'2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',4.000,0.6000,0.2500,2.40,1.00,'ordinary','2026-11-19 10:22:52.971','2026-11-19 10:22:52.971');
/*!40000 ALTER TABLE `billing_detail` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `charging_gun`
--

DROP TABLE IF EXISTS `charging_gun`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `charging_gun` (
  `gun_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `pile_id` bigint unsigned NOT NULL COMMENT '所属桩',
  `gun_no` smallint unsigned NOT NULL COMMENT '桩内枪序号',
  `gun_type` varchar(32) NOT NULL COMMENT '直流快充或交流慢充',
  `connector_standard` varchar(50) NOT NULL COMMENT '接口标准',
  `max_power_kw` decimal(10,3) NOT NULL COMMENT '最大功率kW',
  `status` varchar(32) NOT NULL DEFAULT 'offline' COMMENT '当前状态',
  `has_fault` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '故障标记 与在线事实分开',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`gun_id`),
  UNIQUE KEY `uq_charging_gun_pile_id_gun_no` (`pile_id`,`gun_no`),
  CONSTRAINT `fk_charging_gun_pile_id` FOREIGN KEY (`pile_id`) REFERENCES `charging_pile` (`pile_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_charging_gun_1` CHECK ((`gun_no` > 0)),
  CONSTRAINT `ck_charging_gun_2` CHECK ((`max_power_kw` > 0)),
  CONSTRAINT `ck_charging_gun_3` CHECK ((`gun_type` in (_utf8mb4'dc',_utf8mb4'ac'))),
  CONSTRAINT `ck_charging_gun_4` CHECK ((`status` in (_utf8mb4'idle',_utf8mb4'occupied',_utf8mb4'fault',_utf8mb4'offline'))),
  CONSTRAINT `ck_charging_gun_5` CHECK ((`has_fault` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=904 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `charging_gun`
--

LOCK TABLES `charging_gun` WRITE;
/*!40000 ALTER TABLE `charging_gun` DISABLE KEYS */;
INSERT INTO `charging_gun` VALUES (1,1,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(2,2,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(3,3,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(4,4,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(5,5,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(6,6,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(7,7,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(8,8,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(9,9,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(10,10,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(11,11,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(12,12,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(13,13,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(14,14,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(15,15,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(16,16,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(17,17,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(18,18,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(19,19,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(20,20,1,'dc','GB/T',60.000,'idle',0,'2026-11-19 10:22:52.930','2026-11-19 10:22:52.930'),(901,901,1,'dc','GB/T',60.000,'fault',0,'2026-11-19 10:23:00.097','2026-11-19 10:23:27.408'),(902,902,1,'dc','GB/T',60.000,'offline',0,'2026-11-19 10:23:00.097','2026-11-19 10:23:00.097'),(903,903,1,'dc','GB/T',60.000,'fault',0,'2026-11-19 10:23:00.097','2026-11-19 10:23:00.097');
/*!40000 ALTER TABLE `charging_gun` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `charging_order`
--

DROP TABLE IF EXISTS `charging_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `charging_order` (
  `order_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint unsigned NOT NULL COMMENT '发起车主',
  `gun_id` bigint unsigned NOT NULL COMMENT '充电枪',
  `vehicle_id` bigint unsigned DEFAULT NULL COMMENT '个人可空 车队由授权确定',
  `authorization_id` bigint unsigned DEFAULT NULL COMMENT '车队授权 个人为空',
  `rule_id` bigint unsigned NOT NULL COMMENT '启动时普通规则',
  `operator_id` bigint unsigned NOT NULL COMMENT '启动归属快照',
  `station_id` bigint unsigned NOT NULL COMMENT '启动场站快照',
  `fleet_id` bigint unsigned DEFAULT NULL COMMENT '车队归属快照',
  `settlement_id` bigint unsigned DEFAULT NULL COMMENT '运营商结算归集',
  `order_mode` varchar(32) NOT NULL COMMENT '订单模式',
  `status` varchar(32) NOT NULL DEFAULT 'charging' COMMENT '订单状态 退款另表',
  `started_at` datetime(3) NOT NULL COMMENT '实际开始时间',
  `finished_at` datetime(3) DEFAULT NULL COMMENT '实际结束时间',
  `start_soc` decimal(5,2) DEFAULT NULL COMMENT '车辆开始电量百分比',
  `end_soc` decimal(5,2) DEFAULT NULL COMMENT '车辆结束电量百分比',
  `energy_kwh` decimal(14,3) NOT NULL DEFAULT '0.000' COMMENT '累计实际充电电量',
  `electricity_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '核定电费',
  `service_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '核定服务费',
  `minimum_topup_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '起步补差',
  `discount_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '券抵扣',
  `payable_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '最终应付',
  `free_service_minutes_snapshot` int unsigned NOT NULL DEFAULT '0' COMMENT '启动规则免费分钟快照',
  `minimum_amount_snapshot` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '启动规则起步金额快照',
  `review_required` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '核价或额度需人工复核',
  `review_reason` varchar(500) DEFAULT NULL COMMENT '复核原因',
  `payment_due_at` datetime(3) DEFAULT NULL COMMENT '付款截止 不由网页倒计时决定',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  `active_gun_id` bigint unsigned GENERATED ALWAYS AS ((case when (`status` = _utf8mb4'charging') then `gun_id` else NULL end)) STORED COMMENT '唯一进行中枪 生成列禁止客户端赋值',
  PRIMARY KEY (`order_id`),
  UNIQUE KEY `uq_charging_order_active_gun_id` (`active_gun_id`),
  KEY `ix_charging_order_user_id_started_at` (`user_id`,`started_at`),
  KEY `ix_charging_order_station_id_finished_at` (`station_id`,`finished_at`),
  KEY `ix_charging_order_fleet_id_finished_at` (`fleet_id`,`finished_at`),
  KEY `fk_charging_order_gun_id` (`gun_id`),
  KEY `fk_charging_order_vehicle_id` (`vehicle_id`),
  KEY `fk_charging_order_authorization_id` (`authorization_id`),
  KEY `fk_charging_order_rule_id` (`rule_id`),
  KEY `fk_charging_order_operator_id` (`operator_id`),
  KEY `fk_charging_order_settlement_id` (`settlement_id`),
  CONSTRAINT `fk_charging_order_authorization_id` FOREIGN KEY (`authorization_id`) REFERENCES `fleet_authorization` (`authorization_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_charging_order_fleet_id` FOREIGN KEY (`fleet_id`) REFERENCES `fleet` (`fleet_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_charging_order_gun_id` FOREIGN KEY (`gun_id`) REFERENCES `charging_gun` (`gun_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_charging_order_operator_id` FOREIGN KEY (`operator_id`) REFERENCES `operator` (`operator_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_charging_order_rule_id` FOREIGN KEY (`rule_id`) REFERENCES `pricing_rule` (`rule_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_charging_order_settlement_id` FOREIGN KEY (`settlement_id`) REFERENCES `operator_settlement` (`settlement_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_charging_order_station_id` FOREIGN KEY (`station_id`) REFERENCES `station` (`station_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_charging_order_user_id` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_charging_order_vehicle_id` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicle` (`vehicle_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_charging_order_1` CHECK ((((`order_mode` = _utf8mb4'personal') and (`authorization_id` is null) and (`fleet_id` is null)) or ((`order_mode` = _utf8mb4'fleet') and (`authorization_id` is not null) and (`fleet_id` is not null) and (`vehicle_id` is not null)))),
  CONSTRAINT `ck_charging_order_2` CHECK (((`finished_at` is null) or (`finished_at` >= `started_at`))),
  CONSTRAINT `ck_charging_order_3` CHECK (((`start_soc` is null) or (`start_soc` between 0 and 100))),
  CONSTRAINT `ck_charging_order_4` CHECK (((`end_soc` is null) or (`end_soc` between 0 and 100))),
  CONSTRAINT `ck_charging_order_5` CHECK ((`energy_kwh` >= 0)),
  CONSTRAINT `ck_charging_order_6` CHECK ((`payable_amount` >= 0)),
  CONSTRAINT `ck_charging_order_7` CHECK ((`order_mode` in (_utf8mb4'personal',_utf8mb4'fleet'))),
  CONSTRAINT `ck_charging_order_8` CHECK ((`status` in (_utf8mb4'charging',_utf8mb4'awaiting_payment',_utf8mb4'paid',_utf8mb4'cancelled'))),
  CONSTRAINT `ck_charging_order_9` CHECK ((`review_required` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=1028 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `charging_order`
--

LOCK TABLES `charging_order` WRITE;
/*!40000 ALTER TABLE `charging_order` DISABLE KEYS */;
INSERT INTO `charging_order` (`order_id`, `user_id`, `gun_id`, `vehicle_id`, `authorization_id`, `rule_id`, `operator_id`, `station_id`, `fleet_id`, `settlement_id`, `order_mode`, `status`, `started_at`, `finished_at`, `start_soc`, `end_soc`, `energy_kwh`, `electricity_amount`, `service_amount`, `minimum_topup_amount`, `discount_amount`, `payable_amount`, `free_service_minutes_snapshot`, `minimum_amount_snapshot`, `review_required`, `review_reason`, `payment_due_at`, `created_at`, `updated_at`) VALUES (1,1,1,NULL,NULL,1,1,1,NULL,1,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,11.000,6.60,2.75,0.00,3.00,6.35,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(2,2,2,NULL,NULL,2,2,2,NULL,2,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,12.000,7.20,3.00,0.00,3.00,7.20,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(3,3,3,NULL,NULL,3,3,3,NULL,3,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,13.000,7.80,3.25,0.00,3.00,8.05,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(4,4,4,NULL,NULL,4,4,4,NULL,4,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,14.000,8.40,3.50,0.00,3.00,8.90,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(5,5,5,NULL,NULL,5,5,5,NULL,5,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,15.000,9.00,3.75,0.00,3.00,9.75,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(6,6,6,NULL,NULL,6,6,6,NULL,6,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,16.000,9.60,4.00,0.00,3.00,10.60,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(7,7,7,NULL,NULL,7,7,7,NULL,7,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,17.000,10.20,4.25,0.00,3.00,11.45,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(8,8,8,NULL,NULL,8,8,8,NULL,8,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,18.000,10.80,4.50,0.00,3.00,12.30,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(9,9,9,NULL,NULL,9,9,9,NULL,9,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,19.000,11.40,4.75,0.00,3.00,13.15,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(10,10,10,NULL,NULL,10,10,10,NULL,10,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,20.000,12.00,5.00,0.00,3.00,14.00,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(11,11,11,NULL,NULL,11,11,11,NULL,11,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,21.000,12.60,5.25,0.00,3.00,14.85,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(12,12,12,NULL,NULL,12,12,12,NULL,12,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,22.000,13.20,5.50,0.00,3.00,15.70,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(13,13,13,NULL,NULL,13,13,13,NULL,13,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,23.000,13.80,5.75,0.00,3.00,16.55,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(14,14,14,NULL,NULL,14,14,14,NULL,14,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,24.000,14.40,6.00,0.00,3.00,17.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(15,15,15,NULL,NULL,15,15,15,NULL,15,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,25.000,15.00,6.25,0.00,3.00,18.25,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(16,16,16,NULL,NULL,16,16,16,NULL,16,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,26.000,15.60,6.50,0.00,3.00,19.10,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(17,17,17,NULL,NULL,17,17,17,NULL,17,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,27.000,16.20,6.75,0.00,3.00,19.95,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(18,18,18,NULL,NULL,18,18,18,NULL,18,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,28.000,16.80,7.00,0.00,3.00,20.80,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(19,19,19,NULL,NULL,19,19,19,NULL,19,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,29.000,17.40,7.25,0.00,3.00,21.65,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(20,20,20,NULL,NULL,20,20,20,NULL,20,'personal','paid','2026-10-20 02:00:00.000','2026-10-20 02:30:00.000',NULL,NULL,30.000,18.00,7.50,0.00,3.00,22.50,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(101,1,1,1,1,1,1,1,1,1,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,9.000,4.95,1.80,0.00,0.00,6.75,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(102,2,2,2,2,2,2,2,2,2,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,10.000,5.50,2.00,0.00,0.00,7.50,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(103,3,3,3,3,3,3,3,3,3,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,11.000,6.05,2.20,0.00,0.00,8.25,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(104,4,4,4,4,4,4,4,4,4,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,12.000,6.60,2.40,0.00,0.00,9.00,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(105,5,5,5,5,5,5,5,5,5,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,13.000,7.15,2.60,0.00,0.00,9.75,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(106,6,6,6,6,6,6,6,6,6,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,14.000,7.70,2.80,0.00,0.00,10.50,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(107,7,7,7,7,7,7,7,7,7,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,15.000,8.25,3.00,0.00,0.00,11.25,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(108,8,8,8,8,8,8,8,8,8,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,16.000,8.80,3.20,0.00,0.00,12.00,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(109,9,9,9,9,9,9,9,9,9,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,17.000,9.35,3.40,0.00,0.00,12.75,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(110,10,10,10,10,10,10,10,10,10,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,18.000,9.90,3.60,0.00,0.00,13.50,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(111,11,11,11,11,11,11,11,11,11,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,19.000,10.45,3.80,0.00,0.00,14.25,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(112,12,12,12,12,12,12,12,12,12,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,20.000,11.00,4.00,0.00,0.00,15.00,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(113,13,13,13,13,13,13,13,13,13,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,21.000,11.55,4.20,0.00,0.00,15.75,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(114,14,14,14,14,14,14,14,14,14,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,22.000,12.10,4.40,0.00,0.00,16.50,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(115,15,15,15,15,15,15,15,15,15,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,23.000,12.65,4.60,0.00,0.00,17.25,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(116,16,16,16,16,16,16,16,16,16,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,24.000,13.20,4.80,0.00,0.00,18.00,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(117,17,17,17,17,17,17,17,17,17,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,25.000,13.75,5.00,0.00,0.00,18.75,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(118,18,18,18,18,18,18,18,18,18,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,26.000,14.30,5.20,0.00,0.00,19.50,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(119,19,19,19,19,19,19,19,19,19,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,27.000,14.85,5.40,0.00,0.00,20.25,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(120,20,20,20,20,20,20,20,20,20,'fleet','paid','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,NULL,28.000,15.40,5.60,0.00,0.00,21.00,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:53.012'),(1001,1,1,NULL,NULL,1,1,1,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1002,2,2,NULL,NULL,2,2,2,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1003,3,3,NULL,NULL,3,3,3,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1004,4,4,NULL,NULL,4,4,4,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1005,5,5,NULL,NULL,5,5,5,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1006,6,6,NULL,NULL,6,6,6,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1007,7,7,NULL,NULL,7,7,7,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1008,8,8,NULL,NULL,8,8,8,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1009,9,9,NULL,NULL,9,9,9,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1010,10,10,NULL,NULL,10,10,10,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1011,11,11,NULL,NULL,11,11,11,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1012,12,12,NULL,NULL,12,12,12,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1013,13,13,NULL,NULL,13,13,13,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1014,14,14,NULL,NULL,14,14,14,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1015,15,15,NULL,NULL,15,15,15,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1016,16,16,NULL,NULL,16,16,16,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1017,17,17,NULL,NULL,17,17,17,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1018,18,18,NULL,NULL,18,18,18,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1019,19,19,NULL,NULL,19,19,19,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953'),(1020,20,20,NULL,NULL,20,20,20,NULL,NULL,'personal','awaiting_payment','2026-10-20 05:00:00.000','2026-10-20 05:15:00.000',NULL,NULL,4.000,2.40,1.00,0.00,0.00,3.40,0,0.00,0,NULL,NULL,'2026-11-19 10:22:52.953','2026-11-19 10:22:52.953');
/*!40000 ALTER TABLE `charging_order` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `charging_pile`
--

DROP TABLE IF EXISTS `charging_pile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `charging_pile` (
  `pile_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `station_id` bigint unsigned NOT NULL COMMENT '所属场站',
  `serial_no` varchar(64) NOT NULL COMMENT '铭牌设备序列号',
  `model_name` varchar(100) NOT NULL COMMENT '设备型号',
  `rated_power_kw` decimal(10,3) NOT NULL COMMENT '整桩额定功率kW',
  `protocol` varchar(50) NOT NULL COMMENT '模拟或接入协议名称',
  `commissioned_on` date DEFAULT NULL COMMENT '投运日期',
  `warranty_until` date DEFAULT NULL COMMENT '质保截止',
  `lifecycle_status` varchar(32) NOT NULL DEFAULT 'draft' COMMENT '投运验收状态',
  `status` varchar(32) NOT NULL DEFAULT 'offline' COMMENT '当前设备状态',
  `has_fault` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '保留故障事实 不因离线清除',
  `is_online` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '通信在线事实',
  `last_heartbeat_at` datetime(3) DEFAULT NULL COMMENT '最后收到有效心跳',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`pile_id`),
  UNIQUE KEY `uq_charging_pile_serial_no` (`serial_no`),
  KEY `ix_charging_pile_station_id_status` (`station_id`,`status`),
  KEY `ix_charging_pile_last_heartbeat_at` (`last_heartbeat_at`),
  CONSTRAINT `fk_charging_pile_station_id` FOREIGN KEY (`station_id`) REFERENCES `station` (`station_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_charging_pile_1` CHECK ((`rated_power_kw` > 0)),
  CONSTRAINT `ck_charging_pile_2` CHECK ((`lifecycle_status` in (_utf8mb4'draft',_utf8mb4'pending_acceptance',_utf8mb4'active',_utf8mb4'retired'))),
  CONSTRAINT `ck_charging_pile_3` CHECK ((`status` in (_utf8mb4'idle',_utf8mb4'occupied',_utf8mb4'fault',_utf8mb4'offline'))),
  CONSTRAINT `ck_charging_pile_4` CHECK ((`has_fault` in (0,1))),
  CONSTRAINT `ck_charging_pile_5` CHECK ((`is_online` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=904 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `charging_pile`
--

LOCK TABLES `charging_pile` WRITE;
/*!40000 ALTER TABLE `charging_pile` DISABLE KEYS */;
INSERT INTO `charging_pile` VALUES (1,1,'PILE-01','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.158'),(2,2,'PILE-02','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.159'),(3,3,'PILE-03','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:25:12.321'),(4,4,'PILE-04','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','idle',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:27.933'),(5,5,'PILE-05','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','idle',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:25:12.772'),(6,6,'PILE-06','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.171'),(7,7,'PILE-07','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.174'),(8,8,'PILE-08','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.178'),(9,9,'PILE-09','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-19 10:25:11.897','2026-11-19 10:22:52.915','2026-11-19 10:25:11.904'),(10,10,'PILE-10','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.187'),(11,11,'PILE-11','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:25:12.710'),(12,12,'PILE-12','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.192'),(13,13,'PILE-13','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.195'),(14,14,'PILE-14','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.199'),(15,15,'PILE-15','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.201'),(16,16,'PILE-16','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','idle',0,1,'2026-11-19 09:25:10.963','2026-11-19 10:22:52.915','2026-11-19 10:25:10.992'),(17,17,'PILE-17','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.205'),(18,18,'PILE-18','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.208'),(19,19,'PILE-19','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.211'),(20,20,'PILE-20','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 13:29:00.000','2026-11-19 10:22:52.915','2026-11-19 10:23:26.214'),(901,901,'PILE-901','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','fault',1,0,'2026-11-13 11:58:00.000','2026-11-19 10:23:00.089','2026-11-19 10:23:27.410'),(902,901,'PILE-902','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 11:58:00.000','2026-11-19 10:23:00.089','2026-11-19 10:23:00.089'),(903,901,'PILE-903','DEMO-DC-120',120.000,'OCPP','2026-09-20','2028-09-20','active','offline',0,0,'2026-11-13 12:24:00.000','2026-11-19 10:23:00.089','2026-11-19 10:23:26.155');
/*!40000 ALTER TABLE `charging_pile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `coupon_usage`
--

DROP TABLE IF EXISTS `coupon_usage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coupon_usage` (
  `usage_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `coupon_id` bigint unsigned NOT NULL COMMENT '用户券',
  `order_id` bigint unsigned NOT NULL COMMENT '订单',
  `original_amount` decimal(14,2) NOT NULL COMMENT '优惠前电费服务费合计',
  `discount_amount` decimal(14,2) NOT NULL COMMENT '本次抵扣',
  `locked_at` datetime(3) NOT NULL COMMENT '锁定时间',
  `lock_expires_at` datetime(3) NOT NULL COMMENT '锁定截止',
  `redeemed_at` datetime(3) DEFAULT NULL COMMENT '核销时间',
  `released_at` datetime(3) DEFAULT NULL COMMENT '释放时间',
  `status` varchar(32) NOT NULL DEFAULT 'locked' COMMENT '本次使用状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  `active_coupon_id` bigint unsigned GENERATED ALWAYS AS ((case when (`status` in (_utf8mb4'locked',_utf8mb4'redeemed')) then `coupon_id` else NULL end)) STORED COMMENT '有效锁定或核销唯一',
  `active_order_id` bigint unsigned GENERATED ALWAYS AS ((case when (`status` in (_utf8mb4'locked',_utf8mb4'redeemed')) then `order_id` else NULL end)) STORED COMMENT '有效锁定或核销唯一',
  PRIMARY KEY (`usage_id`),
  UNIQUE KEY `uq_coupon_usage_active_coupon_id` (`active_coupon_id`),
  UNIQUE KEY `uq_coupon_usage_active_order_id` (`active_order_id`),
  KEY `fk_coupon_usage_coupon_id` (`coupon_id`),
  KEY `fk_coupon_usage_order_id` (`order_id`),
  CONSTRAINT `fk_coupon_usage_coupon_id` FOREIGN KEY (`coupon_id`) REFERENCES `user_coupon` (`coupon_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_coupon_usage_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_coupon_usage_1` CHECK ((`discount_amount` >= 0)),
  CONSTRAINT `ck_coupon_usage_2` CHECK ((`discount_amount` <= `original_amount`)),
  CONSTRAINT `ck_coupon_usage_3` CHECK ((`status` in (_utf8mb4'locked',_utf8mb4'redeemed',_utf8mb4'released')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `coupon_usage`
--

LOCK TABLES `coupon_usage` WRITE;
/*!40000 ALTER TABLE `coupon_usage` DISABLE KEYS */;
INSERT INTO `coupon_usage` (`usage_id`, `coupon_id`, `order_id`, `original_amount`, `discount_amount`, `locked_at`, `lock_expires_at`, `redeemed_at`, `released_at`, `status`, `created_at`, `updated_at`) VALUES (1,1,1,9.35,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(2,2,2,10.20,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(3,3,3,11.05,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(4,4,4,11.90,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(5,5,5,12.75,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(6,6,6,13.60,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(7,7,7,14.45,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(8,8,8,15.30,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(9,9,9,16.15,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(10,10,10,17.00,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(11,11,11,17.85,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(12,12,12,18.70,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(13,13,13,19.55,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(14,14,14,20.40,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(15,15,15,21.25,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(16,16,16,22.10,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(17,17,17,22.95,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(18,18,18,23.80,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(19,19,19,24.65,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001'),(20,20,20,25.50,3.00,'2026-10-20 02:30:00.000','2026-10-20 02:45:00.000','2026-10-20 02:32:00.000',NULL,'redeemed','2026-11-19 10:22:53.001','2026-11-19 10:22:53.001');
/*!40000 ALTER TABLE `coupon_usage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `device_acceptance`
--

DROP TABLE IF EXISTS `device_acceptance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_acceptance` (
  `acceptance_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `pile_id` bigint unsigned NOT NULL COMMENT '验收桩',
  `protocol_test_passed` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '模拟协议联调是否通过',
  `nameplate_checked` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '铭牌是否核对',
  `start_stop_passed` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '启停测试结果',
  `heartbeat_passed` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '心跳测试结果',
  `result` varchar(32) NOT NULL COMMENT '验收结论',
  `accepted_by` bigint unsigned NOT NULL COMMENT '验收账号',
  `accepted_at` datetime(3) NOT NULL COMMENT '验收时间',
  `note` varchar(500) DEFAULT NULL COMMENT '验收说明',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`acceptance_id`),
  KEY `fk_device_acceptance_pile_id` (`pile_id`),
  KEY `fk_device_acceptance_accepted_by` (`accepted_by`),
  CONSTRAINT `fk_device_acceptance_accepted_by` FOREIGN KEY (`accepted_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_device_acceptance_pile_id` FOREIGN KEY (`pile_id`) REFERENCES `charging_pile` (`pile_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_device_acceptance_1` CHECK ((`protocol_test_passed` in (0,1))),
  CONSTRAINT `ck_device_acceptance_2` CHECK ((`nameplate_checked` in (0,1))),
  CONSTRAINT `ck_device_acceptance_3` CHECK ((`start_stop_passed` in (0,1))),
  CONSTRAINT `ck_device_acceptance_4` CHECK ((`heartbeat_passed` in (0,1))),
  CONSTRAINT `ck_device_acceptance_5` CHECK ((`result` in (_utf8mb4'passed',_utf8mb4'failed')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `device_acceptance`
--

LOCK TABLES `device_acceptance` WRITE;
/*!40000 ALTER TABLE `device_acceptance` DISABLE KEYS */;
INSERT INTO `device_acceptance` VALUES (1,1,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(2,2,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(3,3,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(4,4,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(5,5,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(6,6,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(7,7,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(8,8,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(9,9,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(10,10,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(11,11,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(12,12,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(13,13,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(14,14,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(15,15,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(16,16,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(17,17,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(18,18,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(19,19,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931'),(20,20,1,1,1,1,'passed',102,'2026-09-19 08:00:00.000',NULL,'2026-11-19 10:22:52.931','2026-11-19 10:22:52.931');
/*!40000 ALTER TABLE `device_acceptance` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `device_alert`
--

DROP TABLE IF EXISTS `device_alert`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_alert` (
  `alert_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `pile_id` bigint unsigned NOT NULL COMMENT '所属桩',
  `gun_id` bigint unsigned DEFAULT NULL COMMENT '枪级故障才填',
  `alarm_rule_id` bigint unsigned NOT NULL COMMENT '命中规则',
  `alert_code` varchar(32) NOT NULL COMMENT '告警码快照',
  `severity` varchar(32) NOT NULL COMMENT '等级快照',
  `occurred_at` datetime(3) NOT NULL COMMENT '首次发生',
  `recovered_at` datetime(3) DEFAULT NULL COMMENT '完成复核后的恢复时间',
  `status` varchar(32) NOT NULL DEFAULT 'open' COMMENT '告警状态',
  `response_seconds_snapshot` int unsigned NOT NULL COMMENT '响应时限快照',
  `normal_since_at` datetime(3) DEFAULT NULL COMMENT '连续正常起始',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  `active_key` varchar(160) GENERATED ALWAYS AS ((case when (`status` <> _utf8mb4'recovered') then concat(`pile_id`,_utf8mb4':',coalesce(`gun_id`,0),_utf8mb4':',`alert_code`) else NULL end)) STORED COMMENT '未恢复告警唯一键',
  PRIMARY KEY (`alert_id`),
  UNIQUE KEY `uq_device_alert_active_key` (`active_key`),
  KEY `ix_device_alert_pile_id_status` (`pile_id`,`status`),
  KEY `fk_device_alert_gun_id` (`gun_id`),
  KEY `fk_device_alert_alarm_rule_id` (`alarm_rule_id`),
  KEY `ix_device_alert_occurred_at` (`occurred_at`),
  CONSTRAINT `fk_device_alert_alarm_rule_id` FOREIGN KEY (`alarm_rule_id`) REFERENCES `alarm_rule` (`alarm_rule_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_device_alert_gun_id` FOREIGN KEY (`gun_id`) REFERENCES `charging_gun` (`gun_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_device_alert_pile_id` FOREIGN KEY (`pile_id`) REFERENCES `charging_pile` (`pile_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_device_alert_1` CHECK ((`severity` in (_utf8mb4'low',_utf8mb4'medium',_utf8mb4'high',_utf8mb4'critical'))),
  CONSTRAINT `ck_device_alert_2` CHECK ((`status` in (_utf8mb4'open',_utf8mb4'processing',_utf8mb4'recovering',_utf8mb4'recovered')))
) ENGINE=InnoDB AUTO_INCREMENT=1134 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `device_alert`
--

LOCK TABLES `device_alert` WRITE;
/*!40000 ALTER TABLE `device_alert` DISABLE KEYS */;
INSERT INTO `device_alert` (`alert_id`, `pile_id`, `gun_id`, `alarm_rule_id`, `alert_code`, `severity`, `occurred_at`, `recovered_at`, `status`, `response_seconds_snapshot`, `normal_since_at`, `created_at`, `updated_at`) VALUES (1,1,1,1,'E001','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(2,2,2,2,'E002','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(3,3,3,3,'E003','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(4,4,4,4,'E004','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(5,5,5,5,'E005','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(6,6,6,6,'E006','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(7,7,7,7,'E007','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(8,8,8,8,'E008','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(9,9,9,9,'E009','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(10,10,10,10,'E010','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(11,11,11,11,'E011','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(12,12,12,12,'E012','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(13,13,13,13,'E013','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(14,14,14,14,'E014','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(15,15,15,15,'E015','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(16,16,16,16,'E016','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(17,17,17,17,'E017','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(18,18,18,18,'E018','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(19,19,19,19,'E019','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(20,20,20,20,'E020','high','2026-10-20 04:00:00.000','2026-10-20 04:35:00.000','recovered',600,'2026-10-20 04:34:00.000','2026-11-19 10:22:52.959','2026-11-19 10:22:52.959'),(901,4,4,901,'E101','critical','2026-11-13 09:35:00.000',NULL,'processing',300,NULL,'2026-11-19 10:22:53.345','2026-11-19 10:22:53.345'),(902,5,5,902,'E102','high','2026-11-13 09:20:00.000',NULL,'processing',600,NULL,'2026-11-19 10:22:53.345','2026-11-19 10:22:53.345'),(903,3,3,3,'E003','high','2026-11-14 01:00:00.000','2026-11-19 10:24:26.725','recovered',600,'2026-11-14 01:35:00.000','2026-11-19 10:22:53.345','2026-11-19 10:23:26.855'),(904,6,6,904,'E104','low','2026-11-13 02:00:00.000',NULL,'processing',7200,NULL,'2026-11-19 10:22:53.345','2026-11-19 10:22:53.345'),(911,901,901,901,'E101','critical','2026-11-13 12:00:00.000',NULL,'processing',300,NULL,'2026-11-19 10:23:00.104','2026-11-19 10:23:00.104'),(912,902,902,902,'E102','high','2026-11-13 12:12:00.000',NULL,'processing',600,NULL,'2026-11-19 10:23:00.104','2026-11-19 10:23:00.104'),(913,903,903,904,'E104','low','2026-11-13 12:24:00.000',NULL,'processing',7200,NULL,'2026-11-19 10:23:00.104','2026-11-19 10:23:00.104'),(931,1,1,1,'EXT-001','low','2026-11-10 01:00:00.000','2026-11-10 02:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(932,2,2,2,'EXT-002','low','2026-11-10 02:00:00.000','2026-11-10 03:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(933,3,3,3,'EXT-003','low','2026-11-10 03:00:00.000','2026-11-10 04:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(934,4,4,4,'EXT-004','low','2026-11-10 04:00:00.000','2026-11-10 05:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(935,5,5,5,'EXT-005','low','2026-11-10 05:00:00.000','2026-11-10 06:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(936,6,6,6,'EXT-006','low','2026-11-10 06:00:00.000','2026-11-10 07:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(937,7,7,7,'EXT-007','low','2026-11-10 07:00:00.000','2026-11-10 08:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(938,8,8,8,'EXT-008','low','2026-11-10 08:00:00.000','2026-11-10 09:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(939,9,9,9,'EXT-009','low','2026-11-10 09:00:00.000','2026-11-10 10:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(940,10,10,10,'EXT-010','low','2026-11-10 10:00:00.000','2026-11-10 11:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(941,11,11,11,'EXT-011','low','2026-11-10 11:00:00.000','2026-11-10 12:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(942,12,12,12,'EXT-012','low','2026-11-10 12:00:00.000','2026-11-10 13:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(943,13,13,13,'EXT-013','low','2026-11-10 13:00:00.000','2026-11-10 14:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(944,14,14,14,'EXT-014','low','2026-11-10 14:00:00.000','2026-11-10 15:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(945,15,15,15,'EXT-015','low','2026-11-10 15:00:00.000','2026-11-10 16:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(946,16,16,16,'EXT-016','low','2026-11-10 16:00:00.000','2026-11-10 17:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(947,17,17,17,'EXT-017','low','2026-11-10 17:00:00.000','2026-11-10 18:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(948,18,18,18,'EXT-018','low','2026-11-10 18:00:00.000','2026-11-10 19:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(949,19,19,19,'EXT-019','low','2026-11-10 19:00:00.000','2026-11-10 20:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(950,20,20,20,'EXT-020','low','2026-11-10 20:00:00.000','2026-11-10 21:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(951,1,1,1,'EXT-021','low','2026-11-11 01:00:00.000','2026-11-11 02:00:00.000','recovered',600,NULL,'2026-11-19 10:23:00.436','2026-11-19 10:23:00.436'),(952,8,8,1,'CONC-3b3aae06','low','2026-11-19 10:23:25.000',NULL,'processing',600,NULL,'2026-11-19 10:23:25.224','2026-11-19 10:23:25.224'),(969,14,NULL,905,'SCN-TEMP-70','high','2026-11-19 10:22:27.712',NULL,'open',600,NULL,'2026-11-19 10:23:27.713','2026-11-19 10:23:27.713'),(978,8,8,1,'CONC-47767911','low','2026-11-19 10:23:39.000',NULL,'processing',600,NULL,'2026-11-19 10:23:39.649','2026-11-19 10:23:39.649');
/*!40000 ALTER TABLE `device_alert` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_device_alert_ai_incident` AFTER INSERT ON `device_alert` FOR EACH ROW begin
  declare v_station bigint unsigned;
  declare v_operator bigint unsigned;
  declare v_incident bigint unsigned;
  declare v_severe int default 0;
  declare v_new bigint unsigned;

  select p.station_id, s.operator_id
    into v_station, v_operator
    from charging_pile p
    join station s on s.station_id = p.station_id
   where p.pile_id = new.pile_id;

  if v_station is not null then
    select incident_id into v_incident
      from incident
     where station_id = v_station
       and status in ('detected', 'declared', 'contained')
     order by incident_id
     limit 1;

    if v_incident is not null then
      insert ignore into incident_alert
        (incident_id, alert_id, linked_at, linked_by, is_root_cause)
      values
        (v_incident, new.alert_id, utc_timestamp(3), null, 0);
    elseif new.severity in ('critical', 'high') then
      select count(*) into v_severe
        from device_alert a
        join charging_pile p on p.pile_id = a.pile_id
       where p.station_id = v_station
         and a.status <> 'recovered'
         and a.severity in ('critical', 'high')
         and a.occurred_at >= new.occurred_at - interval 10 minute;

      if v_severe >= 2 then
        call sp_declare_incident(
          v_operator, v_station, 'hardware', 'P2',
          concat('自动聚合：场站 ', v_station, ' 10 分钟内 ', v_severe, ' 条严重告警'),
          null, new.alert_id, v_new);
      end if;
    end if;
  end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `device_command`
--

DROP TABLE IF EXISTS `device_command`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_command` (
  `command_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `pile_id` bigint unsigned NOT NULL COMMENT '目标桩',
  `gun_id` bigint unsigned NOT NULL COMMENT '目标枪',
  `order_id` bigint unsigned NOT NULL COMMENT '关联订单',
  `command_type` varchar(32) NOT NULL COMMENT '启停命令',
  `status` varchar(32) NOT NULL DEFAULT 'pending' COMMENT '命令状态',
  `attempt_count` int unsigned NOT NULL DEFAULT '0' COMMENT '发送次数',
  `sent_at` datetime(3) DEFAULT NULL COMMENT '发送时间',
  `acknowledged_at` datetime(3) DEFAULT NULL COMMENT '确认时间',
  `error_message` varchar(500) DEFAULT NULL COMMENT '失败说明',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`command_id`),
  UNIQUE KEY `uq_device_command_order_id_command_type` (`order_id`,`command_type`),
  KEY `fk_device_command_pile_id` (`pile_id`),
  KEY `fk_device_command_gun_id` (`gun_id`),
  CONSTRAINT `fk_device_command_gun_id` FOREIGN KEY (`gun_id`) REFERENCES `charging_gun` (`gun_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_device_command_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_device_command_pile_id` FOREIGN KEY (`pile_id`) REFERENCES `charging_pile` (`pile_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_device_command_1` CHECK ((`command_type` in (_utf8mb4'start',_utf8mb4'stop'))),
  CONSTRAINT `ck_device_command_2` CHECK ((`status` in (_utf8mb4'pending',_utf8mb4'sent',_utf8mb4'succeeded',_utf8mb4'failed')))
) ENGINE=InnoDB AUTO_INCREMENT=6021 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `device_command`
--

LOCK TABLES `device_command` WRITE;
/*!40000 ALTER TABLE `device_command` DISABLE KEYS */;
INSERT INTO `device_command` VALUES (1,1,1,1,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(2,2,2,2,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(3,3,3,3,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(4,4,4,4,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5,5,5,5,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6,6,6,6,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(7,7,7,7,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(8,8,8,8,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(9,9,9,9,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(10,10,10,10,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(11,11,11,11,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(12,12,12,12,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(13,13,13,13,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(14,14,14,14,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(15,15,15,15,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(16,16,16,16,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(17,17,17,17,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(18,18,18,18,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(19,19,19,19,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(20,20,20,20,'start','succeeded',1,'2026-10-20 02:00:00.000','2026-10-20 02:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(101,1,1,101,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(102,2,2,102,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(103,3,3,103,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(104,4,4,104,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(105,5,5,105,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(106,6,6,106,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(107,7,7,107,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(108,8,8,108,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(109,9,9,109,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(110,10,10,110,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(111,11,11,111,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(112,12,12,112,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(113,13,13,113,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(114,14,14,114,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(115,15,15,115,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(116,16,16,116,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(117,17,17,117,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(118,18,18,118,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(119,19,19,119,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(120,20,20,120,'start','succeeded',1,'2026-10-20 03:00:00.000','2026-10-20 03:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1001,1,1,1001,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1002,2,2,1002,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1003,3,3,1003,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1004,4,4,1004,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1005,5,5,1005,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1006,6,6,1006,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1007,7,7,1007,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1008,8,8,1008,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1009,9,9,1009,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1010,10,10,1010,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1011,11,11,1011,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1012,12,12,1012,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1013,13,13,1013,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1014,14,14,1014,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1015,15,15,1015,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1016,16,16,1016,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1017,17,17,1017,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1018,18,18,1018,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1019,19,19,1019,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(1020,20,20,1020,'start','succeeded',1,'2026-10-20 05:00:00.000','2026-10-20 05:00:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5001,1,1,1,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5002,2,2,2,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5003,3,3,3,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5004,4,4,4,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5005,5,5,5,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5006,6,6,6,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5007,7,7,7,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5008,8,8,8,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5009,9,9,9,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5010,10,10,10,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5011,11,11,11,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5012,12,12,12,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5013,13,13,13,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5014,14,14,14,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5015,15,15,15,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5016,16,16,16,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5017,17,17,17,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5018,18,18,18,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5019,19,19,19,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5020,20,20,20,'stop','succeeded',1,'2026-10-20 02:30:00.000','2026-10-20 02:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5101,1,1,101,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5102,2,2,102,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5103,3,3,103,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5104,4,4,104,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5105,5,5,105,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5106,6,6,106,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5107,7,7,107,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5108,8,8,108,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5109,9,9,109,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5110,10,10,110,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5111,11,11,111,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5112,12,12,112,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5113,13,13,113,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5114,14,14,114,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5115,15,15,115,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5116,16,16,116,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5117,17,17,117,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5118,18,18,118,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5119,19,19,119,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(5120,20,20,120,'stop','succeeded',1,'2026-10-20 03:30:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6001,1,1,1001,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6002,2,2,1002,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6003,3,3,1003,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6004,4,4,1004,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6005,5,5,1005,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6006,6,6,1006,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6007,7,7,1007,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6008,8,8,1008,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6009,9,9,1009,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6010,10,10,1010,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6011,11,11,1011,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6012,12,12,1012,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6013,13,13,1013,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6014,14,14,1014,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6015,15,15,1015,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6016,16,16,1016,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6017,17,17,1017,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6018,18,18,1018,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6019,19,19,1019,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962'),(6020,20,20,1020,'stop','succeeded',1,'2026-10-20 05:15:00.000','2026-10-20 05:15:00.000',NULL,'2026-11-19 10:22:52.962','2026-11-19 10:22:52.962');
/*!40000 ALTER TABLE `device_command` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `device_credential`
--

DROP TABLE IF EXISTS `device_credential`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_credential` (
  `credential_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `pile_id` bigint unsigned NOT NULL COMMENT '凭据绑定桩',
  `token_hash` binary(32) NOT NULL COMMENT '设备令牌摘要 不存原令牌',
  `expires_at` datetime(3) NOT NULL COMMENT '到期时间',
  `revoked_at` datetime(3) DEFAULT NULL COMMENT '撤销时间',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`credential_id`),
  UNIQUE KEY `uq_device_credential_token_hash` (`token_hash`),
  KEY `fk_device_credential_pile_id` (`pile_id`),
  CONSTRAINT `fk_device_credential_pile_id` FOREIGN KEY (`pile_id`) REFERENCES `charging_pile` (`pile_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=126 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `device_credential`
--

LOCK TABLES `device_credential` WRITE;
/*!40000 ALTER TABLE `device_credential` DISABLE KEYS */;
INSERT INTO `device_credential` VALUES (1,1,_binary 'i_\�9RtM}\��}\�\�}��˒V�ެM0W���^�','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(2,2,_binary '7_I\�.\�|\�(\�\�\�Q|\�v-̗\�g\�\���V','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(3,3,_binary 'G\�󺦔g�0$�0z��(\�Y�\�]o�\�q�Z�U','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(4,4,_binary '?9`��\�˖\�c�욥L\�*�[\�\�P.B\�#9','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(5,5,_binary 'B%\�wIWh\�@\�[�(n\�\�\�s\��4\�B\�\��\�[\Z','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(6,6,_binary '�e;��EBC\Z	��\Z�Ll=���%Fp\�|\�z�42','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(7,7,_binary ']\�)\r` XR��xJ�\0�z�w\�bN4Zj�\�ۍ','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(8,8,_binary 'u!��bf\�!i#��7z�ڲl�b\\I8�\�,��*�ͨ','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(9,9,_binary '\�.=���R��z��&\�OD\�T�#R\�\�|�B','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(10,10,_binary '\�\�A\Zh<j��1�d]��LTD�%�EB(\�(l��','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(11,11,_binary '�;;��\�+�\���\�4`�H�\Z��\"}�\�5-���s','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(12,12,_binary '��\�\�?>GG\�+�\�\�rBn�\�dzf\�\�o{H�g-\�','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(13,13,_binary '<D\r9<�te\�\�\�\r��|+{\�ԫ1��\�=*�̗*','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(14,14,_binary '̅\�`\�*�<t7Ѕ\��1\�	1\0\��pVe','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(15,15,_binary 'G��zCR0o\�Ix��-~D\�\\A[I�r\�\�X�4K`','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(16,16,_binary '\�B\�{F\�7\�\�%CdŗW&�|��a�\�76\�\\��8','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(17,17,_binary 'o,9͝�\���.׭��\�:u��bHA\�r\�<�HC�&','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(18,18,_binary '5���\��^\�5\�\�\\\�\�/#ƙ,�E,\�ֱ\�~�\�','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(19,19,_binary '\'\�\�?\�\�ƸB�+�\�	=�3�^�f��Gzz��','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(20,20,_binary '\�h2�n�\�\�\�{!�\�?\�&��Q�\0\�\�g:�','2027-01-31 16:00:00.000',NULL,'2026-11-19 10:22:52.949','2026-11-19 10:22:52.949'),(23,17,_binary '\�<��6�Q��o\�7�\�f�8.�7w�\�xN','2026-11-19 11:23:26.024',NULL,'2026-11-19 10:23:26.024','2026-11-19 10:23:26.024'),(31,10,_binary 'A\�u�Yԙ\�܄�IK�x�s�8\�fQ|�xJh','2026-11-19 11:23:26.656',NULL,'2026-11-19 10:23:26.656','2026-11-19 10:23:26.656'),(38,17,_binary '�/\�\�Fw�Đ���\�F7iy\�-cǄ=��~Zj2\�\�','2026-11-19 11:23:40.040',NULL,'2026-11-19 10:23:40.040','2026-11-19 10:23:40.040'),(46,10,_binary '\�\�v:w/)�\�M\�R\�\��M�\��T)�9�&','2026-11-19 11:23:40.660',NULL,'2026-11-19 10:23:40.661','2026-11-19 10:23:40.661'),(53,17,_binary '����k\�} ����\�<5�S@VB�91.�C�\�','2026-11-19 11:23:51.658',NULL,'2026-11-19 10:23:51.659','2026-11-19 10:23:51.659'),(61,10,_binary 'a ��-\�.\�\r�l�G�Lg\�-�*ʃr\�VV\�\�y','2026-11-19 11:23:52.350',NULL,'2026-11-19 10:23:52.350','2026-11-19 10:23:52.350'),(68,17,_binary ')�W+\�ܪ\�2�WT<�\�\�\��\�J�\�\�PF\��*.','2026-11-19 11:24:10.348',NULL,'2026-11-19 10:24:10.349','2026-11-19 10:24:10.349'),(76,10,_binary ')CMP\�n�Z\�;��U\�~\�\\Sj3Nu�*\�)�9�\�','2026-11-19 11:24:10.838',NULL,'2026-11-19 10:24:10.838','2026-11-19 10:24:10.838'),(83,17,_binary ';ި0�ܘ)��0Q\��L�\��\'�=\�\���&�z�G�','2026-11-19 11:24:30.656',NULL,'2026-11-19 10:24:30.657','2026-11-19 10:24:30.657'),(91,10,_binary 'rH�(@\�~fkG\"�\�\�\�I5��\�8Pu\�m�','2026-11-19 11:24:31.264',NULL,'2026-11-19 10:24:31.264','2026-11-19 10:24:31.264'),(98,17,_binary '{}�q�\�\�,J+�,�\�7^��\�=\�+=E\Z�)^�\�','2026-11-19 11:25:04.743',NULL,'2026-11-19 10:25:04.744','2026-11-19 10:25:04.744'),(106,10,_binary '�\�,�\�\�u�Wx_V\�d��5ꙓc\�Fztܓ�','2026-11-19 11:25:05.303',NULL,'2026-11-19 10:25:05.303','2026-11-19 10:25:05.303'),(113,17,_binary 'J�nA4��\���e�ɗ9Ǖ\Z�\�|9�\���\�','2026-11-19 11:25:10.868',NULL,'2026-11-19 10:25:10.869','2026-11-19 10:25:10.869'),(121,10,_binary '�&�Wf��oP\�\�F\�-rOR�I\�&��\�Yű\� ','2026-11-19 11:25:11.516',NULL,'2026-11-19 10:25:11.517','2026-11-19 10:25:11.517');
/*!40000 ALTER TABLE `device_credential` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `device_reading`
--

DROP TABLE IF EXISTS `device_reading`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_reading` (
  `sample_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `pile_id` bigint unsigned NOT NULL COMMENT '逻辑引用桩 不建物理FK',
  `sampled_at` datetime(3) NOT NULL COMMENT '设备采样UTC时间',
  `output_voltage_v` decimal(10,3) NOT NULL COMMENT '输出电压V',
  `output_current_a` decimal(10,3) NOT NULL COMMENT '输出电流A',
  `power_kw` decimal(10,3) NOT NULL COMMENT '功率kW',
  `module_temperature_c` decimal(6,2) NOT NULL COMMENT '模块温度摄氏度',
  `offline_seconds` int unsigned NOT NULL DEFAULT '0' COMMENT '上报的离线时长秒',
  `fault_code` varchar(32) NOT NULL DEFAULT 'NONE' COMMENT '故障码',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`sample_id`,`pile_id`,`sampled_at`),
  UNIQUE KEY `uq_device_reading_pile_sampled` (`pile_id`,`sampled_at`),
  KEY `ix_device_reading_pile_id_sampled_at` (`pile_id`,`sampled_at`)
) ENGINE=InnoDB AUTO_INCREMENT=343 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
/*!50500 PARTITION BY RANGE  COLUMNS(sampled_at)
SUBPARTITION BY HASH (`pile_id`)
SUBPARTITIONS 4
(PARTITION p_before_202611 VALUES LESS THAN ('2026-11-01') ENGINE = InnoDB,
 PARTITION p202611 VALUES LESS THAN ('2026-12-01') ENGINE = InnoDB,
 PARTITION p202612 VALUES LESS THAN ('2027-01-01') ENGINE = InnoDB,
 PARTITION p_future VALUES LESS THAN (MAXVALUE) ENGINE = InnoDB) */;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `device_reading`
--

LOCK TABLES `device_reading` WRITE;
/*!40000 ALTER TABLE `device_reading` DISABLE KEYS */;
INSERT INTO `device_reading` VALUES (4,4,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E004','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(8,8,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E008','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(12,12,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E012','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(16,16,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E016','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(20,20,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E020','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(104,4,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(108,8,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(112,12,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(116,16,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(120,20,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(204,4,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(208,8,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(212,12,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(216,16,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(220,20,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(1,1,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E001','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(5,5,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E005','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(9,9,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E009','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(13,13,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E013','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(17,17,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E017','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(101,1,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(105,5,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(109,9,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(113,13,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(117,17,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(201,1,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(205,5,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(209,9,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(213,13,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(217,17,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(2,2,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E002','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(6,6,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E006','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(14,14,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E014','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(18,18,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E018','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(102,2,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(106,6,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(114,14,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(118,18,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(202,2,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(206,6,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(214,14,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(218,18,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(3,3,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E003','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(7,7,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E007','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(11,11,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E011','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(15,15,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E015','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(19,19,'2026-10-20 04:00:00.000',400.000,0.000,0.000,62.00,0,'E019','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(103,3,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(107,7,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(111,11,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(115,15,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(119,19,'2026-10-20 04:34:00.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(203,3,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(207,7,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(211,11,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(215,15,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(219,19,'2026-10-20 04:35:00.000',400.000,0.000,0.000,37.00,0,'NONE','2026-11-19 10:22:52.935','2026-11-19 10:22:52.935'),(221,3,'2026-11-14 01:35:30.000',400.000,0.000,0.000,38.20,0,'NONE','2026-11-19 10:22:53.387','2026-11-19 10:22:53.387'),(222,3,'2026-11-14 01:36:00.000',400.000,0.000,0.000,38.10,0,'NONE','2026-11-19 10:22:53.387','2026-11-19 10:22:53.387'),(223,3,'2026-11-14 01:36:30.000',400.000,0.000,0.000,38.00,0,'NONE','2026-11-19 10:22:53.387','2026-11-19 10:22:53.387');
/*!40000 ALTER TABLE `device_reading` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_maintenance_reading_pile_exists` BEFORE INSERT ON `device_reading` FOR EACH ROW begin
  if not exists (select 1 from charging_pile where pile_id = new.pile_id) then
    signal sqlstate '45000' set message_text = 'pile not found';
  end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_device_reading_ai_alert` AFTER INSERT ON `device_reading` FOR EACH ROW begin
  declare v_rule_id bigint unsigned;
  declare v_code varchar(32);
  declare v_severity varchar(32);
  declare v_response int unsigned;

  
  if new.fault_code is not null and new.fault_code <> 'NONE' then
    set v_rule_id = null, v_code = null, v_severity = null, v_response = null;

    select alarm_rule_id,
           left(coalesce(fault_code, rule_code), 32),
           severity,
           response_seconds
      into v_rule_id, v_code, v_severity, v_response
      from alarm_rule
     where enabled = 1
       and metric = 'fault_code'
       and fault_code = new.fault_code
     limit 1;

    if v_rule_id is not null then
      insert ignore into device_alert
        (pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at,
         status, response_seconds_snapshot, normal_since_at)
      values
        (new.pile_id, null, v_rule_id, v_code, v_severity, new.sampled_at,
         'open', v_response, null);
    end if;
  end if;

  
  set v_rule_id = null, v_code = null, v_severity = null, v_response = null;

  select alarm_rule_id,
         left(rule_code, 32),
         severity,
         response_seconds
    into v_rule_id, v_code, v_severity, v_response
    from alarm_rule
   where enabled = 1
     and metric = 'temperature'
     and threshold_value is not null
     and new.module_temperature_c >= threshold_value
   order by case severity
              when 'critical' then 1
              when 'high'     then 2
              when 'medium'   then 3
              else 4
            end,
            threshold_value desc
   limit 1;

  if v_rule_id is not null then
    insert ignore into device_alert
      (pile_id, gun_id, alarm_rule_id, alert_code, severity, occurred_at,
       status, response_seconds_snapshot, normal_since_at)
    values
      (new.pile_id, null, v_rule_id, v_code, v_severity, new.sampled_at,
       'open', v_response, null);
  end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `device_status_log`
--

DROP TABLE IF EXISTS `device_status_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `device_status_log` (
  `status_log_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `pile_id` bigint unsigned DEFAULT NULL COMMENT '目标桩 与gun_id二选一',
  `gun_id` bigint unsigned DEFAULT NULL COMMENT '目标枪 与pile_id二选一',
  `old_status` varchar(32) DEFAULT NULL COMMENT '原状态 首条可空',
  `new_status` varchar(32) NOT NULL COMMENT '新状态',
  `occurred_at` datetime(3) NOT NULL COMMENT '变化时间',
  `reason` varchar(255) NOT NULL COMMENT '变更原因',
  `actor_account_id` bigint unsigned DEFAULT NULL COMMENT '系统任务为空',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`status_log_id`),
  KEY `ix_device_status_log_pile_id_occurred_at` (`pile_id`,`occurred_at`),
  KEY `ix_device_status_log_gun_id_occurred_at` (`gun_id`,`occurred_at`),
  KEY `fk_device_status_log_actor_account_id` (`actor_account_id`),
  CONSTRAINT `fk_device_status_log_actor_account_id` FOREIGN KEY (`actor_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_device_status_log_gun_id` FOREIGN KEY (`gun_id`) REFERENCES `charging_gun` (`gun_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_device_status_log_pile_id` FOREIGN KEY (`pile_id`) REFERENCES `charging_pile` (`pile_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_device_status_log_1` CHECK ((((`pile_id` is not null) + (`gun_id` is not null)) = 1)),
  CONSTRAINT `ck_device_status_log_2` CHECK ((`old_status` in (_utf8mb4'idle',_utf8mb4'occupied',_utf8mb4'fault',_utf8mb4'offline'))),
  CONSTRAINT `ck_device_status_log_3` CHECK ((`new_status` in (_utf8mb4'idle',_utf8mb4'occupied',_utf8mb4'fault',_utf8mb4'offline')))
) ENGINE=InnoDB AUTO_INCREMENT=170 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `device_status_log`
--

LOCK TABLES `device_status_log` WRITE;
/*!40000 ALTER TABLE `device_status_log` DISABLE KEYS */;
INSERT INTO `device_status_log` VALUES (1,NULL,1,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(2,NULL,2,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(3,NULL,3,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(4,NULL,4,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(5,NULL,5,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(6,NULL,6,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(7,NULL,7,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(8,NULL,8,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(9,NULL,9,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(10,NULL,10,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(11,NULL,11,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(12,NULL,12,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(13,NULL,13,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(14,NULL,14,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(15,NULL,15,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(16,NULL,16,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(17,NULL,17,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(18,NULL,18,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(19,NULL,19,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(20,NULL,20,'idle','fault','2026-10-20 04:00:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(101,NULL,1,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(102,NULL,2,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(103,NULL,3,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(104,NULL,4,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(105,NULL,5,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(106,NULL,6,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(107,NULL,7,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(108,NULL,8,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(109,NULL,9,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(110,NULL,10,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(111,NULL,11,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(112,NULL,12,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(113,NULL,13,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(114,NULL,14,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(115,NULL,15,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(116,NULL,16,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(117,NULL,17,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(118,NULL,18,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(119,NULL,19,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(120,NULL,20,'fault','idle','2026-10-20 04:35:00.000','历史故障演示',102,'2026-11-19 10:22:52.950','2026-11-19 10:22:52.950'),(121,903,NULL,'fault','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.156','2026-11-19 10:23:26.156'),(122,1,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.158','2026-11-19 10:23:26.158'),(123,2,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.160','2026-11-19 10:23:26.160'),(124,3,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.163','2026-11-19 10:23:26.163'),(125,4,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.167','2026-11-19 10:23:26.167'),(126,5,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.169','2026-11-19 10:23:26.169'),(127,6,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.172','2026-11-19 10:23:26.172'),(128,7,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.175','2026-11-19 10:23:26.175'),(129,8,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.179','2026-11-19 10:23:26.179'),(130,9,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.185','2026-11-19 10:23:26.185'),(131,10,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.188','2026-11-19 10:23:26.188'),(132,11,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.190','2026-11-19 10:23:26.190'),(133,12,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.193','2026-11-19 10:23:26.193'),(134,13,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.196','2026-11-19 10:23:26.196'),(135,14,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.200','2026-11-19 10:23:26.200'),(136,15,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.202','2026-11-19 10:23:26.202'),(137,17,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.206','2026-11-19 10:23:26.206'),(138,18,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.209','2026-11-19 10:23:26.209'),(139,19,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.212','2026-11-19 10:23:26.212'),(140,20,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.215','2026-11-19 10:23:26.215'),(141,16,NULL,'idle','offline','2026-11-19 10:23:26.146','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:26.219','2026-11-19 10:23:26.219'),(142,9,NULL,'offline','occupied','2026-11-19 10:23:27.045','heartbeat recovered',NULL,'2026-11-19 10:23:27.047','2026-11-19 10:23:27.047'),(143,901,NULL,'offline','fault','2026-11-19 10:23:27.404','critical alert E101',NULL,'2026-11-19 10:23:27.410','2026-11-19 10:23:27.410'),(146,16,NULL,'idle','offline','2026-11-19 10:23:40.152','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:40.163','2026-11-19 10:23:40.163'),(147,9,NULL,'offline','occupied','2026-11-19 10:23:41.014','heartbeat recovered',NULL,'2026-11-19 10:23:41.018','2026-11-19 10:23:41.018'),(150,16,NULL,'idle','offline','2026-11-19 10:23:51.772','heartbeat timeout > 180s',NULL,'2026-11-19 10:23:51.782','2026-11-19 10:23:51.782'),(151,9,NULL,'offline','occupied','2026-11-19 10:23:52.727','heartbeat recovered',NULL,'2026-11-19 10:23:52.729','2026-11-19 10:23:52.729'),(154,16,NULL,'idle','offline','2026-11-19 10:24:10.436','heartbeat timeout > 180s',NULL,'2026-11-19 10:24:10.443','2026-11-19 10:24:10.443'),(155,9,NULL,'offline','occupied','2026-11-19 10:24:11.147','heartbeat recovered',NULL,'2026-11-19 10:24:11.148','2026-11-19 10:24:11.148'),(158,16,NULL,'idle','offline','2026-11-19 10:24:30.774','heartbeat timeout > 180s',NULL,'2026-11-19 10:24:30.783','2026-11-19 10:24:30.783'),(159,9,NULL,'offline','occupied','2026-11-19 10:24:31.669','heartbeat recovered',NULL,'2026-11-19 10:24:31.670','2026-11-19 10:24:31.670'),(162,16,NULL,'idle','offline','2026-11-19 10:25:04.849','heartbeat timeout > 180s',NULL,'2026-11-19 10:25:04.860','2026-11-19 10:25:04.860'),(163,9,NULL,'offline','occupied','2026-11-19 10:25:05.715','heartbeat recovered',NULL,'2026-11-19 10:25:05.715','2026-11-19 10:25:05.715'),(166,16,NULL,'idle','offline','2026-11-19 10:25:10.971','heartbeat timeout > 180s',NULL,'2026-11-19 10:25:10.981','2026-11-19 10:25:10.981'),(167,9,NULL,'offline','occupied','2026-11-19 10:25:11.897','heartbeat recovered',NULL,'2026-11-19 10:25:11.897','2026-11-19 10:25:11.897');
/*!40000 ALTER TABLE `device_status_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `equipment_change_request`
--

DROP TABLE IF EXISTS `equipment_change_request`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `equipment_change_request` (
  `request_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `pile_id` bigint unsigned DEFAULT NULL COMMENT '桩目标',
  `gun_id` bigint unsigned DEFAULT NULL COMMENT '枪目标',
  `change_type` varchar(32) NOT NULL COMMENT '变更种类',
  `before_data` json NOT NULL COMMENT '原档案快照',
  `proposed_data` json NOT NULL COMMENT '允许字段的新值',
  `reason` varchar(500) NOT NULL COMMENT '申请理由',
  `requested_by` bigint unsigned NOT NULL COMMENT '申请账号',
  `status` varchar(32) NOT NULL DEFAULT 'pending' COMMENT '审批状态',
  `reviewed_by` bigint unsigned DEFAULT NULL COMMENT '审批人',
  `reviewed_at` datetime(3) DEFAULT NULL COMMENT '审批时间',
  `review_note` varchar(500) DEFAULT NULL COMMENT '审批意见',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`request_id`),
  KEY `fk_equipment_change_request_pile_id` (`pile_id`),
  KEY `fk_equipment_change_request_gun_id` (`gun_id`),
  KEY `fk_equipment_change_request_requested_by` (`requested_by`),
  KEY `fk_equipment_change_request_reviewed_by` (`reviewed_by`),
  CONSTRAINT `fk_equipment_change_request_gun_id` FOREIGN KEY (`gun_id`) REFERENCES `charging_gun` (`gun_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_equipment_change_request_pile_id` FOREIGN KEY (`pile_id`) REFERENCES `charging_pile` (`pile_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_equipment_change_request_requested_by` FOREIGN KEY (`requested_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_equipment_change_request_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_equipment_change_request_1` CHECK ((((`pile_id` is not null) + (`gun_id` is not null)) = 1)),
  CONSTRAINT `ck_equipment_change_request_2` CHECK ((`change_type` in (_utf8mb4'archive',_utf8mb4'relocate',_utf8mb4'retrofit',_utf8mb4'retire'))),
  CONSTRAINT `ck_equipment_change_request_3` CHECK ((`status` in (_utf8mb4'pending',_utf8mb4'approved',_utf8mb4'rejected')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `equipment_change_request`
--

LOCK TABLES `equipment_change_request` WRITE;
/*!40000 ALTER TABLE `equipment_change_request` DISABLE KEYS */;
INSERT INTO `equipment_change_request` VALUES (1,1,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(2,2,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(3,3,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(4,4,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(5,5,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(6,6,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(7,7,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(8,8,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(9,9,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(10,10,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(11,11,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(12,12,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(13,13,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(14,14,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(15,15,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(16,16,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(17,17,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(18,18,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(19,19,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951'),(20,20,NULL,'retrofit','{\"model_name\": \"DEMO-DC-120\"}','{\"model_name\": \"DEMO-DC-120B\"}','演示改造申请',102,'pending',NULL,NULL,NULL,'2026-11-19 10:22:52.951','2026-11-19 10:22:52.951');
/*!40000 ALTER TABLE `equipment_change_request` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `escalation_policy`
--

DROP TABLE IF EXISTS `escalation_policy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `escalation_policy` (
  `policy_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `policy_code` varchar(50) NOT NULL COMMENT '策略码',
  `applies_severity` varchar(8) NOT NULL DEFAULT 'ANY' COMMENT '适用级别',
  `min_duration_seconds` int unsigned NOT NULL DEFAULT '0' COMMENT '持续时长门槛',
  `min_impact_piles` int unsigned NOT NULL DEFAULT '0' COMMENT '影响桩数门槛',
  `notify_level` varchar(8) NOT NULL COMMENT '通知层级',
  `action_code` varchar(32) NOT NULL COMMENT '建议动作',
  `enabled` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '是否启用',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`policy_id`),
  UNIQUE KEY `uq_escalation_policy_code` (`policy_code`),
  CONSTRAINT `ck_escalation_policy_1` CHECK ((`applies_severity` in (_utf8mb4'P1',_utf8mb4'P2',_utf8mb4'P3',_utf8mb4'P4',_utf8mb4'ANY'))),
  CONSTRAINT `ck_escalation_policy_2` CHECK ((`notify_level` in (_utf8mb4'L1',_utf8mb4'L2',_utf8mb4'L3'))),
  CONSTRAINT `ck_escalation_policy_3` CHECK ((`action_code` in (_utf8mb4'notify_supervisor',_utf8mb4'notify_operator',_utf8mb4'dispatch_backup',_utf8mb4'suggest_isolate',_utf8mb4'pause_orders',_utf8mb4'declare_incident'))),
  CONSTRAINT `ck_escalation_policy_4` CHECK ((`enabled` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=921 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='升级策略矩阵';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `escalation_policy`
--

LOCK TABLES `escalation_policy` WRITE;
/*!40000 ALTER TABLE `escalation_policy` DISABLE KEYS */;
INSERT INTO `escalation_policy` VALUES (901,'ESC-P1-L3-IMM','P1',0,0,'L3','notify_supervisor',1,'2026-11-19 10:23:00.169','2026-11-19 10:23:00.169'),(902,'ESC-P1-L2-30M','P1',1800,0,'L2','notify_operator',1,'2026-11-19 10:23:00.169','2026-11-19 10:23:00.169'),(903,'ESC-P2-L3-5P','P2',0,5,'L3','notify_supervisor',1,'2026-11-19 10:23:00.169','2026-11-19 10:23:00.169'),(904,'ESC-P2-L2-60M','P2',3600,3,'L2','dispatch_backup',1,'2026-11-19 10:23:00.169','2026-11-19 10:23:00.169'),(905,'ESC-ANY-L1-24H','ANY',86400,0,'L1','notify_operator',1,'2026-11-19 10:23:00.169','2026-11-19 10:23:00.169'),(906,'ESC-EXT-001','P1',600,1,'L3','notify_supervisor',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(907,'ESC-EXT-002','P1',1200,2,'L2','notify_operator',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(908,'ESC-EXT-003','P2',1800,2,'L2','dispatch_backup',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(909,'ESC-EXT-004','P2',2400,3,'L3','suggest_isolate',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(910,'ESC-EXT-005','P3',3600,1,'L1','notify_operator',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(911,'ESC-EXT-006','P3',7200,2,'L2','dispatch_backup',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(912,'ESC-EXT-007','P4',10800,1,'L1','notify_operator',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(913,'ESC-EXT-008','P4',14400,2,'L2','notify_operator',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(914,'ESC-EXT-009','ANY',1800,4,'L3','declare_incident',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(915,'ESC-EXT-010','ANY',3600,5,'L3','suggest_isolate',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(916,'ESC-EXT-011','P1',300,3,'L3','pause_orders',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(917,'ESC-EXT-012','P2',900,2,'L2','pause_orders',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(918,'ESC-EXT-013','P3',5400,1,'L1','notify_operator',0,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(919,'ESC-EXT-014','ANY',7200,0,'L2','notify_operator',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527'),(920,'ESC-EXT-015','ANY',21600,0,'L3','notify_supervisor',1,'2026-11-19 10:23:00.527','2026-11-19 10:23:00.527');
/*!40000 ALTER TABLE `escalation_policy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fault_report`
--

DROP TABLE IF EXISTS `fault_report`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fault_report` (
  `report_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint unsigned NOT NULL COMMENT '报障用户',
  `gun_id` bigint unsigned NOT NULL COMMENT '目标枪',
  `order_id` bigint unsigned DEFAULT NULL COMMENT '相关订单',
  `description` varchar(1000) NOT NULL COMMENT '问题描述',
  `status` varchar(32) NOT NULL DEFAULT 'submitted' COMMENT '处理状态',
  `alert_id` bigint unsigned DEFAULT NULL COMMENT '核查后关联告警',
  `handled_by` bigint unsigned DEFAULT NULL COMMENT '处理账号',
  `handled_at` datetime(3) DEFAULT NULL COMMENT '处理时间',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`report_id`),
  KEY `fk_fault_report_user_id` (`user_id`),
  KEY `fk_fault_report_gun_id` (`gun_id`),
  KEY `fk_fault_report_order_id` (`order_id`),
  KEY `fk_fault_report_alert_id` (`alert_id`),
  KEY `fk_fault_report_handled_by` (`handled_by`),
  CONSTRAINT `fk_fault_report_alert_id` FOREIGN KEY (`alert_id`) REFERENCES `device_alert` (`alert_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fault_report_gun_id` FOREIGN KEY (`gun_id`) REFERENCES `charging_gun` (`gun_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fault_report_handled_by` FOREIGN KEY (`handled_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fault_report_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fault_report_user_id` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_fault_report_1` CHECK ((`status` in (_utf8mb4'submitted',_utf8mb4'linked',_utf8mb4'resolved')))
) ENGINE=InnoDB AUTO_INCREMENT=909 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fault_report`
--

LOCK TABLES `fault_report` WRITE;
/*!40000 ALTER TABLE `fault_report` DISABLE KEYS */;
INSERT INTO `fault_report` VALUES (1,1,1,NULL,'历史场站故障报障','resolved',1,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(2,2,2,NULL,'历史场站故障报障','resolved',2,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(3,3,3,NULL,'历史场站故障报障','resolved',3,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(4,4,4,NULL,'历史场站故障报障','resolved',4,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(5,5,5,NULL,'历史场站故障报障','resolved',5,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(6,6,6,NULL,'历史场站故障报障','resolved',6,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(7,7,7,NULL,'历史场站故障报障','resolved',7,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(8,8,8,NULL,'历史场站故障报障','resolved',8,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(9,9,9,NULL,'历史场站故障报障','resolved',9,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(10,10,10,NULL,'历史场站故障报障','resolved',10,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(11,11,11,NULL,'历史场站故障报障','resolved',11,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(12,12,12,NULL,'历史场站故障报障','resolved',12,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(13,13,13,NULL,'历史场站故障报障','resolved',13,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(14,14,14,NULL,'历史场站故障报障','resolved',14,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(15,15,15,NULL,'历史场站故障报障','resolved',15,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(16,16,16,NULL,'历史场站故障报障','resolved',16,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(17,17,17,NULL,'历史场站故障报障','resolved',17,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(18,18,18,NULL,'历史场站故障报障','resolved',18,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(19,19,19,NULL,'历史场站故障报障','resolved',19,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(20,20,20,NULL,'历史场站故障报障','resolved',20,103,'2026-10-20 04:35:00.000','2026-11-19 10:22:52.980','2026-11-19 10:22:52.980'),(901,1,3,NULL,'充电中途停止，屏幕提示设备故障','linked',903,103,'2026-11-14 01:10:00.000','2026-11-19 10:22:53.436','2026-11-19 10:22:53.436');
/*!40000 ALTER TABLE `fault_report` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fleet`
--

DROP TABLE IF EXISTS `fleet`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet` (
  `fleet_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `company_name` varchar(100) NOT NULL COMMENT '企业名称',
  `credit_code` varchar(18) NOT NULL COMMENT '统一信用代码',
  `contact_name` varchar(50) NOT NULL COMMENT '联系人',
  `contact_phone_cipher` varbinary(512) NOT NULL COMMENT '电话密文',
  `status` varchar(32) NOT NULL DEFAULT 'active' COMMENT '车队状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`fleet_id`),
  UNIQUE KEY `uq_fleet_credit_code` (`credit_code`),
  CONSTRAINT `ck_fleet_1` CHECK ((`status` in (_utf8mb4'active',_utf8mb4'disabled')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fleet`
--

LOCK TABLES `fleet` WRITE;
/*!40000 ALTER TABLE `fleet` DISABLE KEYS */;
INSERT INTO `fleet` VALUES (1,'演示车队01','DEMOFL000000000001','车队联系人1',_binary 'gAAAAABq9qid0_-W0o2n6Er6nCxLX8WodtQsD3bDaOFzBCbT80mUvCMKKPXQFSCIt6x_eUVJWHwZYJAmOrGbSFt8zVKeEOepQA==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(2,'演示车队02','DEMOFL000000000002','车队联系人2',_binary 'gAAAAABq9qidg1hVd0MqxZBmMBd1dDve4_2VuvSqvN9e7TIgS1sAcIdP0y-x6Ns0rg5bYWSyGgiFPrtgUv765EO4wg9-bfvhMw==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(3,'演示车队03','DEMOFL000000000003','车队联系人3',_binary 'gAAAAABq9qidZKmibHYJpLg6OdK7TttfLP6idvxyrHXuXJnHPI_Ne_SlS0AeELIvx1QNvKN0lXjHBTr94_IzpXBagrp50OlPhw==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(4,'演示车队04','DEMOFL000000000004','车队联系人4',_binary 'gAAAAABq9qidpL5lyGQB5vHsBrP5KgOQPWdqPrjgV_fHclyLQ--z05mbdByXHW9iUDtEl4BbsiQ4BApOv2wWRhG7o2iQI80xRA==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(5,'演示车队05','DEMOFL000000000005','车队联系人5',_binary 'gAAAAABq9qidFeGRqoxSySBjbdaXO_oo6NhjqrdIgpSBZAo6A-utsEjukFe2Q9etuANPq3P6JJmTMMtX-NUdMvzFtZNLIxyMYA==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(6,'演示车队06','DEMOFL000000000006','车队联系人6',_binary 'gAAAAABq9qidz8eC_v87tFGXARndcK2O8GNSrEWEi4LdqSa_XrCMQpDTUK_faaHib-Pn7rI-jo_RcwB1iqeUQvVYn2_KfBLmew==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(7,'演示车队07','DEMOFL000000000007','车队联系人7',_binary 'gAAAAABq9qidN8mBimV4DIL9kVcNE25awRvtF0ykcNtrbofrnjgwIEBIYhXqz3VuBeRhy211Wq-I_VfsERx2GczJ9yQ8c7277w==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(8,'演示车队08','DEMOFL000000000008','车队联系人8',_binary 'gAAAAABq9qid7ifSfrCAPOoLa9u92hVXFGGNWrmJfS7XLYQI8ddnMiX4EanIqJireEJ_5KLYbccvDU6U1VQdwIvafNW4Ppcy6g==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(9,'演示车队09','DEMOFL000000000009','车队联系人9',_binary 'gAAAAABq9qidMJvWNKkVzXlpk0wgjyWRFt-8WLsdhsak2iBrpUsbA6JD7cO4zdOqKuNZ2DxalSpbDx_s_6zG31EdKfoPjj1ogw==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(10,'演示车队10','DEMOFL000000000010','车队联系人10',_binary 'gAAAAABq9qidX2klO6TXzXpLAneEPqpQflxkR0gc6bCQIRxuPknNMViqfF_LUU0t6M2CsWye7KHYlRJ2OoCHcKZ31tzLgSOX4g==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(11,'演示车队11','DEMOFL000000000011','车队联系人11',_binary 'gAAAAABq9qid7DdmTHb7xpKfSfn28VEg47soKs1pTIHksBjqQ3hFuA_t6A3tQ33xUe3P22eDa1YONiAmd83kQdk3UVWwZEoELw==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(12,'演示车队12','DEMOFL000000000012','车队联系人12',_binary 'gAAAAABq9qidOTuO9kpwgRUUP6jLUNjN7MZtc3piK0C8wcazQn82ZXOd0-wlfSxmPjziwTpmZakyzrOMXXZAzYwB4cPWIUIK5w==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(13,'演示车队13','DEMOFL000000000013','车队联系人13',_binary 'gAAAAABq9qidWZWWSwISJYZiFhFXhPivhPnwWrsBWE6HNHmbTjtN74KqO0yPl9AzvYqNdc0Y3zaVVpzSyspBT1MPeJSWLf-mhA==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(14,'演示车队14','DEMOFL000000000014','车队联系人14',_binary 'gAAAAABq9qidlMoyRkGgUnoCK_EAcZUvfuTHuX47sXLECdKm7DiRpJBNIvjRTeK0Y56Qm33IVpJLPu_VFysehF3w5Bk6rQm7cQ==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(15,'演示车队15','DEMOFL000000000015','车队联系人15',_binary 'gAAAAABq9qidgurmVhaB1HytyQ1hvDSSyc6wHFKRcI9rKGlFx15XnAs0gImyKYDTmNbTxm2l5AIsfb-EkylUbhrRdq8X6l4KRA==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(16,'演示车队16','DEMOFL000000000016','车队联系人16',_binary 'gAAAAABq9qidk2cpSomar6AizvYmzWKipqdTu5ivZjnP5Hg9cJ9lioWaLJD6Cl3C16ppyNjHQGWJfvCQEGE6ZA4V4zNYzXVcDg==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(17,'演示车队17','DEMOFL000000000017','车队联系人17',_binary 'gAAAAABq9qid1aNgryh1v5aomsQv4nSpB5gQA95lVywdXW_iigciWPdLs5psy8wVN91HTpTx1FDoePib_OvA4SkjromlCAaAzw==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(18,'演示车队18','DEMOFL000000000018','车队联系人18',_binary 'gAAAAABq9qid9GlXFR_m9vyApz-8K0kByqCLGDVQ3Usi0zY0NLKdyBeSUgvM3Vq59TnNPR-NiyIg8gd96N5bHz7Xe_cILM4nWg==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(19,'演示车队19','DEMOFL000000000019','车队联系人19',_binary 'gAAAAABq9qid5ohpGaU6dFNuIsiyOEneinqKEgA1TSM5I744dV7VEPUjGZ2BYZv5h0vVPMQDhBQLXMfGiKzqGg3pjzglXh5qyQ==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886'),(20,'演示车队20','DEMOFL000000000020','车队联系人20',_binary 'gAAAAABq9qid1vyuxXHkTCI0jrfrwZmF066z-4ACd-2L9C5jzRp2Q4Rwrz6jGFYxAK71qCqCAJfv8jLrWxssWT-S249vgzAskQ==','active','2026-11-19 10:22:52.886','2026-11-19 10:22:52.886');
/*!40000 ALTER TABLE `fleet` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fleet_authorization`
--

DROP TABLE IF EXISTS `fleet_authorization`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet_authorization` (
  `authorization_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `card_id` bigint unsigned NOT NULL COMMENT '车队卡',
  `user_id` bigint unsigned NOT NULL COMMENT '用车人',
  `vehicle_id` bigint unsigned NOT NULL COMMENT '授权车辆',
  `default_monthly_limit` decimal(14,2) NOT NULL COMMENT '新月份默认额度',
  `valid_from` datetime(3) NOT NULL COMMENT '生效',
  `valid_until` datetime(3) NOT NULL COMMENT '失效',
  `status` varchar(32) NOT NULL DEFAULT 'active' COMMENT '授权状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`authorization_id`),
  KEY `fk_fleet_authorization_card_id` (`card_id`),
  KEY `fk_fleet_authorization_user_id` (`user_id`),
  KEY `fk_fleet_authorization_vehicle_id` (`vehicle_id`),
  CONSTRAINT `fk_fleet_authorization_card_id` FOREIGN KEY (`card_id`) REFERENCES `fleet_card` (`card_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_authorization_user_id` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_authorization_vehicle_id` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicle` (`vehicle_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_fleet_authorization_1` CHECK ((`default_monthly_limit` >= 0)),
  CONSTRAINT `ck_fleet_authorization_2` CHECK ((`valid_until` > `valid_from`)),
  CONSTRAINT `ck_fleet_authorization_3` CHECK ((`status` in (_utf8mb4'active',_utf8mb4'suspended',_utf8mb4'expired')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fleet_authorization`
--

LOCK TABLES `fleet_authorization` WRITE;
/*!40000 ALTER TABLE `fleet_authorization` DISABLE KEYS */;
INSERT INTO `fleet_authorization` VALUES (1,1,1,1,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(2,2,2,2,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(3,3,3,3,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(4,4,4,4,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(5,5,5,5,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(6,6,6,6,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(7,7,7,7,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(8,8,8,8,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(9,9,9,9,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(10,10,10,10,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(11,11,11,11,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(12,12,12,12,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(13,13,13,13,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(14,14,14,14,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(15,15,15,15,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(16,16,16,16,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(17,17,17,17,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(18,18,18,18,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(19,19,19,19,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920'),(20,20,20,20,300.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.920','2026-11-19 10:22:52.920');
/*!40000 ALTER TABLE `fleet_authorization` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fleet_bill_payment`
--

DROP TABLE IF EXISTS `fleet_bill_payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet_bill_payment` (
  `bill_payment_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `bill_id` bigint unsigned NOT NULL COMMENT '账单',
  `external_trade_no` varchar(80) NOT NULL COMMENT '企业模拟结算流水',
  `amount` decimal(14,2) NOT NULL COMMENT '实际企业收款 纯账单抵扣允许0',
  `status` varchar(32) NOT NULL DEFAULT 'pending' COMMENT '支付状态',
  `paid_at` datetime(3) DEFAULT NULL COMMENT '成功时间',
  `recorded_by` bigint unsigned NOT NULL COMMENT '办理账号',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`bill_payment_id`),
  UNIQUE KEY `uq_fleet_bill_payment_external_trade_no` (`external_trade_no`),
  KEY `fk_fleet_bill_payment_bill_id` (`bill_id`),
  KEY `fk_fleet_bill_payment_recorded_by` (`recorded_by`),
  CONSTRAINT `fk_fleet_bill_payment_bill_id` FOREIGN KEY (`bill_id`) REFERENCES `fleet_monthly_bill` (`bill_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_bill_payment_recorded_by` FOREIGN KEY (`recorded_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_fleet_bill_payment_1` CHECK ((`amount` >= 0)),
  CONSTRAINT `ck_fleet_bill_payment_2` CHECK ((`status` in (_utf8mb4'pending',_utf8mb4'succeeded',_utf8mb4'failed')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fleet_bill_payment`
--

LOCK TABLES `fleet_bill_payment` WRITE;
/*!40000 ALTER TABLE `fleet_bill_payment` DISABLE KEYS */;
INSERT INTO `fleet_bill_payment` VALUES (1,1,'FIX-FB-01',6.75,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(2,2,'FIX-FB-02',7.50,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(3,3,'FIX-FB-03',8.25,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(4,4,'FIX-FB-04',9.00,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(5,5,'FIX-FB-05',9.75,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(6,6,'FIX-FB-06',10.50,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(7,7,'FIX-FB-07',11.25,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(8,8,'FIX-FB-08',12.00,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(9,9,'FIX-FB-09',12.75,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(10,10,'FIX-FB-10',13.50,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(11,11,'FIX-FB-11',14.25,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(12,12,'FIX-FB-12',15.00,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(13,13,'FIX-FB-13',15.75,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(14,14,'FIX-FB-14',16.50,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(15,15,'FIX-FB-15',17.25,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(16,16,'FIX-FB-16',18.00,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(17,17,'FIX-FB-17',18.75,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(18,18,'FIX-FB-18',19.50,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(19,19,'FIX-FB-19',20.25,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929'),(20,20,'FIX-FB-20',21.00,'succeeded','2026-11-02 01:30:00.000',103,'2026-11-19 10:22:52.929','2026-11-19 10:22:52.929');
/*!40000 ALTER TABLE `fleet_bill_payment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fleet_card`
--

DROP TABLE IF EXISTS `fleet_card`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet_card` (
  `card_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `fleet_id` bigint unsigned NOT NULL COMMENT '所属车队',
  `card_no` varchar(64) NOT NULL COMMENT '卡号',
  `issued_at` datetime(3) NOT NULL COMMENT '发卡时间',
  `valid_from` datetime(3) NOT NULL COMMENT '生效',
  `valid_until` datetime(3) NOT NULL COMMENT '失效',
  `status` varchar(32) NOT NULL DEFAULT 'active' COMMENT '卡状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`card_id`),
  UNIQUE KEY `uq_fleet_card_card_no` (`card_no`),
  KEY `fk_fleet_card_fleet_id` (`fleet_id`),
  CONSTRAINT `fk_fleet_card_fleet_id` FOREIGN KEY (`fleet_id`) REFERENCES `fleet` (`fleet_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_fleet_card_1` CHECK ((`valid_until` > `valid_from`)),
  CONSTRAINT `ck_fleet_card_2` CHECK ((`status` in (_utf8mb4'active',_utf8mb4'suspended',_utf8mb4'expired')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fleet_card`
--

LOCK TABLES `fleet_card` WRITE;
/*!40000 ALTER TABLE `fleet_card` DISABLE KEYS */;
INSERT INTO `fleet_card` VALUES (1,1,'DEMO-CARD-01','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(2,2,'DEMO-CARD-02','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(3,3,'DEMO-CARD-03','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(4,4,'DEMO-CARD-04','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(5,5,'DEMO-CARD-05','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(6,6,'DEMO-CARD-06','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(7,7,'DEMO-CARD-07','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(8,8,'DEMO-CARD-08','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(9,9,'DEMO-CARD-09','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(10,10,'DEMO-CARD-10','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(11,11,'DEMO-CARD-11','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(12,12,'DEMO-CARD-12','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(13,13,'DEMO-CARD-13','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(14,14,'DEMO-CARD-14','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(15,15,'DEMO-CARD-15','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(16,16,'DEMO-CARD-16','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(17,17,'DEMO-CARD-17','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(18,18,'DEMO-CARD-18','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(19,19,'DEMO-CARD-19','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901'),(20,20,'DEMO-CARD-20','2026-09-30 16:00:00.000','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.901','2026-11-19 10:22:52.901');
/*!40000 ALTER TABLE `fleet_card` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fleet_monthly_bill`
--

DROP TABLE IF EXISTS `fleet_monthly_bill`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet_monthly_bill` (
  `bill_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `fleet_id` bigint unsigned NOT NULL COMMENT '所属车队',
  `bill_month` date NOT NULL COMMENT '账期首日',
  `order_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '原订单费用合计',
  `adjustment_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '退款等调整 可负',
  `payable_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '应付净额 可负余额结转',
  `paid_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '已确认企业结算收款',
  `status` varchar(32) NOT NULL DEFAULT 'draft' COMMENT '账单状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`bill_id`),
  UNIQUE KEY `uq_fleet_monthly_bill_fleet_id_bill_month` (`fleet_id`,`bill_month`),
  CONSTRAINT `fk_fleet_monthly_bill_fleet_id` FOREIGN KEY (`fleet_id`) REFERENCES `fleet` (`fleet_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_fleet_monthly_bill_1` CHECK ((dayofmonth(`bill_month`) = 1)),
  CONSTRAINT `ck_fleet_monthly_bill_2` CHECK ((`paid_amount` >= 0)),
  CONSTRAINT `ck_fleet_monthly_bill_3` CHECK ((`status` in (_utf8mb4'draft',_utf8mb4'issued',_utf8mb4'partially_paid',_utf8mb4'paid',_utf8mb4'closed')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fleet_monthly_bill`
--

LOCK TABLES `fleet_monthly_bill` WRITE;
/*!40000 ALTER TABLE `fleet_monthly_bill` DISABLE KEYS */;
INSERT INTO `fleet_monthly_bill` VALUES (1,1,'2026-10-01',6.75,0.00,6.75,6.75,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(2,2,'2026-10-01',7.50,0.00,7.50,7.50,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(3,3,'2026-10-01',8.25,0.00,8.25,8.25,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(4,4,'2026-10-01',9.00,0.00,9.00,9.00,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(5,5,'2026-10-01',9.75,0.00,9.75,9.75,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(6,6,'2026-10-01',10.50,0.00,10.50,10.50,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(7,7,'2026-10-01',11.25,0.00,11.25,11.25,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(8,8,'2026-10-01',12.00,0.00,12.00,12.00,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(9,9,'2026-10-01',12.75,0.00,12.75,12.75,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(10,10,'2026-10-01',13.50,0.00,13.50,13.50,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(11,11,'2026-10-01',14.25,0.00,14.25,14.25,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(12,12,'2026-10-01',15.00,0.00,15.00,15.00,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(13,13,'2026-10-01',15.75,0.00,15.75,15.75,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(14,14,'2026-10-01',16.50,0.00,16.50,16.50,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(15,15,'2026-10-01',17.25,0.00,17.25,17.25,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(16,16,'2026-10-01',18.00,0.00,18.00,18.00,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(17,17,'2026-10-01',18.75,0.00,18.75,18.75,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(18,18,'2026-10-01',19.50,0.00,19.50,19.50,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(19,19,'2026-10-01',20.25,0.00,20.25,20.25,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912'),(20,20,'2026-10-01',21.00,0.00,21.00,21.00,'paid','2026-11-19 10:22:52.912','2026-11-19 10:22:52.912');
/*!40000 ALTER TABLE `fleet_monthly_bill` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fleet_monthly_bill_item`
--

DROP TABLE IF EXISTS `fleet_monthly_bill_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet_monthly_bill_item` (
  `bill_item_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `bill_id` bigint unsigned NOT NULL COMMENT '月结单',
  `order_id` bigint unsigned NOT NULL COMMENT '原订单',
  `refund_id` bigint unsigned DEFAULT NULL COMMENT '退款来源',
  `item_type` varchar(32) NOT NULL COMMENT '订单 退款或负额结转',
  `occurred_at` datetime(3) NOT NULL COMMENT '条目发生时间',
  `amount` decimal(14,2) NOT NULL COMMENT '订单为正 退款为负',
  `original_order_finished_at` datetime(3) NOT NULL COMMENT '原订单结束快照',
  `business_key` varchar(100) NOT NULL COMMENT '来源唯一键',
  `source_bill_id` bigint unsigned DEFAULT NULL COMMENT 'credit_carry原账单；其他条目为空',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`bill_item_id`),
  UNIQUE KEY `uq_fleet_monthly_bill_item_business_key` (`business_key`),
  KEY `fk_fleet_monthly_bill_item_bill_id` (`bill_id`),
  KEY `fk_fleet_monthly_bill_item_order_id` (`order_id`),
  KEY `fk_fleet_monthly_bill_item_refund_id` (`refund_id`),
  KEY `fk_fleet_monthly_bill_item_source_bill_id` (`source_bill_id`),
  CONSTRAINT `fk_fleet_monthly_bill_item_bill_id` FOREIGN KEY (`bill_id`) REFERENCES `fleet_monthly_bill` (`bill_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_monthly_bill_item_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_monthly_bill_item_refund_id` FOREIGN KEY (`refund_id`) REFERENCES `refund_record` (`refund_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_monthly_bill_item_source_bill_id` FOREIGN KEY (`source_bill_id`) REFERENCES `fleet_monthly_bill` (`bill_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_fleet_monthly_bill_item_1` CHECK ((((`item_type` = _utf8mb4'refund') and (`refund_id` is not null)) or ((`item_type` <> _utf8mb4'refund') and (`refund_id` is null)))),
  CONSTRAINT `ck_fleet_monthly_bill_item_2` CHECK ((((`item_type` = _utf8mb4'credit_carry') and (`source_bill_id` is not null)) or ((`item_type` <> _utf8mb4'credit_carry') and (`source_bill_id` is null)))),
  CONSTRAINT `ck_fleet_monthly_bill_item_3` CHECK ((`item_type` in (_utf8mb4'order',_utf8mb4'refund',_utf8mb4'credit_carry',_utf8mb4'adjustment')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fleet_monthly_bill_item`
--

LOCK TABLES `fleet_monthly_bill_item` WRITE;
/*!40000 ALTER TABLE `fleet_monthly_bill_item` DISABLE KEYS */;
INSERT INTO `fleet_monthly_bill_item` VALUES (1,1,101,NULL,'order','2026-10-20 03:30:00.000',6.75,'2026-10-20 03:30:00.000','order:101',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(2,2,102,NULL,'order','2026-10-20 03:30:00.000',7.50,'2026-10-20 03:30:00.000','order:102',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(3,3,103,NULL,'order','2026-10-20 03:30:00.000',8.25,'2026-10-20 03:30:00.000','order:103',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(4,4,104,NULL,'order','2026-10-20 03:30:00.000',9.00,'2026-10-20 03:30:00.000','order:104',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(5,5,105,NULL,'order','2026-10-20 03:30:00.000',9.75,'2026-10-20 03:30:00.000','order:105',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(6,6,106,NULL,'order','2026-10-20 03:30:00.000',10.50,'2026-10-20 03:30:00.000','order:106',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(7,7,107,NULL,'order','2026-10-20 03:30:00.000',11.25,'2026-10-20 03:30:00.000','order:107',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(8,8,108,NULL,'order','2026-10-20 03:30:00.000',12.00,'2026-10-20 03:30:00.000','order:108',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(9,9,109,NULL,'order','2026-10-20 03:30:00.000',12.75,'2026-10-20 03:30:00.000','order:109',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(10,10,110,NULL,'order','2026-10-20 03:30:00.000',13.50,'2026-10-20 03:30:00.000','order:110',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(11,11,111,NULL,'order','2026-10-20 03:30:00.000',14.25,'2026-10-20 03:30:00.000','order:111',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(12,12,112,NULL,'order','2026-10-20 03:30:00.000',15.00,'2026-10-20 03:30:00.000','order:112',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(13,13,113,NULL,'order','2026-10-20 03:30:00.000',15.75,'2026-10-20 03:30:00.000','order:113',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(14,14,114,NULL,'order','2026-10-20 03:30:00.000',16.50,'2026-10-20 03:30:00.000','order:114',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(15,15,115,NULL,'order','2026-10-20 03:30:00.000',17.25,'2026-10-20 03:30:00.000','order:115',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(16,16,116,NULL,'order','2026-10-20 03:30:00.000',18.00,'2026-10-20 03:30:00.000','order:116',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(17,17,117,NULL,'order','2026-10-20 03:30:00.000',18.75,'2026-10-20 03:30:00.000','order:117',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(18,18,118,NULL,'order','2026-10-20 03:30:00.000',19.50,'2026-10-20 03:30:00.000','order:118',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(19,19,119,NULL,'order','2026-10-20 03:30:00.000',20.25,'2026-10-20 03:30:00.000','order:119',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011'),(20,20,120,NULL,'order','2026-10-20 03:30:00.000',21.00,'2026-10-20 03:30:00.000','order:120',NULL,'2026-11-19 10:22:53.011','2026-11-19 10:22:53.011');
/*!40000 ALTER TABLE `fleet_monthly_bill_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fleet_price`
--

DROP TABLE IF EXISTS `fleet_price`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet_price` (
  `price_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `fleet_id` bigint unsigned NOT NULL COMMENT '车队',
  `period_id` bigint unsigned NOT NULL COMMENT '时段 由此确定场站',
  `electricity_rate` decimal(12,4) NOT NULL COMMENT '专属电价',
  `service_rate` decimal(12,4) NOT NULL COMMENT '专属服务费单价',
  `valid_from` datetime(3) NOT NULL COMMENT '生效',
  `valid_until` datetime(3) NOT NULL COMMENT '失效',
  `status` varchar(32) NOT NULL DEFAULT 'draft' COMMENT '启用状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`price_id`),
  KEY `ix_fleet_price_fleet_id_period_id_valid_from` (`fleet_id`,`period_id`,`valid_from`),
  KEY `fk_fleet_price_period_id` (`period_id`),
  CONSTRAINT `fk_fleet_price_fleet_id` FOREIGN KEY (`fleet_id`) REFERENCES `fleet` (`fleet_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_price_period_id` FOREIGN KEY (`period_id`) REFERENCES `pricing_period` (`period_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_fleet_price_1` CHECK ((`valid_until` > `valid_from`)),
  CONSTRAINT `ck_fleet_price_2` CHECK ((`electricity_rate` >= 0)),
  CONSTRAINT `ck_fleet_price_3` CHECK ((`service_rate` >= 0)),
  CONSTRAINT `ck_fleet_price_4` CHECK ((`status` in (_utf8mb4'draft',_utf8mb4'active',_utf8mb4'disabled')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fleet_price`
--

LOCK TABLES `fleet_price` WRITE;
/*!40000 ALTER TABLE `fleet_price` DISABLE KEYS */;
INSERT INTO `fleet_price` VALUES (1,1,12,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(2,2,22,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(3,3,32,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(4,4,42,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(5,5,52,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(6,6,62,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(7,7,72,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(8,8,82,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(9,9,92,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(10,10,102,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(11,11,112,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(12,12,122,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(13,13,132,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(14,14,142,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(15,15,152,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(16,16,162,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(17,17,172,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(18,18,182,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(19,19,192,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960'),(20,20,202,0.5500,0.2000,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.960','2026-11-19 10:22:52.960');
/*!40000 ALTER TABLE `fleet_price` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fleet_quota_adjustment`
--

DROP TABLE IF EXISTS `fleet_quota_adjustment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet_quota_adjustment` (
  `quota_adjustment_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `quota_month_id` bigint unsigned NOT NULL COMMENT '被影响月份',
  `order_id` bigint unsigned DEFAULT NULL COMMENT '相关订单',
  `refund_id` bigint unsigned DEFAULT NULL COMMENT '退款来源',
  `change_type` varchar(32) NOT NULL COMMENT '变化类型',
  `amount` decimal(14,2) NOT NULL COMMENT '有符号调整',
  `business_key` varchar(100) NOT NULL COMMENT '业务唯一键',
  `reason` varchar(500) NOT NULL COMMENT '依据',
  `actor_account_id` bigint unsigned DEFAULT NULL COMMENT '系统任务为空',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`quota_adjustment_id`),
  UNIQUE KEY `uq_fleet_quota_adjustment_business_key` (`business_key`),
  KEY `fk_fleet_quota_adjustment_quota_month_id` (`quota_month_id`),
  KEY `fk_fleet_quota_adjustment_order_id` (`order_id`),
  KEY `fk_fleet_quota_adjustment_refund_id` (`refund_id`),
  KEY `fk_fleet_quota_adjustment_actor_account_id` (`actor_account_id`),
  CONSTRAINT `fk_fleet_quota_adjustment_actor_account_id` FOREIGN KEY (`actor_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_quota_adjustment_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_quota_adjustment_quota_month_id` FOREIGN KEY (`quota_month_id`) REFERENCES `fleet_quota_month` (`quota_month_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_quota_adjustment_refund_id` FOREIGN KEY (`refund_id`) REFERENCES `refund_record` (`refund_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_fleet_quota_adjustment_1` CHECK ((`change_type` in (_utf8mb4'limit_change',_utf8mb4'month_transfer',_utf8mb4'refund')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fleet_quota_adjustment`
--

LOCK TABLES `fleet_quota_adjustment` WRITE;
/*!40000 ALTER TABLE `fleet_quota_adjustment` DISABLE KEYS */;
INSERT INTO `fleet_quota_adjustment` VALUES (1,1,NULL,NULL,'limit_change',50.00,'quota-limit-1','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(2,2,NULL,NULL,'limit_change',50.00,'quota-limit-2','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(3,3,NULL,NULL,'limit_change',50.00,'quota-limit-3','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(4,4,NULL,NULL,'limit_change',50.00,'quota-limit-4','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(5,5,NULL,NULL,'limit_change',50.00,'quota-limit-5','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(6,6,NULL,NULL,'limit_change',50.00,'quota-limit-6','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(7,7,NULL,NULL,'limit_change',50.00,'quota-limit-7','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(8,8,NULL,NULL,'limit_change',50.00,'quota-limit-8','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(9,9,NULL,NULL,'limit_change',50.00,'quota-limit-9','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(10,10,NULL,NULL,'limit_change',50.00,'quota-limit-10','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(11,11,NULL,NULL,'limit_change',50.00,'quota-limit-11','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(12,12,NULL,NULL,'limit_change',50.00,'quota-limit-12','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(13,13,NULL,NULL,'limit_change',50.00,'quota-limit-13','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(14,14,NULL,NULL,'limit_change',50.00,'quota-limit-14','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(15,15,NULL,NULL,'limit_change',50.00,'quota-limit-15','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(16,16,NULL,NULL,'limit_change',50.00,'quota-limit-16','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(17,17,NULL,NULL,'limit_change',50.00,'quota-limit-17','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(18,18,NULL,NULL,'limit_change',50.00,'quota-limit-18','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(19,19,NULL,NULL,'limit_change',50.00,'quota-limit-19','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008'),(20,20,NULL,NULL,'limit_change',50.00,'quota-limit-20','月额度由250元调整至300元',105,'2026-11-19 10:22:53.008','2026-11-19 10:22:53.008');
/*!40000 ALTER TABLE `fleet_quota_adjustment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fleet_quota_month`
--

DROP TABLE IF EXISTS `fleet_quota_month`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet_quota_month` (
  `quota_month_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `authorization_id` bigint unsigned NOT NULL COMMENT '授权',
  `bill_month` date NOT NULL COMMENT '上海月份首日',
  `limit_amount` decimal(14,2) NOT NULL COMMENT '月额度',
  `reserved_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '未结算预占总额',
  `used_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '已结算净使用额',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`quota_month_id`),
  UNIQUE KEY `uq_fleet_quota_month_authorization_id_bill_month` (`authorization_id`,`bill_month`),
  CONSTRAINT `fk_fleet_quota_month_authorization_id` FOREIGN KEY (`authorization_id`) REFERENCES `fleet_authorization` (`authorization_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_fleet_quota_month_1` CHECK ((dayofmonth(`bill_month`) = 1)),
  CONSTRAINT `ck_fleet_quota_month_2` CHECK ((`limit_amount` >= 0)),
  CONSTRAINT `ck_fleet_quota_month_3` CHECK ((`reserved_amount` >= 0)),
  CONSTRAINT `ck_fleet_quota_month_4` CHECK ((`used_amount` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fleet_quota_month`
--

LOCK TABLES `fleet_quota_month` WRITE;
/*!40000 ALTER TABLE `fleet_quota_month` DISABLE KEYS */;
INSERT INTO `fleet_quota_month` VALUES (1,1,'2026-10-01',300.00,0.00,6.75,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(2,2,'2026-10-01',300.00,0.00,7.50,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(3,3,'2026-10-01',300.00,0.00,8.25,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(4,4,'2026-10-01',300.00,0.00,9.00,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(5,5,'2026-10-01',300.00,0.00,9.75,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(6,6,'2026-10-01',300.00,0.00,10.50,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(7,7,'2026-10-01',300.00,0.00,11.25,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(8,8,'2026-10-01',300.00,0.00,12.00,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(9,9,'2026-10-01',300.00,0.00,12.75,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(10,10,'2026-10-01',300.00,0.00,13.50,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(11,11,'2026-10-01',300.00,0.00,14.25,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(12,12,'2026-10-01',300.00,0.00,15.00,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(13,13,'2026-10-01',300.00,0.00,15.75,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(14,14,'2026-10-01',300.00,0.00,16.50,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(15,15,'2026-10-01',300.00,0.00,17.25,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(16,16,'2026-10-01',300.00,0.00,18.00,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(17,17,'2026-10-01',300.00,0.00,18.75,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(18,18,'2026-10-01',300.00,0.00,19.50,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(19,19,'2026-10-01',300.00,0.00,20.25,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946'),(20,20,'2026-10-01',300.00,0.00,21.00,'2026-11-19 10:22:52.946','2026-11-19 10:22:52.946');
/*!40000 ALTER TABLE `fleet_quota_month` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fleet_quota_reservation`
--

DROP TABLE IF EXISTS `fleet_quota_reservation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet_quota_reservation` (
  `reservation_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` bigint unsigned NOT NULL COMMENT '订单唯一',
  `quota_month_id` bigint unsigned NOT NULL COMMENT '当前归属月额度',
  `reserved_amount` decimal(14,2) NOT NULL COMMENT '本单原预占金额',
  `actual_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '最终实际扣额',
  `status` varchar(32) NOT NULL DEFAULT 'reserved' COMMENT '占用状态',
  `reserved_at` datetime(3) NOT NULL COMMENT '预占时间',
  `settled_at` datetime(3) DEFAULT NULL COMMENT '结算时间',
  `released_at` datetime(3) DEFAULT NULL COMMENT '释放时间',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`reservation_id`),
  UNIQUE KEY `uq_fleet_quota_reservation_order_id` (`order_id`),
  KEY `fk_fleet_quota_reservation_quota_month_id` (`quota_month_id`),
  CONSTRAINT `fk_fleet_quota_reservation_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_fleet_quota_reservation_quota_month_id` FOREIGN KEY (`quota_month_id`) REFERENCES `fleet_quota_month` (`quota_month_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_fleet_quota_reservation_1` CHECK ((`reserved_amount` > 0)),
  CONSTRAINT `ck_fleet_quota_reservation_2` CHECK ((`actual_amount` >= 0)),
  CONSTRAINT `ck_fleet_quota_reservation_3` CHECK ((`status` in (_utf8mb4'reserved',_utf8mb4'settled',_utf8mb4'released',_utf8mb4'review_required')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fleet_quota_reservation`
--

LOCK TABLES `fleet_quota_reservation` WRITE;
/*!40000 ALTER TABLE `fleet_quota_reservation` DISABLE KEYS */;
INSERT INTO `fleet_quota_reservation` VALUES (1,101,1,50.00,6.75,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(2,102,2,50.00,7.50,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(3,103,3,50.00,8.25,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(4,104,4,50.00,9.00,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(5,105,5,50.00,9.75,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(6,106,6,50.00,10.50,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(7,107,7,50.00,11.25,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(8,108,8,50.00,12.00,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(9,109,9,50.00,12.75,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(10,110,10,50.00,13.50,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(11,111,11,50.00,14.25,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(12,112,12,50.00,15.00,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(13,113,13,50.00,15.75,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(14,114,14,50.00,16.50,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(15,115,15,50.00,17.25,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(16,116,16,50.00,18.00,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(17,117,17,50.00,18.75,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(18,118,18,50.00,19.50,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(19,119,19,50.00,20.25,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983'),(20,120,20,50.00,21.00,'settled','2026-10-20 03:00:00.000','2026-10-20 03:30:00.000',NULL,'2026-11-19 10:22:52.983','2026-11-19 10:22:52.983');
/*!40000 ALTER TABLE `fleet_quota_reservation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `incident`
--

DROP TABLE IF EXISTS `incident`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `incident` (
  `incident_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `incident_no` varchar(32) NOT NULL COMMENT '事件编号 INC-YYYYMMDD-NNNN',
  `operator_id` bigint unsigned NOT NULL COMMENT '所属运营商',
  `station_id` bigint unsigned DEFAULT NULL COMMENT '场站级事件；跨场站事件留空',
  `category` varchar(32) NOT NULL COMMENT '根因类别',
  `severity` varchar(8) NOT NULL COMMENT '事件级别 P1-P4',
  `title` varchar(200) NOT NULL COMMENT '事件标题',
  `status` varchar(32) NOT NULL DEFAULT 'detected' COMMENT '事件状态',
  `detected_at` datetime(3) NOT NULL COMMENT '最早发现时间',
  `declared_at` datetime(3) DEFAULT NULL COMMENT '宣布事件时间',
  `contained_at` datetime(3) DEFAULT NULL COMMENT '影响受控时间',
  `restored_at` datetime(3) DEFAULT NULL COMMENT '业务恢复时间',
  `closed_at` datetime(3) DEFAULT NULL COMMENT '事件关闭时间',
  `commander_account_id` bigint unsigned DEFAULT NULL COMMENT '现场指挥账号',
  `impact_pile_count` int unsigned NOT NULL DEFAULT '0' COMMENT '影响桩数快照',
  `impact_order_count` int unsigned NOT NULL DEFAULT '0' COMMENT '影响订单数快照',
  `estimated_loss_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '预估损失金额',
  `escalation_level` int unsigned NOT NULL DEFAULT '0' COMMENT '已达到的最高通知层级 L1=1 L2=2 L3=3',
  `summary` varchar(1000) DEFAULT NULL COMMENT '事件概述/关闭说明',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  `active_key` varchar(96) GENERATED ALWAYS AS ((case when (`status` in (_utf8mb4'detected',_utf8mb4'declared',_utf8mb4'contained')) then concat(`operator_id`,_utf8mb4':',coalesce(`station_id`,0),_utf8mb4':',`category`) else NULL end)) STORED COMMENT '进行中事件唯一键：同运营商同场站同类别不并行两个事件',
  PRIMARY KEY (`incident_id`),
  UNIQUE KEY `uq_incident_no` (`incident_no`),
  UNIQUE KEY `uq_incident_active_key` (`active_key`),
  KEY `ix_incident_status_severity_detected` (`status`,`severity`,`detected_at`),
  KEY `ix_incident_station_detected` (`station_id`,`detected_at`),
  KEY `ix_incident_operator_detected` (`operator_id`,`detected_at`),
  KEY `fk_incident_commander` (`commander_account_id`),
  CONSTRAINT `fk_incident_commander` FOREIGN KEY (`commander_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_incident_operator_id` FOREIGN KEY (`operator_id`) REFERENCES `operator` (`operator_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_incident_station_id` FOREIGN KEY (`station_id`) REFERENCES `station` (`station_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_incident_1` CHECK ((`severity` in (_utf8mb4'P1',_utf8mb4'P2',_utf8mb4'P3',_utf8mb4'P4'))),
  CONSTRAINT `ck_incident_2` CHECK ((`category` in (_utf8mb4'power',_utf8mb4'communication',_utf8mb4'hardware',_utf8mb4'software',_utf8mb4'security',_utf8mb4'other'))),
  CONSTRAINT `ck_incident_3` CHECK ((`status` in (_utf8mb4'detected',_utf8mb4'declared',_utf8mb4'contained',_utf8mb4'restored',_utf8mb4'reviewed',_utf8mb4'closed',_utf8mb4'cancelled'))),
  CONSTRAINT `ck_incident_4` CHECK (((`declared_at` is null) or (`declared_at` >= `detected_at`))),
  CONSTRAINT `ck_incident_5` CHECK (((`contained_at` is null) or (`declared_at` is null) or (`contained_at` >= `declared_at`))),
  CONSTRAINT `ck_incident_6` CHECK (((`restored_at` is null) or (`contained_at` is null) or (`restored_at` >= `contained_at`))),
  CONSTRAINT `ck_incident_7` CHECK (((`closed_at` is null) or (`restored_at` is null) or (`closed_at` >= `restored_at`)))
) ENGINE=InnoDB AUTO_INCREMENT=942 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='应急事件';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `incident`
--

LOCK TABLES `incident` WRITE;
/*!40000 ALTER TABLE `incident` DISABLE KEYS */;
INSERT INTO `incident` (`incident_id`, `incident_no`, `operator_id`, `station_id`, `category`, `severity`, `title`, `status`, `detected_at`, `declared_at`, `contained_at`, `restored_at`, `closed_at`, `commander_account_id`, `impact_pile_count`, `impact_order_count`, `estimated_loss_amount`, `escalation_level`, `summary`, `created_at`, `updated_at`) VALUES (901,'INC-20261113-0001',3,901,'power','P1','应急园区市电中断导致 3 桩离线','contained','2026-11-13 12:00:00.000','2026-11-13 12:05:00.000','2026-11-13 12:30:00.000',NULL,NULL,101,3,12,1860.00,3,'已隔离场站并暂停接单，等待市电恢复','2026-11-19 10:23:00.134','2026-11-19 10:23:00.134'),(902,'INC-20261113-0002',6,6,'hardware','P2','6 号场站充电模块过温批量告警','restored','2026-11-13 02:00:00.000','2026-11-13 02:10:00.000','2026-11-13 03:00:00.000','2026-11-13 03:30:00.000',NULL,101,1,4,420.00,2,'更换散热风扇后恢复','2026-11-19 10:23:00.134','2026-11-19 10:23:00.134'),(921,'INC-20261110-0921',1,1,'power','P1','演练：1 号场站市电切换异常','closed','2026-11-10 01:00:00.000','2026-11-10 02:00:00.000','2026-11-10 03:00:00.000','2026-11-10 04:00:00.000','2026-11-10 05:00:00.000',101,2,5,125.00,3,'市电恢复后复测通过','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(922,'INC-20261110-0922',2,2,'communication','P2','演练：2 号场站通信中断','closed','2026-11-10 02:00:00.000','2026-11-10 03:00:00.000','2026-11-10 04:00:00.000','2026-11-10 05:00:00.000','2026-11-10 06:00:00.000',101,3,8,150.00,2,'更换通信模块后恢复','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(923,'INC-20261110-0923',3,3,'hardware','P3','演练：3 号场站充电模块故障','closed','2026-11-10 03:00:00.000','2026-11-10 04:00:00.000','2026-11-10 05:00:00.000','2026-11-10 06:00:00.000','2026-11-10 07:00:00.000',102,1,2,175.00,1,'备件更换完成','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(924,'INC-20261110-0924',4,4,'software','P3','演练：4 号场站协议栈异常','closed','2026-11-10 04:00:00.000','2026-11-10 05:00:00.000','2026-11-10 06:00:00.000','2026-11-10 07:00:00.000','2026-11-10 08:00:00.000',102,2,11,200.00,2,'重启服务并回滚配置','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(925,'INC-20261110-0925',5,5,'security','P2','演练：5 号场站设备证书过期','closed','2026-11-10 05:00:00.000','2026-11-10 06:00:00.000','2026-11-10 07:00:00.000','2026-11-10 08:00:00.000','2026-11-10 09:00:00.000',101,4,14,225.00,3,'批量续签证书后恢复','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(926,'INC-20261110-0926',6,6,'other','P4','演练：6 号场站第三方停电通知','closed','2026-11-10 06:00:00.000','2026-11-10 07:00:00.000','2026-11-10 08:00:00.000','2026-11-10 09:00:00.000','2026-11-10 10:00:00.000',101,1,3,250.00,1,'外部停电结束','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(927,'INC-20261110-0927',7,7,'power','P1','演练：7 号场站配电柜跳闸','closed','2026-11-10 07:00:00.000','2026-11-10 08:00:00.000','2026-11-10 09:00:00.000','2026-11-10 10:00:00.000','2026-11-10 11:00:00.000',101,3,17,275.00,3,'合闸后逐桩复测','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(928,'INC-20261110-0928',8,8,'communication','P2','演练：8 号场站 4G 信号弱','closed','2026-11-10 08:00:00.000','2026-11-10 09:00:00.000','2026-11-10 10:00:00.000','2026-11-10 11:00:00.000','2026-11-10 12:00:00.000',102,2,6,300.00,2,'加装信号放大器','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(929,'INC-20261110-0929',9,9,'hardware','P3','演练：9 号场站枪线损坏','closed','2026-11-10 09:00:00.000','2026-11-10 10:00:00.000','2026-11-10 11:00:00.000','2026-11-10 12:00:00.000','2026-11-10 13:00:00.000',102,1,4,325.00,1,'更换枪线','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(930,'INC-20261110-0930',10,10,'software','P3','演练：10 号场站计费上报失败','closed','2026-11-10 10:00:00.000','2026-11-10 11:00:00.000','2026-11-10 12:00:00.000','2026-11-10 13:00:00.000','2026-11-10 14:00:00.000',101,5,20,350.00,2,'补传数据并核对账目','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(931,'INC-20261110-0931',11,11,'security','P2','演练：11 号场站异常登录告警','closed','2026-11-10 11:00:00.000','2026-11-10 12:00:00.000','2026-11-10 13:00:00.000','2026-11-10 14:00:00.000','2026-11-10 15:00:00.000',101,2,9,375.00,3,'封禁来源并重置口令','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(932,'INC-20261110-0932',12,12,'other','P4','演练：12 号场站地锁故障','closed','2026-11-10 12:00:00.000','2026-11-10 13:00:00.000','2026-11-10 14:00:00.000','2026-11-10 15:00:00.000','2026-11-10 16:00:00.000',102,1,1,400.00,1,'手动复位地锁','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(933,'INC-20261110-0933',13,13,'power','P1','演练：13 号场站零线异常','closed','2026-11-10 13:00:00.000','2026-11-10 14:00:00.000','2026-11-10 15:00:00.000','2026-11-10 16:00:00.000','2026-11-10 17:00:00.000',101,3,12,425.00,3,'电工抢修后复测','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(934,'INC-20261110-0934',14,14,'communication','P2','演练：14 号场站平台心跳丢失','closed','2026-11-10 14:00:00.000','2026-11-10 15:00:00.000','2026-11-10 16:00:00.000','2026-11-10 17:00:00.000','2026-11-10 18:00:00.000',101,4,15,450.00,2,'恢复网关后心跳正常','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(935,'INC-20261110-0935',15,15,'hardware','P3','演练：15 号场站风扇异响','closed','2026-11-10 15:00:00.000','2026-11-10 16:00:00.000','2026-11-10 17:00:00.000','2026-11-10 18:00:00.000','2026-11-10 19:00:00.000',102,1,5,475.00,1,'更换风扇','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(936,'INC-20261110-0936',16,16,'software','P3','演练：16 号场站时间同步偏差','closed','2026-11-10 16:00:00.000','2026-11-10 17:00:00.000','2026-11-10 18:00:00.000','2026-11-10 19:00:00.000','2026-11-10 20:00:00.000',102,2,7,500.00,2,'重新配置 NTP','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(937,'INC-20261110-0937',17,17,'security','P2','演练：17 号场站固件版本过旧','closed','2026-11-10 17:00:00.000','2026-11-10 18:00:00.000','2026-11-10 19:00:00.000','2026-11-10 20:00:00.000','2026-11-10 21:00:00.000',101,3,10,525.00,3,'批量升级固件','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(938,'INC-20261110-0938',18,18,'other','P4','演练：18 号场站标识牌脱落','closed','2026-11-10 18:00:00.000','2026-11-10 19:00:00.000','2026-11-10 20:00:00.000','2026-11-10 21:00:00.000','2026-11-10 22:00:00.000',102,1,2,550.00,1,'重新固定标识牌','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(939,'INC-20261110-0939',19,19,'power','P1','演练：19 号场站浪涌保护动作','closed','2026-11-10 19:00:00.000','2026-11-10 20:00:00.000','2026-11-10 21:00:00.000','2026-11-10 22:00:00.000','2026-11-10 23:00:00.000',101,5,18,575.00,3,'更换浪涌模块','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(940,'INC-20261110-0940',20,20,'communication','P2','演练：20 号场站交换机端口故障','closed','2026-11-10 20:00:00.000','2026-11-10 21:00:00.000','2026-11-10 22:00:00.000','2026-11-10 23:00:00.000','2026-11-11 00:00:00.000',101,2,13,600.00,2,'更换端口后恢复','2026-11-19 10:23:00.468','2026-11-19 10:23:00.468'),(941,'INC-20261119-0001',14,14,'hardware','P2','自动聚合：场站 14 10 分钟内 2 条严重告警','declared','2026-11-19 10:23:27.712','2026-11-19 10:23:27.733',NULL,NULL,NULL,NULL,1,0,0.00,0,NULL,'2026-11-19 10:23:27.733','2026-11-19 10:23:27.733');
/*!40000 ALTER TABLE `incident` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_incident_bu_state_guard` BEFORE UPDATE ON `incident` FOR EACH ROW begin
  if new.status <> old.status then
    if not (
         (old.status = 'detected'  and new.status = 'declared')
      or (old.status = 'detected'  and new.status = 'cancelled')
      or (old.status = 'declared'  and new.status = 'contained')
      or (old.status = 'declared'  and new.status = 'cancelled')
      or (old.status = 'contained' and new.status = 'restored')
      or (old.status = 'restored'  and new.status = 'reviewed')
      or (old.status = 'restored'  and new.status = 'closed')
      or (old.status = 'reviewed'  and new.status = 'closed')
    ) then
      signal sqlstate '45000'
        set message_text = '非法的事件状态迁移：detected→declared→contained→restored→reviewed→closed，或前两阶段→cancelled';
    end if;
  end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `incident_action`
--

DROP TABLE IF EXISTS `incident_action`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `incident_action` (
  `action_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `incident_id` bigint unsigned NOT NULL COMMENT '事件',
  `action_type` varchar(32) NOT NULL COMMENT '动作类型',
  `target_type` varchar(16) NOT NULL DEFAULT 'none' COMMENT '动作对象类型',
  `target_id` bigint unsigned DEFAULT NULL COMMENT '动作对象编号；多态引用不建外键',
  `action_at` datetime(3) NOT NULL COMMENT '动作时间',
  `actor_account_id` bigint unsigned DEFAULT NULL COMMENT '执行账号；系统为空',
  `approved_by` bigint unsigned DEFAULT NULL COMMENT '审批账号；高危动作必填',
  `reason` varchar(500) DEFAULT NULL COMMENT '动作依据',
  `result` varchar(500) DEFAULT NULL COMMENT '执行结果',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`action_id`),
  KEY `ix_incident_action_incident_at` (`incident_id`,`action_at`),
  KEY `fk_incident_action_actor` (`actor_account_id`),
  KEY `fk_incident_action_approver` (`approved_by`),
  CONSTRAINT `fk_incident_action_actor` FOREIGN KEY (`actor_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_incident_action_approver` FOREIGN KEY (`approved_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_incident_action_incident` FOREIGN KEY (`incident_id`) REFERENCES `incident` (`incident_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_incident_action_1` CHECK ((`action_type` in (_utf8mb4'declare',_utf8mb4'link_alert',_utf8mb4'notify',_utf8mb4'dispatch',_utf8mb4'isolate_station',_utf8mb4'isolate_pile',_utf8mb4'switch_gun',_utf8mb4'pause_orders',_utf8mb4'resume_orders',_utf8mb4'restore',_utf8mb4'review',_utf8mb4'close',_utf8mb4'cancel',_utf8mb4'escalate'))),
  CONSTRAINT `ck_incident_action_2` CHECK ((`target_type` in (_utf8mb4'none',_utf8mb4'station',_utf8mb4'pile',_utf8mb4'gun',_utf8mb4'order',_utf8mb4'account'))),
  CONSTRAINT `ck_incident_action_3` CHECK (((`target_type` = _utf8mb4'none') or (`target_id` is not null)))
) ENGINE=InnoDB AUTO_INCREMENT=972 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='事件处置动作';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `incident_action`
--

LOCK TABLES `incident_action` WRITE;
/*!40000 ALTER TABLE `incident_action` DISABLE KEYS */;
INSERT INTO `incident_action` VALUES (901,901,'declare','none',NULL,'2026-11-13 12:05:00.000',101,NULL,'3 桩同时掉线，宣布 P1','已宣布','2026-11-19 10:23:00.186','2026-11-19 10:23:00.186'),(902,901,'notify','account',101,'2026-11-13 12:05:00.000',101,NULL,'通知值班主管','已确认','2026-11-19 10:23:00.186','2026-11-19 10:23:00.186'),(903,901,'isolate_station','station',901,'2026-11-13 12:06:00.000',101,101,'防止带故障合闸','场站已隔离，暂停接单','2026-11-19 10:23:00.186','2026-11-19 10:23:00.186'),(904,901,'dispatch','account',102,'2026-11-13 12:07:00.000',101,NULL,'派抢修班到场','已出发','2026-11-19 10:23:00.186','2026-11-19 10:23:00.186'),(905,902,'declare','none',NULL,'2026-11-13 02:10:00.000',101,NULL,'模块温度持续超阈值','已宣布','2026-11-19 10:23:00.186','2026-11-19 10:23:00.186'),(906,902,'restore','station',6,'2026-11-13 03:30:00.000',102,101,'更换风扇并复测通过','业务恢复','2026-11-19 10:23:00.186','2026-11-19 10:23:00.186'),(907,921,'close','none',NULL,'2026-11-10 05:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(908,921,'declare','none',NULL,'2026-11-10 02:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(909,922,'close','none',NULL,'2026-11-10 06:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(910,922,'declare','none',NULL,'2026-11-10 03:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(911,923,'close','none',NULL,'2026-11-10 07:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(912,923,'declare','none',NULL,'2026-11-10 04:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(913,924,'close','none',NULL,'2026-11-10 08:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(914,924,'declare','none',NULL,'2026-11-10 05:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(915,925,'close','none',NULL,'2026-11-10 09:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(916,925,'declare','none',NULL,'2026-11-10 06:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(917,926,'close','none',NULL,'2026-11-10 10:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(918,926,'declare','none',NULL,'2026-11-10 07:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(919,927,'close','none',NULL,'2026-11-10 11:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(920,927,'declare','none',NULL,'2026-11-10 08:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(921,928,'close','none',NULL,'2026-11-10 12:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(922,928,'declare','none',NULL,'2026-11-10 09:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(923,929,'close','none',NULL,'2026-11-10 13:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(924,929,'declare','none',NULL,'2026-11-10 10:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(925,930,'close','none',NULL,'2026-11-10 14:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(926,930,'declare','none',NULL,'2026-11-10 11:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(927,931,'close','none',NULL,'2026-11-10 15:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(928,931,'declare','none',NULL,'2026-11-10 12:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(929,932,'close','none',NULL,'2026-11-10 16:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(930,932,'declare','none',NULL,'2026-11-10 13:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(931,933,'close','none',NULL,'2026-11-10 17:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(932,933,'declare','none',NULL,'2026-11-10 14:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(933,934,'close','none',NULL,'2026-11-10 18:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(934,934,'declare','none',NULL,'2026-11-10 15:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(935,935,'close','none',NULL,'2026-11-10 19:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(936,935,'declare','none',NULL,'2026-11-10 16:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(937,936,'close','none',NULL,'2026-11-10 20:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(938,936,'declare','none',NULL,'2026-11-10 17:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(939,937,'close','none',NULL,'2026-11-10 21:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(940,937,'declare','none',NULL,'2026-11-10 18:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(941,938,'close','none',NULL,'2026-11-10 22:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(942,938,'declare','none',NULL,'2026-11-10 19:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(943,939,'close','none',NULL,'2026-11-10 23:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(944,939,'declare','none',NULL,'2026-11-10 20:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(945,940,'close','none',NULL,'2026-11-11 00:00:00.000',101,101,'复盘通过后关闭事件','已关闭','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(946,940,'declare','none',NULL,'2026-11-10 21:00:00.000',101,NULL,'按 SLA 宣布事件','已宣布','2026-11-19 10:23:00.493','2026-11-19 10:23:00.493'),(970,941,'declare','none',NULL,'2026-11-19 10:23:27.733',NULL,NULL,'声明 P2 事件：自动聚合：场站 14 10 分钟内 2 条严重告警',NULL,'2026-11-19 10:23:27.733','2026-11-19 10:23:27.733'),(971,901,'escalate','none',NULL,'2026-11-19 10:23:27.733',NULL,NULL,'自动升级到 L3，策略 920',NULL,'2026-11-19 10:23:27.733','2026-11-19 10:23:27.733');
/*!40000 ALTER TABLE `incident_action` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `incident_alert`
--

DROP TABLE IF EXISTS `incident_alert`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `incident_alert` (
  `incident_id` bigint unsigned NOT NULL COMMENT '事件',
  `alert_id` bigint unsigned NOT NULL COMMENT '告警',
  `linked_at` datetime(3) NOT NULL COMMENT '关联时间',
  `linked_by` bigint unsigned DEFAULT NULL COMMENT '手工关联账号；系统聚合为空',
  `is_root_cause` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '是否根因告警',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`incident_id`,`alert_id`),
  UNIQUE KEY `uq_incident_alert_alert_id` (`alert_id`),
  KEY `fk_incident_alert_linked_by` (`linked_by`),
  CONSTRAINT `fk_incident_alert_alert` FOREIGN KEY (`alert_id`) REFERENCES `device_alert` (`alert_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_incident_alert_incident` FOREIGN KEY (`incident_id`) REFERENCES `incident` (`incident_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_incident_alert_linked_by` FOREIGN KEY (`linked_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_incident_alert_1` CHECK ((`is_root_cause` in (0,1)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='事件告警关联';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `incident_alert`
--

LOCK TABLES `incident_alert` WRITE;
/*!40000 ALTER TABLE `incident_alert` DISABLE KEYS */;
INSERT INTO `incident_alert` VALUES (901,911,'2026-11-13 12:05:00.000',101,1,'2026-11-19 10:23:00.144','2026-11-19 10:23:00.144'),(901,912,'2026-11-13 12:12:00.000',NULL,0,'2026-11-19 10:23:00.144','2026-11-19 10:23:00.144'),(901,913,'2026-11-13 12:24:00.000',NULL,0,'2026-11-19 10:23:00.144','2026-11-19 10:23:00.144'),(902,904,'2026-11-13 02:10:00.000',101,1,'2026-11-19 10:23:00.144','2026-11-19 10:23:00.144'),(921,931,'2026-11-10 01:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(921,951,'2026-11-11 01:05:00.000',102,0,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(922,932,'2026-11-10 02:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(923,933,'2026-11-10 03:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(924,934,'2026-11-10 04:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(925,935,'2026-11-10 05:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(926,936,'2026-11-10 06:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(927,937,'2026-11-10 07:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(928,938,'2026-11-10 08:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(929,939,'2026-11-10 09:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(930,940,'2026-11-10 10:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(931,941,'2026-11-10 11:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(932,942,'2026-11-10 12:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(933,943,'2026-11-10 13:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(934,944,'2026-11-10 14:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(935,945,'2026-11-10 15:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(936,946,'2026-11-10 16:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(937,947,'2026-11-10 17:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(938,948,'2026-11-10 18:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(939,949,'2026-11-10 19:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480'),(940,950,'2026-11-10 20:05:00.000',101,1,'2026-11-19 10:23:00.480','2026-11-19 10:23:00.480');
/*!40000 ALTER TABLE `incident_alert` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `incident_escalation`
--

DROP TABLE IF EXISTS `incident_escalation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `incident_escalation` (
  `escalation_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `incident_id` bigint unsigned NOT NULL COMMENT '事件',
  `policy_id` bigint unsigned NOT NULL COMMENT '命中的策略',
  `notify_level` varchar(8) NOT NULL COMMENT '通知层级快照',
  `triggered_at` datetime(3) NOT NULL COMMENT '触发时间',
  `notified_account_id` bigint unsigned DEFAULT NULL COMMENT '被通知账号',
  `ack_at` datetime(3) DEFAULT NULL COMMENT '确认时间',
  `note` varchar(500) DEFAULT NULL COMMENT '备注',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`escalation_id`),
  UNIQUE KEY `uq_incident_escalation_once` (`incident_id`,`policy_id`),
  KEY `ix_incident_escalation_time` (`triggered_at`),
  KEY `fk_incident_escalation_policy` (`policy_id`),
  KEY `fk_incident_escalation_account` (`notified_account_id`),
  CONSTRAINT `fk_incident_escalation_account` FOREIGN KEY (`notified_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_incident_escalation_incident` FOREIGN KEY (`incident_id`) REFERENCES `incident` (`incident_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_incident_escalation_policy` FOREIGN KEY (`policy_id`) REFERENCES `escalation_policy` (`policy_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_incident_escalation_1` CHECK ((`notify_level` in (_utf8mb4'L1',_utf8mb4'L2',_utf8mb4'L3')))
) ENGINE=InnoDB AUTO_INCREMENT=924 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='事件升级记录';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `incident_escalation`
--

LOCK TABLES `incident_escalation` WRITE;
/*!40000 ALTER TABLE `incident_escalation` DISABLE KEYS */;
INSERT INTO `incident_escalation` VALUES (901,901,901,'L3','2026-11-13 12:05:00.000',101,'2026-11-13 12:06:00.000','P1 立即通知值班主管','2026-11-19 10:23:00.177','2026-11-19 10:23:00.177'),(902,902,902,'L2','2026-11-13 02:10:00.000',101,'2026-11-13 02:12:00.000','P2 30 分钟未恢复，通知运营商','2026-11-19 10:23:00.177','2026-11-19 10:23:00.177'),(903,921,901,'L3','2026-11-10 01:30:00.000',101,'2026-11-10 01:32:00.000','演练通知主管','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(904,922,902,'L2','2026-11-10 02:30:00.000',101,'2026-11-10 02:32:00.000','演练通知运营商','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(905,923,903,'L2','2026-11-10 03:30:00.000',101,'2026-11-10 03:33:00.000','演练改派','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(906,924,904,'L2','2026-11-10 04:30:00.000',102,'2026-11-10 04:33:00.000','演练改派','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(907,925,905,'L1','2026-11-10 05:30:00.000',102,'2026-11-10 05:35:00.000','演练通知','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(908,926,901,'L3','2026-11-10 06:30:00.000',101,'2026-11-10 06:32:00.000','演练通知主管','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(909,927,902,'L2','2026-11-10 07:30:00.000',101,'2026-11-10 07:33:00.000','演练通知运营商','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(910,928,903,'L2','2026-11-10 08:30:00.000',102,'2026-11-10 08:33:00.000','演练改派','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(911,929,904,'L2','2026-11-10 09:30:00.000',102,'2026-11-10 09:34:00.000','演练改派','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(912,930,905,'L1','2026-11-10 10:30:00.000',101,'2026-11-10 10:35:00.000','演练通知','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(913,931,901,'L3','2026-11-10 11:30:00.000',101,'2026-11-10 11:32:00.000','演练通知主管','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(914,932,902,'L2','2026-11-10 12:30:00.000',101,'2026-11-10 12:33:00.000','演练通知运营商','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(915,933,903,'L2','2026-11-10 13:30:00.000',102,'2026-11-10 13:33:00.000','演练改派','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(916,934,904,'L2','2026-11-10 14:30:00.000',102,'2026-11-10 14:34:00.000','演练改派','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(917,935,905,'L1','2026-11-10 15:30:00.000',101,'2026-11-10 15:35:00.000','演练通知','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(918,936,901,'L3','2026-11-10 16:30:00.000',101,'2026-11-10 16:32:00.000','演练通知主管','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(919,937,902,'L2','2026-11-10 17:30:00.000',101,'2026-11-10 17:33:00.000','演练通知运营商','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(920,938,903,'L2','2026-11-10 18:30:00.000',102,'2026-11-10 18:33:00.000','演练改派','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(921,939,904,'L2','2026-11-10 19:30:00.000',102,'2026-11-10 19:34:00.000','演练改派','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(922,940,905,'L1','2026-11-10 20:30:00.000',101,'2026-11-10 20:35:00.000','演练通知','2026-11-19 10:23:00.540','2026-11-19 10:23:00.540'),(923,901,920,'L3','2026-11-19 10:23:27.733',101,NULL,'持续 512307 秒，影响 3 桩，动作 notify_supervisor','2026-11-19 10:23:27.733','2026-11-19 10:23:27.733');
/*!40000 ALTER TABLE `incident_escalation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `incident_sla`
--

DROP TABLE IF EXISTS `incident_sla`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `incident_sla` (
  `severity` varchar(8) NOT NULL COMMENT '事件级别',
  `ack_seconds` int unsigned NOT NULL COMMENT '宣布事件的时限秒',
  `restore_seconds` int unsigned NOT NULL COMMENT '业务恢复时限秒',
  `description` varchar(200) DEFAULT NULL COMMENT '说明',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`severity`),
  CONSTRAINT `ck_incident_sla_1` CHECK ((`severity` in (_utf8mb4'P1',_utf8mb4'P2',_utf8mb4'P3',_utf8mb4'P4'))),
  CONSTRAINT `ck_incident_sla_2` CHECK ((`ack_seconds` > 0)),
  CONSTRAINT `ck_incident_sla_3` CHECK ((`restore_seconds` >= `ack_seconds`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='事件SLA基线';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `incident_sla`
--

LOCK TABLES `incident_sla` WRITE;
/*!40000 ALTER TABLE `incident_sla` DISABLE KEYS */;
INSERT INTO `incident_sla` VALUES ('P1',900,14400,'重大：整站或多桩失效，15 分钟内宣布，4 小时内恢复','2026-11-19 10:23:00.161','2026-11-19 10:23:00.161'),('P2',1800,28800,'较大：单站部分设备失效，30 分钟内宣布，8 小时内恢复','2026-11-19 10:23:00.161','2026-11-19 10:23:00.161'),('P3',7200,86400,'一般：单桩故障，2 小时内宣布，24 小时内恢复','2026-11-19 10:23:00.161','2026-11-19 10:23:00.161'),('P4',28800,259200,'轻微：不影响充电服务，8 小时内宣布，72 小时内恢复','2026-11-19 10:23:00.161','2026-11-19 10:23:00.161');
/*!40000 ALTER TABLE `incident_sla` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inspection_record`
--

DROP TABLE IF EXISTS `inspection_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inspection_record` (
  `inspection_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `pile_id` bigint unsigned NOT NULL COMMENT '巡检桩',
  `inspected_by` bigint unsigned NOT NULL COMMENT '巡检账号',
  `inspected_at` datetime(3) NOT NULL COMMENT '巡检时间',
  `result` varchar(32) NOT NULL COMMENT '检查结论',
  `parts_used` varchar(500) DEFAULT NULL COMMENT '备件更换说明',
  `note` varchar(1000) DEFAULT NULL COMMENT '检查说明',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`inspection_id`),
  KEY `fk_inspection_record_pile_id` (`pile_id`),
  KEY `fk_inspection_record_inspected_by` (`inspected_by`),
  KEY `ix_inspection_record_inspected_at` (`inspected_at`),
  CONSTRAINT `fk_inspection_record_inspected_by` FOREIGN KEY (`inspected_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_inspection_record_pile_id` FOREIGN KEY (`pile_id`) REFERENCES `charging_pile` (`pile_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_inspection_record_1` CHECK ((`result` in (_utf8mb4'normal',_utf8mb4'abnormal')))
) ENGINE=InnoDB AUTO_INCREMENT=903 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inspection_record`
--

LOCK TABLES `inspection_record` WRITE;
/*!40000 ALTER TABLE `inspection_record` DISABLE KEYS */;
INSERT INTO `inspection_record` VALUES (1,1,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(2,2,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(3,3,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(4,4,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(5,5,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(6,6,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(7,7,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(8,8,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(9,9,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(10,10,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(11,11,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(12,12,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(13,13,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(14,14,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(15,15,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(16,16,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(17,17,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(18,18,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(19,19,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(20,20,102,'2026-10-20 04:34:00.000','normal',NULL,'设备恢复复核','2026-11-19 10:22:52.945','2026-11-19 10:22:52.945'),(901,3,102,'2026-11-14 01:31:00.000','normal','温度探头','闭环前复检：连续采样温度正常，枪线无异常','2026-11-19 10:22:53.419','2026-11-19 10:22:53.419'),(902,6,102,'2026-11-13 02:12:00.000','abnormal','接触器','复检绝缘电阻不达标，需继续维修','2026-11-19 10:22:53.419','2026-11-19 10:22:53.419');
/*!40000 ALTER TABLE `inspection_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `meter_reading`
--

DROP TABLE IF EXISTS `meter_reading`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `meter_reading` (
  `reading_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` bigint unsigned NOT NULL COMMENT '订单',
  `sampled_at` datetime(3) NOT NULL COMMENT '采样时刻',
  `cumulative_energy_kwh` decimal(14,3) NOT NULL COMMENT '累计电表读数 非本单新增电量',
  `soc` decimal(5,2) DEFAULT NULL COMMENT '车辆当前SOC 可空',
  `source` varchar(32) NOT NULL COMMENT '数据来源',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`reading_id`),
  UNIQUE KEY `uq_meter_reading_order_id_sampled_at` (`order_id`,`sampled_at`),
  CONSTRAINT `fk_meter_reading_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_meter_reading_1` CHECK ((`cumulative_energy_kwh` >= 0)),
  CONSTRAINT `ck_meter_reading_2` CHECK (((`soc` is null) or (`soc` between 0 and 100))),
  CONSTRAINT `ck_meter_reading_3` CHECK ((`source` in (_utf8mb4'simulator',_utf8mb4'device',_utf8mb4'manual')))
) ENGINE=InnoDB AUTO_INCREMENT=6021 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `meter_reading`
--

LOCK TABLES `meter_reading` WRITE;
/*!40000 ALTER TABLE `meter_reading` DISABLE KEYS */;
INSERT INTO `meter_reading` VALUES (1,1,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(2,2,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(3,3,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(4,4,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5,5,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6,6,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(7,7,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(8,8,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(9,9,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(10,10,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(11,11,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(12,12,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(13,13,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(14,14,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(15,15,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(16,16,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(17,17,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(18,18,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(19,19,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(20,20,'2026-10-20 02:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(101,101,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(102,102,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(103,103,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(104,104,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(105,105,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(106,106,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(107,107,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(108,108,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(109,109,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(110,110,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(111,111,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(112,112,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(113,113,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(114,114,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(115,115,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(116,116,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(117,117,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(118,118,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(119,119,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(120,120,'2026-10-20 03:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1001,1001,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1002,1002,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1003,1003,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1004,1004,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1005,1005,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1006,1006,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1007,1007,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1008,1008,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1009,1009,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1010,1010,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1011,1011,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1012,1012,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1013,1013,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1014,1014,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1015,1015,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1016,1016,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1017,1017,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1018,1018,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1019,1019,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(1020,1020,'2026-10-20 05:00:00.000',100.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5001,1,'2026-10-20 02:30:00.000',111.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5002,2,'2026-10-20 02:30:00.000',112.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5003,3,'2026-10-20 02:30:00.000',113.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5004,4,'2026-10-20 02:30:00.000',114.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5005,5,'2026-10-20 02:30:00.000',115.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5006,6,'2026-10-20 02:30:00.000',116.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5007,7,'2026-10-20 02:30:00.000',117.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5008,8,'2026-10-20 02:30:00.000',118.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5009,9,'2026-10-20 02:30:00.000',119.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5010,10,'2026-10-20 02:30:00.000',120.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5011,11,'2026-10-20 02:30:00.000',121.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5012,12,'2026-10-20 02:30:00.000',122.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5013,13,'2026-10-20 02:30:00.000',123.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5014,14,'2026-10-20 02:30:00.000',124.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5015,15,'2026-10-20 02:30:00.000',125.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5016,16,'2026-10-20 02:30:00.000',126.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5017,17,'2026-10-20 02:30:00.000',127.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5018,18,'2026-10-20 02:30:00.000',128.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5019,19,'2026-10-20 02:30:00.000',129.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5020,20,'2026-10-20 02:30:00.000',130.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5101,101,'2026-10-20 03:30:00.000',109.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5102,102,'2026-10-20 03:30:00.000',110.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5103,103,'2026-10-20 03:30:00.000',111.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5104,104,'2026-10-20 03:30:00.000',112.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5105,105,'2026-10-20 03:30:00.000',113.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5106,106,'2026-10-20 03:30:00.000',114.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5107,107,'2026-10-20 03:30:00.000',115.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5108,108,'2026-10-20 03:30:00.000',116.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5109,109,'2026-10-20 03:30:00.000',117.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5110,110,'2026-10-20 03:30:00.000',118.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5111,111,'2026-10-20 03:30:00.000',119.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5112,112,'2026-10-20 03:30:00.000',120.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5113,113,'2026-10-20 03:30:00.000',121.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5114,114,'2026-10-20 03:30:00.000',122.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5115,115,'2026-10-20 03:30:00.000',123.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5116,116,'2026-10-20 03:30:00.000',124.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5117,117,'2026-10-20 03:30:00.000',125.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5118,118,'2026-10-20 03:30:00.000',126.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5119,119,'2026-10-20 03:30:00.000',127.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(5120,120,'2026-10-20 03:30:00.000',128.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6001,1001,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6002,1002,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6003,1003,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6004,1004,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6005,1005,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6006,1006,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6007,1007,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6008,1008,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6009,1009,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6010,1010,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6011,1011,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6012,1012,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6013,1013,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6014,1014,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6015,1015,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6016,1016,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6017,1017,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6018,1018,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6019,1019,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968'),(6020,1020,'2026-10-20 05:15:00.000',104.000,NULL,'simulator','2026-11-19 10:22:52.968','2026-11-19 10:22:52.968');
/*!40000 ALTER TABLE `meter_reading` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notification`
--

DROP TABLE IF EXISTS `notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notification` (
  `notification_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `account_id` bigint unsigned NOT NULL COMMENT '接收账号',
  `notification_type` varchar(50) NOT NULL COMMENT 'offline work_order settlement等',
  `business_key` varchar(120) NOT NULL COMMENT '业务事件唯一键',
  `title` varchar(100) NOT NULL COMMENT '标题',
  `content` varchar(1000) NOT NULL COMMENT '脱敏内容',
  `target_path` varchar(255) NOT NULL COMMENT '允许的前端相对路径',
  `read_at` datetime(3) DEFAULT NULL COMMENT '已读时间',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`notification_id`),
  UNIQUE KEY `uq_notification_account_id_business_key` (`account_id`,`business_key`),
  CONSTRAINT `fk_notification_account_id` FOREIGN KEY (`account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=338 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notification`
--

LOCK TABLES `notification` WRITE;
/*!40000 ALTER TABLE `notification` DISABLE KEYS */;
INSERT INTO `notification` VALUES (1,102,'work_order','fixture-work-1','历史工单','演示工单1已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(2,102,'work_order','fixture-work-2','历史工单','演示工单2已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(3,102,'work_order','fixture-work-3','历史工单','演示工单3已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(4,102,'work_order','fixture-work-4','历史工单','演示工单4已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(5,102,'work_order','fixture-work-5','历史工单','演示工单5已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(6,102,'work_order','fixture-work-6','历史工单','演示工单6已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(7,102,'work_order','fixture-work-7','历史工单','演示工单7已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(8,102,'work_order','fixture-work-8','历史工单','演示工单8已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(9,102,'work_order','fixture-work-9','历史工单','演示工单9已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(10,102,'work_order','fixture-work-10','历史工单','演示工单10已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(11,102,'work_order','fixture-work-11','历史工单','演示工单11已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(12,102,'work_order','fixture-work-12','历史工单','演示工单12已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(13,102,'work_order','fixture-work-13','历史工单','演示工单13已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(14,102,'work_order','fixture-work-14','历史工单','演示工单14已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(15,102,'work_order','fixture-work-15','历史工单','演示工单15已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(16,102,'work_order','fixture-work-16','历史工单','演示工单16已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(17,102,'work_order','fixture-work-17','历史工单','演示工单17已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(18,102,'work_order','fixture-work-18','历史工单','演示工单18已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(19,102,'work_order','fixture-work-19','历史工单','演示工单19已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(20,102,'work_order','fixture-work-20','历史工单','演示工单20已闭环','/maintenance/work-orders','2026-10-20 04:40:00.000','2026-11-19 10:22:52.914','2026-11-19 10:22:52.914'),(21,101,'work_order_overdue','wo_overdue:903:1','工单超时未接单','工单 903 已超过响应时限，已升级到 L1','/maintenance/work-orders/903',NULL,'2026-11-19 10:23:26.090','2026-11-19 10:23:26.090'),(22,101,'work_order_overdue','wo_overdue:902:1','工单超时未接单','工单 902 已超过响应时限，已升级到 L1','/maintenance/work-orders/902',NULL,'2026-11-19 10:23:26.097','2026-11-19 10:23:26.097');
/*!40000 ALTER TABLE `notification` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `on_call_shift`
--

DROP TABLE IF EXISTS `on_call_shift`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `on_call_shift` (
  `shift_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `scope_type` varchar(16) NOT NULL COMMENT '值班范围类型',
  `scope_id` bigint unsigned NOT NULL COMMENT '场站或运营商编号；多态引用',
  `shift_start` datetime(3) NOT NULL COMMENT '班次开始',
  `shift_end` datetime(3) NOT NULL COMMENT '班次结束',
  `primary_account_id` bigint unsigned NOT NULL COMMENT '主值班',
  `backup_account_id` bigint unsigned DEFAULT NULL COMMENT '备班',
  `supervisor_account_id` bigint unsigned DEFAULT NULL COMMENT '值班主管',
  `status` varchar(16) NOT NULL DEFAULT 'planned' COMMENT '班次状态',
  `note` varchar(500) DEFAULT NULL COMMENT '交接说明',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`shift_id`),
  UNIQUE KEY `uq_on_call_shift_scope_start` (`scope_type`,`scope_id`,`shift_start`),
  KEY `ix_on_call_shift_window` (`shift_start`,`shift_end`),
  KEY `fk_on_call_shift_primary` (`primary_account_id`),
  KEY `fk_on_call_shift_backup` (`backup_account_id`),
  KEY `fk_on_call_shift_supervisor` (`supervisor_account_id`),
  CONSTRAINT `fk_on_call_shift_backup` FOREIGN KEY (`backup_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_on_call_shift_primary` FOREIGN KEY (`primary_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_on_call_shift_supervisor` FOREIGN KEY (`supervisor_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_on_call_shift_1` CHECK ((`scope_type` in (_utf8mb4'station',_utf8mb4'operator'))),
  CONSTRAINT `ck_on_call_shift_2` CHECK ((`status` in (_utf8mb4'planned',_utf8mb4'active',_utf8mb4'ended'))),
  CONSTRAINT `ck_on_call_shift_3` CHECK ((`shift_end` > `shift_start`)),
  CONSTRAINT `ck_on_call_shift_4` CHECK (((`backup_account_id` is null) or (`backup_account_id` <> `primary_account_id`)))
) ENGINE=InnoDB AUTO_INCREMENT=931 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='值班班次';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `on_call_shift`
--

LOCK TABLES `on_call_shift` WRITE;
/*!40000 ALTER TABLE `on_call_shift` DISABLE KEYS */;
INSERT INTO `on_call_shift` VALUES (901,'station',901,'2026-11-13 00:00:00.000','2026-11-14 00:00:00.000',102,103,101,'active','白班：张工；备班：李工','2026-11-19 10:23:00.153','2026-11-19 10:23:00.153'),(902,'station',6,'2026-11-13 00:00:00.000','2026-11-14 00:00:00.000',102,103,101,'active','白班','2026-11-19 10:23:00.153','2026-11-19 10:23:00.153'),(903,'operator',3,'2026-11-13 00:00:00.000','2026-11-14 00:00:00.000',102,103,101,'active','运营商值班','2026-11-19 10:23:00.153','2026-11-19 10:23:00.153'),(911,'station',1,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(912,'station',2,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(913,'station',3,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(914,'station',4,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(915,'station',5,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(916,'station',6,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(917,'station',7,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(918,'station',8,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(919,'station',9,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(920,'station',10,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(921,'station',11,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(922,'station',12,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(923,'station',13,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(924,'station',14,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(925,'station',15,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(926,'station',16,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(927,'station',17,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(928,'station',18,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(929,'station',19,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508'),(930,'station',20,'2026-11-12 00:00:00.000','2026-11-13 00:00:00.000',102,103,101,'ended','演练班次','2026-11-19 10:23:00.508','2026-11-19 10:23:00.508');
/*!40000 ALTER TABLE `on_call_shift` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operator`
--

DROP TABLE IF EXISTS `operator`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `operator` (
  `operator_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `operator_name` varchar(100) NOT NULL COMMENT '运营商名称',
  `credit_code` varchar(18) NOT NULL COMMENT '统一社会信用代码',
  `contact_name` varchar(50) NOT NULL COMMENT '联系人',
  `contact_phone_cipher` varbinary(512) NOT NULL COMMENT '联系电话密文',
  `status` varchar(32) NOT NULL DEFAULT 'active' COMMENT '启用状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`operator_id`),
  UNIQUE KEY `uq_operator_credit_code` (`credit_code`),
  CONSTRAINT `ck_operator_1` CHECK ((`status` in (_utf8mb4'active',_utf8mb4'disabled')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operator`
--

LOCK TABLES `operator` WRITE;
/*!40000 ALTER TABLE `operator` DISABLE KEYS */;
INSERT INTO `operator` VALUES (1,'演示运营商01','DEMOOP000000000001','运营联系人1',_binary 'gAAAAABq9qidWvCPytezqkC25McOB0veXlbHVTQFA4HZyMtSIIN2CyHHnRXgVhG1BxJDL23Dkcv-mjP44gAN5qFFAJC6_gobdA==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(2,'演示运营商02','DEMOOP000000000002','运营联系人2',_binary 'gAAAAABq9qidQJ1c9hugaJr_1dtjaIILYEkYhDGKqLWIblgg_C8bfkL2uq8ROBlBeGBM0dc--wgR17EbFWWiNnhTTadBvCgq0A==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(3,'演示运营商03','DEMOOP000000000003','运营联系人3',_binary 'gAAAAABq9qidvbcmAofkuGHRwavPfUIv_Iwdh6BO8prS_uJqXkn3gticvELsv9ut6Zsq1tA9qM-PsX2sLsMVoWaL_j-cIBAF4Q==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(4,'演示运营商04','DEMOOP000000000004','运营联系人4',_binary 'gAAAAABq9qidxPHYbtcD9UIT7NX99Q3H9rkPHapstqciPDZ3AMYo-6mX6XYPHVK2fuU3bw04SbXnyMgdRIXXB0UHlqc9NaDd1Q==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(5,'演示运营商05','DEMOOP000000000005','运营联系人5',_binary 'gAAAAABq9qidTR1p5gIVZkGVmDi_PK6PNVxbmESPPPesh9J1yx6sJoWcHP_jJxVwlthn_wW0Vrgto6QR8mdbpGETSm8PC0Nwbw==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(6,'演示运营商06','DEMOOP000000000006','运营联系人6',_binary 'gAAAAABq9qidT2u8_HLqa99-P7asxQtnc3teVupPKvWmQo8-Sw8qr2lAl2Zx-zdhLC22xlAoxb7tdA6BF20M5xAiAkHTj2PiRA==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(7,'演示运营商07','DEMOOP000000000007','运营联系人7',_binary 'gAAAAABq9qidxP8TBz5oAoz7TctehXhgcDU_m3uL4FbG_DlNYlNwC0k4y_3tRgCx259GbyG43YCvqMU-51rtipsMTi0glyJpFA==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(8,'演示运营商08','DEMOOP000000000008','运营联系人8',_binary 'gAAAAABq9qidznhcqqMKO4ahhwVjdpVW7KixuO6W2AuXSXOOCz3NXDoBEvi49Zt18sQNwDO9xH_36oF34xFx3JAZr6Y_FZJzxg==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(9,'演示运营商09','DEMOOP000000000009','运营联系人9',_binary 'gAAAAABq9qid9vWaGPi_RNvqWTU67Wbo1_t_trEpD7paA90R4Kj8RQI0a7F_X9YMtoD9tzwObW9bc50zD--JeRdJ7z2eOAYgxQ==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(10,'演示运营商10','DEMOOP000000000010','运营联系人10',_binary 'gAAAAABq9qidrv2oorwRObKcVV-BVu5H_sWX-nayjqosJkBqiVJ6aAzKG0SceptsUxzc41ElVahAsb0AFb_llSwJLg9rgttdSQ==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(11,'演示运营商11','DEMOOP000000000011','运营联系人11',_binary 'gAAAAABq9qidRYYq6TXgsbNJfGafPSUcbK1hnN4_mn36K-skfH0ENJ_QEcZblhXH63YcpAxczFvPalB84IMk4liTaOj5Iyq8RA==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(12,'演示运营商12','DEMOOP000000000012','运营联系人12',_binary 'gAAAAABq9qidl8Obo9KXWyYW1e5pEh7Iwyd6HLf-PXlhyIpzwToXzDoHqIdWTm_hIpugv1gYbDsg6AuIL0OlatP2bucd7yCcsg==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(13,'演示运营商13','DEMOOP000000000013','运营联系人13',_binary 'gAAAAABq9qidSTB674W6BvabdVnXO2JZVDibtek5mRmu1JSQljpXGyj5aDWVi2MVmR4EvJOhJ2WH3Y4AUFpvP2-LKLqqXXFAEg==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(14,'演示运营商14','DEMOOP000000000014','运营联系人14',_binary 'gAAAAABq9qideFGJ8Py2ucKnzGgbtdmZhDJvKF3MdCOIaC5Eq6FedCblgSjCyNOArBAYjX2ZpPMTn_IAX8rp99UlpGZtgtRFRA==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(15,'演示运营商15','DEMOOP000000000015','运营联系人15',_binary 'gAAAAABq9qidHXCS4YFOk8-krg61uTxTQKV08KSCiCCRa4Q6Blu1S6RdPTkkDtm4aASg__dv98ncdG18RBKik49snNHH1gTcsA==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(16,'演示运营商16','DEMOOP000000000016','运营联系人16',_binary 'gAAAAABq9qidHVilynJYPKw3fau3gg_PQ_Zm_RqMbJFNmyVea2JI93CpIAFkw4cMMkStB1Z2GQ6W90WuTb7XIoJF3mzm5udVNw==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(17,'演示运营商17','DEMOOP000000000017','运营联系人17',_binary 'gAAAAABq9qidUfcDWcG5jhOZjIX_rnxedxvF_fjnRbWosbYkjTOlPgenm9Yxg0TWz-y-_vhdOLo-3XjjWeY7sIicWpkG-_0Sbw==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(18,'演示运营商18','DEMOOP000000000018','运营联系人18',_binary 'gAAAAABq9qidmPpCa_KcY640IHeDdaLGF9Yerus82loKPtq5Npe5-mkGSq9o5T999L_OZxaPzyIdZ2M_Sat8VJvVDfzOu0_W_A==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(19,'演示运营商19','DEMOOP000000000019','运营联系人19',_binary 'gAAAAABq9qidUUwfubVzm9JS4Cl2Ct0siUAFfIuCCE6wJ1hOJvqiN_WXaNFXevZa2Rt8SY2nWw76emp5mgNsm2Bnt6gDUP3hVQ==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875'),(20,'演示运营商20','DEMOOP000000000020','运营联系人20',_binary 'gAAAAABq9qidhIbhfQc7hqE8cKNhJse968fYWqKBBfiO1eCGvVj7PZy-lC2UMbZtYiewdM8qF9xv-lKACNaaXqLWSQquMwyaIA==','active','2026-11-19 10:22:52.875','2026-11-19 10:22:52.875');
/*!40000 ALTER TABLE `operator` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operator_invoice`
--

DROP TABLE IF EXISTS `operator_invoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `operator_invoice` (
  `invoice_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `settlement_id` bigint unsigned NOT NULL COMMENT '结算单',
  `original_invoice_id` bigint unsigned DEFAULT NULL COMMENT '红冲关联原票',
  `invoice_no` varchar(64) NOT NULL COMMENT '模拟票号',
  `invoice_type` varchar(32) NOT NULL COMMENT '正票或红票',
  `title` varchar(100) NOT NULL COMMENT '抬头',
  `tax_no` varchar(30) NOT NULL COMMENT '税号',
  `amount` decimal(14,2) NOT NULL COMMENT '正数票面额 红票由类型表达冲减',
  `status` varchar(32) NOT NULL COMMENT '开票结果',
  `issued_at` datetime(3) NOT NULL COMMENT '开具时间',
  `issued_by` bigint unsigned NOT NULL COMMENT '办理账号',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`invoice_id`),
  UNIQUE KEY `uq_operator_invoice_invoice_no` (`invoice_no`),
  KEY `fk_operator_invoice_settlement_id` (`settlement_id`),
  KEY `fk_operator_invoice_original_invoice_id` (`original_invoice_id`),
  KEY `fk_operator_invoice_issued_by` (`issued_by`),
  CONSTRAINT `fk_operator_invoice_issued_by` FOREIGN KEY (`issued_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_operator_invoice_original_invoice_id` FOREIGN KEY (`original_invoice_id`) REFERENCES `operator_invoice` (`invoice_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_operator_invoice_settlement_id` FOREIGN KEY (`settlement_id`) REFERENCES `operator_settlement` (`settlement_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_operator_invoice_1` CHECK ((`amount` > 0)),
  CONSTRAINT `ck_operator_invoice_2` CHECK ((((`invoice_type` = _utf8mb4'blue') and (`original_invoice_id` is null)) or ((`invoice_type` = _utf8mb4'red') and (`original_invoice_id` is not null)))),
  CONSTRAINT `ck_operator_invoice_3` CHECK ((`invoice_type` in (_utf8mb4'blue',_utf8mb4'red'))),
  CONSTRAINT `ck_operator_invoice_4` CHECK ((`status` in (_utf8mb4'issued',_utf8mb4'red_issued')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operator_invoice`
--

LOCK TABLES `operator_invoice` WRITE;
/*!40000 ALTER TABLE `operator_invoice` DISABLE KEYS */;
INSERT INTO `operator_invoice` VALUES (1,1,NULL,'FIX-OP-01','blue','演示运营商01','DEMOOP000000000001',8.69,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(2,2,NULL,'FIX-OP-02','blue','演示运营商02','DEMOOP000000000002',9.77,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(3,3,NULL,'FIX-OP-03','blue','演示运营商03','DEMOOP000000000003',10.87,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(4,4,NULL,'FIX-OP-04','blue','演示运营商04','DEMOOP000000000004',11.94,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(5,5,NULL,'FIX-OP-05','blue','演示运营商05','DEMOOP000000000005',13.03,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(6,6,NULL,'FIX-OP-06','blue','演示运营商06','DEMOOP000000000006',14.11,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(7,7,NULL,'FIX-OP-07','blue','演示运营商07','DEMOOP000000000007',15.21,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(8,8,NULL,'FIX-OP-08','blue','演示运营商08','DEMOOP000000000008',16.28,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(9,9,NULL,'FIX-OP-09','blue','演示运营商09','DEMOOP000000000009',17.37,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(10,10,NULL,'FIX-OP-10','blue','演示运营商10','DEMOOP000000000010',18.45,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(11,11,NULL,'FIX-OP-11','blue','演示运营商11','DEMOOP000000000011',19.55,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(12,12,NULL,'FIX-OP-12','blue','演示运营商12','DEMOOP000000000012',20.62,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(13,13,NULL,'FIX-OP-13','blue','演示运营商13','DEMOOP000000000013',21.71,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(14,14,NULL,'FIX-OP-14','blue','演示运营商14','DEMOOP000000000014',22.79,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(15,15,NULL,'FIX-OP-15','blue','演示运营商15','DEMOOP000000000015',23.89,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(16,16,NULL,'FIX-OP-16','blue','演示运营商16','DEMOOP000000000016',24.96,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(17,17,NULL,'FIX-OP-17','blue','演示运营商17','DEMOOP000000000017',26.05,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(18,18,NULL,'FIX-OP-18','blue','演示运营商18','DEMOOP000000000018',27.13,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(19,19,NULL,'FIX-OP-19','blue','演示运营商19','DEMOOP000000000019',28.23,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947'),(20,20,NULL,'FIX-OP-20','blue','演示运营商20','DEMOOP000000000020',29.30,'issued','2026-11-02 04:30:00.000',103,'2026-11-19 10:22:52.947','2026-11-19 10:22:52.947');
/*!40000 ALTER TABLE `operator_invoice` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `operator_settlement`
--

DROP TABLE IF EXISTS `operator_settlement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `operator_settlement` (
  `settlement_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `operator_id` bigint unsigned NOT NULL COMMENT '运营商',
  `station_id` bigint unsigned NOT NULL COMMENT '场站',
  `bill_month` date NOT NULL COMMENT '账期首日',
  `energy_kwh` decimal(14,3) NOT NULL DEFAULT '0.000' COMMENT '归集电量',
  `electricity_share_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '运营商电费分成',
  `service_share_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '运营商服务费分成',
  `platform_fee_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '平台费用',
  `adjustment_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '已生效调整合计 可正负',
  `payable_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '应结金额',
  `status` varchar(32) NOT NULL DEFAULT 'draft' COMMENT '结算状态',
  `version` int unsigned NOT NULL DEFAULT '1' COMMENT '对象版本',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`settlement_id`),
  UNIQUE KEY `uq_operator_settlement_operator_id_station_id_bill_month` (`operator_id`,`station_id`,`bill_month`),
  KEY `fk_operator_settlement_station_id` (`station_id`),
  CONSTRAINT `fk_operator_settlement_operator_id` FOREIGN KEY (`operator_id`) REFERENCES `operator` (`operator_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_operator_settlement_station_id` FOREIGN KEY (`station_id`) REFERENCES `station` (`station_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_operator_settlement_1` CHECK ((dayofmonth(`bill_month`) = 1)),
  CONSTRAINT `ck_operator_settlement_2` CHECK ((`version` > 0)),
  CONSTRAINT `ck_operator_settlement_3` CHECK ((`status` in (_utf8mb4'draft',_utf8mb4'pending_confirmation',_utf8mb4'confirmed',_utf8mb4'invoiced',_utf8mb4'closed')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `operator_settlement`
--

LOCK TABLES `operator_settlement` WRITE;
/*!40000 ALTER TABLE `operator_settlement` DISABLE KEYS */;
INSERT INTO `operator_settlement` VALUES (1,1,1,'2026-10-01',20.000,6.61,2.94,0.66,-0.20,8.69,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(2,2,2,'2026-10-01',22.000,7.41,3.30,0.74,-0.20,9.77,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(3,3,3,'2026-10-01',24.000,8.22,3.66,0.81,-0.20,10.87,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(4,4,4,'2026-10-01',26.000,9.02,4.02,0.90,-0.20,11.94,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(5,5,5,'2026-10-01',28.000,9.83,4.38,0.98,-0.20,13.03,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(6,6,6,'2026-10-01',30.000,10.63,4.74,1.06,-0.20,14.11,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(7,7,7,'2026-10-01',32.000,11.44,5.10,1.13,-0.20,15.21,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(8,8,8,'2026-10-01',34.000,12.24,5.46,1.22,-0.20,16.28,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(9,9,9,'2026-10-01',36.000,13.05,5.82,1.30,-0.20,17.37,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(10,10,10,'2026-10-01',38.000,13.85,6.18,1.38,-0.20,18.45,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(11,11,11,'2026-10-01',40.000,14.66,6.54,1.45,-0.20,19.55,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(12,12,12,'2026-10-01',42.000,15.46,6.90,1.54,-0.20,20.62,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(13,13,13,'2026-10-01',44.000,16.27,7.26,1.62,-0.20,21.71,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(14,14,14,'2026-10-01',46.000,17.07,7.62,1.70,-0.20,22.79,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(15,15,15,'2026-10-01',48.000,17.88,7.98,1.77,-0.20,23.89,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(16,16,16,'2026-10-01',50.000,18.68,8.34,1.86,-0.20,24.96,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(17,17,17,'2026-10-01',52.000,19.49,8.70,1.94,-0.20,26.05,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(18,18,18,'2026-10-01',54.000,20.29,9.06,2.02,-0.20,27.13,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(19,19,19,'2026-10-01',56.000,21.10,9.42,2.09,-0.20,28.23,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925'),(20,20,20,'2026-10-01',58.000,21.90,9.78,2.18,-0.20,29.30,'invoiced',2,'2026-11-19 10:22:52.925','2026-11-19 10:22:52.925');
/*!40000 ALTER TABLE `operator_settlement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_review`
--

DROP TABLE IF EXISTS `order_review`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_review` (
  `review_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` bigint unsigned NOT NULL COMMENT '复核订单',
  `review_type` varchar(32) NOT NULL COMMENT '复核类型',
  `decision` varchar(32) NOT NULL COMMENT '结论',
  `evidence` json NOT NULL COMMENT '复核依据和调整明细',
  `note` varchar(500) NOT NULL COMMENT '说明',
  `reviewed_by` bigint unsigned NOT NULL COMMENT '复核账号',
  `reviewed_at` datetime(3) NOT NULL COMMENT '复核时间',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`review_id`),
  KEY `fk_order_review_order_id` (`order_id`),
  KEY `fk_order_review_reviewed_by` (`reviewed_by`),
  CONSTRAINT `fk_order_review_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_order_review_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_order_review_1` CHECK ((`review_type` in (_utf8mb4'meter',_utf8mb4'quota',_utf8mb4'payment'))),
  CONSTRAINT `ck_order_review_2` CHECK ((`decision` in (_utf8mb4'approved',_utf8mb4'rejected')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_review`
--

LOCK TABLES `order_review` WRITE;
/*!40000 ALTER TABLE `order_review` DISABLE KEYS */;
INSERT INTO `order_review` VALUES (1,1001,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(2,1002,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(3,1003,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(4,1004,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(5,1005,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(6,1006,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(7,1007,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(8,1008,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(9,1009,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(10,1010,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(11,1011,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(12,1012,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(13,1013,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(14,1014,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(15,1015,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(16,1016,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(17,1017,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(18,1018,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(19,1019,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977'),(20,1020,'meter','approved','{\"source\": \"simulator\", \"verified_kwh\": \"4.000\"}','已复核电量，待支付',103,'2026-10-20 05:17:00.000','2026-11-19 10:22:52.977','2026-11-19 10:22:52.977');
/*!40000 ALTER TABLE `order_review` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `outbox_event`
--

DROP TABLE IF EXISTS `outbox_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `outbox_event` (
  `outbox_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `event_type` varchar(50) NOT NULL COMMENT '设备命令或通知类型',
  `business_key` varchar(120) NOT NULL COMMENT '唯一事件键',
  `payload` json NOT NULL COMMENT '必要业务编号 不含密钥',
  `status` varchar(32) NOT NULL DEFAULT 'pending' COMMENT '消费状态',
  `attempt_count` int unsigned NOT NULL DEFAULT '0' COMMENT '重试次数',
  `available_at` datetime(3) NOT NULL COMMENT '可执行时间',
  `locked_until` datetime(3) DEFAULT NULL COMMENT '消费者租约',
  `last_error` varchar(500) DEFAULT NULL COMMENT '最近失败说明',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`outbox_id`),
  UNIQUE KEY `uq_outbox_event_business_key` (`business_key`),
  KEY `ix_outbox_event_status_available_at` (`status`,`available_at`),
  CONSTRAINT `ck_outbox_event_1` CHECK ((`status` in (_utf8mb4'pending',_utf8mb4'processing',_utf8mb4'done',_utf8mb4'failed')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `outbox_event`
--

LOCK TABLES `outbox_event` WRITE;
/*!40000 ALTER TABLE `outbox_event` DISABLE KEYS */;
INSERT INTO `outbox_event` VALUES (1,'device_command','fixture-device-command-1','{\"command_id\": 1}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(2,'device_command','fixture-device-command-2','{\"command_id\": 2}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(3,'device_command','fixture-device-command-3','{\"command_id\": 3}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(4,'device_command','fixture-device-command-4','{\"command_id\": 4}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(5,'device_command','fixture-device-command-5','{\"command_id\": 5}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(6,'device_command','fixture-device-command-6','{\"command_id\": 6}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(7,'device_command','fixture-device-command-7','{\"command_id\": 7}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(8,'device_command','fixture-device-command-8','{\"command_id\": 8}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(9,'device_command','fixture-device-command-9','{\"command_id\": 9}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(10,'device_command','fixture-device-command-10','{\"command_id\": 10}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(11,'device_command','fixture-device-command-11','{\"command_id\": 11}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(12,'device_command','fixture-device-command-12','{\"command_id\": 12}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(13,'device_command','fixture-device-command-13','{\"command_id\": 13}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(14,'device_command','fixture-device-command-14','{\"command_id\": 14}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(15,'device_command','fixture-device-command-15','{\"command_id\": 15}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(16,'device_command','fixture-device-command-16','{\"command_id\": 16}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(17,'device_command','fixture-device-command-17','{\"command_id\": 17}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(18,'device_command','fixture-device-command-18','{\"command_id\": 18}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(19,'device_command','fixture-device-command-19','{\"command_id\": 19}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891'),(20,'device_command','fixture-device-command-20','{\"command_id\": 20}','done',1,'2026-10-20 02:00:00.000',NULL,NULL,'2026-11-19 10:22:52.891','2026-11-19 10:22:52.891');
/*!40000 ALTER TABLE `outbox_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `part_stock_movement`
--

DROP TABLE IF EXISTS `part_stock_movement`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `part_stock_movement` (
  `movement_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `part_id` bigint unsigned NOT NULL COMMENT '备件编号',
  `movement_type` varchar(8) NOT NULL COMMENT 'in 入库 / out 领用',
  `qty` int unsigned NOT NULL COMMENT '变动数量',
  `balance_after` int unsigned NOT NULL COMMENT '变动后库存',
  `occurred_at` datetime(3) NOT NULL COMMENT '发生时间',
  `operator_account_id` bigint unsigned DEFAULT NULL COMMENT '操作账号；系统补录为空',
  `note` varchar(255) DEFAULT NULL COMMENT '说明',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`movement_id`),
  KEY `ix_part_movement_part_time` (`part_id`,`occurred_at`),
  CONSTRAINT `fk_part_movement_part` FOREIGN KEY (`part_id`) REFERENCES `spare_part` (`part_id`),
  CONSTRAINT `ck_part_movement_type` CHECK ((`movement_type` in (_utf8mb4'in',_utf8mb4'out')))
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='备件库存流水';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `part_stock_movement`
--

LOCK TABLES `part_stock_movement` WRITE;
/*!40000 ALTER TABLE `part_stock_movement` DISABLE KEYS */;
INSERT INTO `part_stock_movement` VALUES (1,902,'out',1,3,'2026-11-13 09:52:00.000',102,'历史领用补录','2026-11-19 10:23:00.364','2026-11-19 10:23:00.364'),(2,901,'out',2,6,'2026-11-14 01:25:00.000',102,'历史领用补录','2026-11-19 10:23:00.364','2026-11-19 10:23:00.364'),(4,904,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(5,904,'out',1,29,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(6,905,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(7,905,'out',2,28,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(8,906,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(9,906,'out',1,29,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(10,907,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(11,907,'out',2,28,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(12,908,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(13,908,'out',1,29,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(14,909,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(15,909,'out',2,28,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(16,910,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(17,910,'out',1,29,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(18,911,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(19,911,'out',2,28,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(20,912,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(21,912,'out',1,29,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(22,913,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(23,913,'out',2,28,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(24,914,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(25,914,'out',1,29,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(26,915,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(27,915,'out',2,28,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(28,916,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(29,916,'out',1,29,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(30,917,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(31,917,'out',2,28,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(32,918,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(33,918,'out',1,29,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(34,919,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(35,919,'out',2,28,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(36,920,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(37,920,'out',1,29,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(38,921,'in',30,30,'2026-11-14 02:00:00.000',102,'演练入库','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611'),(39,921,'out',2,28,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.611','2026-11-19 10:23:00.611');
/*!40000 ALTER TABLE `part_stock_movement` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `part_usage`
--

DROP TABLE IF EXISTS `part_usage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `part_usage` (
  `usage_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `work_order_id` bigint unsigned NOT NULL COMMENT '工单',
  `part_id` bigint unsigned NOT NULL COMMENT '备件',
  `qty` int unsigned NOT NULL COMMENT '领用数量',
  `used_at` datetime(3) NOT NULL COMMENT '领用时间',
  `used_by` bigint unsigned NOT NULL COMMENT '领用人',
  `note` varchar(500) DEFAULT NULL COMMENT '用途说明',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`usage_id`),
  UNIQUE KEY `uq_part_usage_order_part` (`work_order_id`,`part_id`),
  KEY `ix_part_usage_part_used_at` (`part_id`,`used_at`),
  KEY `fk_part_usage_user` (`used_by`),
  CONSTRAINT `fk_part_usage_part` FOREIGN KEY (`part_id`) REFERENCES `spare_part` (`part_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_part_usage_user` FOREIGN KEY (`used_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_part_usage_work_order` FOREIGN KEY (`work_order_id`) REFERENCES `work_order` (`work_order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_part_usage_1` CHECK ((`qty` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=935 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='备件领用';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `part_usage`
--

LOCK TABLES `part_usage` WRITE;
/*!40000 ALTER TABLE `part_usage` DISABLE KEYS */;
INSERT INTO `part_usage` VALUES (901,904,902,1,'2026-11-13 09:52:00.000',102,'更换散热风扇','2026-11-19 10:23:00.217','2026-11-19 10:23:00.217'),(902,901,901,2,'2026-11-14 01:25:00.000',102,'更换温度探头','2026-11-19 10:23:00.217','2026-11-19 10:23:00.217'),(903,1,904,1,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(904,2,905,2,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(905,3,906,1,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(906,4,907,2,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(907,5,908,1,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(908,6,909,2,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(909,7,910,1,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(910,8,911,2,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(911,9,912,1,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(912,10,913,2,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(913,11,914,1,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(914,12,915,2,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(915,13,916,1,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(916,14,917,2,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(917,15,918,1,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(918,16,919,2,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(919,17,920,1,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598'),(920,18,921,2,'2026-11-15 02:00:00.000',102,'演练领用','2026-11-19 10:23:00.598','2026-11-19 10:23:00.598');
/*!40000 ALTER TABLE `part_usage` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_part_usage_ai_stock` AFTER INSERT ON `part_usage` FOR EACH ROW begin
  update spare_part
     set stock_qty = stock_qty - new.qty
   where part_id = new.part_id
     and stock_qty >= new.qty;

  if row_count() = 0 then
    signal sqlstate '45000' set message_text = '备件库存不足，拒绝领用';
  end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `payment_record`
--

DROP TABLE IF EXISTS `payment_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_record` (
  `payment_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` bigint unsigned NOT NULL COMMENT '订单',
  `channel` varchar(32) NOT NULL COMMENT '模拟渠道或余额',
  `external_trade_no` varchar(80) NOT NULL COMMENT '渠道交易流水号',
  `amount` decimal(14,2) NOT NULL COMMENT '本次支付金额',
  `status` varchar(32) NOT NULL DEFAULT 'pending' COMMENT '支付结果',
  `paid_at` datetime(3) DEFAULT NULL COMMENT '成功支付时间',
  `bill_payment_id` bigint unsigned DEFAULT NULL COMMENT '企业月结收款来源 个人支付为空',
  `fleet_credit_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '本次支付内车队账单抵扣额 非新增现金 实收分配=amount减本列',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`payment_id`),
  UNIQUE KEY `uq_payment_record_channel_external_trade_no` (`channel`,`external_trade_no`),
  UNIQUE KEY `uq_payment_record_bill_payment_id_order_id` (`bill_payment_id`,`order_id`),
  KEY `fk_payment_record_order_id` (`order_id`),
  CONSTRAINT `fk_payment_record_bill_payment_id` FOREIGN KEY (`bill_payment_id`) REFERENCES `fleet_bill_payment` (`bill_payment_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_payment_record_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_payment_record_1` CHECK ((`amount` > 0)),
  CONSTRAINT `ck_payment_record_2` CHECK ((`fleet_credit_amount` >= 0)),
  CONSTRAINT `ck_payment_record_3` CHECK ((`fleet_credit_amount` <= `amount`)),
  CONSTRAINT `ck_payment_record_4` CHECK (((`channel` = _utf8mb4'fleet_monthly') or (`fleet_credit_amount` = 0))),
  CONSTRAINT `ck_payment_record_5` CHECK ((`channel` in (_utf8mb4'mock',_utf8mb4'wallet',_utf8mb4'fleet_monthly'))),
  CONSTRAINT `ck_payment_record_6` CHECK ((`status` in (_utf8mb4'pending',_utf8mb4'succeeded',_utf8mb4'failed')))
) ENGINE=InnoDB AUTO_INCREMENT=121 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payment_record`
--

LOCK TABLES `payment_record` WRITE;
/*!40000 ALTER TABLE `payment_record` DISABLE KEYS */;
INSERT INTO `payment_record` VALUES (1,1,'mock','FIX-P-01',6.35,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(2,2,'mock','FIX-P-02',7.20,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(3,3,'mock','FIX-P-03',8.05,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(4,4,'mock','FIX-P-04',8.90,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(5,5,'mock','FIX-P-05',9.75,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(6,6,'mock','FIX-P-06',10.60,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(7,7,'mock','FIX-P-07',11.45,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(8,8,'mock','FIX-P-08',12.30,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(9,9,'mock','FIX-P-09',13.15,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(10,10,'mock','FIX-P-10',14.00,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(11,11,'mock','FIX-P-11',14.85,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(12,12,'mock','FIX-P-12',15.70,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(13,13,'mock','FIX-P-13',16.55,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(14,14,'mock','FIX-P-14',17.40,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(15,15,'mock','FIX-P-15',18.25,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(16,16,'mock','FIX-P-16',19.10,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(17,17,'mock','FIX-P-17',19.95,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(18,18,'mock','FIX-P-18',20.80,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(19,19,'mock','FIX-P-19',21.65,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(20,20,'mock','FIX-P-20',22.50,'succeeded','2026-10-20 02:32:00.000',NULL,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(101,101,'fleet_monthly','FIX-F-01',6.75,'succeeded','2026-11-02 01:30:00.000',1,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(102,102,'fleet_monthly','FIX-F-02',7.50,'succeeded','2026-11-02 01:30:00.000',2,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(103,103,'fleet_monthly','FIX-F-03',8.25,'succeeded','2026-11-02 01:30:00.000',3,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(104,104,'fleet_monthly','FIX-F-04',9.00,'succeeded','2026-11-02 01:30:00.000',4,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(105,105,'fleet_monthly','FIX-F-05',9.75,'succeeded','2026-11-02 01:30:00.000',5,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(106,106,'fleet_monthly','FIX-F-06',10.50,'succeeded','2026-11-02 01:30:00.000',6,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(107,107,'fleet_monthly','FIX-F-07',11.25,'succeeded','2026-11-02 01:30:00.000',7,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(108,108,'fleet_monthly','FIX-F-08',12.00,'succeeded','2026-11-02 01:30:00.000',8,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(109,109,'fleet_monthly','FIX-F-09',12.75,'succeeded','2026-11-02 01:30:00.000',9,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(110,110,'fleet_monthly','FIX-F-10',13.50,'succeeded','2026-11-02 01:30:00.000',10,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(111,111,'fleet_monthly','FIX-F-11',14.25,'succeeded','2026-11-02 01:30:00.000',11,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(112,112,'fleet_monthly','FIX-F-12',15.00,'succeeded','2026-11-02 01:30:00.000',12,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(113,113,'fleet_monthly','FIX-F-13',15.75,'succeeded','2026-11-02 01:30:00.000',13,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(114,114,'fleet_monthly','FIX-F-14',16.50,'succeeded','2026-11-02 01:30:00.000',14,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(115,115,'fleet_monthly','FIX-F-15',17.25,'succeeded','2026-11-02 01:30:00.000',15,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(116,116,'fleet_monthly','FIX-F-16',18.00,'succeeded','2026-11-02 01:30:00.000',16,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(117,117,'fleet_monthly','FIX-F-17',18.75,'succeeded','2026-11-02 01:30:00.000',17,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(118,118,'fleet_monthly','FIX-F-18',19.50,'succeeded','2026-11-02 01:30:00.000',18,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(119,119,'fleet_monthly','FIX-F-19',20.25,'succeeded','2026-11-02 01:30:00.000',19,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974'),(120,120,'fleet_monthly','FIX-F-20',21.00,'succeeded','2026-11-02 01:30:00.000',20,0.00,'2026-11-19 10:22:52.974','2026-11-19 10:22:52.974');
/*!40000 ALTER TABLE `payment_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `postmortem`
--

DROP TABLE IF EXISTS `postmortem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `postmortem` (
  `postmortem_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `incident_id` bigint unsigned NOT NULL COMMENT '事件，一对一',
  `root_cause_category` varchar(32) NOT NULL COMMENT '根因类别',
  `root_cause` varchar(1000) NOT NULL COMMENT '根因描述',
  `detection_seconds` int unsigned DEFAULT NULL COMMENT '发现耗时快照',
  `response_seconds` int unsigned DEFAULT NULL COMMENT '响应耗时快照',
  `recovery_seconds` int unsigned DEFAULT NULL COMMENT '恢复耗时快照',
  `prevention` varchar(1000) DEFAULT NULL COMMENT '预防措施',
  `reviewer_account_id` bigint unsigned DEFAULT NULL COMMENT '审核账号',
  `reviewed_at` datetime(3) DEFAULT NULL COMMENT '审核时间',
  `status` varchar(16) NOT NULL DEFAULT 'draft' COMMENT '复盘状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`postmortem_id`),
  UNIQUE KEY `uq_postmortem_incident_id` (`incident_id`),
  KEY `fk_postmortem_reviewer` (`reviewer_account_id`),
  CONSTRAINT `fk_postmortem_incident` FOREIGN KEY (`incident_id`) REFERENCES `incident` (`incident_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_postmortem_reviewer` FOREIGN KEY (`reviewer_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_postmortem_1` CHECK ((`root_cause_category` in (_utf8mb4'configuration',_utf8mb4'hardware',_utf8mb4'power',_utf8mb4'network',_utf8mb4'software',_utf8mb4'process',_utf8mb4'external',_utf8mb4'unknown'))),
  CONSTRAINT `ck_postmortem_2` CHECK ((`status` in (_utf8mb4'draft',_utf8mb4'reviewed',_utf8mb4'approved'))),
  CONSTRAINT `ck_postmortem_3` CHECK (((`status` = _utf8mb4'draft') or (`reviewer_account_id` is not null)))
) ENGINE=InnoDB AUTO_INCREMENT=931 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='事件复盘';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `postmortem`
--

LOCK TABLES `postmortem` WRITE;
/*!40000 ALTER TABLE `postmortem` DISABLE KEYS */;
INSERT INTO `postmortem` VALUES (901,902,'hardware','散热风扇轴承磨损导致风量不足，模块温度持续升高触发过温保护',600,600,5400,'把风扇运行时长纳入巡检项；温度连续 10 分钟超 65℃ 提前预警；同型号风扇备件预置到站',101,'2026-11-13 03:40:00.000','approved','2026-11-19 10:23:00.194','2026-11-19 10:23:00.194'),(911,921,'power','市电切换期间配电柜短时失电',300,600,10800,'增加双路市电巡检',101,'2026-11-10 05:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(912,922,'network','通信模块掉线导致心跳中断',420,900,12600,'增加信号质量巡检项',101,'2026-11-10 06:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(913,923,'hardware','充电模块功率器件老化',360,1200,14400,'纳入季度预防性更换',101,'2026-11-10 07:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(914,924,'software','协议栈版本兼容问题',480,900,15000,'升级前做兼容测试',101,'2026-11-10 08:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(915,925,'process','证书到期提醒缺失',600,1200,16200,'建立证书到期台账',101,'2026-11-10 09:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(916,926,'external','外部停电未提前通知',300,1800,18000,'完善停电通知机制',101,'2026-11-10 10:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(917,927,'power','配电柜零线接触不良',240,600,19200,'增加接线端子紧固巡检',101,'2026-11-10 11:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(918,928,'network','弱电井信号衰耗过大',540,1200,19800,'加装信号放大器并纳入巡检',101,'2026-11-10 12:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(919,929,'hardware','枪线长期弯折导致破皮',300,900,20400,'规范枪线收纳',101,'2026-11-10 13:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(920,930,'software','计费上报队列积压',600,1500,21000,'增加队列积压告警',101,'2026-11-10 14:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(921,931,'process','异常登录检测规则缺失',300,600,21600,'补齐安全告警规则',101,'2026-11-10 15:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(922,932,'hardware','地锁机械结构松脱',420,1800,22200,'加装防松垫片',101,'2026-11-10 16:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(923,933,'power','浪涌保护器件寿命到期',360,900,22800,'建立浪涌器件更换周期',101,'2026-11-10 17:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(924,934,'network','交换机端口氧化',480,1200,23400,'定期清洁端口',101,'2026-11-10 18:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(925,935,'hardware','散热风扇轴承磨损',300,900,24000,'纳入季度更换计划',101,'2026-11-10 19:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(926,936,'configuration','NTP 配置被覆盖',600,1500,24600,'配置变更留痕并复核',101,'2026-11-10 20:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(927,937,'process','固件版本基线未同步',420,1800,25200,'建立固件基线清单',101,'2026-11-10 21:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(928,938,'unknown','标识牌固定件缺失',300,3600,25800,'巡检增加标识检查',101,'2026-11-10 22:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(929,939,'power','雷击引发浪涌保护动作',240,600,26400,'增加雷雨季专项巡检',101,'2026-11-10 23:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553'),(930,940,'network','交换机端口模块损坏',360,1200,27000,'备件预置到站',101,'2026-11-11 00:00:00.000','approved','2026-11-19 10:23:00.553','2026-11-19 10:23:00.553');
/*!40000 ALTER TABLE `postmortem` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pricing_period`
--

DROP TABLE IF EXISTS `pricing_period`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pricing_period` (
  `period_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `rule_id` bigint unsigned NOT NULL COMMENT '所属规则',
  `period_type` varchar(32) NOT NULL COMMENT '峰平谷',
  `start_minute` smallint unsigned NOT NULL COMMENT '上海当天起始分钟 0至1439',
  `end_minute` smallint unsigned NOT NULL COMMENT '上海当天结束分钟 1至1440',
  `electricity_rate` decimal(12,4) NOT NULL COMMENT '电价 元每kWh',
  `service_rate` decimal(12,4) NOT NULL COMMENT '服务费单价 元每kWh',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`period_id`),
  UNIQUE KEY `uq_pricing_period_rule_id_start_minute` (`rule_id`,`start_minute`),
  CONSTRAINT `fk_pricing_period_rule_id` FOREIGN KEY (`rule_id`) REFERENCES `pricing_rule` (`rule_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_pricing_period_1` CHECK ((`start_minute` < `end_minute`)),
  CONSTRAINT `ck_pricing_period_2` CHECK ((`end_minute` <= 1440)),
  CONSTRAINT `ck_pricing_period_3` CHECK ((`electricity_rate` >= 0)),
  CONSTRAINT `ck_pricing_period_4` CHECK ((`service_rate` >= 0)),
  CONSTRAINT `ck_pricing_period_5` CHECK ((`period_type` in (_utf8mb4'peak',_utf8mb4'flat',_utf8mb4'valley')))
) ENGINE=InnoDB AUTO_INCREMENT=205 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pricing_period`
--

LOCK TABLES `pricing_period` WRITE;
/*!40000 ALTER TABLE `pricing_period` DISABLE KEYS */;
INSERT INTO `pricing_period` VALUES (11,1,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(12,1,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(13,1,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(14,1,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(21,2,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(22,2,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(23,2,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(24,2,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(31,3,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(32,3,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(33,3,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(34,3,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(41,4,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(42,4,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(43,4,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(44,4,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(51,5,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(52,5,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(53,5,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(54,5,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(61,6,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(62,6,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(63,6,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(64,6,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(71,7,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(72,7,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(73,7,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(74,7,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(81,8,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(82,8,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(83,8,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(84,8,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(91,9,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(92,9,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(93,9,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(94,9,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(101,10,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(102,10,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(103,10,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(104,10,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(111,11,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(112,11,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(113,11,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(114,11,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(121,12,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(122,12,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(123,12,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(124,12,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(131,13,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(132,13,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(133,13,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(134,13,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(141,14,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(142,14,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(143,14,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(144,14,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(151,15,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(152,15,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(153,15,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(154,15,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(161,16,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(162,16,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(163,16,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(164,16,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(171,17,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(172,17,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(173,17,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(174,17,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(181,18,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(182,18,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(183,18,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(184,18,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(191,19,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(192,19,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(193,19,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(194,19,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(201,20,'valley',0,480,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(202,20,'flat',480,1080,0.6000,0.2500,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(203,20,'peak',1080,1320,0.8000,0.3000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932'),(204,20,'valley',1320,1440,0.4000,0.2000,'2026-11-19 10:22:52.932','2026-11-19 10:22:52.932');
/*!40000 ALTER TABLE `pricing_period` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pricing_review`
--

DROP TABLE IF EXISTS `pricing_review`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pricing_review` (
  `review_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '审批记录主键',
  `rule_id` bigint unsigned DEFAULT NULL COMMENT '普通计费规则草稿；与price_id二选一',
  `price_id` bigint unsigned DEFAULT NULL COMMENT '车队专价草稿；与rule_id二选一',
  `requested_by` bigint unsigned NOT NULL COMMENT '申请账号',
  `requested_at` datetime(3) NOT NULL COMMENT '申请时间',
  `decision` varchar(32) NOT NULL DEFAULT 'pending' COMMENT '审批状态',
  `reviewed_by` bigint unsigned DEFAULT NULL COMMENT '审批账号；禁止自批',
  `reviewed_at` datetime(3) DEFAULT NULL COMMENT '审批时间',
  `review_note` varchar(1000) DEFAULT NULL COMMENT '审批意见',
  `content_hash` binary(32) NOT NULL COMMENT '服务器计算方案快照SHA256；审批前再次比对',
  `target_snapshot` json NOT NULL COMMENT '服务器生成的普通规则及其时段或专价完整快照，客户端不能自由覆盖',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC修改时间',
  `pending_target_key` varchar(100) GENERATED ALWAYS AS ((case when (`decision` = _utf8mb4'pending') then concat(if((`rule_id` is not null),_utf8mb4'rule:',_utf8mb4'fleet:'),coalesce(`rule_id`,`price_id`)) else NULL end)) STORED COMMENT '一个价格目标最多一条待审批记录',
  PRIMARY KEY (`review_id`),
  UNIQUE KEY `uq_pricing_review_pending_target_key` (`pending_target_key`),
  KEY `ix_pricing_review_requested_by_requested_at` (`requested_by`,`requested_at`),
  KEY `fk_pricing_review_rule_id` (`rule_id`),
  KEY `fk_pricing_review_price_id` (`price_id`),
  KEY `fk_pricing_review_reviewed_by` (`reviewed_by`),
  CONSTRAINT `fk_pricing_review_price_id` FOREIGN KEY (`price_id`) REFERENCES `fleet_price` (`price_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_pricing_review_requested_by` FOREIGN KEY (`requested_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_pricing_review_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_pricing_review_rule_id` FOREIGN KEY (`rule_id`) REFERENCES `pricing_rule` (`rule_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_pricing_review_1` CHECK ((`decision` in (_utf8mb4'pending',_utf8mb4'approved',_utf8mb4'rejected'))),
  CONSTRAINT `ck_pricing_review_2` CHECK ((((`rule_id` is not null) + (`price_id` is not null)) = 1)),
  CONSTRAINT `ck_pricing_review_3` CHECK (((`reviewed_by` is null) or (`reviewed_by` <> `requested_by`))),
  CONSTRAINT `ck_pricing_review_4` CHECK ((((`decision` = _utf8mb4'pending') and (`reviewed_by` is null) and (`reviewed_at` is null)) or ((`decision` in (_utf8mb4'approved',_utf8mb4'rejected')) and (`reviewed_by` is not null) and (`reviewed_at` is not null))))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pricing_review`
--

LOCK TABLES `pricing_review` WRITE;
/*!40000 ALTER TABLE `pricing_review` DISABLE KEYS */;
INSERT INTO `pricing_review` (`review_id`, `rule_id`, `price_id`, `requested_by`, `requested_at`, `decision`, `reviewed_by`, `reviewed_at`, `review_note`, `content_hash`, `target_snapshot`, `created_at`, `updated_at`) VALUES (1,1,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '_���J�~~ͺQ��v\0c\"Q\�\�\�\�t�@U\�w','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 1, \"rule_name\": \"场站01峰平谷\", \"station_id\": 1, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(2,2,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '��\�9R��B\�*~��\�\�m\�%rR\�l\�ʪH�iU+�','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 2, \"rule_name\": \"场站02峰平谷\", \"station_id\": 2, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(3,3,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '�v\�,\�\�3�b\�\�.Y\�D\�/�3<��\��p3\�#','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 3, \"rule_name\": \"场站03峰平谷\", \"station_id\": 3, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(4,4,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary 'g}\�\�|Der�\�;Z=\�.\'�[ؿ\�\�\�;\�R\�\�','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 4, \"rule_name\": \"场站04峰平谷\", \"station_id\": 4, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(5,5,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '*i>�g�s\�l����ۇPW5\�-nu\�>Q�v�','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 5, \"rule_name\": \"场站05峰平谷\", \"station_id\": 5, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(6,6,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '�٫��\�:�S��f\�5�5CE{.\�ƿ̅q(Ӗ','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 6, \"rule_name\": \"场站06峰平谷\", \"station_id\": 6, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(7,7,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '�(�b\�BhK�j/P�Ě*\�\�j2a\�qY�\�\�\ZI','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 7, \"rule_name\": \"场站07峰平谷\", \"station_id\": 7, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(8,8,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '��عF}k}�\0T\�\�<�\�\�;\�����\�{R=','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 8, \"rule_name\": \"场站08峰平谷\", \"station_id\": 8, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(9,9,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary 'xTZ�eY��\���\�\�\�AE\"\�g1�\�\��(','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 9, \"rule_name\": \"场站09峰平谷\", \"station_id\": 9, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(10,10,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '�\�ޓ��\�\��j�E\�J\�\�=t#\�:p��0o\�\� \�','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 10, \"rule_name\": \"场站10峰平谷\", \"station_id\": 10, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(11,11,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '}\�\�.\�c�o�1E�(\�^bX\��]�NY	6�L\")','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 11, \"rule_name\": \"场站11峰平谷\", \"station_id\": 11, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(12,12,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '=��&�t�(!Nd7�\�\���Y�\�\r�>\�\��Ȓ\�r','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 12, \"rule_name\": \"场站12峰平谷\", \"station_id\": 12, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(13,13,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '6O�I�y\�\�3Vϵ\�7\�u\0��\�\�X��\rۡ%�','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 13, \"rule_name\": \"场站13峰平谷\", \"station_id\": 13, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(14,14,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '���)\�\�Z�ȝh	X�%�\�DG��05o.I','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 14, \"rule_name\": \"场站14峰平谷\", \"station_id\": 14, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(15,15,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '�Y\�\�Q\�\"(U˯\��z:\"�^\�vv\�\�}�`\�\0)','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 15, \"rule_name\": \"场站15峰平谷\", \"station_id\": 15, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(16,16,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '_\�h��\�\��\Z_\'��tH��RnC{e]}�?\�','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 16, \"rule_name\": \"场站16峰平谷\", \"station_id\": 16, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(17,17,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary 'HS\�\���Fm,s\�R\�\�\�&\�u#2@Zn=!?A]�','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 17, \"rule_name\": \"场站17峰平谷\", \"station_id\": 17, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(18,18,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '���\� �p\�AL\�L\�Q&H��^\�\�)�MQ�K\�t','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 18, \"rule_name\": \"场站18峰平谷\", \"station_id\": 18, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(19,19,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '�Y�xٟ#���Q���iQv�vW��\�w�W�\�@\� 0','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 19, \"rule_name\": \"场站19峰平谷\", \"station_id\": 19, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987'),(20,20,NULL,103,'2026-09-29 09:00:00.000','approved',101,'2026-09-30 08:00:00.000',NULL,_binary '/\�:��fs�\�w\�U�n/.OA�	\0\�J7\�ɍ','{\"periods\": [{\"end_minute\": 480, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 0, \"electricity_rate\": \".40\"}, {\"end_minute\": 1080, \"period_type\": \"flat\", \"service_rate\": \".25\", \"start_minute\": 480, \"electricity_rate\": \".60\"}, {\"end_minute\": 1320, \"period_type\": \"peak\", \"service_rate\": \".30\", \"start_minute\": 1080, \"electricity_rate\": \".80\"}, {\"end_minute\": 1440, \"period_type\": \"valley\", \"service_rate\": \".20\", \"start_minute\": 1320, \"electricity_rate\": \".40\"}], \"rule_id\": 20, \"rule_name\": \"场站20峰平谷\", \"station_id\": 20, \"valid_from\": \"2026-09-30 16:00:00\", \"valid_until\": \"2027-01-31 16:00:00\", \"minimum_amount\": \"0.00\", \"free_service_minutes\": 0}','2026-11-19 10:22:52.987','2026-11-19 10:22:52.987');
/*!40000 ALTER TABLE `pricing_review` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pricing_rule`
--

DROP TABLE IF EXISTS `pricing_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pricing_rule` (
  `rule_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `station_id` bigint unsigned NOT NULL COMMENT '场站',
  `rule_name` varchar(100) NOT NULL COMMENT '规则名称',
  `free_service_minutes` int unsigned NOT NULL DEFAULT '0' COMMENT '免服务费分钟数',
  `minimum_amount` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '起步金额',
  `valid_from` datetime(3) NOT NULL COMMENT '生效UTC时间',
  `valid_until` datetime(3) NOT NULL COMMENT '失效UTC时间',
  `status` varchar(32) NOT NULL DEFAULT 'draft' COMMENT '规则状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`rule_id`),
  KEY `ix_pricing_rule_station_id_valid_from` (`station_id`,`valid_from`),
  CONSTRAINT `fk_pricing_rule_station_id` FOREIGN KEY (`station_id`) REFERENCES `station` (`station_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_pricing_rule_1` CHECK ((`valid_until` > `valid_from`)),
  CONSTRAINT `ck_pricing_rule_2` CHECK ((`minimum_amount` >= 0)),
  CONSTRAINT `ck_pricing_rule_3` CHECK ((`status` in (_utf8mb4'draft',_utf8mb4'active',_utf8mb4'disabled')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pricing_rule`
--

LOCK TABLES `pricing_rule` WRITE;
/*!40000 ALTER TABLE `pricing_rule` DISABLE KEYS */;
INSERT INTO `pricing_rule` VALUES (1,1,'场站01峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(2,2,'场站02峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(3,3,'场站03峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(4,4,'场站04峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(5,5,'场站05峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(6,6,'场站06峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(7,7,'场站07峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(8,8,'场站08峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(9,9,'场站09峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(10,10,'场站10峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(11,11,'场站11峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(12,12,'场站12峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(13,13,'场站13峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(14,14,'场站14峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(15,15,'场站15峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(16,16,'场站16峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(17,17,'场站17峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(18,18,'场站18峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(19,19,'场站19峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917'),(20,20,'场站20峰平谷',0,0.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','active','2026-11-19 10:22:52.917','2026-11-19 10:22:52.917');
/*!40000 ALTER TABLE `pricing_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `promotion`
--

DROP TABLE IF EXISTS `promotion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promotion` (
  `promotion_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `promotion_name` varchar(100) NOT NULL COMMENT '活动名称',
  `face_amount` decimal(14,2) NOT NULL COMMENT '券面额',
  `minimum_spend` decimal(14,2) NOT NULL DEFAULT '0.00' COMMENT '使用门槛',
  `valid_from` datetime(3) NOT NULL COMMENT '有效起始',
  `valid_until` datetime(3) NOT NULL COMMENT '有效截止',
  `issue_limit` int unsigned NOT NULL COMMENT '发放上限',
  `issued_count` int unsigned NOT NULL DEFAULT '0' COMMENT '已发数量 持锁更新',
  `per_user_limit` int unsigned NOT NULL DEFAULT '1' COMMENT '每用户领取上限',
  `all_stations` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '1适用全场站 0读关联表',
  `redemption_rule` varchar(500) NOT NULL DEFAULT '个人订单满额抵扣' COMMENT '核销说明',
  `status` varchar(32) NOT NULL DEFAULT 'draft' COMMENT '活动审核状态',
  `created_by` bigint unsigned NOT NULL COMMENT '创建账号',
  `reviewed_by` bigint unsigned DEFAULT NULL COMMENT '审核账号',
  `reviewed_at` datetime(3) DEFAULT NULL COMMENT '审核时间',
  `review_note` varchar(500) DEFAULT NULL COMMENT '审核意见',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`promotion_id`),
  KEY `fk_promotion_created_by` (`created_by`),
  KEY `fk_promotion_reviewed_by` (`reviewed_by`),
  CONSTRAINT `fk_promotion_created_by` FOREIGN KEY (`created_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_promotion_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_promotion_1` CHECK ((`face_amount` > 0)),
  CONSTRAINT `ck_promotion_2` CHECK ((`minimum_spend` >= 0)),
  CONSTRAINT `ck_promotion_3` CHECK ((`issued_count` <= `issue_limit`)),
  CONSTRAINT `ck_promotion_4` CHECK ((`valid_until` > `valid_from`)),
  CONSTRAINT `ck_promotion_5` CHECK ((`all_stations` in (0,1))),
  CONSTRAINT `ck_promotion_6` CHECK ((`status` in (_utf8mb4'draft',_utf8mb4'pending_review',_utf8mb4'active',_utf8mb4'rejected',_utf8mb4'disabled')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `promotion`
--

LOCK TABLES `promotion` WRITE;
/*!40000 ALTER TABLE `promotion` DISABLE KEYS */;
INSERT INTO `promotion` VALUES (1,'演示场站01满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,2,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(2,'演示场站02满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(3,'演示场站03满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(4,'演示场站04满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(5,'演示场站05满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(6,'演示场站06满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(7,'演示场站07满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(8,'演示场站08满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(9,'演示场站09满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(10,'演示场站10满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(11,'演示场站11满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(12,'演示场站12满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(13,'演示场站13满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(14,'演示场站14满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(15,'演示场站15满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(16,'演示场站16满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(17,'演示场站17满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(18,'演示场站18满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(19,'演示场站19满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898'),(20,'演示场站20满8减3',3.00,8.00,'2026-09-30 16:00:00.000','2027-01-31 16:00:00.000',100,1,2,0,'个人订单满额抵扣','active',103,101,'2026-09-30 08:00:00.000',NULL,'2026-11-19 10:22:52.898','2026-11-19 10:22:52.898');
/*!40000 ALTER TABLE `promotion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `promotion_station`
--

DROP TABLE IF EXISTS `promotion_station`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promotion_station` (
  `promotion_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `station_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`promotion_id`,`station_id`),
  KEY `fk_promotion_station_station_id` (`station_id`),
  CONSTRAINT `fk_promotion_station_promotion_id` FOREIGN KEY (`promotion_id`) REFERENCES `promotion` (`promotion_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_promotion_station_station_id` FOREIGN KEY (`station_id`) REFERENCES `station` (`station_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `promotion_station`
--

LOCK TABLES `promotion_station` WRITE;
/*!40000 ALTER TABLE `promotion_station` DISABLE KEYS */;
INSERT INTO `promotion_station` VALUES (1,1,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(2,2,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(3,3,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(4,4,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(5,5,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(6,6,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(7,7,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(8,8,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(9,9,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(10,10,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(11,11,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(12,12,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(13,13,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(14,14,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(15,15,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(16,16,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(17,17,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(18,18,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(19,19,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(20,20,'2026-11-19 10:22:52.923','2026-11-19 10:22:52.923');
/*!40000 ALTER TABLE `promotion_station` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reconciliation_confirmation`
--

DROP TABLE IF EXISTS `reconciliation_confirmation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reconciliation_confirmation` (
  `confirmation_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `settlement_id` bigint unsigned DEFAULT NULL COMMENT '确认结算单',
  `difference_id` bigint unsigned DEFAULT NULL COMMENT '确认差异',
  `object_version` int unsigned NOT NULL COMMENT '对象版本',
  `side` varchar(32) NOT NULL COMMENT '后端推导确认方',
  `decision` varchar(32) NOT NULL COMMENT '同意或异议',
  `confirmed_by` bigint unsigned NOT NULL COMMENT '操作账号',
  `confirmed_at` datetime(3) NOT NULL COMMENT '确认时间',
  `note` varchar(1000) DEFAULT NULL COMMENT '意见',
  `is_current` tinyint unsigned NOT NULL DEFAULT '1' COMMENT '本版本本方当前有效结果',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  `current_key` varchar(120) GENERATED ALWAYS AS ((case when (`is_current` = 1) then concat(if((`settlement_id` is not null),_utf8mb4'S',_utf8mb4'D'),_utf8mb4':',coalesce(`settlement_id`,`difference_id`),_utf8mb4':',`object_version`,_utf8mb4':',`side`) else NULL end)) STORED COMMENT '当前对象版本确认方唯一',
  PRIMARY KEY (`confirmation_id`),
  UNIQUE KEY `uq_reconciliation_confirmation_current_key` (`current_key`),
  KEY `fk_reconciliation_confirmation_settlement_id` (`settlement_id`),
  KEY `fk_reconciliation_confirmation_difference_id` (`difference_id`),
  KEY `fk_reconciliation_confirmation_confirmed_by` (`confirmed_by`),
  CONSTRAINT `fk_reconciliation_confirmation_confirmed_by` FOREIGN KEY (`confirmed_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_reconciliation_confirmation_difference_id` FOREIGN KEY (`difference_id`) REFERENCES `reconciliation_difference` (`difference_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_reconciliation_confirmation_settlement_id` FOREIGN KEY (`settlement_id`) REFERENCES `operator_settlement` (`settlement_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_reconciliation_confirmation_1` CHECK ((((`settlement_id` is not null) + (`difference_id` is not null)) = 1)),
  CONSTRAINT `ck_reconciliation_confirmation_2` CHECK ((`object_version` > 0)),
  CONSTRAINT `ck_reconciliation_confirmation_3` CHECK ((`side` in (_utf8mb4'platform',_utf8mb4'operator'))),
  CONSTRAINT `ck_reconciliation_confirmation_4` CHECK ((`decision` in (_utf8mb4'confirmed',_utf8mb4'disputed'))),
  CONSTRAINT `ck_reconciliation_confirmation_5` CHECK ((`is_current` in (0,1)))
) ENGINE=InnoDB AUTO_INCREMENT=321 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reconciliation_confirmation`
--

LOCK TABLES `reconciliation_confirmation` WRITE;
/*!40000 ALTER TABLE `reconciliation_confirmation` DISABLE KEYS */;
INSERT INTO `reconciliation_confirmation` (`confirmation_id`, `settlement_id`, `difference_id`, `object_version`, `side`, `decision`, `confirmed_by`, `confirmed_at`, `note`, `is_current`, `created_at`, `updated_at`) VALUES (1,NULL,1,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(2,NULL,2,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(3,NULL,3,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(4,NULL,4,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(5,NULL,5,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(6,NULL,6,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(7,NULL,7,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(8,NULL,8,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(9,NULL,9,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(10,NULL,10,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(11,NULL,11,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(12,NULL,12,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(13,NULL,13,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(14,NULL,14,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(15,NULL,15,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(16,NULL,16,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(17,NULL,17,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(18,NULL,18,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(19,NULL,19,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(20,NULL,20,1,'platform','confirmed',101,'2026-11-02 03:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(101,NULL,1,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(102,NULL,2,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(103,NULL,3,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(104,NULL,4,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(105,NULL,5,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(106,NULL,6,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(107,NULL,7,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(108,NULL,8,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(109,NULL,9,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(110,NULL,10,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(111,NULL,11,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(112,NULL,12,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(113,NULL,13,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(114,NULL,14,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(115,NULL,15,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(116,NULL,16,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(117,NULL,17,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(118,NULL,18,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(119,NULL,19,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(120,NULL,20,1,'operator','confirmed',106,'2026-11-02 03:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(201,1,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(202,2,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(203,3,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(204,4,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(205,5,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(206,6,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(207,7,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(208,8,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(209,9,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(210,10,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(211,11,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(212,12,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(213,13,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(214,14,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(215,15,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(216,16,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(217,17,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(218,18,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(219,19,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(220,20,NULL,2,'platform','confirmed',101,'2026-11-02 04:00:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(301,1,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(302,2,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(303,3,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(304,4,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(305,5,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(306,6,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(307,7,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(308,8,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(309,9,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(310,10,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(311,11,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(312,12,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(313,13,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(314,14,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(315,15,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(316,16,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(317,17,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(318,18,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(319,19,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003'),(320,20,NULL,2,'operator','confirmed',106,'2026-11-02 04:05:00.000',NULL,1,'2026-11-19 10:22:53.003','2026-11-19 10:22:53.003');
/*!40000 ALTER TABLE `reconciliation_confirmation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reconciliation_difference`
--

DROP TABLE IF EXISTS `reconciliation_difference`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reconciliation_difference` (
  `difference_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `settlement_id` bigint unsigned NOT NULL COMMENT '所属结算单',
  `order_id` bigint unsigned NOT NULL COMMENT '具体订单',
  `difference_type` varchar(32) NOT NULL COMMENT '电量不符 价格不符 支付问题',
  `amount` decimal(14,2) NOT NULL COMMENT '差异金额 可正负',
  `resolution` varchar(1000) DEFAULT NULL COMMENT '处理结论',
  `status` varchar(32) NOT NULL DEFAULT 'open' COMMENT '生效状态',
  `version` int unsigned NOT NULL DEFAULT '1' COMMENT '结论版本',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`difference_id`),
  KEY `fk_reconciliation_difference_settlement_id` (`settlement_id`),
  KEY `fk_reconciliation_difference_order_id` (`order_id`),
  CONSTRAINT `fk_reconciliation_difference_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_reconciliation_difference_settlement_id` FOREIGN KEY (`settlement_id`) REFERENCES `operator_settlement` (`settlement_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_reconciliation_difference_1` CHECK ((`version` > 0)),
  CONSTRAINT `ck_reconciliation_difference_2` CHECK ((`difference_type` in (_utf8mb4'energy',_utf8mb4'price',_utf8mb4'payment'))),
  CONSTRAINT `ck_reconciliation_difference_3` CHECK ((`status` in (_utf8mb4'open',_utf8mb4'pending_confirmation',_utf8mb4'effective',_utf8mb4'rejected')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reconciliation_difference`
--

LOCK TABLES `reconciliation_difference` WRITE;
/*!40000 ALTER TABLE `reconciliation_difference` DISABLE KEYS */;
INSERT INTO `reconciliation_difference` VALUES (1,1,1,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(2,2,2,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(3,3,3,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(4,4,4,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(5,5,5,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(6,6,6,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(7,7,7,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(8,8,8,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(9,9,9,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(10,10,10,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(11,11,11,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(12,12,12,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(13,13,13,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(14,14,14,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(15,15,15,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(16,16,16,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(17,17,17,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(18,18,18,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(19,19,19,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985'),(20,20,20,'price',-0.20,'双方同意调减0.20元','effective',1,'2026-11-19 10:22:52.985','2026-11-19 10:22:52.985');
/*!40000 ALTER TABLE `reconciliation_difference` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refund_record`
--

DROP TABLE IF EXISTS `refund_record`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refund_record` (
  `refund_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `payment_id` bigint unsigned NOT NULL COMMENT '原支付流水',
  `external_refund_no` varchar(80) NOT NULL COMMENT '本系统全局唯一退款流水',
  `amount` decimal(14,2) NOT NULL COMMENT '退款金额',
  `status` varchar(32) NOT NULL DEFAULT 'pending' COMMENT '退款结果',
  `refunded_at` datetime(3) DEFAULT NULL COMMENT '退款成功时间',
  `reason` varchar(500) NOT NULL COMMENT '退款原因',
  `requested_by` bigint unsigned NOT NULL COMMENT '办理账号',
  `settlement_method` varchar(32) NOT NULL DEFAULT 'original' COMMENT 'original原路模拟退款；fleet_credit只抵后续账单，不再现金退',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`refund_id`),
  UNIQUE KEY `uq_refund_record_external_refund_no` (`external_refund_no`),
  KEY `fk_refund_record_payment_id` (`payment_id`),
  KEY `fk_refund_record_requested_by` (`requested_by`),
  CONSTRAINT `fk_refund_record_payment_id` FOREIGN KEY (`payment_id`) REFERENCES `payment_record` (`payment_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_refund_record_requested_by` FOREIGN KEY (`requested_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_refund_record_1` CHECK ((`amount` > 0)),
  CONSTRAINT `ck_refund_record_2` CHECK ((`status` in (_utf8mb4'pending',_utf8mb4'succeeded',_utf8mb4'failed'))),
  CONSTRAINT `ck_refund_record_3` CHECK ((`settlement_method` in (_utf8mb4'original',_utf8mb4'fleet_credit')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refund_record`
--

LOCK TABLES `refund_record` WRITE;
/*!40000 ALTER TABLE `refund_record` DISABLE KEYS */;
INSERT INTO `refund_record` VALUES (1,1,'FIX-REF-01',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(2,2,'FIX-REF-02',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(3,3,'FIX-REF-03',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(4,4,'FIX-REF-04',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(5,5,'FIX-REF-05',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(6,6,'FIX-REF-06',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(7,7,'FIX-REF-07',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(8,8,'FIX-REF-08',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(9,9,'FIX-REF-09',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(10,10,'FIX-REF-10',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(11,11,'FIX-REF-11',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(12,12,'FIX-REF-12',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(13,13,'FIX-REF-13',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(14,14,'FIX-REF-14',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(15,15,'FIX-REF-15',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(16,16,'FIX-REF-16',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(17,17,'FIX-REF-17',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(18,18,'FIX-REF-18',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(19,19,'FIX-REF-19',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996'),(20,20,'FIX-REF-20',0.50,'pending',NULL,'待复核的模拟退款',103,'original','2026-11-19 10:22:52.996','2026-11-19 10:22:52.996');
/*!40000 ALTER TABLE `refund_record` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `request_dedup`
--

DROP TABLE IF EXISTS `request_dedup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `request_dedup` (
  `dedup_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `account_id` bigint unsigned NOT NULL COMMENT '调用账号',
  `operation` varchar(100) NOT NULL COMMENT '模块函数名',
  `idempotency_key` varchar(64) NOT NULL COMMENT '客户端重试键',
  `request_hash` binary(32) NOT NULL COMMENT '规范化请求摘要',
  `response_status` smallint unsigned DEFAULT NULL COMMENT '已完成HTTP状态',
  `response_body` json DEFAULT NULL COMMENT '可重放脱敏结果',
  `status` varchar(32) NOT NULL DEFAULT 'processing' COMMENT '处理状态',
  `expires_at` datetime(3) NOT NULL COMMENT '过期清理时间',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`dedup_id`),
  UNIQUE KEY `uq_request_dedup_account_id_operation_idempotency_key` (`account_id`,`operation`,`idempotency_key`),
  CONSTRAINT `fk_request_dedup_account_id` FOREIGN KEY (`account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_request_dedup_1` CHECK ((`status` in (_utf8mb4'processing',_utf8mb4'completed')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `request_dedup`
--

LOCK TABLES `request_dedup` WRITE;
/*!40000 ALTER TABLE `request_dedup` DISABLE KEYS */;
INSERT INTO `request_dedup` VALUES (1,1001,'start_charging','fixture-order-1',_binary '�4W3��{���\�(�\��-D+2)��I&_N\��.',201,'{\"order_id\": \"1\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(2,1002,'start_charging','fixture-order-2',_binary '4P��\�s\�2�\�\0&&\�+݆J��\�z}\Zq\"',201,'{\"order_id\": \"2\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(3,1003,'start_charging','fixture-order-3',_binary '�\���1�¤H�^�\��\�\�\r\�\�&q�\�@\��	�',201,'{\"order_id\": \"3\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(4,1004,'start_charging','fixture-order-4',_binary '\�F��O1Q��k\�\�\�BEg\��\�~�\�JW�1\�',201,'{\"order_id\": \"4\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(5,1005,'start_charging','fixture-order-5',_binary '\\A[\�b[an=H�jd\�=,̓w�#\� �\�\�e�\r',201,'{\"order_id\": \"5\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(6,1006,'start_charging','fixture-order-6',_binary '��N��H+�+%�\Z\��;˘*I\�\"�\�P�;-�l',201,'{\"order_id\": \"6\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(7,1007,'start_charging','fixture-order-7',_binary '�T�\�n608.Z9lpV\�J\�W5͓�vը��',201,'{\"order_id\": \"7\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(8,1008,'start_charging','fixture-order-8',_binary '\�\�\�\"q\�?e�*#\rU�\�\'ذU\���\�@��VƳ�',201,'{\"order_id\": \"8\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(9,1009,'start_charging','fixture-order-9',_binary '\���e�E\�F����ݘ���6\�\�,j=��]�ˆ�',201,'{\"order_id\": \"9\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(10,1010,'start_charging','fixture-order-10',_binary '��f�J\�`\�J\�4L�\�6\�T�2\�s\�(qî',201,'{\"order_id\": \"10\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(11,1011,'start_charging','fixture-order-11',_binary '�5�5\"\���\�	\�\\\�rk`Qܖ1P�g�ij6',201,'{\"order_id\": \"11\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(12,1012,'start_charging','fixture-order-12',_binary '\�\�f\�1\��\��?({K\�+w\�[�\�T\�@�\�O^h6',201,'{\"order_id\": \"12\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(13,1013,'start_charging','fixture-order-13',_binary '\\��	O\�\�.̕\�m\�\�\\$\�|\�\�\�W��\�=���?',201,'{\"order_id\": \"13\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(14,1014,'start_charging','fixture-order-14',_binary '\�:%-I�\�\�8�F\�1�sm.��.�����T�J',201,'{\"order_id\": \"14\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(15,1015,'start_charging','fixture-order-15',_binary '\\V��\�\����n\'�rWf\�b\�y�M\�\�\"\�D׎\��',201,'{\"order_id\": \"15\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(16,1016,'start_charging','fixture-order-16',_binary 's:�{@�編\�\�\�%Pt.@F�䇱:�l��\�\�=',201,'{\"order_id\": \"16\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(17,1017,'start_charging','fixture-order-17',_binary 't=\�\"���Ȃ\�~F2�\�]�)\�J��[�q�',201,'{\"order_id\": \"17\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(18,1018,'start_charging','fixture-order-18',_binary '�\�h�\��G�q\'R�C%6����\�=_�\�[\r8\�\�A',201,'{\"order_id\": \"18\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(19,1019,'start_charging','fixture-order-19',_binary '\�\�C��\�{;9��]\r�\�:1w\'\�HHbB��ޓg��',201,'{\"order_id\": \"19\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913'),(20,1020,'start_charging','fixture-order-20',_binary 'D�Vr��S�5�mӥ\�Aa!��&��\�wt\�',201,'{\"order_id\": \"20\"}','completed','2026-10-20 23:00:00.000','2026-11-19 10:22:52.913','2026-11-19 10:22:52.913');
/*!40000 ALTER TABLE `request_dedup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service_feedback`
--

DROP TABLE IF EXISTS `service_feedback`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_feedback` (
  `feedback_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `order_id` bigint unsigned NOT NULL COMMENT '被评价订单',
  `user_id` bigint unsigned NOT NULL COMMENT '评价人',
  `rating` tinyint unsigned NOT NULL COMMENT '1至5分',
  `content` varchar(1000) DEFAULT NULL COMMENT '评价内容',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`feedback_id`),
  UNIQUE KEY `uq_service_feedback_order_id` (`order_id`),
  KEY `fk_service_feedback_user_id` (`user_id`),
  CONSTRAINT `fk_service_feedback_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_service_feedback_user_id` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_service_feedback_1` CHECK ((`rating` between 1 and 5))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service_feedback`
--

LOCK TABLES `service_feedback` WRITE;
/*!40000 ALTER TABLE `service_feedback` DISABLE KEYS */;
INSERT INTO `service_feedback` VALUES (1,1,1,5,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(2,2,2,4,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(3,3,3,5,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(4,4,4,4,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(5,5,5,5,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(6,6,6,4,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(7,7,7,5,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(8,8,8,4,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(9,9,9,5,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(10,10,10,4,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(11,11,11,5,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(12,12,12,4,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(13,13,13,5,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(14,14,14,4,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(15,15,15,5,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(16,16,16,4,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(17,17,17,5,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(18,18,18,4,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(19,19,19,5,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984'),(20,20,20,4,'历史充电评价','2026-11-19 10:22:52.984','2026-11-19 10:22:52.984');
/*!40000 ALTER TABLE `service_feedback` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `settlement_adjustment`
--

DROP TABLE IF EXISTS `settlement_adjustment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `settlement_adjustment` (
  `adjustment_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `settlement_id` bigint unsigned NOT NULL COMMENT '结算单',
  `difference_id` bigint unsigned DEFAULT NULL COMMENT '来源差异',
  `amount` decimal(14,2) NOT NULL COMMENT '调整金额 可正负',
  `reason` varchar(1000) NOT NULL COMMENT '依据',
  `status` varchar(32) NOT NULL DEFAULT 'pending' COMMENT '审批状态',
  `requested_by` bigint unsigned NOT NULL COMMENT '发起人',
  `approved_by` bigint unsigned DEFAULT NULL COMMENT '审批人',
  `approved_at` datetime(3) DEFAULT NULL COMMENT '生效审批时间',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`adjustment_id`),
  KEY `fk_settlement_adjustment_settlement_id` (`settlement_id`),
  KEY `fk_settlement_adjustment_difference_id` (`difference_id`),
  KEY `fk_settlement_adjustment_requested_by` (`requested_by`),
  KEY `fk_settlement_adjustment_approved_by` (`approved_by`),
  CONSTRAINT `fk_settlement_adjustment_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlement_adjustment_difference_id` FOREIGN KEY (`difference_id`) REFERENCES `reconciliation_difference` (`difference_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlement_adjustment_requested_by` FOREIGN KEY (`requested_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlement_adjustment_settlement_id` FOREIGN KEY (`settlement_id`) REFERENCES `operator_settlement` (`settlement_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_settlement_adjustment_1` CHECK ((`amount` <> 0)),
  CONSTRAINT `ck_settlement_adjustment_2` CHECK ((`status` in (_utf8mb4'pending',_utf8mb4'approved',_utf8mb4'rejected')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `settlement_adjustment`
--

LOCK TABLES `settlement_adjustment` WRITE;
/*!40000 ALTER TABLE `settlement_adjustment` DISABLE KEYS */;
INSERT INTO `settlement_adjustment` VALUES (1,1,1,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(2,2,2,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(3,3,3,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(4,4,4,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(5,5,5,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(6,6,6,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(7,7,7,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(8,8,8,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(9,9,9,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(10,10,10,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(11,11,11,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(12,12,12,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(13,13,13,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(14,14,14,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(15,15,15,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(16,16,16,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(17,17,17,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(18,18,18,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(19,19,19,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006'),(20,20,20,-0.20,'对账差异调减','approved',103,101,'2026-11-02 03:15:00.000','2026-11-19 10:22:53.006','2026-11-19 10:22:53.006');
/*!40000 ALTER TABLE `settlement_adjustment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `settlement_item`
--

DROP TABLE IF EXISTS `settlement_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `settlement_item` (
  `settlement_item_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `settlement_id` bigint unsigned NOT NULL COMMENT '结算单',
  `order_id` bigint unsigned NOT NULL COMMENT '来源订单',
  `refund_id` bigint unsigned DEFAULT NULL COMMENT '退款冲减来源',
  `policy_id` bigint unsigned NOT NULL COMMENT '计算使用的政策版本',
  `item_type` varchar(32) NOT NULL COMMENT '条目类型',
  `occurred_at` datetime(3) NOT NULL COMMENT '归集事实时间',
  `net_amount` decimal(14,2) NOT NULL COMMENT '优惠退款后净额 可负',
  `electricity_share_amount` decimal(14,2) NOT NULL COMMENT '本条分成 可负',
  `service_share_amount` decimal(14,2) NOT NULL COMMENT '本条服务分成 可负',
  `platform_fee_amount` decimal(14,2) NOT NULL COMMENT '本条平台费 可负',
  `payable_amount` decimal(14,2) NOT NULL COMMENT '本条应结 可负',
  `business_key` varchar(100) NOT NULL COMMENT 'order或refund来源唯一键',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`settlement_item_id`),
  UNIQUE KEY `uq_settlement_item_business_key` (`business_key`),
  KEY `fk_settlement_item_settlement_id` (`settlement_id`),
  KEY `fk_settlement_item_order_id` (`order_id`),
  KEY `fk_settlement_item_refund_id` (`refund_id`),
  KEY `fk_settlement_item_policy_id` (`policy_id`),
  CONSTRAINT `fk_settlement_item_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlement_item_policy_id` FOREIGN KEY (`policy_id`) REFERENCES `settlement_policy` (`policy_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlement_item_refund_id` FOREIGN KEY (`refund_id`) REFERENCES `refund_record` (`refund_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlement_item_settlement_id` FOREIGN KEY (`settlement_id`) REFERENCES `operator_settlement` (`settlement_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_settlement_item_1` CHECK ((((`item_type` = _utf8mb4'order') and (`refund_id` is null)) or ((`item_type` = _utf8mb4'refund') and (`refund_id` is not null)))),
  CONSTRAINT `ck_settlement_item_2` CHECK ((`item_type` in (_utf8mb4'order',_utf8mb4'refund')))
) ENGINE=InnoDB AUTO_INCREMENT=121 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `settlement_item`
--

LOCK TABLES `settlement_item` WRITE;
/*!40000 ALTER TABLE `settlement_item` DISABLE KEYS */;
INSERT INTO `settlement_item` VALUES (1,1,1,NULL,1,'order','2026-10-20 02:30:00.000',6.35,3.14,1.50,0.32,4.32,'order:1','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(2,2,2,NULL,2,'order','2026-10-20 02:30:00.000',7.20,3.56,1.70,0.36,4.90,'order:2','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(3,3,3,NULL,3,'order','2026-10-20 02:30:00.000',8.05,3.98,1.90,0.40,5.48,'order:3','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(4,4,4,NULL,4,'order','2026-10-20 02:30:00.000',8.90,4.40,2.10,0.45,6.05,'order:4','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(5,5,5,NULL,5,'order','2026-10-20 02:30:00.000',9.75,4.82,2.30,0.49,6.63,'order:5','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(6,6,6,NULL,6,'order','2026-10-20 02:30:00.000',10.60,5.24,2.50,0.53,7.21,'order:6','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(7,7,7,NULL,7,'order','2026-10-20 02:30:00.000',11.45,5.66,2.70,0.57,7.79,'order:7','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(8,8,8,NULL,8,'order','2026-10-20 02:30:00.000',12.30,6.08,2.90,0.62,8.36,'order:8','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(9,9,9,NULL,9,'order','2026-10-20 02:30:00.000',13.15,6.50,3.10,0.66,8.94,'order:9','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(10,10,10,NULL,10,'order','2026-10-20 02:30:00.000',14.00,6.92,3.30,0.70,9.52,'order:10','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(11,11,11,NULL,11,'order','2026-10-20 02:30:00.000',14.85,7.34,3.50,0.74,10.10,'order:11','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(12,12,12,NULL,12,'order','2026-10-20 02:30:00.000',15.70,7.76,3.70,0.79,10.67,'order:12','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(13,13,13,NULL,13,'order','2026-10-20 02:30:00.000',16.55,8.18,3.90,0.83,11.25,'order:13','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(14,14,14,NULL,14,'order','2026-10-20 02:30:00.000',17.40,8.60,4.10,0.87,11.83,'order:14','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(15,15,15,NULL,15,'order','2026-10-20 02:30:00.000',18.25,9.02,4.30,0.91,12.41,'order:15','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(16,16,16,NULL,16,'order','2026-10-20 02:30:00.000',19.10,9.44,4.50,0.96,12.98,'order:16','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(17,17,17,NULL,17,'order','2026-10-20 02:30:00.000',19.95,9.86,4.70,1.00,13.56,'order:17','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(18,18,18,NULL,18,'order','2026-10-20 02:30:00.000',20.80,10.28,4.90,1.04,14.14,'order:18','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(19,19,19,NULL,19,'order','2026-10-20 02:30:00.000',21.65,10.70,5.10,1.08,14.72,'order:19','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(20,20,20,NULL,20,'order','2026-10-20 02:30:00.000',22.50,11.12,5.30,1.13,15.29,'order:20','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(101,1,101,NULL,1,'order','2026-10-20 03:30:00.000',6.75,3.47,1.44,0.34,4.57,'order:101','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(102,2,102,NULL,2,'order','2026-10-20 03:30:00.000',7.50,3.85,1.60,0.38,5.07,'order:102','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(103,3,103,NULL,3,'order','2026-10-20 03:30:00.000',8.25,4.24,1.76,0.41,5.59,'order:103','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(104,4,104,NULL,4,'order','2026-10-20 03:30:00.000',9.00,4.62,1.92,0.45,6.09,'order:104','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(105,5,105,NULL,5,'order','2026-10-20 03:30:00.000',9.75,5.01,2.08,0.49,6.60,'order:105','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(106,6,106,NULL,6,'order','2026-10-20 03:30:00.000',10.50,5.39,2.24,0.53,7.10,'order:106','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(107,7,107,NULL,7,'order','2026-10-20 03:30:00.000',11.25,5.78,2.40,0.56,7.62,'order:107','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(108,8,108,NULL,8,'order','2026-10-20 03:30:00.000',12.00,6.16,2.56,0.60,8.12,'order:108','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(109,9,109,NULL,9,'order','2026-10-20 03:30:00.000',12.75,6.55,2.72,0.64,8.63,'order:109','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(110,10,110,NULL,10,'order','2026-10-20 03:30:00.000',13.50,6.93,2.88,0.68,9.13,'order:110','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(111,11,111,NULL,11,'order','2026-10-20 03:30:00.000',14.25,7.32,3.04,0.71,9.65,'order:111','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(112,12,112,NULL,12,'order','2026-10-20 03:30:00.000',15.00,7.70,3.20,0.75,10.15,'order:112','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(113,13,113,NULL,13,'order','2026-10-20 03:30:00.000',15.75,8.09,3.36,0.79,10.66,'order:113','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(114,14,114,NULL,14,'order','2026-10-20 03:30:00.000',16.50,8.47,3.52,0.83,11.16,'order:114','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(115,15,115,NULL,15,'order','2026-10-20 03:30:00.000',17.25,8.86,3.68,0.86,11.68,'order:115','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(116,16,116,NULL,16,'order','2026-10-20 03:30:00.000',18.00,9.24,3.84,0.90,12.18,'order:116','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(117,17,117,NULL,17,'order','2026-10-20 03:30:00.000',18.75,9.63,4.00,0.94,12.69,'order:117','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(118,18,118,NULL,18,'order','2026-10-20 03:30:00.000',19.50,10.01,4.16,0.98,13.19,'order:118','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(119,19,119,NULL,19,'order','2026-10-20 03:30:00.000',20.25,10.40,4.32,1.01,13.71,'order:119','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009'),(120,20,120,NULL,20,'order','2026-10-20 03:30:00.000',21.00,10.78,4.48,1.05,14.21,'order:120','2026-11-19 10:22:53.009','2026-11-19 10:22:53.009');
/*!40000 ALTER TABLE `settlement_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `settlement_policy`
--

DROP TABLE IF EXISTS `settlement_policy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `settlement_policy` (
  `policy_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `operator_id` bigint unsigned NOT NULL COMMENT '运营商',
  `station_id` bigint unsigned NOT NULL COMMENT '场站',
  `electricity_share_rate` decimal(7,6) NOT NULL COMMENT '运营商电费分成比例0至1',
  `service_share_rate` decimal(7,6) NOT NULL COMMENT '运营商服务费分成比例',
  `platform_fee_rate` decimal(7,6) NOT NULL COMMENT '平台收费比例 基数另说明',
  `payment_basis` varchar(32) NOT NULL COMMENT '首版仅已付清订单',
  `valid_from` datetime(3) NOT NULL COMMENT '生效',
  `valid_until` datetime(3) NOT NULL COMMENT '失效',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`policy_id`),
  KEY `fk_settlement_policy_operator_id` (`operator_id`),
  KEY `fk_settlement_policy_station_id` (`station_id`),
  CONSTRAINT `fk_settlement_policy_operator_id` FOREIGN KEY (`operator_id`) REFERENCES `operator` (`operator_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_settlement_policy_station_id` FOREIGN KEY (`station_id`) REFERENCES `station` (`station_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_settlement_policy_1` CHECK ((`electricity_share_rate` between 0 and 1)),
  CONSTRAINT `ck_settlement_policy_2` CHECK ((`service_share_rate` between 0 and 1)),
  CONSTRAINT `ck_settlement_policy_3` CHECK ((`platform_fee_rate` between 0 and 1)),
  CONSTRAINT `ck_settlement_policy_4` CHECK ((`valid_until` > `valid_from`)),
  CONSTRAINT `ck_settlement_policy_5` CHECK ((`payment_basis` = _utf8mb4'paid_only'))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `settlement_policy`
--

LOCK TABLES `settlement_policy` WRITE;
/*!40000 ALTER TABLE `settlement_policy` DISABLE KEYS */;
INSERT INTO `settlement_policy` VALUES (1,1,1,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(2,2,2,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(3,3,3,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(4,4,4,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(5,5,5,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(6,6,6,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(7,7,7,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(8,8,8,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(9,9,9,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(10,10,10,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(11,11,11,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(12,12,12,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(13,13,13,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(14,14,14,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(15,15,15,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(16,16,16,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(17,17,17,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(18,18,18,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(19,19,19,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923'),(20,20,20,0.700000,0.800000,0.050000,'paid_only','2026-09-30 16:00:00.000','2027-01-31 16:00:00.000','2026-11-19 10:22:52.923','2026-11-19 10:22:52.923');
/*!40000 ALTER TABLE `settlement_policy` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `spare_part`
--

DROP TABLE IF EXISTS `spare_part`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `spare_part` (
  `part_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `part_code` varchar(50) NOT NULL COMMENT '备件编码',
  `part_name` varchar(100) NOT NULL COMMENT '备件名称',
  `model` varchar(100) DEFAULT NULL COMMENT '规格型号',
  `unit` varchar(16) NOT NULL DEFAULT '个' COMMENT '计量单位',
  `station_id` bigint unsigned DEFAULT NULL COMMENT '存放场站；空表示中心库',
  `stock_qty` int unsigned NOT NULL DEFAULT '0' COMMENT '当前库存',
  `safety_stock` int unsigned NOT NULL DEFAULT '0' COMMENT '安全库存',
  `status` varchar(16) NOT NULL DEFAULT 'active' COMMENT '启用状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`part_id`),
  UNIQUE KEY `uq_spare_part_code_station` (`part_code`,`station_id`),
  KEY `ix_spare_part_stock` (`station_id`,`stock_qty`),
  CONSTRAINT `fk_spare_part_station` FOREIGN KEY (`station_id`) REFERENCES `station` (`station_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_spare_part_1` CHECK ((`status` in (_utf8mb4'active',_utf8mb4'disabled'))),
  CONSTRAINT `ck_spare_part_2` CHECK ((`stock_qty` >= 0)),
  CONSTRAINT `ck_spare_part_3` CHECK ((`safety_stock` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=950 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='抢修备件';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `spare_part`
--

LOCK TABLES `spare_part` WRITE;
/*!40000 ALTER TABLE `spare_part` DISABLE KEYS */;
INSERT INTO `spare_part` VALUES (901,'SP-TEMP-01','温度探头','NTC-10K','个',901,6,6,'active','2026-11-19 10:23:00.210','2026-11-19 10:23:00.217'),(902,'SP-FAN-01','散热风扇','FAN-120','个',6,3,5,'active','2026-11-19 10:23:00.210','2026-11-19 10:23:00.217'),(903,'SP-CONT-01','接触器','CJX2-25','个',NULL,20,10,'active','2026-11-19 10:23:00.210','2026-11-19 10:23:00.210'),(904,'SP-EXT-001','通信模块','COMM-4G','个',1,29,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(905,'SP-EXT-002','计费主控板','CTRL-V2','块',2,28,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(906,'SP-EXT-003','功率模块','PWR-30K','个',3,29,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(907,'SP-EXT-004','直流接触器','CJX2-32','个',4,28,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(908,'SP-EXT-005','通信天线','ANT-4G','根',5,29,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(909,'SP-EXT-006','散热风扇','FAN-80','个',6,28,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(910,'SP-EXT-007','充电枪线','CABLE-DC','根',7,29,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(911,'SP-EXT-008','电表模块','METER-01','个',8,28,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(912,'SP-EXT-009','门禁控制器','ACS-01','个',9,29,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(913,'SP-EXT-010','交换机','SW-8','台',10,28,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(914,'SP-EXT-011','浪涌保护器','SPD-40','个',11,29,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(915,'SP-EXT-012','熔断器','FUSE-63','个',12,28,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(916,'SP-EXT-013','显示屏','LCD-7','块',13,29,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(917,'SP-EXT-014','读卡器','RFID-01','个',14,28,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(918,'SP-EXT-015','地锁电机','LOCK-M','个',15,29,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(919,'SP-EXT-016','电源模块','PSU-24','个',16,28,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(920,'SP-EXT-017','温湿度传感器','TH-01','个',17,29,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598'),(921,'SP-EXT-018','指示灯','LED-01','个',18,28,5,'active','2026-11-19 10:23:00.586','2026-11-19 10:23:00.598');
/*!40000 ALTER TABLE `spare_part` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `station`
--

DROP TABLE IF EXISTS `station`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `station` (
  `station_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `operator_id` bigint unsigned NOT NULL COMMENT '所属运营商',
  `station_name` varchar(100) NOT NULL COMMENT '场站名称',
  `address` varchar(255) NOT NULL COMMENT '地址',
  `longitude` decimal(10,7) NOT NULL COMMENT '经度',
  `latitude` decimal(10,7) NOT NULL COMMENT '纬度',
  `parking_spaces` int unsigned NOT NULL DEFAULT '0' COMMENT '车位数量',
  `business_hours` varchar(100) NOT NULL DEFAULT '00:00-24:00' COMMENT '营业时间展示文本',
  `parking_fee_standard` varchar(255) NOT NULL DEFAULT '按场站公示标准' COMMENT '停车费说明 不并入充电费',
  `status` varchar(32) NOT NULL DEFAULT 'draft' COMMENT '场站生命周期',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`station_id`),
  KEY `ix_station_operator_id_status` (`operator_id`,`status`),
  CONSTRAINT `fk_station_operator_id` FOREIGN KEY (`operator_id`) REFERENCES `operator` (`operator_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_station_1` CHECK ((`longitude` between -(180) and 180)),
  CONSTRAINT `ck_station_2` CHECK ((`latitude` between -(90) and 90)),
  CONSTRAINT `ck_station_3` CHECK ((`status` in (_utf8mb4'draft',_utf8mb4'active',_utf8mb4'suspended',_utf8mb4'retired')))
) ENGINE=InnoDB AUTO_INCREMENT=902 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `station`
--

LOCK TABLES `station` WRITE;
/*!40000 ALTER TABLE `station` DISABLE KEYS */;
INSERT INTO `station` VALUES (1,1,'演示场站01','测试道路1号',116.3010000,39.9010000,31,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(2,2,'演示场站02','测试道路2号',116.3020000,39.9020000,32,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(3,3,'演示场站03','测试道路3号',116.3030000,39.9030000,33,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(4,4,'演示场站04','测试道路4号',116.3040000,39.9040000,34,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(5,5,'演示场站05','测试道路5号',116.3050000,39.9050000,35,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(6,6,'演示场站06','测试道路6号',116.3060000,39.9060000,36,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(7,7,'演示场站07','测试道路7号',116.3070000,39.9070000,37,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(8,8,'演示场站08','测试道路8号',116.3080000,39.9080000,38,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(9,9,'演示场站09','测试道路9号',116.3090000,39.9090000,39,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(10,10,'演示场站10','测试道路10号',116.3100000,39.9100000,40,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(11,11,'演示场站11','测试道路11号',116.3110000,39.9110000,41,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(12,12,'演示场站12','测试道路12号',116.3120000,39.9120000,42,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(13,13,'演示场站13','测试道路13号',116.3130000,39.9130000,43,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(14,14,'演示场站14','测试道路14号',116.3140000,39.9140000,44,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(15,15,'演示场站15','测试道路15号',116.3150000,39.9150000,45,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(16,16,'演示场站16','测试道路16号',116.3160000,39.9160000,46,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(17,17,'演示场站17','测试道路17号',116.3170000,39.9170000,47,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(18,18,'演示场站18','测试道路18号',116.3180000,39.9180000,48,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(19,19,'演示场站19','测试道路19号',116.3190000,39.9190000,49,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(20,20,'演示场站20','测试道路20号',116.3200000,39.9200000,50,'00:00-24:00','按场站公示标准','active','2026-11-19 10:22:52.894','2026-11-19 10:22:52.894'),(901,3,'演示场站·应急园区','演示地址 901 号',116.3000000,40.0000000,60,'00:00-24:00','按场站公示标准','active','2026-11-19 10:23:00.083','2026-11-19 10:23:00.083');
/*!40000 ALTER TABLE `station` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_account`
--

DROP TABLE IF EXISTS `sys_account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_account` (
  `account_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(64) NOT NULL COMMENT '登录名',
  `password_hash` varchar(255) NOT NULL COMMENT 'Argon2id或bcrypt哈希 非明文',
  `status` varchar(32) NOT NULL DEFAULT 'active' COMMENT '账号状态',
  `failed_attempts` int unsigned NOT NULL DEFAULT '0' COMMENT '连续失败次数',
  `locked_until` datetime(3) DEFAULT NULL COMMENT '锁定截止',
  `last_login_at` datetime(3) DEFAULT NULL COMMENT '最后登录',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`account_id`),
  UNIQUE KEY `uq_sys_account_username` (`username`),
  CONSTRAINT `ck_sys_account_1` CHECK ((`status` in (_utf8mb4'active',_utf8mb4'disabled')))
) ENGINE=InnoDB AUTO_INCREMENT=1021 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_account`
--

LOCK TABLES `sys_account` WRITE;
/*!40000 ALTER TABLE `sys_account` DISABLE KEYS */;
INSERT INTO `sys_account` VALUES (101,'platform_admin_demo','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(102,'maintenance_engineer_demo','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(103,'customer_service_demo','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(104,'vehicle_owner_demo','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(105,'fleet_admin_demo','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(106,'operator_manager_demo','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1001,'owner_01','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1002,'owner_02','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1003,'owner_03','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1004,'owner_04','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1005,'owner_05','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1006,'owner_06','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1007,'owner_07','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1008,'owner_08','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1009,'owner_09','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1010,'owner_10','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1011,'owner_11','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1012,'owner_12','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1013,'owner_13','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1014,'owner_14','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1015,'owner_15','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1016,'owner_16','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1017,'owner_17','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1018,'owner_18','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1019,'owner_19','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880'),(1020,'owner_20','$argon2id$v=19$m=65536,t=3,p=4$pzgN5lEZRy2ZHwr7Ehw2ww$C9xTDgZPrRK4DjMrUEKnJ9zr1oMK5lqEJrHnVViInec','active',0,NULL,NULL,'2026-11-19 10:22:52.880','2026-11-19 10:22:52.880');
/*!40000 ALTER TABLE `sys_account` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_account_fleet`
--

DROP TABLE IF EXISTS `sys_account_fleet`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_account_fleet` (
  `account_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `fleet_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`account_id`,`fleet_id`),
  KEY `fk_sys_account_fleet_fleet_id` (`fleet_id`),
  CONSTRAINT `fk_sys_account_fleet_account_id` FOREIGN KEY (`account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_sys_account_fleet_fleet_id` FOREIGN KEY (`fleet_id`) REFERENCES `fleet` (`fleet_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_account_fleet`
--

LOCK TABLES `sys_account_fleet` WRITE;
/*!40000 ALTER TABLE `sys_account_fleet` DISABLE KEYS */;
INSERT INTO `sys_account_fleet` VALUES (105,1,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,2,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,3,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,4,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,5,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,6,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,7,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,8,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,9,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,10,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,11,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,12,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,13,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,14,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,15,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,16,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,17,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,18,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,19,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910'),(105,20,'2026-11-19 10:22:52.910','2026-11-19 10:22:52.910');
/*!40000 ALTER TABLE `sys_account_fleet` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_account_operator`
--

DROP TABLE IF EXISTS `sys_account_operator`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_account_operator` (
  `account_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `operator_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`account_id`,`operator_id`),
  KEY `fk_sys_account_operator_operator_id` (`operator_id`),
  CONSTRAINT `fk_sys_account_operator_account_id` FOREIGN KEY (`account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_sys_account_operator_operator_id` FOREIGN KEY (`operator_id`) REFERENCES `operator` (`operator_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_account_operator`
--

LOCK TABLES `sys_account_operator` WRITE;
/*!40000 ALTER TABLE `sys_account_operator` DISABLE KEYS */;
INSERT INTO `sys_account_operator` VALUES (106,1,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,2,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,3,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,4,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,5,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,6,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,7,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,8,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,9,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,10,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,11,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,12,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,13,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,14,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,15,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,16,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,17,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,18,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,19,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909'),(106,20,'2026-11-19 10:22:52.909','2026-11-19 10:22:52.909');
/*!40000 ALTER TABLE `sys_account_operator` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_account_role`
--

DROP TABLE IF EXISTS `sys_account_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_account_role` (
  `account_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `role_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`account_id`,`role_id`),
  KEY `fk_sys_account_role_role_id` (`role_id`),
  CONSTRAINT `fk_sys_account_role_account_id` FOREIGN KEY (`account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_sys_account_role_role_id` FOREIGN KEY (`role_id`) REFERENCES `sys_role` (`role_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_account_role`
--

LOCK TABLES `sys_account_role` WRITE;
/*!40000 ALTER TABLE `sys_account_role` DISABLE KEYS */;
INSERT INTO `sys_account_role` VALUES (101,1,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(102,2,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(103,3,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(104,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(105,5,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(106,6,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1001,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1002,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1003,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1004,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1005,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1006,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1007,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1008,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1009,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1010,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1011,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1012,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1013,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1014,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1015,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1016,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1017,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1018,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1019,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907'),(1020,4,'2026-11-19 10:22:52.907','2026-11-19 10:22:52.907');
/*!40000 ALTER TABLE `sys_account_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_account_station`
--

DROP TABLE IF EXISTS `sys_account_station`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_account_station` (
  `account_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `station_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`account_id`,`station_id`),
  KEY `fk_sys_account_station_station_id` (`station_id`),
  CONSTRAINT `fk_sys_account_station_account_id` FOREIGN KEY (`account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_sys_account_station_station_id` FOREIGN KEY (`station_id`) REFERENCES `station` (`station_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_account_station`
--

LOCK TABLES `sys_account_station` WRITE;
/*!40000 ALTER TABLE `sys_account_station` DISABLE KEYS */;
INSERT INTO `sys_account_station` VALUES (102,1,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,2,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,3,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,4,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,5,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,6,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,7,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,8,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,9,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,10,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,11,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,12,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,13,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,14,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,15,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,16,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,17,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,18,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,19,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922'),(102,20,'2026-11-19 10:22:52.922','2026-11-19 10:22:52.922');
/*!40000 ALTER TABLE `sys_account_station` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_permission`
--

DROP TABLE IF EXISTS `sys_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_permission` (
  `permission_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `permission_code` varchar(100) NOT NULL COMMENT '模块.资源.动作',
  `permission_name` varchar(100) NOT NULL COMMENT '中文说明',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`permission_id`),
  UNIQUE KEY `uq_sys_permission_permission_code` (`permission_code`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_permission`
--

LOCK TABLES `sys_permission` WRITE;
/*!40000 ALTER TABLE `sys_permission` DISABLE KEYS */;
INSERT INTO `sys_permission` VALUES (1,'assets.operator.read','assets.operator.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(2,'assets.station.read','assets.station.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(3,'assets.station.manage','assets.station.manage','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(4,'assets.gun.read','assets.gun.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(5,'assets.pile.manage','assets.pile.manage','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(6,'billing.order.create','billing.order.create','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(7,'billing.order.finish','billing.order.finish','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(8,'billing.order.read','billing.order.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(9,'billing.payment.create','billing.payment.create','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(10,'billing.refund.create','billing.refund.create','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(11,'billing.pricing.manage','billing.pricing.manage','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(12,'maintenance.alert.read','maintenance.alert.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(13,'maintenance.work_order.handle','maintenance.work_order.handle','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(14,'maintenance.work_order.assign','maintenance.work_order.assign','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(15,'maintenance.device_reading.read','maintenance.device_reading.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(16,'membership.user.read','membership.user.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(17,'membership.coupon.read','membership.coupon.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(18,'membership.coupon.manage','membership.coupon.manage','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(19,'membership.fleet.manage','membership.fleet.manage','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(20,'membership.vehicle.manage','membership.vehicle.manage','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(21,'settlement.settlement.read','settlement.settlement.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(22,'settlement.settlement.confirm','settlement.settlement.confirm','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(23,'settlement.invoice.create','settlement.invoice.create','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(24,'settlement.fleet_bill.read','settlement.fleet_bill.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(25,'common.notification.read','common.notification.read','2026-11-19 10:22:52.889','2026-11-19 10:22:52.889'),(26,'maintenance.rule.manage','配置告警规则与响应时限','2026-11-19 10:22:53.831','2026-11-19 10:22:53.831'),(27,'maintenance.inspection.read','查看巡检记录','2026-11-19 10:22:53.831','2026-11-19 10:22:53.831'),(28,'maintenance.inspection.create','新增巡检记录','2026-11-19 10:22:53.831','2026-11-19 10:22:53.831'),(29,'maintenance.fault_report.read','查看用户报障','2026-11-19 10:22:53.831','2026-11-19 10:22:53.831'),(30,'maintenance.fault_report.handle','处理用户报障','2026-11-19 10:22:53.831','2026-11-19 10:22:53.831'),(31,'maintenance.incident.manage','声明与关闭应急事件','2026-11-19 10:22:53.831','2026-11-19 10:22:53.831');
/*!40000 ALTER TABLE `sys_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_role`
--

DROP TABLE IF EXISTS `sys_role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role` (
  `role_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `role_code` varchar(50) NOT NULL COMMENT '固定角色代码',
  `role_name` varchar(50) NOT NULL COMMENT '中文名称',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uq_sys_role_role_code` (`role_code`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_role`
--

LOCK TABLES `sys_role` WRITE;
/*!40000 ALTER TABLE `sys_role` DISABLE KEYS */;
INSERT INTO `sys_role` VALUES (1,'platform_admin','平台管理员','2026-11-19 10:22:52.888','2026-11-19 10:22:52.888'),(2,'maintenance_engineer','场站运维','2026-11-19 10:22:52.888','2026-11-19 10:22:52.888'),(3,'customer_service','客服结算','2026-11-19 10:22:52.888','2026-11-19 10:22:52.888'),(4,'vehicle_owner','车主','2026-11-19 10:22:52.888','2026-11-19 10:22:52.888'),(5,'fleet_admin','车队管理员','2026-11-19 10:22:52.888','2026-11-19 10:22:52.888'),(6,'operator_manager','运营商负责人','2026-11-19 10:22:52.888','2026-11-19 10:22:52.888');
/*!40000 ALTER TABLE `sys_role` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_role_permission`
--

DROP TABLE IF EXISTS `sys_role_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role_permission` (
  `role_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `permission_id` bigint unsigned NOT NULL COMMENT '关联编号',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`role_id`,`permission_id`),
  KEY `fk_sys_role_permission_permission_id` (`permission_id`),
  CONSTRAINT `fk_sys_role_permission_permission_id` FOREIGN KEY (`permission_id`) REFERENCES `sys_permission` (`permission_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_sys_role_permission_role_id` FOREIGN KEY (`role_id`) REFERENCES `sys_role` (`role_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_role_permission`
--

LOCK TABLES `sys_role_permission` WRITE;
/*!40000 ALTER TABLE `sys_role_permission` DISABLE KEYS */;
INSERT INTO `sys_role_permission` VALUES (1,1,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,2,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,3,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,4,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,5,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,6,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,7,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,8,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,9,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,10,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,11,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,12,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,13,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,14,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,15,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,16,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,17,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,18,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,19,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,20,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,21,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,22,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,23,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,24,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,25,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(1,26,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(1,27,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(1,28,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(1,29,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(1,30,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(1,31,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(2,12,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(2,13,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(2,14,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(2,15,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(2,27,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(2,28,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(2,29,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(3,10,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(3,29,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(3,30,'2026-11-19 10:22:53.842','2026-11-19 10:22:53.842'),(4,6,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(4,7,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(4,8,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(4,9,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(4,11,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908'),(6,22,'2026-11-19 10:22:52.908','2026-11-19 10:22:52.908');
/*!40000 ALTER TABLE `sys_role_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sys_session`
--

DROP TABLE IF EXISTS `sys_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_session` (
  `session_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `account_id` bigint unsigned NOT NULL COMMENT '账号',
  `jti_hash` binary(32) NOT NULL COMMENT 'JWT会话标识摘要',
  `expires_at` datetime(3) NOT NULL COMMENT '会话到期',
  `revoked_at` datetime(3) DEFAULT NULL COMMENT '退出或禁用时撤销',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`session_id`),
  UNIQUE KEY `uq_sys_session_jti_hash` (`jti_hash`),
  KEY `fk_sys_session_account_id` (`account_id`),
  CONSTRAINT `fk_sys_session_account_id` FOREIGN KEY (`account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sys_session`
--

LOCK TABLES `sys_session` WRITE;
/*!40000 ALTER TABLE `sys_session` DISABLE KEYS */;
INSERT INTO `sys_session` VALUES (1,1001,_binary 't<~g`��4\�lB�.�iA=H`ہ5��֧\�o�','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(2,1002,_binary 'm03\�\�Uպ\�\�=\\\�	�cd1D\�\�&Q�\�-','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(3,1003,_binary '�}:\��kg�Qɫ�\'�J������7�J�\�e�','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(4,1004,_binary 'Yࣽ���V\��Lx�\�\Z��h�}\�L\�\�F<7','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(5,1005,_binary '#� \�/p�B�\�\�ؤDO!ǺU%��9)E\�]�','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(6,1006,_binary '#bx\�����LQ\�\�(\�%�\\\���$$T��ZܵX2\�','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(7,1007,_binary 'R��jW\�j\�a#T\�\�\�KfFs4��[��q�Q�','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(8,1008,_binary '�煘\�̛{d�˞�����Wt���5�{\�\�\ns?','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(9,1009,_binary '\���kZI	�C;\�_\�ܯ[_\�\�8zMyh�|\�V�','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(10,1010,_binary '�\�\�\�M�zeƵ��{]��\�%4%`\\#�\�jFm','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(11,1011,_binary 'yWGK�?d��F�2\����_��j|�����\r�B','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(12,1012,_binary '۔]|\�Y~f����\�\�\�\�sn\��RSh','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(13,1013,_binary '�`\\��\Z�B\"A���\�\�\�x\�\�\�,4Y�\�ag','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(14,1014,_binary '\�\��\�J\�\0�\�G���?�[�\�nEK��r�','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(15,1015,_binary '��\�۫R�WM|\�L�z\�~�!�\\�tv[fα^A\�','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(16,1016,_binary '>^\�\�\��̖\��Z�8\�!�[�\�Ŷ�\���i�\��','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(17,1017,_binary '\�|\��b�{��[\�f��[��B\��\�\�EB�\�<\�','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(18,1018,_binary '�W\�\�D\�>�\\JdG��=\�G��b\��?#M�)R','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(19,1019,_binary 'n�\�\0��$�O\�\�\�ا\�=\�\�\��~�\'�\"\�\�','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(20,1020,_binary '�\0m2A�Ss\�\�\'h-D_@�a\�&\�\�\�y��k','2026-10-20 12:00:00.000','2026-10-20 11:00:00.000','2026-11-19 10:22:52.911','2026-11-19 10:22:52.911'),(21,101,_binary 'HJ\�\�D�\�\�\�\�\�\�hH�Rf<u4\��F \�4ѝ','2026-11-19 11:23:24.000',NULL,'2026-11-19 10:23:24.855','2026-11-19 10:23:24.855'),(22,102,_binary '\Z\�?x��|��ԨU\�\�>\�&wn��d\\AxJ�J\�[','2026-11-19 11:23:25.000',NULL,'2026-11-19 10:23:25.144','2026-11-19 10:23:25.144'),(23,102,_binary '\"\�K7_��5lȓ��E\�:�\�m\�̶�L\����8','2026-11-19 11:23:25.000',NULL,'2026-11-19 10:23:25.277','2026-11-19 10:23:25.277'),(24,102,_binary '�x{B5*f\�\r`�`�F9\����\�Y��VBPgy','2026-11-19 11:23:25.000',NULL,'2026-11-19 10:23:25.285','2026-11-19 10:23:25.285'),(25,101,_binary '�\�\�d孽뜅��\"���Z\���cG~vu�','2026-11-19 11:23:39.000',NULL,'2026-11-19 10:23:39.459','2026-11-19 10:23:39.459'),(26,102,_binary 'A\��?\n\�\�v��;p)\�\�q-I9\�ْ4\n�l��|','2026-11-19 11:23:39.000',NULL,'2026-11-19 10:23:39.598','2026-11-19 10:23:39.598'),(27,102,_binary '\�\�\\�t\�H�=�\Z�є프@\�z��\��\�\rDV\�\�','2026-11-19 11:23:39.000',NULL,'2026-11-19 10:23:39.682','2026-11-19 10:23:39.682'),(28,102,_binary 'N>\�?\�,\�oި\�\�5n\�ř�.\���uF\�r\�','2026-11-19 11:23:39.000',NULL,'2026-11-19 10:23:39.688','2026-11-19 10:23:39.688'),(29,101,_binary '|\�ve <�H�\�\��5�g����\��#�\� M[�?','2026-11-19 11:23:50.000',NULL,'2026-11-19 10:23:50.969','2026-11-19 10:23:50.969'),(30,102,_binary '�\�Y:qT\�)\�\"\Z\�\��s\�YjP�&���*��\�U','2026-11-19 11:23:51.000',NULL,'2026-11-19 10:23:51.080','2026-11-19 10:23:51.080'),(31,102,_binary '�\n�/\�ڸASR�_\��\�.J��e\�\�\� Q\��d�','2026-11-19 11:23:51.000',NULL,'2026-11-19 10:23:51.180','2026-11-19 10:23:51.180'),(32,102,_binary '�\�\"�Zr��\�Hi\Z�\�Ô���fr\�9��H','2026-11-19 11:23:51.000',NULL,'2026-11-19 10:23:51.188','2026-11-19 10:23:51.188'),(33,101,_binary '�s:��\�\�\nl,�\�\���e?\njY�\�\�\�w{xF�*\n','2026-11-19 11:24:09.000',NULL,'2026-11-19 10:24:09.671','2026-11-19 10:24:09.671'),(34,102,_binary '\n�%\�\�\�hޏU�f�\Z\�=z�QJ^uw\�oŒf','2026-11-19 11:24:09.000',NULL,'2026-11-19 10:24:09.837','2026-11-19 10:24:09.837'),(35,102,_binary '\�H5_\�K��퐚]\r�z|1Z�a\�\��\�T�	D�','2026-11-19 11:24:09.000',NULL,'2026-11-19 10:24:09.919','2026-11-19 10:24:09.919'),(36,102,_binary '!Ƃ��\�+ݍ�\�O�\"t\������;� \�*\�\�','2026-11-19 11:24:09.000',NULL,'2026-11-19 10:24:09.927','2026-11-19 10:24:09.927'),(37,101,_binary '��w�eddۺ\�<\0�Y\�b��\��\�j\��\��','2026-11-19 11:24:29.000',NULL,'2026-11-19 10:24:29.878','2026-11-19 10:24:29.878'),(38,102,_binary '\�\�\�\�;Bq�\�~b\�\'\�G\�iM�\�%,\��7\�:F','2026-11-19 11:24:30.000',NULL,'2026-11-19 10:24:30.104','2026-11-19 10:24:30.104'),(39,102,_binary 'P�QR+�\�g�l�Y\�B-���c\�~_\�Ͷ\�','2026-11-19 11:24:30.000',NULL,'2026-11-19 10:24:30.193','2026-11-19 10:24:30.193'),(40,102,_binary 'Վ6\�SmV}\�\��_\�N��\�	�j۵+a\�\���&','2026-11-19 11:24:30.000',NULL,'2026-11-19 10:24:30.202','2026-11-19 10:24:30.202'),(41,101,_binary 'S�b �,E�P\�Y\�j\�\�|\�]w\�-K�XI~�W','2026-11-19 11:25:03.000',NULL,'2026-11-19 10:25:03.826','2026-11-19 10:25:03.826'),(42,102,_binary '&\�m�l�9TY�rD�8䣋�C�H\�\��~\�Q\�','2026-11-19 11:25:04.000',NULL,'2026-11-19 10:25:04.074','2026-11-19 10:25:04.074'),(43,102,_binary 'HQ\�Ն\�\�4j\�iVcx��	d\�\�Nt�u+\��\�','2026-11-19 11:25:04.000',NULL,'2026-11-19 10:25:04.161','2026-11-19 10:25:04.161'),(44,102,_binary '�\�0�\��X�x���r[hK�?�J��5','2026-11-19 11:25:04.000',NULL,'2026-11-19 10:25:04.169','2026-11-19 10:25:04.169'),(45,101,_binary '�*�w\�\�sy�\�\�+j��\�\�\��G\�r\�\�\�\�E','2026-11-19 11:25:10.000',NULL,'2026-11-19 10:25:10.151','2026-11-19 10:25:10.151'),(46,102,_binary 'C�>\�@xuA@�l�%�!\�&��&\�xm]I\�zq/','2026-11-19 11:25:10.000',NULL,'2026-11-19 10:25:10.255','2026-11-19 10:25:10.255'),(47,102,_binary '\�AQ�Si\�/;\�\�[��\�!\�Fj$�^�\�n�a}','2026-11-19 11:25:10.000',NULL,'2026-11-19 10:25:10.343','2026-11-19 10:25:10.343'),(48,102,_binary '\��̩Gҷ\Z�J�g\�8xBt\�p�s\�B�2ι�','2026-11-19 11:25:10.000',NULL,'2026-11-19 10:25:10.356','2026-11-19 10:25:10.356');
/*!40000 ALTER TABLE `sys_session` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_coupon`
--

DROP TABLE IF EXISTS `user_coupon`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_coupon` (
  `coupon_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `promotion_id` bigint unsigned NOT NULL COMMENT '活动来源',
  `user_id` bigint unsigned NOT NULL COMMENT '持券用户',
  `received_at` datetime(3) NOT NULL COMMENT '领取时间',
  `expires_at` datetime(3) NOT NULL COMMENT '到期时间',
  `face_amount_snapshot` decimal(14,2) NOT NULL COMMENT '发放时面额',
  `minimum_spend_snapshot` decimal(14,2) NOT NULL COMMENT '发放时门槛',
  `status` varchar(32) NOT NULL DEFAULT 'available' COMMENT '券状态',
  `reissue_source_order_id` bigint unsigned DEFAULT NULL COMMENT '退款补发来源订单',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`coupon_id`),
  UNIQUE KEY `uq_user_coupon_reissue_source_order_id` (`reissue_source_order_id`),
  KEY `ix_user_coupon_user_id_status` (`user_id`,`status`),
  KEY `fk_user_coupon_promotion_id` (`promotion_id`),
  CONSTRAINT `fk_user_coupon_promotion_id` FOREIGN KEY (`promotion_id`) REFERENCES `promotion` (`promotion_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_user_coupon_reissue_source_order_id` FOREIGN KEY (`reissue_source_order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_user_coupon_user_id` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_user_coupon_1` CHECK ((`status` in (_utf8mb4'available',_utf8mb4'locked',_utf8mb4'redeemed',_utf8mb4'expired',_utf8mb4'void')))
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_coupon`
--

LOCK TABLES `user_coupon` WRITE;
/*!40000 ALTER TABLE `user_coupon` DISABLE KEYS */;
INSERT INTO `user_coupon` VALUES (1,1,1,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(2,2,2,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(3,3,3,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(4,4,4,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(5,5,5,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(6,6,6,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(7,7,7,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(8,8,8,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(9,9,9,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(10,10,10,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(11,11,11,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(12,12,12,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(13,13,13,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(14,14,14,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(15,15,15,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(16,16,16,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(17,17,17,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(18,18,18,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(19,19,19,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(20,20,20,'2026-10-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'redeemed',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982'),(21,1,1,'2026-11-01 01:00:00.000','2027-01-31 16:00:00.000',3.00,8.00,'available',NULL,'2026-11-19 10:22:52.982','2026-11-19 10:22:52.982');
/*!40000 ALTER TABLE `user_coupon` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_invoice`
--

DROP TABLE IF EXISTS `user_invoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_invoice` (
  `user_invoice_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint unsigned NOT NULL COMMENT '申请人',
  `original_user_invoice_id` bigint unsigned DEFAULT NULL COMMENT '红冲原票',
  `invoice_no` varchar(64) DEFAULT NULL COMMENT '开票后唯一',
  `invoice_type` varchar(32) NOT NULL DEFAULT 'blue' COMMENT '票种',
  `title` varchar(100) NOT NULL COMMENT '抬头',
  `tax_no` varchar(30) DEFAULT NULL COMMENT '企业税号 可空',
  `amount` decimal(14,2) NOT NULL COMMENT '总额',
  `status` varchar(32) NOT NULL DEFAULT 'requested' COMMENT '办理状态',
  `requested_at` datetime(3) NOT NULL COMMENT '申请时间',
  `issued_at` datetime(3) DEFAULT NULL COMMENT '开具时间',
  `handled_by` bigint unsigned DEFAULT NULL COMMENT '办理人员',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`user_invoice_id`),
  UNIQUE KEY `uq_user_invoice_invoice_no` (`invoice_no`),
  KEY `fk_user_invoice_user_id` (`user_id`),
  KEY `fk_user_invoice_original_user_invoice_id` (`original_user_invoice_id`),
  KEY `fk_user_invoice_handled_by` (`handled_by`),
  CONSTRAINT `fk_user_invoice_handled_by` FOREIGN KEY (`handled_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_user_invoice_original_user_invoice_id` FOREIGN KEY (`original_user_invoice_id`) REFERENCES `user_invoice` (`user_invoice_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_user_invoice_user_id` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_user_invoice_1` CHECK ((`amount` > 0)),
  CONSTRAINT `ck_user_invoice_2` CHECK ((((`invoice_type` = _utf8mb4'blue') and (`original_user_invoice_id` is null)) or ((`invoice_type` = _utf8mb4'red') and (`original_user_invoice_id` is not null)))),
  CONSTRAINT `ck_user_invoice_3` CHECK ((`invoice_type` in (_utf8mb4'blue',_utf8mb4'red'))),
  CONSTRAINT `ck_user_invoice_4` CHECK ((`status` in (_utf8mb4'requested',_utf8mb4'issued',_utf8mb4'rejected',_utf8mb4'red_issued')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_invoice`
--

LOCK TABLES `user_invoice` WRITE;
/*!40000 ALTER TABLE `user_invoice` DISABLE KEYS */;
INSERT INTO `user_invoice` VALUES (1,1,NULL,'FIX-USER-01','blue','演示车主01',NULL,6.35,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(2,2,NULL,'FIX-USER-02','blue','演示车主02',NULL,7.20,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(3,3,NULL,'FIX-USER-03','blue','演示车主03',NULL,8.05,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(4,4,NULL,'FIX-USER-04','blue','演示车主04',NULL,8.90,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(5,5,NULL,'FIX-USER-05','blue','演示车主05',NULL,9.75,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(6,6,NULL,'FIX-USER-06','blue','演示车主06',NULL,10.60,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(7,7,NULL,'FIX-USER-07','blue','演示车主07',NULL,11.45,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(8,8,NULL,'FIX-USER-08','blue','演示车主08',NULL,12.30,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(9,9,NULL,'FIX-USER-09','blue','演示车主09',NULL,13.15,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(10,10,NULL,'FIX-USER-10','blue','演示车主10',NULL,14.00,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(11,11,NULL,'FIX-USER-11','blue','演示车主11',NULL,14.85,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(12,12,NULL,'FIX-USER-12','blue','演示车主12',NULL,15.70,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(13,13,NULL,'FIX-USER-13','blue','演示车主13',NULL,16.55,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(14,14,NULL,'FIX-USER-14','blue','演示车主14',NULL,17.40,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(15,15,NULL,'FIX-USER-15','blue','演示车主15',NULL,18.25,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(16,16,NULL,'FIX-USER-16','blue','演示车主16',NULL,19.10,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(17,17,NULL,'FIX-USER-17','blue','演示车主17',NULL,19.95,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(18,18,NULL,'FIX-USER-18','blue','演示车主18',NULL,20.80,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(19,19,NULL,'FIX-USER-19','blue','演示车主19',NULL,21.65,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927'),(20,20,NULL,'FIX-USER-20','blue','演示车主20',NULL,22.50,'issued','2026-10-20 02:45:00.000','2026-10-20 02:50:00.000',103,'2026-11-19 10:22:52.927','2026-11-19 10:22:52.927');
/*!40000 ALTER TABLE `user_invoice` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_invoice_item`
--

DROP TABLE IF EXISTS `user_invoice_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_invoice_item` (
  `user_invoice_item_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_invoice_id` bigint unsigned NOT NULL COMMENT '发票',
  `order_id` bigint unsigned NOT NULL COMMENT '订单',
  `allocated_amount` decimal(14,2) NOT NULL COMMENT '本订单分配金额',
  `status` varchar(32) NOT NULL DEFAULT 'reserved' COMMENT '占用开票额度状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`user_invoice_item_id`),
  UNIQUE KEY `uq_user_invoice_item_user_invoice_id_order_id` (`user_invoice_id`,`order_id`),
  KEY `fk_user_invoice_item_order_id` (`order_id`),
  CONSTRAINT `fk_user_invoice_item_order_id` FOREIGN KEY (`order_id`) REFERENCES `charging_order` (`order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_user_invoice_item_user_invoice_id` FOREIGN KEY (`user_invoice_id`) REFERENCES `user_invoice` (`user_invoice_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_user_invoice_item_1` CHECK ((`allocated_amount` > 0)),
  CONSTRAINT `ck_user_invoice_item_2` CHECK ((`status` in (_utf8mb4'reserved',_utf8mb4'effective',_utf8mb4'released')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_invoice_item`
--

LOCK TABLES `user_invoice_item` WRITE;
/*!40000 ALTER TABLE `user_invoice_item` DISABLE KEYS */;
INSERT INTO `user_invoice_item` VALUES (1,1,1,6.35,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(2,2,2,7.20,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(3,3,3,8.05,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(4,4,4,8.90,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(5,5,5,9.75,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(6,6,6,10.60,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(7,7,7,11.45,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(8,8,8,12.30,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(9,9,9,13.15,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(10,10,10,14.00,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(11,11,11,14.85,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(12,12,12,15.70,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(13,13,13,16.55,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(14,14,14,17.40,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(15,15,15,18.25,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(16,16,16,19.10,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(17,17,17,19.95,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(18,18,18,20.80,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(19,19,19,21.65,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986'),(20,20,20,22.50,'effective','2026-11-19 10:22:52.986','2026-11-19 10:22:52.986');
/*!40000 ALTER TABLE `user_invoice_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_alert_response_detail`
--

DROP TABLE IF EXISTS `v_alert_response_detail`;
/*!50001 DROP VIEW IF EXISTS `v_alert_response_detail`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_alert_response_detail` AS SELECT 
 1 AS `alert_id`,
 1 AS `pile_id`,
 1 AS `serial_no`,
 1 AS `station_id`,
 1 AS `station_name`,
 1 AS `gun_id`,
 1 AS `alert_code`,
 1 AS `severity`,
 1 AS `occurred_at`,
 1 AS `alert_status`,
 1 AS `response_seconds_snapshot`,
 1 AS `work_order_id`,
 1 AS `assigned_to`,
 1 AS `assignee_username`,
 1 AS `assigned_at`,
 1 AS `response_due_at`,
 1 AS `work_order_status`,
 1 AS `escalation_level`,
 1 AS `first_accepted_at`,
 1 AS `response_seconds_actual`,
 1 AS `is_overdue`,
 1 AS `normal_since_at`,
 1 AS `recovered_at`,
 1 AS `total_seconds`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_device_realtime`
--

DROP TABLE IF EXISTS `v_device_realtime`;
/*!50001 DROP VIEW IF EXISTS `v_device_realtime`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_device_realtime` AS SELECT 
 1 AS `pile_id`,
 1 AS `station_id`,
 1 AS `station_name`,
 1 AS `serial_no`,
 1 AS `model_name`,
 1 AS `rated_power_kw`,
 1 AS `lifecycle_status`,
 1 AS `pile_status`,
 1 AS `is_online`,
 1 AS `has_fault`,
 1 AS `last_heartbeat_at`,
 1 AS `heartbeat_silence_seconds`,
 1 AS `gun_id`,
 1 AS `gun_no`,
 1 AS `gun_type`,
 1 AS `connector_standard`,
 1 AS `gun_max_power_kw`,
 1 AS `gun_status`,
 1 AS `open_alert_count`,
 1 AS `worst_open_severity`,
 1 AS `last_power_kw`,
 1 AS `last_temperature_c`,
 1 AS `last_sampled_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_emergency_metrics`
--

DROP TABLE IF EXISTS `v_emergency_metrics`;
/*!50001 DROP VIEW IF EXISTS `v_emergency_metrics`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_emergency_metrics` AS SELECT 
 1 AS `bill_month`,
 1 AS `severity`,
 1 AS `incident_count`,
 1 AS `ack_ok_count`,
 1 AS `ack_breach_count`,
 1 AS `restore_breach_count`,
 1 AS `avg_ack_seconds`,
 1 AS `avg_restore_seconds`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_incident_board`
--

DROP TABLE IF EXISTS `v_incident_board`;
/*!50001 DROP VIEW IF EXISTS `v_incident_board`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_incident_board` AS SELECT 
 1 AS `incident_id`,
 1 AS `incident_no`,
 1 AS `operator_id`,
 1 AS `operator_name`,
 1 AS `station_id`,
 1 AS `station_name`,
 1 AS `category`,
 1 AS `severity`,
 1 AS `title`,
 1 AS `status`,
 1 AS `detected_at`,
 1 AS `declared_at`,
 1 AS `contained_at`,
 1 AS `restored_at`,
 1 AS `closed_at`,
 1 AS `commander_account_id`,
 1 AS `commander_username`,
 1 AS `impact_pile_count`,
 1 AS `impact_order_count`,
 1 AS `estimated_loss_amount`,
 1 AS `escalation_level`,
 1 AS `alert_count`,
 1 AS `open_work_orders`,
 1 AS `ack_limit_seconds`,
 1 AS `restore_limit_seconds`,
 1 AS `ack_seconds`,
 1 AS `restore_seconds`,
 1 AS `ack_breached`,
 1 AS `restore_breached`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_on_call_now`
--

DROP TABLE IF EXISTS `v_on_call_now`;
/*!50001 DROP VIEW IF EXISTS `v_on_call_now`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_on_call_now` AS SELECT 
 1 AS `shift_id`,
 1 AS `scope_type`,
 1 AS `scope_id`,
 1 AS `scope_name`,
 1 AS `shift_start`,
 1 AS `shift_end`,
 1 AS `status`,
 1 AS `primary_username`,
 1 AS `backup_username`,
 1 AS `supervisor_username`,
 1 AS `is_current`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_part_stock_alert`
--

DROP TABLE IF EXISTS `v_part_stock_alert`;
/*!50001 DROP VIEW IF EXISTS `v_part_stock_alert`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_part_stock_alert` AS SELECT 
 1 AS `part_id`,
 1 AS `part_code`,
 1 AS `part_name`,
 1 AS `model`,
 1 AS `station_id`,
 1 AS `station_name`,
 1 AS `stock_qty`,
 1 AS `safety_stock`,
 1 AS `gap`,
 1 AS `stock_status`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_work_order_progress`
--

DROP TABLE IF EXISTS `v_work_order_progress`;
/*!50001 DROP VIEW IF EXISTS `v_work_order_progress`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_work_order_progress` AS SELECT 
 1 AS `work_order_id`,
 1 AS `alert_id`,
 1 AS `alert_code`,
 1 AS `severity`,
 1 AS `pile_id`,
 1 AS `serial_no`,
 1 AS `station_name`,
 1 AS `assigned_to`,
 1 AS `assigned_by`,
 1 AS `assigned_at`,
 1 AS `response_due_at`,
 1 AS `work_order_status`,
 1 AS `escalation_level`,
 1 AS `parts_used`,
 1 AS `result`,
 1 AS `first_accepted_at`,
 1 AS `first_arrived_at`,
 1 AS `last_repaired_at`,
 1 AS `first_review_passed_at`,
 1 AS `closed_at`,
 1 AS `review_failed_count`,
 1 AS `escalated_count`,
 1 AS `accept_seconds`,
 1 AS `arrive_seconds`,
 1 AS `repair_seconds`,
 1 AS `review_seconds`,
 1 AS `total_seconds`,
 1 AS `accept_overdue`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `vehicle`
--

DROP TABLE IF EXISTS `vehicle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vehicle` (
  `vehicle_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `plate_cipher` varbinary(512) NOT NULL COMMENT '车牌密文',
  `plate_hash` binary(32) NOT NULL COMMENT '标准化车牌HMAC',
  `model_name` varchar(100) NOT NULL COMMENT '车型',
  `battery_capacity_kwh` decimal(14,3) NOT NULL COMMENT '电池容量',
  `max_charging_power_kw` decimal(10,3) NOT NULL COMMENT '最大充电功率',
  `supports_fast_charge` tinyint unsigned NOT NULL DEFAULT '0' COMMENT '支持快充',
  `status` varchar(32) NOT NULL DEFAULT 'active' COMMENT '车辆状态',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`vehicle_id`),
  UNIQUE KEY `uq_vehicle_plate_hash` (`plate_hash`),
  CONSTRAINT `ck_vehicle_1` CHECK ((`battery_capacity_kwh` > 0)),
  CONSTRAINT `ck_vehicle_2` CHECK ((`max_charging_power_kw` > 0)),
  CONSTRAINT `ck_vehicle_3` CHECK ((`supports_fast_charge` in (0,1))),
  CONSTRAINT `ck_vehicle_4` CHECK ((`status` in (_utf8mb4'active',_utf8mb4'disabled')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vehicle`
--

LOCK TABLES `vehicle` WRITE;
/*!40000 ALTER TABLE `vehicle` DISABLE KEYS */;
INSERT INTO `vehicle` VALUES (1,_binary 'gAAAAABq9qidYHrFdN4IqIV8lEawLoYjl6wz49905UeZ4k4jRS8spzFt-PxbLDC5vjvPLn3mkFntpEz8aWHiDuFG1kgn3M1huA==',_binary '�=\�Q}ê(�\�\�şUB\r\�[�B�\\�\�pY�O','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(2,_binary 'gAAAAABq9qidaWcZGTz-aTN4BbkpKnzXPjcaaXY1SDZEodF3L64kH5fdwA-H3fa37UgdZJZBRs6RDprXNJG-S9_P6qmDhKMFtQ==',_binary '{I��t\'�\�V\��r�hU\�\�Xn�\\.�߿	Qܒ','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(3,_binary 'gAAAAABq9qidxKajfuHh2VbZmbd8YXk5kQ5jPdZSrz5KmWVQcBMrjU7CWRVAPO2d8uVmYsAfnYL_pHVE-2zQ1UW1t8UhajSr2A==',_binary '�Kh�#\�--�f�\�\���͎\�d�\���tjKN/','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(4,_binary 'gAAAAABq9qid_eLpHzZsrlx9wOPXobGe8Xnr1s_RNOjH6EtCgGVtUEAFiksyVLaCX8aDFtfDspgYdKC_uHjlTOf1cuKWP9TB4w==',_binary '�4ׁ\�\�r7م\�\�tO\�\��#{`-\�0�\�','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(5,_binary 'gAAAAABq9qidmeE4vkL2igmfnGqV__6QCtRSYcsxrvqsZ8IWHtZ1ZyY3eNLtW8FewwdmKkVwfWvKyJq-8d4pbhJ2NGl703V5jw==',_binary 'YTIB��w\�{�!��\�3<\�<\��t�{�}�','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(6,_binary 'gAAAAABq9qiddlXGE_2mvL3BGMjkcnyql3t71dZEMEAGJWvjc5-MjsdivxJdPprW9z1XgvDHZ413MkFnWYEtF5-MrmjrNiLe_A==',_binary 'wj�\�m׈\�g�wն�R��\�g\�>\�\�E\��ft','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(7,_binary 'gAAAAABq9qidAol6K31-lp_ONbCaA2SfH_p2weGdqM9ahutcXGVCIlCqVpV-vgu-eaW8lc6XrhLONHr39C796YGM2UfYxJJ1Sg==',_binary '6�ı:�C\'r���-K?�5y�PMtxl�u�\n�}','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(8,_binary 'gAAAAABq9qidx0sZvuA6hoYLk_dDQ-un6gwnTOVdJTCt7PwhIdchPdMO4ZYIppM6hOhGOAKHybu4d3XnSEBxPz1WmwujO93FGQ==',_binary '�kD\�\nދP�񰂞�>\�3!\��,�\�zd%\�','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(9,_binary 'gAAAAABq9qidtBXcvPJ-9xFa4xVPa7Nuf__S09MVjjMfaHcv-OwcViJs3ED5aRiT5s1qIGamiuUL8Nv9WviLRZYnExDpu1u6pA==',_binary '\�v�bN��z�����Pџ�\�=�	cCơ�UAm�','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(10,_binary 'gAAAAABq9qidPK7fsEbsr7uuSaZm7GaJUJCBG9MGCYePMPHp_IKgEl8Cm_-8a86r8A1DBFUZ1o51bAUWP5gT2Tii0u09KFpfIw==',_binary '��MX�]6�\�.;#{�\�\�\�a�\�g\�B��~h�!','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(11,_binary 'gAAAAABq9qidpRkncKpl25NuebdZHUG1yhJVmM8RHHThRdvDtorIX9rrqDGVNqfCYDZ0eqMWko8Ok-ZiW9HeiPQEzpGnfbFbPA==',_binary 'lB(+58���}#z�F%\�s\'	F��a۝&�\�[m','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(12,_binary 'gAAAAABq9qid2HDmWgLhzJrBljWsk2X8N2VvCLXhWg8pCQGN1VAwOrntDqCd4yZ_H56kdCC1HiLAAproTlrV3jeZ3drn8GtYEQ==',_binary '\�R�.\�s�\�\'�bB��\�Q\�\�/\�%�\n+�\�W�','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(13,_binary 'gAAAAABq9qidadw_gGGWK1-PF_WfBEdX1vvAGFvBgeztt-kn3NFBLFbOQc2AHfXuLZ2Rnl2PfIIktJ-MxLlVDNjaqxul-erJ3g==',_binary '\�K)a\�{g�\�:�E� |&�z\0\�p��M\�$\��\�','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(14,_binary 'gAAAAABq9qid0GK8N0Kqu1HKaXGZPS0JnQPGQj8d-zrdqMv_PRysJlXYDxgq43LLu4RsrT0Zn5w1S8NjSDS2LiCWhINwYvbZyg==',_binary 'O;I9��Y{\�\�\�*~:+޲\�J\��Y�e\�\�qt^>','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(15,_binary 'gAAAAABq9qid80s22GG_bQtTqqYJj2LnJ-DacjT0bgEXyXVNso288qRQ8pjnTC5jUk36mDizsmEt7zWC_l1okEntaHJM8Tn2rA==',_binary '\��`\�\�\�-оy�y٬\�hw ]��\�XC��\�\�','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(16,_binary 'gAAAAABq9qiddoHyCZkJjLzWByrp-APUBBpTFofGMiuCvjtM6erXsagYE9BrEoUdO2r0Lxg3gNVD8nq-bOKZRjNPGg8IaStTYg==',_binary 'L�rQk+\�/\�\n봳|�e�U�p\�\�\�_�UZ','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(17,_binary 'gAAAAABq9qidZJsaNg5S8JZNqo4pf9hFkVPN8fftOZYChoFJMhyAu0pWNF6hhTXMX5GYwGm9P7swa20eJ1m-13WqOW39fekb1g==',_binary '�\�:/�\��\�jXK\��A\�ޱK\��\�1�oR\�l;','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(18,_binary 'gAAAAABq9qidVVc4hoKthVOJmcY6z2e2ORsSwy2tLTNlO5Gcs_VmJ5zPLzrXksvKz3aYZNQ7tvanMSK61W3n44m7KjYouOrMmg==',_binary '�\��\�vX��\��Мq/�����\� \�\�.�\�\�','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(19,_binary 'gAAAAABq9qidxtymRxQYDd-6C9rm1ugJFJQBZm2DDGbMQISJoRvOUlN30ES_tb99st1D_RvMDlBpEc7nUXpO6NqKypwO3xDU5A==',_binary '\�\�U4\�~\�ve�9\�c=��_x\�ÛӁ	N�y','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883'),(20,_binary 'gAAAAABq9qidFbZzh4ZorpjSSy5Bcy9zMbeF1E8uf1QGHakmGb2CdtOnMcEBvmNm_BSe-1ZKiEmfRSiwS6A24tbYvffF-s1wPg==',_binary '�\�Q\���ߟ\�^�ph�Iž\�\�k�\�E�m�o\�','DEMO-EV',70.000,60.000,1,'active','2026-11-19 10:22:52.883','2026-11-19 10:22:52.883');
/*!40000 ALTER TABLE `vehicle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vehicle_binding`
--

DROP TABLE IF EXISTS `vehicle_binding`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vehicle_binding` (
  `binding_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint unsigned NOT NULL COMMENT '绑定用户',
  `vehicle_id` bigint unsigned NOT NULL COMMENT '车辆',
  `bound_at` datetime(3) NOT NULL COMMENT '绑定开始',
  `unbound_at` datetime(3) DEFAULT NULL COMMENT '解绑时间',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  `active_vehicle_id` bigint unsigned GENERATED ALWAYS AS ((case when (`unbound_at` is null) then `vehicle_id` else NULL end)) STORED COMMENT '一车同一时刻只归一用户',
  PRIMARY KEY (`binding_id`),
  UNIQUE KEY `uq_vehicle_binding_active_vehicle_id` (`active_vehicle_id`),
  KEY `fk_vehicle_binding_user_id` (`user_id`),
  KEY `fk_vehicle_binding_vehicle_id` (`vehicle_id`),
  CONSTRAINT `fk_vehicle_binding_user_id` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_vehicle_binding_vehicle_id` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicle` (`vehicle_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_vehicle_binding_1` CHECK (((`unbound_at` is null) or (`unbound_at` >= `bound_at`)))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vehicle_binding`
--

LOCK TABLES `vehicle_binding` WRITE;
/*!40000 ALTER TABLE `vehicle_binding` DISABLE KEYS */;
INSERT INTO `vehicle_binding` (`binding_id`, `user_id`, `vehicle_id`, `bound_at`, `unbound_at`, `created_at`, `updated_at`) VALUES (1,1,1,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(2,2,2,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(3,3,3,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(4,4,4,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(5,5,5,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(6,6,6,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(7,7,7,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(8,8,8,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(9,9,9,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(10,10,10,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(11,11,11,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(12,12,12,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(13,13,13,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(14,14,14,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(15,15,15,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(16,16,16,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(17,17,17,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(18,18,18,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(19,19,19,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919'),(20,20,20,'2026-09-16 01:00:00.000',NULL,'2026-11-19 10:22:52.919','2026-11-19 10:22:52.919');
/*!40000 ALTER TABLE `vehicle_binding` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wallet_transaction`
--

DROP TABLE IF EXISTS `wallet_transaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wallet_transaction` (
  `wallet_transaction_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint unsigned NOT NULL COMMENT '余额用户',
  `payment_id` bigint unsigned DEFAULT NULL COMMENT '余额支付来源',
  `refund_id` bigint unsigned DEFAULT NULL COMMENT '余额退款来源',
  `transaction_type` varchar(32) NOT NULL COMMENT '变动种类',
  `amount` decimal(14,2) NOT NULL COMMENT '有符号金额 支出为负',
  `balance_after` decimal(14,2) NOT NULL COMMENT '交易后余额',
  `business_key` varchar(100) NOT NULL COMMENT '业务幂等键',
  `occurred_at` datetime(3) NOT NULL COMMENT '发生时间',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`wallet_transaction_id`),
  UNIQUE KEY `uq_wallet_transaction_business_key` (`business_key`),
  KEY `fk_wallet_transaction_user_id` (`user_id`),
  KEY `fk_wallet_transaction_payment_id` (`payment_id`),
  KEY `fk_wallet_transaction_refund_id` (`refund_id`),
  CONSTRAINT `fk_wallet_transaction_payment_id` FOREIGN KEY (`payment_id`) REFERENCES `payment_record` (`payment_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_wallet_transaction_refund_id` FOREIGN KEY (`refund_id`) REFERENCES `refund_record` (`refund_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_wallet_transaction_user_id` FOREIGN KEY (`user_id`) REFERENCES `app_user` (`user_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_wallet_transaction_1` CHECK ((`amount` <> 0)),
  CONSTRAINT `ck_wallet_transaction_2` CHECK ((`balance_after` >= 0)),
  CONSTRAINT `ck_wallet_transaction_3` CHECK ((`transaction_type` in (_utf8mb4'mock_topup',_utf8mb4'payment',_utf8mb4'refund')))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wallet_transaction`
--

LOCK TABLES `wallet_transaction` WRITE;
/*!40000 ALTER TABLE `wallet_transaction` DISABLE KEYS */;
INSERT INTO `wallet_transaction` VALUES (1,1,NULL,NULL,'mock_topup',200.00,200.00,'topup-1','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(2,2,NULL,NULL,'mock_topup',200.00,200.00,'topup-2','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(3,3,NULL,NULL,'mock_topup',200.00,200.00,'topup-3','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(4,4,NULL,NULL,'mock_topup',200.00,200.00,'topup-4','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(5,5,NULL,NULL,'mock_topup',200.00,200.00,'topup-5','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(6,6,NULL,NULL,'mock_topup',200.00,200.00,'topup-6','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(7,7,NULL,NULL,'mock_topup',200.00,200.00,'topup-7','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(8,8,NULL,NULL,'mock_topup',200.00,200.00,'topup-8','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(9,9,NULL,NULL,'mock_topup',200.00,200.00,'topup-9','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(10,10,NULL,NULL,'mock_topup',200.00,200.00,'topup-10','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(11,11,NULL,NULL,'mock_topup',200.00,200.00,'topup-11','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(12,12,NULL,NULL,'mock_topup',200.00,200.00,'topup-12','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(13,13,NULL,NULL,'mock_topup',200.00,200.00,'topup-13','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(14,14,NULL,NULL,'mock_topup',200.00,200.00,'topup-14','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(15,15,NULL,NULL,'mock_topup',200.00,200.00,'topup-15','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(16,16,NULL,NULL,'mock_topup',200.00,200.00,'topup-16','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(17,17,NULL,NULL,'mock_topup',200.00,200.00,'topup-17','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(18,18,NULL,NULL,'mock_topup',200.00,200.00,'topup-18','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(19,19,NULL,NULL,'mock_topup',200.00,200.00,'topup-19','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007'),(20,20,NULL,NULL,'mock_topup',200.00,200.00,'topup-20','2026-10-01 01:00:00.000','2026-11-19 10:22:53.007','2026-11-19 10:22:53.007');
/*!40000 ALTER TABLE `wallet_transaction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `work_order`
--

DROP TABLE IF EXISTS `work_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_order` (
  `work_order_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `alert_id` bigint unsigned NOT NULL COMMENT '关联告警',
  `assigned_to` bigint unsigned NOT NULL COMMENT '维修人员账号',
  `assigned_by` bigint unsigned NOT NULL COMMENT '派单账号',
  `assigned_at` datetime(3) NOT NULL COMMENT '派单时间',
  `response_due_at` datetime(3) NOT NULL COMMENT '首次接单截止',
  `status` varchar(32) NOT NULL DEFAULT 'assigned' COMMENT '当前状态',
  `escalation_level` int unsigned NOT NULL DEFAULT '0' COMMENT '超时升级次数',
  `parts_used` varchar(500) DEFAULT NULL COMMENT '更换备件说明',
  `result` varchar(500) DEFAULT NULL COMMENT '处理结果',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`work_order_id`),
  KEY `ix_work_order_assigned_to_status` (`assigned_to`,`status`),
  KEY `ix_work_order_status_response_due_at` (`status`,`response_due_at`),
  KEY `fk_work_order_alert_id` (`alert_id`),
  KEY `fk_work_order_assigned_by` (`assigned_by`),
  KEY `ix_work_order_assigned_at` (`assigned_at`),
  CONSTRAINT `fk_work_order_alert_id` FOREIGN KEY (`alert_id`) REFERENCES `device_alert` (`alert_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_work_order_assigned_by` FOREIGN KEY (`assigned_by`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_work_order_assigned_to` FOREIGN KEY (`assigned_to`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_work_order_1` CHECK ((`status` in (_utf8mb4'assigned',_utf8mb4'accepted',_utf8mb4'arrived',_utf8mb4'repaired',_utf8mb4'closed')))
) ENGINE=InnoDB AUTO_INCREMENT=999 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_order`
--

LOCK TABLES `work_order` WRITE;
/*!40000 ALTER TABLE `work_order` DISABLE KEYS */;
INSERT INTO `work_order` VALUES (1,1,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(2,2,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(3,3,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(4,4,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(5,5,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(6,6,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(7,7,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(8,8,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(9,9,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(10,10,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(11,11,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(12,12,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(13,13,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(14,14,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(15,15,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(16,16,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(17,17,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(18,18,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(19,19,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(20,20,102,103,'2026-10-20 04:01:00.000','2026-10-20 04:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:52.978','2026-11-19 10:22:52.978'),(901,903,102,101,'2026-11-14 01:01:00.000','2026-11-14 01:11:00.000','closed',0,'温度探头','复核通过','2026-11-19 10:22:53.353','2026-11-19 10:22:53.353'),(902,901,102,101,'2026-11-13 10:10:00.000','2026-11-13 10:15:00.000','assigned',1,NULL,NULL,'2026-11-19 10:22:53.353','2026-11-19 10:23:26.092'),(903,902,102,101,'2026-11-13 09:41:00.000','2026-11-13 09:51:00.000','assigned',1,NULL,NULL,'2026-11-19 10:22:53.353','2026-11-19 10:23:26.086'),(904,902,102,101,'2026-11-13 09:30:00.000','2026-11-13 09:40:00.000','closed',0,'散热风扇','复核通过','2026-11-19 10:22:53.353','2026-11-19 10:22:53.353'),(905,901,102,101,'2026-11-13 09:40:00.000','2026-11-13 09:45:00.000','closed',0,'熔断器','复核通过','2026-11-19 10:22:53.353','2026-11-19 10:22:53.353'),(906,904,102,101,'2026-11-13 02:01:00.000','2026-11-13 04:01:00.000','arrived',0,'接触器',NULL,'2026-11-19 10:22:53.353','2026-11-19 10:22:53.353'),(907,952,102,101,'2026-11-19 10:23:25.267','2026-11-19 10:33:25.267','accepted',0,NULL,NULL,'2026-11-19 10:23:25.267','2026-11-19 10:23:25.360'),(917,911,102,101,'2026-11-19 10:23:27.404','2026-11-19 10:28:27.404','assigned',0,NULL,NULL,'2026-11-19 10:23:27.411','2026-11-19 10:23:27.411'),(921,978,102,101,'2026-11-19 10:23:39.673','2026-11-19 10:33:39.673','accepted',0,NULL,NULL,'2026-11-19 10:23:39.673','2026-11-19 10:23:39.740');
/*!40000 ALTER TABLE `work_order` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_work_order_bu_state_guard` BEFORE UPDATE ON `work_order` FOR EACH ROW begin
  if new.status <> old.status then
    if not (
         (old.status = 'assigned' and new.status = 'accepted')
      or (old.status = 'accepted' and new.status = 'arrived')
      or (old.status = 'arrived'  and new.status = 'repaired')
      or (old.status = 'repaired' and new.status = 'arrived')
      or (old.status = 'repaired' and new.status = 'closed')
    ) then
      signal sqlstate '45000'
        set message_text = '非法的工单状态迁移：只允许 assigned→accepted→arrived→repaired→closed，或 repaired→arrived（复核未通过）';
    end if;
  end if;
end */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `work_order_event`
--

DROP TABLE IF EXISTS `work_order_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `work_order_event` (
  `event_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键',
  `work_order_id` bigint unsigned NOT NULL COMMENT '工单',
  `event_type` varchar(32) NOT NULL COMMENT '事件类型',
  `event_at` datetime(3) NOT NULL COMMENT '事件时间',
  `old_status` varchar(32) NOT NULL COMMENT '原状态',
  `new_status` varchar(32) NOT NULL COMMENT '新状态',
  `actor_account_id` bigint unsigned DEFAULT NULL COMMENT '系统任务为空',
  `note` varchar(500) DEFAULT NULL COMMENT '处理说明',
  `review_result` varchar(255) DEFAULT NULL COMMENT '复核依据',
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'UTC创建时间',
  `updated_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'UTC最后修改时间',
  PRIMARY KEY (`event_id`),
  KEY `ix_work_order_event_work_order_id_event_at` (`work_order_id`,`event_at`),
  KEY `fk_work_order_event_actor_account_id` (`actor_account_id`),
  CONSTRAINT `fk_work_order_event_actor_account_id` FOREIGN KEY (`actor_account_id`) REFERENCES `sys_account` (`account_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `fk_work_order_event_work_order_id` FOREIGN KEY (`work_order_id`) REFERENCES `work_order` (`work_order_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `ck_work_order_event_1` CHECK ((`event_type` in (_utf8mb4'accepted',_utf8mb4'arrived',_utf8mb4'repaired',_utf8mb4'review_passed',_utf8mb4'review_failed',_utf8mb4'closed',_utf8mb4'escalated')))
) ENGINE=InnoDB AUTO_INCREMENT=9170 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `work_order_event`
--

LOCK TABLES `work_order_event` WRITE;
/*!40000 ALTER TABLE `work_order_event` DISABLE KEYS */;
INSERT INTO `work_order_event` VALUES (1,1,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(2,2,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(3,3,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(4,4,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(5,5,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(6,6,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(7,7,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(8,8,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(9,9,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(10,10,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(11,11,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(12,12,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(13,13,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(14,14,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(15,15,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(16,16,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(17,17,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(18,18,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(19,19,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(20,20,'accepted','2026-10-20 04:04:00.000','assigned','accepted',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(101,1,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(102,2,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(103,3,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(104,4,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(105,5,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(106,6,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(107,7,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(108,8,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(109,9,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(110,10,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(111,11,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(112,12,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(113,13,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(114,14,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(115,15,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(116,16,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(117,17,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(118,18,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(119,19,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(120,20,'arrived','2026-10-20 04:11:00.000','accepted','arrived',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(201,1,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(202,2,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(203,3,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(204,4,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(205,5,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(206,6,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(207,7,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(208,8,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(209,9,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(210,10,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(211,11,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(212,12,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(213,13,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(214,14,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(215,15,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(216,16,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(217,17,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(218,18,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(219,19,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(220,20,'repaired','2026-10-20 04:24:00.000','arrived','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(301,1,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(302,2,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(303,3,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(304,4,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(305,5,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(306,6,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(307,7,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(308,8,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(309,9,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(310,10,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(311,11,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(312,12,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(313,13,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(314,14,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(315,15,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(316,16,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(317,17,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(318,18,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(319,19,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(320,20,'review_passed','2026-10-20 04:30:00.000','repaired','repaired',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(401,1,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(402,2,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(403,3,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(404,4,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(405,5,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(406,6,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(407,7,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(408,8,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(409,9,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(410,10,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(411,11,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(412,12,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(413,13,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(414,14,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(415,15,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(416,16,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(417,17,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(418,18,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(419,19,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(420,20,'closed','2026-10-20 04:34:00.000','repaired','closed',102,'历史工单演示',NULL,'2026-11-19 10:22:52.998','2026-11-19 10:22:52.998'),(9001,901,'accepted','2026-11-14 01:05:00.000','assigned','accepted',102,'已接单',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9002,901,'arrived','2026-11-14 01:12:00.000','accepted','arrived',102,'到场检查',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9003,901,'repaired','2026-11-14 01:25:00.000','arrived','repaired',102,'更换温度探头',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9004,901,'review_passed','2026-11-14 01:31:00.000','repaired','repaired',102,'复检合格','连续 6 分钟温度正常','2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9005,901,'closed','2026-11-14 01:35:00.000','repaired','closed',102,'工单闭环','复检合格','2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9011,904,'accepted','2026-11-13 09:31:00.000','assigned','accepted',102,'已接单',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9012,904,'arrived','2026-11-13 09:38:00.000','accepted','arrived',102,'到场检查',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9013,904,'repaired','2026-11-13 09:52:00.000','arrived','repaired',102,'更换散热风扇',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9014,904,'review_passed','2026-11-13 09:56:00.000','repaired','repaired',102,'复检合格','风扇转速正常','2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9015,904,'closed','2026-11-13 09:58:00.000','repaired','closed',102,'工单闭环','复检合格','2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9021,905,'accepted','2026-11-13 09:42:00.000','assigned','accepted',102,'已接单',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9022,905,'arrived','2026-11-13 09:47:00.000','accepted','arrived',102,'到场检查',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9023,905,'repaired','2026-11-13 09:56:00.000','arrived','repaired',102,'更换熔断器',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9024,905,'review_passed','2026-11-13 10:00:00.000','repaired','repaired',102,'复检合格','通断测试正常','2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9025,905,'closed','2026-11-13 10:04:00.000','repaired','closed',102,'工单闭环','复检合格','2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9031,906,'accepted','2026-11-13 02:03:00.000','assigned','accepted',102,'已接单',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9032,906,'arrived','2026-11-13 02:06:00.000','accepted','arrived',102,'到场检查',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9033,906,'repaired','2026-11-13 02:10:00.000','arrived','repaired',102,'更换接触器',NULL,'2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9034,906,'review_failed','2026-11-13 02:15:00.000','repaired','arrived',102,'复检仍告警','绝缘电阻不达标','2026-11-19 10:22:53.370','2026-11-19 10:22:53.370'),(9035,907,'accepted','2026-11-19 10:23:25.358','assigned','accepted',102,NULL,NULL,'2026-11-19 10:23:25.359','2026-11-19 10:23:25.359'),(9041,903,'escalated','2026-11-19 10:23:26.084','assigned','assigned',NULL,'超时未接单，自动升级到 L1',NULL,'2026-11-19 10:23:26.087','2026-11-19 10:23:26.087'),(9042,902,'escalated','2026-11-19 10:23:26.084','assigned','assigned',NULL,'超时未接单，自动升级到 L1',NULL,'2026-11-19 10:23:26.093','2026-11-19 10:23:26.093'),(9056,921,'accepted','2026-11-19 10:23:39.739','assigned','accepted',102,NULL,NULL,'2026-11-19 10:23:39.739','2026-11-19 10:23:39.739');
/*!40000 ALTER TABLE `work_order_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'charging_platform_test'
--

--
-- Dumping routines for database 'charging_platform_test'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_close_incident` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_close_incident`(
  in p_incident_id bigint unsigned,
  in p_actor_account_id bigint unsigned,
  in p_summary varchar(1000)
)
begin
  declare v_status varchar(32);
  declare v_pending_orders int default 0;
  declare v_open_alerts int default 0;
  declare v_pm int default 0;

  select status into v_status
    from incident where incident_id = p_incident_id for update;

  if v_status is null then
    signal sqlstate '45000' set message_text = '事件不存在';
  end if;
  if v_status not in ('restored', 'reviewed') then
    signal sqlstate '45000' set message_text = '只有已恢复(restored)或已复盘(reviewed)的事件可以关闭';
  end if;

  select count(*) into v_open_alerts
    from incident_alert ia
    join device_alert a on a.alert_id = ia.alert_id
   where ia.incident_id = p_incident_id
     and a.status <> 'recovered';
  if v_open_alerts > 0 then
    signal sqlstate '45000' set message_text = '仍有未恢复告警，不能关闭事件';
  end if;

  select count(*) into v_pending_orders
    from incident_alert ia
    join work_order w on w.alert_id = ia.alert_id
   where ia.incident_id = p_incident_id
     and w.status <> 'closed';
  if v_pending_orders > 0 then
    signal sqlstate '45000' set message_text = '仍有未闭环工单，不能关闭事件';
  end if;

  select count(*) into v_pm
    from postmortem
   where incident_id = p_incident_id and status = 'approved';
  if v_pm = 0 then
    signal sqlstate '45000' set message_text = '缺少已审核通过的复盘报告，不能关闭事件';
  end if;

  update incident
     set status = 'closed',
         closed_at = utc_timestamp(3),
         summary = p_summary
   where incident_id = p_incident_id;

  insert into incident_action
    (incident_id, action_type, target_type, action_at, actor_account_id, reason)
  values
    (p_incident_id, 'close', 'none', utc_timestamp(3), p_actor_account_id, p_summary);
end ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_close_work_order` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_close_work_order`(
  in p_work_order_id bigint unsigned,
  in p_actor_account_id bigint unsigned,
  in p_review_result varchar(255),
  in p_note varchar(500)
)
begin
  declare v_status varchar(32);
  declare v_alert_id bigint unsigned;
  declare v_pending_orders int default 0;
  declare v_normal_since datetime(3);

  select status, alert_id
    into v_status, v_alert_id
    from work_order
   where work_order_id = p_work_order_id
   for update;

  if v_status is null then
    signal sqlstate '45000' set message_text = '工单不存在';
  end if;

  if v_status <> 'repaired' then
    signal sqlstate '45000' set message_text = '只有已修复(repaired)的工单可以闭环';
  end if;

  if not exists (
       select 1 from work_order_event
        where work_order_id = p_work_order_id
          and event_type = 'review_passed'
     ) then
    signal sqlstate '45000' set message_text = '闭环前必须存在复核通过(review_passed)事件';
  end if;

  insert into work_order_event
    (work_order_id, event_type, event_at, old_status, new_status,
     actor_account_id, note, review_result)
  values
    (p_work_order_id, 'closed', utc_timestamp(3), 'repaired', 'closed',
     p_actor_account_id, p_note, p_review_result);

  update work_order
     set status = 'closed'
   where work_order_id = p_work_order_id;

  select count(*)
    into v_pending_orders
    from work_order
   where alert_id = v_alert_id
     and status <> 'closed';

  if v_pending_orders = 0 then
    
    select max(ev.event_at)
      into v_normal_since
      from work_order_event ev
      join work_order w on w.work_order_id = ev.work_order_id
     where w.alert_id = v_alert_id
       and ev.event_type = 'closed';

    update device_alert
       set status = 'recovering',
           normal_since_at = v_normal_since
     where alert_id = v_alert_id
       and status <> 'recovered';

    call sp_recover_alert(v_alert_id, utc_timestamp(3));
  end if;
end ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_declare_incident` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_declare_incident`(
  in p_operator_id bigint unsigned,
  in p_station_id bigint unsigned,
  in p_category varchar(32),
  in p_severity varchar(8),
  in p_title varchar(200),
  in p_actor_account_id bigint unsigned,
  in p_alert_id bigint unsigned,
  out p_incident_id bigint unsigned
)
begin
  declare v_operator_of_station bigint unsigned;
  declare v_day varchar(8);
  declare v_seq int;
  declare v_no varchar(32);
  declare v_detected datetime(3);
  declare v_commander bigint unsigned;
  declare v_impact int default 0;
  declare v_id bigint unsigned;

  if p_station_id is not null then
    select operator_id into v_operator_of_station
      from station where station_id = p_station_id;
    if v_operator_of_station is null then
      signal sqlstate '45000' set message_text = '场站不存在';
    end if;
    if v_operator_of_station <> p_operator_id then
      signal sqlstate '45000' set message_text = '场站不属于该运营商，拒绝声明事件';
    end if;
  end if;

  
  set v_detected = null;
  if p_alert_id is not null then
    select occurred_at into v_detected from device_alert where alert_id = p_alert_id;
  end if;
  if v_detected is null then
    set v_detected = utc_timestamp(3);
  end if;

  
  set v_day = date_format(v_detected, '%Y%m%d');
  select coalesce(max(cast(substring_index(incident_no, '-', -1) as unsigned)), 0) + 1
    into v_seq
    from incident
   where incident_no like concat('INC-', v_day, '-%');
  set v_no = concat('INC-', v_day, '-', lpad(v_seq, 4, '0'));

  
  set v_commander = null;
  if p_station_id is not null then
    select coalesce(supervisor_account_id, primary_account_id) into v_commander
      from on_call_shift
     where scope_type = 'station' and scope_id = p_station_id
       and shift_start <= utc_timestamp(3) and shift_end > utc_timestamp(3)
     limit 1;
  end if;
  if v_commander is null then
    select coalesce(supervisor_account_id, primary_account_id) into v_commander
      from on_call_shift
     where scope_type = 'operator' and scope_id = p_operator_id
       and shift_start <= utc_timestamp(3) and shift_end > utc_timestamp(3)
     limit 1;
  end if;

  
  if p_station_id is not null then
    select count(distinct a.pile_id) into v_impact
      from device_alert a
      join charging_pile p on p.pile_id = a.pile_id
     where p.station_id = p_station_id
       and a.status <> 'recovered';
  else
    select count(distinct a.pile_id) into v_impact
      from device_alert a
      join charging_pile p on p.pile_id = a.pile_id
      join station s on s.station_id = p.station_id
     where s.operator_id = p_operator_id
       and a.status <> 'recovered';
  end if;

  insert into incident
    (incident_no, operator_id, station_id, category, severity, title, status,
     detected_at, declared_at, commander_account_id, impact_pile_count, impact_order_count)
  values
    (v_no, p_operator_id, p_station_id, p_category, p_severity, p_title, 'declared',
     v_detected, utc_timestamp(3), v_commander, v_impact, 0);

  set v_id = last_insert_id();
  set p_incident_id = v_id;

  if p_alert_id is not null then
    insert ignore into incident_alert
      (incident_id, alert_id, linked_at, linked_by, is_root_cause)
    values
      (v_id, p_alert_id, utc_timestamp(3), p_actor_account_id, 1);
  end if;

  insert into incident_action
    (incident_id, action_type, target_type, target_id, action_at, actor_account_id, reason)
  values
    (v_id, 'declare', 'none', null, utc_timestamp(3), p_actor_account_id,
     concat('声明 ', p_severity, ' 事件：', p_title));

  call sp_escalate_incidents(utc_timestamp(3));
end ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_escalate_incidents` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_escalate_incidents`(
  in p_now datetime(3)
)
begin
  declare v_done int default 0;
  declare v_incident_id bigint unsigned;
  declare v_severity varchar(8);
  declare v_impact int unsigned;
  declare v_elapsed int;
  declare v_policy_id bigint unsigned;
  declare v_level varchar(8);
  declare v_action varchar(32);
  declare v_notify bigint unsigned;
  declare v_level_num int;

  declare cur_incident cursor for
    select i.incident_id, i.severity, i.impact_pile_count
      from incident i
     where i.status in ('detected', 'declared', 'contained');
  declare continue handler for not found set v_done = 1;

  open cur_incident;
  read_loop: loop
    fetch cur_incident into v_incident_id, v_severity, v_impact;
    if v_done = 1 then
      leave read_loop;
    end if;

    
    set v_elapsed = (select timestampdiff(second, coalesce(i.declared_at, i.detected_at), p_now)
                       from incident i where i.incident_id = v_incident_id);

    set v_policy_id = (
      select p.policy_id
        from escalation_policy p
       where p.enabled = 1
         and (p.applies_severity = v_severity or p.applies_severity = 'ANY')
         and v_elapsed >= p.min_duration_seconds
         and v_impact  >= p.min_impact_piles
         and not exists (
               select 1 from incident_escalation e
                where e.incident_id = v_incident_id
                  and e.policy_id = p.policy_id
             )
       order by field(p.notify_level, 'L3', 'L2', 'L1'), p.min_duration_seconds desc
       limit 1);

    if v_policy_id is not null then
      select p.notify_level, p.action_code
        into v_level, v_action
        from escalation_policy p
       where p.policy_id = v_policy_id;

      set v_level_num = case v_level when 'L3' then 3 when 'L2' then 2 else 1 end;

      set v_notify = (
        select coalesce(sco.supervisor_account_id, sco.primary_account_id)
          from on_call_shift sco
          join incident i
            on (i.station_id is not null and sco.scope_type = 'station'  and sco.scope_id = i.station_id)
            or (i.station_id is null     and sco.scope_type = 'operator' and sco.scope_id = i.operator_id)
         where i.incident_id = v_incident_id
           and sco.shift_start <= p_now
           and sco.shift_end   >  p_now
         limit 1);

      if v_notify is null then
        set v_notify = (select commander_account_id from incident where incident_id = v_incident_id);
      end if;

      insert into incident_escalation
        (incident_id, policy_id, notify_level, triggered_at, notified_account_id, note)
      values
        (v_incident_id, v_policy_id, v_level, p_now, v_notify,
         concat('持续 ', v_elapsed, ' 秒，影响 ', v_impact, ' 桩，动作 ', v_action));

      update incident
         set escalation_level = greatest(escalation_level, v_level_num)
       where incident_id = v_incident_id;

      insert into incident_action
        (incident_id, action_type, target_type, action_at, reason)
      values
        (v_incident_id, 'escalate', 'none', p_now,
         concat('自动升级到 ', v_level, '，策略 ', v_policy_id));
    end if;
  end loop;
  close cur_incident;
end ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_recover_alert` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_recover_alert`(
  in p_alert_id bigint unsigned,
  in p_now datetime(3)
)
begin
  declare v_status varchar(32);
  declare v_normal_since datetime(3);
  declare v_pile_id bigint unsigned;
  declare v_recovery_seconds int unsigned;
  declare v_pending_orders int default 0;
  declare v_bad_samples int default 0;

  select a.status, a.normal_since_at, a.pile_id, r.recovery_seconds
    into v_status, v_normal_since, v_pile_id, v_recovery_seconds
    from device_alert a
    join alarm_rule r on r.alarm_rule_id = a.alarm_rule_id
   where a.alert_id = p_alert_id
   for update;

  if v_status is null then
    signal sqlstate '45000' set message_text = '告警不存在';
  end if;

  if v_status = 'recovering' and v_normal_since is not null then
    select count(*)
      into v_pending_orders
      from work_order
     where alert_id = p_alert_id
       and status <> 'closed';

    
    select count(*)
      into v_bad_samples
      from device_reading
     where pile_id = v_pile_id
       and sampled_at >= v_normal_since
       and sampled_at <= p_now
       and fault_code <> 'NONE';

    if v_pending_orders = 0
       and v_bad_samples = 0
       and timestampdiff(second, v_normal_since, p_now) >= v_recovery_seconds then
      update device_alert
         set status = 'recovered',
             recovered_at = p_now
       where alert_id = p_alert_id;
    end if;
  end if;
end ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `v_alert_response_detail`
--

/*!50001 DROP VIEW IF EXISTS `v_alert_response_detail`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_alert_response_detail` AS select `a`.`alert_id` AS `alert_id`,`a`.`pile_id` AS `pile_id`,`p`.`serial_no` AS `serial_no`,`p`.`station_id` AS `station_id`,`s`.`station_name` AS `station_name`,`a`.`gun_id` AS `gun_id`,`a`.`alert_code` AS `alert_code`,`a`.`severity` AS `severity`,`a`.`occurred_at` AS `occurred_at`,`a`.`status` AS `alert_status`,`a`.`response_seconds_snapshot` AS `response_seconds_snapshot`,`w`.`work_order_id` AS `work_order_id`,`w`.`assigned_to` AS `assigned_to`,`acc`.`username` AS `assignee_username`,`w`.`assigned_at` AS `assigned_at`,`w`.`response_due_at` AS `response_due_at`,`w`.`status` AS `work_order_status`,`w`.`escalation_level` AS `escalation_level`,`e`.`first_accepted_at` AS `first_accepted_at`,timestampdiff(SECOND,`a`.`occurred_at`,coalesce(`e`.`first_accepted_at`,utc_timestamp())) AS `response_seconds_actual`,(case when (`w`.`work_order_id` is null) then 0 when ((`e`.`first_accepted_at` is null) and (utc_timestamp() > `w`.`response_due_at`)) then 1 when (`e`.`first_accepted_at` > `w`.`response_due_at`) then 1 else 0 end) AS `is_overdue`,`a`.`normal_since_at` AS `normal_since_at`,`a`.`recovered_at` AS `recovered_at`,timestampdiff(SECOND,`a`.`occurred_at`,`a`.`recovered_at`) AS `total_seconds` from (((((`device_alert` `a` join `charging_pile` `p` on((`p`.`pile_id` = `a`.`pile_id`))) join `station` `s` on((`s`.`station_id` = `p`.`station_id`))) left join `work_order` `w` on((`w`.`alert_id` = `a`.`alert_id`))) left join `sys_account` `acc` on((`acc`.`account_id` = `w`.`assigned_to`))) left join (select `work_order_event`.`work_order_id` AS `work_order_id`,min((case when (`work_order_event`.`event_type` = 'accepted') then `work_order_event`.`event_at` end)) AS `first_accepted_at` from `work_order_event` group by `work_order_event`.`work_order_id`) `e` on((`e`.`work_order_id` = `w`.`work_order_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_device_realtime`
--

/*!50001 DROP VIEW IF EXISTS `v_device_realtime`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_device_realtime` AS select `p`.`pile_id` AS `pile_id`,`p`.`station_id` AS `station_id`,`s`.`station_name` AS `station_name`,`p`.`serial_no` AS `serial_no`,`p`.`model_name` AS `model_name`,`p`.`rated_power_kw` AS `rated_power_kw`,`p`.`lifecycle_status` AS `lifecycle_status`,`p`.`status` AS `pile_status`,`p`.`is_online` AS `is_online`,`p`.`has_fault` AS `has_fault`,`p`.`last_heartbeat_at` AS `last_heartbeat_at`,timestampdiff(SECOND,`p`.`last_heartbeat_at`,utc_timestamp()) AS `heartbeat_silence_seconds`,`g`.`gun_id` AS `gun_id`,`g`.`gun_no` AS `gun_no`,`g`.`gun_type` AS `gun_type`,`g`.`connector_standard` AS `connector_standard`,`g`.`max_power_kw` AS `gun_max_power_kw`,`g`.`status` AS `gun_status`,coalesce(`a`.`open_alert_count`,0) AS `open_alert_count`,coalesce(`a`.`worst_severity`,'none') AS `worst_open_severity`,`r`.`power_kw` AS `last_power_kw`,`r`.`module_temperature_c` AS `last_temperature_c`,`r`.`sampled_at` AS `last_sampled_at` from ((((`charging_pile` `p` join `station` `s` on((`s`.`station_id` = `p`.`station_id`))) left join `charging_gun` `g` on((`g`.`pile_id` = `p`.`pile_id`))) left join (select `device_alert`.`pile_id` AS `pile_id`,count(0) AS `open_alert_count`,(case min((case `device_alert`.`severity` when 'critical' then 1 when 'high' then 2 when 'medium' then 3 else 4 end)) when 1 then 'critical' when 2 then 'high' when 3 then 'medium' else 'low' end) AS `worst_severity` from `device_alert` where (`device_alert`.`status` <> 'recovered') group by `device_alert`.`pile_id`) `a` on((`a`.`pile_id` = `p`.`pile_id`))) left join (select `dr`.`pile_id` AS `pile_id`,`dr`.`power_kw` AS `power_kw`,`dr`.`module_temperature_c` AS `module_temperature_c`,`dr`.`sampled_at` AS `sampled_at` from (`device_reading` `dr` join (select `device_reading`.`pile_id` AS `pile_id`,max(`device_reading`.`sample_id`) AS `last_sample_id` from `device_reading` group by `device_reading`.`pile_id`) `m` on((`m`.`last_sample_id` = `dr`.`sample_id`)))) `r` on((`r`.`pile_id` = `p`.`pile_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_emergency_metrics`
--

/*!50001 DROP VIEW IF EXISTS `v_emergency_metrics`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_emergency_metrics` AS select date_format(`v_incident_board`.`detected_at`,'%Y-%m') AS `bill_month`,`v_incident_board`.`severity` AS `severity`,count(0) AS `incident_count`,sum((case when (`v_incident_board`.`ack_breached` = 0) then 1 else 0 end)) AS `ack_ok_count`,sum(`v_incident_board`.`ack_breached`) AS `ack_breach_count`,sum(`v_incident_board`.`restore_breached`) AS `restore_breach_count`,round(avg(`v_incident_board`.`ack_seconds`),0) AS `avg_ack_seconds`,round(avg(`v_incident_board`.`restore_seconds`),0) AS `avg_restore_seconds` from `v_incident_board` where (`v_incident_board`.`status` in ('restored','reviewed','closed')) group by date_format(`v_incident_board`.`detected_at`,'%Y-%m'),`v_incident_board`.`severity` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_incident_board`
--

/*!50001 DROP VIEW IF EXISTS `v_incident_board`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_incident_board` AS select `i`.`incident_id` AS `incident_id`,`i`.`incident_no` AS `incident_no`,`i`.`operator_id` AS `operator_id`,`o`.`operator_name` AS `operator_name`,`i`.`station_id` AS `station_id`,`s`.`station_name` AS `station_name`,`i`.`category` AS `category`,`i`.`severity` AS `severity`,`i`.`title` AS `title`,`i`.`status` AS `status`,`i`.`detected_at` AS `detected_at`,`i`.`declared_at` AS `declared_at`,`i`.`contained_at` AS `contained_at`,`i`.`restored_at` AS `restored_at`,`i`.`closed_at` AS `closed_at`,`i`.`commander_account_id` AS `commander_account_id`,`c`.`username` AS `commander_username`,`i`.`impact_pile_count` AS `impact_pile_count`,`i`.`impact_order_count` AS `impact_order_count`,`i`.`estimated_loss_amount` AS `estimated_loss_amount`,`i`.`escalation_level` AS `escalation_level`,coalesce(`al`.`alert_count`,0) AS `alert_count`,coalesce(`wo`.`open_work_orders`,0) AS `open_work_orders`,`sla`.`ack_seconds` AS `ack_limit_seconds`,`sla`.`restore_seconds` AS `restore_limit_seconds`,timestampdiff(SECOND,`i`.`detected_at`,coalesce(`i`.`declared_at`,utc_timestamp())) AS `ack_seconds`,timestampdiff(SECOND,`i`.`detected_at`,coalesce(`i`.`restored_at`,utc_timestamp())) AS `restore_seconds`,(case when (timestampdiff(SECOND,`i`.`detected_at`,coalesce(`i`.`declared_at`,utc_timestamp())) > `sla`.`ack_seconds`) then 1 else 0 end) AS `ack_breached`,(case when (timestampdiff(SECOND,`i`.`detected_at`,coalesce(`i`.`restored_at`,utc_timestamp())) > `sla`.`restore_seconds`) then 1 else 0 end) AS `restore_breached` from ((((((`incident` `i` join `operator` `o` on((`o`.`operator_id` = `i`.`operator_id`))) left join `station` `s` on((`s`.`station_id` = `i`.`station_id`))) left join `sys_account` `c` on((`c`.`account_id` = `i`.`commander_account_id`))) join `incident_sla` `sla` on((`sla`.`severity` = `i`.`severity`))) left join (select `incident_alert`.`incident_id` AS `incident_id`,count(0) AS `alert_count` from `incident_alert` group by `incident_alert`.`incident_id`) `al` on((`al`.`incident_id` = `i`.`incident_id`))) left join (select `ia`.`incident_id` AS `incident_id`,count(0) AS `open_work_orders` from (`incident_alert` `ia` join `work_order` `w` on((`w`.`alert_id` = `ia`.`alert_id`))) where (`w`.`status` <> 'closed') group by `ia`.`incident_id`) `wo` on((`wo`.`incident_id` = `i`.`incident_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_on_call_now`
--

/*!50001 DROP VIEW IF EXISTS `v_on_call_now`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_on_call_now` AS select `sc`.`shift_id` AS `shift_id`,`sc`.`scope_type` AS `scope_type`,`sc`.`scope_id` AS `scope_id`,(case `sc`.`scope_type` when 'station' then (select `station`.`station_name` from `station` where (`station`.`station_id` = `sc`.`scope_id`)) else (select `operator`.`operator_name` from `operator` where (`operator`.`operator_id` = `sc`.`scope_id`)) end) AS `scope_name`,`sc`.`shift_start` AS `shift_start`,`sc`.`shift_end` AS `shift_end`,`sc`.`status` AS `status`,`p`.`username` AS `primary_username`,`b`.`username` AS `backup_username`,`sp`.`username` AS `supervisor_username`,(case when ((utc_timestamp() >= `sc`.`shift_start`) and (utc_timestamp() < `sc`.`shift_end`)) then 1 else 0 end) AS `is_current` from (((`on_call_shift` `sc` left join `sys_account` `p` on((`p`.`account_id` = `sc`.`primary_account_id`))) left join `sys_account` `b` on((`b`.`account_id` = `sc`.`backup_account_id`))) left join `sys_account` `sp` on((`sp`.`account_id` = `sc`.`supervisor_account_id`))) where ((`sc`.`shift_end` >= utc_timestamp()) and (`sc`.`shift_start` <= (utc_timestamp() + interval 1 day))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_part_stock_alert`
--

/*!50001 DROP VIEW IF EXISTS `v_part_stock_alert`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_part_stock_alert` AS select `p`.`part_id` AS `part_id`,`p`.`part_code` AS `part_code`,`p`.`part_name` AS `part_name`,`p`.`model` AS `model`,`p`.`station_id` AS `station_id`,`s`.`station_name` AS `station_name`,`p`.`stock_qty` AS `stock_qty`,`p`.`safety_stock` AS `safety_stock`,(cast(`p`.`stock_qty` as signed) - cast(`p`.`safety_stock` as signed)) AS `gap`,(case when (`p`.`stock_qty` = 0) then 'out_of_stock' when (`p`.`stock_qty` < `p`.`safety_stock`) then 'low' else 'at_safety' end) AS `stock_status` from (`spare_part` `p` left join `station` `s` on((`s`.`station_id` = `p`.`station_id`))) where ((`p`.`status` = 'active') and (`p`.`stock_qty` <= `p`.`safety_stock`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_work_order_progress`
--

/*!50001 DROP VIEW IF EXISTS `v_work_order_progress`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_work_order_progress` AS select `w`.`work_order_id` AS `work_order_id`,`w`.`alert_id` AS `alert_id`,`a`.`alert_code` AS `alert_code`,`a`.`severity` AS `severity`,`a`.`pile_id` AS `pile_id`,`p`.`serial_no` AS `serial_no`,`s`.`station_name` AS `station_name`,`w`.`assigned_to` AS `assigned_to`,`w`.`assigned_by` AS `assigned_by`,`w`.`assigned_at` AS `assigned_at`,`w`.`response_due_at` AS `response_due_at`,`w`.`status` AS `work_order_status`,`w`.`escalation_level` AS `escalation_level`,`w`.`parts_used` AS `parts_used`,`w`.`result` AS `result`,`e`.`first_accepted_at` AS `first_accepted_at`,`e`.`first_arrived_at` AS `first_arrived_at`,`e`.`last_repaired_at` AS `last_repaired_at`,`e`.`first_review_passed_at` AS `first_review_passed_at`,`e`.`closed_at` AS `closed_at`,`e`.`review_failed_count` AS `review_failed_count`,`e`.`escalated_count` AS `escalated_count`,timestampdiff(SECOND,`w`.`assigned_at`,`e`.`first_accepted_at`) AS `accept_seconds`,timestampdiff(SECOND,`e`.`first_accepted_at`,`e`.`first_arrived_at`) AS `arrive_seconds`,timestampdiff(SECOND,`e`.`first_arrived_at`,`e`.`last_repaired_at`) AS `repair_seconds`,timestampdiff(SECOND,`e`.`last_repaired_at`,`e`.`closed_at`) AS `review_seconds`,timestampdiff(SECOND,`w`.`assigned_at`,`e`.`closed_at`) AS `total_seconds`,(case when (`e`.`first_accepted_at` is null) then (case when (utc_timestamp() > `w`.`response_due_at`) then 1 else 0 end) when (`e`.`first_accepted_at` > `w`.`response_due_at`) then 1 else 0 end) AS `accept_overdue` from ((((`work_order` `w` join `device_alert` `a` on((`a`.`alert_id` = `w`.`alert_id`))) join `charging_pile` `p` on((`p`.`pile_id` = `a`.`pile_id`))) join `station` `s` on((`s`.`station_id` = `p`.`station_id`))) left join (select `work_order_event`.`work_order_id` AS `work_order_id`,min((case when (`work_order_event`.`event_type` = 'accepted') then `work_order_event`.`event_at` end)) AS `first_accepted_at`,min((case when (`work_order_event`.`event_type` = 'arrived') then `work_order_event`.`event_at` end)) AS `first_arrived_at`,max((case when (`work_order_event`.`event_type` = 'repaired') then `work_order_event`.`event_at` end)) AS `last_repaired_at`,min((case when (`work_order_event`.`event_type` = 'review_passed') then `work_order_event`.`event_at` end)) AS `first_review_passed_at`,max((case when (`work_order_event`.`event_type` = 'closed') then `work_order_event`.`event_at` end)) AS `closed_at`,sum((case when (`work_order_event`.`event_type` = 'review_failed') then 1 else 0 end)) AS `review_failed_count`,sum((case when (`work_order_event`.`event_type` = 'escalated') then 1 else 0 end)) AS `escalated_count` from `work_order_event` group by `work_order_event`.`work_order_id`) `e` on((`e`.`work_order_id` = `w`.`work_order_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-19 18:25:41
