CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure'); -- тип данных enum / перечисление работает как в СИ
-- используется в таблицах P2P и Verter

CREATE TABLE IF NOT EXISTS TableName_Peers (
    Nickname varchar NOT NULL PRIMARY KEY,
    Birthday date NOT NULL
);

CREATE TABLE IF NOT EXISTS TransferredPoints (
    ID bigint PRIMARY KEY NOT NULL,
    CheckingPeer varchar NOT NULL,
    CheckedPeer varchar NOT NULL,
    PointsAmount bigint NOT NULL

);

CREATE TABLE IF NOT EXISTS TableName_Tasks (
    Title text NOT NULL PRIMARY KEY, -- тута
    ParentTask text,
    MaxXP BIGINT NOT NULL
   
);

CREATE TABLE IF NOT EXISTS TableName_Checks (
    ID BIGINT PRIMARY KEY NOT NULL,
    Peer varchar NOT NULL,
    Task text NOT NULL, -- тута
    Date date NOT NULL
  -- 1) поле Task связан с полем Title из таблицы Tasks
); -- таким образом поле Task может принимать только те значения, которые упоминались в поле Title

CREATE TABLE IF NOT EXISTS P2P (
    ID BIGINT PRIMARY KEY NOT NULL,
    "Check" bigint NOT NULL,
    CheckingPeer varchar NOT NULL,
    "State" check_status NOT NULL,
    "Time" time NOT NULL

);

CREATE TABLE IF NOT EXISTS Verter (
    ID bigint PRIMARY KEY NOT NULL,
    "Check" bigint NOT NULL,
    "State" check_status NOT NULL,
    "Time" time NOT NULL
    
);
	   
CREATE TABLE IF NOT EXISTS Friends (
    ID bigint PRIMARY KEY NOT NULL,
    Peer1 varchar NOT NULL,
    Peer2 varchar NOT NULL

);

CREATE TABLE IF NOT EXISTS Recommendations (
    ID bigint PRIMARY KEY NOT NULL,
    Peer varchar NOT NULL,
    RecommendedPeer varchar NOT NULL
   
);

CREATE TABLE IF NOT EXISTS XP (
    ID bigint PRIMARY KEY NOT NULL,
    "Check" bigint NOT NULL,
    XPAmount bigint NOT NULL
);

CREATE TABLE IF NOT EXISTS TimeTracking (
    ID bigint PRIMARY KEY NOT NULL,
    Peer varchar NOT NULL,
    "Date" date NOT NULL,
    "Time" time NOT NULL,
    "State" bigint NOT NULL CHECK ("State" IN (1, 2))
);

INSERT INTO TableName_Peers VALUES  
('john', '2000-01-01'),
('bob', '2001-01-01'),
('alice', '2002-01-01'), 
('mike', '2003-01-01'),
('kate', '2004-01-01');

INSERT INTO TableName_Tasks VALUES
('A5_s21_memory', null, 500), 
('A6_s21_memory', null, 400),
('A7_s21_memory', 'A5_s21_memory', 250),  
('A8_s21_memory', 'A6_s21_memory', 300),
('A9_s21_memory', null, 1000);

INSERT INTO TableName_Checks VALUES
(1, 'john', 'A5_s21_memory', '2020-03-01'),
(2, 'bob', 'A6_s21_memory', '2020-04-01'),
(3, 'alice', 'A7_s21_memory', '2020-05-01'),
(4, 'mike', 'A8_s21_memory', '2020-06-01'), 
(5, 'kate', 'A9_s21_memory', '2020-07-01');

INSERT INTO P2P VALUES  
(1, 1, 'bob', 'Success', '12:00'), 
(2, 2, 'alice', 'Failure', '13:00'),
(3, 3, 'mike', 'Start', '14:00'),
(4, 4, 'kate', 'Success', '15:00'),
(5, 5, 'john', 'Start', '16:00'); 

INSERT INTO Verter VALUES
(1, 1, 'Success', '12:05'),
(2, 2, 'Success', '13:05'), 
(3, 3, 'Failure', '14:05'),
(4, 4, 'Success', '15:05'),
(5, 5, 'Start', '16:05');

INSERT INTO Friends VALUES  
(1, 'john', 'bob'),
(2, 'alice', 'mike'), 
(3, 'bob', 'kate'),
(4, 'mike', 'john'),  
(5, 'kate', 'alice');

INSERT INTO Recommendations VALUES
(1, 'john', 'alice'),  
(2, 'bob', 'mike'),
(3, 'alice', 'kate'),
(4, 'mike', 'john'), 
(5, 'kate', 'bob');

INSERT INTO XP VALUES  
(1, 1, 250),
(2, 2, 100),  
(3, 3, 125),
(4, 4, 300),  
(5, 5, 500);

INSERT INTO TimeTracking VALUES
(1, 'john', '2022-01-01', '12:00', 1),  
(2, 'bob', '2022-02-01', '13:00', 1),
(3, 'alice', '2022-03-01', '14:00', 2), 
(4, 'mike', '2022-04-01', '15:00', 1),
(5, 'kate', '2022-05-01', '16:00', 2);




-------------------------------------------
-- 1) Создать хранимую процедуру, которая, не уничтожая базу данных, уничтожает 
-- все те таблицы текущей базы данных, имена которых начинаются с фразы 'TableName'.

CREATE OR REPLACE PROCEDURE drop_tables_with_prefix()
AS $$
DECLARE
    table_ TEXT;
BEGIN
    FOR table_ IN   
    SELECT table_name
        FROM information_schema.tables
        WHERE table_name LIKE 'tablename%' or table_name LIKE 'TableName%'
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || table_ || ' CASCADE;';
    END LOOP    ;
END;
$$
LANGUAGE plpgsql;
  CALL drop_tables_with_prefix();

---------------------------------------------
-- 2)  Хранимая процедура с выходным параметром, которая выводит список имен и 
-- параметров всех скалярных SQL функций пользователя в текущей базе данных. 
-- Имена функций без параметров не выводить. Имена и список параметров должны 
-- выводиться в одну строку. Выходной параметр возвращает количество найденных функций.

CREATE OR REPLACE PROCEDURE list_of_functions(list_of_functions_and_params OUT TEXT, quantity OUT INTEGER)
as $$
BEGIN
    WITH table_funct_pasram as (
        SELECT format('%I.%I(%s)', ns.nspname, p.proname, oidvectortypes(p.proargtypes)) as result
        FROM pg_proc p INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
        where (ns.nspname = 'public' or ns.nspname = 'privat') and p.proargtypes <> ''
 )
    select result into list_of_functions_and_params from table_funct_pasram;
    WITH table_funct_pasram as (
        SELECT format('%I.%I(%s)', ns.nspname, p.proname, oidvectortypes(p.proargtypes)) as result
        FROM pg_proc p INNER JOIN pg_namespace ns ON (p.pronamespace = ns.oid)
        where (ns.nspname = 'public' or ns.nspname = 'privat') and p.proargtypes <> ''
 )
 SELECT count(*) into quantity from table_funct_pasram;
    RETURN;
END;
$$ LANGUAGE plpgsql;

CALL  list_of_functions(' ',0);


-- думаю что все же надо поправить то как это все присваивается может дременные таблицы или еще что использовать

--3) Создать хранимую процедуру с выходным параметром, 
-- которая уничтожает все SQL DML триггеры в текущей базе 
-- данных. Выходной параметр возвращает количество уничтоженных триггеров.

CREATE OR REPLACE PROCEDURE proc_delete_triggers( count_triggers OUT int)
AS $$
DECLARE
    tgname name;
	table_name name;
BEGIN

    SELECT count(tgname) into count_triggers
    FROM pg_trigger
    WHERE tgenabled = 'O' AND tgconstraint = 0;


    FOR tgname, table_name IN (SELECT tgname, tgrelid::regclass AS table_name
        FROM pg_trigger
        JOIN pg_class ON pg_trigger.tgrelid = pg_class.oid
        WHERE tgenabled = 'O' AND tgconstraint = 0)
    LOOP
            
            EXECUTE 'DROP TRIGGER ' ||tgname  || ' ON ' || table_name ;
        END LOOP;


RETURN;
END;
$$ LANGUAGE plpgsql;

-- опять же надо почекать 

-- 4)Создать хранимую процедуру с входным параметром, 
-- которая выводит имена и описания типа объектов 
-- (только хранимых процедур и скалярных функций), 
-- в тексте которых на языке SQL встречается строка, 
-- задаваемая параметром процедуры.

CREATE OR REPLACE PROCEDURE proc_search_proc_string(n VARCHAR, r REFCURSOR DEFAULT 'ref') 
AS $$

BEGIN
    OPEN r FOR
		SELECT proname AS Name, proargnames, CASE prokind
								WHEN 'p' THEN 'procedure' 
								WHEN 'f' THEN 'function'
								ELSE NULL
								END AS type
		 FROM pg_proc pr
		 
         JOIN pg_namespace ns ON ns.oid = pr.pronamespace
		WHERE  nspname != 'pg_catalog' 
		      AND nspname != 'information_schema'
              AND proname ILIKE '%' || n || '%';
END;
$$ LANGUAGE plpgsql;


CALL proc_search_proc_string('delete');
FETCH ALL FROM "ref";
