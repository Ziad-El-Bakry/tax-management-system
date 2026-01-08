-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jan 08, 2026 at 06:27 AM
-- Server version: 8.0.30
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tax_system_php`
--

-- --------------------------------------------------------

--
-- Table structure for table `audit_log`
--

CREATE TABLE `audit_log` (
  `log_id` bigint NOT NULL,
  `table_name` varchar(50) DEFAULT NULL,
  `operation` varchar(20) DEFAULT NULL,
  `old_data` json DEFAULT NULL,
  `new_data` json DEFAULT NULL,
  `changed_by` varchar(100) DEFAULT NULL,
  `change_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `audit_log`
--

INSERT INTO `audit_log` (`log_id`, `table_name`, `operation`, `old_data`, `new_data`, `changed_by`, `change_time`) VALUES
(35, 'tax_returns', 'UPDATE', '{\"status\": \"Overdue\", \"return_id\": 9, \"tax_amount\": 12000.00}', '{\"status\": \"Overdue\", \"return_id\": 9, \"tax_amount\": 12000.00}', 'root@localhost', '2026-01-08 06:19:53'),
(36, 'tax_returns', 'DELETE', '{\"return_id\": 212, \"tax_amount\": 8000.00}', NULL, 'root@localhost', '2026-01-08 06:23:43'),
(37, 'tax_returns', 'DELETE', '{\"return_id\": 214, \"tax_amount\": 12000.00}', NULL, 'root@localhost', '2026-01-08 06:25:00'),
(38, 'tax_returns', 'DELETE', '{\"return_id\": 31, \"tax_amount\": 17175.30}', NULL, 'root@localhost', '2026-01-08 06:25:49');

-- --------------------------------------------------------

--
-- Table structure for table `citizens`
--

CREATE TABLE `citizens` (
  `citizen_id` int NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `citizens`
--

INSERT INTO `citizens` (`citizen_id`, `full_name`, `email`, `created_at`) VALUES
(9, 'ahmed ail', 'ahmed12ali@gmail.com', '2026-01-08 06:09:26'),
(32, 'حسن نصر', 'user825122@example.com', '2026-01-06 07:46:01');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `payment_id` int NOT NULL,
  `return_id` int DEFAULT NULL,
  `amount` decimal(12,2) DEFAULT NULL,
  `payment_date` date NOT NULL,
  `payment_method` enum('Bank Transfer','Mobile App','Tax Office') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
PARTITION BY RANGE (year(`payment_date`))
(
PARTITION p_2024 VALUES LESS THAN (2025) ENGINE=InnoDB,
PARTITION p_future VALUES LESS THAN MAXVALUE ENGINE=InnoDB
);

--
-- Triggers `payments`
--
DELIMITER $$
CREATE TRIGGER `update_status_after_payment` AFTER INSERT ON `payments` FOR EACH ROW BEGIN
    DECLARE total_paid DECIMAL(12,2);
    DECLARE required_amount DECIMAL(12,2);

    -- 1. حساب إجمالي ما تم دفعه لهذا الإقرار (شامل الدفعة الجديدة)
    SELECT SUM(amount) INTO total_paid
    FROM payments
    WHERE return_id = NEW.return_id;

    -- 2. معرفة المبلغ الأصلي المطلوب
    SELECT tax_amount INTO required_amount
    FROM tax_returns
    WHERE return_id = NEW.return_id;

    -- 3. تحديث الحالة بناءً على الحسابات
    IF total_paid >= required_amount THEN
        UPDATE tax_returns 
        SET status = 'PAID' 
        WHERE return_id = NEW.return_id;
    ELSE
        UPDATE tax_returns 
        SET status = 'PARTIAL_PAYMENT' 
        WHERE return_id = NEW.return_id;
    END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tax_returns`
--

CREATE TABLE `tax_returns` (
  `return_id` int NOT NULL,
  `citizen_id` int DEFAULT NULL,
  `tax_year` int NOT NULL,
  `declared_income` decimal(12,2) DEFAULT NULL,
  `tax_amount` decimal(12,2) DEFAULT NULL,
  `status` varchar(30) DEFAULT 'PENDING',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `tax_returns`
--

INSERT INTO `tax_returns` (`return_id`, `citizen_id`, `tax_year`, `declared_income`, `tax_amount`, `status`, `created_at`) VALUES
(30, 32, 2022, 305649.00, 30564.90, 'Pending', '2026-01-06 07:46:01'),
(211, 9, 2024, 80000.00, 8000.00, 'Paid', '2026-01-08 06:10:55'),
(213, 9, 2025, 120000.00, 12000.00, 'PENDING', '2026-01-08 06:11:40');

--
-- Triggers `tax_returns`
--
DELIMITER $$
CREATE TRIGGER `tax_returns_audit_delete` AFTER DELETE ON `tax_returns` FOR EACH ROW BEGIN
    INSERT INTO audit_log (
        table_name, operation, old_data, new_data, changed_by
    )
    VALUES (
        'tax_returns',
        'DELETE',
        JSON_OBJECT(
            'return_id', OLD.return_id,
            'tax_amount', OLD.tax_amount
        ),
        NULL,
        USER()
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tax_returns_audit_update` AFTER UPDATE ON `tax_returns` FOR EACH ROW BEGIN
    INSERT INTO audit_log (
        table_name, operation, old_data, new_data, changed_by
    )
    VALUES (
        'tax_returns',
        'UPDATE',
        JSON_OBJECT(
            'return_id', OLD.return_id,
            'tax_amount', OLD.tax_amount,
            'status', OLD.status
        ),
        JSON_OBJECT(
            'return_id', NEW.return_id,
            'tax_amount', NEW.tax_amount,
            'status', NEW.status
        ),
        USER()
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tax_returns_backup`
--

CREATE TABLE `tax_returns_backup` (
  `return_id` int NOT NULL DEFAULT '0',
  `citizen_id` int DEFAULT NULL,
  `tax_year` int NOT NULL,
  `declared_income` decimal(12,2) DEFAULT NULL,
  `tax_amount` decimal(12,2) DEFAULT NULL,
  `status` varchar(30) DEFAULT 'PENDING',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `full_name` varchar(100) DEFAULT 'Admin User',
  `role` varchar(20) DEFAULT 'admin',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `password`, `full_name`, `role`, `created_at`) VALUES
(1, 'admin', '123', 'مدير النظام', 'admin', '2026-01-06 07:07:33'),
(9, 'ahmed ali', '123', 'User', 'user', '2026-01-08 06:07:44'),
(32, 'حسن نصر', '123', 'رجل اعمال', 'user', '2026-01-06 09:51:13');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `audit_log`
--
ALTER TABLE `audit_log`
  ADD PRIMARY KEY (`log_id`);

--
-- Indexes for table `citizens`
--
ALTER TABLE `citizens`
  ADD PRIMARY KEY (`citizen_id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`payment_id`,`payment_date`),
  ADD KEY `return_id` (`return_id`);

--
-- Indexes for table `tax_returns`
--
ALTER TABLE `tax_returns`
  ADD PRIMARY KEY (`return_id`),
  ADD KEY `citizen_id` (`citizen_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `audit_log`
--
ALTER TABLE `audit_log`
  MODIFY `log_id` bigint NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=39;

--
-- AUTO_INCREMENT for table `citizens`
--
ALTER TABLE `citizens`
  MODIFY `citizen_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=223;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `payment_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `tax_returns`
--
ALTER TABLE `tax_returns`
  MODIFY `return_id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=215;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=35;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
