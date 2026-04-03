
-- =========================================================
-- 1. DIMENSIÓN TIEMPO
-- =========================================================

CREATE TABLE anio (
    anio INT PRIMARY KEY
);

CREATE TABLE mes (
    id_mes   INT PRIMARY KEY,
    anio     INT NOT NULL,
    desc_mes VARCHAR(20) NOT NULL,
    CONSTRAINT fk_mes_anio
        FOREIGN KEY (anio) REFERENCES anio(anio)
);

CREATE TABLE dia (
    fecha_hora TIMESTAMP PRIMARY KEY,  -- fecha + hora
    id_mes     INT NOT NULL,
    CONSTRAINT fk_dia_mes
        FOREIGN KEY (id_mes) REFERENCES mes(id_mes)
);

-- =========================================================
-- 2. DIMENSIÓN PRODUCTO / CUENTA
-- =========================================================

CREATE TABLE tipo_producto (
    id_tipo_producto   INT PRIMARY KEY,
    desc_tipo_producto VARCHAR(100) NOT NULL
);

CREATE TABLE producto (
    id_producto        INT PRIMARY KEY,
    id_tipo_producto   INT NOT NULL,
    desc_producto      VARCHAR(100) NOT NULL,
    CONSTRAINT fk_producto_tipo
        FOREIGN KEY (id_tipo_producto) REFERENCES tipo_producto(id_tipo_producto)
);

CREATE TABLE cuenta (
    id_cuenta      INT PRIMARY KEY,
    id_producto    INT NOT NULL,
    desc_cuenta    VARCHAR(150) NOT NULL,
    CONSTRAINT fk_cuenta_producto
        FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
);

-- =========================================================
-- 3. CLIENTE / GRUPO
-- =========================================================

CREATE TABLE grupo (
    id_grupo   INT PRIMARY KEY,
    desc_grupo VARCHAR(100) NOT NULL
);

CREATE TABLE cliente (
    id_cliente   INT PRIMARY KEY,
    id_grupo     INT,
    desc_cliente VARCHAR(150) NOT NULL,
    CONSTRAINT fk_cliente_grupo
        FOREIGN KEY (id_grupo) REFERENCES grupo(id_grupo)
);

-- =========================================================
-- 4. DIMENSIÓN CANAL
-- =========================================================

CREATE TABLE tipo_canal (
    id_tipo_canal   INT PRIMARY KEY,
    desc_tipo_canal VARCHAR(100) NOT NULL
);

CREATE TABLE canal (
    id_canal      INT PRIMARY KEY,
    id_tipo_canal INT NOT NULL,
    desc_canal    VARCHAR(100) NOT NULL,
    CONSTRAINT fk_canal_tipo
        FOREIGN KEY (id_tipo_canal) REFERENCES tipo_canal(id_tipo_canal)
);

-- =========================================================
-- 5. DIMENSIÓN GEOGRAFÍA
-- =========================================================

CREATE TABLE pais (
    id_pais   INT PRIMARY KEY,
    desc_pais VARCHAR(100) NOT NULL
);

CREATE TABLE estado (
    id_estado   INT PRIMARY KEY,
    id_pais     INT NOT NULL,
    desc_estado VARCHAR(100) NOT NULL,
    CONSTRAINT fk_estado_pais
        FOREIGN KEY (id_pais) REFERENCES pais(id_pais)
);

CREATE TABLE ciudad (
    id_ciudad   INT PRIMARY KEY,
    id_estado   INT NOT NULL,
    desc_ciudad VARCHAR(100) NOT NULL,
    CONSTRAINT fk_ciudad_estado
        FOREIGN KEY (id_estado) REFERENCES estado(id_estado)
);

-- =========================================================
-- 6. DIMENSIÓN TRANSACCIÓN
-- =========================================================

CREATE TABLE categoria_transaccion (
    id_categoria_transaccion INT PRIMARY KEY,
    desc_categoria_trans      VARCHAR(100) NOT NULL
);

CREATE TABLE tipo_transaccion (
    id_tipo_transaccion      INT PRIMARY KEY,
    id_categoria_transaccion INT NOT NULL,
    desc_tipo_transaccion    VARCHAR(100) NOT NULL,
    CONSTRAINT fk_tipo_categoria
        FOREIGN KEY (id_categoria_transaccion)
        REFERENCES categoria_transaccion(id_categoria_transaccion)
);

-- =========================================================
-- 7. DIMENSIÓN FRAUDE
-- =========================================================

CREATE TABLE tipo_fraude (
    id_tipo_fraude   INT PRIMARY KEY,
    desc_tipo_fraude VARCHAR(150) NOT NULL
);

CREATE TABLE fraude (
    id_fraude      INT PRIMARY KEY,
    id_tipo_fraude INT NOT NULL,
    desc_fraude    VARCHAR(150) NOT NULL,
    CONSTRAINT fk_fraude_tipo
        FOREIGN KEY (id_tipo_fraude) REFERENCES tipo_fraude(id_tipo_fraude)
);

-- =========================================================
-- 8. DIMENSIÓN MOTIVO DE RECLAMO
-- =========================================================

CREATE TABLE categoria_motivo (
    id_categoria_motivo   INT PRIMARY KEY,
    desc_categoria_motivo VARCHAR(150) NOT NULL
);

CREATE TABLE motivo_reclamo (
    id_motivo_reclamo   INT PRIMARY KEY,
    id_categoria_motivo INT NOT NULL,
    desc_motivo         VARCHAR(150) NOT NULL,
    CONSTRAINT fk_motivo_categoria
        FOREIGN KEY (id_categoria_motivo)
        REFERENCES categoria_motivo(id_categoria_motivo)
);

-- =========================================================
-- 9. HECHOS: TRANSACCIONES
-- =========================================================

CREATE TABLE hechos_transaccionales (
    fecha_hora          TIMESTAMP NOT NULL,
    id_cliente          INT NOT NULL,
    id_cuenta           INT NOT NULL,
    id_canal            INT NOT NULL,
    id_ciudad           INT NOT NULL,
    id_tipo_transaccion INT NOT NULL,
    monto_transaccion   DECIMAL(18,2),
    ganancia_generada   DECIMAL(18,2),
    saldo_cuenta        DECIMAL(18,2),
    CONSTRAINT pk_hechos_transaccionales
        PRIMARY KEY (fecha_hora, id_cliente, id_cuenta, id_tipo_transaccion),
    CONSTRAINT fk_ht_fecha
        FOREIGN KEY (fecha_hora) REFERENCES dia(fecha_hora),
    CONSTRAINT fk_ht_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    CONSTRAINT fk_ht_cuenta
        FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta),
    CONSTRAINT fk_ht_canal
        FOREIGN KEY (id_canal) REFERENCES canal(id_canal),
    CONSTRAINT fk_ht_ciudad
        FOREIGN KEY (id_ciudad) REFERENCES ciudad(id_ciudad),
    CONSTRAINT fk_ht_tipo_trans
        FOREIGN KEY (id_tipo_transaccion) REFERENCES tipo_transaccion(id_tipo_transaccion)
);

-- =========================================================
-- 10. HECHOS: RECLAMOS
-- =========================================================

CREATE TABLE hechos_reclamos (
    fecha_hora            TIMESTAMP NOT NULL,
    id_cliente            INT NOT NULL,
    id_cuenta             INT NOT NULL,
    id_canal              INT NOT NULL,
    id_ciudad             INT NOT NULL,
    id_tipo_transaccion   INT NOT NULL,
    id_motivo_reclamo     INT NOT NULL,
    tiempo_resolucion_min INT,
    estatus_reclamo       VARCHAR(50),
    CONSTRAINT pk_hechos_reclamos
        PRIMARY KEY (fecha_hora, id_cliente, id_cuenta, id_motivo_reclamo, id_tipo_transaccion),
    CONSTRAINT fk_hr_fecha
        FOREIGN KEY (fecha_hora) REFERENCES dia(fecha_hora),
    CONSTRAINT fk_hr_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    CONSTRAINT fk_hr_cuenta
        FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta),
    CONSTRAINT fk_hr_canal
        FOREIGN KEY (id_canal) REFERENCES canal(id_canal),
    CONSTRAINT fk_hr_ciudad
        FOREIGN KEY (id_ciudad) REFERENCES ciudad(id_ciudad),
    CONSTRAINT fk_hr_motivo
        FOREIGN KEY (id_motivo_reclamo) REFERENCES motivo_reclamo(id_motivo_reclamo),
    CONSTRAINT fk_hr_tipo_trans
        FOREIGN KEY (id_tipo_transaccion) REFERENCES tipo_transaccion(id_tipo_transaccion)
);

-- =========================================================
-- 11. HECHOS: FRAUDE
-- =========================================================

CREATE TABLE hechos_fraude (
    fecha_hora        TIMESTAMP NOT NULL,
    id_cliente        INT NOT NULL,
    id_cuenta         INT NOT NULL,
    id_canal          INT NOT NULL,
    id_ciudad         INT NOT NULL,
    id_tipo_transaccion INT NOT NULL,
    id_fraude         INT NOT NULL,
    monto_fraudulento DECIMAL(18,2),
    estatus_fraude    VARCHAR(50),
    CONSTRAINT pk_hechos_fraude
        PRIMARY KEY (fecha_hora, id_cliente, id_cuenta, id_fraude, id_tipo_transaccion),
    CONSTRAINT fk_hf_fecha
        FOREIGN KEY (fecha_hora) REFERENCES dia(fecha_hora),
    CONSTRAINT fk_hf_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente),
    CONSTRAINT fk_hf_cuenta
        FOREIGN KEY (id_cuenta) REFERENCES cuenta(id_cuenta),
    CONSTRAINT fk_hf_canal
        FOREIGN KEY (id_canal) REFERENCES canal(id_canal),
    CONSTRAINT fk_hf_ciudad
        FOREIGN KEY (id_ciudad) REFERENCES ciudad(id_ciudad),
    CONSTRAINT fk_hf_fraude
        FOREIGN KEY (id_fraude) REFERENCES fraude(id_fraude),
    CONSTRAINT fk_hf_tipo_trans
        FOREIGN KEY (id_tipo_transaccion) REFERENCES tipo_transaccion(id_tipo_transaccion)
);