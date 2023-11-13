-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS `Task`;
DROP TABLE IF EXISTS `Employee`;

CREATE TABLE `Employee` (
	`id` INT NOT NULL,
	`name` VARCHAR(191) NOT NULL,
	`age` INT NOT NULL,
	`phone` VARCHAR(191) NOT NULL,
	`email` VARCHAR(191) NOT NULL,
	`department` VARCHAR(191) NOT NULL,
	PRIMARY KEY(`id`)
);

CREATE TABLE `Task` (
	`taskId` INT NOT NULL,
	`taskName` VARCHAR(191) NOT NULL,
	`description` VARCHAR(191) NOT NULL,
	`status` ENUM('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED') NOT NULL,
	`employeeId` INT NOT NULL,
	FOREIGN KEY(`employeeId`) REFERENCES `Employee`(`id`),
	PRIMARY KEY(`taskId`)
);
