-- ============================================
-- CORRECCION DE EDADES - DATOS GENERADOS
-- Reasigna ventas cuyos clientes no cumplen la clasificacion.
-- ============================================

UPDATE venta v
SET id_cliente = (
    SELECT MIN(c.id_cliente)
    FROM cliente c
    JOIN boleto b ON b.id_venta = v.id_venta
    JOIN funcion f ON f.id_funcion = b.id_funcion
    JOIN pelicula p ON p.id_pelicula = f.id_pelicula
    JOIN clasificacion cl ON cl.id_clasificacion = p.id_clasificacion
    WHERE TRUNC(MONTHS_BETWEEN(f.fecha, c.fecha_nacimiento) / 12)
          >= cl.edad_minima
)
WHERE EXISTS (
    SELECT 1
    FROM boleto b
    JOIN funcion f ON f.id_funcion = b.id_funcion
    JOIN pelicula p ON p.id_pelicula = f.id_pelicula
    JOIN clasificacion cl ON cl.id_clasificacion = p.id_clasificacion
    JOIN cliente c ON c.id_cliente = v.id_cliente
    WHERE b.id_venta = v.id_venta
      AND TRUNC(MONTHS_BETWEEN(f.fecha, c.fecha_nacimiento) / 12)
          < cl.edad_minima
);

COMMIT;

-- Debe devolver 0 filas.
SELECT DISTINCT c.id_cliente,
       b.id_boleto,
       f.id_funcion,
       p.titulo,
       cl.edad_minima,
       TRUNC(MONTHS_BETWEEN(f.fecha, c.fecha_nacimiento) / 12) AS edad
FROM cliente c
JOIN venta v ON v.id_cliente = c.id_cliente
JOIN boleto b ON b.id_venta = v.id_venta
JOIN funcion f ON f.id_funcion = b.id_funcion
JOIN pelicula p ON p.id_pelicula = f.id_pelicula
JOIN clasificacion cl ON cl.id_clasificacion = p.id_clasificacion
WHERE TRUNC(MONTHS_BETWEEN(f.fecha, c.fecha_nacimiento) / 12) < cl.edad_minima;
