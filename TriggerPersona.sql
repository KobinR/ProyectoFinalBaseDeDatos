/*  CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) es para el ID_Usuario de los trigger cuando tengamos lo de python */

 /* 1. tipo de tabla 'TVP'     disque para permitir poner varias cosas en lo de valor nuevo/viejo pero con lo de python       drop type TipoAuditoria;*/ 

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

Create Procedure SP_RegistrarAuditoria
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