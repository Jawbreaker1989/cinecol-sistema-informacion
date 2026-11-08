-- ============================================
-- BLOQUE D - VALIDACION Y RECONCILIACION
-- Ejecutar conectado como CINECOL_DW.
-- Las consultas de control deben devolver 0 filas,
-- salvo los conteos y totales que deben coincidir.
-- ============================================

-- 1. Conteos OLTP contra hechos.
SELECT
    (SELECT COUNT(*) FROM CINECOL_R.boleto) AS boletos_oltp,
    (SELECT COUNT(*) FROM fact_venta_boleto) AS boletos_dw,
    (SELECT COUNT(*) FROM CINECOL_R.funcion) AS funciones_oltp,
    (SELECT COUNT(*) FROM fact_ocupacion_funcion) AS funciones_dw
FROM dual;

-- 2. Sumas de precios y totales de venta.
SELECT
    (SELECT NVL(SUM(precio), 0) FROM CINECOL_R.boleto) AS ingresos_boletos_oltp,
    (SELECT NVL(SUM(precio), 0) FROM fact_venta_boleto) AS ingresos_boletos_dw,
    (SELECT NVL(SUM(total), 0) FROM CINECOL_R.venta) AS total_ventas_oltp
FROM dual;

-- 3. Diferencias numéricas: deben devolver una sola fila con ceros.
SELECT
    (SELECT COUNT(*) FROM CINECOL_R.boleto)
      - (SELECT COUNT(*) FROM fact_venta_boleto) AS diferencia_boleto,
    (SELECT NVL(SUM(precio), 0) FROM CINECOL_R.boleto)
      - (SELECT NVL(SUM(precio), 0) FROM fact_venta_boleto) AS diferencia_ingresos,
    (SELECT NVL(SUM(total), 0) FROM CINECOL_R.venta)
      - (SELECT NVL(SUM(precio), 0) FROM fact_venta_boleto) AS diferencia_ventas,
    (SELECT COUNT(*) FROM CINECOL_R.funcion)
      - (SELECT COUNT(*) FROM fact_ocupacion_funcion) AS diferencia_funciones
FROM dual;

-- 4. Boletos con SK desconocida: debe devolver 0 filas.
SELECT id_boleto
FROM fact_venta_boleto
WHERE sk_tiempo_funcion = -1
   OR sk_tiempo_venta = -1
   OR sk_pelicula = -1
   OR sk_sala = -1
   OR sk_cliente = -1
   OR sk_empleado = -1
   OR sk_metodo_pago = -1
   OR sk_franja = -1
ORDER BY id_boleto;

-- 5. Rechazos ETL: debe devolver 0 filas.
SELECT id_rechazo, id_boleto, motivo
FROM etl_rechazo_boleto
ORDER BY id_rechazo;

-- 6. Business keys duplicadas: cada consulta debe devolver 0 filas.
SELECT id_pelicula, COUNT(*) AS cantidad
FROM dim_pelicula
WHERE id_pelicula <> -1
GROUP BY id_pelicula
HAVING COUNT(*) > 1;

SELECT id_sala, COUNT(*) AS cantidad
FROM dim_sala
WHERE id_sala <> -1
GROUP BY id_sala
HAVING COUNT(*) > 1;

SELECT id_cliente, COUNT(*) AS cantidad
FROM dim_cliente
WHERE id_cliente <> -1
GROUP BY id_cliente
HAVING COUNT(*) > 1;

SELECT id_empleado, COUNT(*) AS cantidad
FROM dim_empleado
WHERE id_empleado <> -1
GROUP BY id_empleado
HAVING COUNT(*) > 1;

SELECT id_metodo_pago, COUNT(*) AS cantidad
FROM dim_metodo_pago
WHERE id_metodo_pago <> -1
GROUP BY id_metodo_pago
HAVING COUNT(*) > 1;

-- 7. Evidencia punta a punta para tres boletos.
SELECT fvb.id_boleto,
       fvb.id_venta,
       fvb.id_funcion,
       fvb.precio,
       tf.fecha AS fecha_funcion,
       tv.fecha AS fecha_venta,
       dp.titulo,
       ds.nombre_sala,
       dc.nombre_cliente,
       de.nombre_empleado,
       dm.nombre_metodo,
       df.franja
FROM (
    SELECT id_boleto
    FROM fact_venta_boleto
    ORDER BY id_boleto
    FETCH FIRST 3 ROWS ONLY
) muestra
JOIN fact_venta_boleto fvb ON fvb.id_boleto = muestra.id_boleto
JOIN dim_tiempo tf ON tf.sk_tiempo = fvb.sk_tiempo_funcion
JOIN dim_tiempo tv ON tv.sk_tiempo = fvb.sk_tiempo_venta
JOIN dim_pelicula dp ON dp.sk_pelicula = fvb.sk_pelicula
JOIN dim_sala ds ON ds.sk_sala = fvb.sk_sala
JOIN dim_cliente dc ON dc.sk_cliente = fvb.sk_cliente
JOIN dim_empleado de ON de.sk_empleado = fvb.sk_empleado
JOIN dim_metodo_pago dm ON dm.sk_metodo_pago = fvb.sk_metodo_pago
JOIN dim_franja df ON df.sk_franja = fvb.sk_franja
ORDER BY fvb.id_boleto;

-- 8. Estadisticas para el optimizador.
BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(
        ownname => USER,
        options => 'GATHER AUTO',
        cascade => TRUE
    );
END;
/

COMMIT;
