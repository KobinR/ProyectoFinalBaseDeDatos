	USE Centro_Medico
	GO

alter table AUDITORIA alter column ID_USUARIO int null
alter table AUDITORIA add USUARIO_SQL varchar(100) null
/*  CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) es para el ID_Usuario de los trigger cuando tengamos lo de python */

 /* 1. tipo de tabla 'TVP'     permitir poner varias cosas en lo de valor nuevo/viejo pero con lo de python       drop type TipoAuditoria;*/ 

 /*App < Trigger < tvp < SP*/
 /*el trigger detecta el evento, manda la info al tvp 'tipoauditoria' para permitir que muestren varios datos por medio de @Aud*/
 /*el sp recibe el @Aud lleno y lo guarda en @registros*/

create type TipoAuditoria as table
(
    ID_USUARIO         int           null,
    USUARIO_SQL        Varchar (100) null,
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

    Insert into AUDITORIA (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, FECHA, HORA, VALOR_ANTERIOR, VALOR_NUEVO, IP_EQUIPO)
    Select
        ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, CAST(GETDATE() as date), CAST(GETDATE() as time), VALOR_ANTERIOR, VALOR_NUEVO, CAST (CONNECTIONPROPERTY('client_net_address') as varchar(50))    
    from @Registros;
end;
go
/*-----------------------------------------------*/

Create procedure SP_BuscarPersona /*Buscador de personas*/
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

exec SP_BuscarPersona @filtro = 'Esteban';

/*-----------------------------------------------*/

Create procedure SP_HistorialPaciente
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

Create procedure SP_MedicamentosPorVencer 
    @DiasLimite int
as
begin
    select i.ID_INVENTARIO, m.NOMBRE, i.LOTE, i.FECHA_VENCIMIENTO, i.CANTIDAD, DATEDIFF(DAY, GETDATE(), i.FECHA_VENCIMIENTO) AS DiasParaVencer
    from INVENTARIO i
    inner join MEDICAMENTO m on m.ID_MEDICAMENTO = i.ID_MEDICAMENTO
    where i.FECHA_VENCIMIENTO <= DATEADD(DAY, @DiasLimite, GETDATE())
    order by i.FECHA_VENCIMIENTO asc;
end;

exec SP_MedicamentosPorVencer @DiasLimite = 1000
/*------------------------------------------------*/
select * from PACIENTE
Create procedure SP_PacientesPorSeguro
    @SeguroMedico varchar(50)
as
begin
    select p.ID_PERSONA, p.CEDULA, p.NOMBRE, p.PRIMER_APELLIDO, p.SEGUNDO_APELLIDO, pac.ID_PACIENTE, pac.SEGURO_MEDICO, pac.TIPO_SANGRE
    from PACIENTE pac
    inner join PERSONA p ON p.ID_PERSONA = pac.ID_PERSONA
    where pac.SEGURO_MEDICO = @SeguroMedico
    order by p.PRIMER_APELLIDO;
end;

exec SP_PacientesPorSeguro @SeguroMedico = 'CCSS'

/*------------------------------------------------*/

Create procedure SP_ContarConsultaPorPaciente /*Cantidad de consultas que tiene un paciente*/
    @Cedula varchar(20)
as
begin
    select p.CEDULA, p.NOMBRE, p.PRIMER_APELLIDO, COUNT(c.ID_CONSULTA) AS TotalConsultas
    from PERSONA p
    inner join PACIENTE pac on pac.ID_PERSONA  = p.ID_PERSONA
    inner join EXPEDIENTE e on e.ID_PACIENTE   = pac.ID_PACIENTE
    inner join CONSULTA c on c.ID_EXPEDIENTE = e.ID_EXPEDIENTE
    where p.CEDULA = @Cedula
    group by p.CEDULA, p.NOMBRE, p.PRIMER_APELLIDO;
end;

select * from PACIENTE
select * from PERSONA

/*------------------------------------------------*/

Create procedure SP_CambiarEstadoPersona
    @ID_Persona int,
    @Estado     bit
as
begin
    if not exists (select 1 from PERSONA where ID_PERSONA = @ID_Persona)
    begin
        RAISERROR('La persona indicada no existe.',16,1);
        return;
    end
    update PERSONA set ESTADO = @Estado where ID_PERSONA = @ID_Persona;
end
/*------------------------------------------------*/
Create procedure SP_CancelarReceta
    @ID_Receta int
as
begin
    if not exists (select 1 from RECETA where ID_RECETA = @ID_Receta and ESTADO = 'PENDIENTE') /*PENDIENTE*/
    begin
        RAISERROR('Solo se pueden cancelar recetas pendientes.', 16, 1);
        return;
    end
    update RECETA set ESTADO = 'CANCELADA' where ID_RECETA = @ID_Receta; /*CANCELADA*/
end

select * from RECETA
select * from DETALLE_RECETA
select * from AUDITORIA
/*------------------------------------------------*/
Create procedure SP_UltimoAccesoUsuario
    @Usuario varchar(50)
as
begin
    select u.ID_USUARIO, u.USUARIO, u.ULTIMO_ACCESO, u.ESTADO,p.NOMBRE + ' ' + p.PRIMER_APELLIDO AS NombreEmpleado
    from USUARIO u
    inner join EMPLEADO e ON e.ID_EMPLEADO = u.ID_EMPLEADO
    inner join PERSONA p    ON p.ID_PERSONA    = e.ID_PERSONA
    where u.USUARIO = @Usuario
    order by u.ULTIMO_ACCESO desc;
end;
select * from USUARIO
/*------------------------------------------------*/

/* 3. Triggers


------------------ Persona ---------------- */ 
Create Trigger TR_Persona_Insert on PERSONA after insert as
begin

    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end , 'PERSONA', i.ID_PERSONA, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
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
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'PERSONA', i.ID_PERSONA, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_PERSONA = i.ID_PERSONA;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Persona_Delete on PERSONA after delete as
Begin

    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'PERSONA', d.ID_PERSONA, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

delete PERSONA where ID_PERSONA = 39

/*---------------- Paciente ----------------*/


Create Trigger TR_Paciente_Insert on PACIENTE after insert as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'PACIENTE', i.ID_PACIENTE, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Paciente_Update on PACIENTE after update as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'PACIENTE', i.ID_PACIENTE, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_PACIENTE = i.ID_PACIENTE;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go


Create Trigger TR_Paciente_Delete on PACIENTE after delete as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL , TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'PACIENTE', d.ID_PACIENTE, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

/*---------------- Consulta ----------------*/

Create Trigger TR_Consulta_Insert on CONSULTA after insert as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'CONSULTA', i.ID_CONSULTA, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_Consulta_Update on Consulta after update as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL , TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'CONSULTA', i.ID_CONSULTA, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_CONSULTA = i.ID_CONSULTA;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Consulta_Delete on Consulta after delete as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL , TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'CONSULTA', d.ID_CONSULTA, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Receta ----------------*/

Create Trigger TR_Receta_Insert on RECETA after insert as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'RECETA', i.ID_RECETA, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_Receta_Update on RECETA after update as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'RECETA', i.ID_RECETA, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_RECETA = i.ID_RECETA;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Receta_Delete on RECETA after delete as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'RECETA', d.ID_RECETA, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Detalle Receta  ----------------*/

Create Trigger TR_DetalleReceta_Insert on DETALLE_RECETA after insert as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'DETALLE_RECETA', i.ID_DETALLE, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_DetalleReceta_Update on DETALLE_RECETA after update as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'DETALLE_RECETA', i.ID_DETALLE, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_DETALLE = i.ID_DETALLE;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_DetalleReceta_Delete on DETALLE_RECETA after delete as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion, case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'DETALLE_RECETA', d.ID_DETALLE, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Medicamento ----------------*/

Create Trigger TR_MEDICAMENTO_Insert on MEDICAMENTO after insert as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'MEDICAMENTO', i.ID_MEDICAMENTO, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_MEDICAMENTO_Update on MEDICAMENTO after update as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'MEDICAMENTO', i.ID_MEDICAMENTO, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_MEDICAMENTO = i.ID_MEDICAMENTO;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_MEDICAMENTO_Delete on MEDICAMENTO after delete as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'MEDICAMENTO', d.ID_MEDICAMENTO, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Inventario ----------------*/

Create Trigger TR_INVENTARIO_Insert on INVENTARIO after insert as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'INVENTARIO', i.ID_INVENTARIO, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_INVENTARIO_Update on INVENTARIO after update as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion, case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'INVENTARIO', i.ID_INVENTARIO, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_INVENTARIO = i.ID_INVENTARIO;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_INVENTARIO_Delete on INVENTARIO after delete as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'INVENTARIO', d.ID_INVENTARIO, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Empleado ----------------*/

Create Trigger TR_EMPLEADO_Insert on EMPLEADO after insert as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'EMPLEADO', i.ID_EMPLEADO , 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_EMPLEADO_Update on EMPLEADO after update as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'EMPLEADO', i.ID_EMPLEADO, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_EMPLEADO = i.ID_EMPLEADO;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_EMPLEADO_Delete on EMPLEADO after delete as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'EMPLEADO', d.ID_EMPLEADO, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- Expediente ----------------*/

Create Trigger TR_Expediente_Insert on EXPEDIENTE after insert as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion, case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'EXPEDIENTE', i.ID_EXPEDIENTE, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Expediente_Update on EXPEDIENTE after update as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion, case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'EXPEDIENTE', i.ID_EXPEDIENTE, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i
    Inner join deleted d on d.ID_EXPEDIENTE = i.ID_EXPEDIENTE;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Expediente_Delete on EXPEDIENTE after delete as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion, case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'EXPEDIENTE', d.ID_EXPEDIENTE, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go


/*---------------- Usuario ----------------*/

Create Trigger TR_Usuario_Insert on Usuario after insert as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'USUARIO', i.ID_USUARIO, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_Usuario_Update on Usuario after update as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL , TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'USUARIO', i.ID_USUARIO, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_USUARIO = i.ID_USUARIO;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Usuario_Delete on Usuario after delete as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'USUARIO', d.ID_USUARIO, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*---------------- mEDICO ----------------*/

Create Trigger TR_Medico_Insert on Medico after insert as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'MEDICO', i.ID_MEDICO, 'INSERT', NULL, (select i.* for json path, WITHOUT_ARRAY_WRAPPER)
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
GO

Create Trigger TR_Medico_Update on Medico after update as
begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO,USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'MEDICO', i.ID_MEDICO, 'UPDATE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), (select i.* for json path, WITHOUT_ARRAY_WRAPPER) 
    From inserted i
    Inner join deleted d on d.ID_MEDICO = i.ID_MEDICO;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

Create Trigger TR_Medico_Delete on Medico after delete as
Begin
    Declare @Aud TipoAuditoria;
    Declare @IdUsuarioSesion int = cast(Session_context(N'ID_USUARIO') as int)
    Insert into @Aud (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select @IdUsuarioSesion , case when @IdUsuarioSesion is null then CURRENT_USER else null end, 'MEDICO', d.ID_MEDICO, 'DELETE', (select d.* for json path, WITHOUT_ARRAY_WRAPPER), NULL 
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

/*------------------------------------------------*/

/* 4. Vistas */

Create view Vista_PacientesActivos as
select p.ID_PERSONA, p.CEDULA, p.NOMBRE, p.PRIMER_APELLIDO, p.SEGUNDO_APELLIDO,p.TELEFONO, p.CORREO, pac.ID_PACIENTE, pac.TIPO_SANGRE, pac.SEGURO_MEDICO, pac.NOMBRE_CONTACTO, pac.TELEFONO_CONTACTO, pac.PARENTESCO, pac.FECHA_REGISTRO

from PERSONA p
INNER JOIN PACIENTE pac on pac.ID_PERSONA = p.ID_PERSONA
where p.ESTADO = 1;

select * from Vista_PacientesActivos

/*------------------------------------------------*/

Create view Vista_RecetasPendientes as
Select r.ID_RECETA, r.FECHA, r.ESTADO, p.NOMBRE + ' ' + p.PRIMER_APELLIDO  as Paciente, pm.NOMBRE + ' ' + pm.PRIMER_APELLIDO as Medico
    
from RECETA r
inner join CONSULTA c on c.ID_CONSULTA   = r.ID_CONSULTA
inner join EXPEDIENTE e on e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
inner join PACIENTE pac on pac.ID_PACIENTE = e.ID_PACIENTE
inner join PERSONA p on p.ID_PERSONA = pac.ID_PERSONA
inner join MEDICO m  on m.ID_MEDICO = c.ID_MEDICO
inner join EMPLEADO emp on emp.ID_EMPLEADO = m.ID_EMPLEADO
inner join PERSONA pm  on pm.ID_PERSONA   = emp.ID_PERSONA
where r.ESTADO = 'PENDIENTE';

select * from Vista_RecetasPendientes

/*------------------------------------------------*/

Create view Vista_ResumenInventario as
select m.ID_MEDICAMENTO, m.NOMBRE, m.PRESENTACION, SUM(inv.CANTIDAD) as StockTotal, MAX(inv.STOCK_MINIMO) as StockMinimoReferencia, case when SUM(inv.CANTIDAD) < MAX(inv.STOCK_MINIMO) then 'Bajo' else 'Normal' end as Estado   
from MEDICAMENTO m
inner join INVENTARIO inv on inv.ID_MEDICAMENTO = m.ID_MEDICAMENTO
group by m.ID_MEDICAMENTO, m.NOMBRE, m.PRESENTACION

Select * from Vista_ResumenInventario

/*------------------------------------------------*/

create view Vista_HistorialConsultas as
select c.ID_CONSULTA, c.FECHA, c.MOTIVO, c.DIAGNOSTICO, c.TRATAMIENTO, c.OBSERVACIONES, p.CEDULA as CedulaPaciente, p.NOMBRE + ' ' + p.PRIMER_APELLIDO as Paciente, pm.NOMBRE + ' ' + pm.PRIMER_APELLIDO as Medico, m.ESPECIALIDAD
  
from CONSULTA c
inner join EXPEDIENTE e on e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
inner join PACIENTE pac on pac.ID_PACIENTE = e.ID_PACIENTE
inner join PERSONA p on p.ID_PERSONA = pac.ID_PERSONA
inner join MEDICO m on m.ID_MEDICO = c.ID_MEDICO
inner join EMPLEADO emp on emp.ID_EMPLEADO = m.ID_EMPLEADO
inner join PERSONA pm on pm.ID_PERSONA = emp.ID_PERSONA

select * from Vista_HistorialConsultas

/*------------------------------------------------*/

create view Vista_EmpleadosActivos as
select e.ID_EMPLEADO, p.CEDULA, p.NOMBRE, p.PRIMER_APELLIDO, p.SEGUNDO_APELLIDO, e.PUESTO, e.FECHA_INGRESO, e.SALARIO, e.ESTADO_LABORAL
from EMPLEADO e
inner join PERSONA p on p.ID_PERSONA = e.ID_PERSONA
where e.ESTADO_LABORAL = 'Activo'

select * from Vista_EmpleadosActivos

/*------------------------------------------------*/

Create view Vista_MedicamentosPorVencer as /*en los siguientes 90 dias*/
select i.ID_INVENTARIO, m.NOMBRE, i.LOTE, i.FECHA_VENCIMIENTO, i.CANTIDAD, DATEDIFF(DAY, GETDATE(), i.FECHA_VENCIMIENTO) AS DiasParaVencer
from INVENTARIO i
inner join MEDICAMENTO m ON m.ID_MEDICAMENTO = i.ID_MEDICAMENTO
where i.FECHA_VENCIMIENTO <= DATEADD(DAY, 90, GETDATE())

Select * from Vista_MedicamentosPorVencer

/*-------------------------------------------------*/

Create view Vista_DetalleRecetaCompleto as
Select r.ID_RECETA, r.FECHA as FechaReceta, r.ESTADO as EstadoReceta, p.NOMBRE + ' ' + p.PRIMER_APELLIDO as Paciente, dr.ID_DETALLE, m.NOMBRE as Medicamento, dr.CANTIDAD, dr.DOSIS, dr.FRECUENCIA, dr.DURACION, dr.PRECIO_ASIGNADO

from RECETA r
inner join DETALLE_RECETA dr on dr.ID_RECETA = r.ID_RECETA
inner join MEDICAMENTO m on m.ID_MEDICAMENTO = dr.ID_MEDICAMENTO
inner join CONSULTA c on c.ID_CONSULTA = r.ID_CONSULTA
inner join EXPEDIENTE e on e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
inner join PACIENTE pac on pac.ID_PACIENTE = e.ID_PACIENTE
inner join PERSONA p on p.ID_PERSONA = pac.ID_PERSONA

Select * from Vista_DetalleRecetaCompleto

/*-------------------------------------------*/

Create View Vista_AuditoriaLegible as
select a.ID_AUDITORIA, u.USUARIO as UsuarioResponsable, a.TABLA_AFECTADA, a.REGISTRO_AFECTADO, a.ACCION, a.FECHA, a.HORA, a.IP_EQUIPO, a.VALOR_ANTERIOR, a.VALOR_NUEVO
from AUDITORIA a
inner join USUARIO u on u.ID_USUARIO = a.ID_USUARIO

Select * from Vista_AuditoriaLegible

/*------------------------------------------------*/

Create view Vista_MedicosDisponibles as
select m.ID_MEDICO, p.NOMBRE + ' ' + p.PRIMER_APELLIDO as Medico, m.ESPECIALIDAD, m.CONSULTORIO, m.CODIGO_COLEGIADO
from MEDICO m
inner join EMPLEADO e on e.ID_EMPLEADO = m.ID_EMPLEADO
inner join PERSONA p on p.ID_PERSONA = e.ID_PERSONA
where e.ESTADO_LABORAL = 'Activo'

Select * from Vista_MedicosDisponibles

/*---------------------------------------------*/

Create view Vista_PacientesSinSeguro as
Select p.ID_PERSONA, p.CEDULA, p.NOMBRE, p.PRIMER_APELLIDO, pac.ID_PACIENTE, pac.SEGURO_MEDICO
from PACIENTE pac
inner join PERSONA p on p.ID_PERSONA = pac.ID_PERSONA
where pac.SEGURO_MEDICO is null or pac.SEGURO_MEDICO = 'Ninguno'

select * from Vista_PacientesSinSeguro

/*=======
delete PERSONA where ID_PERSONA = 34*/



/*
====================================Cálculos y Funciones========================================

10 cálculos o funciones para cumplir con las necesidades operativas del negocio.

*/

-- ----------------------------------------------------------
-- 1. Funcion_EdadPersona
-- Calcula la edad actual (en años cumplidos) de una persona a partir de su fecha de nacimiento. 

CREATE FUNCTION Funcion_EdadPersona (@ID_PERSONA INT)
RETURNS INT
AS
	BEGIN
		DECLARE @Edad INT;
		SELECT @Edad = DATEDIFF(YEAR, FECHA_NACIMIENTO, GETDATE()) --Agarra la diferencia entre el año de nacimiento y la fecha de hoy para le edad
		- CASE
			WHEN (MONTH(FECHA_NACIMIENTO) > MONTH(GETDATE())) --depende de eso, 
			OR (MONTH(FECHA_NACIMIENTO) = MONTH(GETDATE())
			AND DAY(FECHA_NACIMIENTO) > DAY(GETDATE()))
			THEN 1 ELSE 0
			END
		FROM PERSONA
		WHERE ID_PERSONA = @ID_PERSONA;
		RETURN @Edad;
	END;
GO
--para llamarlo, usa id persona 
SELECT dbo.Funcion_EdadPersona(2) as [Edad Actual];


-- 2. Funcion_AntiguedadEmpleado
-- Calcula los años completos de servicio de un empleado, de esta manera podemos calcular beneficios a obtener

CREATE FUNCTION Funcion_AntiguedadEmpleado (@ID_EMPLEADO INT)
RETURNS INT
AS
	BEGIN
		DECLARE @Antiguedad INT;
		SELECT @Antiguedad = DATEDIFF(YEAR, FECHA_INGRESO, GETDATE())
			- CASE
			WHEN (MONTH(FECHA_INGRESO) > MONTH(GETDATE()))
			OR (MONTH(FECHA_INGRESO) = MONTH(GETDATE())
			AND DAY(FECHA_INGRESO) > DAY(GETDATE()))
			THEN 1 ELSE 0
			END
		FROM EMPLEADO
		WHERE ID_EMPLEADO = @ID_EMPLEADO;
		RETURN @Antiguedad;
	END;
GO

--para llamarlo, se le asigna un id de empleado

SELECT dbo.Funcion_AntiguedadEmpleado(5);

-- 3. Funcion_PrecioConIVA
-- Aplica el 13% de IVA a un precio base. Es una pieza reutilizable por si se quiere calcular el IVA con otros calculos
------------------------------------------------------------
CREATE FUNCTION Funcion_PrecioConIVA (@Precio DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
	BEGIN
		RETURN ROUND(@Precio * 1.13, 2);
	END;
GO
--para llamarlo, se asigna un precio
SELECT dbo.Funcion_PrecioConIVA(1000.00);

-- 4. Funcion_TotalDetalleReceta
-- Calcula el subtotal de una linea de DETALLE_RECETA (cantidad * precio asignado al momento de la venta).

CREATE FUNCTION Funcion_TotalDetalleReceta (@ID_DETALLE INT)
RETURNS DECIMAL(10,2)
AS
	BEGIN
		DECLARE @Total DECIMAL(10,2);
		SELECT @Total = CANTIDAD * PRECIO_ASIGNADO
		FROM DETALLE_RECETA
		WHERE ID_DETALLE = @ID_DETALLE;
		RETURN @Total;
	END;
GO

--llamarlo se le debe proporcionar el id detalle

SELECT dbo.Funcion_TotalDetalleReceta(6)

-- 5. Funcion_Vencimiento
-- Calcula cuantos dias faltan para que venza un lote de inventario. Un numero negativo significa que ya vencio.

CREATE FUNCTION Funcion_Vencimiento (@ID_INVENTARIO INT)
RETURNS INT
AS
	BEGIN
		DECLARE @Dias INT;
		SELECT @Dias = DATEDIFF(DAY, GETDATE(), FECHA_VENCIMIENTO)
		FROM INVENTARIO
		WHERE ID_INVENTARIO = @ID_INVENTARIO;
		RETURN @Dias;
	END;
GO

--se manda el ID del inventario, o sea del item

SELECT dbo.Funcion_Vencimiento(4);

-- 6. Funcion_MedicinaDisponible
-- Suma la cantidad total disponible de un medicamento sumando todos sus lotes del inventario. Sirve para saber cuanto hay en existencia 

CREATE FUNCTION Funcion_MedicinaDisponible (@ID_MEDICAMENTO INT)
RETURNS INT
AS
	BEGIN
		DECLARE @Stock INT;
		SELECT @Stock = SUM(CANTIDAD)
		FROM INVENTARIO
		WHERE ID_MEDICAMENTO = @ID_MEDICAMENTO;
		RETURN ISNULL(@Stock, 0);
	END;
GO
--le enviamos el ID del medicamento para el calculo
SELECT dbo.Funcion_MedicinaDisponible(9)


-- 7. Funcion_TotalConsultas
-- Cuenta cuantas consultas atendio un medico dentro de un rango de fechas.

CREATE FUNCTION Funcion_TotalConsultas(
    @ID_MEDICO INT,
    @FechaInicio DATE,
    @FechaFin DATE
)
RETURNS INT
AS
	BEGIN
		DECLARE @Total INT;
		SELECT @Total = COUNT(*)
		FROM CONSULTA
		WHERE ID_MEDICO = @ID_MEDICO AND FECHA BETWEEN @FechaInicio AND @FechaFin;
		RETURN ISNULL(@Total, 0);
	END;
GO

--recibe 3 parametros distintos, id, y el rango de fechas

SELECT dbo.Funcion_TotalConsultas(1, '2026-01-01', '2026-12-31');



-- 8. Funcion_NombreCompleto
-- nombre y apellidos de una persona en un solo texto.

CREATE FUNCTION Funcion_NombreCompleto(@ID_PERSONA INT)
RETURNS VARCHAR(100)
AS
	BEGIN
		DECLARE @NombreCompleto VARCHAR(100);
		SELECT @NombreCompleto = NOMBRE + ' ' + PRIMER_APELLIDO + ISNULL(' ' + SEGUNDO_APELLIDO, '')
		FROM PERSONA
		WHERE ID_PERSONA = @ID_PERSONA;
		RETURN @NombreCompleto;
	END;
GO

--para llamarlo unicamente se llama el id

SELECT dbo.Funcion_NombreCompleto(16)

-- 9. Funcion_TotalInventario
-- Suma el valor monetario del inventario. Podria funcionar para reportes financieros

CREATE FUNCTION Funcion_TotalInventario ()
RETURNS DECIMAL(12,2)
AS
	BEGIN
		DECLARE @ValorTotal DECIMAL(12,2);
		SELECT @ValorTotal = SUM(i.CANTIDAD * m.PRECIO)
		FROM INVENTARIO i
		INNER JOIN MEDICAMENTO m ON m.ID_MEDICAMENTO = i.ID_MEDICAMENTO;
		RETURN ISNULL(@ValorTotal, 0);
	END;
GO

--este no recibe parametros, es un calculo del total de lo que tenemos

SELECT dbo.Funcion_TotalInventario()


-- 10. Funcion_TotalPacientesAtendidosxMedico
--conta a las personas que ha podido atender el medico, no por consulta, son las personas

CREATE FUNCTION Funcion_TotalPacientesAtendidosxMedico (@ID_MEDICO INT)
RETURNS INT
	AS
	BEGIN
		DECLARE @Total INT;
			SELECT @Total = COUNT(DISTINCT e.ID_PACIENTE)
			FROM CONSULTA c
			INNER JOIN EXPEDIENTE e ON e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
			WHERE c.ID_MEDICO = @ID_MEDICO;
		RETURN ISNULL(@Total, 0);
	END;
GO

--para llamar, se manda id medico

SELECT dbo.Funcion_TotalPacientesAtendidosxMedico(2) as [Pacientes Atendidos]