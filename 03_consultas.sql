/* =====================================================================
   Script 3 de 3: consultas de ejemplo.
   Se pueden ejecutar de una en una (selecciona y pulsa F5 en SSMS).
   ===================================================================== */

USE InvestigacionesCientificas;
GO

-- 1. Ver el contenido de todas las tablas
SELECT * FROM Instituciones;
SELECT * FROM AreasTematicas;
SELECT * FROM Autores;
SELECT * FROM Investigaciones;
SELECT * FROM Autor_Investigacion;
SELECT * FROM Publicaciones;
SELECT * FROM PermisosUsuario;

-- 2. Investigaciones con su institución y área temática (JOIN)
SELECT i.id_investigacion, i.titulo, inst.nombre AS institucion, a.nombre AS area, i.fecha
FROM Investigaciones i
JOIN Instituciones inst ON i.id_institucion = inst.id_institucion
JOIN AreasTematicas a   ON i.id_area = a.id_area
ORDER BY i.fecha DESC;

-- 3. Autores de cada investigación
SELECT inv.titulo AS investigacion, aut.nombre AS autor, aut.email
FROM Investigaciones inv
JOIN Autor_Investigacion ai ON inv.id_investigacion = ai.id_investigacion
JOIN Autores aut            ON ai.id_autor = aut.id_autor
ORDER BY inv.titulo, aut.nombre;

-- 4. Publicaciones y la investigación de la que salen
SELECT pub.id_publicacion, pub.titulo AS publicacion, pub.fecha_publicacion, inv.titulo AS investigacion
FROM Publicaciones pub
JOIN Investigaciones inv ON pub.id_investigacion = inv.id_investigacion
ORDER BY pub.fecha_publicacion;

-- 5. Investigaciones de un autor específico
DECLARE @autor VARCHAR(100) = 'Alex Urrego';
SELECT aut.nombre AS autor, inv.titulo, inv.fecha
FROM Autores aut
JOIN Autor_Investigacion ai ON aut.id_autor = ai.id_autor
JOIN Investigaciones inv    ON ai.id_investigacion = inv.id_investigacion
WHERE aut.nombre = @autor;

-- 6. Cantidad de investigaciones por área (GROUP BY + LEFT JOIN: incluye áreas sin investigaciones)
SELECT a.nombre AS area, COUNT(i.id_investigacion) AS total_investigaciones
FROM AreasTematicas a
LEFT JOIN Investigaciones i ON a.id_area = i.id_area
GROUP BY a.nombre
ORDER BY total_investigaciones DESC;

-- 7. Investigaciones con más de un autor (GROUP BY + HAVING)
SELECT inv.titulo, COUNT(ai.id_autor) AS total_autores
FROM Investigaciones inv
JOIN Autor_Investigacion ai ON inv.id_investigacion = ai.id_investigacion
GROUP BY inv.titulo
HAVING COUNT(ai.id_autor) > 1
ORDER BY total_autores DESC;

-- 8. Investigaciones sin publicaciones (LEFT JOIN + IS NULL)
SELECT inv.id_investigacion, inv.titulo
FROM Investigaciones inv
LEFT JOIN Publicaciones pub ON inv.id_investigacion = pub.id_investigacion
WHERE pub.id_publicacion IS NULL;

-- 9. Autor con más investigaciones (subconsulta)
SELECT TOP 1 aut.nombre, COUNT(*) AS total_investigaciones
FROM Autores aut
JOIN Autor_Investigacion ai ON aut.id_autor = ai.id_autor
GROUP BY aut.nombre
ORDER BY COUNT(*) DESC;

-- 10. Vista que resume cada investigación (reutilizable)
GO
CREATE OR ALTER VIEW vw_resumen_investigaciones AS
SELECT i.id_investigacion,
       i.titulo,
       inst.nombre AS institucion,
       a.nombre    AS area,
       i.fecha,
       (SELECT COUNT(*) FROM Autor_Investigacion ai WHERE ai.id_investigacion = i.id_investigacion) AS total_autores,
       (SELECT COUNT(*) FROM Publicaciones p        WHERE p.id_investigacion  = i.id_investigacion) AS total_publicaciones
FROM Investigaciones i
LEFT JOIN Instituciones inst ON i.id_institucion = inst.id_institucion
LEFT JOIN AreasTematicas a   ON i.id_area = a.id_area;
GO

SELECT * FROM vw_resumen_investigaciones ORDER BY fecha DESC;
GO
