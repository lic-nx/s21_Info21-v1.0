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

CREATE OR REPLACE PROCEDURE csv_import(
    p_table_name TEXT,
    p_filename TEXT,
    p_delimiter CHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format(
        'COPY %I FROM %L WITH CSV HEADER DELIMITER %L',
        p_table_name,
        p_filename,
        p_delimiter
    );
END; 
$$;

CREATE OR REPLACE PROCEDURE csv_export(
    p_table_name TEXT, 
    p_filename TEXT,
    p_delimiter CHAR DEFAULT ','
)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format(
        'COPY %I TO %L WITH CSV HEADER DELIMITER %L', 
        p_table_name,
        p_filename,
        p_delimiter
    );
END;  
$$;

INSERT INTO tasks VALUES ('None', null, 0);
CALL csv_import('peers', 'C:\SteamLibrary\peers.csv', ';');
CALL csv_import('friends', 'C:\SteamLibrary\friends.csv', ';');
CALL csv_import('recommendations', 'C:\SteamLibrary\recommendations.csv', ';');
CALL csv_import('timetracking', 'C:\SteamLibrary\time_tracking.csv', ';');
CALL csv_import('transferredpoints', 'C:\SteamLibrary\transferred_points.csv', ';');
CALL csv_import('tasks', 'C:\SteamLibrary\tasks.csv', ';');
CALL csv_import('checks', 'C:\SteamLibrary\checks.csv', ';');
CALL csv_import('xp', 'C:\SteamLibrary\XP.csv', ';');
CALL csv_import('p2p', 'C:\SteamLibrary\P2P.csv', ';');
CALL csv_import('verter', 'C:\SteamLibrary\verter.csv', ';');

CALL csv_export('peers', 'C:\SteamLibrary\peers1.csv', ';');
CALL csv_export('friends', 'C:\SteamLibrary\friends1.csv', ';');
CALL csv_export('recommendations', 'C:\SteamLibrary\recommendations1.csv', ';');
CALL csv_export('timetracking', 'C:\SteamLibrary\time_tracking1.csv', ';');
CALL csv_export('transferredpoints', 'C:\SteamLibrary\transferred_points1.csv', ';');
CALL csv_export('tasks', 'C:\SteamLibrary\tasks1.csv', ';');
CALL csv_export('checks', 'C:\SteamLibrary\checks1.csv', ';');
CALL csv_export('xp', 'C:\SteamLibrary\XP1.csv', ';');
CALL csv_export('p2p', 'C:\SteamLibrary\P2P1.csv', ';');
CALL csv_export('verter', 'C:\SteamLibrary\verter1.csv', ';');

