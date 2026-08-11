"""
Modulo de conexion y operaciones CRUD sobre la tabla PERSONA.

Flujo de autenticacion:
1. login() valida usuario/clave contra la tabla USUARIO.
2. Si es valido, propaga ID_USUARIO a SQL Server via
   sp_set_session_context, para que los triggers de auditoria
   (TR_Persona_Insert/Update/Delete) lo capturen automaticamente.
3. La conexion resultante se reutiliza durante toda la sesion
   de la app (app de un solo usuario a la vez). prueba


"""

import pyodbc


# ------------------------------------------------------------------
# Configuracion de conexion (ajustar segun tu entorno)
#
# Usamos Windows Authentication (Trusted_Connection): la conexion se
# abre con la sesion de Windows actual, no con usuario/clave de SQL
# Server. Esto coincide con como te conectas en SSMS.
# ------------------------------------------------------------------
SERVER = r"KOBIN\SQLEXPRESS"                 # cambiar segun donde estemos conectando la base de datos
DATABASE = "Centro_Medico"
DRIVER = "{ODBC Driver 18 for SQL Server}"
TRUST_CERT = "yes"                   # "yes" para desarrollo/local


def _connection_string() -> str: #metodo de conexion necesaria con obdc
    return (
        f"DRIVER={DRIVER};"
        f"SERVER={SERVER};"
        f"DATABASE={DATABASE};"
        f"Trusted_Connection=yes;"
        f"TrustServerCertificate={TRUST_CERT};"
    )


def get_raw_connection() -> pyodbc.Connection: #Abre una conexion nueva con la cuenta de servicio.
    return pyodbc.connect(_connection_string())

# ------------------------------------------------------------------
# Autenticacion
# ------------------------------------------------------------------
def login(usuario: str, clave: str): #usado para el log in del inicio, comprueba las credenciales
    """
    Valida credenciales contra USUARIO y deja la conexion lista
    con ID_USUARIO propagado a SESSION_CONTEXT.

    Retorna (conexion, id_usuario, nombre_completo).
    Lanza ValueError si las credenciales son invalidas.
    """
    conn = get_raw_connection()
    cursor = conn.cursor()

    cursor.execute(
        """
        SELECT u.ID_USUARIO, u.CLAVE_ACCESO, u.ESTADO,
        p.NOMBRE, p.PRIMER_APELLIDO
        FROM USUARIO u
        INNER JOIN EMPLEADO e ON e.ID_EMPLEADO = u.ID_EMPLEADO
        INNER JOIN PERSONA p ON p.ID_PERSONA = e.ID_PERSONA
        WHERE u.USUARIO = ?
        """,
        usuario,
    )
    row = cursor.fetchone()

    if row is None: #si el usuario no es valido o no lo encuentra
        conn.close()
        raise ValueError("Usuario no encontrado")

    id_usuario, clave_guardada, estado, nombre, apellido = row

    if estado == 0: #usuario inactivo segun la tabla
        conn.close()
        raise ValueError("Usuario inactivo")

    if clave_guardada != clave: #clave
        conn.close()
        raise ValueError("Clave incorrecta")

    cursor.execute( #
        "EXEC sp_set_session_context @key=N'ID_USUARIO', @value=?",
        id_usuario,
    )
    cursor.execute(
        "UPDATE USUARIO SET ULTIMO_ACCESO = GETDATE() WHERE ID_USUARIO = ?",
        id_usuario,
    )
    conn.commit()

    return conn, id_usuario, f"{nombre} {apellido}" #usuario actual


# ------------------------------------------------------------------
# CRUD - PERSONA
# ------------------------------------------------------------------
COLUMNAS_PERSONA = [
    "ID_PERSONA", "CEDULA", "NOMBRE", "PRIMER_APELLIDO", "SEGUNDO_APELLIDO",
    "FECHA_NACIMIENTO", "SEXO", "TELEFONO", "CORREO", "DIRECCION", "ESTADO",
]


def listar_personas(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todas las personas, opcionalmente filtradas por
    cedula, nombre o apellido (busqueda parcial)."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_PERSONA)}
            FROM PERSONA
            WHERE CEDULA LIKE ? OR NOMBRE LIKE ?
            OR PRIMER_APELLIDO LIKE ? OR SEGUNDO_APELLIDO LIKE ?
            ORDER BY ID_PERSONA
            """,
            (like, like, like, like),
        )
    else:
        cursor.execute(
            f"SELECT {', '.join(COLUMNAS_PERSONA)} FROM PERSONA ORDER BY ID_PERSONA"
        )
    return cursor.fetchall()


def crear_persona(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO PERSONA (CEDULA, NOMBRE, PRIMER_APELLIDO, SEGUNDO_APELLIDO,
                                FECHA_NACIMIENTO, SEXO, TELEFONO, CORREO,
                                DIRECCION, ESTADO)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            data["cedula"], data["nombre"], data["primer_apellido"],
            data["segundo_apellido"] or None, data["fecha_nacimiento"],
            data["sexo"], data["telefono"], data["correo"],
            data["direccion"], data["estado"],
        ),
    )
    conn.commit()


def actualizar_persona(conn: pyodbc.Connection, id_persona: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE PERSONA
        SET CEDULA = ?, NOMBRE = ?, PRIMER_APELLIDO = ?, SEGUNDO_APELLIDO = ?,
            FECHA_NACIMIENTO = ?, SEXO = ?, TELEFONO = ?, CORREO = ?,
            DIRECCION = ?, ESTADO = ?
        WHERE ID_PERSONA = ?
        """,
        (
            data["cedula"], data["nombre"], data["primer_apellido"],
            data["segundo_apellido"] or None, data["fecha_nacimiento"],
            data["sexo"], data["telefono"], data["correo"],
            data["direccion"], data["estado"], id_persona,
        ),
    )
    conn.commit()


def eliminar_persona(conn: pyodbc.Connection, id_persona: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM PERSONA WHERE ID_PERSONA = ?", id_persona)
    conn.commit()

# ------------------------------------------------------------------
# CRUD - PACIENTE
# ------------------------------------------------------------------
# PACIENTE depende de PERSONA, listar_pacientes trae tambien cedula/nombre via JOIN y y para
# crear un paciente nuevo primero se busca la persona con buscar_persona_por_cedula().

COLUMNAS_PACIENTE = [
    "p.ID_PACIENTE", "p.ID_PERSONA", "per.CEDULA", "per.NOMBRE", "per.PRIMER_APELLIDO",
    "p.TIPO_SANGRE", "p.SEGURO_MEDICO", "p.NOMBRE_CONTACTO",
    "p.TELEFONO_CONTACTO", "p.PARENTESCO", "p.FECHA_REGISTRO",
]

def buscar_persona_por_cedula(conn: pyodbc.Connection, cedula: str):
    """Devuelve (ID_PERSONA, NOMBRE, PRIMER_APELLIDO) o None si no existe."""
    cursor = conn.cursor()
    cursor.execute(
        "SELECT ID_PERSONA, NOMBRE, PRIMER_APELLIDO FROM PERSONA WHERE CEDULA = ?",
        cedula,
    )
    return cursor.fetchone()

def listar_pacientes(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todos los pacientes con datos de PERSONA via JOIN,
    opcionalmente filtrados por cedula, nombre o apellido."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_PACIENTE)}
            FROM PACIENTE p
            INNER JOIN PERSONA per ON per.ID_PERSONA = p.ID_PERSONA
            WHERE per.CEDULA LIKE ? OR per.NOMBRE LIKE ? OR per.PRIMER_APELLIDO LIKE ?
            ORDER BY p.ID_PACIENTE
            """,
            (like, like, like),
        )
    else:
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_PACIENTE)}
            FROM PACIENTE p
            INNER JOIN PERSONA per ON per.ID_PERSONA = p.ID_PERSONA
            ORDER BY p.ID_PACIENTE
            """
        )
    return cursor.fetchall()

def crear_paciente(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO PACIENTE (ID_PERSONA, TIPO_SANGRE, SEGURO_MEDICO,
                                NOMBRE_CONTACTO, TELEFONO_CONTACTO, PARENTESCO,
                                FECHA_REGISTRO)
        VALUES (?, ?, ?, ?, ?, ?, GETDATE())
        """,
        (
            data["id_persona"], data["tipo_sangre"] or None, data["seguro_medico"] or None,
            data["nombre_contacto"] or None, data["telefono_contacto"] or None,
            data["parentesco"] or None,
        ),
    )
    conn.commit()

def actualizar_paciente(conn: pyodbc.Connection, id_paciente: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE PACIENTE
        SET TIPO_SANGRE = ?, SEGURO_MEDICO = ?, NOMBRE_CONTACTO = ?,
            TELEFONO_CONTACTO = ?, PARENTESCO = ?
        WHERE ID_PACIENTE = ?
        """,
        (
            data["tipo_sangre"] or None, data["seguro_medico"] or None,
            data["nombre_contacto"] or None, data["telefono_contacto"] or None,
            data["parentesco"] or None, id_paciente,
        ),
    )
    conn.commit()

def eliminar_paciente(conn: pyodbc.Connection, id_paciente: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM PACIENTE WHERE ID_PACIENTE = ?", id_paciente)
    conn.commit()

# ------------------------------------------------------------------
# CRUD - EXPEDIENTE
# ------------------------------------------------------------------
# EXPEDIENTE depende de PACIENTE. Para enganchar el paciente se busca por la cedula de
# la PERSONA asociada
COLUMNAS_EXPEDIENTE = [
    "e.ID_EXPEDIENTE", "e.ID_PACIENTE", "per.CEDULA", "per.NOMBRE", "per.PRIMER_APELLIDO",
    "e.ALERGIAS", "e.ENFERMEDADES_CRONICAS", "e.ANTECEDENTES",
    "e.OBSERVACIONES", "e.FECHA_CREACION",
]
 
 
def buscar_paciente_por_cedula(conn: pyodbc.Connection, cedula: str):
    """Devuelve (ID_PACIENTE, NOMBRE, PRIMER_APELLIDO) o None si la
    cedula no pertenece a ningun paciente registrado."""
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT pac.ID_PACIENTE, per.NOMBRE, per.PRIMER_APELLIDO
        FROM PACIENTE pac
        INNER JOIN PERSONA per ON per.ID_PERSONA = pac.ID_PERSONA
        WHERE per.CEDULA = ?
        """,
        cedula,
    )
    return cursor.fetchone()
 
 
def listar_expedientes(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todos los expedientes con datos de PACIENTE/PERSONA
    via JOIN, opcionalmente filtrados por cedula, nombre o apellido."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_EXPEDIENTE)}
            FROM EXPEDIENTE e
            INNER JOIN PACIENTE p ON p.ID_PACIENTE = e.ID_PACIENTE
            INNER JOIN PERSONA per ON per.ID_PERSONA = p.ID_PERSONA
            WHERE per.CEDULA LIKE ? OR per.NOMBRE LIKE ? OR per.PRIMER_APELLIDO LIKE ?
            ORDER BY e.ID_EXPEDIENTE
            """,
            (like, like, like),
        )
    else:
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_EXPEDIENTE)}
            FROM EXPEDIENTE e
            INNER JOIN PACIENTE p ON p.ID_PACIENTE = e.ID_PACIENTE
            INNER JOIN PERSONA per ON per.ID_PERSONA = p.ID_PERSONA
            ORDER BY e.ID_EXPEDIENTE
            """
        )
    return cursor.fetchall()
 
 
def crear_expediente(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO EXPEDIENTE (ID_PACIENTE, ALERGIAS, ENFERMEDADES_CRONICAS,
                                    ANTECEDENTES, OBSERVACIONES, FECHA_CREACION)
        VALUES (?, ?, ?, ?, ?, GETDATE())
        """,
        (
            data["id_paciente"], data["alergias"] or None, data["enfermedades_cronicas"] or None,
            data["antecedentes"] or None, data["observaciones"] or None,
        ),
    )
    conn.commit()
 
 
def actualizar_expediente(conn: pyodbc.Connection, id_expediente: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE EXPEDIENTE
        SET ALERGIAS = ?, ENFERMEDADES_CRONICAS = ?, ANTECEDENTES = ?, OBSERVACIONES = ?
        WHERE ID_EXPEDIENTE = ?
        """,
        (
            data["alergias"] or None, data["enfermedades_cronicas"] or None,
            data["antecedentes"] or None, data["observaciones"] or None, id_expediente,
        ),
    )
    conn.commit()
 
 
def eliminar_expediente(conn: pyodbc.Connection, id_expediente: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM EXPEDIENTE WHERE ID_EXPEDIENTE = ?", id_expediente)
    conn.commit()

# ------------------------------------------------------------------
# CRUD - EMPLEADO
# ------------------------------------------------------------------
# EMPLEADO depende de PERSONA
 
COLUMNAS_EMPLEADO = [
    "emp.ID_EMPLEADO", "emp.ID_PERSONA", "per.CEDULA", "per.NOMBRE", "per.PRIMER_APELLIDO",
    "emp.PUESTO", "emp.FECHA_INGRESO", "emp.SALARIO", "emp.ESTADO_LABORAL",
]

def listar_empleados(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todos los empleados con datos de PERSONA via JOIN,
    opcionalmente filtrados por cedula, nombre o apellido."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_EMPLEADO)}
            FROM EMPLEADO emp
            INNER JOIN PERSONA per ON per.ID_PERSONA = emp.ID_PERSONA
            WHERE per.CEDULA LIKE ? OR per.NOMBRE LIKE ? OR per.PRIMER_APELLIDO LIKE ?
            ORDER BY emp.ID_EMPLEADO
            """,
            (like, like, like),
        )
    else:
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_EMPLEADO)}
            FROM EMPLEADO emp
            INNER JOIN PERSONA per ON per.ID_PERSONA = emp.ID_PERSONA
            ORDER BY emp.ID_EMPLEADO
            """
        )
    return cursor.fetchall()
 
 
def crear_empleado(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO EMPLEADO (ID_PERSONA, PUESTO, FECHA_INGRESO, SALARIO, ESTADO_LABORAL)
        VALUES (?, ?, ?, ?, ?)
        """,
        (
            data["id_persona"], data["puesto"], data["fecha_ingreso"],
            data["salario"], data["estado_laboral"],
        ),
    )
    conn.commit()
 
 
def actualizar_empleado(conn: pyodbc.Connection, id_empleado: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE EMPLEADO
        SET PUESTO = ?, FECHA_INGRESO = ?, SALARIO = ?, ESTADO_LABORAL = ?
        WHERE ID_EMPLEADO = ?
        """,
        (
            data["puesto"], data["fecha_ingreso"], data["salario"],
            data["estado_laboral"], id_empleado,
        ),
    )
    conn.commit()
 
 
def eliminar_empleado(conn: pyodbc.Connection, id_empleado: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM EMPLEADO WHERE ID_EMPLEADO = ?", id_empleado)
    conn.commit()

# ------------------------------------------------------------------
# CRUD - USUARIO
# ------------------------------------------------------------------
# USUARIO depende de EMPLEADO. Se engancha buscando el empleado por la cedula de su PERSONA asociada.
# ULTIMO_ACCESO no se toca desde este CRUD: ya se actualiza solo dentro de login().

COLUMNAS_USUARIO = [
    "u.ID_USUARIO", "u.ID_EMPLEADO", "per.CEDULA", "per.NOMBRE", "per.PRIMER_APELLIDO",
    "u.USUARIO", "u.CLAVE_ACCESO", "u.ULTIMO_ACCESO", "u.ESTADO",
]
 
 
def buscar_empleado_por_cedula(conn: pyodbc.Connection, cedula: str):
    """Devuelve (ID_EMPLEADO, NOMBRE, PRIMER_APELLIDO) o None si la
    cedula no pertenece a ningun empleado registrado."""
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT emp.ID_EMPLEADO, per.NOMBRE, per.PRIMER_APELLIDO
        FROM EMPLEADO emp
        INNER JOIN PERSONA per ON per.ID_PERSONA = emp.ID_PERSONA
        WHERE per.CEDULA = ?
        """,
        cedula,
    )
    return cursor.fetchone()
 
 
def listar_usuarios(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todos los usuarios con datos de EMPLEADO/PERSONA via
    JOIN, opcionalmente filtrados por cedula, nombre, apellido o
    nombre de usuario."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_USUARIO)}
            FROM USUARIO u
            INNER JOIN EMPLEADO emp ON emp.ID_EMPLEADO = u.ID_EMPLEADO
            INNER JOIN PERSONA per ON per.ID_PERSONA = emp.ID_PERSONA
            WHERE per.CEDULA LIKE ? OR per.NOMBRE LIKE ?
            OR per.PRIMER_APELLIDO LIKE ? OR u.USUARIO LIKE ?
            ORDER BY u.ID_USUARIO
            """,
            (like, like, like, like),
        )
    else:
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_USUARIO)}
            FROM USUARIO u
            INNER JOIN EMPLEADO emp ON emp.ID_EMPLEADO = u.ID_EMPLEADO
            INNER JOIN PERSONA per ON per.ID_PERSONA = emp.ID_PERSONA
            ORDER BY u.ID_USUARIO
            """
        )
    return cursor.fetchall()
 
 
def crear_usuario(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO USUARIO (ID_EMPLEADO, USUARIO, CLAVE_ACCESO, ESTADO)
        VALUES (?, ?, ?, ?)
        """,
        (data["id_empleado"], data["usuario"], data["clave_acceso"], data["estado"]),
    )
    conn.commit()
 
 
def actualizar_usuario(conn: pyodbc.Connection, id_usuario: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE USUARIO
        SET USUARIO = ?, CLAVE_ACCESO = ?, ESTADO = ?
        WHERE ID_USUARIO = ?
        """,
        (data["usuario"], data["clave_acceso"], data["estado"], id_usuario),
    )
    conn.commit()
 
 
def eliminar_usuario(conn: pyodbc.Connection, id_usuario: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM USUARIO WHERE ID_USUARIO = ?", id_usuario)
    conn.commit()


# ------------------------------------------------------------------
# CRUD - MEDICO
# ------------------------------------------------------------------
# MEDICO depende de EMPLEADO, igual que USUARIO. 

COLUMNAS_MEDICO = [
    "m.ID_MEDICO", "m.ID_EMPLEADO", "per.CEDULA", "per.NOMBRE", "per.PRIMER_APELLIDO",
    "m.CODIGO_COLEGIADO", "m.ESPECIALIDAD", "m.CONSULTORIO",
]
 
 
def listar_medicos(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todos los medicos con datos de EMPLEADO/PERSONA via
    JOIN, opcionalmente filtrados por cedula, nombre, apellido o
    especialidad."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_MEDICO)}
            FROM MEDICO m
            INNER JOIN EMPLEADO emp ON emp.ID_EMPLEADO = m.ID_EMPLEADO
            INNER JOIN PERSONA per ON per.ID_PERSONA = emp.ID_PERSONA
            WHERE per.CEDULA LIKE ? OR per.NOMBRE LIKE ?
            OR per.PRIMER_APELLIDO LIKE ? OR m.ESPECIALIDAD LIKE ?
            ORDER BY m.ID_MEDICO
            """,
            (like, like, like, like),
        )
    else:
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_MEDICO)}
            FROM MEDICO m
            INNER JOIN EMPLEADO emp ON emp.ID_EMPLEADO = m.ID_EMPLEADO
            INNER JOIN PERSONA per ON per.ID_PERSONA = emp.ID_PERSONA
            ORDER BY m.ID_MEDICO
            """
        )
    return cursor.fetchall()
 
 
def crear_medico(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO MEDICO (ID_EMPLEADO, CODIGO_COLEGIADO, ESPECIALIDAD, CONSULTORIO)
        VALUES (?, ?, ?, ?)
        """,
        (data["id_empleado"], data["codigo_colegiado"], data["especialidad"], data["consultorio"]),
    )
    conn.commit()
 
 
def actualizar_medico(conn: pyodbc.Connection, id_medico: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE MEDICO
        SET CODIGO_COLEGIADO = ?, ESPECIALIDAD = ?, CONSULTORIO = ?
        WHERE ID_MEDICO = ?
        """,
        (data["codigo_colegiado"], data["especialidad"], data["consultorio"], id_medico),
    )
    conn.commit()
 
 
def eliminar_medico(conn: pyodbc.Connection, id_medico: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM MEDICO WHERE ID_MEDICO = ?", id_medico)
    conn.commit()


# ------------------------------------------------------------------
# CRUD - CONSULTA
# ------------------------------------------------------------------
# CONSULTA tiene DOS llaves foraneas obligatorias: ID_EXPEDIENTE y
# ID_MEDICO. Cada una se engancha por separado buscando por la cedula
# de la persona correspondiente (paciente por un lado, medico por otro).

COLUMNAS_CONSULTA = [
    "c.ID_CONSULTA", "c.ID_EXPEDIENTE", "perpac.CEDULA", "perpac.NOMBRE", "perpac.PRIMER_APELLIDO",
    "c.ID_MEDICO", "permed.NOMBRE", "permed.PRIMER_APELLIDO",
    "c.FECHA", "c.MOTIVO", "c.DIAGNOSTICO", "c.TRATAMIENTO", "c.OBSERVACIONES",
]
 
 
def buscar_expediente_por_cedula(conn: pyodbc.Connection, cedula: str):
    """Devuelve (ID_EXPEDIENTE, NOMBRE, PRIMER_APELLIDO) del paciente
    dueño del expediente, o None si la cedula no tiene expediente."""
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT e.ID_EXPEDIENTE, per.NOMBRE, per.PRIMER_APELLIDO
        FROM EXPEDIENTE e
        INNER JOIN PACIENTE pac ON pac.ID_PACIENTE = e.ID_PACIENTE
        INNER JOIN PERSONA per ON per.ID_PERSONA = pac.ID_PERSONA
        WHERE per.CEDULA = ?
        """,
        cedula,
    )
    return cursor.fetchone()
 
 
def buscar_medico_por_cedula(conn: pyodbc.Connection, cedula: str):
    """Devuelve (ID_MEDICO, NOMBRE, PRIMER_APELLIDO) o None si la
    cedula no pertenece a ningun medico registrado."""
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT m.ID_MEDICO, per.NOMBRE, per.PRIMER_APELLIDO
        FROM MEDICO m
        INNER JOIN EMPLEADO emp ON emp.ID_EMPLEADO = m.ID_EMPLEADO
        INNER JOIN PERSONA per ON per.ID_PERSONA = emp.ID_PERSONA
        WHERE per.CEDULA = ?
        """,
        cedula,
    )
    return cursor.fetchone()
 
 
def listar_consultas(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todas las consultas con datos del paciente y del
    medico via JOIN, opcionalmente filtradas por cedula, nombre o
    apellido del paciente."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_CONSULTA)}
            FROM CONSULTA c
            INNER JOIN EXPEDIENTE e ON e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
            INNER JOIN PACIENTE pac ON pac.ID_PACIENTE = e.ID_PACIENTE
            INNER JOIN PERSONA perpac ON perpac.ID_PERSONA = pac.ID_PERSONA
            INNER JOIN MEDICO m ON m.ID_MEDICO = c.ID_MEDICO
            INNER JOIN EMPLEADO emp ON emp.ID_EMPLEADO = m.ID_EMPLEADO
            INNER JOIN PERSONA permed ON permed.ID_PERSONA = emp.ID_PERSONA
            WHERE perpac.CEDULA LIKE ? OR perpac.NOMBRE LIKE ? OR perpac.PRIMER_APELLIDO LIKE ?
            ORDER BY c.ID_CONSULTA
            """,
            (like, like, like),
        )
    else:
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_CONSULTA)}
            FROM CONSULTA c
            INNER JOIN EXPEDIENTE e ON e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
            INNER JOIN PACIENTE pac ON pac.ID_PACIENTE = e.ID_PACIENTE
            INNER JOIN PERSONA perpac ON perpac.ID_PERSONA = pac.ID_PERSONA
            INNER JOIN MEDICO m ON m.ID_MEDICO = c.ID_MEDICO
            INNER JOIN EMPLEADO emp ON emp.ID_EMPLEADO = m.ID_EMPLEADO
            INNER JOIN PERSONA permed ON permed.ID_PERSONA = emp.ID_PERSONA
            ORDER BY c.ID_CONSULTA
            """
        )
    return cursor.fetchall()
 
 
def crear_consulta(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO CONSULTA (ID_EXPEDIENTE, ID_MEDICO, FECHA, MOTIVO,
                                DIAGNOSTICO, TRATAMIENTO, OBSERVACIONES)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            data["id_expediente"], data["id_medico"], data["fecha"], data["motivo"],
            data["diagnostico"], data["tratamiento"] or None, data["observaciones"] or None,
        ),
    )
    conn.commit()
 
 
def actualizar_consulta(conn: pyodbc.Connection, id_consulta: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE CONSULTA
        SET FECHA = ?, MOTIVO = ?, DIAGNOSTICO = ?, TRATAMIENTO = ?, OBSERVACIONES = ?
        WHERE ID_CONSULTA = ?
        """,
        (
            data["fecha"], data["motivo"], data["diagnostico"],
            data["tratamiento"] or None, data["observaciones"] or None, id_consulta,
        ),
    )
    conn.commit()
 
 
def eliminar_consulta(conn: pyodbc.Connection, id_consulta: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM CONSULTA WHERE ID_CONSULTA = ?", id_consulta)
    conn.commit()

    # ------------------------------------------------------------------
# CRUD - MEDICAMENTO
# ------------------------------------------------------------------
# MEDICAMENTO no depende de ninguna otra tabla (no tiene FK), asi que
# no hace falta enganchar nada por cedula
 
COLUMNAS_MEDICAMENTO = [
    "ID_MEDICAMENTO", "NOMBRE", "DESCRIPCION", "PRESENTACION", "CONCENTRACION",
    "PRECIO", "FABRICANTE", "REQUIERE_RECETA", "ESTADO",
]


def listar_medicamentos(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todos los medicamentos, opcionalmente filtrados por
    nombre o fabricante (busqueda parcial)."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_MEDICAMENTO)}
            FROM MEDICAMENTO
            WHERE NOMBRE LIKE ? OR FABRICANTE LIKE ?
            ORDER BY ID_MEDICAMENTO
            """,
            (like, like),
        )
    else:
        cursor.execute(
            f"SELECT {', '.join(COLUMNAS_MEDICAMENTO)} FROM MEDICAMENTO ORDER BY ID_MEDICAMENTO"
        )
    return cursor.fetchall()
 
 
def crear_medicamento(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO MEDICAMENTO (NOMBRE, DESCRIPCION, PRESENTACION, CONCENTRACION,
                                    PRECIO, FABRICANTE, REQUIERE_RECETA, ESTADO)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            data["nombre"], data["descripcion"] or None, data["presentacion"],
            data["concentracion"], data["precio"], data["fabricante"] or None,
            data["requiere_receta"], data["estado"],
        ),
    )
    conn.commit()
 
 
def actualizar_medicamento(conn: pyodbc.Connection, id_medicamento: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE MEDICAMENTO
        SET NOMBRE = ?, DESCRIPCION = ?, PRESENTACION = ?, CONCENTRACION = ?,
            PRECIO = ?, FABRICANTE = ?, REQUIERE_RECETA = ?, ESTADO = ?
        WHERE ID_MEDICAMENTO = ?
        """,
        (
            data["nombre"], data["descripcion"] or None, data["presentacion"],
            data["concentracion"], data["precio"], data["fabricante"] or None,
            data["requiere_receta"], data["estado"], id_medicamento,
        ),
    )
    conn.commit()
 
 
def eliminar_medicamento(conn: pyodbc.Connection, id_medicamento: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM MEDICAMENTO WHERE ID_MEDICAMENTO = ?", id_medicamento)
    conn.commit()

COLUMNAS_RECETA = [
    "r.ID_RECETA", "r.ID_CONSULTA", "per.CEDULA", "per.NOMBRE", "per.PRIMER_APELLIDO",
    "r.FECHA", "r.ESTADO",
]
 
 
def buscar_consultas_por_cedula(conn: pyodbc.Connection, cedula: str):
    """Devuelve una lista de (ID_CONSULTA, FECHA, MOTIVO) con todas
    las consultas del paciente con esa cedula, mas recientes primero."""
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT c.ID_CONSULTA, c.FECHA, c.MOTIVO
        FROM CONSULTA c
        INNER JOIN EXPEDIENTE e ON e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
        INNER JOIN PACIENTE pac ON pac.ID_PACIENTE = e.ID_PACIENTE
        INNER JOIN PERSONA per ON per.ID_PERSONA = pac.ID_PERSONA
        WHERE per.CEDULA = ?
        ORDER BY c.FECHA DESC
        """,
        cedula,
    )
    return cursor.fetchall()
 
 
def listar_recetas(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todas las recetas con la cedula/nombre del paciente
    via JOIN, opcionalmente filtradas por cedula, nombre o apellido."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_RECETA)}
            FROM RECETA r
            INNER JOIN CONSULTA c ON c.ID_CONSULTA = r.ID_CONSULTA
            INNER JOIN EXPEDIENTE e ON e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
            INNER JOIN PACIENTE pac ON pac.ID_PACIENTE = e.ID_PACIENTE
            INNER JOIN PERSONA per ON per.ID_PERSONA = pac.ID_PERSONA
            WHERE per.CEDULA LIKE ? OR per.NOMBRE LIKE ? OR per.PRIMER_APELLIDO LIKE ?
            ORDER BY r.ID_RECETA
            """,
            (like, like, like),
        )
    else:
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_RECETA)}
            FROM RECETA r
            INNER JOIN CONSULTA c ON c.ID_CONSULTA = r.ID_CONSULTA
            INNER JOIN EXPEDIENTE e ON e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
            INNER JOIN PACIENTE pac ON pac.ID_PACIENTE = e.ID_PACIENTE
            INNER JOIN PERSONA per ON per.ID_PERSONA = pac.ID_PERSONA
            ORDER BY r.ID_RECETA
            """
        )
    return cursor.fetchall()
 
 
def crear_receta(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO RECETA (ID_CONSULTA, FECHA, ESTADO)
        VALUES (?, ?, ?)
        """,
        (data["id_consulta"], data["fecha"], data["estado"]),
    )
    conn.commit()
 
 
def actualizar_receta(conn: pyodbc.Connection, id_receta: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE RECETA
        SET FECHA = ?, ESTADO = ?
        WHERE ID_RECETA = ?
        """,
        (data["fecha"], data["estado"], id_receta),
    )
    conn.commit()
 
 
def eliminar_receta(conn: pyodbc.Connection, id_receta: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM RECETA WHERE ID_RECETA = ?", id_receta)
    conn.commit()


# ------------------------------------------------------------------
# CRUD - DETALLE_RECETA
# ------------------------------------------------------------------
# DETALLE_RECETA tiene DOS llaves foraneas obligatorias: ID_RECETA e
# ID_MEDICAMENTO. Igual que en RECETA, la busqueda de recetas por
# cedula puede devolver varias (un paciente con varias recetas), asi
# que buscar_recetas_por_cedula() devuelve una lista.
 
COLUMNAS_DETALLE_RECETA = [
    "d.ID_DETALLE", "d.ID_RECETA", "per.CEDULA", "per.NOMBRE", "per.PRIMER_APELLIDO",
    "d.ID_MEDICAMENTO", "med.NOMBRE", "d.CANTIDAD", "d.DOSIS", "d.FRECUENCIA",
    "d.DURACION", "d.PRECIO_ASIGNADO",
]

def buscar_recetas_por_cedula(conn: pyodbc.Connection, cedula: str):
    """Devuelve una lista de (ID_RECETA, FECHA, ESTADO) con todas las
    recetas del paciente con esa cedula, mas recientes primero."""
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT r.ID_RECETA, r.FECHA, r.ESTADO
        FROM RECETA r
        INNER JOIN CONSULTA c ON c.ID_CONSULTA = r.ID_CONSULTA
        INNER JOIN EXPEDIENTE e ON e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
        INNER JOIN PACIENTE pac ON pac.ID_PACIENTE = e.ID_PACIENTE
        INNER JOIN PERSONA per ON per.ID_PERSONA = pac.ID_PERSONA
        WHERE per.CEDULA = ?
        ORDER BY r.FECHA DESC
        """,
        cedula,
    )
    return cursor.fetchall()
 
 
def buscar_medicamentos_por_nombre(conn: pyodbc.Connection, nombre: str):
    """Devuelve una lista de (ID_MEDICAMENTO, NOMBRE, PRESENTACION)
    cuyo nombre coincide parcialmente con el texto buscado."""
    cursor = conn.cursor()
    cursor.execute(
        """
        SELECT ID_MEDICAMENTO, NOMBRE, PRESENTACION
        FROM MEDICAMENTO
        WHERE NOMBRE LIKE ?
        ORDER BY NOMBRE
        """,
        f"%{nombre}%",
    )
    return cursor.fetchall()
 
 
def listar_detalle_recetas(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todos los detalles de receta con cedula/nombre del
    paciente y nombre del medicamento via JOIN, opcionalmente
    filtrados por cedula, nombre del paciente o nombre del medicamento."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_DETALLE_RECETA)}
            FROM DETALLE_RECETA d
            INNER JOIN RECETA r ON r.ID_RECETA = d.ID_RECETA
            INNER JOIN CONSULTA c ON c.ID_CONSULTA = r.ID_CONSULTA
            INNER JOIN EXPEDIENTE e ON e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
            INNER JOIN PACIENTE pac ON pac.ID_PACIENTE = e.ID_PACIENTE
            INNER JOIN PERSONA per ON per.ID_PERSONA = pac.ID_PERSONA
            INNER JOIN MEDICAMENTO med ON med.ID_MEDICAMENTO = d.ID_MEDICAMENTO
            WHERE per.CEDULA LIKE ? OR per.NOMBRE LIKE ? OR med.NOMBRE LIKE ?
            ORDER BY d.ID_DETALLE
            """,
            (like, like, like),
        )
    else:
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_DETALLE_RECETA)}
            FROM DETALLE_RECETA d
            INNER JOIN RECETA r ON r.ID_RECETA = d.ID_RECETA
            INNER JOIN CONSULTA c ON c.ID_CONSULTA = r.ID_CONSULTA
            INNER JOIN EXPEDIENTE e ON e.ID_EXPEDIENTE = c.ID_EXPEDIENTE
            INNER JOIN PACIENTE pac ON pac.ID_PACIENTE = e.ID_PACIENTE
            INNER JOIN PERSONA per ON per.ID_PERSONA = pac.ID_PERSONA
            INNER JOIN MEDICAMENTO med ON med.ID_MEDICAMENTO = d.ID_MEDICAMENTO
            ORDER BY d.ID_DETALLE
            """
        )
    return cursor.fetchall()
 
 
def crear_detalle_receta(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO DETALLE_RECETA (ID_RECETA, ID_MEDICAMENTO, CANTIDAD, DOSIS,
                                        FRECUENCIA, DURACION, PRECIO_ASIGNADO)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            data["id_receta"], data["id_medicamento"], data["cantidad"], data["dosis"],
            data["frecuencia"], data["duracion"], data["precio_asignado"],
        ),
    )
    conn.commit()
 
 
def actualizar_detalle_receta(conn: pyodbc.Connection, id_detalle: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE DETALLE_RECETA
        SET CANTIDAD = ?, DOSIS = ?, FRECUENCIA = ?, DURACION = ?, PRECIO_ASIGNADO = ?
        WHERE ID_DETALLE = ?
        """,
        (
            data["cantidad"], data["dosis"], data["frecuencia"],
            data["duracion"], data["precio_asignado"], id_detalle,
        ),
    )
    conn.commit()
 
 
def eliminar_detalle_receta(conn: pyodbc.Connection, id_detalle: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM DETALLE_RECETA WHERE ID_DETALLE = ?", id_detalle)
    conn.commit()


# ------------------------------------------------------------------
# CRUD - INVENTARIO
# ------------------------------------------------------------------
# INVENTARIO depende de MEDICAMENTO

COLUMNAS_INVENTARIO = [
    "i.ID_INVENTARIO", "i.ID_MEDICAMENTO", "med.NOMBRE", "i.LOTE",
    "i.FECHA_INGRESO", "i.FECHA_VENCIMIENTO", "i.CANTIDAD", "i.STOCK_MINIMO",
]
 
 
def listar_inventario(conn: pyodbc.Connection, filtro: str = ""):
    """Devuelve todo el inventario con el nombre del medicamento via
    JOIN, opcionalmente filtrado por nombre de medicamento o lote."""
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_INVENTARIO)}
            FROM INVENTARIO i
            INNER JOIN MEDICAMENTO med ON med.ID_MEDICAMENTO = i.ID_MEDICAMENTO
            WHERE med.NOMBRE LIKE ? OR i.LOTE LIKE ?
            ORDER BY i.ID_INVENTARIO
            """,
            (like, like),
        )
    else:
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_INVENTARIO)}
            FROM INVENTARIO i
            INNER JOIN MEDICAMENTO med ON med.ID_MEDICAMENTO = i.ID_MEDICAMENTO
            ORDER BY i.ID_INVENTARIO
            """
        )
    return cursor.fetchall()
 
 
def crear_inventario(conn: pyodbc.Connection, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        INSERT INTO INVENTARIO (ID_MEDICAMENTO, LOTE, FECHA_INGRESO,
                                    FECHA_VENCIMIENTO, CANTIDAD, STOCK_MINIMO)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (
            data["id_medicamento"], data["lote"], data["fecha_ingreso"],
            data["fecha_vencimiento"], data["cantidad"], data["stock_minimo"],
        ),
    )
    conn.commit()
 
 
def actualizar_inventario(conn: pyodbc.Connection, id_inventario: int, data: dict) -> None:
    cursor = conn.cursor()
    cursor.execute(
        """
        UPDATE INVENTARIO
        SET LOTE = ?, FECHA_INGRESO = ?, FECHA_VENCIMIENTO = ?, CANTIDAD = ?, STOCK_MINIMO = ?
        WHERE ID_INVENTARIO = ?
        """,
        (
            data["lote"], data["fecha_ingreso"], data["fecha_vencimiento"],
            data["cantidad"], data["stock_minimo"], id_inventario,
        ),
    )
    conn.commit()
 
 
def eliminar_inventario(conn: pyodbc.Connection, id_inventario: int) -> None:
    cursor = conn.cursor()
    cursor.execute("DELETE FROM INVENTARIO WHERE ID_INVENTARIO = ?", id_inventario)
    conn.commit()

# ------------------------------------------------------------------
# AUDITORIA
# ------------------------------------------------------------------
# AUDITORIA se llena sola via triggers
 
COLUMNAS_AUDITORIA = [
    "a.ID_AUDITORIA", "u.USUARIO", "a.USUARIO_SQL", "per.NOMBRE", "per.PRIMER_APELLIDO",
    "a.TABLA_AFECTADA", "a.REGISTRO_AFECTADO", "a.ACCION", "a.FECHA", "a.HORA",
    "a.VALOR_ANTERIOR", "a.VALOR_NUEVO", "a.IP_EQUIPO",
]
 
 
def listar_auditoria(conn: pyodbc.Connection, filtro: str = ""):
    cursor = conn.cursor()
    if filtro:
        like = f"%{filtro}%"
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_AUDITORIA)}
            FROM AUDITORIA a
            LEFT JOIN USUARIO u ON u.ID_USUARIO = a.ID_USUARIO
            LEFT JOIN EMPLEADO emp ON emp.ID_EMPLEADO = u.ID_EMPLEADO
            LEFT JOIN PERSONA per ON per.ID_PERSONA = emp.ID_PERSONA
            WHERE a.TABLA_AFECTADA LIKE ? OR a.ACCION LIKE ? OR u.USUARIO LIKE ? OR a.USUARIO_SQL LIKE ?
            ORDER BY a.FECHA DESC, a.HORA DESC
            """,
            (like, like, like, like),
        )
    else:
        cursor.execute(
            f"""
            SELECT {', '.join(COLUMNAS_AUDITORIA)}
            FROM AUDITORIA a
            LEFT JOIN USUARIO u ON u.ID_USUARIO = a.ID_USUARIO
            LEFT JOIN EMPLEADO emp ON emp.ID_EMPLEADO = u.ID_EMPLEADO
            LEFT JOIN PERSONA per ON per.ID_PERSONA = emp.ID_PERSONA
            ORDER BY a.FECHA DESC, a.HORA DESC
            """
        )
    return cursor.fetchall()