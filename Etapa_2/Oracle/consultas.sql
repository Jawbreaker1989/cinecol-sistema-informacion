
-- ============================================
-- CONSULTAS SQL - BASE DE DATOS DE CINE
-- Oracle SQL Developer
-- ============================================


-- 1. Todas las peliculas ordenadas por titulo
SELECT titulo, duracion_min
FROM pelicula
ORDER BY titulo;


-- 2. Empleados de la sucursal 1 en orden alfabetico
SELECT nombre_empleado, cargo
FROM empleado
WHERE id_sucursal = 1
ORDER BY nombre_empleado;


-- 3. Peliculas con su clasificacion
SELECT titulo, nombre_clasificacion
FROM pelicula
NATURAL JOIN clasificacion
ORDER BY titulo;


-- 4. Peliculas de 100 minutos o mas,
--    de la mas larga a la mas corta
SELECT titulo, duracion_min
FROM pelicula
WHERE duracion_min >= 100
ORDER BY duracion_min DESC;


-- 5. Clientes nacidos despues del año 2000
--    del mas joven al mayor
SELECT nombre_cliente, fecha_nacimiento
FROM cliente
WHERE fecha_nacimiento > TO_DATE('2000-01-01', 'YYYY-MM-DD')
ORDER BY fecha_nacimiento;


-- 6. Cada pelicula con el nombre de su genero
SELECT titulo, nombre_genero
FROM pelicula p
JOIN genero g ON g.id_genero = p.id_genero
ORDER BY nombre_genero;


-- 7. Cantidad de ventas y dinero recaudado por sucursal
SELECT nombre_sucursal,
       COUNT(*) AS num_ventas,
       SUM(total) AS total_recaudado
FROM venta v
JOIN sucursal s ON s.id_sucursal = v.id_sucursal
GROUP BY nombre_sucursal;


-- 8. Peliculas que tienen 2 o mas funciones programadas
SELECT titulo,
       COUNT(*) AS num_funciones
FROM funcion f
JOIN pelicula p ON p.id_pelicula = f.id_pelicula
GROUP BY titulo
HAVING COUNT(*) >= 2;


-- 9. Funciones con su sala y capacidad
SELECT id_funcion,
       fecha,
       hora_inicio,
       nombre_sala,
       capacidad_asientos
FROM funcion
NATURAL JOIN sala
ORDER BY fecha, hora_inicio;


-- 10. Resumen de ventas y clientes
SELECT COUNT(*) AS total_ventas,
       COUNT(DISTINCT id_cliente) AS clientes_que_compraron,
       MAX(total) AS venta_mayor,
       ROUND(AVG(total)) AS venta_promedio
FROM venta;


-- 11. Resumen general de boletos
SELECT COUNT(*) AS total_boletos,
       SUM(precio) AS total_ingresos,
       ROUND(AVG(precio)) AS precio_promedio,
       MIN(precio) AS precio_minimo,
       MAX(precio) AS precio_maximo
FROM boleto;


-- 12. Ventas con cliente y metodo de pago
SELECT v.id_venta,
       v.fecha_venta,
       c.nombre_cliente,
       m.nombre_metodo,
       v.total
FROM venta v
JOIN cliente c USING (id_cliente)
JOIN metodo_pago m USING (id_metodo_pago)
ORDER BY v.id_venta;


-- 13. Plantilla de cuadre de caja:
--     cada sucursal con cada metodo de pago
SELECT su.nombre_sucursal,
       m.nombre_metodo
FROM sucursal su
CROSS JOIN metodo_pago m
ORDER BY su.nombre_sucursal, m.nombre_metodo;


-- 14. Peliculas para mayores de 15 años
SELECT titulo,
       nombre_clasificacion,
       duracion_min
FROM pelicula
NATURAL JOIN clasificacion
WHERE edad_minima >= 15
ORDER BY duracion_min DESC;


-- 15. Clientes con 2 o mas compras
--     ¿Quienes compran mas?
SELECT nombre_cliente,
       COUNT(*) AS compras,
       SUM(total) AS gastado
FROM venta
JOIN cliente USING (id_cliente)
GROUP BY id_cliente, nombre_cliente
HAVING COUNT(*) >= 2
ORDER BY compras DESC, gastado DESC;

--Subconsultas:
-- 1. Peliculas con tres o mas funciones programadas
SELECT p.id_pelicula,
       p.titulo,
       p.duracion_min,
       p.id_genero
FROM pelicula p
WHERE p.id_pelicula IN (
    SELECT f.id_pelicula
    FROM funcion f
    GROUP BY f.id_pelicula
    HAVING COUNT(f.id_funcion) >= 3
)
ORDER BY p.titulo;

-- 2. Metodos de pago utilizados en cinco o mas ventas
SELECT m.id_metodo_pago,
       m.nombre_metodo,
       m.descripcion
FROM metodo_pago m
WHERE m.id_metodo_pago IN (
    SELECT v.id_metodo_pago
    FROM venta v
    GROUP BY v.id_metodo_pago
    HAVING COUNT(v.id_venta) >= 5
)
ORDER BY m.nombre_metodo;

-- 3. Empleados que han procesado cinco o mas ventas
SELECT e.id_empleado,
       e.nombre_empleado,
       e.cargo,
       e.id_sucursal
FROM empleado e
WHERE e.id_empleado IN (
    SELECT v.id_empleado
    FROM venta v
    GROUP BY v.id_empleado
    HAVING COUNT(v.id_venta) >= 5
)
ORDER BY e.id_sucursal,
         e.nombre_empleado;
         
-- 4. Funciones con boletos vendidos
SELECT f.id_funcion,
       f.fecha,
       f.hora_inicio,
       p.titulo,
       s.nombre_sala
FROM funcion f
JOIN pelicula p
  ON p.id_pelicula = f.id_pelicula
JOIN sala s
  ON s.id_sala = f.id_sala
WHERE f.id_funcion IN (
    SELECT b.id_funcion
    FROM boleto b
    GROUP BY b.id_funcion
    HAVING COUNT(b.id_boleto) >= 1
)
ORDER BY f.fecha,
         f.hora_inicio;
         
-- 5. Funciones con asistencia superior al promedio general
SELECT x.id_funcion,
       x.fecha,
       x.hora_inicio,
       x.titulo,
       x.nombre_sala,
       x.capacidad_asientos,
       x.boletos_vendidos,
       ROUND(
           x.boletos_vendidos * 100 / x.capacidad_asientos,
           2
       ) AS porcentaje_ocupacion
FROM (
    SELECT f.id_funcion,
           f.fecha,
           f.hora_inicio,
           p.titulo,
           s.nombre_sala,
           s.capacidad_asientos,
           COUNT(b.id_boleto) AS boletos_vendidos
    FROM funcion f
    JOIN pelicula p
      ON p.id_pelicula = f.id_pelicula
    JOIN sala s
      ON s.id_sala = f.id_sala
    LEFT JOIN boleto b
      ON b.id_funcion = f.id_funcion
    GROUP BY f.id_funcion,
             f.fecha,
             f.hora_inicio,
             p.titulo,
             s.nombre_sala,
             s.capacidad_asientos
) x
WHERE x.boletos_vendidos > (
    SELECT AVG(y.boletos_vendidos)
    FROM (
        SELECT f2.id_funcion,
               COUNT(b2.id_boleto) AS boletos_vendidos
        FROM funcion f2
        LEFT JOIN boleto b2
          ON b2.id_funcion = f2.id_funcion
        GROUP BY f2.id_funcion
    ) y
)
ORDER BY x.boletos_vendidos DESC;