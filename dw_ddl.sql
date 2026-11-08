-- ============================================
-- BLOQUE B - ESQUEMA ESTRELLA CINECOL
-- Ejecutar conectado como CINECOL_DW.
-- Las dimensiones usan SCD tipo 1: se actualiza la foto actual.
-- ============================================

CREATE SEQUENCE seq_dim_tiempo START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_dim_pelicula START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_dim_sala START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_dim_cliente START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_dim_empleado START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_dim_metodo_pago START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_dim_franja START WITH 1 INCREMENT BY 1;

CREATE TABLE dim_tiempo (
    sk_tiempo          NUMBER        NOT NULL,
    fecha              DATE          NOT NULL,
    dia                NUMBER        NOT NULL,
    mes                NUMBER        NOT NULL,
    nombre_mes         VARCHAR2(20)  NOT NULL,
    trimestre           NUMBER        NOT NULL,
    anio               NUMBER        NOT NULL,
    dia_semana         VARCHAR2(20)  NOT NULL,
    es_fin_de_semana   CHAR(1)       NOT NULL,
    CONSTRAINT pk_dim_tiempo PRIMARY KEY (sk_tiempo),
    CONSTRAINT uq_dim_tiempo_fecha UNIQUE (fecha),
    CONSTRAINT ck_dim_tiempo_fin CHECK (es_fin_de_semana IN ('S', 'N'))
);

CREATE TABLE dim_pelicula (
    sk_pelicula        NUMBER        NOT NULL,
    id_pelicula        NUMBER        NOT NULL,
    titulo             VARCHAR2(150),
    duracion_min       NUMBER,
    genero             VARCHAR2(50),
    clasificacion      VARCHAR2(20),
    edad_minima        NUMBER,
    CONSTRAINT pk_dim_pelicula PRIMARY KEY (sk_pelicula),
    CONSTRAINT uq_dim_pelicula_bk UNIQUE (id_pelicula)
);

CREATE TABLE dim_sala (
    sk_sala            NUMBER        NOT NULL,
    id_sala            NUMBER        NOT NULL,
    nombre_sala        VARCHAR2(50),
    capacidad          NUMBER,
    tipo_sala          VARCHAR2(20),
    id_sucursal        NUMBER,
    nombre_sucursal    VARCHAR2(100),
    ciudad             VARCHAR2(80),
    departamento       VARCHAR2(80),
    CONSTRAINT pk_dim_sala PRIMARY KEY (sk_sala),
    CONSTRAINT uq_dim_sala_bk UNIQUE (id_sala)
);

CREATE TABLE dim_cliente (
    sk_cliente         NUMBER        NOT NULL,
    id_cliente         NUMBER        NOT NULL,
    nombre_cliente     VARCHAR2(100),
    documento          VARCHAR2(20),
    rango_edad         VARCHAR2(20),
    CONSTRAINT pk_dim_cliente PRIMARY KEY (sk_cliente),
    CONSTRAINT uq_dim_cliente_bk UNIQUE (id_cliente)
);

CREATE TABLE dim_empleado (
    sk_empleado        NUMBER        NOT NULL,
    id_empleado        NUMBER        NOT NULL,
    nombre_empleado    VARCHAR2(100),
    cargo              VARCHAR2(50),
    id_sucursal        NUMBER,
    nombre_sucursal    VARCHAR2(100),
    CONSTRAINT pk_dim_empleado PRIMARY KEY (sk_empleado),
    CONSTRAINT uq_dim_empleado_bk UNIQUE (id_empleado)
);

CREATE TABLE dim_metodo_pago (
    sk_metodo_pago     NUMBER        NOT NULL,
    id_metodo_pago     NUMBER        NOT NULL,
    nombre_metodo      VARCHAR2(50),
    CONSTRAINT pk_dim_metodo_pago PRIMARY KEY (sk_metodo_pago),
    CONSTRAINT uq_dim_metodo_pago_bk UNIQUE (id_metodo_pago)
);

CREATE TABLE dim_franja (
    sk_franja          NUMBER        NOT NULL,
    franja             VARCHAR2(20)  NOT NULL,
    hora_inicio        VARCHAR2(5)   NOT NULL,
    CONSTRAINT pk_dim_franja PRIMARY KEY (sk_franja),
    CONSTRAINT uq_dim_franja_bk UNIQUE (hora_inicio)
);

CREATE TABLE etl_rechazo_boleto (
    id_rechazo         NUMBER GENERATED ALWAYS AS IDENTITY,
    id_boleto          NUMBER,
    motivo              VARCHAR2(4000) NOT NULL,
    fecha_rechazo      TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT pk_etl_rechazo_boleto PRIMARY KEY (id_rechazo)
);

CREATE TABLE fact_venta_boleto (
    sk_tiempo_funcion  NUMBER        NOT NULL,
    sk_tiempo_venta    NUMBER        NOT NULL,
    sk_pelicula        NUMBER        NOT NULL,
    sk_sala            NUMBER        NOT NULL,
    sk_cliente         NUMBER        NOT NULL,
    sk_empleado        NUMBER        NOT NULL,
    sk_metodo_pago     NUMBER        NOT NULL,
    sk_franja          NUMBER        NOT NULL,
    id_venta           NUMBER        NOT NULL,
    id_funcion         NUMBER        NOT NULL,
    id_boleto          NUMBER        NOT NULL,
    precio             NUMBER(10,2)  NOT NULL,
    cantidad           NUMBER        DEFAULT 1 NOT NULL,
    CONSTRAINT pk_fact_venta_boleto PRIMARY KEY (id_boleto),
    CONSTRAINT ck_fact_cantidad CHECK (cantidad = 1)
);

CREATE TABLE fact_ocupacion_funcion (
    sk_tiempo          NUMBER        NOT NULL,
    sk_pelicula        NUMBER        NOT NULL,
    sk_sala            NUMBER        NOT NULL,
    sk_franja          NUMBER        NOT NULL,
    id_funcion         NUMBER        NOT NULL,
    capacidad          NUMBER        NOT NULL,
    boletos_vendidos   NUMBER        NOT NULL,
    ingresos           NUMBER(12,2)  NOT NULL,
    CONSTRAINT pk_fact_ocupacion PRIMARY KEY (id_funcion),
    CONSTRAINT ck_fact_ocupacion_no_neg CHECK (
        capacidad >= 0 AND boletos_vendidos >= 0 AND ingresos >= 0
    )
);

ALTER TABLE fact_venta_boleto ADD CONSTRAINT fk_fvb_tiempo_funcion
    FOREIGN KEY (sk_tiempo_funcion) REFERENCES dim_tiempo (sk_tiempo);
ALTER TABLE fact_venta_boleto ADD CONSTRAINT fk_fvb_tiempo_venta
    FOREIGN KEY (sk_tiempo_venta) REFERENCES dim_tiempo (sk_tiempo);
ALTER TABLE fact_venta_boleto ADD CONSTRAINT fk_fvb_pelicula
    FOREIGN KEY (sk_pelicula) REFERENCES dim_pelicula (sk_pelicula);
ALTER TABLE fact_venta_boleto ADD CONSTRAINT fk_fvb_sala
    FOREIGN KEY (sk_sala) REFERENCES dim_sala (sk_sala);
ALTER TABLE fact_venta_boleto ADD CONSTRAINT fk_fvb_cliente
    FOREIGN KEY (sk_cliente) REFERENCES dim_cliente (sk_cliente);
ALTER TABLE fact_venta_boleto ADD CONSTRAINT fk_fvb_empleado
    FOREIGN KEY (sk_empleado) REFERENCES dim_empleado (sk_empleado);
ALTER TABLE fact_venta_boleto ADD CONSTRAINT fk_fvb_metodo
    FOREIGN KEY (sk_metodo_pago) REFERENCES dim_metodo_pago (sk_metodo_pago);
ALTER TABLE fact_venta_boleto ADD CONSTRAINT fk_fvb_franja
    FOREIGN KEY (sk_franja) REFERENCES dim_franja (sk_franja);

ALTER TABLE fact_ocupacion_funcion ADD CONSTRAINT fk_fof_tiempo
    FOREIGN KEY (sk_tiempo) REFERENCES dim_tiempo (sk_tiempo);
ALTER TABLE fact_ocupacion_funcion ADD CONSTRAINT fk_fof_pelicula
    FOREIGN KEY (sk_pelicula) REFERENCES dim_pelicula (sk_pelicula);
ALTER TABLE fact_ocupacion_funcion ADD CONSTRAINT fk_fof_sala
    FOREIGN KEY (sk_sala) REFERENCES dim_sala (sk_sala);
ALTER TABLE fact_ocupacion_funcion ADD CONSTRAINT fk_fof_franja
    FOREIGN KEY (sk_franja) REFERENCES dim_franja (sk_franja);

CREATE INDEX ix_fvb_tiempo_funcion ON fact_venta_boleto (sk_tiempo_funcion);
CREATE INDEX ix_fvb_tiempo_venta ON fact_venta_boleto (sk_tiempo_venta);
CREATE INDEX ix_fvb_pelicula ON fact_venta_boleto (sk_pelicula);
CREATE INDEX ix_fvb_sala ON fact_venta_boleto (sk_sala);
CREATE INDEX ix_fvb_cliente ON fact_venta_boleto (sk_cliente);
CREATE INDEX ix_fvb_empleado ON fact_venta_boleto (sk_empleado);
CREATE INDEX ix_fvb_metodo ON fact_venta_boleto (sk_metodo_pago);
CREATE INDEX ix_fvb_franja ON fact_venta_boleto (sk_franja);
CREATE INDEX ix_fof_tiempo ON fact_ocupacion_funcion (sk_tiempo);
CREATE INDEX ix_fof_pelicula ON fact_ocupacion_funcion (sk_pelicula);
CREATE INDEX ix_fof_sala ON fact_ocupacion_funcion (sk_sala);
CREATE INDEX ix_fof_franja ON fact_ocupacion_funcion (sk_franja);

INSERT INTO dim_tiempo (
    sk_tiempo, fecha, dia, mes, nombre_mes, trimestre,
    anio, dia_semana, es_fin_de_semana
) VALUES (
    -1, DATE '1900-01-01', 0, 0, 'No definido', 0,
    0, 'No definido', 'N'
);

INSERT INTO dim_pelicula (sk_pelicula, id_pelicula, titulo)
VALUES (-1, -1, 'No definido');
INSERT INTO dim_sala (sk_sala, id_sala, nombre_sala, tipo_sala)
VALUES (-1, -1, 'No definido', 'No definido');
INSERT INTO dim_cliente (sk_cliente, id_cliente, nombre_cliente, rango_edad)
VALUES (-1, -1, 'No definido', 'No definido');
INSERT INTO dim_empleado (sk_empleado, id_empleado, nombre_empleado)
VALUES (-1, -1, 'No definido');
INSERT INTO dim_metodo_pago (sk_metodo_pago, id_metodo_pago, nombre_metodo)
VALUES (-1, -1, 'No definido');
INSERT INTO dim_franja (sk_franja, franja, hora_inicio)
VALUES (-1, 'No definido', '00:00');

COMMIT;
