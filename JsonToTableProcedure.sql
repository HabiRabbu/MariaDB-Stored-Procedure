USE Test;

DELIMITER //

-- Drop the procedure if it exists (Due to working on this in console)
DROP PROCEDURE IF EXISTS json_to_table;

CREATE PROCEDURE json_to_table(json_input JSON)
BEGIN
   DECLARE key_val_pairs JSON;

    IF NOT JSON_VALID(json_input) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid JSON object', MYSQL_ERRNO = 333;
    END IF;

    CREATE TEMPORARY TABLE IF NOT EXISTS cte_idx (idx INT);

    INSERT INTO cte_idx (idx) VALUES (0);

    INSERT INTO cte_idx (idx)
    SELECT idx + 1
    FROM cte_idx
    WHERE idx < JSON_LENGTH(JSON_KEYS(json_input, '$')) - 1;
    -- Create a Common Table Expression (CTE)
    WITH recursive cte AS (
        SELECT
            JSON_UNQUOTE(JSON_EXTRACT(JSON_KEYS(json_input, '$'), CONCAT('$[', idx, ']'))) AS `key`,
            JSON_UNQUOTE(JSON_EXTRACT(json_input, CONCAT('$.', JSON_UNQUOTE(JSON_EXTRACT(JSON_KEYS(json_input, '$'), CONCAT('$[', idx, ']')))))) AS `value`
        FROM
            cte_idx
    WHERE idx < JSON_LENGTH(JSON_KEYS(json_input, '$'))
    )
    SELECT * FROM cte;

    -- Drop the temporary table
    DROP TEMPORARY TABLE IF EXISTS cte_idx;

END //

DELIMITER ;
