/* =========================================================
   PRY2205 – EXP 3 – SEMANA 8 

   Este script contiene el desarrollo de los Casos 2 y 3.
   El Caso 1 (creación del esquema y carga de datos) fue
   ejecutado previamente con el script entregado por el docente.
   ========================================================= */


/* =========================================================
   CASO 2 – CONTROL DE STOCK DE LIBROS

   En este caso se crea una tabla que permite revisar el
   estado del stock de libros, considerando cuántos
   ejemplares existen, cuántos están prestados y cuántos
   se encuentran disponibles.
   ========================================================= */

CREATE TABLE CONTROL_STOCK_LIBROS AS
SELECT
    l.libroid                              AS ID_LIBRO,
    l.nombre_libro                         AS NOMBRE_LIBRO,

    -- Total de ejemplares registrados por libro
    COUNT(e.ejemplarid)                    AS TOTAL_EJEMPLARES,

    -- Ejemplares que actualmente están en préstamo
    SUM(
        CASE
            WHEN p.prestamoid IS NOT NULL THEN 1
            ELSE 0
        END
    )                                      AS EJEMPLARES_PRESTAMO,

    -- Ejemplares disponibles para préstamo
    COUNT(e.ejemplarid)
    - SUM(
        CASE
            WHEN p.prestamoid IS NOT NULL THEN 1
            ELSE 0
        END
      )                                    AS EJEMPLARES_DISPONIBLES,

    -- Porcentaje de ejemplares prestados
    ROUND(
        (
            SUM(
                CASE
                    WHEN p.prestamoid IS NOT NULL THEN 1
                    ELSE 0
                END
            )
            / NULLIF(COUNT(e.ejemplarid), 0)
        ) * 100
    )                                      AS PORC_PRESTAMO,

    -- Indicador simple para identificar stock crítico
    CASE
        WHEN (
            COUNT(e.ejemplarid)
            - SUM(
                CASE
                    WHEN p.prestamoid IS NOT NULL THEN 1
                    ELSE 0
                END
              )
        ) > 2 THEN 'S'
        ELSE 'N'
    END                                    AS IND_STOCK_CRITICO

FROM PUB_LIBRO l
JOIN PUB_EJEMPLAR e
  ON e.libroid = l.libroid

LEFT JOIN PUB_PRESTAMO p
  ON p.libroid    = e.libroid
 AND p.ejemplarid = e.ejemplarid
 AND p.empleadoid IN (150, 180, 190)
 AND EXTRACT(YEAR FROM p.fecha_inicio) = EXTRACT(YEAR FROM SYSDATE) - 2

GROUP BY
    l.libroid,
    l.nombre_libro

ORDER BY
    l.libroid;


-- Validación rápida del Caso 2
SELECT COUNT(*) AS TOTAL_REGISTROS
FROM CONTROL_STOCK_LIBROS;


/* =========================================================
   CASO 3 – VISTA DE MULTAS POR PRÉSTAMO

   En este caso se crea una vista que permite identificar
   préstamos con atraso, mostrando información clara del
   alumno, libro, carrera y la rebaja de multa asociada.
   ========================================================= */

CREATE OR REPLACE VIEW ADMIN.V_MULTAS_PRESTAMO AS
SELECT
    p.prestamoid                          AS ID_PRESTAMO,

    -- Información del alumno
    a.alumnoid                            AS ID_ALUMNO,
    a.nombre || ' ' || a.apaterno || ' ' || a.amaterno
                                          AS NOMBRE_ALUMNO,

    -- Información del libro
    l.libroid                             AS ID_LIBRO,
    l.nombre_libro                        AS NOMBRE_LIBRO,

    -- Carrera del alumno
    c.descripcion                         AS CARRERA,

    -- Fechas asociadas al préstamo
    p.fecha_inicio,
    p.fecha_termino,
    p.fecha_entrega,

    -- Indica si existe atraso en la devolución
    CASE
        WHEN p.fecha_entrega IS NOT NULL
         AND p.fecha_entrega > p.fecha_termino
        THEN 'SI'
        ELSE 'NO'
    END                                   AS ATRASO,

    -- Cantidad de días de atraso
    CASE
        WHEN p.fecha_entrega IS NOT NULL
         AND p.fecha_entrega > p.fecha_termino
        THEN (p.fecha_entrega - p.fecha_termino)
        ELSE 0
    END                                   AS DIAS_ATRASO,

    -- Porcentaje de rebaja de multa según carrera
    NVL(rm.porc_rebaja_multa, 0)           AS PORC_REBAJA_MULTA

FROM PUB_PRESTAMO p
JOIN PUB_ALUMNO a
  ON a.alumnoid = p.alumnoid
JOIN PUB_LIBRO l
  ON l.libroid = p.libroid
JOIN PUB_CARRERA c
  ON c.carreraid = a.carreraid
LEFT JOIN PUB_REBAJA_MULTA rm
  ON rm.carreraid = c.carreraid;


-- Validación final del Caso 3
SELECT *
FROM ADMIN.V_MULTAS_PRESTAMO
FETCH FIRST 5 ROWS ONLY;


/* =========================================================
   DIFICULTADES Y SOLUCIÓN

   Durante el desarrollo del trabajo surgieron principalmente
   problemas relacionados con el uso de nombres incorrectos
   de columnas y la forma de ejecutar las consultas en
   SQL Developer.

   Los errores se debieron al asumir nombres de claves foráneas
   que no existían en las tablas, por lo que corregi revisando
   la estructura real mediante la instrucción DESC.

   Una vez encontre los nombres correctos de las columnas
   y ajustados los JOIN y LEFT JOIN, las consultas se ejecutaron
   correctamente y se pudieron crear tanto la tabla de control
   de stock como la vista de multas por préstamo.
   ========================================================= */
