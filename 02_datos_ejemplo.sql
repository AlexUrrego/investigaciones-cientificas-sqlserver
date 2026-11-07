/* =====================================================================
   Script 2 de 3: datos de ejemplo (inventados).
   Solo inserta si las tablas están vacías, así que no duplica datos.
   ===================================================================== */

USE InvestigacionesCientificas;
GO

IF NOT EXISTS (SELECT 1 FROM Instituciones)
BEGIN
    INSERT INTO Instituciones (nombre, region) VALUES
        ('Instituto de Tecnología Andina', 'Andina'),
        ('Universidad Ejemplo del Caribe', 'Caribe'),
        ('Centro de Investigación del Pacífico', 'Pacífico');

    INSERT INTO AreasTematicas (nombre) VALUES
        ('Inteligencia Artificial'),
        ('Análisis de Datos'),
        ('Bases de Datos'),
        ('Educación y Tecnología');

    INSERT INTO Autores (nombre, email) VALUES
        ('Alex Urrego',  'autor1@example.com'),
        ('María Pérez',  'maria.perez@example.com'),
        ('Carlos Gómez', 'carlos.gomez@example.com'),
        ('Laura Ríos',   'laura.rios@example.com');

    INSERT INTO Investigaciones (titulo, resumen, fecha, id_institucion, id_area, palabras_clave) VALUES
        ('Estudio sobre inteligencia artificial en educación',
         'Analiza modelos de IA aplicados al aprendizaje personalizado.',
         '2025-03-04', 1, 1, 'inteligencia artificial, educación, aprendizaje personalizado'),
        ('Análisis de datos abiertos de temperatura en Colombia',
         'Exploración de series de tiempo de temperatura por ciudad.',
         '2025-05-15', 2, 2, 'datos abiertos, temperatura, Pandas'),
        ('Modelado relacional de investigaciones científicas',
         'Diseño de una base de datos relacional para registrar investigaciones.',
         '2025-06-01', 1, 3, 'SQL Server, modelo relacional'),
        ('Visualización de datos para la toma de decisiones',
         'Uso de gráficas para comunicar resultados de análisis.',
         '2025-07-10', 3, 2, 'visualización, decisiones');

    INSERT INTO Autor_Investigacion (id_autor, id_investigacion) VALUES
        (1, 1), (2, 1), (3, 1),
        (1, 2),
        (1, 3), (4, 3),
        (4, 4), (2, 4);

    INSERT INTO Publicaciones (id_investigacion, titulo, fecha_publicacion) VALUES
        (1, 'Revista de Tecnología Educativa',      '2025-06-20'),
        (1, 'Congreso Internacional de IA',         '2025-08-12'),
        (2, 'Jornadas de Datos Abiertos',           '2025-09-05'),
        (3, 'Revista de Bases de Datos Aplicadas',  '2025-10-01');

    INSERT INTO PermisosUsuario (usuario, nivel_acceso, id_autor) VALUES
        ('alex',     'admin',    1),
        ('maria',    'edicion',  2),
        ('invitado', 'lectura',  NULL);
END
GO
