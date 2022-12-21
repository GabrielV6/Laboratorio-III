-- 1. Hacer un trigger que al registrar una captura se verifique que la cantidad de capturas que haya realizado 
--    el competidor no supere las reglamentadas por el torneo. Tampoco debe permitirse registrar más capturas si el 
--    competidor ya ha devuelto veinte peces o más en el torneo. Indicar cada situación con un mensaje de error aclaratorio. 
--    Caso contrario, registrar la captura.

Create trigger tr_captura
On capturas
After insert
As
Begin
Declare @id_competidor int
Declare @cant_capturas int
Declare @cant_devueltas int
Declare @mensaje varchar(100)
Declare @CapturasXCompetidor int
Declare @PecesDevueltosPorCompetidor int

Set @id_competidor = (Select IDCompetidor from inserted)
Set @cant_capturas = (Select count(*) from capturas where IDCompetidor = @id_competidor)
Set @cant_devueltas = (Select count(*) from capturas where IDCompetidor = @id_competidor and Devuelta = 1)
Set @CapturasXCompetidor = (Select CapturasPorCompetidor from torneos where id = (Select IDTorneo from Capturas where id = @id_competidor))
Set @PecesDevueltosPorCompetidor = (Select count(*) from capturas where IDCompetidor = @id_competidor and Devuelta = 1) 

If @cant_capturas > @CapturasXCompetidor
Begin
Set @mensaje = 'No se puede registrar la captura, ya se registraron 20 capturas'
Raiserror(@mensaje, 16, 1)
Rollback
End

If @cant_devueltas >= @PecesDevueltosPorCompetidor
Begin
Set @mensaje = 'No se puede registrar la captura, ya se devolvieron 20 peces'
Raiserror(@mensaje, 16, 1)
Rollback
End
End

-- Inserto dats de prueba

Insert into capturas (IDCompetidor,IDTorneo, IDEspecie, FechaHora, Peso, devuelta) values (1,1,1,'2018-01-01',10,0)
Insert into capturas (IDCompetidor,IDTorneo, IDEspecie, FechaHora, Peso, devuelta) values (1,2,1,'2018-01-01',10,0)
Insert into capturas (IDCompetidor,IDTorneo, IDEspecie, FechaHora, Peso, devuelta) values (1,2,1,'2018-01-01',10,0)
Insert into capturas (IDCompetidor,IDTorneo, IDEspecie, FechaHora, Peso, devuelta) values (1,2,1,'2018-01-01',10,0)
Insert into capturas (IDCompetidor,IDTorneo, IDEspecie, FechaHora, Peso, devuelta) values (1,1,1,'2018-01-02',12,1)

Delete from capturas where id = 5
drop trigger tr_captura

-- 2. Hacer un trigger que no permita que al cargar un torneo se otorguen más de un millón de pesos en premios entre todos los torneos de ese mismo año.
--    En caso de ocurrir indicar el error con un mensaje aclaratorio. Caso contrario, registrar el torneo.
Go
Create trigger tr_torneo
On torneos
After insert
As
Begin
Declare @id_torneo int
Declare @anio int
Declare @premios int
Declare @mensaje varchar(100)

Set @id_torneo = (Select ID from inserted)
Set @anio = (Select Año from torneos where id = @id_torneo)
Set @premios = (Select sum(Premio) from torneos where Año = @anio)

If @premios > 1000000
Begin
Set @mensaje = 'No se puede registrar el torneo, ya se otorgaron mas de 1 millon de pesos en premios'
Raiserror(@mensaje, 16, 1)
Rollback
End
End

-- Inserto dats de prueba

Insert into torneos (Nombre, Año,Ciudad,Inicio,Fin,Premio,CapturasPorCompetidor) values ('Torneo 2',2018,'Buenos Aires','2018-10-02','2018-12-10',490000,3)

-- 3.Hacer un trigger que al eliminar una captura sea marcada como devuelta y que al eliminar una captura que ya se encuentra como devuelta 
-- se realice la baja física del registro.

GO
Create trigger tr_captura
On capturas
instead of delete
As
Begin
Declare @id_captura int
Declare @mensaje varchar(100)

Set @id_captura = (Select ID from deleted)

If (Select Devuelta from capturas where id = @id_captura) = 0
Begin
Update capturas set Devuelta = 1 where id = @id_captura
End
Else
Begin
Delete from capturas where id = @id_captura
End 
End
	
-- Inserto dats de prueba

Delete from capturas where id = 4

-- 4. Hacer un procedimiento almacenado que a partir de un IDTorneo indique los datos del ganador del mismo. 
--    El ganador es aquel pescador que haya sumado la mayor cantidad de puntos en el torneo. 
--    Se suman 3 puntos por cada pez capturado y se resta un punto por cada pez devuelto. Indicar Nombre, Apellido y Puntos.

GO
create procedure sp_ganador
@id_torneo int
as
Begin

Select top 1 with ties Com.Nombre, Com.Apellido, 
Case When 
  C.Devuelta = 0 then count(C.ID)*3
else 
  count(C.ID)*2
End as Puntos
From Capturas C
inner join Competidores Com on Com.ID = C.IDCompetidor
Where C.IDTorneo = @id_torneo
Group by Com.Nombre, Com.Apellido, C.Devuelta
Order by Puntos Asc
End

-- Segunda forma de realizar la Query 

Create procedure sp_ganador2

-- Inserto dats de prueba
Go
exec sp_ganador '1'
drop procedure sp_ganador

Select * from capturas;
Select * from competidores;
Select * from torneos;
Select * from especies;
