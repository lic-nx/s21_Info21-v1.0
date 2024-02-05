CREATE OR replace PROCEDURE ALL_Block_done(block_name text)
--  returns TABLE ("Peer" character varying, "PointsChange" numeric) 
 as $$
 BEGIN
 SELECT title AS "Peer"  FROM tasks WHERE title ILIKE '%block_name%';
 END;
 $$ LANGUAGE plpgsql;


CALL ALL_Block_done('memory');
-- SELECT * from ALL_Block_done;