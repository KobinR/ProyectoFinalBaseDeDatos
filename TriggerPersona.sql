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