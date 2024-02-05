-- В ЭКСПОРТ И В ИМПОРТ ПРОЦЕДУРАХ ВЫХОДИТ ОШИБКА "permission denied" - "нет доступа/разрешения".
-- Нужно указать абсолютный путь, то есть /Users/a1/Desktop/checks.csv или типо того. 
-- Есть подозрения, что они просто не видят файл, НО путь указываю правильно:((

-- Шаблон: FOREIGN KEY поле_текущей_таблицы REFERENCES название_другой_таблицы(поле_из_той_самой_другой_таблицы)
-- Дает возможность связать поле из одной таблицы с полем другой таблицы, чтобы между ними не было противоречивых данных
-- Пример в связи между таблицами Tasks и Checks

CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure'); -- тип данных enum / перечисление работает как в СИ
-- используется в таблицах P2P и Verter

CREATE TABLE IF NOT EXISTS Peers (
    Nickname varchar NOT NULL PRIMARY KEY,
    Birthday date NOT NULL
);

CREATE TABLE IF NOT EXISTS TransferredPoints (
    ID bigint PRIMARY KEY NOT NULL,
    CheckingPeer varchar NOT NULL,
    CheckedPeer varchar NOT NULL,
    PointsAmount bigint NOT NULL,
    FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
    FOREIGN KEY (CheckedPeer) REFERENCES Peers(Nickname)
);

CREATE TABLE IF NOT EXISTS Tasks (
    Title text NOT NULL PRIMARY KEY, -- тута
    ParentTask text,
    MaxXP BIGINT NOT NULL,
    FOREIGN KEY (ParentTask) REFERENCES Tasks (Title)
);

CREATE TABLE IF NOT EXISTS Checks (
    ID BIGINT PRIMARY KEY NOT NULL,
    Peer varchar NOT NULL,
    Task text NOT NULL, -- тута
    Date date NOT NULL,
    FOREIGN KEY (Peer) REFERENCES Peers (Nickname),
    FOREIGN KEY (Task) REFERENCES Tasks (Title) -- 1) поле Task связан с полем Title из таблицы Tasks
); -- таким образом поле Task может принимать только те значения, которые упоминались в поле Title

CREATE TABLE IF NOT EXISTS P2P (
    ID BIGINT PRIMARY KEY NOT NULL,
    "Check" bigint NOT NULL,
    CheckingPeer varchar NOT NULL,
    "State" check_status NOT NULL,
    "Time" time NOT NULL,
    FOREIGN KEY ("Check") REFERENCES Checks (ID),
    FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname)
);

CREATE TABLE IF NOT EXISTS Verter (
    ID bigint PRIMARY KEY NOT NULL,
    "Check" bigint NOT NULL,
    "State" check_status NOT NULL,
    "Time" time NOT NULL,
    FOREIGN KEY ("Check") REFERENCES Checks(ID)
);
	   
CREATE TABLE IF NOT EXISTS Friends (
    ID bigint PRIMARY KEY NOT NULL,
    Peer1 varchar NOT NULL,
    Peer2 varchar NOT NULL,
    FOREIGN KEY (Peer1) REFERENCES Peers(Nickname),
    FOREIGN KEY (Peer2) REFERENCES Peers(Nickname)
);

CREATE TABLE IF NOT EXISTS Recommendations (
    ID bigint PRIMARY KEY NOT NULL,
    Peer varchar NOT NULL,
    RecommendedPeer varchar NOT NULL,
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
    FOREIGN KEY (RecommendedPeer) REFERENCES Peers(Nickname)
);

CREATE TABLE IF NOT EXISTS XP (
    ID bigint PRIMARY KEY NOT NULL,
    "Check" bigint NOT NULL,
    XPAmount bigint NOT NULL,
    FOREIGN KEY ("Check") REFERENCES Checks(ID)
);

CREATE TABLE IF NOT EXISTS TimeTracking (
    ID bigint PRIMARY KEY NOT NULL,
    Peer varchar NOT NULL,
    "Date" date NOT NULL,
    "Time" time NOT NULL,
    "State" bigint NOT NULL CHECK ("State" IN (1, 2)),
    FOREIGN KEY (Peer) REFERENCES Peers(Nickname)
);

INSERT INTO Peers VALUES  
('john', '2000-01-01'),
('bob', '2001-01-01'),
('alice', '2002-01-01'), 
('mike', '2003-01-01'),
('kate', '2004-01-01');

INSERT INTO Tasks VALUES
('A5_s21_memory', null, 500), 
('A6_s21_memory', null, 400),
('A7_s21_memory', 'A5_s21_memory', 250),  
('A8_s21_memory', 'A6_s21_memory', 300),
('A9_s21_memory', null, 1000);

INSERT INTO Checks VALUES
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

-- CREATE OR REPLACE PROCEDURE import_csv(p_table text, p_csv_file text) 
-- LANGUAGE plpgsql AS $$
-- BEGIN
--   EXECUTE format('
--     COPY %I FROM %L
--     WITH CSV HEADER
--     ', p_table, p_csv_file);
-- END;
-- $$;

-- CALL import_csv('checks', '/Users/a1/Desktop/checks.csv');

-- CREATE OR REPLACE PROCEDURE export_csv(p_table text, p_csv_file text)
-- LANGUAGE plpgsql AS $$
-- BEGIN
--   EXECUTE format('
--     COPY %I TO %L
--     WITH CSV HEADER
--     ', p_table, p_csv_file);
-- END;
-- $$;

-- CALL export_csv('mytable', '/Users/a1/Desktop/data.csv');

-- drop table universal_mailing
