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
SERVER = "KOBIN\SQLEXPRESS"                 # cambiar segun donde estemos conectando la base de datos
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