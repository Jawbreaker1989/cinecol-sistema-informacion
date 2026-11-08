-- ============================================
-- BLOQUE C - ETL CINECOL DW
-- Ejecutar conectado como CINECOL_DW.
-- Dimensiones: MERGE por business key (SCD tipo 1).
-- Facts: TRUNCATE y recarga completa para este proyecto.
-- ============================================

-- DIM_TIEMPO: incluye el dia anterior por ventas de funciones tempranas.
MERGE INTO dim_tiempo d
USING (
    SELECT DATE '2026-07-01' + LEVEL - 1 AS fecha
    FROM dual
    CONNECT BY LEVEL <= (DATE '2026-12-31' - DATE '2026-07-01') + 1
) x
ON (d.fecha = x.fecha)
WHEN NOT MATCHED THEN
    INSERT (
        sk_tiempo, fecha, dia, mes, nombre_mes, trimestre,
        anio, dia_semana, es_fin_de_semana
    )
    VALUES (
        seq_dim_tiempo.NEXTVAL,
        x.fecha,
        EXTRACT(DAY FROM x.fecha),
        EXTRACT(MONTH FROM x.fecha),
        TO_CHAR(x.fecha, 'Month', 'NLS_DATE_LANGUAGE=SPANISH'),
        TO_NUMBER(TO_CHAR(x.fecha, 'Q')),
        EXTRACT(YEAR FROM x.fecha),
        TO_CHAR(x.fecha, 'Day', 'NLS_DATE_LANGUAGE=SPANISH'),
        CASE
            WHEN TO_CHAR(x.fecha, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH')
                 IN ('SAT', 'SUN') THEN 'S'
            ELSE 'N'
        END
    );

MERGE INTO dim_pelicula d
USING (
    SELECT p.id_pelicula, p.titulo, p.duracion_min,
           g.nombre_genero AS genero,
           c.nombre_clasificacion AS clasificacion,
           c.edad_minima
    FROM CINECOL_R.pelicula p
    JOIN CINECOL_R.genero g ON g.id_genero = p.id_genero
    JOIN CINECOL_R.clasificacion c
      ON c.id_clasificacion = p.id_clasificacion
) x
ON (d.id_pelicula = x.id_pelicula)
WHEN MATCHED THEN UPDATE SET
    d.titulo = x.titulo,
    d.duracion_min = x.duracion_min,
    d.genero = x.genero,
    d.clasificacion = x.clasificacion,
    d.edad_minima = x.edad_minima
WHEN NOT MATCHED THEN INSERT (
    sk_pelicula, id_pelicula, titulo, duracion_min,
    genero, clasificacion, edad_minima
) VALUES (
    seq_dim_pelicula.NEXTVAL, x.id_pelicula, x.titulo, x.duracion_min,
    x.genero, x.clasificacion, x.edad_minima
);

MERGE INTO dim_sala d
USING (
    SELECT sa.id_sala, sa.nombre_sala, sa.capacidad_asientos AS capacidad,
           CASE WHEN INSTR(UPPER(sa.nombre_sala), 'VIP') > 0
                THEN 'VIP' ELSE 'Estandar' END AS tipo_sala,
           su.id_sucursal, su.nombre_sucursal,
           ci.nombre_ciudad AS ciudad, ci.departamento
    FROM CINECOL_R.sala sa
    JOIN CINECOL_R.sucursal su ON su.id_sucursal = sa.id_sucursal
    JOIN CINECOL_R.ciudad ci ON ci.id_ciudad = su.id_ciudad
) x
ON (d.id_sala = x.id_sala)
WHEN MATCHED THEN UPDATE SET
    d.nombre_sala = x.nombre_sala,
    d.capacidad = x.capacidad,
    d.tipo_sala = x.tipo_sala,
    d.id_sucursal = x.id_sucursal,
    d.nombre_sucursal = x.nombre_sucursal,
    d.ciudad = x.ciudad,
    d.departamento = x.departamento
WHEN NOT MATCHED THEN INSERT (
    sk_sala, id_sala, nombre_sala, capacidad, tipo_sala,
    id_sucursal, nombre_sucursal, ciudad, departamento
) VALUES (
    seq_dim_sala.NEXTVAL, x.id_sala, x.nombre_sala, x.capacidad,
    x.tipo_sala, x.id_sucursal, x.nombre_sucursal, x.ciudad, x.departamento
);

MERGE INTO dim_cliente d
USING (
    SELECT c.id_cliente, c.nombre_cliente, c.documento,
           CASE
             WHEN TRUNC(MONTHS_BETWEEN(DATE '2026-10-31',
                                       c.fecha_nacimiento) / 12) < 18
               THEN 'Menor de 18'
             WHEN TRUNC(MONTHS_BETWEEN(DATE '2026-10-31',
                                       c.fecha_nacimiento) / 12) BETWEEN 18 AND 25
               THEN '18-25'
             WHEN TRUNC(MONTHS_BETWEEN(DATE '2026-10-31',
                                       c.fecha_nacimiento) / 12) BETWEEN 26 AND 40
               THEN '26-40'
             WHEN TRUNC(MONTHS_BETWEEN(DATE '2026-10-31',
                                       c.fecha_nacimiento) / 12) BETWEEN 41 AND 60
               THEN '41-60'
             ELSE 'Mas de 60'
           END AS rango_edad
    FROM CINECOL_R.cliente c
) x
ON (d.id_cliente = x.id_cliente)
WHEN MATCHED THEN UPDATE SET
    d.nombre_cliente = x.nombre_cliente,
    d.documento = x.documento,
    d.rango_edad = x.rango_edad
WHEN NOT MATCHED THEN INSERT (
    sk_cliente, id_cliente, nombre_cliente, documento, rango_edad
) VALUES (
    seq_dim_cliente.NEXTVAL, x.id_cliente, x.nombre_cliente,
    x.documento, x.rango_edad
);

MERGE INTO dim_empleado d
USING (
    SELECT e.id_empleado, e.nombre_empleado, e.cargo,
           e.id_sucursal, s.nombre_sucursal
    FROM CINECOL_R.empleado e
    JOIN CINECOL_R.sucursal s ON s.id_sucursal = e.id_sucursal
) x
ON (d.id_empleado = x.id_empleado)
WHEN MATCHED THEN UPDATE SET
    d.nombre_empleado = x.nombre_empleado,
    d.cargo = x.cargo,
    d.id_sucursal = x.id_sucursal,
    d.nombre_sucursal = x.nombre_sucursal
WHEN NOT MATCHED THEN INSERT (
    sk_empleado, id_empleado, nombre_empleado, cargo,
    id_sucursal, nombre_sucursal
) VALUES (
    seq_dim_empleado.NEXTVAL, x.id_empleado, x.nombre_empleado, x.cargo,
    x.id_sucursal, x.nombre_sucursal
);

MERGE INTO dim_metodo_pago d
USING (
    SELECT id_metodo_pago, nombre_metodo
    FROM CINECOL_R.metodo_pago
) x
ON (d.id_metodo_pago = x.id_metodo_pago)
WHEN MATCHED THEN UPDATE SET d.nombre_metodo = x.nombre_metodo
WHEN NOT MATCHED THEN INSERT (
    sk_metodo_pago, id_metodo_pago, nombre_metodo
) VALUES (
    seq_dim_metodo_pago.NEXTVAL, x.id_metodo_pago, x.nombre_metodo
);

MERGE INTO dim_franja d
USING (
    SELECT DISTINCT
           CASE
             WHEN TO_NUMBER(SUBSTR(f.hora_inicio, 1, 2)) < 6
               THEN 'Madrugada'
             WHEN TO_NUMBER(SUBSTR(f.hora_inicio, 1, 2)) < 18
               THEN 'Tarde'
             ELSE 'Noche'
           END AS franja,
           SUBSTR(f.hora_inicio, 1, 2) || ':00' AS hora_inicio
    FROM CINECOL_R.funcion f
) x
ON (d.hora_inicio = x.hora_inicio)
WHEN MATCHED THEN UPDATE SET d.franja = x.franja
WHEN NOT MATCHED THEN INSERT (
    sk_franja, franja, hora_inicio
) VALUES (
    seq_dim_franja.NEXTVAL, x.franja, x.hora_inicio
);

TRUNCATE TABLE etl_rechazo_boleto;
TRUNCATE TABLE fact_venta_boleto;
TRUNCATE TABLE fact_ocupacion_funcion;

-- Rechazos: se registra cualquier boleto sin correspondencia dimensional.
INSERT INTO etl_rechazo_boleto (id_boleto, motivo)
SELECT b.id_boleto,
       'Falta lookup dimensional para venta, funcion, pelicula, sala, cliente, empleado, metodo o franja'
FROM CINECOL_R.boleto b
JOIN CINECOL_R.venta v ON v.id_venta = b.id_venta
JOIN CINECOL_R.funcion f ON f.id_funcion = b.id_funcion
WHERE NOT EXISTS (
    SELECT 1
    FROM dim_pelicula dp
    JOIN dim_sala ds ON ds.id_sala = f.id_sala
    JOIN dim_cliente dc ON dc.id_cliente = v.id_cliente
    JOIN dim_empleado de ON de.id_empleado = v.id_empleado
    JOIN dim_metodo_pago dm ON dm.id_metodo_pago = v.id_metodo_pago
    JOIN dim_tiempo tf ON tf.fecha = TRUNC(f.fecha)
    JOIN dim_tiempo tv ON tv.fecha = TRUNC(v.fecha_venta)
    JOIN dim_franja df
      ON df.hora_inicio = SUBSTR(f.hora_inicio, 1, 2) || ':00'
    WHERE dp.id_pelicula = f.id_pelicula
);

INSERT INTO fact_venta_boleto (
    sk_tiempo_funcion, sk_tiempo_venta, sk_pelicula, sk_sala,
    sk_cliente, sk_empleado, sk_metodo_pago, sk_franja,
    id_venta, id_funcion, id_boleto, precio, cantidad
)
SELECT NVL(tf.sk_tiempo, -1),
       NVL(tv.sk_tiempo, -1),
       NVL(dp.sk_pelicula, -1),
       NVL(ds.sk_sala, -1),
       NVL(dc.sk_cliente, -1),
       NVL(de.sk_empleado, -1),
       NVL(dm.sk_metodo_pago, -1),
       NVL(df.sk_franja, -1),
       v.id_venta,
       f.id_funcion,
       b.id_boleto,
       b.precio,
       1
FROM CINECOL_R.boleto b
JOIN CINECOL_R.venta v ON v.id_venta = b.id_venta
JOIN CINECOL_R.funcion f ON f.id_funcion = b.id_funcion
LEFT JOIN dim_tiempo tf ON tf.fecha = TRUNC(f.fecha)
LEFT JOIN dim_tiempo tv ON tv.fecha = TRUNC(v.fecha_venta)
LEFT JOIN dim_pelicula dp ON dp.id_pelicula = f.id_pelicula
LEFT JOIN dim_sala ds ON ds.id_sala = f.id_sala
LEFT JOIN dim_cliente dc ON dc.id_cliente = v.id_cliente
LEFT JOIN dim_empleado de ON de.id_empleado = v.id_empleado
LEFT JOIN dim_metodo_pago dm ON dm.id_metodo_pago = v.id_metodo_pago
LEFT JOIN dim_franja df ON df.hora_inicio = SUBSTR(f.hora_inicio, 1, 2) || ':00';

INSERT INTO fact_ocupacion_funcion (
    sk_tiempo, sk_pelicula, sk_sala, sk_franja,
    id_funcion, capacidad, boletos_vendidos, ingresos
)
SELECT NVL(dt.sk_tiempo, -1),
       NVL(dp.sk_pelicula, -1),
       NVL(ds.sk_sala, -1),
       NVL(df.sk_franja, -1),
       f.id_funcion,
       NVL(ds.capacidad, 0),
       COUNT(b.id_boleto),
       NVL(SUM(b.precio), 0)
FROM CINECOL_R.funcion f
LEFT JOIN dim_tiempo dt ON dt.fecha = TRUNC(f.fecha)
LEFT JOIN dim_pelicula dp ON dp.id_pelicula = f.id_pelicula
LEFT JOIN dim_sala ds ON ds.id_sala = f.id_sala
LEFT JOIN dim_franja df ON df.hora_inicio = SUBSTR(f.hora_inicio, 1, 2) || ':00'
LEFT JOIN CINECOL_R.boleto b ON b.id_funcion = f.id_funcion
GROUP BY dt.sk_tiempo, dp.sk_pelicula, ds.sk_sala, df.sk_franja,
         f.id_funcion, NVL(ds.capacidad, 0);

COMMIT;
