



----------------------Este es el query para la base de datos -------------------------

USE [master]
GO
/****** Object:  Database [Centro_Medico]    Script Date: 11/8/2026 17:18:11 ******/
CREATE DATABASE [Centro_Medico]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Centro_Medico', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\Centro_Medico.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Centro_Medico_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\Centro_Medico_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [Centro_Medico] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Centro_Medico].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Centro_Medico] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Centro_Medico] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Centro_Medico] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Centro_Medico] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Centro_Medico] SET ARITHABORT OFF 
GO
ALTER DATABASE [Centro_Medico] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Centro_Medico] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Centro_Medico] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Centro_Medico] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Centro_Medico] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Centro_Medico] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Centro_Medico] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Centro_Medico] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Centro_Medico] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Centro_Medico] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Centro_Medico] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Centro_Medico] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Centro_Medico] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Centro_Medico] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Centro_Medico] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Centro_Medico] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Centro_Medico] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Centro_Medico] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [Centro_Medico] SET  MULTI_USER 
GO
ALTER DATABASE [Centro_Medico] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Centro_Medico] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Centro_Medico] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Centro_Medico] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [Centro_Medico] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [Centro_Medico] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [Centro_Medico] SET QUERY_STORE = ON
GO
ALTER DATABASE [Centro_Medico] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [Centro_Medico]
GO
/****** Object:  UserDefinedTableType [dbo].[TipoAuditoria]    Script Date: 11/8/2026 17:18:11 ******/
CREATE TYPE [dbo].[TipoAuditoria] AS TABLE(
	[ID_USUARIO] [int] NULL,
	[USUARIO_SQL] [varchar](100) NULL,
	[TABLA_AFECTADA] [varchar](50) NOT NULL,
	[REGISTRO_AFECTADO] [int] NOT NULL,
	[ACCION] [varchar](10) NOT NULL,
	[VALOR_ANTERIOR] [varchar](max) NULL,
	[VALOR_NUEVO] [varchar](max) NULL
)
GO
/****** Object:  UserDefinedFunction [dbo].[Funcion_AntiguedadEmpleado]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Funcion_AntiguedadEmpleado] (@ID_EMPLEADO INT)
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
/****** Object:  UserDefinedFunction [dbo].[Funcion_EdadPersona]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Funcion_EdadPersona] (@ID_PERSONA INT)
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
/****** Object:  UserDefinedFunction [dbo].[Funcion_MedicinaDisponible]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Funcion_MedicinaDisponible] (@ID_MEDICAMENTO INT)
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
/****** Object:  UserDefinedFunction [dbo].[Funcion_NombreCompleto]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Funcion_NombreCompleto](@ID_PERSONA INT)
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
/****** Object:  UserDefinedFunction [dbo].[Funcion_PrecioConIVA]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Funcion_PrecioConIVA] (@Precio DECIMAL(10,2))
RETURNS DECIMAL(10,2)
AS
	BEGIN
		RETURN ROUND(@Precio * 1.13, 2);
	END;
GO
/****** Object:  UserDefinedFunction [dbo].[Funcion_TotalConsultas]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Funcion_TotalConsultas](
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
/****** Object:  UserDefinedFunction [dbo].[Funcion_TotalDetalleReceta]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Funcion_TotalDetalleReceta] (@ID_DETALLE INT)
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
/****** Object:  UserDefinedFunction [dbo].[Funcion_TotalInventario]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Funcion_TotalInventario] ()
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
/****** Object:  UserDefinedFunction [dbo].[Funcion_TotalPacientesAtendidosxMedico]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Funcion_TotalPacientesAtendidosxMedico] (@ID_MEDICO INT)
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
/****** Object:  UserDefinedFunction [dbo].[Funcion_Vencimiento]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Funcion_Vencimiento] (@ID_INVENTARIO INT)
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
/****** Object:  Table [dbo].[PACIENTE]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PACIENTE](
	[ID_PACIENTE] [int] IDENTITY(1,1) NOT NULL,
	[ID_PERSONA] [int] NOT NULL,
	[TIPO_SANGRE] [varchar](5) NULL,
	[SEGURO_MEDICO] [varchar](60) NULL,
	[NOMBRE_CONTACTO] [varchar](100) NULL,
	[TELEFONO_CONTACTO] [varchar](20) NULL,
	[PARENTESCO] [varchar](50) NULL,
	[FECHA_REGISTRO] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_PACIENTE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[ID_PERSONA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PERSONA]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PERSONA](
	[ID_PERSONA] [int] IDENTITY(1,1) NOT NULL,
	[CEDULA] [varchar](20) NOT NULL,
	[NOMBRE] [varchar](50) NOT NULL,
	[PRIMER_APELLIDO] [varchar](50) NOT NULL,
	[SEGUNDO_APELLIDO] [varchar](50) NULL,
	[FECHA_NACIMIENTO] [date] NOT NULL,
	[SEXO] [char](1) NOT NULL,
	[TELEFONO] [varchar](20) NOT NULL,
	[CORREO] [varchar](100) NULL,
	[DIRECCION] [varchar](250) NOT NULL,
	[ESTADO] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_PERSONA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[CEDULA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[CORREO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[Vista_PacientesActivos]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[Vista_PacientesActivos] as
select p.ID_PERSONA, p.CEDULA, p.NOMBRE, p.PRIMER_APELLIDO, p.SEGUNDO_APELLIDO,p.TELEFONO, p.CORREO, pac.ID_PACIENTE, pac.TIPO_SANGRE, pac.SEGURO_MEDICO, pac.NOMBRE_CONTACTO, pac.TELEFONO_CONTACTO, pac.PARENTESCO, pac.FECHA_REGISTRO

from PERSONA p
INNER JOIN PACIENTE pac on pac.ID_PERSONA = p.ID_PERSONA
where p.ESTADO = 1;
GO
/****** Object:  Table [dbo].[CONSULTA]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CONSULTA](
	[ID_CONSULTA] [int] IDENTITY(1,1) NOT NULL,
	[ID_EXPEDIENTE] [int] NOT NULL,
	[ID_MEDICO] [int] NOT NULL,
	[FECHA] [datetime] NOT NULL,
	[MOTIVO] [varchar](300) NOT NULL,
	[DIAGNOSTICO] [varchar](500) NOT NULL,
	[TRATAMIENTO] [varchar](500) NULL,
	[OBSERVACIONES] [varchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_CONSULTA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EMPLEADO]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EMPLEADO](
	[ID_EMPLEADO] [int] IDENTITY(1,1) NOT NULL,
	[ID_PERSONA] [int] NOT NULL,
	[PUESTO] [varchar](50) NOT NULL,
	[FECHA_INGRESO] [date] NOT NULL,
	[SALARIO] [decimal](10, 2) NOT NULL,
	[ESTADO_LABORAL] [varchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_EMPLEADO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[ID_PERSONA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EXPEDIENTE]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EXPEDIENTE](
	[ID_EXPEDIENTE] [int] IDENTITY(1,1) NOT NULL,
	[ID_PACIENTE] [int] NOT NULL,
	[ALERGIAS] [varchar](300) NULL,
	[ENFERMEDADES_CRONICAS] [varchar](300) NULL,
	[ANTECEDENTES] [varchar](500) NULL,
	[OBSERVACIONES] [varchar](500) NULL,
	[FECHA_CREACION] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_EXPEDIENTE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[ID_PACIENTE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MEDICO]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MEDICO](
	[ID_MEDICO] [int] IDENTITY(1,1) NOT NULL,
	[ID_EMPLEADO] [int] NOT NULL,
	[CODIGO_COLEGIADO] [varchar](30) NOT NULL,
	[ESPECIALIDAD] [varchar](80) NOT NULL,
	[CONSULTORIO] [varchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_MEDICO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[CODIGO_COLEGIADO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[ID_EMPLEADO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RECETA]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RECETA](
	[ID_RECETA] [int] IDENTITY(1,1) NOT NULL,
	[ID_CONSULTA] [int] NOT NULL,
	[FECHA] [datetime] NOT NULL,
	[ESTADO] [varchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_RECETA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[ID_CONSULTA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[Vista_RecetasPendientes]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create view [dbo].[Vista_RecetasPendientes] as
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
GO
/****** Object:  Table [dbo].[INVENTARIO]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[INVENTARIO](
	[ID_INVENTARIO] [int] IDENTITY(1,1) NOT NULL,
	[ID_MEDICAMENTO] [int] NOT NULL,
	[LOTE] [varchar](30) NOT NULL,
	[FECHA_INGRESO] [date] NOT NULL,
	[FECHA_VENCIMIENTO] [date] NOT NULL,
	[CANTIDAD] [int] NOT NULL,
	[STOCK_MINIMO] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_INVENTARIO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MEDICAMENTO]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MEDICAMENTO](
	[ID_MEDICAMENTO] [int] IDENTITY(1,1) NOT NULL,
	[NOMBRE] [varchar](100) NOT NULL,
	[DESCRIPCION] [varchar](300) NULL,
	[PRESENTACION] [varchar](80) NOT NULL,
	[CONCENTRACION] [varchar](50) NOT NULL,
	[PRECIO] [decimal](10, 2) NOT NULL,
	[FABRICANTE] [varchar](100) NULL,
	[REQUIERE_RECETA] [bit] NOT NULL,
	[ESTADO] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_MEDICAMENTO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[Vista_ResumenInventario]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create view [dbo].[Vista_ResumenInventario] as
select m.ID_MEDICAMENTO, m.NOMBRE, m.PRESENTACION, SUM(inv.CANTIDAD) as StockTotal, MAX(inv.STOCK_MINIMO) as StockMinimoReferencia, case when SUM(inv.CANTIDAD) < MAX(inv.STOCK_MINIMO) then 'Bajo' else 'Normal' end as Estado   
from MEDICAMENTO m
inner join INVENTARIO inv on inv.ID_MEDICAMENTO = m.ID_MEDICAMENTO
group by m.ID_MEDICAMENTO, m.NOMBRE, m.PRESENTACION
GO
/****** Object:  View [dbo].[Vista_HistorialConsultas]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[Vista_HistorialConsultas] as
select c.ID_CONSULTA, c.FECHA, c.MOTIVO, c.DIAGNOSTICO, c.TRATAMIENTO, c.OBSERVACIONES, p.CEDULA as CedulaPaciente, p.NOMBRE + ' ' + p.PRIMER_APELLIDO as Paciente, pm.NOMBRE + ' ' + pm.PRIMER_APELLIDO as Medico, m.ESPECIALIDAD
  
from CONSULTA c
inner join EXPEDIENTE e on e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
inner join PACIENTE pac on pac.ID_PACIENTE = e.ID_PACIENTE
inner join PERSONA p on p.ID_PERSONA = pac.ID_PERSONA
inner join MEDICO m on m.ID_MEDICO = c.ID_MEDICO
inner join EMPLEADO emp on emp.ID_EMPLEADO = m.ID_EMPLEADO
inner join PERSONA pm on pm.ID_PERSONA = emp.ID_PERSONA
GO
/****** Object:  View [dbo].[Vista_EmpleadosActivos]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[Vista_EmpleadosActivos] as
select e.ID_EMPLEADO, p.CEDULA, p.NOMBRE, p.PRIMER_APELLIDO, p.SEGUNDO_APELLIDO, e.PUESTO, e.FECHA_INGRESO, e.SALARIO, e.ESTADO_LABORAL
from EMPLEADO e
inner join PERSONA p on p.ID_PERSONA = e.ID_PERSONA
where e.ESTADO_LABORAL = 'Activo'
GO
/****** Object:  View [dbo].[Vista_MedicamentosPorVencer]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create view [dbo].[Vista_MedicamentosPorVencer] as /*en los siguientes 90 dias*/
select i.ID_INVENTARIO, m.NOMBRE, i.LOTE, i.FECHA_VENCIMIENTO, i.CANTIDAD, DATEDIFF(DAY, GETDATE(), i.FECHA_VENCIMIENTO) AS DiasParaVencer
from INVENTARIO i
inner join MEDICAMENTO m ON m.ID_MEDICAMENTO = i.ID_MEDICAMENTO
where i.FECHA_VENCIMIENTO <= DATEADD(DAY, 90, GETDATE())
GO
/****** Object:  Table [dbo].[DETALLE_RECETA]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DETALLE_RECETA](
	[ID_DETALLE] [int] IDENTITY(1,1) NOT NULL,
	[ID_RECETA] [int] NOT NULL,
	[ID_MEDICAMENTO] [int] NOT NULL,
	[CANTIDAD] [int] NOT NULL,
	[DOSIS] [varchar](100) NOT NULL,
	[FRECUENCIA] [varchar](100) NOT NULL,
	[DURACION] [varchar](100) NOT NULL,
	[PRECIO_ASIGNADO] [decimal](10, 2) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_DETALLE] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[Vista_DetalleRecetaCompleto]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create view [dbo].[Vista_DetalleRecetaCompleto] as
Select r.ID_RECETA, r.FECHA as FechaReceta, r.ESTADO as EstadoReceta, p.NOMBRE + ' ' + p.PRIMER_APELLIDO as Paciente, dr.ID_DETALLE, m.NOMBRE as Medicamento, dr.CANTIDAD, dr.DOSIS, dr.FRECUENCIA, dr.DURACION, dr.PRECIO_ASIGNADO

from RECETA r
inner join DETALLE_RECETA dr on dr.ID_RECETA = r.ID_RECETA
inner join MEDICAMENTO m on m.ID_MEDICAMENTO = dr.ID_MEDICAMENTO
inner join CONSULTA c on c.ID_CONSULTA = r.ID_CONSULTA
inner join EXPEDIENTE e on e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
inner join PACIENTE pac on pac.ID_PACIENTE = e.ID_PACIENTE
inner join PERSONA p on p.ID_PERSONA = pac.ID_PERSONA
GO
/****** Object:  Table [dbo].[AUDITORIA]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AUDITORIA](
	[ID_AUDITORIA] [int] IDENTITY(1,1) NOT NULL,
	[ID_USUARIO] [int] NULL,
	[TABLA_AFECTADA] [varchar](50) NOT NULL,
	[REGISTRO_AFECTADO] [int] NOT NULL,
	[ACCION] [varchar](10) NOT NULL,
	[FECHA] [date] NOT NULL,
	[HORA] [time](7) NOT NULL,
	[VALOR_ANTERIOR] [varchar](max) NULL,
	[VALOR_NUEVO] [varchar](max) NULL,
	[IP_EQUIPO] [varchar](50) NULL,
	[USUARIO_SQL] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_AUDITORIA] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[USUARIO]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[USUARIO](
	[ID_USUARIO] [int] IDENTITY(1,1) NOT NULL,
	[ID_EMPLEADO] [int] NOT NULL,
	[USUARIO] [varchar](30) NOT NULL,
	[CLAVE_ACCESO] [varchar](100) NOT NULL,
	[ULTIMO_ACCESO] [datetime] NULL,
	[ESTADO] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_USUARIO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[ID_EMPLEADO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[USUARIO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[Vista_AuditoriaLegible]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View [dbo].[Vista_AuditoriaLegible] as
select a.ID_AUDITORIA, u.USUARIO as UsuarioResponsable, a.TABLA_AFECTADA, a.REGISTRO_AFECTADO, a.ACCION, a.FECHA, a.HORA, a.IP_EQUIPO, a.VALOR_ANTERIOR, a.VALOR_NUEVO
from AUDITORIA a
inner join USUARIO u on u.ID_USUARIO = a.ID_USUARIO
GO
/****** Object:  View [dbo].[Vista_MedicosDisponibles]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create view [dbo].[Vista_MedicosDisponibles] as
select m.ID_MEDICO, p.NOMBRE + ' ' + p.PRIMER_APELLIDO as Medico, m.ESPECIALIDAD, m.CONSULTORIO, m.CODIGO_COLEGIADO
from MEDICO m
inner join EMPLEADO e on e.ID_EMPLEADO = m.ID_EMPLEADO
inner join PERSONA p on p.ID_PERSONA = e.ID_PERSONA
where e.ESTADO_LABORAL = 'Activo'
GO
/****** Object:  View [dbo].[Vista_PacientesSinSeguro]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create view [dbo].[Vista_PacientesSinSeguro] as
Select p.ID_PERSONA, p.CEDULA, p.NOMBRE, p.PRIMER_APELLIDO, pac.ID_PACIENTE, pac.SEGURO_MEDICO
from PACIENTE pac
inner join PERSONA p on p.ID_PERSONA = pac.ID_PERSONA
where pac.SEGURO_MEDICO is null or pac.SEGURO_MEDICO = 'Ninguno'
GO
ALTER TABLE [dbo].[AUDITORIA] ADD  DEFAULT (getdate()) FOR [FECHA]
GO
ALTER TABLE [dbo].[AUDITORIA] ADD  DEFAULT (CONVERT([time],getdate())) FOR [HORA]
GO
ALTER TABLE [dbo].[CONSULTA] ADD  DEFAULT (getdate()) FOR [FECHA]
GO
ALTER TABLE [dbo].[EXPEDIENTE] ADD  DEFAULT (getdate()) FOR [FECHA_CREACION]
GO
ALTER TABLE [dbo].[INVENTARIO] ADD  DEFAULT ((10)) FOR [STOCK_MINIMO]
GO
ALTER TABLE [dbo].[MEDICAMENTO] ADD  DEFAULT ((1)) FOR [REQUIERE_RECETA]
GO
ALTER TABLE [dbo].[MEDICAMENTO] ADD  DEFAULT ((1)) FOR [ESTADO]
GO
ALTER TABLE [dbo].[PACIENTE] ADD  DEFAULT (getdate()) FOR [FECHA_REGISTRO]
GO
ALTER TABLE [dbo].[PERSONA] ADD  DEFAULT ((1)) FOR [ESTADO]
GO
ALTER TABLE [dbo].[RECETA] ADD  DEFAULT (getdate()) FOR [FECHA]
GO
ALTER TABLE [dbo].[USUARIO] ADD  DEFAULT ((1)) FOR [ESTADO]
GO
ALTER TABLE [dbo].[AUDITORIA]  WITH CHECK ADD  CONSTRAINT [FK_AUDITORIA_USUARIO] FOREIGN KEY([ID_USUARIO])
REFERENCES [dbo].[USUARIO] ([ID_USUARIO])
GO
ALTER TABLE [dbo].[AUDITORIA] CHECK CONSTRAINT [FK_AUDITORIA_USUARIO]
GO
ALTER TABLE [dbo].[CONSULTA]  WITH CHECK ADD  CONSTRAINT [FK_CONSULTA_EXPEDIENTE] FOREIGN KEY([ID_EXPEDIENTE])
REFERENCES [dbo].[EXPEDIENTE] ([ID_EXPEDIENTE])
GO
ALTER TABLE [dbo].[CONSULTA] CHECK CONSTRAINT [FK_CONSULTA_EXPEDIENTE]
GO
ALTER TABLE [dbo].[CONSULTA]  WITH CHECK ADD  CONSTRAINT [FK_CONSULTA_MEDICO] FOREIGN KEY([ID_MEDICO])
REFERENCES [dbo].[MEDICO] ([ID_MEDICO])
GO
ALTER TABLE [dbo].[CONSULTA] CHECK CONSTRAINT [FK_CONSULTA_MEDICO]
GO
ALTER TABLE [dbo].[DETALLE_RECETA]  WITH CHECK ADD  CONSTRAINT [FK_DETALLE_MEDICAMENTO] FOREIGN KEY([ID_MEDICAMENTO])
REFERENCES [dbo].[MEDICAMENTO] ([ID_MEDICAMENTO])
GO
ALTER TABLE [dbo].[DETALLE_RECETA] CHECK CONSTRAINT [FK_DETALLE_MEDICAMENTO]
GO
ALTER TABLE [dbo].[DETALLE_RECETA]  WITH CHECK ADD  CONSTRAINT [FK_DETALLE_RECETA] FOREIGN KEY([ID_RECETA])
REFERENCES [dbo].[RECETA] ([ID_RECETA])
GO
ALTER TABLE [dbo].[DETALLE_RECETA] CHECK CONSTRAINT [FK_DETALLE_RECETA]
GO
ALTER TABLE [dbo].[EMPLEADO]  WITH CHECK ADD  CONSTRAINT [FK_EMPLEADO_PERSONA] FOREIGN KEY([ID_PERSONA])
REFERENCES [dbo].[PERSONA] ([ID_PERSONA])
GO
ALTER TABLE [dbo].[EMPLEADO] CHECK CONSTRAINT [FK_EMPLEADO_PERSONA]
GO
ALTER TABLE [dbo].[EXPEDIENTE]  WITH CHECK ADD  CONSTRAINT [FK_EXPEDIENTE_PACIENTE] FOREIGN KEY([ID_PACIENTE])
REFERENCES [dbo].[PACIENTE] ([ID_PACIENTE])
GO
ALTER TABLE [dbo].[EXPEDIENTE] CHECK CONSTRAINT [FK_EXPEDIENTE_PACIENTE]
GO
ALTER TABLE [dbo].[INVENTARIO]  WITH CHECK ADD  CONSTRAINT [FK_INVENTARIO_MEDICAMENTO] FOREIGN KEY([ID_MEDICAMENTO])
REFERENCES [dbo].[MEDICAMENTO] ([ID_MEDICAMENTO])
GO
ALTER TABLE [dbo].[INVENTARIO] CHECK CONSTRAINT [FK_INVENTARIO_MEDICAMENTO]
GO
ALTER TABLE [dbo].[MEDICO]  WITH CHECK ADD  CONSTRAINT [FK_MEDICO_EMPLEADO] FOREIGN KEY([ID_EMPLEADO])
REFERENCES [dbo].[EMPLEADO] ([ID_EMPLEADO])
GO
ALTER TABLE [dbo].[MEDICO] CHECK CONSTRAINT [FK_MEDICO_EMPLEADO]
GO
ALTER TABLE [dbo].[PACIENTE]  WITH CHECK ADD  CONSTRAINT [FK_PACIENTE_PERSONA] FOREIGN KEY([ID_PERSONA])
REFERENCES [dbo].[PERSONA] ([ID_PERSONA])
GO
ALTER TABLE [dbo].[PACIENTE] CHECK CONSTRAINT [FK_PACIENTE_PERSONA]
GO
ALTER TABLE [dbo].[RECETA]  WITH CHECK ADD  CONSTRAINT [FK_RECETA_CONSULTA] FOREIGN KEY([ID_CONSULTA])
REFERENCES [dbo].[CONSULTA] ([ID_CONSULTA])
GO
ALTER TABLE [dbo].[RECETA] CHECK CONSTRAINT [FK_RECETA_CONSULTA]
GO
ALTER TABLE [dbo].[USUARIO]  WITH CHECK ADD  CONSTRAINT [FK_USUARIO_EMPLEADO] FOREIGN KEY([ID_EMPLEADO])
REFERENCES [dbo].[EMPLEADO] ([ID_EMPLEADO])
GO
ALTER TABLE [dbo].[USUARIO] CHECK CONSTRAINT [FK_USUARIO_EMPLEADO]
GO
ALTER TABLE [dbo].[AUDITORIA]  WITH CHECK ADD CHECK  (([ACCION]='DELETE' OR [ACCION]='UPDATE' OR [ACCION]='INSERT'))
GO
ALTER TABLE [dbo].[DETALLE_RECETA]  WITH CHECK ADD CHECK  (([CANTIDAD]>(0)))
GO
ALTER TABLE [dbo].[EMPLEADO]  WITH CHECK ADD CHECK  (([ESTADO_LABORAL]='INCAPACITADO' OR [ESTADO_LABORAL]='VACACIONES' OR [ESTADO_LABORAL]='INACTIVO' OR [ESTADO_LABORAL]='ACTIVO'))
GO
ALTER TABLE [dbo].[EMPLEADO]  WITH CHECK ADD CHECK  (([SALARIO]>=(0)))
GO
ALTER TABLE [dbo].[INVENTARIO]  WITH CHECK ADD CHECK  (([CANTIDAD]>=(0)))
GO
ALTER TABLE [dbo].[MEDICAMENTO]  WITH CHECK ADD CHECK  (([PRECIO]>=(0)))
GO
ALTER TABLE [dbo].[PERSONA]  WITH CHECK ADD CHECK  (([SEXO]='F' OR [SEXO]='M'))
GO
ALTER TABLE [dbo].[RECETA]  WITH CHECK ADD CHECK  (([ESTADO]='CANCELADA' OR [ESTADO]='ENTREGADA' OR [ESTADO]='PENDIENTE'))
GO
/****** Object:  StoredProcedure [dbo].[SP_BuscarPersona]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_BuscarPersona] /*Buscador de personas*/
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
GO
/****** Object:  StoredProcedure [dbo].[SP_CambiarEstadoPersona]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_CambiarEstadoPersona]
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
GO
/****** Object:  StoredProcedure [dbo].[SP_CancelarReceta]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_CancelarReceta]
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
GO
/****** Object:  StoredProcedure [dbo].[SP_ConsultasMedico]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_ConsultasMedico] /*las fechas pueden estar vacias para tomar todas las consultas del medico*/
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
GO
/****** Object:  StoredProcedure [dbo].[SP_ContarConsultaPorPaciente]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_ContarConsultaPorPaciente] /*Cantidad de consultas que tiene un paciente*/
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
GO
/****** Object:  StoredProcedure [dbo].[SP_HistorialPaciente]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_HistorialPaciente]
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
GO
/****** Object:  StoredProcedure [dbo].[SP_MedicamentosPorVencer]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_MedicamentosPorVencer] 
    @DiasLimite int
as
begin
    select i.ID_INVENTARIO, m.NOMBRE, i.LOTE, i.FECHA_VENCIMIENTO, i.CANTIDAD, DATEDIFF(DAY, GETDATE(), i.FECHA_VENCIMIENTO) AS DiasParaVencer
    from INVENTARIO i
    inner join MEDICAMENTO m on m.ID_MEDICAMENTO = i.ID_MEDICAMENTO
    where i.FECHA_VENCIMIENTO <= DATEADD(DAY, @DiasLimite, GETDATE())
    order by i.FECHA_VENCIMIENTO asc;
end;
GO
/****** Object:  StoredProcedure [dbo].[SP_PacientesPorSeguro]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_PacientesPorSeguro]
    @SeguroMedico varchar(50)
as
begin
    select p.ID_PERSONA, p.CEDULA, p.NOMBRE, p.PRIMER_APELLIDO, p.SEGUNDO_APELLIDO, pac.ID_PACIENTE, pac.SEGURO_MEDICO, pac.TIPO_SANGRE
    from PACIENTE pac
    inner join PERSONA p ON p.ID_PERSONA = pac.ID_PERSONA
    where pac.SEGURO_MEDICO = @SeguroMedico
    order by p.PRIMER_APELLIDO;
end;
GO
/****** Object:  StoredProcedure [dbo].[SP_RegistrarAuditoria]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_RegistrarAuditoria] /*Sp para no repetir codigo en los triggers*/
    @Registros TipoAuditoria readonly
as
begin

    Insert into AUDITORIA (ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, FECHA, HORA, VALOR_ANTERIOR, VALOR_NUEVO, IP_EQUIPO)
    Select
        ID_USUARIO, USUARIO_SQL, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, CAST(GETDATE() as date), CAST(GETDATE() as time), VALOR_ANTERIOR, VALOR_NUEVO, CAST (CONNECTIONPROPERTY('client_net_address') as varchar(50))    
    from @Registros;
end;
GO
/****** Object:  StoredProcedure [dbo].[SP_UltimoAccesoUsuario]    Script Date: 11/8/2026 17:18:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UltimoAccesoUsuario]
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
GO
USE [master]
GO
ALTER DATABASE [Centro_Medico] SET  READ_WRITE 
GO

/*
Aca procederemos a colocar todo lo que corresponde a la generacion de informacion para la base de datos. A continuacion, para llenar tablas:
*/

SET IDENTITY_INSERT PERSONA ON; --Como estamos asignando ID's, es necesario decirle a SQL que nosotros lo asignamos manualmente

INSERT INTO PERSONA (ID_PERSONA, CEDULA, NOMBRE, PRIMER_APELLIDO, SEGUNDO_APELLIDO, FECHA_NACIMIENTO, SEXO, TELEFONO, CORREO, DIRECCION, ESTADO)
VALUES
(1, '1-1111-1111', 'Ana', 'Rodriguez', 'Solis', '1990-05-14', 'F', '8888-1111', 'ana.rodriguez@correo.com', 'San Jose, Costa Rica', 1),
(2, '2-2222-2222', 'Carlos', 'Jimenez', 'Vargas', '1985-11-02', 'M', '8888-2222', 'carlos.jimenez@correo.com', 'Cartago, Costa Rica', 1),
(3, '3-3333-3333', 'Maria', 'Fernandez', NULL, '1978-03-21', 'F', '8888-3333', 'marfern63@yahoo.com', 'Heredia, Costa Rica', 1),
(4, '4-4444-4444', 'Luis', 'Mora', 'Chacon', '1995-07-30', 'M', '8888-4444', 'luis.mora@correo.com', 'Alajuela, Costa Rica', 1),
(5, '5-5555-5555', 'Sofia', 'Castro', 'Alvarado', '1992-09-10', 'F', '8888-5555', 'sofia.castro@correo.com', 'San Jose, Costa Rica', 1),
(6, '3-5541-5325', 'Bernarda', 'Rodriguez', 'Chaves', '1992-09-10', 'F', '8238-5355', 'berhjasda@gmail.com', 'San Jose, Costa Rica', 1),
(7, '5-3242-5572', 'Guadalupe', 'Ceciliano', 'Alvarado', '1992-09-10', 'F', '8888-5555', 'lupitasjhk321@hotmail.com', 'Puntarenas, Costa Rica', 1),
(8, '4-3456-0793', 'Alberto', 'Gutierrez', 'Ivankovich', '2002-09-10', 'M', '8312-5587', 'albertro@correo.com', 'Guanacaste, Costa Rica', 1),
(9, '7-1231-5786', 'Jesus', 'Tucuman', 'Ramirez', '2005-09-10', 'M', '6547-5125', 'jesustuo@correo.com', 'Limon, Costa Rica', 1),
(10, '4-9279-1434', 'Carlos', 'Tucuman', 'Villalobos', '2000-04-23', 'M', '8818-9928', 'carlostucuman95@yahoo.com', 'Cartago, Costa Rica', 0),
(11, '6-2674-2519', 'Fernanda', 'Chacon', 'Rivera', '1989-02-12', 'F', '7718-5333', 'fernanda_2715@outlook.com', 'Guanacaste, Costa Rica', 1),
(12, '2-1750-4733', 'Elberth', 'Zuniga', 'Ramirez', '1983-02-28', 'M', '6987-2654', 'elbzuni90@yahoo.com', 'Cartago, Costa Rica', 1),
(13, '3-8573-7216', 'Paola', 'Chacon', 'Segura', '1982-11-23', 'F', '8324-6313', 'paolachacon46@yahoo.com', 'Cartago, Costa Rica', 1),
(14, '8-3340-5339', 'Kenneth', 'Jimenez', 'Elizondo', '1973-04-24', 'M', '8651-5304', 'kenjime226@hotmail.com', 'Limon, Costa Rica', 1),
(15, '7-2040-7304', 'Yolanda', 'Brenes', 'Segura', '1989-10-15', 'F', '8357-1188', 'yolandabrenes18@gmail.com', 'Cartago, Costa Rica', 1),
(16, '2-5889-9317', 'Rolando', 'Tucuman', 'Elizondo', '2003-04-05', 'M', '7880-3646', 'rolandotucuman56@outlook.com', 'Puntarenas, Costa Rica', 1),
(17, '5-4923-1949', 'Gerardo', 'Solano', 'Campos', '1980-10-03', 'M', '6849-8962', 'gerardosolano14@outlook.com', 'Guanacaste, Costa Rica', 1),
(18, '4-6107-7537', 'Rolando', 'Castro', 'Bolanos', '1988-08-17', 'M', '7223-5061', 'rolando_4442@hotmail.com', 'Limon, Costa Rica', 1),
(19, '1-6413-2160', 'Diego', 'Solano', 'Solis', '1997-04-09', 'M', '8597-4510', 'diegosolano30@gmail.com', 'San Jose, Costa Rica', 0),
(20, '7-8651-1887', 'Yeison', 'Salas', NULL, '1971-01-13', 'M', '8447-2790', 'yeison.salas@gmail.com', 'Alajuela, Costa Rica', 1),
(21, '9-2604-1828', 'Alberto', 'Ceciliano', 'Duran', '1999-01-03', 'M', '6270-7658', 'alberto_4663@hotmail.com', 'Guanacaste, Costa Rica', 1),
(22, '7-8973-3536', 'Kimberly', 'Ceciliano', 'Corrales', '1977-05-07', 'F', '6693-9883', 'kimberly_135@outlook.com', 'Heredia, Costa Rica', 1),
(23, '2-2113-4853', 'Ronald', 'Jimenez', 'Chaves', '1990-02-19', 'M', '6692-1651', 'ronald.jimenez@gmail.com', 'Cartago, Costa Rica', 1),
(24, '8-6180-2188', 'Minor', 'Salas', 'Rivera', '1965-08-20', 'M', '8202-2200', 'minor.salas@outlook.com', 'Heredia, Costa Rica', 1),
(25, '5-9666-1128', 'Freddy', 'Tucuman', 'Bolanos', '2000-05-22', 'M', '6999-3200', 'fretucu910@outlook.com', 'Limon, Costa Rica', 1),
(26, '8-5114-1832', 'Bernarda', 'Mora', 'Duran', '1970-11-14', 'F', '7145-1058', 'bermora629@hotmail.com', 'Puntarenas, Costa Rica', 1),
(27, '9-1590-7049', 'Guadalupe', 'Tucuman', NULL, '2002-09-05', 'F', '7230-1685', 'guadalupetucuman71@gmail.com', 'Cartago, Costa Rica', 1),
(28, '3-4878-3662', 'Natalia', 'Jimenez', 'Segura', '1976-07-01', 'F', '6854-6442', 'natjime692@yahoo.com', 'Puntarenas, Costa Rica', 1),
(29, '5-4728-4652', 'Fernanda', 'Tucuman', 'Barrantes', '1966-11-07', 'F', '7436-5564', 'fernanda_734@hotmail.com', 'Heredia, Costa Rica', 1),
(30, '1-2776-8119', 'Esteban', 'Ugalde', 'Aguilar', '1987-12-26', 'M', '7546-9379', 'estebanugalde69@outlook.com', 'Heredia, Costa Rica', 1);
SET IDENTITY_INSERT PERSONA OFF;
 
SET IDENTITY_INSERT EMPLEADO ON; --aplicamos lo mismo para todos los demas
INSERT INTO EMPLEADO (ID_EMPLEADO, ID_PERSONA, PUESTO, FECHA_INGRESO, SALARIO, ESTADO_LABORAL)
VALUES
(101, 1, 'Medico', '2013-07-19', 1499656, 'Activo'),
(102, 2, 'Medico', '2018-01-17', 1885267, 'Activo'),
(103, 3, 'Enfermera', '2023-12-22', 745478, 'Activo'),
(104, 4, 'Enfermera', '2022-06-20', 823903, 'Activo'),
(105, 5, 'Recepcionista', '2023-05-17', 533528, 'Activo'),
(106, 6, 'Farmaceutico', '2018-12-10', 860217, 'Activo');
SET IDENTITY_INSERT EMPLEADO OFF;
 
SET IDENTITY_INSERT MEDICO ON;
INSERT INTO MEDICO (ID_MEDICO, ID_EMPLEADO, CODIGO_COLEGIADO, ESPECIALIDAD, CONSULTORIO)
VALUES
(1, 101, 'MED-7211', 'Pediatria', 'Consultorio 4'),
(2, 102, 'MED-5930', 'Cardiologia', 'Consultorio 8');
SET IDENTITY_INSERT MEDICO OFF;
 
SET IDENTITY_INSERT USUARIO ON;
INSERT INTO USUARIO (ID_USUARIO, ID_EMPLEADO, USUARIO, CLAVE_ACCESO, ULTIMO_ACCESO, ESTADO)
VALUES
(1, 101, 'arodriguez.kiwi', '1234', '2026-07-21 18:37:00', 0),
(2, 102, 'cjimenez.sol', 'hdghasd32!', '2026-07-25 09:32:00', 1),
(3, 103, 'mfernandez', 'hghsdfg02!', '2026-07-23 16:40:00', 1),
(4, 104, 'lmora', 'Hx805477!', '2026-07-19 09:51:00', 1),
(5, 105, 'scastro', 'Hx356736!', '2026-07-22 15:54:00', 1),
(6, 106, 'bernarda_aster54', 'Hx703634!', '2026-07-18 17:44:00', 0);
SET IDENTITY_INSERT USUARIO OFF;
 
SET IDENTITY_INSERT PACIENTE ON;
INSERT INTO PACIENTE (ID_PACIENTE, ID_PERSONA, TIPO_SANGRE, SEGURO_MEDICO, NOMBRE_CONTACTO, TELEFONO_CONTACTO, PARENTESCO, FECHA_REGISTRO)
VALUES
(1, 7, 'B-', 'INS Basico', 'Randall Chinchilla', '7133-7070', 'Hija', '2026-02-12 08:43:00'),
(2, 8, 'O+', 'CCSS', 'Bernarda Brenes', '6968-8450', NULL, '2026-02-21 17:38:00'),
(3, 9, 'A-', NULL, 'Luis Gutierrez', '8310-2124', 'Amigo', '2026-02-19 10:52:00'),
(4, 10, 'O+', 'INS Plus', 'Yeison Rodriguez', '6233-9850', 'Madre', '2026-01-22 07:08:00'),
(5, 11, 'O-', 'INS Plus', 'Rolando Solano', NULL, 'Madre', '2026-06-14 15:07:00'),
(6, 12, 'O+', 'CCSS', 'Warner Salas', '8326-1710', 'Amigo', '2026-03-15 17:01:00'),
(7, 13, 'B-', 'Seguro Privado Mapfre', 'Kenneth Mora', '7175-2323', 'Madre', '2026-01-05 11:39:00'),
(8, 14, 'A-', 'Ninguno', 'Minor Sequeira', '8540-2624', 'Esposa', '2026-07-21 17:56:00'),
(9, 15, 'AB-', 'INS Plus', 'Alberto Solano', '7525-2557', 'Hermana', '2026-06-09 12:09:00'),
(10, 16, 'B-', NULL, 'Camila Fernandez', '8856-7105', 'Amigo', '2026-01-19 15:35:00'),
(11, 17, 'A+', 'Seguro Privado Mapfre', 'Diego Rojas', '8152-5712', 'Hermana', '2026-01-19 15:13:00'),
(12, 18, 'O+', 'INS Plus', 'Valeria Ugalde', '7217-5564', 'Hijo', '2026-07-18 16:39:00'),
(13, 19, 'AB+', 'CCSS', 'Maria Vargas', '7447-6751', NULL, '2026-07-05 16:42:00'),
(14, 20, 'O-', NULL, 'Maria Fernandez', '6485-7878', 'Madre', '2026-03-10 12:49:00'),
(15, 21, 'AB-', 'INS Plus', 'Gabriela Chinchilla', NULL, NULL, '2026-04-22 13:31:00'),
(16, 22, 'O+', 'INS Plus', 'Warner Mora', '6390-8972', 'Hermano', '2026-01-08 13:38:00'),
(17, 23, 'AB+', NULL, 'Ivannia Ceciliano', '7396-6375', 'Hija', '2026-06-14 09:08:00'),
(18, 24, 'O-', 'INS Plus', 'Warner Zuniga', '7173-7505', 'Esposo', '2026-04-01 14:58:00'),
(19, 25, 'B-', 'Ninguno', 'Kenneth Salas', '8527-5743', 'Esposo', '2026-03-06 16:29:00');
SET IDENTITY_INSERT PACIENTE OFF;
 
SET IDENTITY_INSERT EXPEDIENTE ON;
INSERT INTO EXPEDIENTE (ID_EXPEDIENTE, ID_PACIENTE, ALERGIAS, ENFERMEDADES_CRONICAS, ANTECEDENTES, OBSERVACIONES, FECHA_CREACION)
VALUES
(1, 1, 'Penicilina', 'Ninguna', 'Diabetes tipo 2', 'Requiere seguimiento cardiologico', '2026-02-14 16:25:00'),
(2, 2, 'Penicilina', 'Ninguna', 'Ninguno', 'Paciente nuevo', '2026-06-11 10:21:00'),
(3, 3, 'Penicilina', 'Colesterol alto', 'Diabetes tipo 2', 'Requiere seguimiento nutricional', '2026-05-17 10:57:00'),
(4, 4, 'Camarones', 'Hipotiroidismo', 'Asma leve', 'Paciente nuevo', '2026-02-04 09:16:00'),
(5, 5, 'Latex', 'Colesterol alto', 'Asma leve', 'Paciente nuevo', '2026-07-25 17:04:00'),
(6, 6, 'Acaros', 'Ninguna', 'Alergia estacional', 'Requiere seguimiento cardiologico', '2026-07-19 14:43:00'),
(7, 7, 'Camarones', 'Ninguna', 'Colesterol alto', 'Sin observaciones', '2026-02-15 08:30:00'),
(8, 8, 'Sulfas', 'Ninguna', 'Ninguno', 'Control periodico', '2026-05-02 12:32:00'),
(9, 9, 'Sulfas', 'Ninguna', 'Gastritis cronica', 'Requiere seguimiento nutricional', '2026-01-02 12:53:00'),
(10, 10, 'Penicilina', 'Hipotiroidismo', 'Diabetes tipo 2', 'Sin observaciones', '2026-05-20 15:24:00'),
(11, 11, 'Ninguna', 'Ninguna', 'Alergia estacional', 'Sin observaciones', '2026-06-07 12:38:00'),
(12, 12, 'Latex', 'Hipertension', 'Gastritis cronica', 'Control periodico', '2026-01-26 12:45:00'),
(13, 13, 'Latex', 'Hipertension', 'Migraña cronica', 'Requiere seguimiento cardiologico', '2026-06-15 14:33:00'),
(14, 14, 'Latex', 'Asma', 'Colesterol alto', 'Requiere seguimiento nutricional', '2026-03-13 13:49:00'),
(15, 15, 'Ninguna', 'Ninguna', 'Colesterol alto', 'En tratamiento continuo', '2026-01-11 08:35:00'),
(16, 16, 'Ninguna', 'Asma', 'Ninguno', 'Paciente nuevo', '2026-06-22 16:55:00'),
(17, 17, 'Camarones', 'Hipertension', 'Alergia estacional', 'En tratamiento continuo', '2026-06-05 12:19:00'),
(18, 18, 'Ninguna', 'Diabetes tipo 2', 'Alergia estacional', 'Sin observaciones', '2026-06-03 11:35:00'),
(19, 19, 'Camarones', 'Ninguna', 'Asma leve', 'Requiere seguimiento cardiologico', '2026-06-23 17:58:00');
SET IDENTITY_INSERT EXPEDIENTE OFF;
 
SET IDENTITY_INSERT MEDICAMENTO ON;
INSERT INTO MEDICAMENTO (ID_MEDICAMENTO, NOMBRE, DESCRIPCION, PRESENTACION, CONCENTRACION, PRECIO, FABRICANTE, REQUIERE_RECETA, ESTADO)
VALUES
(1, 'Losartan 50mg', 'Antihipertensivo, indicado para hipertension arterial y prevencion cardiovascular', 'Tableta', '50mg', 3500, 'Laboratorios Bagos', 1, 1),
(2, 'Metformina 850mg', 'Antidiabetico oral, uso en diabetes tipo 2 y sindrome metabolico', 'Tableta', '850mg', 2800, 'Laboratorios Stein', 1, 1),
(3, 'Acetaminofen 500mg', 'Analgesico y antipiretico, uso en dolor leve y fiebre', 'Tableta', '500mg', 1200, 'Laboratorios Gutis', 0, 1),
(4, 'Amoxicilina 500mg', 'Antibiotico de amplio espectro, infecciones respiratorias y urinarias', 'Capsula', '500mg', 2500, 'Laboratorios Roemmers', 1, 1),
(5, 'Ibuprofeno 400mg', 'Antiinflamatorio no esteroideo, dolor muscular e inflamacion', 'Tableta', '400mg', 1500, 'Laboratorios Gutis', 0, 1),
(6, 'Salbutamol Inhalador', 'Broncodilatador, uso en asma y EPOC', 'Aerosol', '100mcg/dosis', 4200, 'Laboratorios Chalver', 1, 1),
(7, 'Omeprazol 20mg', 'Protector gastrico, uso en gastritis y reflujo', 'Capsula', '20mg', 1900, 'Laboratorios Bagos', 0, 1),
(8, 'Loratadina 10mg', 'Antihistaminico, uso en rinitis alergica y urticaria', 'Tableta', '10mg', 1300, 'Laboratorios Stein', 0, 1),
(9, 'Atorvastatina 20mg', 'Hipolipemiante, uso en colesterol alto y prevencion cardiovascular', 'Tableta', '20mg', 3100, 'Laboratorios Bagos', 1, 1),
(10, 'Sertralina 50mg', 'Antidepresivo ISRS, uso en depresion y trastornos de ansiedad', 'Tableta', '50mg', 3800, 'Laboratorios Roemmers', 1, 1);
SET IDENTITY_INSERT MEDICAMENTO OFF;
 
SET IDENTITY_INSERT CONSULTA ON;
INSERT INTO CONSULTA (ID_CONSULTA, ID_EXPEDIENTE, ID_MEDICO, FECHA, MOTIVO, DIAGNOSTICO, TRATAMIENTO, OBSERVACIONES)
VALUES
(1, 9, 1, '2026-05-07', 'Control de rutina', 'Gastritis', 'Referencia a especialista', 'Paciente responde bien al tratamiento'),
(2, 16, 1, '2026-06-16', 'Control de presion', 'Ansiedad leve', 'Continuar tratamiento actual', 'Se indica reposo'),
(3, 1, 1, '2026-03-08', 'Chequeo general', 'Gastritis', 'Terapia con inhalador', 'Se indica reposo'),
(4, 19, 2, '2026-04-18', 'Dificultad respiratoria', 'Rinitis alergica', 'Referencia a especialista', 'Requiere examenes adicionales'),
(5, 18, 2, '2026-03-23', 'Alergia estacional', 'Migraña', 'Terapia con inhalador', 'Buena evolucion clinica'),
(6, 9, 1, '2026-01-24', 'Fiebre y tos', 'Rinitis alergica', 'Reposo e hidratacion', 'Sin complicaciones aparentes'),
(7, 18, 1, '2026-02-07', 'Malestar general', 'Ansiedad leve', 'Terapia con inhalador', 'Paciente responde bien al tratamiento'),
(8, 19, 2, '2026-01-07', 'Revision de tratamiento', 'Gastritis', 'Cambio de dieta', 'Sin complicaciones aparentes'),
(9, 6, 2, '2026-01-23', 'Dificultad respiratoria', 'Contractura muscular', 'Terapia con inhalador', 'Sin complicaciones aparentes'),
(10, 2, 1, '2026-05-10', 'Malestar general', 'Contractura muscular', 'Continuar tratamiento actual', 'Se recomienda seguimiento en 2 semanas'),
(11, 4, 1, '2026-05-10', 'Alergia estacional', 'Ansiedad leve', 'Continuar tratamiento actual', 'Se recomienda seguimiento en 2 semanas'),
(12, 11, 1, '2026-01-09', 'Chequeo pediatrico', 'Ansiedad leve', 'Reposo e hidratacion', 'Sin complicaciones aparentes'),
(13, 3, 2, '2026-04-03', 'Dolor muscular', 'Hipertension controlada', 'Antiinflamatorio por 5 dias', 'Paciente estable'),
(14, 5, 2, '2026-01-08', 'Control de rutina', 'Colesterol elevado', 'Referencia a especialista', 'Requiere examenes adicionales'),
(15, 8, 2, '2026-04-15', 'Revision de tratamiento', 'Sin hallazgos relevantes', 'Referencia a especialista', 'Se recomienda seguimiento en 2 semanas'),
(16, 10, 1, '2026-05-24', 'Control de rutina', 'Gastritis', 'Control en 3 meses', 'Se recomienda seguimiento en 2 semanas'),
(17, 9, 1, '2026-02-08', 'Dolor lumbar', 'Colesterol elevado', 'Reposo e hidratacion', 'Se recomienda seguimiento en 2 semanas'),
(18, 6, 1, '2026-04-15', 'Malestar general', 'Sin hallazgos relevantes', 'Continuar tratamiento actual', 'Se recomienda seguimiento en 2 semanas'),
(19, 10, 1, '2026-02-10', 'Malestar general', 'Migraña', 'Continuar tratamiento actual', 'Paciente responde bien al tratamiento'),
(20, 3, 1, '2026-03-26', 'Revision post-tratamiento', 'Sin hallazgos relevantes', 'Control en 3 meses', 'Sin complicaciones aparentes'),
(21, 14, 1, '2026-05-08', 'Control de presion', 'Contractura muscular', 'Terapia con inhalador', 'Paciente estable'),
(22, 5, 1, '2026-01-06', 'Revision post-tratamiento', 'Migraña', 'Terapia con inhalador', 'Paciente estable'),
(23, 15, 1, '2026-04-23', 'Revision de tratamiento', 'Diabetes controlada', 'Terapia con inhalador', 'Paciente responde bien al tratamiento'),
(24, 17, 2, '2026-04-03', 'Dolor muscular', 'Hipertension controlada', 'Referencia a especialista', 'Buena evolucion clinica'),
(25, 11, 2, '2026-01-03', 'Fiebre y tos', 'Sin hallazgos relevantes', 'Ajuste de medicamento', 'Paciente estable'),
(26, 9, 1, '2026-07-25', 'Dolor lumbar', 'Ansiedad leve', 'Continuar tratamiento actual', 'Buena evolucion clinica');
SET IDENTITY_INSERT CONSULTA OFF;
 
SET IDENTITY_INSERT RECETA ON;
INSERT INTO RECETA (ID_RECETA, ID_CONSULTA, FECHA, ESTADO)
VALUES
(1, 9, '2026-01-23', 'ENTREGADA'),
(2, 6, '2026-01-24', 'CANCELADA'),
(3, 19, '2026-02-10', 'ENTREGADA'),
(4, 14, '2026-01-08', 'ENTREGADA'),
(5, 21, '2026-05-08', 'CANCELADA'),
(6, 16, '2026-05-24', 'ENTREGADA'),
(7, 3, '2026-03-08', 'CANCELADA'),
(8, 22, '2026-01-06', 'PENDIENTE'),
(9, 12, '2026-01-09', 'ENTREGADA'),
(10, 23, '2026-04-23', 'PENDIENTE'),
(11, 11, '2026-05-10', 'ENTREGADA'),
(12, 25, '2026-01-03', 'ENTREGADA'),
(13, 24, '2026-04-03', 'ENTREGADA'),
(14, 2, '2026-06-16', 'PENDIENTE'),
(15, 20, '2026-03-26', 'ENTREGADA'),
(16, 15, '2026-04-15', 'CANCELADA');
SET IDENTITY_INSERT RECETA OFF;
 

SET IDENTITY_INSERT DETALLE_RECETA ON;
INSERT INTO DETALLE_RECETA (ID_DETALLE, ID_RECETA, ID_MEDICAMENTO, CANTIDAD, DOSIS, FRECUENCIA, DURACION, PRECIO_ASIGNADO)
VALUES
(1, 1, 9, 30, '1 aplicacion', 'Cada 8 horas', '5 dias', '3259.51'),
(2, 2, 6, 30, '1 tableta', 'Cada 12 horas', '7 dias', '4139.64'),
(3, 2, 8, 60, '2 tabletas', 'Cada 24 horas', '10 dias', '1321.62'),
(4, 3, 8, 10, '5ml', 'Cada 12 horas', '5 dias', '1290.56'),
(5, 3, 2, 20, '5ml', 'Cada 8 horas', '30 dias', '2974.39'),
(6, 4, 2, 15, '1 tableta', 'Cada 6 horas', '3 dias', '2848.55'),
(7, 5, 3, 20, '5ml', 'Cada 24 horas', '10 dias', '1236.12'),
(8, 5, 8, 30, '1 aplicacion', 'Cada 12 horas', '10 dias', '1295.35'),
(9, 6, 3, 15, '5ml', 'Cada 12 horas', '3 dias', '1285.55'),
(10, 6, 7, 20, '1 aplicacion', 'Cada 24 horas', '30 dias', '1938.67'),
(11, 7, 1, 20, '1 capsula', 'Cada 6 horas', '5 dias', '3763.43'),
(12, 8, 9, 30, '1 capsula', 'Cada 24 horas', '30 dias', '3116.05'),
(13, 9, 7, 20, '2 tabletas', 'Cada 12 horas', '30 dias', '2074.93'),
(14, 9, 8, 30, '2 tabletas', 'Cada 6 horas', '3 dias', '1426.97'),
(15, 10, 8, 30, '1 aplicacion', 'Cada 12 horas', '10 dias', '1325.03'),
(16, 11, 3, 60, '5ml', 'Cada 24 horas', '3 dias', '1190.72'),
(17, 12, 2, 60, '1 aplicacion', 'Cada 8 horas', '5 dias', '2820.39'),
(18, 13, 3, 10, '1 aplicacion', 'Cada 24 horas', '7 dias', '1234.94'),
(19, 14, 7, 20, '5ml', 'Cada 6 horas', '7 dias', '2080.39'),
(20, 14, 2, 30, '5ml', 'Cada 8 horas', '30 dias', '3003.09'),
(21, 15, 4, 20, '2 tabletas', 'Cada 8 horas', '10 dias', '2675.47'),
(22, 16, 2, 30, '2 tabletas', 'Cada 24 horas', '3 dias', '2718.13');
SET IDENTITY_INSERT DETALLE_RECETA OFF;
 
SET IDENTITY_INSERT INVENTARIO ON;
INSERT INTO INVENTARIO (ID_INVENTARIO, ID_MEDICAMENTO, LOTE, FECHA_INGRESO, FECHA_VENCIMIENTO, CANTIDAD, STOCK_MINIMO)
VALUES
(1, 1, 'LOT-2026-001', '2026-03-01', '2028-01-13', 148, 16),
(2, 1, 'LOT-2026-001B', '2026-02-13', '2027-06-08', 27, 15),
(3, 2, 'LOT-2026-002', '2026-01-27', '2029-11-11', 57, 9),
(4, 2, 'LOT-2026-002B', '2026-01-10', '2028-12-27', 55, 29),
(5, 3, 'LOT-2026-003', '2026-06-16', '2028-10-01', 40, 5),
(6, 3, 'LOT-2026-003B', '2026-03-07', '2027-09-24', 175, 21),
(7, 4, 'LOT-2026-004', '2026-04-04', '2028-04-10', 51, 6),
(8, 4, 'LOT-2026-004B', '2026-02-14', '2029-10-15', 36, 8),
(9, 5, 'LOT-2026-005', '2026-04-20', '2029-01-21', 151, 23),
(10, 5, 'LOT-2026-005B', '2026-02-23', '2027-05-14', 20, 24),
(11, 6, 'LOT-2026-006', '2026-03-08', '2029-07-06', 190, 26),
(12, 6, 'LOT-2026-006B', '2026-01-17', '2028-02-17', 159, 21),
(13, 7, 'LOT-2026-007', '2026-05-18', '2027-07-28', 140, 6),
(14, 7, 'LOT-2026-007B', '2026-06-13', '2028-05-24', 24, 16),
(15, 8, 'LOT-2026-008', '2026-01-12', '2027-12-22', 180, 8),
(16, 8, 'LOT-2026-008B', '2026-05-24', '2028-03-02', 110, 22),
(17, 9, 'LOT-2026-009', '2026-03-27', '2029-03-27', 195, 19),
(18, 9, 'LOT-2026-009B', '2026-06-16', '2029-03-26', 54, 7),
(19, 10, 'LOT-2026-010', '2026-06-25', '2028-01-10', 71, 6),
(20, 10, 'LOT-2026-010B', '2026-02-02', '2028-05-17', 121, 22);
SET IDENTITY_INSERT INVENTARIO OFF;
 
SET IDENTITY_INSERT AUDITORIA ON;
INSERT INTO AUDITORIA (ID_AUDITORIA, ID_USUARIO, TABLA_AFECTADA, REGISTRO_AFECTADO, ACCION, FECHA, HORA, VALOR_ANTERIOR, VALOR_NUEVO, IP_EQUIPO)
VALUES
(1, 5, 'EXPEDIENTE', 9, 'INSERT', '2026-07-09', '20:52:00', NULL, 'Registro creado', '10.0.0.228'),
(2, 4, 'RECETA', 24, 'UPDATE', '2026-07-26', '07:29:00', 'Valor previo del registro', 'Valor actualizado del registro', '10.0.0.11'),
(3, 1, 'PACIENTE', 25, 'INSERT', '2026-07-22', '17:43:00', NULL, 'Registro creado', '10.0.0.88'),
(4, 4, 'EXPEDIENTE', 12, 'INSERT', '2026-07-26', '12:00:00', NULL, 'Registro creado', '10.0.0.35'),
(5, 3, 'EXPEDIENTE', 4, 'UPDATE', '2026-07-12', '16:47:00', 'Valor previo del registro', 'Valor actualizado del registro', '10.0.0.98'),
(6, 6, 'RECETA', 19, 'UPDATE', '2026-07-21', '11:06:00', 'Valor previo del registro', 'Valor actualizado del registro', '192.168.1.43'),
(7, 6, 'PACIENTE', 16, 'INSERT', '2026-07-20', '20:35:00', NULL, 'Registro creado', '192.168.1.214'),
(8, 3, 'EXPEDIENTE', 8, 'DELETE', '2026-07-03', '16:52:00', 'Registro existente', NULL, '10.0.0.199'),
(9, 4, 'MEDICAMENTO', 10, 'DELETE', '2026-07-14', '07:08:00', 'Registro existente', NULL, '10.0.0.209'),
(10, 1, 'CONSULTA', 10, 'UPDATE', '2026-07-04', '07:15:00', 'Valor previo del registro', 'Valor actualizado del registro', '192.168.1.186'),
(11, 5, 'PACIENTE', 13, 'UPDATE', '2026-07-12', '16:47:00', 'Valor previo del registro', 'Valor actualizado del registro', '192.168.10.13'),
(12, 6, 'EXPEDIENTE', 14, 'DELETE', '2026-07-24', '17:09:00', 'Registro existente', NULL, '192.168.10.95');
SET IDENTITY_INSERT AUDITORIA OFF;