
/*INTEGRANTES DEL EQUIPO:

   -Martínez Barrueta Mariana
   -Zuñiga Aviles Nathan Emiliano
   -Gamez Gress Isaac Humberto


*/
use covidHistorico2;

--Saber q años existen en las tablas 
select year(FECHA_INGRESO), count(*)
from datoscovid
group by year(FECHA_INGRESO);

--Crean los filegroups y archivos .ndf
ALTER DATABASE covidHistorico2 ADD FILEGROUP FG_ANTES_2020;
ALTER DATABASE covidHistorico2 ADD FILEGROUP FG_2020;
ALTER DATABASE covidHistorico2 ADD FILEGROUP FG_2021;
ALTER DATABASE covidHistorico2 ADD FILEGROUP FG_2022_MAS;

ALTER DATABASE covidHistorico2 
ADD FILE (NAME = FG_ANTES_2020_dat, FILENAME = 'C:\Data\FG_ANTES_2020.ndf')
TO FILEGROUP FG_ANTES_2020;

ALTER DATABASE covidHistorico2
ADD FILE (NAME = FG_2020_dat, FILENAME = 'C:\Data\FG_2020.ndf')
TO FILEGROUP FG_2020;

ALTER DATABASE covidHistorico2
ADD FILE (NAME = FG_2021_dat, FILENAME = 'C:\Data\FG_2021.ndf')
TO FILEGROUP FG_2021;

ALTER DATABASE covidHistorico2
ADD FILE (NAME = FG_2022_MAS_dat, FILENAME = 'C:\Data\FG_2022_MAS.ndf')
TO FILEGROUP FG_2022_MAS;

--Funcion de partición
CREATE PARTITION FUNCTION pf_anio (DATE)
AS RANGE RIGHT FOR VALUES 
('2020-01-01', '2021-01-01', '2022-01-01');

--Esquema de particion
CREATE PARTITION SCHEME ps_anio
AS PARTITION pf_anio
TO (
    FG_ANTES_2020,
    FG_2020,
    FG_2021,
    FG_2022_MAS
);

--Tabla particionada
CREATE TABLE covid_particionado (
    ID_REGISTRO VARCHAR(50) NOT NULL,
    FECHA_INGRESO DATE NOT NULL,
    ENTIDAD_RES VARCHAR(50),
    EDAD INT
)
ON ps_anio(FECHA_INGRESO);

CREATE CLUSTERED INDEX idx_fecha
ON covid_particionado(FECHA_INGRESO, ID_REGISTRO)
ON ps_anio(FECHA_INGRESO);

--Insertar los datos en la tabla particionada
INSERT INTO covid_particionado (
    ID_REGISTRO,
    FECHA_INGRESO,
    ENTIDAD_RES,
    EDAD
)
SELECT 
    ID_REGISTRO,
    TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO,'"',''), 23),
    REPLACE(ENTIDAD_RES,'"',''),
    TRY_CONVERT(INT, REPLACE(EDAD,'"',''))
FROM datoscovid
WHERE TRY_CONVERT(DATE, REPLACE(FECHA_INGRESO,'"',''), 23) IS NOT NULL;

