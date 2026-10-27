CREATE TABLE IF NOT EXISTS triple_term (
	term_id INTEGER PRIMARY KEY REFERENCES term,
	subject BIGINT NOT NULL REFERENCES term,
	predicate BIGINT NOT NULL REFERENCES term,
	object BIGINT NOT NULL REFERENCES term
);

CREATE INDEX triple_term_spo ON triple_term (subject, predicate, object);
CREATE INDEX triple_term_pos ON triple_term (predicate, object, subject);
CREATE INDEX triple_term_osp ON triple_term (object, subject, predicate);

ALTER TABLE `attean_version` ADD COLUMN `model_version` INTEGER NOT NULL;
ALTER TABLE `attean_version` ADD COLUMN `notes` LONGTEXT;
DELETE FROM attean_version;
INSERT INTO attean_version (store_version, model_version, notes) VALUES ("0.004", 1, "populated by schema creation");
