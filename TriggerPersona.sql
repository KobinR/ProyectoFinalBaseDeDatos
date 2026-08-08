/*  CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) es para el ID_Usuario de los trigger cuando tengamos lo de python */

 /* 1. tipo de tabla 'TVP'     disque para permitir poner varias cosas en lo de valor nuevo/viejo pero con lo de python       drop type TipoAuditoria;*/ 

Create type TipoAuditoria as table
(
    ID_USUARIO         int           null,
    TABLA_AFECTADA     Varchar(50)   not null,
    REGISTRO_AFECTADO  int           not null,
    ACCION             Varchar(10)   not null,
    VALOR_ANTERIOR     Varchar(50)  null,
    VALOR_NUEVO        Varchar(50)  null
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


-- ---------------- Persona ---------------- */ 
Alter Trigger TR_Persona_Insert on PERSONA after insert as
begin

    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    Select 1 , 'PERSONA', i.ID_PERSONA, 'INSERT', NULL, 'INSERT' /*  CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) */
    From inserted i;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go


select * from USUARIO
select * from AUDITORIA
go

Alter Trigger TR_Persona_Update on PERSONA after update as
begin
    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select 2, 'PERSONA', i.ID_PERSONA, 'update', 'Valor Anterior', 'Valor nuevo' /*  CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) */
    From inserted i;
    Exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

alter Trigger TR_Persona_Delete on PERSONA after delete as
Begin

    Declare @Aud TipoAuditoria;
    Insert into @Aud (ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, VALOR_ANTERIOR, VALOR_NUEVO)
    select 3, 'PERSONA', d.ID_PERSONA, 'delete', 'Registro existente', NULL /*  CAST(SESSION_CONTEXT(N'ID_USUARIO') as int) */
    from deleted d;
    exec SP_RegistrarAuditoria @Registros = @Aud;
end;
go

delete PERSONA where ID_PERSONA = 34