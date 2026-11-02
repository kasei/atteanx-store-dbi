ALTER TABLE `term` MODIFY COLUMN `type` ENUM('iri', 'literal', 'blank', 'triple');

CREATE TABLE IF NOT EXISTS triple_term (
	term_id BIGINT UNSIGNED PRIMARY KEY REFERENCES term,
	subject BIGINT UNSIGNED NOT NULL REFERENCES term,
	predicate BIGINT UNSIGNED NOT NULL REFERENCES term,
	object BIGINT UNSIGNED NOT NULL REFERENCES term,
	KEY (subject, predicate, object),
	KEY (predicate, object, subject),
	KEY (object, subject, predicate),
	INDEX (graph)
);


ALTER TABLE `attean_version` ADD COLUMN `model_version` INTEGER NOT NULL;
ALTER TABLE `attean_version` ADD COLUMN `notes` LONGTEXT;
DELETE FROM attean_version;
INSERT INTO attean_version (store_version, model_version, notes) VALUES ("0.004", 1, "populated by schema creation");
