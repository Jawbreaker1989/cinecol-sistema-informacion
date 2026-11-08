-- CineCol: script para importar en SQL Developer Data Modeler

CREATE TABLE ciudad (
  id_ciudad       NUMBER        NOT NULL,
  nombre_ciudad   VARCHAR2(80)  NOT NULL,
  departamento    VARCHAR2(80)  NOT NULL,
  CONSTRAINT pk_ciudad PRIMARY KEY (id_ciudad)
);

CREATE TABLE sucursal (
  id_sucursal      NUMBER        NOT NULL,
  nombre_sucursal  VARCHAR2(100) NOT NULL,
  direccion        VARCHAR2(150) NOT NULL,
  telefono         VARCHAR2(20),
  id_ciudad        NUMBER        NOT NULL,
  CONSTRAINT pk_sucursal PRIMARY KEY (id_sucursal)
);

CREATE TABLE sala (
  id_sala             NUMBER       NOT NULL,
  nombre_sala         VARCHAR2(50) NOT NULL,
  capacidad_asientos  NUMBER       NOT NULL,
  id_sucursal         NUMBER       NOT NULL,
  CONSTRAINT pk_sala PRIMARY KEY (id_sala)
);

CREATE TABLE asiento (
  id_asiento  NUMBER       NOT NULL,
  fila        VARCHAR2(5)  NOT NULL,
  numero      NUMBER       NOT NULL,
  id_sala     NUMBER       NOT NULL,
  CONSTRAINT pk_asiento PRIMARY KEY (id_asiento),
  CONSTRAINT uq_asiento_sala_fila_numero UNIQUE (id_sala, fila, numero)
);

CREATE TABLE empleado (
  id_empleado      NUMBER        NOT NULL,
  nombre_empleado  VARCHAR2(100) NOT NULL,
  cargo            VARCHAR2(50)  NOT NULL,
  id_sucursal      NUMBER        NOT NULL,
  CONSTRAINT pk_empleado PRIMARY KEY (id_empleado)
);

CREATE TABLE cliente (
  id_cliente        NUMBER        NOT NULL,
  nombre_cliente    VARCHAR2(100) NOT NULL,
  documento         VARCHAR2(20)  NOT NULL,
  celular           VARCHAR2(20),
  fecha_nacimiento  DATE          NOT NULL,
  CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
  CONSTRAINT uq_cliente_documento UNIQUE (documento)
);

CREATE TABLE genero (
  id_genero      NUMBER        NOT NULL,
  nombre_genero  VARCHAR2(50)  NOT NULL,
  descripcion    VARCHAR2(150),
  CONSTRAINT pk_genero PRIMARY KEY (id_genero)
);

CREATE TABLE clasificacion (
  id_clasificacion      NUMBER        NOT NULL,
  nombre_clasificacion  VARCHAR2(20)  NOT NULL,
  edad_minima           NUMBER        NOT NULL,
  descripcion           VARCHAR2(150),
  CONSTRAINT pk_clasificacion PRIMARY KEY (id_clasificacion)
);

CREATE TABLE pelicula (
  id_pelicula       NUMBER        NOT NULL,
  titulo            VARCHAR2(150) NOT NULL,
  duracion_min      NUMBER        NOT NULL,
  sinopsis          VARCHAR2(300),
  id_genero         NUMBER        NOT NULL,
  id_clasificacion  NUMBER        NOT NULL,
  CONSTRAINT pk_pelicula PRIMARY KEY (id_pelicula)
);

CREATE TABLE funcion (
  id_funcion   NUMBER       NOT NULL,
  fecha        DATE         NOT NULL,
  hora_inicio  VARCHAR2(5)  NOT NULL,
  hora_fin     VARCHAR2(5)  NOT NULL,
  inicio_ts    TIMESTAMP,
  fin_ts       TIMESTAMP,
  id_pelicula  NUMBER       NOT NULL,
  id_sala      NUMBER       NOT NULL,
  CONSTRAINT pk_funcion PRIMARY KEY (id_funcion)
);

CREATE TABLE metodo_pago (
  id_metodo_pago  NUMBER        NOT NULL,
  nombre_metodo   VARCHAR2(50)  NOT NULL,
  descripcion     VARCHAR2(150),
  CONSTRAINT pk_metodo_pago PRIMARY KEY (id_metodo_pago)
);

CREATE TABLE venta (
  id_venta        NUMBER         NOT NULL,
  fecha_venta     DATE           NOT NULL,
  total           NUMBER(10,2)   NOT NULL,
  id_cliente      NUMBER         NOT NULL,
  id_empleado     NUMBER         NOT NULL,
  id_metodo_pago  NUMBER         NOT NULL,
  id_sucursal     NUMBER         NOT NULL,
  CONSTRAINT pk_venta PRIMARY KEY (id_venta)
);

CREATE TABLE boleto (
  id_boleto       NUMBER         NOT NULL,
  numero_asiento  NUMBER         NOT NULL,
  precio          NUMBER(10,2)   NOT NULL,
  id_venta        NUMBER         NOT NULL,
  id_funcion      NUMBER         NOT NULL,
  id_asiento      NUMBER         NOT NULL,
  CONSTRAINT pk_boleto PRIMARY KEY (id_boleto),
  CONSTRAINT uq_boleto_funcion_asiento UNIQUE (id_funcion, id_asiento)
);

-- Llaves foraneas (el nombre sera el de la relacion en el MER)
ALTER TABLE sucursal ADD CONSTRAINT ubica      FOREIGN KEY (id_ciudad)        REFERENCES ciudad (id_ciudad);
ALTER TABLE sala     ADD CONSTRAINT administra FOREIGN KEY (id_sucursal)      REFERENCES sucursal (id_sucursal);
ALTER TABLE asiento  ADD CONSTRAINT contiene   FOREIGN KEY (id_sala)          REFERENCES sala (id_sala);
ALTER TABLE empleado ADD CONSTRAINT adscribe   FOREIGN KEY (id_sucursal)      REFERENCES sucursal (id_sucursal);
ALTER TABLE pelicula ADD CONSTRAINT clasifica  FOREIGN KEY (id_genero)        REFERENCES genero (id_genero);
ALTER TABLE pelicula ADD CONSTRAINT restringe  FOREIGN KEY (id_clasificacion) REFERENCES clasificacion (id_clasificacion);
ALTER TABLE funcion  ADD CONSTRAINT programa   FOREIGN KEY (id_pelicula)      REFERENCES pelicula (id_pelicula);
ALTER TABLE funcion  ADD CONSTRAINT aloja      FOREIGN KEY (id_sala)          REFERENCES sala (id_sala);
ALTER TABLE venta    ADD CONSTRAINT realiza    FOREIGN KEY (id_cliente)       REFERENCES cliente (id_cliente);
ALTER TABLE venta    ADD CONSTRAINT procesa    FOREIGN KEY (id_empleado)      REFERENCES empleado (id_empleado);
ALTER TABLE venta    ADD CONSTRAINT liquida    FOREIGN KEY (id_metodo_pago)   REFERENCES metodo_pago (id_metodo_pago);
ALTER TABLE venta    ADD CONSTRAINT venta_sucursal FOREIGN KEY (id_sucursal)  REFERENCES sucursal (id_sucursal);
ALTER TABLE boleto   ADD CONSTRAINT genera     FOREIGN KEY (id_venta)         REFERENCES venta (id_venta);
ALTER TABLE boleto   ADD CONSTRAINT habilita   FOREIGN KEY (id_funcion)       REFERENCES funcion (id_funcion);
ALTER TABLE boleto   ADD CONSTRAINT asigna     FOREIGN KEY (id_asiento)       REFERENCES asiento (id_asiento);
