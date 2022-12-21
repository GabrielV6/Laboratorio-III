-- 1. Hacer un trigger que al cargar un crédito verifique que el importe del mismo sumado a los importes de los créditos que actualmente solicitó esa persona no supere al triple de la declaración de ganancias. 
--Sólo deben tenerse en cuenta en la sumatoria los créditos que no se encuentren cancelados. 
-- De no poder otorgar el crédito aclararlo con un mensaje.

CREATE TRIGGER verif_credito
ON CREDITOS
AFTER INSERT
AS

BEGIN
DECLARE @dni INT
DECLARE @importe DECIMAL(10,2)
DECLARE @suma DECIMAL(10,2)
DECLARE @mensaje VARCHAR(100)

SET @dni = (SELECT dni FROM inserted)

SET @suma = (SELECT SUM(importe) FROM CREDITOS WHERE dni = @dni AND Cancelado = 0)

IF @suma > 3 * (SELECT DeclaracionGanancias FROM PERSONAS WHERE dni = @dni)
BEGIN
SET @mensaje = 'No se puede otorgar el crédito1'
RAISERROR(@mensaje, 16, 1)
ROLLBACK 
END
END

-- Test de prueba para Trigger: 
-- DNI; 1111 -> declaracion 100000,00

Insert into CREDITOS (IDBanco,dni,Fecha,importe,Plazo, Cancelado) values (1,1111,'2018-01-01',10000000,5,0)



-- 2. Hacer un trigger que al eliminar un crédito realice la cancelación del mismo.
Go

CREATE TRIGGER cancelar_credito
ON CREDITOS
instead of DELETE
AS

BEGIN
DECLARE @id INT
Set @id = (SELECT id FROM deleted)

UPDATE CREDITOS SET Cancelado = 1 WHERE id = @id 
-- UPDATE CREDITOS SET Cancelado = 1 WHERE ID IN(Select ID FROM deleted)
END

-- Test 2.

Delete from CREDITOS where id = 3


-- 3. Hacer un trigger que no permita otorgar créditos con un plazo de 20 o más años a personas cuya declaración de ganancias 
--    sea menor al promedio de declaración de ganancias.

Go
CREATE TRIGGER verif_plazo
ON CREDITOS
AFTER INSERT
AS

BEGIN

DECLARE @dni INT
DECLARE @plazo Money
DECLARE @mensaje VARCHAR(100)

SET @dni = (SELECT dni FROM inserted)
SET @plazo = (SELECT plazo FROM inserted)

IF @plazo >= 20 AND (SELECT DeclaracionGanancias FROM PERSONAS WHERE dni = @dni) < (SELECT AVG(DeclaracionGanancias) FROM PERSONAS)
BEGIN
SET @mensaje = 'No se puede otorgar el crédito2'
RAISERROR(@mensaje, 16, 1)
ROLLBACK
END
END


-- Test 3.

Insert into CREDITOS (IDBanco,dni,Fecha,importe,Plazo, Cancelado) values (1,4444,'2018-01-01',100000334,21,0)


-- 4. Hacer un procedimiento almacenado que reciba dos fechas y liste todos los créditos otorgados entre esas fechas. 
--    Debe listar el apellido y nombre del solicitante, el nombre del banco, el tipo de banco, la fecha del crédito y el importe solicitado.

Go
CREATE PROCEDURE creditos_entre_fechas
@fecha1 DATETIME,
@fecha2 DATETIME
AS

BEGIN
SELECT P.Apellidos, P.Nombres, B.Nombre, B.Tipo, C.Fecha, C.Importe
FROM CREDITOS C
INNER JOIN PERSONAS P ON C.dni = P.dni
INNER JOIN BANCOS B ON C.IDBanco = B.ID
WHERE C.Fecha BETWEEN @fecha1 AND @fecha2
END

-- Test 4.

EXEC creditos_entre_fechas '2018-01-01','2018-01-31'


--------------------------
Select * from PERSONAS
Select * FROM CREDITOS
Select * FROM Bancos






