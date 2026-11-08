-- ============================================
-- AUDITORIA OLTP - PASO 1 DEL DW CINECOL
-- Solo lectura: cada consulta debe devolver 0 filas.
-- Ejecutar en Oracle SQL Developer y guardar cada resultado.
-- ============================================

-- 1. El total de la venta debe coincidir con la suma de sus boletos.
SELECT v.id_venta,
       v.total AS total_venta,
       SUM(b.precio) AS total_boletos
FROM venta v
LEFT JOIN boleto b ON b.id_venta = v.id_venta
GROUP BY v.id_venta, v.total
HAVING v.total <> NVL(SUM(b.precio), 0)
ORDER BY v.id_venta;

-- 2. El empleado debe pertenecer a la sucursal de la venta.
SELECT v.id_venta,
       v.id_sucursal AS sucursal_venta,
       e.id_empleado,
       e.id_sucursal AS sucursal_empleado
FROM venta v
JOIN empleado e ON e.id_empleado = v.id_empleado
WHERE v.id_sucursal <> e.id_sucursal
ORDER BY v.id_venta;

-- 3. La función debe pertenecer a la sucursal que realizó la venta.
SELECT DISTINCT v.id_venta,
       b.id_funcion,
       v.id_sucursal AS sucursal_venta,
       s.id_sucursal AS sucursal_funcion
FROM boleto b
JOIN venta v ON v.id_venta = b.id_venta
JOIN funcion f ON f.id_funcion = b.id_funcion
JOIN sala s ON s.id_sala = f.id_sala
WHERE v.id_sucursal <> s.id_sucursal
ORDER BY v.id_venta, b.id_funcion;

-- 4. El asiento vendido debe pertenecer a la sala de la función.
SELECT b.id_boleto,
       b.id_funcion,
       b.id_asiento,
       f.id_sala AS sala_funcion,
       a.id_sala AS sala_asiento
FROM boleto b
JOIN funcion f ON f.id_funcion = b.id_funcion
JOIN asiento a ON a.id_asiento = b.id_asiento
WHERE a.id_sala <> f.id_sala
ORDER BY b.id_boleto;

-- 5. La venta debe registrarse antes del inicio de la función.
SELECT v.id_venta,
       v.fecha_venta,
       b.id_funcion,
       f.fecha,
       f.hora_inicio
FROM venta v
JOIN boleto b ON b.id_venta = v.id_venta
JOIN funcion f ON f.id_funcion = b.id_funcion
WHERE v.fecha_venta >
      TO_DATE(
          TO_CHAR(f.fecha, 'YYYY-MM-DD') || ' ' || f.hora_inicio,
          'YYYY-MM-DD HH24:MI'
      )
ORDER BY v.id_venta, b.id_funcion;

-- 6. El cliente debe tener edad suficiente para la clasificación.
SELECT DISTINCT c.id_cliente,
       c.nombre_cliente,
       b.id_boleto,
       f.id_funcion,
       p.titulo,
       cl.nombre_clasificacion,
       cl.edad_minima,
       TRUNC(MONTHS_BETWEEN(f.fecha, c.fecha_nacimiento) / 12) AS edad
FROM cliente c
JOIN venta v ON v.id_cliente = c.id_cliente
JOIN boleto b ON b.id_venta = v.id_venta
JOIN funcion f ON f.id_funcion = b.id_funcion
JOIN pelicula p ON p.id_pelicula = f.id_pelicula
JOIN clasificacion cl ON cl.id_clasificacion = p.id_clasificacion
WHERE TRUNC(MONTHS_BETWEEN(f.fecha, c.fecha_nacimiento) / 12) < cl.edad_minima
ORDER BY c.id_cliente, b.id_boleto;

-- 7. No debe haber funciones solapadas en una misma sala.
WITH rangos AS (
    SELECT f.id_funcion,
           f.id_sala,
           TO_DATE(
               TO_CHAR(f.fecha, 'YYYY-MM-DD') || ' ' || f.hora_inicio,
               'YYYY-MM-DD HH24:MI'
           ) AS inicio_funcion,
           TO_DATE(
               TO_CHAR(f.fecha, 'YYYY-MM-DD') || ' ' || f.hora_fin,
               'YYYY-MM-DD HH24:MI'
           ) + CASE
                   WHEN f.hora_fin < f.hora_inicio THEN 1
                   ELSE 0
               END AS fin_funcion
    FROM funcion f
)
SELECT r1.id_sala,
       r1.id_funcion AS funcion_1,
       r2.id_funcion AS funcion_2,
       r1.inicio_funcion AS inicio_1,
       r1.fin_funcion AS fin_1,
       r2.inicio_funcion AS inicio_2,
       r2.fin_funcion AS fin_2
FROM rangos r1
JOIN rangos r2
  ON r2.id_sala = r1.id_sala
 AND r2.id_funcion > r1.id_funcion
 AND r1.inicio_funcion < r2.fin_funcion
 AND r2.inicio_funcion < r1.fin_funcion
ORDER BY r1.id_sala, r1.id_funcion, r2.id_funcion;
