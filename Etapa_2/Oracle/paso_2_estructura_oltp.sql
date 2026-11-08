-- ============================================
-- PASO 2 - CAMBIOS ESTRUCTURALES MINIMOS DEL OLTP
-- Ejecutar sobre una base CineCol ya existente.
-- No corrige datos de negocio; eso corresponde al Paso 3.
-- ============================================

-- La columna DATE de Oracle conserva fecha y hora; no se cambia su tipo.
-- Las columnas se agregan inicialmente anulables para permitir la migracion.
ALTER TABLE funcion ADD (
    inicio_ts TIMESTAMP,
    fin_ts    TIMESTAMP
);

ALTER TABLE boleto ADD CONSTRAINT uq_boleto_funcion_asiento
    UNIQUE (id_funcion, id_asiento);

ALTER TABLE cliente ADD CONSTRAINT uq_cliente_documento
    UNIQUE (documento);

ALTER TABLE asiento ADD CONSTRAINT uq_asiento_sala_fila_numero
    UNIQUE (id_sala, fila, numero);

-- Construye los instantes a partir de fecha y HH24:MI.
-- La fecha final avanza un dia cuando la funcion cruza medianoche.
UPDATE funcion
SET inicio_ts =
        CAST(fecha AS TIMESTAMP)
        + NUMTODSINTERVAL(
            TO_NUMBER(SUBSTR(hora_inicio, 1, 2)) * 60
            + TO_NUMBER(SUBSTR(hora_inicio, 4, 2)),
            'MINUTE'
        ),
    fin_ts =
        CAST(fecha AS TIMESTAMP)
        + NUMTODSINTERVAL(
            TO_NUMBER(SUBSTR(hora_fin, 1, 2)) * 60
            + TO_NUMBER(SUBSTR(hora_fin, 4, 2))
            + CASE WHEN hora_fin < hora_inicio THEN 1440 ELSE 0 END,
            'MINUTE'
        );

ALTER TABLE funcion MODIFY (
    inicio_ts NOT NULL,
    fin_ts    NOT NULL
);

COMMIT;
