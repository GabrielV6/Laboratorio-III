-- Resolver:

----------------------------------------------------------------------------------------------------------

--1) Se pide agregar una modificación a la base de datos para que permita registrar la
--calificación (de 1 a 10) que el Cliente le otorga al Chofer en un viaje y además una

Alter table Puntos
Add TipoPuntaje Varchar(10) not null check (TipoPuntaje in ('Cliente','Chofer'));

Alter table Puntos 
add	Comentario Varchar(100) not null;

Alter table Puntos
add Check (PuntosObtenidos between 1 and 10);

----------------------------------------------------------------------------------------------------------

--2) Realizar una vista llamada VW_ClientesDeudores que permita listar: Apellidos,
--Nombres, Contacto (indica el email de contacto, si no lo tiene el teléfono y de lo
--contrario "Sin datos de contacto"), cantidad de viajes totales, cantidad de viajes no
--abonados y total adeudado. Sólo listar aquellos clientes cuya cantidad de viajes no
--abonados sea superior a la mitad de viajes totales realizados.

GO

Create view VW_ClientesDeudores as

Select Apellidos, Nombres, C.ID, 
Coalesce(Email,Telefono,'Sin datos de contacto')as Contacto,
count(V.ID) as CantidadViajesTotales,
count(V.ID) - sum(case when Pagado = 1 then 1 else 0 end) as CantidadViajesNoAbonados,
Sum(case when Pagado = 0 then Importe else 0 end) as TotalAdeudado
From Clientes C
inner join Viajes V On C.ID = V.IDCliente and Inicio is not null
Group by Apellidos, Nombres, Email, Telefono, C.ID
Having sum(case when Pagado = 0 then 1 else 0 end) > count(V.ID)/2


GO

--Prueba---------------------------

Select * from VW_ClientesDeudores

Drop View VW_ClientesDeudores
-----------------------------------

----------------------------------------------------------------------------------------------------------

--3. **ATENTOO**) Realizar un procedimiento almacenado llamado SP_ChoferesEfectivo que reciba un
-- año como parámetro y permita lista apellidos y nombres de los choferes que en ese
-- año únicamente realizaron viajes que fueron abonados con la forma de pago 'Efectivo'.
-- NOTA: Es indistinto si el viaje fue pagado o no. Utilizar la fecha de inicio del viaje para determinar el año del mismo.

GO

Alter procedure SP_ChoferesEfectivo(
    @Anio int
)
AS
Begin
    Select distinct C.Apellidos, C.Nombres, C.ID
	From Choferes C
	inner join Viajes V On C.ID = V.IDChofer
	inner join FormasPago F On V.FormaPago = F.ID
	Where F.Nombre = 'Efectivo' and year(V.Inicio) = @Anio and C.Suspendido = 0 and C.ID not in
	(
	    Select distinct C.ID
	    From Choferes C
	    inner join Viajes V On C.ID = V.IDChofer
	    inner join FormasPago F On V.FormaPago = F.ID
	    Where F.Nombre <> 'Efectivo' and year(V.Inicio) = @Anio and C.Suspendido = 0 
    )
End
-- NOTA: Tenia que considerar que SOLO COBRARON EN EFECTIVO , si COMBRO DE OTRA FORMA SE DESCARTA.
GO

--Prueba---------------------------
-- escribir sintaxis para ejecutar SP 

exec SP_ChoferesEfectivo @Anio=2021

----------------------------------------------------------------------------------------------------------

--4.) Realizar un trigger que al borrar un cliente, primero quitarle todos los puntos (bajafísica) 
-- y establecer a NULL todos los viajes de ese cliente. Luego, eliminar físicamente el cliente de la base de datos.

----------
--Tabla: Cliente
--Tipo: Instead of
--Accion: Delete
----------
GO

Create Trigger TR_BorrarCliente
On Clientes
Instead of Delete
AS
Begin
       
	Delete from Puntos
	Where IDCliente = (Select ID from Deleted)
	
	Update Viajes
	Set IDCliente = NULL
	Where IDCliente = (Select ID from Deleted)
	
	Delete from Clientes
	Where ID = (Select ID from Deleted)
	
End
-- Para hilar fino podriamos hacer un Try Catch

Select * From Puntos

----------------------------------------------------------------------------------------------------------

--5.)  Realizar un trigger que garantice que el Cliente sólo pueda calificar al Chofer si el
--     viaje se encuentra pagado. Caso contrario indicarlo con un mensaje aclaratorio.

----------
--Tabla: Puntos
--Tipo: after
--Accion: Insert
----------

GO

Create Trigger TR_CalificarChofer
On Puntos
After Insert
AS
Begin
	Declare @idviaje int
	Declare @pago int
	
	Set @idviaje = (Select IDViaje from Inserted)
	set @pago = (Select Pagado from Viajes where ID = @idviaje)
	if @pago = 0
	Begin
		Rollback Transaction
		RAISERROR('El viaje no esta pagado',16,1)
	End
	
	
	
End

drop trigger TR_CalificarChofer
-- Probar el trigger

insert into Viajes (IDCliente, IDChofer, Inicio, Fin, kms, Importe, FormaPago, Pagado)
values (1, 1, '2021-01-01 00:00:00', '2021-01-01 00:00:00',100, 100, 1, 0)

insert into Puntos (IDCliente, IDViaje,Fecha, PuntosObtenidos,FechaVencimiento, TipoPuntaje, Comentario)
values (1, 2003, '2021-01-01 00:00:00', 10, '2021-01-01 00:00:00', 'Cliente', 'Muy bueno')



