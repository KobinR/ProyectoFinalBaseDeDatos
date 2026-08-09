/*  CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) es para el ID_Usuario de los trigger cuando tengamos lo de python */

 /* 1. tipo de tabla 'TVP'     disque para permitir poner varias cosas en lo de valor nuevo/viejo pero con lo de python       drop type TipoAuditoria;*/ 

 /*App < Trigger < tvp < SP*/
 /*el trigger detecta el evento, manda la info al tvp 'tipoauditoria' para permitir que muestren varios datos por medio de @Aud*/
 /*el sp recibe el @Aud lleno y lo guarda en @registros*/

create type TipoAuditoria as table
(
    ID_USUARIO         int           null,
    TABLA_AFECTADA     Varchar(50)   not null,
    REGISTRO_AFECTADO  int           not null,
    ACCION             Varchar(10)   not null,
    VALOR_ANTERIOR     Varchar(max)  null,
    VALOR_NUEVO        Varchar(max)  null
);
go


/*2. Procedimiento almacenado*/ 

Create Procedure SP_RegistrarAuditoria /*Sp para no repetir codigo en los triggers*/
    @Registros TipoAuditoria readonly
as
begin

    Insert into AUDITORIA (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, FECHA, HORA, VALOR_ANTERIOR, VALOR_NUEVO, IP_EQUIPO)
    Select
        ID_USUARIO,
        TABLA_AFECTADA,
        REGISTRO_AFECTADO,
        ACCION,
        CAST(GETDATE() as date),
        CAST(GETDATE() as time),
        VALOR_ANTERIOR,
        VALOR_NUEVO,
        CAST (CONNECTIONPROPERTY('client_net_address') as varchar(50))
    from @Registros;
end;
go
/*-----------------------------------------------*/

alter procedure SP_BuscarPersona /*Buscador de personas*/
    @filtro varchar(100)
as
begin

    select ID_PERSONA, CEDULA, NOMBRE, PRIMER_APELLIDO, SEGUNDO_APELLIDO, FECHA_NACIMIENTO, SEXO, TELEFONO, CORREO, DIRECCION, ESTADO
    from PERSONA
    where @filtro is null or CEDULA like '%' + @filtro + '%' or /**/
    NOMBRE like '%' + @filtro + '%' or
    PRIMER_APELLIDO like '%' + @filtro + '%' or
    SEGUNDO_APELLIDO like '%' + @filtro + '%'

order by ID_PERSONA desc;
end;

EXEC SP_BuscarPersona @filtro = 'Esteban';

/*-----------------------------------------------*/

Alter procedure SP_HistorialPaciente
    @Cedula varchar(20)
 as 
 begin
    select c.ID_CONSULTA, c.FECHA, c.MOTIVO, c.DIAGNOSTICO, c.TRATAMIENTO, c.OBSERVACIONES,pm.NOMBRE+ ' '+ pm.PRIMER_APELLIDO as Medico, m.ESPECIALIDAD
    from PERSONA p
    inner join PACIENTE pac on pac.ID_PERSONA = p.ID_PERSONA
    inner join EXPEDIENTE e on e.ID_PACIENTE = pac.ID_PACIENTE
    inner join CONSULTA c on c.ID_EXPEDIENTE = e.ID_EXPEDIENTE
    inner join MEDICO m on m.ID_MEDICO = c.ID_MEDICO
    inner join EMPLEADO emp on emp.ID_EMPLEADO = m.ID_EMPLEADO
    inner join PERSONA pm on pm.ID_PERSONA = emp.ID_PERSONA
    where p.CEDULA = @Cedula
    order by c.FECHA desc
end

exec SP_HistorialPaciente @cedula = '5-3242-5572'

/*-------------------------------*/
select * from CONSULTA
select * from MEDICO
select * from EXPEDIENTE
select * from PACIENTE
create procedure SP_ConsultasMedico /*las fechas pueden estar vacias para tomar todas las consultas del medico*/
@IDMedico int,
@fechaInicio date = null,
@fechaFin date = null
as
begin

    select c.ID_CONSULTA, c.FECHA, c.MOTIVO, c.DIAGNOSTICO, p.NOMBRE+ e.OBSERVACIONES + ' '+ p.PRIMER_APELLIDO as paciente
    from CONSULTA c
    inner join EXPEDIENTE e on e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
    inner join PACIENTE pac on pac.ID_PACIENTE = e.ID_PACIENTE
    inner join PERSONA p    on p.ID_PERSONA    = pac.ID_PERSONA
    where c.ID_MEDICO = @IDMedico
      and (@fechaInicio is null or c.FECHA >= @fechaInicio)
      and (@fechaFin    is null or c.FECHA <= @fechaFin)
    order by c.FECHA desc;
end;

/*-----------------------------------------*/

select * from MEDICAMENTO
select * from INVENTARIO

alter procedure SP_MedicamentosPorVencer 
    @DiasLimite int
as
begin
    select i.ID_INVENTARIO, m.NOMBRE, i.LOTE, i.FECHA_VENCIMIENTO, i.CANTIDAD, DATEDIFF(DAY, GETDATE(), i.FECHA_VENCIMIENTO) AS DiasParaVencer
    from INVENTARIO i
    inner join MEDICAMENTO m on m.ID_MEDICAMENTO = i.ID_MEDICAMENTO
    where i.FECHA_VENCIMIENTO <= DATEADD(DAY, @DiasLimite, GETDATE())
    order by i.FECHA_VENCIMIENTO asc;
end;

exec SP_MedicamentosPorVencer

/* 3. Triggers


------------------ Persona ---------------- */ 
Create Trigger TR_Persona_Insert on PERSONA after insert as
begin

    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) , 'PERSONA', i.ID_PERSONA, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Select * from PERSONA
select * from MEDICAMENTO
select * from DETALLE_RECETA
select * from USUARIO
select * from AUDITORIA
go

Create Trigger TR_Persona_Update on PERSONA after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'PERSONA', i.ID_PERSONA, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_PERSONA = i.ID_PERSONA;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Persona_Delete on PERSONA after delete as
Begin

    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'PERSONA', d.ID_PERSONA, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

delete PERSONA where ID_PERSONA = 34

/*---------------- Paciente ----------------*/


Create Trigger TR_Paciente_Insert on PACIENTE after insert as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) , 'PACIENTE', i.ID_PACIENTE, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_Paciente_Update on PACIENTE after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'PACIENTE', i.ID_PACIENTE, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_PACIENTE = i.ID_PACIENTE;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO


Create Trigger TR_Paciente_Delete on PACIENTE after delete as
Begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'PACIENTE', d.ID_PACIENTE, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

/*---------------- Consulta ----------------*/

Create Trigger TR_Consulta_Insert on CONSULTA after insert as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) , 'CONSULTA', i.ID_CONSULTA, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_Consulta_Update on Consulta after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'CONSULTA', i.ID_CONSULTA, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_CONSULTA = i.ID_CONSULTA;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Consulta_Delete on Consulta after delete as
Begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'CONSULTA', d.ID_CONSULTA, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Receta ----------------*/

Create Trigger TR_Receta_Insert on RECETA after insert as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) , 'RECETA', i.ID_RECETA, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_Receta_Update on RECETA after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'RECETA', i.ID_RECETA, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_RECETA = i.ID_RECETA;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Receta_Delete on RECETA after delete as
Begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'RECETA', d.ID_RECETA, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Detalle Receta  ----------------*/

Create Trigger TR_DetalleReceta_Insert on DETALLE_RECETA after insert as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) , 'DETALLE_RECETA', i.ID_DETALLE, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_DetalleReceta_Update on DETALLE_RECETA after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'DETALLE_RECETA', i.ID_DETALLE, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_DETALLE = i.ID_DETALLE;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_DetalleReceta_Delete on DETALLE_RECETA after delete as
Begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'DETALLE_RECETA', d.ID_DETALLE, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Medicamento ----------------*/

Create Trigger TR_MEDICAMENTO_Insert on MEDICAMENTO after insert as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) , 'MEDICAMENTO', i.ID_MEDICAMENTO, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_MEDICAMENTO_Update on MEDICAMENTO after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'MEDICAMENTO', i.ID_MEDICAMENTO, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_MEDICAMENTO = i.ID_MEDICAMENTO;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_MEDICAMENTO_Delete on MEDICAMENTO after delete as
Begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'MEDICAMENTO', d.ID_MEDICAMENTO, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Inventario ----------------*/

Create Trigger TR_INVENTARIO_Insert on INVENTARIO after insert as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) , 'INVENTARIO', i.ID_INVENTARIO, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_INVENTARIO_Update on INVENTARIO after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'INVENTARIO', i.ID_INVENTARIO, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_INVENTARIO = i.ID_INVENTARIO;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_INVENTARIO_Delete on INVENTARIO after delete as
Begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'INVENTARIO', d.ID_INVENTARIO, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Empleado ----------------*/

Create Trigger TR_EMPLEADO_Insert on EMPLEADO after insert as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) , 'EMPLEADO', i.ID_EMPLEADO , 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_EMPLEADO_Update on EMPLEADO after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'EMPLEADO', i.ID_EMPLEADO, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_EMPLEADO = i.ID_EMPLEADO;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_EMPLEADO_Delete on EMPLEADO after delete as
Begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'EMPLEADO', d.ID_EMPLEADO, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Usuario ----------------*/

Create Trigger TR_Usuario_Insert on Usuario after insert as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) , 'USUARIO', i.ID_USUARIO, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_Usuario_Update on Usuario after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'USUARIO', i.ID_USUARIO, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_USUARIO = i.ID_USUARIO;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Usuario_Delete on Usuario after delete as
Begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'USUARIO', d.ID_USUARIO, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- mEDICO ----------------*/

Create Trigger TR_Medico_Insert on Medico after insert as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) , 'MEDICO', i.ID_MEDICO, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_Medico_Update on Medico after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'MEDICO', i.ID_MEDICO, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_MEDICO = i.ID_MEDICO;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Medico_Delete on Medico after delete as
Begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select CAST(SESSION_CONTEXT(N'ID_USUARIO') as int), 'MEDICO', d.ID_MEDICO, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go