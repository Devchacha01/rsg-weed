-- RSG-Weed Database Schema
-- Run this file to create or update the required tables

-- Create the plants table
CREATE TABLE IF NOT EXISTS `rsg_weed_plants` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `strain` varchar(50) NOT NULL DEFAULT 'kalka',
    `coords` text NOT NULL,
    `stage` int(11) NOT NULL DEFAULT 1,
    `water` float NOT NULL DEFAULT 100.0,
    `growth` float NOT NULL DEFAULT 0.0,
    `quality` float NOT NULL DEFAULT 100.0,
    `fertilized` tinyint(1) NOT NULL DEFAULT 0,
    `citizenid` varchar(50) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

