SET allow_suspicious_low_cardinality_types = 1;

-- =========================================================
-- 1. DIMENSIÓN TIEMPO
-- =========================================================

CREATE TABLE anio (
    anio UInt16
)
ENGINE = MergeTree()
ORDER BY (anio)
PRIMARY KEY (anio);


SET allow_suspicious_low_cardinality_types = 1;
CREATE TABLE mes (
    id_mes   UInt32,
    anio     LowCardinality(UInt16),
    desc_mes String
)
ENGINE = MergeTree()
ORDER BY (id_mes)
PRIMARY KEY (id_mes);

CREATE TABLE dia (
    fecha_hora DateTime64(3),
    id_mes     LowCardinality(UInt32)
)
ENGINE = MergeTree()
ORDER BY (fecha_hora)
PRIMARY KEY (fecha_hora);

-- =========================================================
-- 2. DIMENSIÓN PRODUCTO / CUENTA
-- =========================================================

CREATE TABLE tipo_producto (
    id_tipo_producto   UInt32,
    desc_tipo_producto String
)
ENGINE = MergeTree()
ORDER BY (id_tipo_producto)
PRIMARY KEY (id_tipo_producto);

CREATE TABLE producto (
    id_producto        UInt32,
    id_tipo_producto   LowCardinality(UInt32),
    desc_producto      String
)
ENGINE = MergeTree()
ORDER BY (id_producto)
PRIMARY KEY (id_producto);

CREATE TABLE cuenta (
    id_cuenta      UInt32,
    id_producto    LowCardinality(UInt32),
    desc_cuenta    String
)
ENGINE = MergeTree()
ORDER BY (id_cuenta)
PRIMARY KEY (id_cuenta);

-- =========================================================
-- 3. CLIENTE / GRUPO
-- =========================================================

CREATE TABLE grupo (
    id_grupo   UInt32,
    desc_grupo String
)
ENGINE = MergeTree()
ORDER BY (id_grupo)
PRIMARY KEY (id_grupo);

SET allow_suspicious_low_cardinality_types = 1;
CREATE TABLE cliente (
    id_cliente   UInt32,
    id_grupo     LowCardinality(Nullable(UInt32)),
    desc_cliente String
)
ENGINE = MergeTree()
ORDER BY (id_cliente)
PRIMARY KEY (id_cliente);

-- =========================================================
-- 4. DIMENSIÓN CANAL
-- =========================================================

CREATE TABLE tipo_canal (
    id_tipo_canal   UInt32,
    desc_tipo_canal String
)
ENGINE = MergeTree()
ORDER BY (id_tipo_canal)
PRIMARY KEY (id_tipo_canal);

CREATE TABLE canal (
    id_canal      UInt32,
    id_tipo_canal LowCardinality(UInt32),
    desc_canal    String
)
ENGINE = MergeTree()
ORDER BY (id_canal)
PRIMARY KEY (id_canal);

-- =========================================================
-- 5. DIMENSIÓN GEOGRAFÍA
-- =========================================================

CREATE TABLE pais (
    id_pais   UInt32,
    desc_pais String
)
ENGINE = MergeTree()
ORDER BY (id_pais)
PRIMARY KEY (id_pais);

CREATE TABLE estado (
    id_estado   UInt32,
    id_pais     LowCardinality(UInt32),
    desc_estado String
)
ENGINE = MergeTree()
ORDER BY (id_estado)
PRIMARY KEY (id_estado);

CREATE TABLE ciudad (
    id_ciudad   UInt32,
    id_estado   LowCardinality(UInt32),
    desc_ciudad String
)
ENGINE = MergeTree()
ORDER BY (id_ciudad)
PRIMARY KEY (id_ciudad);

-- =========================================================
-- 6. DIMENSIÓN TRANSACCIÓN
-- =========================================================

CREATE TABLE categoria_transaccion (
    id_categoria_transaccion UInt32,
    desc_categoria_trans      String
)
ENGINE = MergeTree()
ORDER BY (id_categoria_transaccion)
PRIMARY KEY (id_categoria_transaccion);

CREATE TABLE tipo_transaccion (
    id_tipo_transaccion      UInt32,
    id_categoria_transaccion LowCardinality(UInt32),
    desc_tipo_transaccion    String
)
ENGINE = MergeTree()
ORDER BY (id_tipo_transaccion)
PRIMARY KEY (id_tipo_transaccion);

-- =========================================================
-- 7. DIMENSIÓN FRAUDE
-- =========================================================

CREATE TABLE tipo_fraude (
    id_tipo_fraude   UInt32,
    desc_tipo_fraude String
)
ENGINE = MergeTree()
ORDER BY (id_tipo_fraude)
PRIMARY KEY (id_tipo_fraude);

CREATE TABLE fraude (
    id_fraude      UInt32,
    id_tipo_fraude LowCardinality(UInt32),
    desc_fraude    String
)
ENGINE = MergeTree()
ORDER BY (id_fraude)
PRIMARY KEY (id_fraude);

-- =========================================================
-- 8. DIMENSIÓN MOTIVO DE RECLAMO
-- =========================================================

CREATE TABLE categoria_motivo (
    id_categoria_motivo   UInt32,
    desc_categoria_motivo String
)
ENGINE = MergeTree()
ORDER BY (id_categoria_motivo)
PRIMARY KEY (id_categoria_motivo);

CREATE TABLE motivo_reclamo (
    id_motivo_reclamo   UInt32,
    id_categoria_motivo LowCardinality(UInt32),
    desc_motivo         String
)
ENGINE = MergeTree()
ORDER BY (id_motivo_reclamo)
PRIMARY KEY (id_motivo_reclamo);

-- =========================================================
-- 9. HECHOS: TRANSACCIONES
-- =========================================================

SET allow_suspicious_low_cardinality_types = 1;

CREATE TABLE hechos_transaccionales (
    fecha_hora          DateTime64(3),
    id_cliente          LowCardinality(UInt32),
    id_cuenta           LowCardinality(UInt32),
    id_canal            LowCardinality(UInt32),
    id_ciudad           LowCardinality(UInt32),
    id_tipo_transaccion LowCardinality(UInt32),
    monto_transaccion   Nullable(Decimal(18, 2)),
    ganancia_generada   Nullable(Decimal(18, 2)),
    saldo_cuenta        Nullable(Decimal(18, 2))
)
ENGINE = MergeTree()
PARTITION BY toDate(fecha_hora)
ORDER BY (id_cliente, id_cuenta, id_ciudad, id_tipo_transaccion, fecha_hora)
PRIMARY KEY (id_cliente, id_cuenta, id_ciudad, id_tipo_transaccion);


-- =========================================================
-- 10. HECHOS: RECLAMOS
-- =========================================================

CREATE TABLE hechos_reclamos (
    fecha_hora            DateTime64(3),
    id_cliente            LowCardinality(UInt32),
    id_cuenta             LowCardinality(UInt32),
    id_canal              LowCardinality(UInt32),
    id_ciudad             LowCardinality(UInt32),
    id_tipo_transaccion   LowCardinality(UInt32),
    id_motivo_reclamo     LowCardinality(UInt32),
    tiempo_resolucion_min Nullable(UInt32),
    estatus_reclamo       LowCardinality(Nullable(String))
)
ENGINE = MergeTree()
PARTITION BY toDate(fecha_hora)
ORDER BY (id_cliente, id_cuenta, id_motivo_reclamo, id_tipo_transaccion, fecha_hora)
PRIMARY KEY (id_cliente, id_cuenta, id_motivo_reclamo, id_tipo_transaccion);


-- =========================================================
-- 11. HECHOS: FRAUDE
-- =========================================================

CREATE TABLE hechos_fraude (
    fecha_hora          DateTime64(3),
    id_cliente          LowCardinality(UInt32),
    id_cuenta           LowCardinality(UInt32),
    id_canal            LowCardinality(UInt32),
    id_ciudad           LowCardinality(UInt32),
    id_tipo_transaccion LowCardinality(UInt32),
    id_fraude           LowCardinality(UInt32),
    monto_fraudulento   Nullable(Decimal(18, 2)),
    estatus_fraude      LowCardinality(Nullable(String))
)
ENGINE = MergeTree()
PARTITION BY toDate(fecha_hora)
ORDER BY (id_cliente, id_cuenta, id_fraude, id_tipo_transaccion, fecha_hora)
PRIMARY KEY (id_cliente, id_cuenta, id_fraude, id_tipo_transaccion);