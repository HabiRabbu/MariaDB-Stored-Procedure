DELIMITER //

CREATE PROCEDURE json_to_table(IN json_text TEXT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RESIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid JSON object', MYSQL_ERRNO = 333;
    END;
    
    SET @json = JSON_VALID(json_text);
    
    IF @json IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid JSON object', MYSQL_ERRNO = 333;
    END IF;
    
    SET @keys = JSON_KEYS(json_text);
    SET @num_keys = JSON_LENGTH(@keys);
    SET @idx = 0;
    SET @sql = NULL;
    
    WHILE @idx < @num_keys DO
        SET @key = JSON_UNQUOTE(JSON_EXTRACT(@keys, CONCAT('$[', @idx, ']')));
        SET @value = JSON_EXTRACT(json_text, CONCAT('$.', JSON_UNQUOTE(JSON_EXTRACT(@keys, CONCAT('$[', @idx, ']')))));
        
        IF @idx = 0 THEN
            SET @sql = CONCAT('SELECT "', @key, '" AS `key`, ', 'CAST(', QUOTE(JSON_UNQUOTE(@value)), ' AS CHAR) AS `value`');
        ELSE
            SET @sql = CONCAT(@sql, ' UNION ALL SELECT "', @key, '", ', 'CAST(', QUOTE(JSON_UNQUOTE(@value)), ' AS CHAR) AS `value`');
        END IF;
        
        SET @idx = @idx + 1;
    END WHILE;
    
    SET @sql = CONCAT(@sql, ';');
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //

DELIMITER ;