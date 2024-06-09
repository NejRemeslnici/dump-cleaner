-- MySQLShell dump 2.0.1  Distrib Ver 8.4.0 for Linux on x86_64 - for MySQL 8.4.0 (MySQL Community Server (GPL)), for Linux (x86_64)
--
-- Host: localhost    Database: db    Table: users
-- ------------------------------------------------------
-- Server version	8.4.0

--
-- Table structure for table `users`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE IF NOT EXISTS `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `e_mail` varchar(255) DEFAULT NULL,
  `phone_number` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
