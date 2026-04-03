-- CONSULTA 1)
-----------------------------
-- enfocada en identificar clientes de alto valor para ofertas de nuevos productos, estableceremos los siguientes filtros para definir "Alto Valor":
--Alta Ganancia: El cliente debe estar entre el 10% superior en términos de ganancia_total_generada.
--Alta Frecuencia: El cliente debe tener un número de transacciones superior al promedio de todos los clientes.

WITH ClienteMetricas AS (
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
    arrayStringConcat(arraySort(groupArrayDistinct(p.desc_producto)), ', ') AS productos_actuales
FROM
    ClienteMetricas cm
JOIN
    MetricasGlobales mg ON 1=1
JOIN
    hechos_transaccionales ht ON cm.id_cliente = ht.id_cliente
JOIN
    cuenta cu ON ht.id_cuenta = cu.id_cuenta
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
-- CONSULTA 2)
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
--Unir los resultados del desglose (Breakdown) con los totales (MesesTop5)

WITH MesesTop5 AS (
    -- 1. Calcular el total de transacciones por cada mes (YYYYMM)
    SELECT
        toYYYYMM(ht.fecha_hora) AS id_mes,
        m.desc_mes,
        COUNT(ht.fecha_hora) AS total_transacciones_mes
    FROM
        hechos_transaccionales ht
    JOIN
        mes m ON toYYYYMM(ht.fecha_hora) = m.id_mes
    GROUP BY
        id_mes, m.desc_mes
    ORDER BY
        total_transacciones_mes DESC
    LIMIT 5
),
BreakdownPorMes AS (
    -- 2. Calcular el desglose por tipo de transacción SÓLO para esos 5 meses
    SELECT
        m.id_mes,
        m.desc_mes,
        tt.desc_tipo_transaccion,
        COUNT(ht.fecha_hora) AS total_transacciones_tipo
    FROM
        hechos_transaccionales ht
    JOIN
        mes m ON toYYYYMM(ht.fecha_hora) = m.id_mes
    JOIN
        tipo_transaccion tt ON ht.id_tipo_transaccion = tt.id_tipo_transaccion
    WHERE
        m.id_mes IN (SELECT id_mes FROM MesesTop5)
    GROUP BY
        m.desc_mes, m.id_mes, tt.desc_tipo_transaccion
)
-- 3. Unir los resultados del desglose (Breakdown) con los totales (MesesTop5)
SELECT
    b.desc_mes,
    b.desc_tipo_transaccion,
    b.total_transacciones_tipo
FROM
    BreakdownPorMes b
JOIN
    MesesTop5 t5 ON b.id_mes = t5.id_mes
ORDER BY
    t5.total_transacciones_mes DESC,
    b.total_transacciones_tipo DESC;






-----------------------------
-- CONSULTA 4)
-----------------------------
-- La consulta te proporciona una lista de los mejores 50 clientes, clasificados por ganancia, que ya tienen una relación transaccional con el producto más exitoso 
--del banco. Estos clientes son el público ideal para recibir una oferta de un producto nuevo o mejorado, ya que han demostrado ser rentables y tienen afinidad con 
--la oferta de productos más exitosa.

WITH ProductoRentabilidad AS (
    -- 1. Identificar el Producto más rentable
    SELECT
        p_cte.id_producto AS id_producto,
        p_cte.desc_producto AS desc_producto,
        SUM(ht.ganancia_generada) AS ganancia_total_producto
    FROM
        hechos_transaccionales ht
    JOIN
        cuenta cu ON ht.id_cuenta = cu.id_cuenta
    JOIN
        producto p_cte ON cu.id_producto = p_cte.id_producto
    GROUP BY
        p_cte.id_producto, p_cte.desc_producto
    ORDER BY
        ganancia_total_producto DESC
    LIMIT 1
)
-- 2. Identificar a los clientes más valiosos
SELECT
    cl.id_cliente,
    cl.desc_cliente,
    g.desc_grupo,
    COUNT(DISTINCT p.id_producto) AS num_productos_diferentes,
    SUM(ht.ganancia_generada) AS ganancia_generada_por_cliente
FROM
    cliente cl
JOIN
    hechos_transaccionales ht ON cl.id_cliente = ht.id_cliente
JOIN
    cuenta cu ON ht.id_cuenta = cu.id_cuenta
JOIN
    producto p ON cu.id_producto = p.id_producto
JOIN
    grupo g ON cl.id_grupo = g.id_grupo
JOIN
    ProductoRentabilidad pr ON p.id_producto = pr.id_producto
    
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
    COUNT(DISTINCT ht.fecha_hora) AS total_transacciones,
    AVG(ht.saldo_cuenta) AS saldo_promedio,
    COUNT(hr.fecha_hora) AS total_reclamos,
    COUNT(DISTINCT p.id_producto) AS productos_diferentes,
    MAX(ht.fecha_hora) AS ultima_transaccion,
    
    CASE
        WHEN COUNT(hr.fecha_hora) >= 2 THEN 'ALTO_RIESGO_RECLAMOS'
        
        WHEN dateDiff('day', MAX(ht.fecha_hora), now64(3)) > 90 THEN 'RIESGO_INACTIVIDAD'
        
        WHEN AVG(ht.saldo_cuenta) < 1000 THEN 'RIESGO_SALDO_BAJO'
        WHEN COUNT(ht.fecha_hora) > 0 THEN 'BAJO_RIESGO'
        ELSE 'RIESGO_ABANDONO_TOTAL'
    END AS indicador_riesgo
FROM
    cliente c
LEFT JOIN
    grupo g ON c.id_grupo = g.id_grupo
LEFT JOIN
    hechos_transaccionales ht ON c.id_cliente = ht.id_cliente
LEFT JOIN
    hechos_reclamos hr ON c.id_cliente = hr.id_cliente
LEFT JOIN
    cuenta cu ON ht.id_cuenta = cu.id_cuenta
LEFT JOIN
    producto p ON cu.id_producto = p.id_producto
GROUP BY
    c.id_cliente, c.desc_cliente, g.desc_grupo
ORDER BY
    total_reclamos DESC, total_transacciones ASC, ultima_transaccion ASC;







-----------------------------
-- CONSULTA 6)
-----------------------------
-- Esta consulta identifica qué canales son más usados y cuáles generan mayor ganancia.
-- Consulta 6.1: Canales más rentables
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
    ganancia_total_canal DESC;

-- Consulta 6.2: Top 3 de canales por grupo de cliente
WITH UsoPorGrupo AS (
    SELECT
        g.desc_grupo,
        ca.desc_canal,
        COUNT(ht.fecha_hora) AS total_transacciones,
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
    SELECT
        id_cliente,
        AVG(monto_transaccion) AS avg_monto_cliente,
        stddevSamp(monto_transaccion) AS std_monto_cliente
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
    ht.monto_transaccion > (mc.avg_monto_cliente + (3 * mc.std_monto_cliente))
    AND 
    mc.std_monto_cliente IS NOT NULL
ORDER BY
    ht.monto_transaccion DESC
LIMIT 100;