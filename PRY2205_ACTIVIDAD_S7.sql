--CASO 1

DROP SYNONYM trab;
DROP SYNONYM bono_ant;
DROP SYNONYM tic_con;

CREATE SYNONYM trab FOR trabajador;
CREATE SYNONYM bono_ant FOR bono_antiguedad;
CREATE SYNONYM tic_con FOR tickets_concierto;


INSERT INTO detalle_bonificaciones_trabajador (
    num,
    rut,
    nombre_trabajador,
    sueldo_base,
    num_ticket,
    direccion,
    sistema_salud,
    monto,
    bonif_x_ticket,
    simulacion_x_ticket,
    simulacion_antiguedad
)
SELECT
    seq_det_bonif.NEXTVAL,
    t.numrut || '-' || t.dvrut AS rut,
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS nombre_trabajador,
    '$' || TO_CHAR(ROUND(t.sueldo_base), 'FM999G999G999') AS sueldo_base,
    NVL(CAST(tc.nro_ticket AS VARCHAR2(12)), 'No hay info') AS num_ticket,
    t.direccion,
    i.nombre_isapre AS sistema_salud,
    '$' || TO_CHAR(NVL(ROUND(tc.monto_ticket), 0), 'FM999G999G999') AS monto,
    '$' || TO_CHAR(
        CASE
            WHEN tc.monto_ticket IS NULL THEN 0
            WHEN tc.monto_ticket <= 50000 THEN 0
            WHEN tc.monto_ticket <= 100000 THEN ROUND(tc.monto_ticket * 0.05)
            ELSE ROUND(tc.monto_ticket * 0.07)
        END,
        'FM999G999G999'
    ) AS bonif_x_ticket,
    '$' || TO_CHAR(
        ROUND(
            t.sueldo_base +
                CASE
                    WHEN tc.monto_ticket IS NULL THEN 0
                    WHEN tc.monto_ticket <= 50000 THEN 0
                    WHEN tc.monto_ticket <= 100000 THEN ROUND(tc.monto_ticket * 0.05)
                    ELSE ROUND(tc.monto_ticket * 0.07)
                END
        ),
        'FM999G999G999'
    ) AS simulacion_x_ticket,
    '$' || TO_CHAR(
        ROUND(
            t.sueldo_base *
            (
                1 + NVL(
                    (SELECT ba.porcentaje FROM bono_ant ba
                     WHERE
                        ba.limite_inferior <=
                            TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12)
                        AND ba.limite_superior >=
                            TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecing) / 12)
                    ), 0)
            )
        ),
        'FM999G999G999'
    ) AS simulacion_antiguedad
FROM trab t
JOIN isapre i ON t.cod_isapre = i.cod_isapre
LEFT JOIN tic_con tc ON tc.numrut_t = t.numrut
WHERE
    i.porc_descto_isapre > 4
    AND TRUNC(MONTHS_BETWEEN(SYSDATE, t.fecnac) / 12) < 50;
    
COMMIT;
    
SELECT *
FROM detalle_bonificaciones_trabajador
ORDER BY monto DESC, nombre_trabajador ASC;



-- Caso 2 parte 1

DROP SYNONYM trab;
DROP SYNONYM bono_esc;

CREATE SYNONYM trab FOR trabajador;
CREATE SYNONYM bono_esc FOR bono_escolar;

CREATE OR REPLACE VIEW v_aumentos_estudios AS
SELECT
    TO_CHAR(t.numrut, 'FM99G999G999') || '-' || t.dvrut AS rut_trabajador,

    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) AS trabajador,

    b.descrip AS descrip,

    LPAD(b.porc_bono, 6, '0') AS pct_estudios,

    t.sueldo_base AS sueldo_actual,

    ROUND(t.sueldo_base * b.porc_bono / 100) AS aumento,

    TO_CHAR(ROUND(t.sueldo_base * (1 + b.porc_bono / 100)), 'FM$99G999G999') AS sueldo_aumentado

FROM trab t
JOIN bono_esc b ON t.id_escolaridad_t = b.id_escolar
WHERE
    t.id_categoria_t = (
        SELECT id_categoria
        FROM tipo_trabajador
        WHERE UPPER(desc_categoria) = 'CAJERO'
    )
    OR t.numrut IN (
        SELECT af.numrut_t
        FROM asignacion_familiar af
        GROUP BY af.numrut_t
        HAVING COUNT(*) IN (1, 2)
    )
ORDER BY
    b.porc_bono ASC,
    INITCAP(t.nombre || ' ' || t.appaterno || ' ' || t.apmaterno) ASC;
    
SELECT *
FROM v_aumentos_estudios
ORDER BY pct_estudios, trabajador;


---Caso 2 parte 2

DROP INDEX idx_trabajador_apm_2;

CREATE INDEX idx_trabajador_apm_2
  ON trabajador(UPPER(apmaterno));

SELECT * FROM trabajador WHERE UPPER(apmaterno) = 'CASTILLO';

EXPLAIN PLAN FOR
SELECT * FROM trabajador WHERE UPPER(apmaterno) = 'CASTILLO';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);