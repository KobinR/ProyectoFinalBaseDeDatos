	USE Centro_Medico
	GO

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



/*
====================================Cálculos y Funciones========================================

10 cálculos o funciones para cumplir con las necesidades operativas del negocio.

*/

-- ----------------------------------------------------------
-- 1. FN_EdadPersona
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

/* no esta terminado!
-- 2. FN_EdadPersona
-- Calcula la edad actual (en años cumplidos) de una persona a partir de su fecha de nacimiento. 
SELECT dr.ID_MEDICAMENTO as ID, 
	   m.NOMBRE as [Nombre Medicamento], 
	   m.PRECIO as[Precio actual], 
	   dr.PRECIO_ASIGNADO as [Precio al momento de la venta], 
	   dr.CANTIDAD as Cantidad, 
	   (dr.CANTIDAD*dr.PRECIO_ASIGNADO) as [Precio Final de la Receta]
FROM DETALLE_RECETA dr
INNER JOIN MEDICAMENTO m on m.ID_MEDICAMENTO=dr.ID_MEDICAMENTO
 --Aca podriamos generar un trigger o un procedimiento almacenado cuyo 
 */



