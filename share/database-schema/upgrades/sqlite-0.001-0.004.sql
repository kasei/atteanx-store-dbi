ALTER TABLE `attean_version` ADD COLUMN `model_version` INTEGER NOT NULL;
ALTER TABLE `attean_version` ADD COLUMN `notes` LONGTEXT;
DELETE FROM attean_version;
INSERT INTO attean_version (store_version, model_version, notes) VALUES ("0.004", 1, "populated by schema creation");
