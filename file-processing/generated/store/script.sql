-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS `Person`;

CREATE TABLE `Person` (
	`firstName` VARCHAR(191) NOT NULL,
	`lastName` VARCHAR(191) NOT NULL,
	`phone` VARCHAR(191) NOT NULL,
	PRIMARY KEY(`firstName`,`lastName`)
);
