-----------------------------
-- CONSULTA 1) DICE
-----------------------------


-- enfocada en identificar clientes de alto valor para ofertas de nuevos productos, estableceremos los siguientes filtros para definir "Alto Valor":

--Alta Ganancia: El cliente debe estar entre el 10% superior en términos de ganancia_total_generada.

--Alta Frecuencia: El cliente debe tener un número de transacciones superior al promedio de todos los clientes.

WITH ClienteMetricas AS (
    --Calcula las métricas clave por cliente
    SELECT
        c.id_cliente,
        c.desc_cliente,
        SUM(ht.ganancia_generada) AS ganancia_total_generada,
        COUNT(ht.fecha_hora) AS total_transacciones,
        NTILE(10) OVER (ORDER BY SUM(ht.ganancia_generada) DESC) AS ganancia_decil_rank
    FROM
        cliente c
    JOIN
        hechos_transaccionales ht ON c.id_cliente = ht.id_cliente
    GROUP BY
        c.id_cliente, c.desc_cliente
),
MetricasGlobales AS (
    -- Calcula el promedio de transacciones de todos los clientes
    SELECT
        AVG(total_transacciones) AS promedio_transacciones_global
    FROM
        ClienteMetricas
)
SELECT
    cm.id_cliente,
    cm.desc_cliente,
    cm.ganancia_total_generada,
    cm.total_transacciones,
    cm.ganancia_decil_rank,
    -- ⚠️ CLAVE: La unión para productos debe pasar por hechos_transaccionales (ht) o cuenta (cu)
    STRING_AGG(DISTINCT p.desc_producto, ', ' ORDER BY p.desc_producto) AS productos_actuales
FROM
    ClienteMetricas cm
JOIN
    MetricasGlobales mg ON 1=1
JOIN
    hechos_transaccionales ht ON cm.id_cliente = ht.id_cliente -- Unión correcta: Cliente -> Hechos
JOIN
    cuenta cu ON ht.id_cuenta = cu.id_cuenta                   -- Unión correcta: Hechos -> Cuenta
JOIN
    producto p ON cu.id_producto = p.id_producto
WHERE
    cm.ganancia_decil_rank = 1
    AND
    cm.total_transacciones > mg.promedio_transacciones_global
GROUP BY
    cm.id_cliente, cm.desc_cliente, cm.ganancia_total_generada, cm.total_transacciones, cm.ganancia_decil_rank
ORDER BY
    cm.ganancia_total_generada DESC;



-----------------------------
-- CONSULTA 2) DRILL UP
-----------------------------

-- El patrón de comportamiento de sus clientes para poder ofrecer nuevas cuentas.
-- Analiza el uso actual de productos, el volumen transaccional y la rentabilidad por cliente.

SELECT
    tt.desc_tipo_transaccion,
    SUM(ht.ganancia_generada) AS ganancia_total
FROM
    hechos_transaccionales ht
JOIN
    tipo_transaccion tt ON ht.id_tipo_transaccion = tt.id_tipo_transaccion
GROUP BY
    tt.desc_tipo_transaccion
ORDER BY
    ganancia_total DESC
LIMIT 10;


-----------------------------
-- CONSULTA 3)
-----------------------------

--identifica los 5 valores de id_mes únicos que tuvieron la mayor cantidad absoluta de transacciones, sin considerar el tipo de transacción.

--Consulta Final: Luego, se usa WHERE m.id_mes IN (SELECT id_mes FROM MesesTop5) para filtrar todos los registros de hechos_transaccionales y mostrar solo el desglose por desc_tipo_transaccion para esos 5 meses de alto volumen.

--Ordenamiento: Se utiliza un subquery en el ORDER BY para asegurar que los meses se muestren en el orden de su volumen total descendente.

WITH MesesTop5 AS (
    -- 1. Calcular el total de transacciones por cada mes (YYYYMM)
    SELECT
        d.id_mes,
        m.desc_mes,
        COUNT(ht.fecha_hora) AS total_transacciones_mes
    FROM
        hechos_transaccionales ht
    JOIN
        dia d ON ht.fecha_hora = d.fecha_hora
    JOIN
        mes m ON d.id_mes = m.id_mes
    GROUP BY
        d.id_mes, m.desc_mes
    ORDER BY
        total_transacciones_mes DESC
    LIMIT 5 -- Selecciona los 5 meses con mayor volumen total
)
-- 2. Mostrar el detalle del tipo de transacción para esos 5 meses
SELECT
    m.desc_mes,
    tt.desc_tipo_transaccion,
    COUNT(ht.fecha_hora) AS total_transacciones
FROM
    hechos_transaccionales ht
JOIN
    dia d ON ht.fecha_hora = d.fecha_hora
JOIN
    mes m ON d.id_mes = m.id_mes
JOIN
    tipo_transaccion tt ON ht.id_tipo_transaccion = tt.id_tipo_transaccion
WHERE
    m.id_mes IN (SELECT id_mes FROM MesesTop5) -- Filtra solo los meses Top 5
GROUP BY
    m.desc_mes, m.id_mes, tt.desc_tipo_transaccion
ORDER BY
    (SELECT total_transacciones_mes FROM MesesTop5 WHERE id_mes = m.id_mes) DESC, -- Ordena por el volumen total del mes
    total_transacciones DESC; -- Luego, por volumen de tipo de transacción dentro del mes



-----------------------------
-- CONSULTA 4) SLICE
-----------------------------

-- La consulta te proporciona una lista de los mejores 50 clientes, clasificados por ganancia, que ya tienen una relación transaccional con el producto más exitoso 
--del banco. Estos clientes son el público ideal para recibir una oferta de un producto nuevo o mejorado, ya que han demostrado ser rentables y tienen afinidad con 
--la oferta de productos más exitosa.

WITH ProductoRentabilidad AS (
    -- 1. Identificar el Producto más rentable por ganancia total
    SELECT
        p.id_producto,
        p.desc_producto,
        SUM(ht.ganancia_generada) AS ganancia_total_producto
    FROM
        hechos_transaccionales ht
    JOIN
        cuenta cu ON ht.id_cuenta = cu.id_cuenta
    JOIN
        producto p ON cu.id_producto = p.id_producto
    GROUP BY
        p.id_producto, p.desc_producto
    ORDER BY
        ganancia_total_producto DESC
    LIMIT 1
)
-- 2. Identificar a los clientes más valiosos que usaron ese producto
SELECT
    cl.id_cliente,
    cl.desc_cliente,
    g.desc_grupo,
    -- Contamos el número de cuentas/productos únicos que el cliente tiene en transacciones
    COUNT(DISTINCT p.id_producto) AS num_productos_diferentes,
    SUM(ht.ganancia_generada) AS ganancia_generada_por_cliente
FROM
    cliente cl
JOIN
    hechos_transaccionales ht ON cl.id_cliente = ht.id_cliente  -- ⬅️ RELACIÓN CORRECTA: Cliente -> Hechos
JOIN
    cuenta cu ON ht.id_cuenta = cu.id_cuenta                    -- Hechos -> Cuenta
JOIN
    producto p ON cu.id_producto = p.id_producto
JOIN
    grupo g ON cl.id_grupo = g.id_grupo
WHERE
    -- Filtra por el ID del producto que resultó ser el más rentable
    p.id_producto = (SELECT id_producto FROM ProductoRentabilidad)
GROUP BY
    cl.id_cliente, cl.desc_cliente, g.desc_grupo
ORDER BY
    ganancia_generada_por_cliente DESC
LIMIT 50;



-----------------------------
-- CONSULTA 5)
-----------------------------

--La consulta tiene como finalidad primordial identificar clientes con alto riesgo de abandono o retención mediante 
--el análisis consolidado de su actividad histórica en el banco. Utiliza un LEFT JOIN para incluir a todos los clientes, 
--incluso aquellos sin transacciones recientes o reclamos, y agrega métricas clave como el saldo_promedio, el total_transacciones, 
--el total_reclamos y la ultima_transaccion. Finalmente, aplica una lógica CASE para asignar un indicador_riesgo categórico 
--(ALTO_RIESGO_RECLAMOS, RIESGO_INACTIVIDAD, RIESGO_SALDO_BAJO, RIESGO_ABANDONO_TOTAL) basado en umbrales de negocio 
--(ej., más de 90 días sin actividad o dos o más reclamos), permitiendo al equipo de gestión de clientes priorizar a aquellos usuarios 
--que requieren una intervención inmediata para mitigar la posible pérdida de ingresos y relación comercial.




SELECT
    c.id_cliente,
    c.desc_cliente,
    g.desc_grupo,
    -- Métricas de Actividad y Saldo
    COUNT(DISTINCT ht.fecha_hora) AS total_transacciones,
    AVG(ht.saldo_cuenta) AS saldo_promedio,
    -- Métricas de Reclamos y Productos
    COUNT(hr.fecha_hora) AS total_reclamos,
    -- ⚠️ CORRECCIÓN AQUÍ: Contamos los productos distintos ÚNICAMENTE A TRAVÉS de las transacciones del cliente (ht)
    COUNT(DISTINCT p.id_producto) AS productos_diferentes,
    MAX(ht.fecha_hora) AS ultima_transaccion,
    
    -- Indicador de Riesgo (La lógica de riesgo se aplica solo si hay transacciones)
    CASE
        -- Alto Riesgo por Reclamos (si tiene 2 o más reclamos)
        WHEN COUNT(hr.fecha_hora) >= 2 THEN 'ALTO_RIESGO_RECLAMOS'
        -- Riesgo por Inactividad (si la última transacción fue hace más de 90 días)
        WHEN (CURRENT_TIMESTAMP - MAX(ht.fecha_hora)) > INTERVAL '90 days' THEN 'RIESGO_INACTIVIDAD'
        -- Riesgo por Saldo Bajo (si el saldo promedio transaccional es bajo)
        WHEN AVG(ht.saldo_cuenta) < 1000 THEN 'RIESGO_SALDO_BAJO'
        -- Bajo Riesgo (Si hay actividad, pero sin los problemas anteriores)
        WHEN COUNT(ht.fecha_hora) > 0 THEN 'BAJO_RIESGO'
        -- Abandono (No hay transacciones registradas)
        ELSE 'RIESGO_ABANDONO_TOTAL'
    END AS indicador_riesgo
FROM
    cliente c
LEFT JOIN
    grupo g ON c.id_grupo = g.id_grupo
LEFT JOIN
    hechos_transaccionales ht ON c.id_cliente = ht.id_cliente -- Unión clave
LEFT JOIN
    hechos_reclamos hr ON c.id_cliente = hr.id_cliente
LEFT JOIN
    cuenta cu ON ht.id_cuenta = cu.id_cuenta                  -- ✅ CORREGIDO: Unido vía ht
LEFT JOIN
    producto p ON cu.id_producto = p.id_producto              -- Unido vía cu
GROUP BY
    c.id_cliente, c.desc_cliente, g.desc_grupo
ORDER BY
    total_reclamos DESC, total_transacciones ASC, ultima_transaccion ASC;


    
-----------------------------
-- CONSULTA 6)
-----------------------------

-- Esta consulta identifica qué canales son más usados y cuáles generan mayor ganancia.

SELECT
    ca.desc_canal,
    tc.desc_tipo_canal,
    COUNT(ht.fecha_hora) AS total_transacciones_canal,
    SUM(ht.monto_transaccion) AS monto_total_canal,
    SUM(ht.ganancia_generada) AS ganancia_total_canal
FROM
    hechos_transaccionales ht
JOIN
    canal ca ON ht.id_canal = ca.id_canal
JOIN
    tipo_canal tc ON ca.id_tipo_canal = tc.id_tipo_canal
GROUP BY
    ca.desc_canal, tc.desc_tipo_canal
ORDER BY
    ganancia_total_canal DESC; -- Prioriza los canales más rentables


-- Esta consulta muestra qué canales específicos utiliza cada cliente, agrupándolos para un perfilado individual

WITH UsoPorGrupo AS (
    -- 1. Calcula el total de transacciones por cada combinación (Grupo, Canal)
    SELECT
        g.desc_grupo,
        ca.desc_canal,
        COUNT(ht.fecha_hora) AS total_transacciones,
        -- 2. Clasifica los canales DENTRO de cada grupo de clientes
        ROW_NUMBER() OVER (
            PARTITION BY g.id_grupo
            ORDER BY COUNT(ht.fecha_hora) DESC
        ) as canal_rank
    FROM
        hechos_transaccionales ht
    JOIN
        cliente c ON ht.id_cliente = c.id_cliente
    JOIN
        grupo g ON c.id_grupo = g.id_grupo
    JOIN
        canal ca ON ht.id_canal = ca.id_canal
    GROUP BY
        g.id_grupo, g.desc_grupo, ca.desc_canal
)
-- Consulta para Comparar Canales por Grupo de Clientes (Top 3)
SELECT
    desc_grupo,
    desc_canal,
    total_transacciones,
    canal_rank
FROM
    UsoPorGrupo
WHERE
    canal_rank <= 3
ORDER BY
    desc_grupo, canal_rank;




-----------------------------
-- CONSULTA 7)
-----------------------------


--Para detectar transacciones inusuales o anómalas, utilizaremos un enfoque estadístico básico: identificar transacciones cuyo monto se desvía 
--significativamente del comportamiento histórico del cliente (por ejemplo, más de 3 desviaciones estándar por encima del monto promedio transaccionado 
--por ese mismo cliente).

WITH MetricasCliente AS (
    -- 1. Calcula el promedio (AVG) y la desviación estándar (STDDEV)
    --    de los montos de transacción para cada cliente.
    SELECT
        id_cliente,
        AVG(monto_transaccion) AS avg_monto_cliente,
        STDDEV(monto_transaccion) AS std_monto_cliente
    FROM
        hechos_transaccionales
    GROUP BY
        id_cliente
)
SELECT
    ht.fecha_hora,
    c.desc_cliente,
    tt.desc_tipo_transaccion,
    ca.desc_canal,
    ht.monto_transaccion,
    mc.avg_monto_cliente,
    mc.std_monto_cliente
FROM
    hechos_transaccionales ht
JOIN
    MetricasCliente mc ON ht.id_cliente = mc.id_cliente
JOIN
    cliente c ON ht.id_cliente = c.id_cliente
JOIN
    tipo_transaccion tt ON ht.id_tipo_transaccion = tt.id_tipo_transaccion
JOIN
    canal ca ON ht.id_canal = ca.id_canal
WHERE
    -- 2. Filtra transacciones cuyo monto supera el promedio MÁS tres veces la desviación estándar.
    --    Esto marca la transacción como una anomalía estadística.
    ht.monto_transaccion > (mc.avg_monto_cliente + (3 * mc.std_monto_cliente))
    AND 
    -- 3. Excluye casos donde solo hay un registro o el STDDEV es nulo.
    mc.std_monto_cliente IS NOT NULL
ORDER BY
    ht.monto_transaccion DESC; -- Muestra las 100 transacciones más anómalas


-----------------------------
-- CONSULTA 7B) Transacciones normales
-----------------------------

WITH MetricasCliente AS (
    SELECT
        id_cliente,
        AVG(monto_transaccion) AS avg_monto_cliente,
        STDDEV(monto_transaccion) AS std_monto_cliente
    FROM
        hechos_transaccionales
    GROUP BY
        id_cliente
)
SELECT
    ht.fecha_hora,
    c.desc_cliente,
    tt.desc_tipo_transaccion,
    ca.desc_canal,
    ht.monto_transaccion,
    mc.avg_monto_cliente,
    mc.std_monto_cliente
FROM
    hechos_transaccionales ht
JOIN
    MetricasCliente mc ON ht.id_cliente = mc.id_cliente
JOIN
    cliente c ON ht.id_cliente = c.id_cliente
JOIN
    tipo_transaccion tt ON ht.id_tipo_transaccion = tt.id_tipo_transaccion
JOIN
    canal ca ON ht.id_canal = ca.id_canal
WHERE
    (
        -- aquí van las “normales”: monto menor o igual al umbral
        ht.monto_transaccion <= (mc.avg_monto_cliente + (3 * mc.std_monto_cliente))
        -- y también consideramos los clientes sin varianza (stddev nulo),
        -- porque ahí no tiene sentido marcar anomalías
        OR mc.std_monto_cliente IS NULL
    )
ORDER BY
    ht.fecha_hora DESC
LIMIT 961;



------------------------------------------------------
-- CONSULTA 7 Modificada (Anomalía de Monto Y Hora)
------------------------------------------------------

-- Detecta transacciones que se desvían 3+ stddev del promedio del cliente
-- Y que ADEMÁS ocurren en un horario anómalo (1:00 AM - 5:59 AM).

WITH MetricasCliente AS (
    -- 1. Calcula el promedio (AVG) y la desviación estándar (STDDEV)
    --    de los montos de transacción para cada cliente. (Sin cambios)
    SELECT
        id_cliente,
        AVG(monto_transaccion) AS avg_monto_cliente,
        STDDEV(monto_transaccion) AS std_monto_cliente
    FROM
        hechos_transaccionales
    GROUP BY
        id_cliente
)
SELECT
    ht.fecha_hora,
    c.desc_cliente,
    tt.desc_tipo_transaccion,
    ca.desc_canal,
    ht.monto_transaccion,
    mc.avg_monto_cliente,
    mc.std_monto_cliente
FROM
    hechos_transaccionales ht
JOIN
    MetricasCliente mc ON ht.id_cliente = mc.id_cliente
JOIN
    cliente c ON ht.id_cliente = c.id_cliente
JOIN
    tipo_transaccion tt ON ht.id_tipo_transaccion = tt.id_tipo_transaccion
JOIN
    canal ca ON ht.id_canal = ca.id_canal
WHERE
    -- 2. Filtra transacciones cuyo monto supera el promedio MÁS tres veces la desviación estándar.
    ht.monto_transaccion > (mc.avg_monto_cliente + (3 * mc.std_monto_cliente))
    AND 
    -- 3. Excluye casos donde solo hay un registro o el STDDEV es nulo.
    mc.std_monto_cliente IS NOT NULL
    AND
    -- 4. NUEVA CONDICIÓN: Filtra por horario anómalo (1:00 AM a 5:59 AM)
    --    EXTRACT(HOUR FROM ...) obtiene la hora (0-23) de la fecha.
    EXTRACT(HOUR FROM ht.fecha_hora) BETWEEN 1 AND 5
ORDER BY
    ht.monto_transaccion DESC;


--------------------------------------------------------------------------
-- CONSULTA OPUESTA (Transacciones Normales en Monto O en Hora)
--------------------------------------------------------------------------

-- Detecta transacciones que son normales en monto, O que ocurren
-- en un horario normal, O que no tenían desviación estándar (STDDEV).
-- Es decir, todas las transacciones que la consulta original EXCLUYÓ.

WITH MetricasCliente AS (
    -- 1. (Sin cambios)
    SELECT
        id_cliente,
        AVG(monto_transaccion) AS avg_monto_cliente,
        STDDEV(monto_transaccion) AS std_monto_cliente
    FROM
        hechos_transaccionales
    GROUP BY
        id_cliente
)
SELECT
    ht.fecha_hora,
    c.desc_cliente,
    tt.desc_tipo_transaccion,
    ca.desc_canal,
    ht.monto_transaccion,
    mc.avg_monto_cliente,
    mc.std_monto_cliente
FROM
    hechos_transaccionales ht
JOIN
    MetricasCliente mc ON ht.id_cliente = mc.id_cliente
JOIN
    cliente c ON ht.id_cliente = c.id_cliente
JOIN
    tipo_transaccion tt ON ht.id_tipo_transaccion = tt.id_tipo_transaccion
JOIN
    canal ca ON ht.id_canal = ca.id_canal
WHERE
    -- 2. Condición OPUESTA 1: El monto es NORMAL (menor o igual al límite).
    ht.monto_transaccion <= (mc.avg_monto_cliente + (3 * mc.std_monto_cliente))
    
    -- 3. Condición OPUESTA 2: O el STDDEV es NULO (casos que la original excluía).
    OR mc.std_monto_cliente IS NULL
    
    -- 4. Condición OPUESTA 3: O la HORA es NORMAL (fuera del rango 1-5 AM).
    OR EXTRACT(HOUR FROM ht.fecha_hora) NOT BETWEEN 1 AND 5
    
ORDER BY
    ht.fecha_hora ASC
LIMIT 600;



--Consulta pivot
SELECT
    c.desc_canal,

    SUM(CASE WHEN tt.desc_tipo_transaccion = 'Transferencia Interna'
             THEN ht.monto_transaccion ELSE 0 END) AS monto_transferencia_interna,

    SUM(CASE WHEN tt.desc_tipo_transaccion = 'SPEI Salida'
             THEN ht.monto_transaccion ELSE 0 END) AS monto_spei_salida,

    SUM(CASE WHEN tt.desc_tipo_transaccion = 'Pago Teléfono'
             THEN ht.monto_transaccion ELSE 0 END) AS monto_pago_telefono,

    SUM(CASE WHEN tt.desc_tipo_transaccion = 'Pago Luz'
             THEN ht.monto_transaccion ELSE 0 END) AS monto_pago_luz,

    SUM(CASE WHEN tt.desc_tipo_transaccion = 'Retiro Cajero'
             THEN ht.monto_transaccion ELSE 0 END) AS monto_retiro_cajero,

    SUM(CASE WHEN tt.desc_tipo_transaccion = 'Compra Online'
             THEN ht.monto_transaccion ELSE 0 END) AS monto_compra_online,

    SUM(CASE WHEN tt.desc_tipo_transaccion = 'Compra TPV'
             THEN ht.monto_transaccion ELSE 0 END) AS monto_compra_tpv,

    SUM(CASE WHEN tt.desc_tipo_transaccion = 'Pago Internet'
             THEN ht.monto_transaccion ELSE 0 END) AS monto_pago_internet,

    SUM(CASE WHEN tt.desc_tipo_transaccion = 'SPEI Entrada'
             THEN ht.monto_transaccion ELSE 0 END) AS monto_spei_entrada

FROM hechos_transaccionales ht
JOIN canal c
  ON ht.id_canal = c.id_canal
JOIN tipo_transaccion tt
  ON ht.id_tipo_transaccion = tt.id_tipo_transaccion
JOIN dia d
  ON ht.fecha_hora = d.fecha_hora
JOIN mes m
  ON d.id_mes = m.id_mes
JOIN anio a
  ON m.anio = a.anio
WHERE a.anio = 2024   -- si quieres todos los años, quita esta línea
GROUP BY
    c.desc_canal
ORDER BY
    c.desc_canal;


--consulta drill down
SELECT
    a.anio,
    m.desc_mes,
    SUM(ht.monto_transaccion) AS monto_total
FROM hechos_transaccionales ht
JOIN dia d   ON ht.fecha_hora = d.fecha_hora
JOIN mes m   ON d.id_mes      = m.id_mes
JOIN anio a  ON m.anio        = a.anio
GROUP BY
    a.anio,
    m.id_mes,
    m.desc_mes
ORDER BY
    a.anio,
    m.id_mes;