--1. Hacer con sub consultas -> ¿Cuántos turnos fueron atendidos por la doctora Flavia Rice?

SELECT COUNT(DISTINCT T.IDTurno) AS TurnosAtendidos
FROM Turnos T
WHERE T.IDMEDICO = (SELECT IDMedico
						 FROM Medicos
						 WHERE Nombre = 'Flavia' AND Apellido = 'Rice') 
						
--2. Hacer sub consulta de -> ¿Cuánto tuvo que pagar la consulta el paciente con el turno nro 146?
--Teniendo en cuenta que el paciente debe pagar el costo de la consulta del médico menos lo que cubre la cobertura de la obra social. 
-- La cobertura de la obra social está expresado en un valor decimal entre 0 y 1. Siendo 0 el 0% de cobertura y 1 el 100% de la cobertura.

--Si la cobertura de la obra social es 0.2, entonces el paciente debe pagar el 80% de la consulta.

SELECT (M.COSTO_CONSULTA - (M.COSTO_CONSULTA * O.COBERTURA)) AS PagoPaciente
FROM Turnos T
INNER JOIN Medicos M ON T.IDMedico = M.IDMedico
INNER JOIN Pacientes P ON T.IDPaciente = P.IDPaciente
INNER JOIN OBRAS_SOCIALES O ON P.IDObraSocial = O.IDObraSocial
WHERE T.IDTurno = 146


--3. Hacer sub consulta de -> ¿Cuál es el costo de la consulta promedio de cualquier especialista en "Oftalmología"?

SELECT AVG(M.COSTO_CONSULTA) AS CostoConsultaPromedio
FROM Medicos M
INNER JOIN ESPECIALIDADES E ON M.IDEspecialidad = E.IDEspecialidad
WHERE E.NOMBRE = 'Oftalmología'


--4. Hacer sub consulta de -> ¿Cuántas médicas cobran sus honorarios de consulta un costo mayor a $1000?

SELECT COUNT(*) AS CantMedicas
FROM Medicos M
WHERE  M.SEXO = 'F' AND M.COSTO_CONSULTA > 1000


--5. hacer sub consiulta de -> ¿Cuál es la cantidad de pacientes que no se atendieron en el año 2015?

SELECT COUNT(DISTINCT P.IDPACIENTE) AS CantPacientesNoAtendidos
FROM Pacientes P
Where P.IDPaciente not in (SELECT T.IDPaciente
							FROM Turnos T
							WHERE YEAR(T.FECHAHORA) = 2015)

--6. hacer sub consulta de -> ¿Cuáles son el/los paciente/s que se atendieron más veces? (indistintamente del sexo del paciente)


SELECT  P.IDPaciente, P.NOMBRE, P.APELLIDO, COUNT(*) AS CantTurnos
FROM Turnos T
INNER JOIN Pacientes P ON T.IDPaciente = P.IDPaciente
GROUP BY P.IDPaciente, P.NOMBRE, P.APELLIDO
Order by CantTurnos DESC


SELECT P.IDPaciente, P.NOMBRE, P.APELLIDO, COUNT(*) AS CantTurnos
FROM Turnos T
INNER JOIN Pacientes P ON T.IDPaciente = P.IDPaciente
GROUP BY P.IDPaciente, P.NOMBRE, P.APELLIDO
HAVING COUNT(*) = (SELECT MAX(CantTurnos)
					FROM (SELECT COUNT(*) AS CantTurnos
							FROM Turnos T
							INNER JOIN Pacientes P ON T.IDPaciente = P.IDPaciente
							GROUP BY P.IDPaciente, P.NOMBRE, P.APELLIDO) AS T)



--7. Hacer sub consulta de: ¿Cuál es el apellido del médico (sexo masculino) con más antigüedad de la clínica?

SELECT M.APELLIDO
FROM Medicos M
WHERE M.SEXO = 'M' AND M.FECHAINGRESO = (SELECT MIN(M.FECHAINGRESO)
											FROM Medicos M
											WHERE M.SEXO = 'M')
											
--v2 Arreglarlo
Select M.APELLIDO
From Medicos M
Where M.IDMEDICO = (SELECT Top 1 with ties M.IDMEDICO, MIN(M.FECHAINGRESO) As FechaIngreso
	FROM Medicos M
	WHERE M.SEXO = 'M'
	GROUP BY M.IDMEDICO
	ORDER BY FechaIngreso ASC
)

-- Prueba									
Select * From Medicos 
Where IDMedico = 37
			
--8. Hacer sub consulta de: ¿Cuántos pacientes distintos se atendieron en turnos que duraron más que la duración promedio?

-- Ejemplo hipotético: Si la duración promedio de los turnos fuese 50 minutos. 
-- ¿Cuántos pacientes distintos se atendieron en turnos que duraron más que 50 minutos?

-- OJO SIEMPRE PONER DISTINC O REVISAR POR LAS DUDAS

SELECT COUNT(DISTINCT T.IDPACIENTE) AS CantPacientes
FROM Turnos T
INNER JOIN Pacientes P ON T.IDPaciente = P.IDPaciente
WHERE T.DURACION > ( Select AVG(T.Duracion) As PromedioDuracion From Turnos T)


--Prueba
Select * From Turnos 
Where Duracion > 51
Order by Duracion DESC


--9. ¿Qué Obras Sociales cubren a pacientes que se hayan atendido en algún turno con algún médico de especialidad 'Odontología'?


Select O.NOMBRE
From OBRAS_SOCIALES O
Inner Join PACIENTES P ON O.IDObraSocial = P.IDObraSocial
Inner Join Turnos T ON P.IDPaciente = T.IDPaciente
Inner Join Medicos M ON T.IDMedico = M.IDMedico
inner join ESPECIALIDADES E ON M.IDEspecialidad = E.IDEspecialidad
Where E.Nombre Like 'Odontología'
Group by O.NOMBRE

--V2 
Select O.NOMBRE
From OBRAS_SOCIALES O
Inner Join PACIENTES P ON O.IDObraSocial = P.IDObraSocial
Where P.IDPACIENTE In
(Select IDPACIENTE From 
Turnos t	
Inner Join Medicos M ON T.IDMedico = M.IDMedico
inner join ESPECIALIDADES E ON M.IDEspecialidad = E.IDEspecialidad
Where E.Nombre Like 'Odontología')


--10. ¿Cuántos médicos tienen la especialidad "Gastroenterología" ó "Pediatría"?

SELECT COUNT(DISTINCT M.IDMEDICO) AS CantMedicos
FROM Medicos M
INNER JOIN ESPECIALIDADES E ON M.IDEspecialidad = E.IDEspecialidad
WHERE E.NOMBRE = 'Gastroenterología' OR E.NOMBRE = 'Pediatría'

-- Prueba
Select * From Medicos 
Where IDEspecialidad = 3 OR IDEspecialidad = 4

-----------------
-- Prueba
Select * from Turnos where IDTURNO = 146
-- Medico 42 , paciente 79 
Select * from Medicos where IDMEDICO = 42
-- costo total 505,00
Select * from Pacientes where IDPACIENTE = 79
-- obra social 9 
Select * From OBRAS_SOCIALES where IDOBRASOCIAL  = 9
-- cobertura es 0.60 
--PAGA EL TOTAL DE: 505-(505*0.60)  = 

Select * From ESPECIALIDADES