CREATE TABLE resumes
(
	id                                      INT                                 NOT NULL        GENERATED BY DEFAULT AS IDENTITY(MINVALUE 0 START WITH 0 INCREMENT BY 1),
	full_name                               VARCHAR(255)                        NOT NULL,
	about                                   TEXT,
	work_experience                         INT                                 NOT NULL		DEFAULT 0,
	desired_salary                          DOUBLE PRECISION                    NOT NULL,
	birth_date                              DATE                                NOT NULL,
	sending_datetime                        TIMESTAMP                           NOT NULL		DEFAULT NOW(),
	city_to_work_in_id                      INT                                 NOT NULL		DEFAULT 0,
	desired_vacancy_id                      INT                                 NOT NULL		DEFAULT 0,
	avatar                                  BYTEA,
	file                                    BYTEA,
	file_name                               VARCHAR(255),
	CONSTRAINT pkey_resumes_id	            PRIMARY KEY(id),
	CONSTRAINT ukey_resumes_full_name	    UNIQUE(full_name),
    CONSTRAINT fkey_resumes_to_cities       FOREIGN KEY(city_to_work_in_id)     REFERENCES cities(id),
    CONSTRAINT fkey_resumes_to_vacancies    FOREIGN KEY(desired_vacancy_id)     REFERENCES vacancies(id)
);

DROP FUNCTION IF EXISTS generate_where;
CREATE FUNCTION generate_where(
	IN filter_id_from               INT					DEFAULT NULL,
	IN filter_id_to                 INT					DEFAULT NULL,
	IN filter_fullName           	VARCHAR(255)		DEFAULT NULL,
	IN filter_about                	TEXT				DEFAULT NULL,
	IN filter_workExperience_from   INT					DEFAULT NULL,
	IN filter_workExperience_to     INT					DEFAULT NULL,
	IN filter_desiredSalary_from    DOUBLE PRECISION	DEFAULT NULL,
	IN filter_desiredSalary_to      DOUBLE PRECISION	DEFAULT NULL,
	IN filter_birthDate_from       	DATE				DEFAULT NULL,
	IN filter_birthDate_to          DATE				DEFAULT NULL,
	IN filter_sendingDatetime_from  TIMESTAMP			DEFAULT NULL,
	IN filter_sendingDatetime_to   	TIMESTAMP			DEFAULT NULL,
	IN filter_citiesToWorkInIds 	TEXT				DEFAULT NULL,
	IN filter_desiredVacanciesIds  	TEXT				DEFAULT NULL,
	IN sort_field           		VARCHAR(255)		DEFAULT 'id',
	IN sort_ascOrDesc           	VARCHAR(4)			DEFAULT 'asc',
	IN records_on_page              INT					DEFAULT 20,
	IN page                  		INT					DEFAULT 1
)
RETURNS TEXT
LANGUAGE 'plpgsql'
AS $$
DECLARE
	sql_query TEXT;
BEGIN
	-- Первое условие WHERE необходимо для того, чтобы WHERE не был пустым при отсутсвии всех условий фильтрации
	sql_query = ' WHERE (TRUE)';

	IF filter_id_from 				is not null THEN
		sql_query = sql_query || ' AND (resumes.id >= ' || filter_id_from || ')';
	END IF;
	IF filter_id_to 				is not null THEN
		sql_query = sql_query || ' AND (resumes.id <= ' || filter_id_to || ')';
	END IF;

	IF filter_fullName 				is not null THEN
		sql_query = sql_query || format(' AND (resumes.full_name LIKE %L)', '%' || filter_fullName || '%');
	END IF;
	IF filter_about 				is not null THEN
		sql_query = sql_query || format(' AND (resumes.about LIKE %L)', '%' || filter_about || '%');
	END IF;

	IF filter_workExperience_from 	is not null THEN
		sql_query = sql_query || ' AND (resumes.work_experience >= ' || filter_workExperience_from || ')';
	END IF;
	IF filter_workExperience_to 	is not null THEN
		sql_query = sql_query || ' AND (resumes.work_experience <= ' || filter_workExperience_to || ')';
	END IF;

	IF filter_desiredSalary_from 	is not null THEN
		sql_query = sql_query || ' AND (resumes.desired_salary >= ' || filter_desiredSalary_from || ')';
	END IF;
	IF filter_desiredSalary_to 		is not null THEN
		sql_query = sql_query || ' AND (resumes.desired_salary <= ' || filter_desiredSalary_to || ')';
	END IF;

	IF filter_birthDate_from 		is not null THEN
		sql_query = sql_query || format(' AND (resumes.birth_date >= %L::date)', filter_birthDate_from);
	END IF;
	IF filter_birthDate_to 			is not null THEN
		sql_query = sql_query || format(' AND (resumes.birth_date <= %L::date)', filter_birthDate_to);
	END IF;

	IF filter_sendingDatetime_from 	is not null THEN
		sql_query = sql_query || format(' AND (resumes.sending_datetime >= %L::timestamp)', filter_sendingDatetime_from);
	END IF;
	IF filter_sendingDatetime_to 	is not null THEN
		sql_query = sql_query || format(' AND (resumes.sending_datetime <= %L::timestamp)', filter_sendingDatetime_to);
	END IF;

	IF filter_citiesToWorkInIds 	is not null THEN
		sql_query = sql_query || format(' AND (resumes.city_to_work_in_id = ANY (%L))', filter_citiesToWorkInIds);
	END IF;

	IF filter_desiredVacanciesIds 	is not null THEN
		sql_query = sql_query || format(' AND (resumes.desired_vacancy_id = ANY (%L))', filter_desiredVacanciesIds);
	END IF;

	RETURN sql_query;
END $$;

DROP FUNCTION IF EXISTS get_records;
CREATE FUNCTION get_records(
	IN filter_id_from               INT					DEFAULT NULL,
	IN filter_id_to                 INT					DEFAULT NULL,
	IN filter_fullName           	VARCHAR(255)		DEFAULT NULL,
	IN filter_about                	TEXT				DEFAULT NULL,
	IN filter_workExperience_from   INT					DEFAULT NULL,
	IN filter_workExperience_to     INT					DEFAULT NULL,
	IN filter_desiredSalary_from    DOUBLE PRECISION	DEFAULT NULL,
	IN filter_desiredSalary_to      DOUBLE PRECISION	DEFAULT NULL,
	IN filter_birthDate_from       	DATE				DEFAULT NULL,
	IN filter_birthDate_to          DATE				DEFAULT NULL,
	IN filter_sendingDatetime_from  TIMESTAMP			DEFAULT NULL,
	IN filter_sendingDatetime_to   	TIMESTAMP			DEFAULT NULL,
	IN filter_citiesToWorkInIds 	TEXT				DEFAULT NULL,
	IN filter_desiredVacanciesIds  	TEXT				DEFAULT NULL,
	IN sort_field           		VARCHAR(255)		DEFAULT 'id',
	IN sort_ascOrDesc           	VARCHAR(4)			DEFAULT 'asc',
	IN records_on_page              INT					DEFAULT 20,
	IN page                  		INT					DEFAULT 1
)
RETURNS TABLE (
	id                  			INT,
	full_name           			VARCHAR(255),
	about                			TEXT,
	work_experience      			INT,
	desired_salary       			DOUBLE PRECISION,
	birth_date           			DATE,
	sending_datetime      			TIMESTAMP,
	city_to_work_in_id    			INT,
	desired_vacancy_id    			INT,
	avatar                			BYTEA,
	file                  			BYTEA,
	file_name             			VARCHAR(255)
)
LANGUAGE 'plpgsql'
AS $$
DECLARE
	sql_query TEXT;
BEGIN
	-- Первое условие WHERE необходимо для того, чтобы WHERE не был пустым при отсутсвии всех условий фильтрации
	sql_query = 'SELECT * FROM resumes';
	sql_query = sql_query || generate_where(
		filter_id_from,
		filter_id_to,
		filter_fullName,
		filter_about,
		filter_workExperience_from,
		filter_workExperience_to,
		filter_desiredSalary_from,
		filter_desiredSalary_to,
		filter_birthDate_from,
		filter_birthDate_to,
		filter_sendingDatetime_from,
		filter_sendingDatetime_to,
		filter_citiesToWorkInIds,
		filter_desiredVacanciesIds,
		sort_field,
		sort_ascOrDesc,
		records_on_page,
		page
	);
	sql_query = sql_query || ' ORDER BY resumes.' || sort_field || ' ' || sort_ascOrDesc;
	sql_query = sql_query || ' LIMIT ' || records_on_page || ' OFFSET ' || ((page - 1) * records_on_page);
	sql_query = sql_query || ';';
	RETURN QUERY EXECUTE sql_query;
END $$;

DROP FUNCTION IF EXISTS get_records_pages_number;
CREATE FUNCTION get_records_pages_number(
	IN filter_id_from               INT					DEFAULT NULL,
	IN filter_id_to                 INT					DEFAULT NULL,
	IN filter_fullName           	VARCHAR(255)		DEFAULT NULL,
	IN filter_about                	TEXT				DEFAULT NULL,
	IN filter_workExperience_from   INT					DEFAULT NULL,
	IN filter_workExperience_to     INT					DEFAULT NULL,
	IN filter_desiredSalary_from    DOUBLE PRECISION	DEFAULT NULL,
	IN filter_desiredSalary_to      DOUBLE PRECISION	DEFAULT NULL,
	IN filter_birthDate_from       	DATE				DEFAULT NULL,
	IN filter_birthDate_to          DATE				DEFAULT NULL,
	IN filter_sendingDatetime_from  TIMESTAMP			DEFAULT NULL,
	IN filter_sendingDatetime_to   	TIMESTAMP			DEFAULT NULL,
	IN filter_citiesToWorkInIds 	TEXT				DEFAULT NULL,
	IN filter_desiredVacanciesIds  	TEXT				DEFAULT NULL,
	IN sort_field           		VARCHAR(255)		DEFAULT 'id',
	IN sort_ascOrDesc           	VARCHAR(4)			DEFAULT 'asc',
	IN records_on_page              INT					DEFAULT 20,
	IN page                  		INT					DEFAULT 1
)
RETURNS TABLE(
	pages_number           			INT
)
LANGUAGE 'plpgsql'
AS $$
DECLARE
	sql_query TEXT;
BEGIN
	sql_query = 'SELECT ceil(count(*) / ' || records_on_page || '::float)::integer as pages_number FROM resumes ' || generate_where(
		filter_id_from,
		filter_id_to,
		filter_fullName,
		filter_about,
		filter_workExperience_from,
		filter_workExperience_to,
		filter_desiredSalary_from,
		filter_desiredSalary_to,
		filter_birthDate_from,
		filter_birthDate_to,
		filter_sendingDatetime_from,
		filter_sendingDatetime_to,
		filter_citiesToWorkInIds,
		filter_desiredVacanciesIds,
		sort_field,
		sort_ascOrDesc,
		records_on_page,
		page
	) || ';';
	RETURN QUERY EXECUTE sql_query;
END $$;

DROP FUNCTION IF EXISTS get_record;
CREATE FUNCTION get_record(
	IN _id					INT
)
RETURNS TABLE (
	id                  	INT,
	full_name           	VARCHAR(255),
	about                	TEXT,
	work_experience      	INT,
	desired_salary       	DOUBLE PRECISION,
	birth_date           	DATE,
	sending_datetime      	TIMESTAMP,
	city_to_work_in_id    	INT,
	desired_vacancy_id    	INT,
	avatar                	BYTEA,
	file                  	BYTEA,
	file_name             	VARCHAR(255)
)
LANGUAGE 'plpgsql'
AS $$
BEGIN
	RETURN QUERY (SELECT * FROM resumes WHERE resumes.id = _id);
END $$;

DROP FUNCTION IF EXISTS add_record;
CREATE FUNCTION add_record(
	IN _full_name 			VARCHAR(255),
	IN _about				TEXT,
	IN _work_experience		INT,
	IN _desired_salary 		DOUBLE PRECISION,
	IN _birth_date 			DATE,
	IN _sending_datetime 	TIMESTAMP 			DEFAULT now(),
	IN _city_to_work_in_id 	INT 				DEFAULT 0,
	IN _desired_vacancy_id	INT 				DEFAULT 0,
	IN _avatar 				BYTEA				DEFAULT null,
	IN _file 				BYTEA 				DEFAULT null,
	IN _file_name 			TEXT 				DEFAULT null
)
RETURNS VARCHAR(255)
LANGUAGE 'plpgsql'
AS $$
BEGIN
	INSERT INTO resumes(
		full_name,
		about,
		work_experience,
		desired_salary,
		birth_date,
		sending_datetime,
		city_to_work_in_id,
		desired_vacancy_id,
		avatar,
		file,
		file_name
	) VALUES (
		_full_name,
		_about,
		_work_experience,
		_desired_salary,
		_birth_date,
		_sending_datetime,
		_city_to_work_in_id,
		_desired_vacancy_id,
		_avatar,
		_file,
		_file_name
	);
	RETURN (SELECT 'success');
EXCEPTION
	WHEN OTHERS THEN
		DECLARE
			error_message VARCHAR(255);
		BEGIN
			GET STACKED DIAGNOSTICS error_message = PG_EXCEPTION_DETAIL;
			RETURN (SELECT error_message);
		END;
END $$;

DROP FUNCTION IF EXISTS edit_record;
CREATE FUNCTION edit_record(
	IN _id						INT,

	IN _is_full_name			BOOLEAN				DEFAULT false,
	IN _full_name 				VARCHAR(255)		DEFAULT null,

	IN _is_about				BOOLEAN				DEFAULT false,
	IN _about					TEXT				DEFAULT null,

	IN _is_work_experience		BOOLEAN				DEFAULT false,
	IN _work_experience			INT					DEFAULT null,

	IN _is_desired_salary		BOOLEAN				DEFAULT false,
	IN _desired_salary 			DOUBLE PRECISION	DEFAULT null,

	IN _is_birth_date			BOOLEAN				DEFAULT false,
	IN _birth_date 				DATE				DEFAULT null,

	IN _is_sending_datetime		BOOLEAN				DEFAULT false,
	IN _sending_datetime 		TIMESTAMP			DEFAULT null,

	IN _is_city_to_work_in_id	BOOLEAN				DEFAULT false,
	IN _city_to_work_in_id 		INT					DEFAULT null,

	IN _is_desired_vacancy_id	BOOLEAN				DEFAULT false,
	IN _desired_vacancy_id		INT					DEFAULT null,

	IN _is_avatar				BOOLEAN				DEFAULT false,
	IN _avatar 					BYTEA				DEFAULT null,

	IN _is_file					BOOLEAN				DEFAULT false,
	IN _file 					BYTEA				DEFAULT null,
	IN _file_name 				TEXT				DEFAULT null
)
RETURNS VARCHAR(255)
LANGUAGE 'plpgsql'
AS $$
DECLARE
	records_found	INT;
BEGIN
	records_found = (SELECT count(*) FROM resumes WHERE id = _id);
	IF records_found = 0 THEN
		RETURN (SELECT ('Запись с ID = ' || _id || ' не найдена!'));
	ELSE
		IF _is_full_name = true 			THEN 	UPDATE resumes SET full_name = _full_name 						WHERE id = _id; END IF;
		IF _is_about = true 				THEN 	UPDATE resumes SET about = _about 								WHERE id = _id; END IF;
		IF _is_work_experience = true 		THEN 	UPDATE resumes SET work_experience = _work_experience 			WHERE id = _id; END IF;
		IF _is_desired_salary = true 		THEN 	UPDATE resumes SET desired_salary = _desired_salary 			WHERE id = _id; END IF;
		IF _is_birth_date = true 			THEN 	UPDATE resumes SET birth_date = _birth_date 					WHERE id = _id; END IF;
		IF _is_sending_datetime = true 		THEN 	UPDATE resumes SET sending_datetime = _sending_datetime 		WHERE id = _id; END IF;
		IF _is_city_to_work_in_id = true 	THEN 	UPDATE resumes SET city_to_work_in_id = _city_to_work_in_id 	WHERE id = _id; END IF;
		IF _is_desired_vacancy_id = true 	THEN 	UPDATE resumes SET desired_vacancy_id = _desired_vacancy_id 	WHERE id = _id; END IF;
		IF _is_avatar = true 				THEN 	UPDATE resumes SET avatar = _avatar 							WHERE id = _id; END IF;
		IF _is_file = true	 				THEN 	UPDATE resumes SET file = _file, file_name = _file_name			WHERE id = _id; END IF;
		RETURN (SELECT 'success');
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		DECLARE
			error_message VARCHAR(255);
		BEGIN
			GET STACKED DIAGNOSTICS error_message = PG_EXCEPTION_DETAIL;
			RETURN (SELECT error_message);
		END;
END $$;

DROP FUNCTION IF EXISTS delete_record;
CREATE FUNCTION delete_record(
	IN _id					INT
)
RETURNS VARCHAR(255)
LANGUAGE 'plpgsql'
AS $$
DECLARE
	records_found	INT;
BEGIN
	records_found = (SELECT count(*) FROM resumes WHERE id = _id);
	IF records_found = 0 THEN
		RETURN (SELECT ('Запись с ID = ' || _id || ' не найдена!'));
	ELSE
		DELETE FROM resumes	WHERE id = _id;
		RETURN (SELECT 'success');
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		DECLARE
			error_message VARCHAR(255);
		BEGIN
			GET STACKED DIAGNOSTICS error_message = PG_EXCEPTION_DETAIL;
			RETURN (SELECT error_message);
		END;
END $$;