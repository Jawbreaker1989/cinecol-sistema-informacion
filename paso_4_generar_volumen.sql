-- ============================================
-- PASO 4 - GENERACION DE VOLUMEN PARA EL DW
-- Ejecutar despues de paso_3_correccion_datos.sql.
-- Genera 2.500 ventas y 12.500 boletos, repartidos
-- entre agosto y octubre de 2026.
-- ============================================

DECLARE
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    v_salas              t_ids;
    v_salas_count        PLS_INTEGER := 0;
    v_id_sala            sala.id_sala%TYPE;
    v_id_asiento         asiento.id_asiento%TYPE;
    v_id_empleado        empleado.id_empleado%TYPE;
    v_id_funcion         funcion.id_funcion%TYPE;
    v_id_venta            venta.id_venta%TYPE;
    v_id_boleto           boleto.id_boleto%TYPE;
    v_id_ciudad           sucursal.id_ciudad%TYPE;
    v_id_sucursal         sala.id_sucursal%TYPE;
    v_nombre_sala        sala.nombre_sala%TYPE;
    v_fecha_funcion      DATE;
    v_inicio_ts          TIMESTAMP;
    v_fin_ts             TIMESTAMP;
    v_precio              boleto.precio%TYPE;
    v_total               venta.total%TYPE;
    v_grupo_dia           PLS_INTEGER;
    v_slot                PLS_INTEGER;
    v_numero_asiento     PLS_INTEGER;
BEGIN
    -- Algunas cargas iniciales solo crean sucursales 1 a 8.
    -- Completa las sucursales 9 a 19 usando ciudades ya cargadas.
    FOR n IN 9..19 LOOP
        BEGIN
            SELECT id_sucursal
            INTO v_id_sucursal
            FROM sucursal
            WHERE id_sucursal = n;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                SELECT MIN(id_ciudad)
                INTO v_id_ciudad
                FROM ciudad
                HAVING COUNT(*) > 0;

                INSERT INTO sucursal (
                    id_sucursal, nombre_sucursal, direccion,
                    telefono, id_ciudad
                ) VALUES (
                    n,
                    'CineCol Generada ' || n,
                    'Direccion generada ' || n,
                    '600555' || LPAD(TO_CHAR(n), 4, '0'),
                    v_id_ciudad
                );
        END;
    END LOOP;

    -- Asegura una sala y 30 asientos en cada sucursal 9 a 19.
    FOR r IN (SELECT id_sucursal
              FROM sucursal
              WHERE id_sucursal BETWEEN 9 AND 19
              ORDER BY id_sucursal) LOOP
        SELECT COUNT(*)
        INTO v_grupo_dia
        FROM sala
        WHERE id_sucursal = r.id_sucursal;

        IF v_grupo_dia = 0 THEN
            SELECT NVL(MAX(id_sala), 0) + 1
            INTO v_id_sala
            FROM sala;

            INSERT INTO sala (
                id_sala, nombre_sala, capacidad_asientos, id_sucursal
            ) VALUES (
                v_id_sala,
                CASE WHEN MOD(r.id_sucursal, 3) = 0
                     THEN 'Sala VIP ' || r.id_sucursal
                     ELSE 'Sala Estandar ' || r.id_sucursal
                END,
                30,
                r.id_sucursal
            );
        ELSE
            SELECT MIN(id_sala)
            INTO v_id_sala
            FROM sala
            WHERE id_sucursal = r.id_sucursal;
        END IF;

        FOR n IN 1..30 LOOP
            BEGIN
                SELECT id_asiento
                INTO v_id_asiento
                FROM asiento
                WHERE id_sala = v_id_sala
                  AND numero = n
                  AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    SELECT NVL(MAX(id_asiento), 0) + 1
                    INTO v_id_asiento
                    FROM asiento;

                    INSERT INTO asiento (
                        id_asiento, fila, numero, id_sala
                    ) VALUES (
                        v_id_asiento,
                        CHR(64 + CEIL(n / 10)),
                        n,
                        v_id_sala
                    );
            END;
        END LOOP;

        SELECT COUNT(*)
        INTO v_grupo_dia
        FROM empleado
        WHERE id_sucursal = r.id_sucursal
          AND UPPER(cargo) = 'TAQUILLERO';

        IF v_grupo_dia = 0 THEN
            SELECT NVL(MAX(id_empleado), 0) + 1
            INTO v_id_empleado
            FROM empleado;

            INSERT INTO empleado (
                id_empleado, nombre_empleado, cargo, id_sucursal
            ) VALUES (
                v_id_empleado,
                'Taquillero Generado ' || r.id_sucursal,
                'Taquillero',
                r.id_sucursal
            );
        END IF;
    END LOOP;

    -- Carga la lista de salas de las sucursales nuevas.
    SELECT id_sala
    BULK COLLECT INTO v_salas
    FROM sala
    WHERE id_sucursal BETWEEN 9 AND 19
    ORDER BY id_sala;

    v_salas_count := v_salas.COUNT;

    IF v_salas_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20041, 'No hay salas disponibles para generar volumen.');
    END IF;

    SELECT NVL(MAX(id_funcion), 0) + 1 INTO v_id_funcion FROM funcion;
    SELECT NVL(MAX(id_venta), 0) + 1 INTO v_id_venta FROM venta;
    SELECT NVL(MAX(id_boleto), 0) + 1 INTO v_id_boleto FROM boleto;

    FOR i IN 1..2500 LOOP
        v_id_sala := v_salas(MOD(i - 1, v_salas_count) + 1);

        SELECT id_sucursal, nombre_sala
        INTO v_id_sucursal, v_nombre_sala
        FROM sala
        WHERE id_sala = v_id_sala;

        v_grupo_dia := TRUNC((i - 1) / v_salas_count);
        v_fecha_funcion := DATE '2026-08-01' + MOD(v_grupo_dia, 92);
        v_slot := MOD(TRUNC(v_grupo_dia / 92), 4);
        v_inicio_ts := CAST(v_fecha_funcion AS TIMESTAMP)
                       + NUMTODSINTERVAL(600 + (v_slot * 240), 'MINUTE');
        v_fin_ts := v_inicio_ts + NUMTODSINTERVAL(120, 'MINUTE');

        INSERT INTO funcion (
            id_funcion, fecha, hora_inicio, hora_fin,
            inicio_ts, fin_ts, id_pelicula, id_sala
        ) VALUES (
            v_id_funcion,
            v_fecha_funcion,
            TO_CHAR(v_inicio_ts, 'HH24:MI'),
            TO_CHAR(v_fin_ts, 'HH24:MI'),
            v_inicio_ts,
            v_fin_ts,
            MOD(i - 1, 30) + 1,
            v_id_sala
        );

        SELECT MIN(id_empleado)
        INTO v_id_empleado
        FROM empleado
        WHERE id_sucursal = v_id_sucursal
          AND UPPER(cargo) = 'TAQUILLERO';

        v_precio := CASE
                        WHEN INSTR(UPPER(v_nombre_sala), 'VIP') > 0
                        THEN 28000
                        ELSE 18000
                    END;
        v_total := v_precio * 5;

        INSERT INTO venta (
            id_venta, fecha_venta, total, id_cliente,
            id_empleado, id_metodo_pago, id_sucursal
        ) VALUES (
            v_id_venta,
            CAST(v_inicio_ts - NUMTODSINTERVAL(30, 'MINUTE') AS DATE),
            v_total,
            MOD(i - 1, 60) + 1,
            v_id_empleado,
            MOD(i - 1, 5) + 1,
            v_id_sucursal
        );

        FOR n IN 1..5 LOOP
            v_numero_asiento := n;

            SELECT id_asiento
            INTO v_id_asiento
            FROM asiento
            WHERE id_sala = v_id_sala
              AND numero = v_numero_asiento
              AND ROWNUM = 1;

            INSERT INTO boleto (
                id_boleto, numero_asiento, precio,
                id_venta, id_funcion, id_asiento
            ) VALUES (
                v_id_boleto,
                v_numero_asiento,
                v_precio,
                v_id_venta,
                v_id_funcion,
                v_id_asiento
            );

            v_id_boleto := v_id_boleto + 1;
        END LOOP;

        v_id_funcion := v_id_funcion + 1;
        v_id_venta := v_id_venta + 1;
    END LOOP;

    COMMIT;
END;
/

-- Evidencia mínima del volumen generado.
SELECT COUNT(*) AS funciones_agosto_octubre
FROM funcion
WHERE fecha BETWEEN DATE '2026-08-01' AND DATE '2026-10-31';

SELECT COUNT(*) AS ventas_totales,
       COUNT(DISTINCT id_cliente) AS clientes_con_compras
FROM venta;

SELECT COUNT(*) AS boletos_totales
FROM boleto;

SELECT COUNT(DISTINCT v.id_sucursal) AS sucursales_con_ventas
FROM venta v
WHERE v.id_sucursal BETWEEN 1 AND 19;
