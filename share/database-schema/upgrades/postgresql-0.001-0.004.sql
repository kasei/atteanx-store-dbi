ALTER TYPE TERM_TYPE ADD VALUE 'triple';

CREATE TABLE IF NOT EXISTS triple_term (
	term_id BIGINT PRIMARY KEY REFERENCES term,
	subject BIGINT NOT NULL REFERENCES term,
	predicate BIGINT NOT NULL REFERENCES term,
	object BIGINT NOT NULL REFERENCES term,
	KEY (subject, predicate, object),
	KEY (predicate, object, subject),
	KEY (object, subject, predicate)
);

ALTER TABLE attean_version ADD COLUMN model_version INTEGER NOT NULL;
ALTER TABLE attean_version ADD COLUMN notes TEXT;
DELETE FROM attean_version;
INSERT INTO attean_version (store_version, model_version, notes) VALUES ('0.004', 1, 'populated by schema creation');
