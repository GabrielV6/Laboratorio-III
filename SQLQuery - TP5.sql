--1. Hacer un trigger que al compartir un archivo se verifique que el mismo no se esté compartiendo con el usuario dueño del archivo. 
--   También tener en cuenta que los usuarios que tienen un tipo de cuenta Free solamente pueden compartir archivos con permiso de lectura (R). 
--   Mostrar el mensaje correspondiente a cada situación o bien guardar el registro.
--   Nota: La fecha de compartición debe ser la del sistema. Si se comparte con permiso de escritura y no tiene el tipo de cuenta suficiente 
--   debe cancelar la inserción del registro.

Go
Create Trigger Compartir
on Compartidos
instead of insert
as
begin

declare @idArchivo int
declare @idUsuario int
declare @permiso char(1)
declare @idTipoCuenta int
declare @almacenamiento int

select @idArchivo = IDArchivo, @idUsuario = IDUsuario, @permiso = Permiso from inserted
select @idTipoCuenta = IDTipo from Usuarios where ID = @idUsuario
select @almacenamiento = CapacidadAlmacenamiento from TiposCuenta where ID = @idTipoCuenta

if(Select IDUsuario from Archivos where ID = @idArchivo) = @idUsuario
begin
raiserror('No se puede compartir con el usuario dueño del archivo', 16, 1)
return
end

if(@permiso <> 'R' and @idTipoCuenta = (select ID from TiposCuenta where Descripcion Like 'Free'))
begin
raiserror('No se puede compartir con permiso de escritura', 16, 1)
return
end

if( @permiso <> 'R' and @almacenamiento < (select tamaño from Archivos where ID = @idArchivo))
begin
raiserror('No se puede compartir, espacio insuficiente', 16, 1)
return
end


insert into Compartidos (IDArchivo, Fecha, Permiso, IDUsuario)
values (@idArchivo, getdate(), @permiso, @idUsuario)

end

--Prueba de trigger

		-- Espacio insuficiente
		insert into Compartidos (IDArchivo, Fecha, Permiso, IDUsuario)
		values (2, getdate(), 'W', 4)
		-- No se puede compartir con permiso de escritura
		insert into Compartidos (IDArchivo, Fecha, Permiso, IDUsuario)
		values (2, getdate(), 'W', 3)
		-- No se puede compartir con el usuario dueño del archivo
		insert into Compartidos (IDArchivo, Fecha, Permiso, IDUsuario)
		values (2, getdate(), 'W', 1)

		--OK
		insert into Compartidos (IDArchivo, Fecha, Permiso, IDUsuario)
		values (2, getdate(), 'R', 3)



--2. Realizar un procedimiento almacenado llamado SP_Estadistica que permita visualizar por cada tipo de archivo, 
--   el total acumulado en MBs por los archivos agrupando por tipo de cuenta. La información debe estar ordenada por MBs acumulados en orden decreciente.

Go
Create Procedure SP_Estadistica

as
begin

select sum(Archivos.Tamaño) as 'MBs acumulados', TiposArchivo.Descripcion as 'Tipo de archivo', TiposCuenta.Descripcion as 'Tipo de cuenta'
from Archivos
inner join TiposArchivo on Archivos.IDTipo = TiposArchivo.ID
inner join Usuarios on Archivos.IDUsuario = Usuarios.ID
inner join TiposCuenta on Usuarios.IDTipo = TiposCuenta.ID
group by TiposArchivo.Descripcion, TiposCuenta.Descripcion
order by sum(Archivos.Tamaño) desc

end
--Prueba de SP

	exec SP_Estadistica


	
--3. Hacer un procedimiento almacenado llamado SP_RegistrarUsuario que reciba IDUsuarioReferencia, Nombre del usuario y Tipo de cuenta para registrar 
--   un usuario a LaraBox y registrarlo en la base de datos. Si este fue invitado por otro usuario, este último (el usuario que invitó) 
--   recibe una bonificación de 100 Megabytes en su espacio total de almacenamiento.
--   En cualquier caso (invitado o no), la cuenta a registrar debe establecer el tamaño total de almacenamiento a partir del Tipo de cuenta asignado.

-- NOTA: Si un usuario no fue invitado, entonces registra NULL en el campo IDUSUARIOREFERENCIA. 
-- El espacio de almacenamiento de los usuarios ya se encuentra expresado en Megabytes al igual que la CapacidadAlmacenamiento del tipo de cuenta 
-- en la tabla TiposCuenta.

GO

Create Procedure SP_RegistrarUsuario
@IDUsuarioReferencia int,
@NombreUsuario varchar(50),
@IDTipoCuenta int

as
begin

declare @almacenamientoCuenta int
declare @almacenamientoUsuario int

select @almacenamientoCuenta = CapacidadAlmacenamiento from TiposCuenta where ID = @IDTipoCuenta

if(@IDUsuarioReferencia is not null)
	begin
	select @almacenamientoUsuario = (select Espacio from Usuarios where ID = @IDUsuarioReferencia) + 100

	update Usuarios set Espacio = @almacenamientoUsuario where ID = @IDUsuarioReferencia
end
else
begin
	set @IDUsuarioReferencia = NULL
end

insert into Usuarios (IDUsuarioReferencia, Nombreusuario, Espacio, IDTipo,Estado)
values (@IDUsuarioReferencia, @NombreUsuario, @almacenamientoCuenta, @IDTipoCuenta, 1)

end

	-- Prueba de SP

	--Prueba ok, 100+ para usuario 1
		exec SP_RegistrarUsuario 1, 'Usuario 4', 1
	
	--Prueba ok, para usuario null
		exec SP_RegistrarUsuario null,'Usuario 4', 1
	
	--Prueba ok, 100+ para usuario 2
		exec SP_RegistrarUsuario 2, 'Usuario 4', 1



--4. Hacer un procedimiento llamado SP_EstadisticaUsuario almacenado que reciba un IDUsuario y muestre por pantalla el nombre de usuario, 
--   la cantidad total de archivos, el nombre del último archivo subido por dicho usuario y la cantidad de MBs de espacio disponible que tiene en la cuenta. 
--   En caso de no haber subido un archivo mostrar NULL en el nombre del último archivo subido.
--   NOTA: Deben contabilizarse todos los archivos del usuario indistintamente del estado.


GO

Create Procedure SP_EstadisticaUsuario
@IDUsuario int

as
begin

Select NombreUsuario, (select count(*) from Archivos where IDUsuario = @IDUsuario) as 'Cantidad de archivos', 
(
	select top 1 Coalesce(Nombre,'NULL') from Archivos where IDUsuario = @IDUsuario order by FechaCreacion desc
) as 'Ultimo archivo subido', 
(
	select Espacio - sum(Tamaño) from Archivos where IDUsuario = @IDUsuario
) as 'Espacio disponible'
from Usuarios
where Usuarios.ID = @IDUsuario


end

	--Prueba SP

	exec SP_EstadisticaUsuario 1


	
-- tablas 

Select * from Archivos
Select * from TiposArchivo
select * from Usuarios
select * from TiposCuenta
select * from Compartidos