/* PRACTICA 1 BASE DE DATOS ADVENTUREWORKS 2022*/

use AdventureWorks2022;

select * from sales.SalesOrderHeader;
select * from sales.SalesOrderDetail;
select * from Production.Product;
select * from HumanResources.Employee;
select * from Person.Person;

/*Consulta 1 */
/*Encuentra los 10 productos más vendidos en 2014, mostrando nombre del producto, 
cantidad total vendida y nombre del cliente. */
SELECT 
    P.Name AS Producto, 
    T.cant AS TotalVendido,
    PER.FirstName + ' ' + PER.LastName AS NombreCliente
FROM Production.Product P
JOIN (
    -- 1. Subconsulta: Encuentra los 10 IDs más vendidos SOLO en 2014
    SELECT TOP 10 
        SOD.ProductID, 
        SUM(SOD.OrderQty) AS cant
    FROM Sales.SalesOrderDetail SOD
    JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
    WHERE YEAR(SOH.OrderDate) = 2014
    GROUP BY SOD.ProductID
    ORDER BY cant DESC
) AS T ON P.ProductID = T.ProductID
-- 2. Unimos con el detalle para ver a TODOS los clientes de esos productos en 2014
JOIN Sales.SalesOrderDetail D ON P.ProductID = D.ProductID
JOIN Sales.SalesOrderHeader H ON D.SalesOrderID = H.SalesOrderID
JOIN Sales.Customer C ON H.CustomerID = C.CustomerID
JOIN Person.Person PER ON C.PersonID = PER.BusinessEntityID
WHERE YEAR(H.OrderDate) = 2014
ORDER BY T.cant DESC, Producto;


/*Una vez resuelta la consulta: agrega el precio unitario promedio (AVG(UnitPrice)) y filtra solo 
productos con ListPrice > 1000.*/
SELECT 
    P.Name AS Producto, 
    T.cant AS TotalVendido2014,
    T.PrecioPromedio,
    PER.FirstName + ' ' + PER.LastName AS NombreCliente
FROM Production.Product P
JOIN (
    -- Subconsulta
    SELECT TOP 10 
        SOD.ProductID, 
        SUM(SOD.OrderQty) AS cant,
        AVG(SOD.UnitPrice) AS PrecioPromedio
    FROM Sales.SalesOrderDetail SOD
    JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
    JOIN Production.Product PRO ON SOD.ProductID = PRO.ProductID
    WHERE YEAR(SOH.OrderDate) = 2014    -- Solo año 2014
      AND PRO.ListPrice > 1000          -- Solo productos > 1000
    GROUP BY SOD.ProductID
    ORDER BY cant DESC
) AS T ON P.ProductID = T.ProductID
-- 2. Detalle de los clientes
JOIN Sales.SalesOrderDetail D ON P.ProductID = D.ProductID
JOIN Sales.SalesOrderHeader H ON D.SalesOrderID = H.SalesOrderID
JOIN Sales.Customer C ON H.CustomerID = C.CustomerID
JOIN Person.Person PER ON C.PersonID = PER.BusinessEntityID
WHERE YEAR(H.OrderDate) = 2014
ORDER BY T.cant DESC, Producto;

/*Consulta 2*/

/*Lista los empleados que han vendido más que el promedio de ventas por empleado en 
el territorio 'Northwest'. */

SELECT 
    P.FirstName + ' ' + P.LastName AS Empleado,
    SUM(SOH.TotalDue) AS TotalVendidoEmpleado
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
JOIN HumanResources.Employee E ON SOH.SalesPersonID = E.BusinessEntityID
JOIN Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
WHERE ST.Name = 'Northwest'
GROUP BY P.FirstName, P.LastName
HAVING SUM(SOH.TotalDue) > (
    -- Esta subconsulta calcula el promedio de ventas por empleado en ese territorio
    SELECT AVG(VentasPorVendedor.Total)
    FROM (
        SELECT SUM(TotalDue) AS Total
        FROM Sales.SalesOrderHeader SOH2
        JOIN Sales.SalesTerritory ST2 ON SOH2.TerritoryID = ST2.TerritoryID
        WHERE ST2.Name = 'Northwest'
        GROUP BY SOH2.SalesPersonID
    ) AS VentasPorVendedor
);

/*Una vez resuelta la consulta convierte la subconsulta en un CTE (Common Table Expresión). */
-- 1. Definimos el CTE (nuestra tabla temporal lógica)
WITH VentasPorVendedorCTE AS (
    SELECT 
        SOH2.SalesPersonID,
        SUM(SOH2.TotalDue) AS TotalVentas
    FROM Sales.SalesOrderHeader SOH2
    JOIN Sales.SalesTerritory ST2 ON SOH2.TerritoryID = ST2.TerritoryID
    WHERE ST2.Name = 'Northwest'
    GROUP BY SOH2.SalesPersonID
)

-- 2. Usamos el CTE en la consulta principal
SELECT 
    P.FirstName + ' ' + P.LastName AS Empleado,
    SUM(SOH.TotalDue) AS TotalVendidoEmpleado
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
JOIN HumanResources.Employee E ON SOH.SalesPersonID = E.BusinessEntityID
JOIN Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
WHERE ST.Name = 'Northwest'
GROUP BY P.FirstName, P.LastName
HAVING SUM(SOH.TotalDue) > (SELECT AVG(TotalVentas) FROM VentasPorVendedorCTE);


/*Consulta 3*/

/*  Calcula ventas totales por territorio y año, mostrando solo aquellos con más de 5 órdenes 
y ventas > $1,000,000, ordenado por ventas descendente. */
SELECT 
    ST.Name AS Territorio,
    YEAR(SOH.OrderDate) AS Anio,
    SUM(SOH.TotalDue) AS VentasTotales,
    COUNT(SOH.SalesOrderID) AS NumeroOrdenes,
    STDEV(SOH.TotalDue) AS DesviacionVentas
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
GROUP BY ST.Name, YEAR(SOH.OrderDate)
HAVING COUNT(SOH.SalesOrderID) > 5 AND SUM(SOH.TotalDue) > 1000000
ORDER BY VentasTotales DESC;

/* Una vez resuelta la consulta agrega desviación estándar de ventas  */
SELECT 
    ST.Name AS Territorio,
    YEAR(SOH.OrderDate) AS Anio,
    SUM(SOH.TotalDue) AS VentasTotales,
    COUNT(SOH.SalesOrderID) AS NumeroOrdenes,
    STDEV(SOH.TotalDue) AS DesviacionVentas
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryID
GROUP BY ST.Name, YEAR(SOH.OrderDate)
HAVING COUNT(SOH.SalesOrderID) > 5 AND SUM(SOH.TotalDue) > 1000000
ORDER BY VentasTotales DESC;

/*Consulta 4*/

/*  Encuentra vendedores que han vendido TODOS los productos de la categoría "Bikes". */
SELECT SP.BusinessEntityID, P.FirstName, P.LastName
FROM Sales.SalesPerson SP
JOIN Person.Person P ON SP.BusinessEntityID = P.BusinessEntityID
WHERE NOT EXISTS (
    SELECT PRO.ProductID
    FROM Production.Product PRO
    JOIN Production.ProductSubcategory SC ON PRO.ProductSubcategoryID = SC.ProductSubcategoryID
    JOIN Production.ProductCategory C ON SC.ProductCategoryID = C.ProductCategoryID
    WHERE C.Name = 'Bikes'
    EXCEPT
    SELECT SOD.ProductID
    FROM Sales.SalesOrderHeader SOH
    JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
    WHERE SOH.SalesPersonID = SP.BusinessEntityID
);

/* Cambia a categoría "Clothing" (ID=4). */
	SELECT 
		PER.FirstName + ' ' + PER.LastName AS Vendedor,
		CAT.Name AS Categoria,
		COUNT(DISTINCT SOD.ProductID) AS ProductosVendidos
	FROM Sales.SalesOrderHeader SOH
	JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
	JOIN Sales.SalesPerson SP ON SOH.SalesPersonID = SP.BusinessEntityID
	JOIN Person.Person PER ON SP.BusinessEntityID = PER.BusinessEntityID
	JOIN Production.Product PRO ON SOD.ProductID = PRO.ProductID
	JOIN Production.ProductSubcategory SUB ON PRO.ProductSubcategoryID = SUB.ProductSubcategoryID
	JOIN Production.ProductCategory CAT ON SUB.ProductCategoryID = CAT.ProductCategoryID
		WHERE CAT.ProductCategoryID = 4 -- Categoría Clothing
	GROUP BY PER.FirstName, PER.LastName, CAT.Name;

/*Consulta 5*/

/*Determinar el producto más vendido de cada categoría de producto, considerando el 
escenario de que el esquema SALES se encuentra en una instancia (servidor) A y el esquema 
PRODUCTION en otra instancia (servidor) B.5*/

EXEC sp_addlinkedserver 
   @server = 'SV_SELF',
   @srvproduct = 'SQLServer', -- opcional
   @provider = 'SQLOLEDB',
   @datasrc = '10.95.188.103,1433';

EXEC sp_addlinkedsrvlogin 
   @rmtsrvname = 'SV_SELF',--'nombre_de_la_conexión_que_se_asociara'
   @useself = 'false', -- valor false si se usarán credenciales distintas
   @rmtuser = 'sa', --ususario remoto
   @rmtpassword = '1111'; --password de usuario remoto

EXEC sp_testlinkedserver SV_SELF;

EXEC sp_dropserver'SV_SELF', 'droplogins';
go

SELECT 
    CAT.Name AS Categoria,
    P.Name AS Producto,
    SUM(SOD.OrderQty * SOD.UnitPrice) AS ValorTotalVendido
FROM [SV_SELF].[AdventureWorks2022].[Production].[Product] P
INNER JOIN [SV_SELF].[AdventureWorks2022].[Sales].[SalesOrderDetail] SOD 
    ON P.ProductID = SOD.ProductID
INNER JOIN [SV_SELF].[AdventureWorks2022].[Production].[ProductSubcategory] PS 
    ON P.ProductSubcategoryID = PS.ProductSubcategoryID
INNER JOIN [SV_SELF].[AdventureWorks2022].[Production].[ProductCategory] CAT 
    ON PS.ProductCategoryID = CAT.ProductCategoryID
GROUP BY CAT.ProductCategoryID, CAT.Name, P.Name
HAVING SUM(SOD.OrderQty * SOD.UnitPrice) = (
    SELECT MAX(VentasPorCat.Total)
    FROM (
        SELECT P2.ProductSubcategoryID, SUM(SOD2.OrderQty * SOD2.UnitPrice) AS Total
        FROM [SV_SELF].[AdventureWorks2022].[Sales].[SalesOrderDetail] SOD2
        INNER JOIN [SV_SELF].[AdventureWorks2022].[Production].[Product] P2 
            ON SOD2.ProductID = P2.ProductID
        GROUP BY P2.ProductSubcategoryID, P2.ProductID
    ) AS VentasPorCat
    INNER JOIN [SV_SELF].[AdventureWorks2022].[Production].[ProductSubcategory] PS2 
        ON VentasPorCat.ProductSubcategoryID = PS2.ProductSubcategoryID
    WHERE PS2.ProductCategoryID = CAT.ProductCategoryID
)
ORDER BY Categoria;