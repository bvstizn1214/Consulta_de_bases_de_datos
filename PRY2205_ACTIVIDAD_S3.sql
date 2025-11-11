--CASO 1

ACCEPT RENTA_MINIMA NUMBER PROMPT 'Ingrese renta mínima (solo números, sin $ ni separadores): '
ACCEPT RENTA_MAXIMA NUMBER PROMPT 'Ingrese renta máxima (solo números, sin $ ni separadores): '

SELECT
    SUBSTR(TO_CHAR(numrut_cli), 1, LENGTH(TO_CHAR(numrut_cli)) - 6) || '.' ||
    SUBSTR(TO_CHAR(numrut_cli), LENGTH(TO_CHAR(numrut_cli)) - 5, 3) || '.' ||
    SUBSTR(TO_CHAR(numrut_cli), LENGTH(TO_CHAR(numrut_cli)) - 2, 3) || '-' ||
    dvrut_cli AS "RUT Cliente",
    INITCAP(LOWER(nombre_cli || ' ' || appaterno_cli || ' ' || apmaterno_cli)) AS "Nombre Completo Cliente",
    NVL(direccion_cli, '') AS "Dirección Cliente",
    '$' || TO_CHAR(ROUND(NVL(renta_cli,0)), 'FM999G999G999') AS "Renta Cliente",
    TO_CHAR(NVL(celular_cli,0)) AS "Celular Cliente",
    CASE
        WHEN renta_cli > 500000 THEN 'TRAMO 1'
        WHEN renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
        WHEN renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
        ELSE 'TRAMO 4'
    END AS "Tramo Renta Cliente",
    COUNT(*) OVER (
        PARTITION BY CASE
            WHEN renta_cli > 500000 THEN 'TRAMO 1'
            WHEN renta_cli BETWEEN 400000 AND 500000 THEN 'TRAMO 2'
            WHEN renta_cli BETWEEN 200000 AND 399999 THEN 'TRAMO 3'
            ELSE 'TRAMO 4'
        END
    ) AS "Clientes en Tramo"
FROM cliente
WHERE
    renta_cli BETWEEN &RENTA_MINIMA AND &RENTA_MAXIMA
    AND celular_cli IS NOT NULL
ORDER BY
    LOWER(nombre_cli),
    LOWER(appaterno_cli),
    LOWER(apmaterno_cli);
    
    
-- CASO 2
ACCEPT SUELDO_PROMEDIO_MINIMO NUMBER PROMPT 'Ingrese sueldo promedio mínimo (solo números): '

SELECT
    ID_CATEGORIA_EMP                                              AS "CODIGO_CATEGORIA",
    CASE NVL(ID_CATEGORIA_EMP,0)
        WHEN 1 THEN 'Gerente'
        WHEN 2 THEN 'Supervisor'
        WHEN 3 THEN 'Ejecutivo de Arriendo'
        WHEN 4 THEN 'Auxiliar'
        ELSE 'Sin Categoría'
    END                                                             AS "DESCRIPCION_CATEGORIA",
    COUNT(*)                                                         AS "CANTIDAD_EMPLEADOS",
    CASE NVL(ID_SUCURSAL,0)
        WHEN 10 THEN 'Sucursal Las Condes'
        WHEN 20 THEN 'Sucursal Santiago Centro'
        WHEN 30 THEN 'Sucursal Providencia'
        WHEN 40 THEN 'Sucursal Vitacura'
        ELSE 'Sucursal Desconocida'
    END                                                             AS "SUCURSAL",
    '$' || TO_CHAR(ROUND(AVG(SUELDO_EMP),0), 'FM999G999G999')       AS "SUELDO_PROMEDIO",
    TO_CHAR(SYSDATE, 'DD-MM-YYYY')                                   AS "FECHA_INFORME"
FROM EMPLEADO
GROUP BY
    ID_CATEGORIA_EMP,
    ID_SUCURSAL
HAVING
    AVG(SUELDO_EMP) >= &SUELDO_PROMEDIO_MINIMO
ORDER BY
    AVG(SUELDO_EMP) DESC;
    
    
-- CASO 3 
    
SELECT
    P.ID_TIPO_PROPIEDAD                                          AS "CODIGO_TIPO",
    UPPER(NVL(T.DESC_TIPO_PROPIEDAD,'OTRO'))                     AS "DESCRIPCION_TIPO",
    COUNT(*)                                                     AS "TOTAL_PROPIEDADES",
    '$' || TO_CHAR(ROUND(AVG(NVL(P.VALOR_ARRIENDO,0))), 'FM999G999G999') AS "PROMEDIO_ARRIENDO",
    REPLACE(TO_CHAR(ROUND(AVG(NVL(P.SUPERFICIE,0)),2), 'FM999G999G990D99'), '.', ',') AS "PROMEDIO_SUPERFICIE",
    '$' || TO_CHAR(
            ROUND(
                AVG(
                    CASE WHEN NVL(P.SUPERFICIE,0) > 0 THEN P.VALOR_ARRIENDO / P.SUPERFICIE
                    ELSE NULL END
                )
            ,0)
        , 'FM999G999G999')                                       AS "VALOR_ARRIENDO_M2",
    CASE
        WHEN ROUND(AVG(CASE WHEN NVL(P.SUPERFICIE,0) > 0 THEN P.VALOR_ARRIENDO / P.SUPERFICIE END),0) < 5000 THEN 'Económico'
        WHEN ROUND(AVG(CASE WHEN NVL(P.SUPERFICIE,0) > 0 THEN P.VALOR_ARRIENDO / P.SUPERFICIE END),0) BETWEEN 5000 AND 10000 THEN 'Medio'
        ELSE 'Alto'
    END                                                          AS "CLASIFICACION",
    MAX(TO_CHAR(SYSDATE, 'DD-MM-YYYY'))                          AS "FECHA_INFORME"
FROM PROPIEDAD P
JOIN TIPO_PROPIEDAD T
    ON P.ID_TIPO_PROPIEDAD = T.ID_TIPO_PROPIEDAD
GROUP BY
    P.ID_TIPO_PROPIEDAD,
    T.DESC_TIPO_PROPIEDAD
HAVING
    AVG(CASE WHEN NVL(P.SUPERFICIE,0) > 0 THEN P.VALOR_ARRIENDO / P.SUPERFICIE END) > 1000
ORDER BY
    AVG(CASE WHEN NVL(P.SUPERFICIE,0) > 0 THEN P.VALOR_ARRIENDO / P.SUPERFICIE END) DESC;