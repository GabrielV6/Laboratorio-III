-- PARCIAL LABORATORIO 3 -- 

--1. Al insertar una votación, verificar que el usuario que vota no lo haga más de una vez para el mismo concurso ni se pueda votar a sí mismo. 
--Tampoco puede votar una fotografía descalificada.

ALTER TRIGGER verif_voto
ON Votaciones
AFTER INSERT
AS

BEGIN
DECLARE @id_usuario INT
DECLARE @id_concurso INT
DECLARE @id_foto INT
DECLARE @IdFotografia INT
DECLARE @mensaje VARCHAR(100)

SET @id_usuario = (SELECT IDVotante FROM inserted)
SET @id_foto = (SELECT IDFotografia FROM inserted)
SET @id_concurso = (Select IdConcurso From Fotografias Where ID = @id_foto)

IF (SELECT COUNT(*) FROM Votaciones 
	WHERE IDVotante = @id_usuario AND IDFotografia = @id_foto and @id_concurso = (Select IdConcurso From Fotografias Where ID = @id_foto)) > 1

BEGIN
SET @mensaje = 'No se puede votar más de una vez '
RAISERROR(@mensaje, 16, 1)
ROLLBACK
END


IF (Select IDParticipante From Fotografias Where ID = @id_foto) = @id_usuario
BEGIN
SET @mensaje = 'No se puede votar a sí mismo'
RAISERROR(@mensaje, 16, 1)
ROLLBACK
END

IF (SELECT Descalificada FROM Fotografias WHERE id = @id_foto) = 1

BEGIN
SET @mensaje = 'No se puede votar una foto descalificada'
RAISERROR(@mensaje, 16, 1)
ROLLBACK
END

END


-- Prueba

INSERT INTO Votaciones (IDVotante, IDFotografia, fecha, puntaje) VALUES (2, 7, '2018-01-01', 10)


--2. Al insertar una fotografía verificar que el usuario creador de la fotografía tenga el ranking suficiente para participar en el concurso. 
--   También se debe verificar que el concurso haya iniciado y no finalizado. Además, el participante no debe registrar una 
--   descalificación en los últimos 100 días. Si ocurriese un error, mostrarlo con un mensaje aclaratorio. De lo contrario, 
--   insertar el registro teniendo en cuenta que la fecha de publicación es la fecha y hora del sistema.

--NOTA: Si una fotografía está descalificada. La fecha de descalificación corresponde a la fecha de fin del concurso de dicha fotografía.
--NOTA2: - El ranking de un usuario consiste en el promedio de puntajes de todas las fotografías de su autoría. Si no tiene promedio, 
--       el ranking del usuario debe ser 0.
--NOTA3: - Un concurso cuyo RankingMinimo es 0.0 significa que acepta a cualquier participante.

Go

CREATE TRIGGER verif_foto
ON Fotografias
INSTEAD OF INSERT
AS

BEGIN
DECLARE @id_usuario INT
DECLARE @id_concurso INT
DECLARE @fecha_publicacion DATETIME
DECLARE @ranking FLOAT
DECLARE @mensaje VARCHAR(100)

SET @id_usuario = (SELECT IDParticipante FROM inserted)
SET @id_concurso = (SELECT IdConcurso FROM inserted)
SET @fecha_publicacion = (SELECT GETDATE())

--Verifico que el concurso haya iniciado y no finalizado
IF (SELECT Inicio FROM Concursos WHERE ID = @id_concurso) > @fecha_publicacion
BEGIN
SET @mensaje = 'El concurso no ha iniciado'
RAISERROR(@mensaje, 16, 1)
ROLLBACK
END

IF (SELECT Fin FROM Concursos WHERE ID = @id_concurso) < @fecha_publicacion
BEGIN
SET @mensaje = 'El concurso ya finalizó'
RAISERROR(@mensaje, 16, 1)
ROLLBACK
END

--Verifico que el usuario tenga el ranking suficiente para participar en el concurso
SET @ranking = (SELECT AVG(Puntaje) FROM Votaciones WHERE IDVotante = @id_usuario)

IF (SELECT RankingMinimo FROM Concursos WHERE ID = @id_concurso) > @ranking
BEGIN
SET @mensaje = 'El usuario no tiene el ranking suficiente para participar en el concurso'
RAISERROR(@mensaje, 16, 1)
ROLLBACK
END

--Verifico que el participante no tenga una descalificación en los últimos 100 días
IF(Select count(*) From Fotografias Where IDParticipante = 2 and Descalificada = 1 and Publicacion > DATEADD(day, -100, GETDATE())) > 0
BEGIN
SET @mensaje = 'El participante tiene una descalificación en los últimos 100 días'
RAISERROR(@mensaje, 16, 1)
ROLLBACK
END

--Inserto la foto
INSERT INTO Fotografias (IDParticipante, IdConcurso,Titulo,Descalificada, Publicacion) VALUES 
(@id_usuario, @id_concurso, (SELECT Titulo FROM inserted), 0, @fecha_publicacion)

END



--3. Hacer un procedimiento almacenado llamado SP_Descalificar que reciba un ID de fotografía y realice la descalificación de la misma. 
--   También debe eliminar todas las votaciones registradas a la fotografía en cuestión. 
---  Sólo se puede descalificar una fotografía si pertenece a un concurso no finalizado.
GO

CREATE PROCEDURE SP_Descalificar(
	@id_foto INT
)
AS
BEGIN
DECLARE @id_concurso INT
DECLARE @mensaje VARCHAR(100)

SET @id_concurso = (Select IdConcurso From Fotografias Where ID = @id_foto)

IF (Select DATEDIFF(day, GETDATE(), Fin) From Concursos Where ID = @id_concurso) < 0
BEGIN
SET @mensaje = 'No se puede descalificar una foto de un concurso no finalizado'
RAISERROR(@mensaje, 16, 1)
ROLLBACK
END

UPDATE Fotografias SET Descalificada = 1 WHERE ID = @id_foto

DELETE FROM Votaciones WHERE IDFotografia = @id_foto

END


--Prueba

EXEC SP_Descalificar 1
insert into Concursos (Titulo, Inicio, Fin , RankingMinimo) values ('Concurso 1', '2018-01-01', '2022-11-08', 0.00)



Go

-- 4. Hacer un procedimiento almacenado llamado SP_Ranking que a partir de un IDConcurso se pueda obtener las tres mejores 
--  fotografías publicadas (si las hay). Indicando el nombre del concurso, apellido y nombres del participante, el título de la publicación,
--  la fecha de publicación y el puntaje promedio obtenido por esa publicación.

CREATE PROCEDURE SP_Ranking(
	@id_concurso INT
)
AS
BEGIN

SELECT TOP 3 C.Titulo As NombreConcurso, P.Apellidos, P.Nombres, F.Titulo AS TituloPublicacion, F.Publicacion, AVG(V.puntaje) AS PuntajePromedio
FROM Concursos C
INNER JOIN Fotografias F ON C.ID = F.IdConcurso
INNER JOIN Participantes P ON F.IDParticipante = P.ID
INNER JOIN Votaciones V ON F.ID = V.IDFotografia 
WHERE C.ID = @id_concurso AND F.Descalificada = 0 and P.ID = F.IDParticipante and V.IDFotografia = F.ID
GROUP BY C.Titulo, P.Apellidos, P.Nombres, F.Titulo, F.Publicacion
ORDER BY AVG(V.puntaje) DESC

END



-- 5. Hacer un listado en el que se obtenga: ID de participante, apellidos y nombres de los participantes que hayan votado 
--    al menos en dos concursos distintos.

SELECT DISTINCT p.ID, p.Apellidos, p.Nombres
FROM Participantes p
INNER JOIN Votaciones v ON p.ID = v.IDVotante
INNER JOIN Fotografias f ON v.IDFotografia = f.ID
INNER JOIN Concursos c ON f.IdConcurso = c.ID
WHERE c.ID IN (SELECT DISTINCT c.ID
				FROM Concursos c
				INNER JOIN Fotografias f ON c.ID = f.IdConcurso
				INNER JOIN Votaciones v ON f.ID = v.IDFotografia
				GROUP BY c.ID
				HAVING COUNT(DISTINCT v.IDVotante) >= 2)
Group by p.ID, p.Apellidos, p.Nombres
having count(distinct c.ID) >= 2
			

