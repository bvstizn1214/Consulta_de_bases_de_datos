------------------------------------------------------------
-- REPORTE DE CONSULTORÍA
-- Muestra profesionales con asesorías FINALIZADAS en banca Y retail.
------------------------------------------------------------

-- CASO 1
SELECT
    p.id_profesional AS "ID",  -- Alias
    -- Concatenación para nombre completo
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS "PROFESIONAL",
    b.nro_asesoria_banca AS "NRO_ASESORIA_BANCA",  -- Cantidad asesorías Banca
    '$' || TO_CHAR(b.monto_total_banca, 'FM999G999G999') AS "MONTO_TOTAL_BANCA",  -- Monto formateado
    r.nro_asesoria_retail AS "NRO_ASESORIA_RETAIL",  -- Cantidad asesorías Retail
    '$' || TO_CHAR(r.monto_total_retail, 'FM999G999G999') AS "MONTO_TOTAL_RETAIL",  -- Monto formateado
    (b.nro_asesoria_banca + r.nro_asesoria_retail) AS "TOTAL_ASESORIAS",  -- Suma total asesorías (operador SET)
    '$' || TO_CHAR((b.monto_total_banca + r.monto_total_retail), 'FM999G999G999') AS "TOTAL_HONORARIOS"
FROM
    -- Subconsulta: datos de asesorías en sector banca
    (
        SELECT
            a.id_profesional,
            COUNT(*) AS nro_asesoria_banca,                 -- Función de grupo
            ROUND(SUM(a.honorario)) AS monto_total_banca    -- Función de grupo + redondeo (función de una fila)
        FROM
            asesoria a
            INNER JOIN empresa e ON a.cod_empresa = e.cod_empresa
        WHERE
            e.cod_sector = 3      -- Restricción: solo banca
            AND a.fin_asesoria IS NOT NULL  -- Debe estar finalizada
        GROUP BY a.id_profesional
    ) b
    INNER JOIN (
        -- Subconsulta: datos de asesorías en sector retail
        SELECT
            a.id_profesional,
            COUNT(*) AS nro_asesoria_retail,
            ROUND(SUM(a.honorario)) AS monto_total_retail
        FROM
            asesoria a
            INNER JOIN empresa e ON a.cod_empresa = e.cod_empresa
        WHERE
            e.cod_sector = 4      -- Restricción: solo retail
            AND a.fin_asesoria IS NOT NULL
        GROUP BY a.id_profesional
    ) r
    -- Operador SET: join entre los resultados de banca y retail
    ON b.id_profesional = r.id_profesional
    -- Join a la tabla profesional para obtener nombre y apellidos
    INNER JOIN profesional p ON p.id_profesional = b.id_profesional
ORDER BY
    p.id_profesional ASC;   -- Cláusula de ordenamiento solicitada
    
-------------------------------------------------------------------------------
-- CASO 2: Resumen y Almacenamiento de Reporte Mensual de Asesorías
-----------------------------------------------------------------------
DROP TABLE REPORTE_MES;   

-- Crea la tabla REPORTE_MES donde se almacenarán los reportes mensuales.
CREATE TABLE REPORTE_MES (
    ID_PROF         NUMBER(10),
    NOMBRE_COMPLETO VARCHAR2(100),
    NOMBRE_PROFESION VARCHAR2(50),
    NOM_COMUNA      VARCHAR2(50),
    NRO_ASESORIAS   NUMBER(5),
    MONTO_TOTAL_HONORARIOS NUMBER(15),
    PROMEDIO_HONORARIO     NUMBER(15),
    HONORARIO_MINIMO       NUMBER(15),
    HONORARIO_MAXIMO       NUMBER(15)
);

COMMIT;

-- Inserta el reporte mensual en la tabla REPORTE_MES
-- usando los datos de las asesorías finalizadas en abril del año pasado.
INSERT INTO REPORTE_MES (
    ID_PROF,
    NOMBRE_COMPLETO,
    NOMBRE_PROFESION,
    NOM_COMUNA,
    NRO_ASESORIAS,
    MONTO_TOTAL_HONORARIOS,
    PROMEDIO_HONORARIO,
    HONORARIO_MINIMO,
    HONORARIO_MAXIMO
)
SELECT
    p.id_profesional AS ID_PROF,  --Alias
    
     -- Concatenación: apellido paterno, apellido materno y nombre
    p.appaterno || ' ' || p.apmaterno || ' ' || p.nombre AS NOMBRE_COMPLETO,
    f.nombre_profesion AS NOMBRE_PROFESION,
    c.nom_comuna AS NOM_COMUNA,
    COUNT(a.honorario) AS NRO_ASESORIAS, --Total asesoris
    ROUND(SUM(a.honorario)) AS MONTO_TOTAL_HONORARIOS, -- Ttal honorarios redondeado
    ROUND(AVG(a.honorario)) AS PROMEDIO_HONORARIO, --Prmedio honorario redondeado
    ROUND(MIN(a.honorario)) AS HONORARIO_MINIMO, -- Mínimo honorario redondead
    ROUND(MAX(a.honorario)) AS HONORARIO_MAXIMO -- Maximo honrario redondeado
FROM
    asesoria a
    INNER JOIN profesional p ON a.id_profesional = p.id_profesional
    INNER JOIN profesion f   ON p.cod_profesion = f.cod_profesion
    INNER JOIN comuna c      ON p.cod_comuna = c.cod_comuna
WHERE
    a.fin_asesoria IS NOT NULL -- Solo assorias finalizadas
    AND EXTRACT(YEAR FROM a.fin_asesoria) = EXTRACT(YEAR FROM SYSDATE) - 1 -- Año pasado
    AND EXTRACT(MONTH FROM a.fin_asesoria) = 4 --(Abril)
GROUP BY
    p.id_profesional,
    p.appaterno, p.apmaterno, p.nombre,
    f.nombre_profesion,
    c.nom_comuna
ORDER BY
    p.id_profesional ASC;

COMMIT;

SELECT * FROM REPORTE_MES;


-- CASO 3 
-------------------------------------------------------------
-- REPORTE ANTES DE LA ACTUALIZACIÓN 
-------------------------------------------------------------
SELECT
    p.ID_PROFESIONAL,
    p.NUMRUN_PROF,
    NVL(SUM(a.HONORARIO), 0) AS HONORARIO_MARZO, -- Total honorarios marzo año anterior
    p.SUELDO -- -- Sueldo actual antes de actualizar
FROM
    PROFESIONAL p
LEFT JOIN ASESORIA a
    ON p.ID_PROFESIONAL = a.ID_PROFESIONAL
    AND EXTRACT(MONTH FROM a.FIN_ASESORIA) = 3 --(marzo)
    AND EXTRACT(YEAR FROM a.FIN_ASESORIA) = EXTRACT(YEAR FROM SYSDATE) - 1 -- Año anterior
GROUP BY
    p.ID_PROFESIONAL,
    p.NUMRUN_PROF,
    p.SUELDO
ORDER BY
    p.ID_PROFESIONAL;
-------------------------------------------------------------
-- ACTUALIZACIÓN DE SUELDO
-------------------------------------------------------------
UPDATE PROFESIONAL p
SET SUELDO = SUELDO * (
    CASE
     -- Si los honorarios son >= $1.000.000, incrementa sueldo en 15%
        WHEN (
            SELECT NVL(SUM(a.HONORARIO), 0)
            FROM ASESORIA a
            WHERE a.ID_PROFESIONAL = p.ID_PROFESIONAL
              AND EXTRACT(MONTH FROM a.FIN_ASESORIA) = 3
              AND EXTRACT(YEAR FROM a.FIN_ASESORIA) = EXTRACT(YEAR FROM SYSDATE) - 1
        ) >= 1000000 THEN 1.15
        -- Si son > 0 pero < $1.000.000, incrementa en 10%
        WHEN (
            SELECT NVL(SUM(a.HONORARIO), 0)
            FROM ASESORIA a
            WHERE a.ID_PROFESIONAL = p.ID_PROFESIONAL
              AND EXTRACT(MONTH FROM a.FIN_ASESORIA) = 3
              AND EXTRACT(YEAR FROM a.FIN_ASESORIA) = EXTRACT(YEAR FROM SYSDATE) - 1
        ) > 0 THEN 1.10
        -- Si no cumple ninguna condición, sueldo no cambia
        ELSE 1
    END
)
WHERE EXISTS (
    SELECT 1
    FROM ASESORIA a
    WHERE a.ID_PROFESIONAL = p.ID_PROFESIONAL
      AND EXTRACT(MONTH FROM a.FIN_ASESORIA) = 3
      AND EXTRACT(YEAR FROM a.FIN_ASESORIA) = EXTRACT(YEAR FROM SYSDATE) - 1
);
------------------------------------------------------------
-- 3. REPORTE DESPUÉS de modificación
------------------------------------------------------------
COMMIT;

SELECT
    p.ID_PROFESIONAL,
    p.NUMRUN_PROF,
    NVL(SUM(a.HONORARIO), 0) AS HONORARIO_MARZO, -- Total honorarios marzo año anterior
    p.SUELDO  -- Sueldo actualizado
FROM
    PROFESIONAL p
LEFT JOIN ASESORIA a
    ON p.ID_PROFESIONAL = a.ID_PROFESIONAL
    AND EXTRACT(MONTH FROM a.FIN_ASESORIA) = 3
    AND EXTRACT(YEAR FROM a.FIN_ASESORIA) = EXTRACT(YEAR FROM SYSDATE) - 1
GROUP BY
    p.ID_PROFESIONAL,
    p.NUMRUN_PROF,
    p.SUELDO
ORDER BY
    p.ID_PROFESIONAL;