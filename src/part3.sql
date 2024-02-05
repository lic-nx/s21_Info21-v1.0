-- task
-- 1) Написать функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде
-- Ник пира 1, ник пира 2, количество переданных пир поинтов.
-- Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.
CREATE OR replace FUNCTION TransferredPointsReturns()
 returns TABLE ("Peer1" character varying, "Peer2" character varying, "PointsAmount" bigint)
 as $$
 BEGIN
    RETURN QUERY
(    SELECT t0.checkingpeer, t0.checkedpeer, (t0.pointsamount - coalesce(t1.PointsAmount, 0)) as "PoinstAmount" from transferredpoints t0
    left JOIN transferredpoints t1 on  t1.checkingpeer = t0.checkedpeer and t1.checkedpeer = t0.checkingpeer and t1.id > t0.id
);
 END;
 $$ LANGUAGE plpgsql;


select * from TransferredPointsReturns();


-- 2) Написать функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP
-- В таблицу включать только задания, успешно прошедшие проверку (определять по таблице Checks). 
-- Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.


CREATE OR replace FUNCTION ReturnXpUsers()
returns table ("Peer" character varying, "Task" text, "XP" bigint)
as $$
BEGIN
    RETURN QUERY
    SELECT ch.peer, ch.task, xp.xpamount from checks ch
    join xp on xp."Check" = ch.id;
END;
$$ LANGUAGE plpgsql;

SELECT * from ReturnXpUsers();
-- 3) Написать функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня
-- Параметры функции: день, например 12.05.2022. 
-- Функция возвращает только список пиров.

CREATE OR replace FUNCTION peersWhatNotGoOut(IN day_date date)
returns SETOF varchar
as $$
BEGIN
 RETURN QUERY
    SELECT peer
                      FROM timetracking
                      WHERE timetracking."Date" = day_date
                      GROUP BY peer, "Date"
                      HAVING COUNT("State") < 3;
END;
$$ LANGUAGE plpgsql;

SELECT * from peersWhatNotGoOut('2022-01-01');


-- 4) Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints
-- Результат вывести отсортированным по изменению числа поинтов. 
-- Формат вывода: ник пира, изменение в количество пир поинтов

CREATE OR replace FUNCTION ReturnChangePRP()
 returns TABLE ("Peer1" character varying, "PointsChange" numeric) 
 as $$
 BEGIN
    RETURN QUERY
     WITH table1 AS (SELECT checkingpeer, ABS(SUM(pointsamount)) AS sum_points
                FROM transferredpoints
                GROUP BY checkingpeer),
                 table2 AS (
                SELECT checkedpeer, ABS(SUM(pointsamount)) AS sum_points
                FROM transferredpoints
                GROUP BY checkedpeer)
            SELECT coalesce(checkingpeer, checkedpeer) AS "Peer1", ((COALESCE(table1.sum_points, 0)) -
                              (COALESCE(table2.sum_points, 0))) AS "PointsChange"
            FROM table1
                full JOIN table2 ON table1.checkingpeer = table2.checkedpeer
            ORDER BY "PointsChange" DESC;
 END;
 $$ LANGUAGE plpgsql;


SELECT * from ReturnChangePRP();

-- 5) Посчитать изменение в количестве пир поинтов каждого пира по таблице, возвращаемой первой функцией из Part 3

-- Результат вывести отсортированным по изменению числа поинтов. 
-- Формат вывода: ник пира, изменение в количество пир поинтов

CREATE OR replace FUNCTION ReturnChangePRP2()
returns TABLE ("Peer" character varying, "PointsChange" numeric) 
as $$
BEGIN  
RETURN QUERY
    WITH p1 AS (SELECT "Peer1" as peer, SUM("PointsAmount") AS "PointsChange"
    FROM TransferredPointsReturns()
    GROUP by peer
    ), 
    p2 AS (SELECT "Peer2" as peer, SUM ("PointsAmount") AS "PointsChange"
    FROM TransferredPointsReturns()
    GROUP by peer)
    SELECT COALESCE(p1.peer, p2.peer) AS "Peer", COALESCE(p1."PointsChange", 0) - COALESCE(p2."PointsChange", 0) as "PointsChange"
    FROM p1
    FULL JOIN p2 ON p2.peer = p1.peer
    ORDER by "PointsChange" DESC

;
 END;
 $$ LANGUAGE plpgsql;


SELECT * from ReturnChangePRP2();


--6) Определить самое часто проверяемое задание за каждый день
-- При одинаковом количестве проверок каких-то заданий в определенный день, вывести их все. 
-- Формат вывода: день, название задания


CREATE OR replace FUNCTION maxTask()
 returns TABLE ("date" date, "task" text) 
 as $$
 BEGIN
 RETURN QUERY
 WITH t1 AS (SELECT checks.task, checks.date, count(checks.task) amount FROM checks GROUP BY checks.task, checks.date),
        max_count AS (SELECT cc.task, cc.date, cc.amount FROM t1 cc
        WHERE amount = (SELECT max(amount) FROM t1 WHERE t1.date = cc.date))

        SELECT max_count.date, max_count.task FROM  max_count ORDER BY date;

 END;
 $$ LANGUAGE plpgsql;


SELECT * from maxTask();



-- 7)Найти всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания
-- Параметры процедуры: название блока, например "CPP". 
-- Результат вывести отсортированным по дате завершения. 
-- Формат вывода: ник пира, дата завершения блока (т.е. последнего выполненного задания из этого блока)


CREATE OR replace FUNCTION ALL_Block_done(block_name text)
returns TABLE ("peer" character varying, "date" Date) 
 as $$
 BEGIN
 RETURN QUERY
 SELECT checks."peer", checks."date" from checks where 
 (select count(tabl.title) from (SELECT title FROM tasks WHERE title ~ block_name) as tabl) = (SELECT count(*) from (select id from verter where checks.task ~ block_name and checks.id = verter."Check" 
            and verter."State" = 'Success')as t3)
  ;
 END;
 $$ LANGUAGE plpgsql;


SELECT * from ALL_Block_done('A5');



-- 8) Определить, к какому пиру стоит идти на проверку каждому обучающемуся
-- Определять нужно исходя из рекомендаций друзей пира, т.е. нужно найти пира, проверяться у которого рекомендует наибольшее число друзей. 
-- Формат вывода: ник пира, ник найденного проверяющего

create or replace function recommended_peers()
returns table ("peer" varchar, "recommendedPeer" varchar) as
$$
begin
    return query
    with recommendationcount as (
        select
            peer1, recommendations.recommendedpeer,
            count(*) as recommendationcount,
            row_number() over (partition by peer1 order by count(*) desc) as row
        from friends
        join recommendations on friends.peer2 = recommendations.peer
        group by peer1, recommendations.recommendedpeer
    )
    select peer1, recommendedpeer from recommendationcount where row = 1;
end;
$$ language plpgsql;
    

SELECT * from recommended_peers();

-- 9)Определить процент пиров, которые:

-- Приступили только к блоку 1
-- Приступили только к блоку 2
-- Приступили к обоим
-- Не приступили ни к одному

-- Пир считается приступившим к блоку, если 
-- он проходил хоть одну проверку любого задания из этого блока (по таблице Checks)
-- Параметры процедуры: название блока 1, например SQL, название блока 2, например A. 
-- Формат вывода: процент приступивших только к
--  первому блоку, процент приступивших только ко второму блоку, процент приступивших к обоим,
--  процент не приступивших ни к одному
CREATE OR REPLACE FUNCTION procent_of_Peers(block1 text, block2 text)
returns table("StartedBlock1" float, "StartedBlock2" float, "StartedBothBlocks" float, "DidntStartAnyBlock0" float) as $$
BEGIN
    return query
        WITH peers_count AS (SELECT COUNT(DISTINCT nickname) AS point FROM peers), 
        peers_in_first_task AS (SELECT COUNT(DISTINCT peer) AS first_task FROM checks WHERE task ~ block1 GROUP BY task),
        peers_in_second_task AS (SELECT COUNT(DISTINCT peer) AS second_task FROM checks WHERE task ~ block2 GROUP BY task),
        peers_in_two_task AS (SELECT COUNT(DISTINCT peer) as start_task from checks WHERE
        peer in (SELECT DISTINCT peer FROM checks WHERE task ~ block1 )
        AND
        peer in (SELECT DISTINCT peer AS second_task FROM checks WHERE task ~ block2 )),
        peers_Dont_start AS (SELECT COUNT(DISTINCT peer) as start_task from checks WHERE
        peer not in (SELECT DISTINCT peer FROM checks WHERE task ~ block1 )
        AND
        peer not in (SELECT DISTINCT peer AS second_task FROM checks WHERE task ~ block2 ))

        SELECT 100*(peers_in_first_task.first_task::float / peers_count.point) AS StartedBlock1, 
        100 * (peers_in_second_task.second_task::float / peers_count.point) AS StartedBlock2, 
        100 * (peers_in_two_task.start_task::float / peers_count.point) AS StartedBothBlocks, 
        100 * (peers_Dont_start.start_task::float / peers_count.point) AS DidntStartAnyBlock0
        from peers_count, peers_in_first_task, peers_in_second_task, peers_in_two_task, peers_Dont_start
        ;
END;
$$ language  plpgsql;

SELECT * from procent_of_Peers('A5', 'A6');

-- 10) Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения
-- Также определите процент пиров, которые хоть раз проваливали проверку в свой день рождения. 
-- Формат вывода: процент пиров, успешно прошедших проверку в день рождения, процент пиров, проваливших проверку в день рождения
CREATE OR REPLACE FUNCTION success_at_day( )
returns table("SuccessfulChecks" bigint, "UnsuccessfulChecks" bigint) as $$
BEGIN
    return query
    WITH c_p as (
        SELECT COUNT(*) as count_peers from peers
    ), 
    passed_at_day as (
        SELECT count(ch.id) as tmp from checks ch
        join peers pe on ch.peer = pe.nickname
        where 
        EXTRACT(MONTH FROM pe.birthday) = EXTRACT(MONTH FROM ch."date") 
        AND EXTRACT(DAY FROM pe.birthday) = EXTRACT(DAY FROM ch."date")
        and ch.id not in (SELECT "Check" from p2p where "State" = 'Success')),
    done_passed_at_day as (
        SELECT count(ch.id) as tmp from checks ch
        join peers pe on ch.peer = pe.nickname
        where 
        EXTRACT(MONTH FROM pe.birthday) = EXTRACT(MONTH FROM ch."date") 
        AND EXTRACT(DAY FROM pe.birthday) = EXTRACT(DAY FROM ch."date")
        and ch.id in (SELECT "Check" from p2p where "State" = 'Success')
 )
 SELECT (100*(done_passed_at_day.tmp)/(c_p.count_peers)) as "SuccessfulChecks",  
 (100*(passed_at_day.tmp)/(c_p.count_peers)) as "UnsuccessfulChecks"
 from c_p, done_passed_at_day, passed_at_day
;
    
    -- pe.birthday = ch."date"
END;
$$ language  plpgsql;

SELECT * from success_at_day( );

-- 11) Определить всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3
-- Параметры процедуры: названия заданий 1, 2 и 3. 
-- Формат вывода: список пиров


CREATE OR REPLACE FUNCTION success_task(task1 text, task2 text, task3 text)
RETURNS TABLE ("peers" character varying) AS $$
BEGIN
    RETURN QUERY
    WITH peer_in_task1 AS (
        SELECT peer FROM checks WHERE task ~ task1
    ),
    peer_in_task2 AS (
        SELECT peer FROM checks WHERE task ~ task2
    ),
    peer_in_task3 AS (
        SELECT peer FROM checks WHERE task ~ task3
    )
    SELECT distinct peer AS "peers" FROM checks WHERE peer IN (SELECT peer FROM peer_in_task1) AND peer IN (SELECT peer FROM peer_in_task2) AND peer NOT IN (SELECT peer FROM peer_in_task3);
END;
$$
LANGUAGE plpgsql;

SELECT * FROM success_task('A8_s21_memory', 'A9_s21_memory', 'A5_s21_memory');

-- 12) Используя рекурсивное обобщенное табличное выражение, для каждой задачи вывести кол-во предшествующих ей задач
-- То есть сколько задач нужно выполнить, исходя из условий входа, чтобы получить доступ к текущей. 
-- Формат вывода: название задачи, количество предшествующих

CREATE OR REPLACE FUNCTION number_of_tasks_preceding()
RETURNS TABLE (title text, counter integer ) as $$
BEGIN 
    RETURN QUERY
WITH RECURSIVE r AS (
    -- стартовая часть рекурсии (т.н. "anchor")
    SELECT 
        tasks.title, 
        0 as counter 
        from tasks 
        where parenttask is null
    UNION all
    
    -- рекурсивная часть  
        SELECT ts.title, r.counter + 1 from  tasks ts
        join r on ts.parenttask = r.title
)
SELECT r.title, r.counter FROM r order by title;

END;
$$
LANGUAGE plpgsql;

SELECT * from number_of_tasks_preceding();


-- 13) Найти "удачные" для проверок дни. 
-- День считается "удачным", если в нем есть хотя бы N идущих 
-- подряд успешных проверки
-- Параметры процедуры: количество идущих подряд успешных проверок N. 
-- Временем проверки считать время начала P2P этапа. 
-- Под идущими подряд успешными проверками подразумеваются 
-- успешные проверки, между которыми нет неуспешных. 
-- При этом кол-во опыта за каждую из этих проверок должно 
-- быть не меньше 80% от максимального. 
-- Формат вывода: список дней

CREATE OR REPLACE FUNCTION lucky_days(N int)
RETURNS TABLE ("Day" date) AS $$
BEGIN
	RETURN QUERY
		WITH  all_checks AS (
			SELECT c.id, c.date, p2p."Time", p2p."State", xp.xpamount
			FROM checks c, p2p, xp
			WHERE c.id = p2p."Check" AND (p2p."State" = 'Success' OR p2p."State" = 'Failure')
				AND c.id = xp."Check" AND xpamount >= (SELECT tasks.maxxp
														 FROM tasks
														 WHERE tasks.title = c.task) * 0.8
			ORDER BY c.date, p2p."Time"),
		 
			status_in_row as (SELECT id, date, "Time", "State",
			(CASE WHEN "State" = 'Success' THEN row_number() over (partition by "State", date) ELSE 0 END) AS amount
												 FROM all_checks ORDER BY date
		 ),
            max_done as (SELECT s.date, MAX(amount) amount FROM status_in_row s GROUP BY date)

         SELECT date AS "Day" FROM max_done WHERE amount >= N;
END;
$$ LANGUAGE plpgsql;



------------------------------------------------------
-- 14) Определить пира с наибольшим количеством XP
-- Формат вывода: ник пира, количество XP

CREATE OR REPLACE FUNCTION with_most_XP()
RETURNS TABLE ("Peer" character varying, "XP" numeric ) as $$
BEGIN 
 RETURN QUERY
 select peer as "Peer", sum(xpamount) as "XP" from xp
    join checks on xp."Check" = checks.id
    group by "Peer"
    order by "XP" desc limit 1;


END;
$$
LANGUAGE plpgsql;

SELECT * FROM with_most_XP();

-- 15) Определить пиров, приходивших раньше заданного времени не менее N раз за всё время
-- Параметры процедуры: время, количество раз N. 
-- Формат вывода: список пиров



CREATE OR REPLACE FUNCTION who_came_before(given_time time, N integer)
RETURNS TABLE ("Peer" character varying ) as $$
BEGIN 
 RETURN QUERY
 
    SELECT peer from timetracking
    where "Time" < given_time and "State" = 1
    group by peer
        having count(*) >= N;
 
END;
$$
LANGUAGE plpgsql;

SELECT * FROM who_came_before('13:00:00', 1);

-- 16) Определить пиров, выходивших за последние N дней из кампуса больше M раз
-- Параметры процедуры: количество дней N, количество раз M. 
-- Формат вывода: список пиров



CREATE OR REPLACE FUNCTION who_out_more(N integer, M integer)
RETURNS TABLE ("Peer" character varying ) as $$
BEGIN 
 RETURN QUERY
 
    select peer as "Peer" from timetracking
        where "Date" >= current_date - (N || ' days')::interval and "State" = 2
        group by peer
        having count(*) > M;
 
END;
$$
LANGUAGE plpgsql;

SELECT * FROM who_out_more(1365, 0);


-- 17) Определить для каждого месяца процент ранних входов
-- Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус за всё время (будем называть это общим числом входов). 
-- Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, приходили в кампус раньше 12:00 за всё время (будем называть это числом ранних входов). 
-- Для каждого месяца посчитать процент ранних входов в кампус относительно общего числа входов. 
-- Формат вывода: месяц, процент ранних входов


CREATE OR REPLACE FUNCTION percentage_of_early_shoots()
RETURNS TABLE ("Month" text, "EarlyEntries" bigint) as $$
BEGIN 
 RETURN QUERY
     select to_char(month, 'month'),
        100 * sum(case when extract(hour from "Time") < 12 then 1 else 0 end) / count(*)
    from (select date_trunc('month', "Date") as month, "Time" from timetracking where "State" = 1) as subquery
    group by to_char(month, 'month');
  
 
END;
$$
LANGUAGE plpgsql;

SELECT * FROM percentage_of_early_shoots();