/* =====================================================================
   Base de datos: InvestigacionesCientificas
   Motor: SQL Server (compatible con SQL Server Express)
   Script 1 de 3: crea la base de datos y las tablas.
   Se puede ejecutar más de una vez: no borra ni duplica nada.
   ===================================================================== */

IF DB_ID(N'InvestigacionesCientificas') IS NULL
    CREATE DATABASE InvestigacionesCientificas;
GO

USE InvestigacionesCientificas;
GO

IF OBJECT_ID(N'dbo.Instituciones', N'U') IS NULL
CREATE TABLE Instituciones (
    id_institucion INT PRIMARY KEY IDENTITY,
    nombre         VARCHAR(100) NOT NULL,
    region         VARCHAR(50)
);

IF OBJECT_ID(N'dbo.AreasTematicas', N'U') IS NULL
CREATE TABLE AreasTematicas (
    id_area INT PRIMARY KEY IDENTITY,
    nombre  VARCHAR(100) NOT NULL
);

IF OBJECT_ID(N'dbo.Autores', N'U') IS NULL
CREATE TABLE Autores (
    id_autor INT PRIMARY KEY IDENTITY,
    nombre   VARCHAR(100) NOT NULL,
    email    VARCHAR(100)
);

IF OBJECT_ID(N'dbo.Investigaciones', N'U') IS NULL
CREATE TABLE Investigaciones (
    id_investigacion INT PRIMARY KEY IDENTITY,
    titulo           VARCHAR(200) NOT NULL,
    resumen          VARCHAR(MAX),
    fecha            DATE,
    id_institucion   INT,
    id_area          INT,
    palabras_clave   VARCHAR(250),
    FOREIGN KEY (id_institucion) REFERENCES Instituciones(id_institucion),
    FOREIGN KEY (id_area)        REFERENCES AreasTematicas(id_area)
);

-- Si se borra una investigación, se borran también sus filas relacionadas
IF OBJECT_ID(N'dbo.Autor_Investigacion', N'U') IS NULL
CREATE TABLE Autor_Investigacion (
    id_autor         INT,
    id_investigacion INT,
    PRIMARY KEY (id_autor, id_investigacion),
    FOREIGN KEY (id_autor)         REFERENCES Autores(id_autor),
    FOREIGN KEY (id_investigacion) REFERENCES Investigaciones(id_investigacion) ON DELETE CASCADE
);

IF OBJECT_ID(N'dbo.Publicaciones', N'U') IS NULL
CREATE TABLE Publicaciones (
    id_publicacion    INT PRIMARY KEY IDENTITY,
    id_investigacion  INT,
    titulo            VARCHAR(200),
    fecha_publicacion DATE,
    FOREIGN KEY (id_investigacion) REFERENCES Investigaciones(id_investigacion) ON DELETE CASCADE
);

IF OBJECT_ID(N'dbo.PermisosUsuario', N'U') IS NULL
CREATE TABLE PermisosUsuario (
    id_usuario   INT PRIMARY KEY IDENTITY,
    usuario      VARCHAR(50) NOT NULL,
    nivel_acceso VARCHAR(20) CHECK (nivel_acceso IN ('lectura', 'edicion', 'admin')),
    id_autor     INT,
    FOREIGN KEY (id_autor) REFERENCES Autores(id_autor)
);
GO
