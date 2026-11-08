-- ============================================
-- PASO 3 - CORRECCION DE DATOS EXISTENTES
-- Ejecutar despues de paso_2_estructura_oltp.sql.
-- No amplia el volumen; esa tarea corresponde al Paso 4.
-- ============================================

-- 1. Completar celulares de los clientes 31 a 60 con exactamente 10 digitos.
-- Se usa un valor determinista para que el script sea repetible.
UPDATE cliente
SET celular = '3' || LPAD(TO_CHAR(id_cliente), 9, '0')
WHERE id_cliente BETWEEN 31 AND 60
  AND (celular IS NULL OR LENGTH(celular) <> 10);

-- 2. Ajustar la hora de cada venta para que ocurra al menos 30 minutos
-- antes de la primera funcion asociada a sus boletos.
-- Si la funcion inicia antes de las 10:30, la venta queda el dia anterior
-- a las 10:00. La fecha almacenada conserva fecha y hora en Oracle DATE.
UPDATE venta v
SET fecha_venta = (
    SELECT CASE
             WHEN MIN(f.inicio_ts) >=
                  CAST(TRUNC(CAST(MIN(f.inicio_ts) AS DATE)) AS TIMESTAMP)
                  + NUMTODSINTERVAL(10 * 60 + 30, 'MINUTE')
             THEN MIN(f.inicio_ts) - NUMTODSINTERVAL(30, 'MINUTE')
             ELSE CAST(TRUNC(CAST(MIN(f.inicio_ts) AS DATE)) AS TIMESTAMP)
                  - NUMTODSINTERVAL(14 * 60, 'HOUR')
           END
    FROM boleto b
    JOIN funcion f ON f.id_funcion = b.id_funcion
    WHERE b.id_venta = v.id_venta
)
WHERE EXISTS (
    SELECT 1
    FROM boleto b
    WHERE b.id_venta = v.id_venta
);

-- 3. Conservar las peliculas 1 a 30. Las peliculas 31 a 60 se eliminan
-- solo si no tienen funciones; el bloque aborta si existe una referencia.
DECLARE
    v_funciones NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_funciones
    FROM funcion
    WHERE id_pelicula > 30;

    IF v_funciones > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20031,
            'No se pueden eliminar peliculas 31-60: existen funciones asociadas.'
        );
    END IF;

    DELETE FROM pelicula
    WHERE id_pelicula BETWEEN 31 AND 60;
END;
/

COMMIT;

-- 4. Controles de resultado: deben devolver 0 filas.
SELECT id_cliente, celular
FROM cliente
WHERE id_cliente BETWEEN 31 AND 60
  AND (celular IS NULL OR NOT REGEXP_LIKE(celular, '^[0-9]{10}$'))
ORDER BY id_cliente;

SELECT v.id_venta,
       v.fecha_venta,
       MIN(f.inicio_ts) AS primera_funcion
FROM venta v
JOIN boleto b ON b.id_venta = v.id_venta
JOIN funcion f ON f.id_funcion = b.id_funcion
GROUP BY v.id_venta, v.fecha_venta
HAVING v.fecha_venta > MIN(f.inicio_ts) - NUMTODSINTERVAL(15, 'MINUTE')
ORDER BY v.id_venta;

SELECT id_pelicula, titulo
FROM pelicula
WHERE id_pelicula > 30
ORDER BY id_pelicula;
