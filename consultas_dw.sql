-- ============================================
-- BLOQUE E - EXPLOTACION ANALITICA DEL DW
-- Ejecutar conectado como CINECOL_DW.
-- ============================================

-- 1. Ingresos por sucursal y mes.
SELECT ds.nombre_sucursal,
       tf.anio,
       tf.mes,
       SUM(f.precio) AS ingresos
FROM fact_venta_boleto f
JOIN dim_sala ds ON ds.sk_sala = f.sk_sala
JOIN dim_tiempo tf ON tf.sk_tiempo = f.sk_tiempo_funcion
GROUP BY ds.nombre_sucursal, tf.anio, tf.mes
ORDER BY tf.anio, tf.mes, ingresos DESC;

-- 2. Top 5 peliculas por boletos dentro de cada genero.
SELECT genero, titulo, boletos
FROM (
    SELECT dp.genero,
           dp.titulo,
           COUNT(*) AS boletos,
           RANK() OVER (
               PARTITION BY dp.genero
               ORDER BY COUNT(*) DESC
           ) AS posicion
    FROM fact_venta_boleto f
    JOIN dim_pelicula dp ON dp.sk_pelicula = f.sk_pelicula
    GROUP BY dp.genero, dp.titulo
)
WHERE posicion <= 5
ORDER BY genero, posicion, titulo;

-- 3. Ingresos por franja horaria y dia de la semana.
SELECT df.franja,
       tf.dia_semana,
       SUM(f.precio) AS ingresos
FROM fact_venta_boleto f
JOIN dim_franja df ON df.sk_franja = f.sk_franja
JOIN dim_tiempo tf ON tf.sk_tiempo = f.sk_tiempo_funcion
GROUP BY df.franja, tf.dia_semana
ORDER BY df.franja, tf.dia_semana;

-- 4. Ocupacion promedio por sala y tipo.
SELECT ds.nombre_sala,
       ds.tipo_sala,
       ROUND(
           100 * SUM(o.boletos_vendidos) / NULLIF(SUM(o.capacidad), 0),
           2
       ) AS ocupacion_promedio_pct
FROM fact_ocupacion_funcion o
JOIN dim_sala ds ON ds.sk_sala = o.sk_sala
GROUP BY ds.nombre_sala, ds.tipo_sala
ORDER BY ds.tipo_sala, ocupacion_promedio_pct DESC;

-- 5. Ingresos por metodo de pago y participacion.
SELECT dm.nombre_metodo,
       SUM(f.precio) AS ingresos,
       ROUND(
           100 * RATIO_TO_REPORT(SUM(f.precio)) OVER (),
           2
       ) AS participacion_pct
FROM fact_venta_boleto f
JOIN dim_metodo_pago dm ON dm.sk_metodo_pago = f.sk_metodo_pago
GROUP BY dm.nombre_metodo
ORDER BY ingresos DESC;

-- 6. Crecimiento de ingresos mes a mes.
WITH mensual AS (
    SELECT tf.anio,
           tf.mes,
           SUM(f.precio) AS ingresos
    FROM fact_venta_boleto f
    JOIN dim_tiempo tf ON tf.sk_tiempo = f.sk_tiempo_funcion
    GROUP BY tf.anio, tf.mes
)
SELECT anio,
       mes,
       ingresos,
       LAG(ingresos) OVER (ORDER BY anio, mes) AS ingresos_mes_anterior,
       ROUND(
           100 * (ingresos - LAG(ingresos) OVER (ORDER BY anio, mes))
           / NULLIF(LAG(ingresos) OVER (ORDER BY anio, mes), 0),
           2
       ) AS crecimiento_pct
FROM mensual
ORDER BY anio, mes;

-- 7. Ingresos acumulados por sucursal y fecha.
SELECT ds.nombre_sucursal,
       tf.fecha,
       SUM(f.precio) AS ingresos_dia,
       SUM(SUM(f.precio)) OVER (
           PARTITION BY ds.nombre_sucursal
           ORDER BY tf.fecha
           ROWS UNBOUNDED PRECEDING
       ) AS ingresos_acumulados
FROM fact_venta_boleto f
JOIN dim_sala ds ON ds.sk_sala = f.sk_sala
JOIN dim_tiempo tf ON tf.sk_tiempo = f.sk_tiempo_funcion
GROUP BY ds.nombre_sucursal, tf.fecha
ORDER BY ds.nombre_sucursal, tf.fecha;

-- 8. Subtotales por departamento, ciudad y sucursal.
SELECT ds.departamento,
       ds.ciudad,
       ds.nombre_sucursal,
       GROUPING(ds.departamento) AS grp_departamento,
       GROUPING(ds.ciudad) AS grp_ciudad,
       GROUPING(ds.nombre_sucursal) AS grp_sucursal,
       SUM(f.precio) AS ingresos
FROM fact_venta_boleto f
JOIN dim_sala ds ON ds.sk_sala = f.sk_sala
GROUP BY ROLLUP(ds.departamento, ds.ciudad, ds.nombre_sucursal)
ORDER BY ds.departamento, ds.ciudad, ds.nombre_sucursal;

-- 9. Perfil de publico: rango de edad por genero.
SELECT dc.rango_edad,
       dp.genero,
       COUNT(*) AS boletos
FROM fact_venta_boleto f
JOIN dim_cliente dc ON dc.sk_cliente = f.sk_cliente
JOIN dim_pelicula dp ON dp.sk_pelicula = f.sk_pelicula
GROUP BY CUBE(dc.rango_edad, dp.genero)
ORDER BY dc.rango_edad, dp.genero;

-- 10. Top empleados por ventas y ticket promedio por sucursal.
WITH resumen AS (
    SELECT de.nombre_sucursal,
           de.nombre_empleado,
           COUNT(DISTINCT f.id_venta) AS ventas,
           ROUND(SUM(f.precio) / COUNT(DISTINCT f.id_venta), 2)
             AS ticket_promedio
    FROM fact_venta_boleto f
    JOIN dim_empleado de ON de.sk_empleado = f.sk_empleado
    GROUP BY de.nombre_sucursal, de.nombre_empleado
)
SELECT nombre_sucursal,
       nombre_empleado,
       ventas,
       ticket_promedio,
       DENSE_RANK() OVER (
           PARTITION BY nombre_sucursal
           ORDER BY ventas DESC
       ) AS posicion
FROM resumen
ORDER BY nombre_sucursal, posicion, nombre_empleado;

-- Contraste 1: ingresos por sucursal y mes en OLTP.
SELECT s.nombre_sucursal,
       EXTRACT(YEAR FROM f.fecha) AS anio,
       EXTRACT(MONTH FROM f.fecha) AS mes,
       SUM(b.precio) AS ingresos
FROM CINECOL_R.boleto b
JOIN CINECOL_R.funcion f ON f.id_funcion = b.id_funcion
JOIN CINECOL_R.sala sa ON sa.id_sala = f.id_sala
JOIN CINECOL_R.sucursal s ON s.id_sucursal = sa.id_sucursal
GROUP BY s.nombre_sucursal, EXTRACT(YEAR FROM f.fecha),
         EXTRACT(MONTH FROM f.fecha)
ORDER BY anio, mes, ingresos DESC;

-- Contraste 2: ingresos por metodo de pago en OLTP.
SELECT m.nombre_metodo,
       SUM(b.precio) AS ingresos
FROM CINECOL_R.boleto b
JOIN CINECOL_R.venta v ON v.id_venta = b.id_venta
JOIN CINECOL_R.metodo_pago m ON m.id_metodo_pago = v.id_metodo_pago
GROUP BY m.nombre_metodo
ORDER BY ingresos DESC;

-- Contraste 3: ocupacion por funcion en OLTP.
SELECT f.id_funcion,
       COUNT(b.id_boleto) AS boletos_vendidos,
       sa.capacidad_asientos AS capacidad,
       ROUND(100 * COUNT(b.id_boleto) / NULLIF(sa.capacidad_asientos, 0), 2)
         AS ocupacion_pct
FROM CINECOL_R.funcion f
JOIN CINECOL_R.sala sa ON sa.id_sala = f.id_sala
LEFT JOIN CINECOL_R.boleto b ON b.id_funcion = f.id_funcion
GROUP BY f.id_funcion, sa.capacidad_asientos
ORDER BY f.id_funcion;

-- Planes de ejecucion para las consultas 1 y 4.
EXPLAIN PLAN FOR
SELECT ds.nombre_sucursal, tf.anio, tf.mes, SUM(f.precio) AS ingresos
FROM fact_venta_boleto f
JOIN dim_sala ds ON ds.sk_sala = f.sk_sala
JOIN dim_tiempo tf ON tf.sk_tiempo = f.sk_tiempo_funcion
GROUP BY ds.nombre_sucursal, tf.anio, tf.mes;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR
SELECT ds.tipo_sala,
       ROUND(100 * SUM(o.boletos_vendidos) / NULLIF(SUM(o.capacidad), 0), 2)
FROM fact_ocupacion_funcion o
JOIN dim_sala ds ON ds.sk_sala = o.sk_sala
GROUP BY ds.tipo_sala;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
