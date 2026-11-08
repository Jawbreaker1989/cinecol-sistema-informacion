-- ============================================
-- MIGRACION - SEPARAR DIM_SUCURSAL DE DIM_SALA
-- Ejecutar conectado como CINECOL_DW sobre el DW ya creado.
-- Luego ejecutar etl_cinecol_dw.sql para recargar las facts.
-- ============================================

CREATE SEQUENCE seq_dim_sucursal START WITH 1 INCREMENT BY 1;

CREATE TABLE dim_sucursal (
    sk_sucursal        NUMBER        NOT NULL,
    id_sucursal        NUMBER        NOT NULL,
    nombre_sucursal    VARCHAR2(100),
    ciudad             VARCHAR2(80),
    departamento       VARCHAR2(80),
    CONSTRAINT pk_dim_sucursal PRIMARY KEY (sk_sucursal),
    CONSTRAINT uq_dim_sucursal_bk UNIQUE (id_sucursal)
);

INSERT INTO dim_sucursal (
    sk_sucursal, id_sucursal, nombre_sucursal, ciudad, departamento
)
SELECT -1, -1, 'No definido', 'No definido', 'No definido'
FROM dual;

INSERT INTO dim_sucursal (
    sk_sucursal, id_sucursal, nombre_sucursal, ciudad, departamento
)
SELECT seq_dim_sucursal.NEXTVAL,
       su.id_sucursal,
       su.nombre_sucursal,
       ci.nombre_ciudad,
       ci.departamento
FROM CINECOL_R.sucursal su
JOIN CINECOL_R.ciudad ci ON ci.id_ciudad = su.id_ciudad;

ALTER TABLE fact_venta_boleto ADD sk_sucursal NUMBER;
ALTER TABLE fact_ocupacion_funcion ADD sk_sucursal NUMBER;

UPDATE fact_venta_boleto f
SET sk_sucursal = (
    SELECT ds.sk_sucursal
    FROM dim_sucursal ds
    JOIN dim_sala sala ON sala.sk_sala = f.sk_sala
    WHERE ds.id_sucursal = sala.id_sucursal
);

UPDATE fact_ocupacion_funcion f
SET sk_sucursal = (
    SELECT ds.sk_sucursal
    FROM dim_sucursal ds
    JOIN dim_sala sala ON sala.sk_sala = f.sk_sala
    WHERE ds.id_sucursal = sala.id_sucursal
);

UPDATE fact_venta_boleto SET sk_sucursal = -1 WHERE sk_sucursal IS NULL;
UPDATE fact_ocupacion_funcion SET sk_sucursal = -1 WHERE sk_sucursal IS NULL;

ALTER TABLE fact_venta_boleto MODIFY sk_sucursal NOT NULL;
ALTER TABLE fact_ocupacion_funcion MODIFY sk_sucursal NOT NULL;

ALTER TABLE fact_venta_boleto ADD CONSTRAINT fk_fvb_sucursal
    FOREIGN KEY (sk_sucursal) REFERENCES dim_sucursal (sk_sucursal);
ALTER TABLE fact_ocupacion_funcion ADD CONSTRAINT fk_fof_sucursal
    FOREIGN KEY (sk_sucursal) REFERENCES dim_sucursal (sk_sucursal);

CREATE INDEX ix_fvb_sucursal ON fact_venta_boleto (sk_sucursal);
CREATE INDEX ix_fof_sucursal ON fact_ocupacion_funcion (sk_sucursal);

ALTER TABLE dim_sala DROP COLUMN id_sucursal;
ALTER TABLE dim_sala DROP COLUMN nombre_sucursal;
ALTER TABLE dim_sala DROP COLUMN ciudad;
ALTER TABLE dim_sala DROP COLUMN departamento;

COMMIT;
