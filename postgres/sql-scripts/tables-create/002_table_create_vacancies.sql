CREATE TABLE vacancies
(
	id                                          INT                     NOT NULL    GENERATED BY DEFAULT AS IDENTITY(MINVALUE 0 START WITH 0 INCREMENT BY 1),
	name                                        VARCHAR(64)             NOT NULL,
	parent                                      INT,
	CONSTRAINT pkey_vacancies_id	            PRIMARY KEY(id),
	CONSTRAINT ukey_vacancies_name_and_parent	UNIQUE(name, parent),
    CONSTRAINT fkey_vacancies_to_vacancies      FOREIGN KEY(parent)     REFERENCES vacancies(id)
);
INSERT INTO vacancies(id, name, parent) VALUES (0, 'Любая', NULL);