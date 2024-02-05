--1) Процедура добавления P2P проверки

CREATE OR REPLACE PROCEDURE add_p2p_check(
    p2p_nickname VARCHAR,
    p2p_checker_nickname VARCHAR,
    check_task_name VARCHAR,
    p2p_check_status check_status,
    p2p_time time)
    LANGUAGE plpgsql AS $$
    BEGIN IF
    p2p_check_status = 'Start' THEN INSERT INTO checks(id, peer, task, "date")
        VALUES((SELECT max(id) + 1 from checks), p2p_nickname, check_task_name,
               CURRENT_DATE);
--считаем что id генерируется самостоятельно

    INSERT INTO p2p(id, "Check", checkingPeer, "State", "Time")
        VALUES((SELECT max(id) + 1 from p2p), (SELECT max(id) from checks),
               p2p_checker_nickname, p2p_check_status, p2p_time);

ELSE INSERT INTO p2p(id, "Check", checkingPeer, "State", "Time")
    VALUES((SELECT max(id) + 1 from p2p),
           (SELECT
            "Check" FROM p2p WHERE checkingPeer = p2p_checker_nickname AND
            "State" = 'Start' AND
            "Check" NOT IN(SELECT "Check" FROM p2p WHERE "State" <> 'Start')
                ORDER BY "Time" DESC LIMIT 1),
           p2p_checker_nickname, p2p_check_status, p2p_time);
END IF;
END;
$$;

CALL add_p2p_check('yculbhvhbj', 'iodskxuoka', 'C1', 'Start', '10:00');
CALL add_p2p_check('iodskxuoka', 'sdgkxkjwmk', 'C2', 'Start', '11:00');
CALL add_p2p_check('iodskxuoka', 'uyaqyslbhk', 'C5', 'Start', '12:00');
CALL add_p2p_check('llxfrdpypf', 'hsygfqpicc', 'C6', 'Start', '13:00');
CALL add_p2p_check('gflglwhwjn', 'hzwxhpqfbb', 'C7', 'Start', '14:00');

-- 2) процедура проверки вектором

  CREATE OR REPLACE PROCEDURE add_verter_check(checks_nickname VARCHAR,
                          checks_task_name VARCHAR,
                          verter_check_status check_status,
                          verter_time
                             time)
                            LANGUAGE plpgsql AS $$
                            BEGIN
    IF(select count("State") from p2p where "State" = 'Success') >
    0 THEN INSERT INTO verter(id, "Check", "State", "Time")
    VALUES((SELECT MAX(id) + 1 from verter),
           (select id from checks where peer =
                checks_nickname and
                task = checks_task_name and
                       id in(select "Check" from p2p where "State" = 'Success')
                           ORDER BY "date" DESC LIMIT 1),
        verter_check_status,
           verter_time);
END IF;
END;
$$;

CALL add_verter_check('alice', 'A8_s21_memory', 'Failure', '10:00');
CALL add_verter_check('alice', 'A8_s21_memory', 'Success', '10:00');
CALL add_verter_check('mike', 'A8_s21_memory', 'Success', '11:00');

--3)тригеры после добавления записи со статутом "начало" в таблицу P2P,
    -- изменить соответствующую запись в таблице TransferredPoints


 CREATE OR REPLACE FUNCTION
        update_transferredPoints()
RETURNS trigger AS $$
BEGIN
    if NEW."State" ='Start' THEN
        if (SELECT count(CheckingPeer) from TransferredPoints where CheckingPeer = NEW.CheckingPeer and CheckedPeer = (SELECT Peer FROM Checks WHERE id = NEW."Check")) <1
        THEN
            INSERT INTO TransferredPoints
            VALUES(COALESCE((select max(id)+1 from transferredpoints),1), NEW.CheckingPeer, (SELECT Peer FROM Checks WHERE id = NEW."Check"), 1);
        ELSE UPDATE TransferredPoints SET PointsAmount =
            PointsAmount + 1 WHERE CheckingPeer =
            NEW.CheckingPeer and CheckedPeer =
            (SELECT Peer FROM Checks WHERE id = NEW."Check");
        END IF;
    END IF;
RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER p2p_trigger
AFTER INSERT ON P2P
FOR EACH ROW
EXECUTE FUNCTION update_transferredPoints();

CALL add_p2p_check('mvazvelhwy', 'iosfiypdje', 'C1', 'Start', '10:00');
CALL add_p2p_check('mvazvelhwy', 'wbbmjueeye', 'C2', 'Start', '11:00');
CALL add_p2p_check('wsiwgwornx', 'iosfiypdje', 'C5', 'Start', '12:00');
CALL add_p2p_check('wsiwgwornx', 'prbedzugjq', 'C6', 'Start', '13:00');
CALL add_p2p_check('wsiwgwornx', 'xshctjmsxa', 'C7', 'Start', '14:00');

-- 4)
CREATE OR REPLACE TRIGGER update_transferredPoints_trigger AFTER INSERT ON p2p
    FOR EACH ROW EXECUTE FUNCTION
    update_transferredPoints();

INSERT INTO p2p VALUES((SELECT max(id)+1 from p2p), 5, 'john', 'Start', '10:00');

--надо будет добавить тесты

    -- перед добавлением записи в таблицу XP,
    --проверить корректность добавляемой записи-- Запись считается корректной,
    --если : Количество XP не превышает максимальное доступное для
                --  проверяемой
                -- задачи Поле Check ссылается на
                    --  успешную проверку-- Если запись не прошла проверку,
    --не добавлять её в таблицу


CREATE OR REPLACE FUNCTION check_new_row() 
RETURNS trigger AS $$
        BEGIN IF
        EXISTS(SELECT id from verter WHERE "Check" = NEW."Check" AND "State" = 'Success') 
        THEN 
            IF NEW.xpamount > (SELECT maxxp from tasks where title =
               (SELECT task FROM checks where id = NEW."Check" limit 1))
            THEN RAISE EXCEPTION '% the value is higher than acceptable',
                NEW.xpamount;
            END IF;
            IF NEW.xpamount < 0 
            THEN RAISE EXCEPTION '% the value is less than acceptable', NEW.xpamount;
            END IF;
        ELSE RAISE EXCEPTION 'there is no successfully completed verification';
    END IF;
RETURN NEW;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE TRIGGER check_new_row_trigger BEFORE INSERT ON xp FOR EACH ROW
    EXECUTE FUNCTION
    check_new_row();

INSERT INTO xp VALUES((SELECT MAX(id) FROM XP)+1, 1, 50);
INSERT INTO xp VALUES((SELECT MAX(id) FROM XP)+1, 2, 50);
INSERT INTO xp VALUES((SELECT MAX(id) FROM XP)+1, 3, 50);
INSERT INTO xp VALUES((SELECT MAX(id) FROM XP)+1, 6, 0);
INSERT INTO xp VALUES((SELECT MAX(id) FROM XP)+1, 8, 50);

-- drop PROCEDURE add_verter_check;
--drop PROCEDURE public.add_p2p_check;
--DROP TABLE verter, xp, transferredpoints, timetracking, tasks,
-- recommendations, peers, p2p, friends, checks;
--drop TYPE check_status;
--drop FUNCTION update_transferredPoints()