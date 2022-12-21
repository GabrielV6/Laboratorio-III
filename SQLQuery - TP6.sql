--FINAL LABORATORIO III

--1. Hacer un trigger que al agregar un archivo verifique que el usuario tenga espacio suficiente para almacenarlo. 
--   En caso de no poseer suficiente espacio, cancelar el registro e indicarlo con un mensaje aclaratorio. De lo contrario, guardar el registro.
Go
Create Trigger AgregarArchivo
on Archivos
instead of insert
as
begin

declare @idTipo int 
declare @idUsuario int
declare @NombreArchivo varchar(100)
declare @fecha date
declare @tamaño int
declare @almacenamiento int

select @idTipo = IDTipo, @idUsuario = IDUsuario, @NombreArchivo = Nombre, @fecha = FechaCreacion, @tamaño = Tamaño from inserted
select @almacenamiento = Espacio from Usuarios where ID = @idUsuario
-- ERROR habia que sumar el tamaño de todos los archivos y validar que el nuevo archivo entrara con la capacidad que tiene ahora.
if(@almacenamiento < @tamaño)
begin
raiserror('No se puede agregar el archivo, espacio insuficiente', 16, 1)
return
end

insert into Archivos (IDTipo, IDUsuario, Nombre, FechaCreacion, Tamaño, Estado)
values (@idTipo, @idUsuario, @NombreArchivo, @fecha, @tamaño,1)

end


--2. Hacer un trigger que al registrar un archivo compartido (Tabla Compartidos) verifique que las cuentas Free no puedan:
--Compartir el mismo archivo con más de un usuario.
--Compartir más de tres archivos distintos.
--En caso de que ocurra alguna de las siguientes situaciones, indicarlo con un mensaje aclaratorio y cancelar la carga. De lo contrario, guardar el registro.

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
declare @contador int
declare @fecha date

select @idArchivo = IDArchivo, @idUsuario = IDUsuario, @permiso = Permiso, @fecha = Fecha from inserted
select @idTipoCuenta = IDTipo from Usuarios where ID = @idUsuario

if(@idTipoCuenta = (select ID from TiposCuenta where Descripcion Like 'Free'))
	begin
	
	--validar que no se pueda Compartir el mismo archivo con más de un usuario.
    if((select count(*) from Compartidos where IDArchivo = @idArchivo) > 0)
	begin
	raiserror('No se puede compartir el archivo, ya se encuentra compartido', 16, 1)
	return
	end
	
	--validar que no se pueda Compartir más de tres archivos distintos.

	-- ERROR tenia que hacer un disctint idArchivo, y no el <> en el where.
	select @contador = count(*) from Compartidos where IDUsuario = @idUsuario and IDArchivo <> @idArchivo
	if(@contador > 3)
	begin
	raiserror('No se puede compartir el archivo, supera el limite de archivos compartidos', 16, 1)
	return
	end
		
	
end

insert into Compartidos (IDArchivo, Fecha, Permiso, IDUsuario)
values (@idArchivo, @fecha, @permiso, @idUsuario)


end


--3. Hacer un procedimiento almacenado llamado SP_RegistrarUsuario que reciba IDUsuarioReferencia, Nombre del usuario y 
-- Tipo de cuenta para registrar un usuario a LaraBox y registrarlo en la base de datos. 
-- Si este fue invitado por otro usuario, este último (el usuario que invitó) debe recibir un aumento de la mitad de su Espacio actual 
--(si es la primera vez que recibe este bonus) y de 500MB por los próximos bonus hasta un total de 5. Luego ya no recibe más bonificaciones.
-- NOTA: Si un usuario no fue invitado, entonces registra NULL en el campo IDUSUARIOREFERENCIA. El espacio de almacenamiento de los usuarios 
-- ya se encuentra expresado en Megabytes al igual que la CapacidadAlmacenamiento del tipo de cuenta en la tabla TiposCuenta.

--OK
Go
Create Procedure SP_RegistrarUsuario
@IDUsuarioReferencia int,
@Nombre varchar(100),
@IDTipoCuenta int
as
begin

declare @espacio int
declare @contador int

if(@IDUsuarioReferencia is not null)
	begin
	select @espacio = Espacio from Usuarios where ID = @IDUsuarioReferencia
	select @contador = count(u.IDUsuarioReferencia) from Usuarios u where IDUsuarioReferencia = @IDUsuarioReferencia

	if(@contador <5)
		begin
		set @espacio = @espacio + (@espacio/2) + 500
		update Usuarios set Espacio = @espacio where ID = @IDUsuarioReferencia 
		
	end
		else
			begin
			set @espacio = @espacio + (@espacio/2)
			update Usuarios set Espacio = @espacio where ID = @IDUsuarioReferencia 
		end

	insert into Usuarios (IDUsuarioReferencia, NombreUsuario, Espacio, IDTipo, Estado)
	values (@IDUsuarioReferencia, @Nombre, (select CapacidadAlmacenamiento from TiposCuenta where ID = @IDTipoCuenta), @IDTipoCuenta, 1)
end
else
begin
	
	insert into Usuarios (IDUsuarioReferencia, NombreUsuario, Espacio, IDTipo, Estado)
	values (@IDUsuarioReferencia, @Nombre, (select CapacidadAlmacenamiento from TiposCuenta where ID = @IDTipoCuenta), @IDTipoCuenta, 1)
end

end

	--prueba

	exec SP_RegistrarUsuario 2, 'Usuario New1', 1

-- 4.Hacer un procedimiento almacenado llamado SP_InformacionUsuario que reciba un IDUsuario como parámetro y muestre por cada tipo de archivo: 
-- el nombre y la cantidad de archivos no eliminados de ese tipo que registre el usuario. 

--OK
Go
Create Procedure SP_InformacionUsuario
@IDUsuario int
as
begin

select distinct t.Descripcion 'TipoDeArchivo', count(a.ID) as CantidadArchivos from Archivos a
inner join TiposArchivo t on t.ID = a.IDTipo
where a.IDUsuario = @IDUsuario and a.Estado = 1
group by t.Descripcion 

end

--prueba
exec SP_InformacionUsuario 1


-- JOSE FINAL 

--  Hacer un trigger que al agregar un archivo verifique que el usuario tenga espacio
--suficiente para almacenarlo. Tener en cuenta que los archivos que pertenecen a los tipos
--'Lara File' y 'Kloster File' ocupan el doble de espacio para cuentas de tipo 'Free'. También
--considerar que las cuentas de tipo 'Free' no pueden subir un archivo individual de más de 1000MB independientemente del tipo de archivo que sea.
--Informar cada situación con un mensaje aclaratorio. En caso de que pueda registrarse, insertar el registro

Select sum(a.Tamaño) from Archivos a where a.IDUsuario = 4 and a.Estado = 1
Select TiposCuenta.CapacidadAlmacenamiento From Usuarios 
inner join TiposCuenta on TiposCuenta.ID = Usuarios.IDTipo
where Usuarios.ID = 1

Select * From Usuarios where ID = 4
Select * from Archivos where IDUsuario = 4
Select * FROM tiposArchivo
Select * FROM TiposCuenta where ID = 2



-- 15+ 15 +10 = 40 mb (Disponible = 960-200 = 760)

-- Prueba 1 

insert into Archivos (IDTipo,IDUsuario,Nombre,FechaCreacion, Tamaño, Estado)
values (4, 4, 'Archivo 1', '2019-05-01', 200, 1)

--Prueba 2 Con usuario tipo Free

update Usuarios set IDTipo =1 where ID = 4

insert into Archivos (IDTipo,IDUsuario,Nombre,FechaCreacion, Tamaño, Estado)
values (4, 4, 'Archivo 2', '2019-05-01', 400, 1)

-- Prueba 3 Con usuario tipo Free y archivo tipo Lara File OK

insert into Archivos (IDTipo,IDUsuario,Nombre,FechaCreacion, Tamaño, Estado)
values (4, 4, 'Archivo 2', '2019-05-01', 300, 1)

-- 

Go
Alter trigger TR_VALIDACION_ARCHIVOS
on Archivos
instead of insert
as
begin

declare @idUsuario int
declare @idTipoCuenta int
declare @idTipoArchivo int
declare @espacio float
declare @disponible float
declare @tamaño float

select @idUsuario = IDUsuario from inserted
select @idTipoCuenta = IDTipo from Usuarios where ID = @idUsuario
select @idTipoArchivo = IDTipo from inserted
select @espacio = Espacio from Usuarios where ID = @idUsuario
select @tamaño = Tamaño from inserted


declare @sumaArchivos float
select @sumaArchivos = sum(a.Tamaño) from Archivos a where a.IDUsuario = @idUsuario and a.Estado = 1

set @disponible = @espacio - @sumaArchivos

if(@tamaño <= @disponible)
begin

	if(@idTipoArchivo = (Select ID from TiposArchivo where Descripcion = 'Lara File') or @idTipoArchivo = (Select ID from TiposArchivo where Descripcion = 'Kloster File') AND @idTipoCuenta = (Select ID from TiposCuenta where Descripcion = 'Free'))
	begin 
		set @tamaño = @tamaño * 2
	end
	
		if(@tamaño <= @disponible)
		begin
			insert into Archivos (IDTipo,IDUsuario,Nombre,FechaCreacion, Tamaño, Estado)
			select IDTipo, IDUsuario, Nombre, FechaCreacion, Tamaño, Estado from inserted
			return
			
		end
		else
		begin
			raiserror('No hay espacio suficiente para almacenar el archivo Recuerde que los archivos de su estilo pesan el doble', 16, 1)
		end
	end
	if(@idTipoCuenta = (Select ID from TiposCuenta where Descripcion like 'Free'))
		begin
			if(@tamaño > 1000)
			begin
			raiserror('No se puede almacenar un archivo + de 1000MB con tipo de cuenta free', 16, 1)
			end
		end
else
	begin

	raiserror('No hay espacio suficiente para almacenar el archivo', 16, 1)
	end
	
insert into Archivos (IDTipo,IDUsuario,Nombre,FechaCreacion, Tamaño, Estado)
select IDTipo, IDUsuario, Nombre, FechaCreacion, Tamaño, Estado from inserted

end



	
		