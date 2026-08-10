"""
App de escritorio (Tkinter) para gestionar PERSONA en CentroMedico.

Ejecutar con:
    python app_personas.py
"""

import tkinter as tk
from tkinter import ttk, messagebox
import pyodbc

import ConexionODBC as db


# ==========================================================
# VENTANA DE LOGIN
# ==========================================================
class LoginWindow(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Centro Medico - Iniciar sesion")
        self.geometry("320x180")
        self.resizable(False, False)

        self.conn = None
        self.id_usuario = None
        self.nombre_completo = None

        ttk.Label(self, text="Usuario:").pack(pady=(20, 0))
        self.entry_usuario = ttk.Entry(self)
        self.entry_usuario.pack()
        self.entry_usuario.focus()

        ttk.Label(self, text="Clave:").pack(pady=(10, 0))
        self.entry_clave = ttk.Entry(self, show="*")
        self.entry_clave.pack()

        ttk.Button(self, text="Ingresar", command=self._intentar_login).pack(pady=20)

        self.bind("<Return>", lambda e: self._intentar_login())

    def _intentar_login(self):
        usuario = self.entry_usuario.get().strip()
        clave = self.entry_clave.get()

        if not usuario or not clave:
            messagebox.showwarning("Datos incompletos", "Ingresa usuario y clave.")
            return

        try:
            self.conn, self.id_usuario, self.nombre_completo = db.login(usuario, clave)
        except ValueError as e:
            messagebox.showerror("Error de inicio de sesion", str(e))
            return
        except pyodbc.Error as e:
            messagebox.showerror(
                "Error de conexion",
                f"No se pudo conectar a la base de datos.\n\n{e}",
            )
            return

        self.destroy()  # cierra login, main() abre la ventana principal

# ==========================================================
# MENU PRINCIPAL
# ==========================================================
# Cada entrada define el texto del boton y si ya tiene modulo
MODULOS = [ #cuando se termine cada uno se va agregando
    ("Personas", True),
    ("Pacientes", True),
    ("Expedientes", True),
    ("Empleados", True),
    ("Usuarios", True),
    ("Medicos", True),
    ("Consultas", True),
    ("Recetas", True),
    ("Detalle de receta", False),
    ("Medicamentos", True),
    ("Inventario", False),
    ("Auditoria", False),
]
ESTADOS_LABORALES = ["Activo", "Inactivo", "Suspendido", "Vacaciones"]
ESTADOS_RECETA = ["Pendiente", "Entregada", "Cancelada"]

class MenuPrincipal(tk.Tk):
    def __init__(self, conn, id_usuario, nombre_completo):
        super().__init__()
        self.conn = conn
        self.id_usuario = id_usuario

        self.title("Centro Medico - Menu principal")
        self.geometry("420x420")
        self.resizable(False, False)

        ttk.Label(
            self, text=f"Sesion activa: {nombre_completo}", font=("Segoe UI", 10, "bold")
        ).pack(pady=(15, 5))

        contenedor = ttk.Frame(self)
        contenedor.pack(expand=True, fill="both", padx=20, pady=10)

        filas, columnas = 4, 3
        for idx, (nombre, disponible) in enumerate(MODULOS):
            fila, columna = divmod(idx, columnas)
            boton = ttk.Button(
                contenedor,
                text=nombre,
                width=16,
                command=lambda n=nombre, d=disponible: self._abrir_modulo(n, d),
            )
            boton.grid(row=fila, column=columna, padx=5, pady=8)

        ttk.Button(self, text="Cerrar sesion", command=self._cerrar_app).pack(pady=(5, 15))

        self.protocol("WM_DELETE_WINDOW", self._cerrar_app)

    def _abrir_modulo(self, nombre: str, disponible: bool):
        if not disponible:
            messagebox.showinfo("En construccion", f"El modulo de {nombre} aun no esta listo.")
            return

        if nombre == "Personas":
            VentanaPersonas(self, self.conn)
        elif nombre == "Pacientes":
            VentanaPacientes(self,self.conn)
        elif nombre == "Expedientes":
            VentanaExpedientes(self,self.conn)
        elif nombre == "Empleados":
            VentanaEmpleados(self,self.conn)
        elif nombre == "Usuarios":
            VentanaUsuarios(self,self.conn)
        elif nombre == "Medicos":
            VentanaMedicos(self,self.conn)
        elif nombre == "Consultas":
            VentanaConsultas(self,self.conn)
        elif nombre == "Medicamentos":
            VentanaMedicamentos(self,self.conn)
        elif nombre == "Recetas":
            VentanaMedicamentos(self,self.conn)

    def _cerrar_app(self):
        if self.conn:
            self.conn.close()
        self.destroy()


# ==========================================================
# CRUD PERSONA
# ==========================================================
class VentanaPersonas(tk.Toplevel):
    def __init__(self, parent, conn):
        super().__init__(parent)
        self.conn = conn
        self.id_persona_seleccionada = None
 
        self.title("Gestion de Personas")
        self.geometry("950x520")
 
        self._construir_barra_busqueda()
        self._construir_tabla()
        self._construir_formulario()
        self._construir_botones()
 
        self.cargar_personas()
 
    # ---------------- UI ----------------
    def _construir_barra_busqueda(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(10, 0))
 
        ttk.Label(frame, text="Buscar (cedula / nombre / apellido):").pack(side="left")
        self.entry_buscar = ttk.Entry(frame, width=30)
        self.entry_buscar.pack(side="left", padx=5)
        self.entry_buscar.bind("<Return>", lambda e: self.cargar_personas())
 
        ttk.Button(frame, text="Buscar", command=self.cargar_personas).pack(side="left", padx=5)
        ttk.Button(frame, text="Mostrar todos", command=self._mostrar_todos).pack(side="left")
 
    def _construir_tabla(self):
        columnas = ("ID", "Cedula", "Nombre", "Ap. Primero", "Ap. Segundo",
                    "F. Nacimiento", "Sexo", "Telefono", "Correo", "Direccion", "Activo")
 
        self.tabla = ttk.Treeview(self, columns=columnas, show="headings", height=12)
        for col in columnas:
            self.tabla.heading(col, text=col)
            self.tabla.column(col, width=90, anchor="w")
        self.tabla.column("Correo", width=150)
        self.tabla.column("Direccion", width=150)
 
        self.tabla.pack(fill="both", expand=True, padx=10, pady=10)
        self.tabla.bind("<<TreeviewSelect>>", self._al_seleccionar_fila)
 
    def _construir_formulario(self):
        frame = ttk.LabelFrame(self, text="Datos de la persona")
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        self.vars = {
            "cedula": tk.StringVar(),
            "nombre": tk.StringVar(),
            "primer_apellido": tk.StringVar(),
            "segundo_apellido": tk.StringVar(),
            "fecha_nacimiento": tk.StringVar(),
            "sexo": tk.StringVar(value="M"),
            "telefono": tk.StringVar(),
            "correo": tk.StringVar(),
            "direccion": tk.StringVar(),
        }
        self.var_estado = tk.BooleanVar(value=True)
 
        campos = [
            ("Cedula", "cedula"), ("Nombre", "nombre"),
            ("1er Apellido", "primer_apellido"), ("2do Apellido", "segundo_apellido"),
            ("F. Nacimiento (AAAA-MM-DD)", "fecha_nacimiento"),
            ("Telefono", "telefono"), ("Correo", "correo"), ("Direccion", "direccion"),
        ]
 
        for idx, (etiqueta, clave) in enumerate(campos):
            fila, columna = divmod(idx, 2)
            ttk.Label(frame, text=etiqueta).grid(row=fila, column=columna * 2, sticky="e", padx=5, pady=4)
            ttk.Entry(frame, textvariable=self.vars[clave], width=28).grid(
                row=fila, column=columna * 2 + 1, sticky="w", padx=5, pady=4
            )
 
        fila_extra = len(campos) // 2
 
        ttk.Label(frame, text="Sexo").grid(row=fila_extra, column=0, sticky="e", padx=5, pady=4)
        combo_sexo = ttk.Combobox(frame, textvariable=self.vars["sexo"], values=["M", "F"], width=5, state="readonly")
        combo_sexo.grid(row=fila_extra, column=1, sticky="w", padx=5, pady=4)
 
        ttk.Checkbutton(frame, text="Activo", variable=self.var_estado).grid(
            row=fila_extra, column=2, sticky="w", padx=5, pady=4
        )
 
    def _construir_botones(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        ttk.Button(frame, text="Nuevo", command=self._limpiar_formulario).pack(side="left", padx=5)
        ttk.Button(frame, text="Guardar", command=self._guardar).pack(side="left", padx=5)
        ttk.Button(frame, text="Eliminar", command=self._eliminar).pack(side="left", padx=5)
        ttk.Button(frame, text="Cerrar", command=self.destroy).pack(side="right", padx=5)
 
    # ---------------- Logica ----------------
    def cargar_personas(self):
        filtro = self.entry_buscar.get().strip()
        try:
            filas = db.listar_personas(self.conn, filtro)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo consultar PERSONA.\n\n{e}")
            return
 
        self.tabla.delete(*self.tabla.get_children())
        for fila in filas:
            self.tabla.insert("", "end", values=list(fila))
 
    def _mostrar_todos(self):
        self.entry_buscar.delete(0, "end")
        self.cargar_personas()
 
    def _al_seleccionar_fila(self, event):
        seleccion = self.tabla.selection()
        if not seleccion:
            return
        valores = self.tabla.item(seleccion[0], "values")
 
        self.id_persona_seleccionada = int(valores[0])
        self.vars["cedula"].set(valores[1])
        self.vars["nombre"].set(valores[2])
        self.vars["primer_apellido"].set(valores[3])
        self.vars["segundo_apellido"].set(valores[4] if valores[4] != "None" else "")
        self.vars["fecha_nacimiento"].set(str(valores[5])[:10])
        self.vars["sexo"].set(valores[6])
        self.vars["telefono"].set(valores[7])
        self.vars["correo"].set(valores[8])
        self.vars["direccion"].set(valores[9])
        self.var_estado.set(str(valores[10]) in ("True", "1"))
 
    def _limpiar_formulario(self):
        self.id_persona_seleccionada = None
        for var in self.vars.values():
            var.set("")
        self.vars["sexo"].set("M")
        self.var_estado.set(True)
        self.tabla.selection_remove(self.tabla.selection())
 
    def _leer_formulario(self) -> dict:
        return {
            "cedula": self.vars["cedula"].get().strip(),
            "nombre": self.vars["nombre"].get().strip(),
            "primer_apellido": self.vars["primer_apellido"].get().strip(),
            "segundo_apellido": self.vars["segundo_apellido"].get().strip(),
            "fecha_nacimiento": self.vars["fecha_nacimiento"].get().strip(),
            "sexo": self.vars["sexo"].get(),
            "telefono": self.vars["telefono"].get().strip(),
            "correo": self.vars["correo"].get().strip(),
            "direccion": self.vars["direccion"].get().strip(),
            "estado": 1 if self.var_estado.get() else 0,
        }
 
    def _validar(self, data: dict) -> bool:
        obligatorios = ["cedula", "nombre", "primer_apellido", "fecha_nacimiento", "telefono"]
        faltantes = [c for c in obligatorios if not data[c]]
        if faltantes:
            messagebox.showwarning("Datos incompletos", f"Faltan campos: {', '.join(faltantes)}")
            return False
        return True
 
    def _guardar(self):
        data = self._leer_formulario()
        if not self._validar(data):
            return
 
        try:
            if self.id_persona_seleccionada is None:
                db.crear_persona(self.conn, data)
                messagebox.showinfo("Exito", "Persona creada correctamente.")
            else:
                db.actualizar_persona(self.conn, self.id_persona_seleccionada, data)
                messagebox.showinfo("Exito", "Persona actualizada correctamente.")
        except pyodbc.Error as e:
            messagebox.showerror("Error al guardar", str(e))
            return
 
        self._limpiar_formulario()
        self.cargar_personas()
 
    def _eliminar(self):
        if self.id_persona_seleccionada is None:
            messagebox.showwarning("Sin seleccion", "Selecciona una persona de la tabla primero.")
            return
 
        confirmar = messagebox.askyesno(
            "Confirmar", "¿Seguro que deseas eliminar esta persona? Esta accion no se puede deshacer."
        )
        if not confirmar:
            return
 
        try:
            db.eliminar_persona(self.conn, self.id_persona_seleccionada)
            messagebox.showinfo("Exito", "Persona eliminada.")
        except pyodbc.Error as e:
            messagebox.showerror(
                "Error al eliminar",
                f"No se pudo eliminar (puede tener registros relacionados, ej. EMPLEADO/PACIENTE).\n\n{e}",
            )
            return
 
        self._limpiar_formulario()
        self.cargar_personas()

# ==========================================================
# CRUD PACIENTE
# ==========================================================
class VentanaPacientes(tk.Toplevel):
    def __init__(self, parent, conn):
        super().__init__(parent)
        self.conn = conn
        self.id_paciente_seleccionado = None
        self.id_persona_enganchada = None
 
        self.title("Gestion de Pacientes")
        self.geometry("1000x560")
 
        self._construir_barra_busqueda()
        self._construir_tabla()
        self._construir_formulario()
        self._construir_botones()
 
        self.cargar_pacientes()
 
    # ---------------- UI ----------------
    def _construir_barra_busqueda(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(10, 0))
 
        ttk.Label(frame, text="Buscar (cedula / nombre / apellido):").pack(side="left")
        self.entry_buscar = ttk.Entry(frame, width=30)
        self.entry_buscar.pack(side="left", padx=5)
        self.entry_buscar.bind("<Return>", lambda e: self.cargar_pacientes())
 
        ttk.Button(frame, text="Buscar", command=self.cargar_pacientes).pack(side="left", padx=5)
        ttk.Button(frame, text="Mostrar todos", command=self._mostrar_todos).pack(side="left")
 
    def _construir_tabla(self):
        columnas = ("ID Paciente", "ID Persona", "Cedula", "Nombre", "Ap. Primero",
                    "Tipo Sangre", "Seguro Medico", "Contacto", "Tel. Contacto",
                    "Parentesco", "F. Registro")
 
        self.tabla = ttk.Treeview(self, columns=columnas, show="headings", height=12)
        for col in columnas:
            self.tabla.heading(col, text=col)
            self.tabla.column(col, width=90, anchor="w")
        self.tabla.column("Seguro Medico", width=130)
        self.tabla.column("Contacto", width=130)
 
        self.tabla.pack(fill="both", expand=True, padx=10, pady=10)
        self.tabla.bind("<<TreeviewSelect>>", self._al_seleccionar_fila)
 
    def _construir_formulario(self):
        # --- sub-frame: enganchar persona por cedula ---
        frame_persona = ttk.LabelFrame(self, text="Persona asociada")
        frame_persona.pack(fill="x", padx=10, pady=(0, 5))
 
        ttk.Label(frame_persona, text="Cedula:").pack(side="left", padx=(5, 0))
        self.entry_cedula_paciente = ttk.Entry(frame_persona, width=15)
        self.entry_cedula_paciente.pack(side="left", padx=5)
 
        ttk.Button(
            frame_persona, text="Buscar persona", command=self._buscar_persona
        ).pack(side="left", padx=5)
 
        self.label_persona_enganchada = ttk.Label(frame_persona, text="(sin persona seleccionada)")
        self.label_persona_enganchada.pack(side="left", padx=10)
 
        
        frame = ttk.LabelFrame(self, text="Datos del paciente")
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        self.vars = {
            "tipo_sangre": tk.StringVar(),
            "seguro_medico": tk.StringVar(),
            "nombre_contacto": tk.StringVar(),
            "telefono_contacto": tk.StringVar(),
            "parentesco": tk.StringVar(),
        }
 
        campos = [
            ("Tipo de sangre", "tipo_sangre"), ("Seguro medico", "seguro_medico"),
            ("Nombre de contacto", "nombre_contacto"), ("Telefono de contacto", "telefono_contacto"),
            ("Parentesco", "parentesco"),
        ]
 
        for idx, (etiqueta, clave) in enumerate(campos):
            fila, columna = divmod(idx, 2)
            ttk.Label(frame, text=etiqueta).grid(row=fila, column=columna * 2, sticky="e", padx=5, pady=4)
            ttk.Entry(frame, textvariable=self.vars[clave], width=28).grid(
                row=fila, column=columna * 2 + 1, sticky="w", padx=5, pady=4
            )
 
    def _construir_botones(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        ttk.Button(frame, text="Nuevo", command=self._limpiar_formulario).pack(side="left", padx=5)
        ttk.Button(frame, text="Guardar", command=self._guardar).pack(side="left", padx=5)
        ttk.Button(frame, text="Eliminar", command=self._eliminar).pack(side="left", padx=5)
        ttk.Button(frame, text="Cerrar", command=self.destroy).pack(side="right", padx=5)
 
    # ---------------- Logica ----------------
    def cargar_pacientes(self):
        filtro = self.entry_buscar.get().strip()
        try:
            filas = db.listar_pacientes(self.conn, filtro)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo consultar PACIENTE.\n\n{e}")
            return
 
        self.tabla.delete(*self.tabla.get_children())
        for fila in filas:
            self.tabla.insert("", "end", values=list(fila))
 
    def _mostrar_todos(self):
        self.entry_buscar.delete(0, "end")
        self.cargar_pacientes()
 
    def _buscar_persona(self):
        cedula = self.entry_cedula_paciente.get().strip()
        if not cedula:
            messagebox.showwarning("Falta cedula", "Escribe una cedula para buscar.")
            return
 
        try:
            persona = db.buscar_persona_por_cedula(self.conn, cedula)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo buscar la persona.\n\n{e}")
            return
 
        if persona is None:
            messagebox.showwarning("No encontrada", "No existe una persona con esa cedula.")
            self.id_persona_enganchada = None
            self.label_persona_enganchada.config(text="(sin persona seleccionada)")
            return
 
        id_persona, nombre, primer_apellido = persona
        self.id_persona_enganchada = id_persona
        self.label_persona_enganchada.config(text=f"{nombre} {primer_apellido} (ID {id_persona})")
 
    def _al_seleccionar_fila(self, event):
        seleccion = self.tabla.selection()
        if not seleccion:
            return
        valores = self.tabla.item(seleccion[0], "values")
 
        self.id_paciente_seleccionado = int(valores[0])
        self.id_persona_enganchada = int(valores[1])
        self.label_persona_enganchada.config(text=f"{valores[3]} {valores[4]} (ID {valores[1]})")
        self.entry_cedula_paciente.delete(0, "end")
        self.entry_cedula_paciente.insert(0, valores[2])
 
        self.vars["tipo_sangre"].set(valores[5] if valores[5] != "None" else "")
        self.vars["seguro_medico"].set(valores[6] if valores[6] != "None" else "")
        self.vars["nombre_contacto"].set(valores[7] if valores[7] != "None" else "")
        self.vars["telefono_contacto"].set(valores[8] if valores[8] != "None" else "")
        self.vars["parentesco"].set(valores[9] if valores[9] != "None" else "")
 
    def _limpiar_formulario(self):
        self.id_paciente_seleccionado = None
        self.id_persona_enganchada = None
        self.label_persona_enganchada.config(text="(sin persona seleccionada)")
        self.entry_cedula_paciente.delete(0, "end")
        for var in self.vars.values():
            var.set("")
        self.tabla.selection_remove(self.tabla.selection())
 
    def _leer_formulario(self) -> dict:
        return {
            "id_persona": self.id_persona_enganchada,
            "tipo_sangre": self.vars["tipo_sangre"].get().strip(),
            "seguro_medico": self.vars["seguro_medico"].get().strip(),
            "nombre_contacto": self.vars["nombre_contacto"].get().strip(),
            "telefono_contacto": self.vars["telefono_contacto"].get().strip(),
            "parentesco": self.vars["parentesco"].get().strip(),
        }
 
    def _validar(self, data: dict) -> bool:
        # Solo se exige la persona enganchada al CREAR; al editar, la
        # persona ya viene fija desde la fila seleccionada.
        if self.id_paciente_seleccionado is None and data["id_persona"] is None:
            messagebox.showwarning(
                "Falta persona", "Busca y selecciona una persona por cedula antes de guardar."
            )
            return False
        return True
 
    def _guardar(self):
        data = self._leer_formulario()
        if not self._validar(data):
            return
 
        try:
            if self.id_paciente_seleccionado is None:
                db.crear_paciente(self.conn, data)
                messagebox.showinfo("Exito", "Paciente creado correctamente.")
            else:
                db.actualizar_paciente(self.conn, self.id_paciente_seleccionado, data)
                messagebox.showinfo("Exito", "Paciente actualizado correctamente.")
        except pyodbc.Error as e:
            messagebox.showerror("Error al guardar", str(e))
            return
 
        self._limpiar_formulario()
        self.cargar_pacientes()
 
    def _eliminar(self):
        if self.id_paciente_seleccionado is None:
            messagebox.showwarning("Sin seleccion", "Selecciona un paciente de la tabla primero.")
            return
 
        confirmar = messagebox.askyesno(
            "Confirmar", "¿Seguro que deseas eliminar este paciente? Esta accion no se puede deshacer."
        )
        if not confirmar:
            return
 
        try:
            db.eliminar_paciente(self.conn, self.id_paciente_seleccionado)
            messagebox.showinfo("Exito", "Paciente eliminado.")
        except pyodbc.Error as e:
            messagebox.showerror(
                "Error al eliminar",
                f"No se pudo eliminar (puede tener registros relacionados, ej. EXPEDIENTE/CONSULTA).\n\n{e}",
            )
            return
 
        self._limpiar_formulario()
        self.cargar_pacientes()

# ==========================================================
# CRUD EXPEDIENTE
# ==========================================================
class VentanaExpedientes(tk.Toplevel):
    def __init__(self, parent, conn):
        super().__init__(parent)
        self.conn = conn
        self.id_expediente_seleccionado = None
        self.id_paciente_enganchado = None
 
        self.title("Gestion de Expedientes")
        self.geometry("1000x620")
 
        self._construir_barra_busqueda()
        self._construir_tabla()
        self._construir_formulario()
        self._construir_botones()
 
        self.cargar_expedientes()
 
    # ---------------- UI ----------------
    def _construir_barra_busqueda(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(10, 0))
 
        ttk.Label(frame, text="Buscar (cedula / nombre / apellido):").pack(side="left")
        self.entry_buscar = ttk.Entry(frame, width=30)
        self.entry_buscar.pack(side="left", padx=5)
        self.entry_buscar.bind("<Return>", lambda e: self.cargar_expedientes())
 
        ttk.Button(frame, text="Buscar", command=self.cargar_expedientes).pack(side="left", padx=5)
        ttk.Button(frame, text="Mostrar todos", command=self._mostrar_todos).pack(side="left")
 
    def _construir_tabla(self):
        columnas = ("ID Expediente", "ID Paciente", "Cedula", "Nombre", "Ap. Primero",
                    "Alergias", "Enf. Cronicas", "Antecedentes", "Observaciones", "F. Creacion")
 
        self.tabla = ttk.Treeview(self, columns=columnas, show="headings", height=10)
        for col in columnas:
            self.tabla.heading(col, text=col)
            self.tabla.column(col, width=90, anchor="w")
        self.tabla.column("Alergias", width=130)
        self.tabla.column("Enf. Cronicas", width=130)
        self.tabla.column("Antecedentes", width=130)
        self.tabla.column("Observaciones", width=150)
 
        self.tabla.pack(fill="both", expand=True, padx=10, pady=10)
        self.tabla.bind("<<TreeviewSelect>>", self._al_seleccionar_fila)
 
    def _construir_formulario(self):
        # --- sub-frame: enganchar paciente por cedula ---
        frame_paciente = ttk.LabelFrame(self, text="Paciente asociado")
        frame_paciente.pack(fill="x", padx=10, pady=(0, 5))
 
        ttk.Label(frame_paciente, text="Cedula:").pack(side="left", padx=(5, 0))
        self.entry_cedula_expediente = ttk.Entry(frame_paciente, width=15)
        self.entry_cedula_expediente.pack(side="left", padx=5)
 
        ttk.Button(
            frame_paciente, text="Buscar paciente", command=self._buscar_paciente
        ).pack(side="left", padx=5)
 
        self.label_paciente_enganchado = ttk.Label(frame_paciente, text="(sin paciente seleccionado)")
        self.label_paciente_enganchado.pack(side="left", padx=10)
 
        # --- sub-frame: datos propios de EXPEDIENTE ---
        frame = ttk.LabelFrame(self, text="Datos del expediente")
        frame.pack(fill="both", expand=True, padx=10, pady=(0, 10))
 
        self.texts = {}
        campos = [
            ("Alergias", "alergias"),
            ("Enfermedades cronicas", "enfermedades_cronicas"),
            ("Antecedentes", "antecedentes"),
            ("Observaciones", "observaciones"),
        ]
 
        for idx, (etiqueta, clave) in enumerate(campos):
            ttk.Label(frame, text=etiqueta).grid(row=idx, column=0, sticky="ne", padx=5, pady=4)
            caja = tk.Text(frame, width=70, height=3, wrap="word")
            caja.grid(row=idx, column=1, sticky="w", padx=5, pady=4)
            self.texts[clave] = caja
 
    def _construir_botones(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        ttk.Button(frame, text="Nuevo", command=self._limpiar_formulario).pack(side="left", padx=5)
        ttk.Button(frame, text="Guardar", command=self._guardar).pack(side="left", padx=5)
        ttk.Button(frame, text="Eliminar", command=self._eliminar).pack(side="left", padx=5)
        ttk.Button(frame, text="Cerrar", command=self.destroy).pack(side="right", padx=5)
 
    # ---------------- Logica ----------------
    def cargar_expedientes(self):
        filtro = self.entry_buscar.get().strip()
        try:
            filas = db.listar_expedientes(self.conn, filtro)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo consultar EXPEDIENTE.\n\n{e}")
            return
 
        self.tabla.delete(*self.tabla.get_children())
        for fila in filas:
            self.tabla.insert("", "end", values=list(fila))
 
    def _mostrar_todos(self):
        self.entry_buscar.delete(0, "end")
        self.cargar_expedientes()
 
    def _buscar_paciente(self):
        cedula = self.entry_cedula_expediente.get().strip()
        if not cedula:
            messagebox.showwarning("Falta cedula", "Escribe una cedula para buscar.")
            return
 
        try:
            paciente = db.buscar_paciente_por_cedula(self.conn, cedula)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo buscar el paciente.\n\n{e}")
            return
 
        if paciente is None:
            messagebox.showwarning(
                "No encontrado", "Esa cedula no pertenece a ningun paciente registrado."
            )
            self.id_paciente_enganchado = None
            self.label_paciente_enganchado.config(text="(sin paciente seleccionado)")
            return
 
        id_paciente, nombre, primer_apellido = paciente
        self.id_paciente_enganchado = id_paciente
        self.label_paciente_enganchado.config(text=f"{nombre} {primer_apellido} (ID Paciente {id_paciente})")
 
    def _al_seleccionar_fila(self, event):
        seleccion = self.tabla.selection()
        if not seleccion:
            return
        valores = self.tabla.item(seleccion[0], "values")
 
        self.id_expediente_seleccionado = int(valores[0])
        self.id_paciente_enganchado = int(valores[1])
        self.label_paciente_enganchado.config(text=f"{valores[3]} {valores[4]} (ID Paciente {valores[1]})")
        self.entry_cedula_expediente.delete(0, "end")
        self.entry_cedula_expediente.insert(0, valores[2])
 
        campos_valores = {
            "alergias": valores[5], "enfermedades_cronicas": valores[6],
            "antecedentes": valores[7], "observaciones": valores[8],
        }
        for clave, valor in campos_valores.items():
            self.texts[clave].delete("1.0", "end")
            self.texts[clave].insert("1.0", valor if valor != "None" else "")
 
    def _limpiar_formulario(self):
        self.id_expediente_seleccionado = None
        self.id_paciente_enganchado = None
        self.label_paciente_enganchado.config(text="(sin paciente seleccionado)")
        self.entry_cedula_expediente.delete(0, "end")
        for caja in self.texts.values():
            caja.delete("1.0", "end")
        self.tabla.selection_remove(self.tabla.selection())
 
    def _leer_formulario(self) -> dict:
        return {
            "id_paciente": self.id_paciente_enganchado,
            "alergias": self.texts["alergias"].get("1.0", "end").strip(),
            "enfermedades_cronicas": self.texts["enfermedades_cronicas"].get("1.0", "end").strip(),
            "antecedentes": self.texts["antecedentes"].get("1.0", "end").strip(),
            "observaciones": self.texts["observaciones"].get("1.0", "end").strip(),
        }
 
    def _validar(self, data: dict) -> bool:
        # Solo se exige el paciente enganchado al CREAR; al editar, el
        # paciente ya viene fijo desde la fila seleccionada.
        if self.id_expediente_seleccionado is None and data["id_paciente"] is None:
            messagebox.showwarning(
                "Falta paciente", "Busca y selecciona un paciente por cedula antes de guardar."
            )
            return False
        return True
 
    def _guardar(self):
        data = self._leer_formulario()
        if not self._validar(data):
            return
 
        try:
            if self.id_expediente_seleccionado is None:
                db.crear_expediente(self.conn, data)
                messagebox.showinfo("Exito", "Expediente creado correctamente.")
            else:
                db.actualizar_expediente(self.conn, self.id_expediente_seleccionado, data)
                messagebox.showinfo("Exito", "Expediente actualizado correctamente.")
        except pyodbc.Error as e:
            messagebox.showerror("Error al guardar", str(e))
            return
 
        self._limpiar_formulario()
        self.cargar_expedientes()
 
    def _eliminar(self):
        if self.id_expediente_seleccionado is None:
            messagebox.showwarning("Sin seleccion", "Selecciona un expediente de la tabla primero.")
            return
 
        confirmar = messagebox.askyesno(
            "Confirmar", "¿Seguro que deseas eliminar este expediente? Esta accion no se puede deshacer."
        )
        if not confirmar:
            return
 
        try:
            db.eliminar_expediente(self.conn, self.id_expediente_seleccionado)
            messagebox.showinfo("Exito", "Expediente eliminado.")
        except pyodbc.Error as e:
            messagebox.showerror(
                "Error al eliminar",
                f"No se pudo eliminar (puede tener registros relacionados, ej. CONSULTA).\n\n{e}",
            )
            return
 
        self._limpiar_formulario()
        self.cargar_expedientes()

# ==========================================================
# CRUD EMPLEADO
# ==========================================================

class VentanaEmpleados(tk.Toplevel):
    def __init__(self, parent, conn):
        super().__init__(parent)
        self.conn = conn
        self.id_empleado_seleccionado = None
        self.id_persona_enganchada = None
 
        self.title("Gestion de Empleados")
        self.geometry("1000x560")
 
        self._construir_barra_busqueda()
        self._construir_tabla()
        self._construir_formulario()
        self._construir_botones()
 
        self.cargar_empleados()
 
    # ---------------- UI ----------------
    def _construir_barra_busqueda(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(10, 0))
 
        ttk.Label(frame, text="Buscar (cedula / nombre / apellido):").pack(side="left")
        self.entry_buscar = ttk.Entry(frame, width=30)
        self.entry_buscar.pack(side="left", padx=5)
        self.entry_buscar.bind("<Return>", lambda e: self.cargar_empleados())
 
        ttk.Button(frame, text="Buscar", command=self.cargar_empleados).pack(side="left", padx=5)
        ttk.Button(frame, text="Mostrar todos", command=self._mostrar_todos).pack(side="left")
 
    def _construir_tabla(self):
        columnas = ("ID Empleado", "ID Persona", "Cedula", "Nombre", "Ap. Primero",
                    "Puesto", "F. Ingreso", "Salario", "Estado Laboral")
 
        self.tabla = ttk.Treeview(self, columns=columnas, show="headings", height=12)
        for col in columnas:
            self.tabla.heading(col, text=col)
            self.tabla.column(col, width=95, anchor="w")
 
        self.tabla.pack(fill="both", expand=True, padx=10, pady=10)
        self.tabla.bind("<<TreeviewSelect>>", self._al_seleccionar_fila)
 
    def _construir_formulario(self):
        # --- sub-frame: enganchar persona por cedula ---
        frame_persona = ttk.LabelFrame(self, text="Persona asociada")
        frame_persona.pack(fill="x", padx=10, pady=(0, 5))
 
        ttk.Label(frame_persona, text="Cedula:").pack(side="left", padx=(5, 0))
        self.entry_cedula_empleado = ttk.Entry(frame_persona, width=15)
        self.entry_cedula_empleado.pack(side="left", padx=5)
 
        ttk.Button(
            frame_persona, text="Buscar persona", command=self._buscar_persona
        ).pack(side="left", padx=5)
 
        self.label_persona_enganchada = ttk.Label(frame_persona, text="(sin persona seleccionada)")
        self.label_persona_enganchada.pack(side="left", padx=10)
 
        frame = ttk.LabelFrame(self, text="Datos del empleado")
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        self.vars = {
            "puesto": tk.StringVar(),
            "fecha_ingreso": tk.StringVar(),
            "salario": tk.StringVar(),
            "estado_laboral": tk.StringVar(value=ESTADOS_LABORALES[0]),
        }
 
        ttk.Label(frame, text="Puesto").grid(row=0, column=0, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.vars["puesto"], width=28).grid(
            row=0, column=1, sticky="w", padx=5, pady=4
        )
 
        ttk.Label(frame, text="F. Ingreso (AAAA-MM-DD)").grid(row=0, column=2, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.vars["fecha_ingreso"], width=28).grid(
            row=0, column=3, sticky="w", padx=5, pady=4
        )
 
        ttk.Label(frame, text="Salario").grid(row=1, column=0, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.vars["salario"], width=28).grid(
            row=1, column=1, sticky="w", padx=5, pady=4
        )
 
        ttk.Label(frame, text="Estado laboral").grid(row=1, column=2, sticky="e", padx=5, pady=4)
        ttk.Combobox(
            frame, textvariable=self.vars["estado_laboral"], values=ESTADOS_LABORALES,
            width=25, state="readonly",
        ).grid(row=1, column=3, sticky="w", padx=5, pady=4)
 
    def _construir_botones(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        ttk.Button(frame, text="Nuevo", command=self._limpiar_formulario).pack(side="left", padx=5)
        ttk.Button(frame, text="Guardar", command=self._guardar).pack(side="left", padx=5)
        ttk.Button(frame, text="Eliminar", command=self._eliminar).pack(side="left", padx=5)
        ttk.Button(frame, text="Cerrar", command=self.destroy).pack(side="right", padx=5)
 
    # ---------------- Logica ----------------
    def cargar_empleados(self):
        filtro = self.entry_buscar.get().strip()
        try:
            filas = db.listar_empleados(self.conn, filtro)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo consultar EMPLEADO.\n\n{e}")
            return
 
        self.tabla.delete(*self.tabla.get_children())
        for fila in filas:
            self.tabla.insert("", "end", values=list(fila))
 
    def _mostrar_todos(self):
        self.entry_buscar.delete(0, "end")
        self.cargar_empleados()
 
    def _buscar_persona(self):
        cedula = self.entry_cedula_empleado.get().strip()
        if not cedula:
            messagebox.showwarning("Falta cedula", "Escribe una cedula para buscar.")
            return
 
        try:
            persona = db.buscar_persona_por_cedula(self.conn, cedula)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo buscar la persona.\n\n{e}")
            return
 
        if persona is None:
            messagebox.showwarning("No encontrada", "No existe una persona con esa cedula.")
            self.id_persona_enganchada = None
            self.label_persona_enganchada.config(text="(sin persona seleccionada)")
            return
 
        id_persona, nombre, primer_apellido = persona
        self.id_persona_enganchada = id_persona
        self.label_persona_enganchada.config(text=f"{nombre} {primer_apellido} (ID {id_persona})")
 
    def _al_seleccionar_fila(self, event):
        seleccion = self.tabla.selection()
        if not seleccion:
            return
        valores = self.tabla.item(seleccion[0], "values")
 
        self.id_empleado_seleccionado = int(valores[0])
        self.id_persona_enganchada = int(valores[1])
        self.label_persona_enganchada.config(text=f"{valores[3]} {valores[4]} (ID {valores[1]})")
        self.entry_cedula_empleado.delete(0, "end")
        self.entry_cedula_empleado.insert(0, valores[2])
 
        self.vars["puesto"].set(valores[5])
        self.vars["fecha_ingreso"].set(str(valores[6])[:10])
        self.vars["salario"].set(valores[7])
        self.vars["estado_laboral"].set(valores[8])
 
    def _limpiar_formulario(self):
        self.id_empleado_seleccionado = None
        self.id_persona_enganchada = None
        self.label_persona_enganchada.config(text="(sin persona seleccionada)")
        self.entry_cedula_empleado.delete(0, "end")
        self.vars["puesto"].set("")
        self.vars["fecha_ingreso"].set("")
        self.vars["salario"].set("")
        self.vars["estado_laboral"].set(ESTADOS_LABORALES[0])
        self.tabla.selection_remove(self.tabla.selection())
 
    def _leer_formulario(self) -> dict:
        return {
            "id_persona": self.id_persona_enganchada,
            "puesto": self.vars["puesto"].get().strip(),
            "fecha_ingreso": self.vars["fecha_ingreso"].get().strip(),
            "salario": self.vars["salario"].get().strip(),
            "estado_laboral": self.vars["estado_laboral"].get(),
        }
 
    def _validar(self, data: dict) -> bool:
        if self.id_empleado_seleccionado is None and data["id_persona"] is None:
            messagebox.showwarning(
                "Falta persona", "Busca y selecciona una persona por cedula antes de guardar."
            )
            return False
 
        obligatorios = ["puesto", "fecha_ingreso", "salario", "estado_laboral"]
        faltantes = [c for c in obligatorios if not data[c]]
        if faltantes:
            messagebox.showwarning("Datos incompletos", f"Faltan campos: {', '.join(faltantes)}")
            return False
 
        try:
            float(data["salario"])
        except ValueError:
            messagebox.showwarning("Salario invalido", "El salario debe ser un numero (ej. 850000.00).")
            return False
 
        return True
 
    def _guardar(self):
        data = self._leer_formulario()
        if not self._validar(data):
            return
 
        try:
            if self.id_empleado_seleccionado is None:
                db.crear_empleado(self.conn, data)
                messagebox.showinfo("Exito", "Empleado creado correctamente.")
            else:
                db.actualizar_empleado(self.conn, self.id_empleado_seleccionado, data)
                messagebox.showinfo("Exito", "Empleado actualizado correctamente.")
        except pyodbc.Error as e:
            messagebox.showerror("Error al guardar", str(e))
            return
 
        self._limpiar_formulario()
        self.cargar_empleados()
 
    def _eliminar(self):
        if self.id_empleado_seleccionado is None:
            messagebox.showwarning("Sin seleccion", "Selecciona un empleado de la tabla primero.")
            return
 
        confirmar = messagebox.askyesno(
            "Confirmar", "¿Seguro que deseas eliminar este empleado? Esta accion no se puede deshacer."
        )
        if not confirmar:
            return
 
        try:
            db.eliminar_empleado(self.conn, self.id_empleado_seleccionado)
            messagebox.showinfo("Exito", "Empleado eliminado.")
        except pyodbc.Error as e:
            messagebox.showerror(
                "Error al eliminar",
                f"No se pudo eliminar (puede tener registros relacionados, ej. USUARIO/CONSULTA).\n\n{e}",
            )
            return
 
        self._limpiar_formulario()
        self.cargar_empleados()
# ==========================================================
# CRUD USUARIO
# ==========================================================

class VentanaUsuarios(tk.Toplevel):
    def __init__(self, parent, conn):
        super().__init__(parent)
        self.conn = conn
        self.id_usuario_seleccionado = None
        self.id_empleado_enganchado = None
 
        self.title("Gestion de Usuarios")
        self.geometry("1000x520")
 
        self._construir_barra_busqueda()
        self._construir_tabla()
        self._construir_formulario()
        self._construir_botones()
 
        self.cargar_usuarios()
 
    # ---------------- UI ----------------
    def _construir_barra_busqueda(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(10, 0))
 
        ttk.Label(frame, text="Buscar (cedula / nombre / apellido / usuario):").pack(side="left")
        self.entry_buscar = ttk.Entry(frame, width=30)
        self.entry_buscar.pack(side="left", padx=5)
        self.entry_buscar.bind("<Return>", lambda e: self.cargar_usuarios())
 
        ttk.Button(frame, text="Buscar", command=self.cargar_usuarios).pack(side="left", padx=5)
        ttk.Button(frame, text="Mostrar todos", command=self._mostrar_todos).pack(side="left")
 
    def _construir_tabla(self):
        columnas = ("ID Usuario", "ID Empleado", "Cedula", "Nombre", "Ap. Primero",
                    "Usuario", "Clave", "Ultimo Acceso", "Activo")
 
        self.tabla = ttk.Treeview(self, columns=columnas, show="headings", height=12)
        for col in columnas:
            self.tabla.heading(col, text=col)
            self.tabla.column(col, width=100, anchor="w")
 
        self.tabla.pack(fill="both", expand=True, padx=10, pady=10)
        self.tabla.bind("<<TreeviewSelect>>", self._al_seleccionar_fila)
 
    def _construir_formulario(self):
        # --- sub-frame: enganchar empleado por cedula ---
        frame_empleado = ttk.LabelFrame(self, text="Empleado asociado")
        frame_empleado.pack(fill="x", padx=10, pady=(0, 5))
 
        ttk.Label(frame_empleado, text="Cedula:").pack(side="left", padx=(5, 0))
        self.entry_cedula_usuario = ttk.Entry(frame_empleado, width=15)
        self.entry_cedula_usuario.pack(side="left", padx=5)
 
        ttk.Button(
            frame_empleado, text="Buscar empleado", command=self._buscar_empleado
        ).pack(side="left", padx=5)
 
        self.label_empleado_enganchado = ttk.Label(frame_empleado, text="(sin empleado seleccionado)")
        self.label_empleado_enganchado.pack(side="left", padx=10)
 
        # --- sub-frame: datos propios de USUARIO ---
        frame = ttk.LabelFrame(self, text="Datos del usuario")
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        self.vars = {
            "usuario": tk.StringVar(),
            "clave_acceso": tk.StringVar(),
        }
        self.var_estado = tk.BooleanVar(value=True)
 
        ttk.Label(frame, text="Usuario").grid(row=0, column=0, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.vars["usuario"], width=28).grid(
            row=0, column=1, sticky="w", padx=5, pady=4
        )
 
        ttk.Label(frame, text="Clave de acceso").grid(row=0, column=2, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.vars["clave_acceso"], width=28).grid(
            row=0, column=3, sticky="w", padx=5, pady=4
        )
 
        ttk.Checkbutton(frame, text="Activo", variable=self.var_estado).grid(
            row=1, column=1, sticky="w", padx=5, pady=4
        )
 
    def _construir_botones(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        ttk.Button(frame, text="Nuevo", command=self._limpiar_formulario).pack(side="left", padx=5)
        ttk.Button(frame, text="Guardar", command=self._guardar).pack(side="left", padx=5)
        ttk.Button(frame, text="Eliminar", command=self._eliminar).pack(side="left", padx=5)
        ttk.Button(frame, text="Cerrar", command=self.destroy).pack(side="right", padx=5)
 
    # ---------------- Logica ----------------
    def cargar_usuarios(self):
        filtro = self.entry_buscar.get().strip()
        try:
            filas = db.listar_usuarios(self.conn, filtro)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo consultar USUARIO.\n\n{e}")
            return
 
        self.tabla.delete(*self.tabla.get_children())
        for fila in filas:
            self.tabla.insert("", "end", values=list(fila))
 
    def _mostrar_todos(self):
        self.entry_buscar.delete(0, "end")
        self.cargar_usuarios()
 
    def _buscar_empleado(self):
        cedula = self.entry_cedula_usuario.get().strip()
        if not cedula:
            messagebox.showwarning("Falta cedula", "Escribe una cedula para buscar.")
            return
 
        try:
            empleado = db.buscar_empleado_por_cedula(self.conn, cedula)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo buscar el empleado.\n\n{e}")
            return
 
        if empleado is None:
            messagebox.showwarning(
                "No encontrado", "Esa cedula no pertenece a ningun empleado registrado."
            )
            self.id_empleado_enganchado = None
            self.label_empleado_enganchado.config(text="(sin empleado seleccionado)")
            return
 
        id_empleado, nombre, primer_apellido = empleado
        self.id_empleado_enganchado = id_empleado
        self.label_empleado_enganchado.config(text=f"{nombre} {primer_apellido} (ID Empleado {id_empleado})")
 
    def _al_seleccionar_fila(self, event):
        seleccion = self.tabla.selection()
        if not seleccion:
            return
        valores = self.tabla.item(seleccion[0], "values")
 
        self.id_usuario_seleccionado = int(valores[0])
        self.id_empleado_enganchado = int(valores[1])
        self.label_empleado_enganchado.config(text=f"{valores[3]} {valores[4]} (ID Empleado {valores[1]})")
        self.entry_cedula_usuario.delete(0, "end")
        self.entry_cedula_usuario.insert(0, valores[2])
 
        self.vars["usuario"].set(valores[5])
        self.vars["clave_acceso"].set(valores[6])
        self.var_estado.set(str(valores[8]) in ("True", "1"))
 
    def _limpiar_formulario(self):
        self.id_usuario_seleccionado = None
        self.id_empleado_enganchado = None
        self.label_empleado_enganchado.config(text="(sin empleado seleccionado)")
        self.entry_cedula_usuario.delete(0, "end")
        self.vars["usuario"].set("")
        self.vars["clave_acceso"].set("")
        self.var_estado.set(True)
        self.tabla.selection_remove(self.tabla.selection())
 
    def _leer_formulario(self) -> dict:
        return {
            "id_empleado": self.id_empleado_enganchado,
            "usuario": self.vars["usuario"].get().strip(),
            "clave_acceso": self.vars["clave_acceso"].get(),
            "estado": 1 if self.var_estado.get() else 0,
        }
 
    def _validar(self, data: dict) -> bool:
        if self.id_usuario_seleccionado is None and data["id_empleado"] is None:
            messagebox.showwarning(
                "Falta empleado", "Busca y selecciona un empleado por cedula antes de guardar."
            )
            return False
 
        if not data["usuario"]:
            messagebox.showwarning("Datos incompletos", "Falta el nombre de usuario.")
            return False
 
        if not data["clave_acceso"]:
            messagebox.showwarning("Datos incompletos", "Falta la clave de acceso.")
            return False
 
        return True
 
    def _guardar(self):
        data = self._leer_formulario()
        if not self._validar(data):
            return
 
        try:
            if self.id_usuario_seleccionado is None:
                db.crear_usuario(self.conn, data)
                messagebox.showinfo("Exito", "Usuario creado correctamente.")
            else:
                db.actualizar_usuario(self.conn, self.id_usuario_seleccionado, data)
                messagebox.showinfo("Exito", "Usuario actualizado correctamente.")
        except pyodbc.Error as e:
            messagebox.showerror("Error al guardar", str(e))
            return
 
        self._limpiar_formulario()
        self.cargar_usuarios()
 
    def _eliminar(self):
        if self.id_usuario_seleccionado is None:
            messagebox.showwarning("Sin seleccion", "Selecciona un usuario de la tabla primero.")
            return
 
        confirmar = messagebox.askyesno(
            "Confirmar", "¿Seguro que deseas eliminar este usuario? Esta accion no se puede deshacer."
        )
        if not confirmar:
            return
 
        try:
            db.eliminar_usuario(self.conn, self.id_usuario_seleccionado)
            messagebox.showinfo("Exito", "Usuario eliminado.")
        except pyodbc.Error as e:
            messagebox.showerror(
                "Error al eliminar",
                f"No se pudo eliminar (puede tener registros relacionados, ej. AUDITORIA).\n\n{e}",
            )
            return
 
        self._limpiar_formulario()
        self.cargar_usuarios()

# ==========================================================
# CRUD MEDICO
# ==========================================================
class VentanaMedicos(tk.Toplevel):
    def __init__(self, parent, conn):
        super().__init__(parent)
        self.conn = conn
        self.id_medico_seleccionado = None
        self.id_empleado_enganchado = None
 
        self.title("Gestion de Medicos")
        self.geometry("1000x520")
 
        self._construir_barra_busqueda()
        self._construir_tabla()
        self._construir_formulario()
        self._construir_botones()
 
        self.cargar_medicos()
 
    # ---------------- UI ----------------
    def _construir_barra_busqueda(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(10, 0))
 
        ttk.Label(frame, text="Buscar (cedula / nombre / apellido / especialidad):").pack(side="left")
        self.entry_buscar = ttk.Entry(frame, width=30)
        self.entry_buscar.pack(side="left", padx=5)
        self.entry_buscar.bind("<Return>", lambda e: self.cargar_medicos())
 
        ttk.Button(frame, text="Buscar", command=self.cargar_medicos).pack(side="left", padx=5)
        ttk.Button(frame, text="Mostrar todos", command=self._mostrar_todos).pack(side="left")
 
    def _construir_tabla(self):
        columnas = ("ID Medico", "ID Empleado", "Cedula", "Nombre", "Ap. Primero",
                    "Cod. Colegiado", "Especialidad", "Consultorio")
 
        self.tabla = ttk.Treeview(self, columns=columnas, show="headings", height=12)
        for col in columnas:
            self.tabla.heading(col, text=col)
            self.tabla.column(col, width=100, anchor="w")
 
        self.tabla.pack(fill="both", expand=True, padx=10, pady=10)
        self.tabla.bind("<<TreeviewSelect>>", self._al_seleccionar_fila)
 
    def _construir_formulario(self):
        # --- sub-frame: enganchar empleado por cedula ---
        frame_empleado = ttk.LabelFrame(self, text="Empleado asociado")
        frame_empleado.pack(fill="x", padx=10, pady=(0, 5))
 
        ttk.Label(frame_empleado, text="Cedula:").pack(side="left", padx=(5, 0))
        self.entry_cedula_medico = ttk.Entry(frame_empleado, width=15)
        self.entry_cedula_medico.pack(side="left", padx=5)
 
        ttk.Button(
            frame_empleado, text="Buscar empleado", command=self._buscar_empleado
        ).pack(side="left", padx=5)
 
        self.label_empleado_enganchado = ttk.Label(frame_empleado, text="(sin empleado seleccionado)")
        self.label_empleado_enganchado.pack(side="left", padx=10)
 
        # --- sub-frame: datos propios de MEDICO ---
        frame = ttk.LabelFrame(self, text="Datos del medico")
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        self.vars = {
            "codigo_colegiado": tk.StringVar(),
            "especialidad": tk.StringVar(),
            "consultorio": tk.StringVar(),
        }
 
        ttk.Label(frame, text="Codigo colegiado").grid(row=0, column=0, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.vars["codigo_colegiado"], width=28).grid(
            row=0, column=1, sticky="w", padx=5, pady=4
        )
 
        ttk.Label(frame, text="Especialidad").grid(row=0, column=2, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.vars["especialidad"], width=28).grid(
            row=0, column=3, sticky="w", padx=5, pady=4
        )
 
        ttk.Label(frame, text="Consultorio").grid(row=1, column=0, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.vars["consultorio"], width=28).grid(
            row=1, column=1, sticky="w", padx=5, pady=4
        )
 
    def _construir_botones(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        ttk.Button(frame, text="Nuevo", command=self._limpiar_formulario).pack(side="left", padx=5)
        ttk.Button(frame, text="Guardar", command=self._guardar).pack(side="left", padx=5)
        ttk.Button(frame, text="Eliminar", command=self._eliminar).pack(side="left", padx=5)
        ttk.Button(frame, text="Cerrar", command=self.destroy).pack(side="right", padx=5)
 
    # ---------------- Logica ----------------
    def cargar_medicos(self):
        filtro = self.entry_buscar.get().strip()
        try:
            filas = db.listar_medicos(self.conn, filtro)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo consultar MEDICO.\n\n{e}")
            return
 
        self.tabla.delete(*self.tabla.get_children())
        for fila in filas:
            self.tabla.insert("", "end", values=list(fila))
 
    def _mostrar_todos(self):
        self.entry_buscar.delete(0, "end")
        self.cargar_medicos()
 
    def _buscar_empleado(self):
        cedula = self.entry_cedula_medico.get().strip()
        if not cedula:
            messagebox.showwarning("Falta cedula", "Escribe una cedula para buscar.")
            return
 
        try:
            empleado = db.buscar_empleado_por_cedula(self.conn, cedula)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo buscar el empleado.\n\n{e}")
            return
 
        if empleado is None:
            messagebox.showwarning(
                "No encontrado", "Esa cedula no pertenece a ningun empleado registrado."
            )
            self.id_empleado_enganchado = None
            self.label_empleado_enganchado.config(text="(sin empleado seleccionado)")
            return
 
        id_empleado, nombre, primer_apellido = empleado
        self.id_empleado_enganchado = id_empleado
        self.label_empleado_enganchado.config(text=f"{nombre} {primer_apellido} (ID Empleado {id_empleado})")
 
    def _al_seleccionar_fila(self, event):
        seleccion = self.tabla.selection()
        if not seleccion:
            return
        valores = self.tabla.item(seleccion[0], "values")
 
        self.id_medico_seleccionado = int(valores[0])
        self.id_empleado_enganchado = int(valores[1])
        self.label_empleado_enganchado.config(text=f"{valores[3]} {valores[4]} (ID Empleado {valores[1]})")
        self.entry_cedula_medico.delete(0, "end")
        self.entry_cedula_medico.insert(0, valores[2])
 
        self.vars["codigo_colegiado"].set(valores[5])
        self.vars["especialidad"].set(valores[6])
        self.vars["consultorio"].set(valores[7])
 
    def _limpiar_formulario(self):
        self.id_medico_seleccionado = None
        self.id_empleado_enganchado = None
        self.label_empleado_enganchado.config(text="(sin empleado seleccionado)")
        self.entry_cedula_medico.delete(0, "end")
        for var in self.vars.values():
            var.set("")
        self.tabla.selection_remove(self.tabla.selection())
 
    def _leer_formulario(self) -> dict:
        return {
            "id_empleado": self.id_empleado_enganchado,
            "codigo_colegiado": self.vars["codigo_colegiado"].get().strip(),
            "especialidad": self.vars["especialidad"].get().strip(),
            "consultorio": self.vars["consultorio"].get().strip(),
        }
 
    def _validar(self, data: dict) -> bool:
        if self.id_medico_seleccionado is None and data["id_empleado"] is None:
            messagebox.showwarning(
                "Falta empleado", "Busca y selecciona un empleado por cedula antes de guardar."
            )
            return False
 
        obligatorios = ["codigo_colegiado", "especialidad", "consultorio"]
        faltantes = [c for c in obligatorios if not data[c]]
        if faltantes:
            messagebox.showwarning("Datos incompletos", f"Faltan campos: {', '.join(faltantes)}")
            return False
 
        return True
 
    def _guardar(self):
        data = self._leer_formulario()
        if not self._validar(data):
            return
 
        try:
            if self.id_medico_seleccionado is None:
                db.crear_medico(self.conn, data)
                messagebox.showinfo("Exito", "Medico creado correctamente.")
            else:
                db.actualizar_medico(self.conn, self.id_medico_seleccionado, data)
                messagebox.showinfo("Exito", "Medico actualizado correctamente.")
        except pyodbc.Error as e:
            messagebox.showerror("Error al guardar", str(e))
            return
 
        self._limpiar_formulario()
        self.cargar_medicos()
 
    def _eliminar(self):
        if self.id_medico_seleccionado is None:
            messagebox.showwarning("Sin seleccion", "Selecciona un medico de la tabla primero.")
            return
 
        confirmar = messagebox.askyesno(
            "Confirmar", "¿Seguro que deseas eliminar este medico? Esta accion no se puede deshacer."
        )
        if not confirmar:
            return
 
        try:
            db.eliminar_medico(self.conn, self.id_medico_seleccionado)
            messagebox.showinfo("Exito", "Medico eliminado.")
        except pyodbc.Error as e:
            messagebox.showerror(
                "Error al eliminar",
                f"No se pudo eliminar (puede tener registros relacionados, ej. CONSULTA).\n\n{e}",
            )
            return
 
        self._limpiar_formulario()
        self.cargar_medicos()

# ==========================================================
# CRUD CONSULTA
# ==========================================================

class VentanaConsultas(tk.Toplevel):
    def __init__(self, parent, conn):
        super().__init__(parent)
        self.conn = conn
        self.id_consulta_seleccionada = None
        self.id_expediente_enganchado = None
        self.id_medico_enganchado = None
 
        self.title("Gestion de Consultas")
        self.geometry("1050x680")
 
        self._construir_barra_busqueda()
        self._construir_tabla()
        self._construir_formulario()
        self._construir_botones()
 
        self.cargar_consultas()
 
    # ---------------- UI ----------------
    def _construir_barra_busqueda(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(10, 0))
 
        ttk.Label(frame, text="Buscar (cedula / nombre / apellido del paciente):").pack(side="left")
        self.entry_buscar = ttk.Entry(frame, width=30)
        self.entry_buscar.pack(side="left", padx=5)
        self.entry_buscar.bind("<Return>", lambda e: self.cargar_consultas())
 
        ttk.Button(frame, text="Buscar", command=self.cargar_consultas).pack(side="left", padx=5)
        ttk.Button(frame, text="Mostrar todos", command=self._mostrar_todos).pack(side="left")
 
    def _construir_tabla(self):
        columnas = ("ID Consulta", "ID Expediente", "Cedula Pac.", "Nombre Pac.", "Ap. Pac.",
                    "ID Medico", "Nombre Med.", "Ap. Med.", "Fecha", "Motivo",
                    "Diagnostico", "Tratamiento", "Observaciones")
 
        self.tabla = ttk.Treeview(self, columns=columnas, show="headings", height=8)
        for col in columnas:
            self.tabla.heading(col, text=col)
            self.tabla.column(col, width=85, anchor="w")
 
        self.tabla.pack(fill="both", expand=True, padx=10, pady=10)
        self.tabla.bind("<<TreeviewSelect>>", self._al_seleccionar_fila)
 
    def _construir_formulario(self):
        # --- sub-frame: enganchar expediente (paciente) por cedula ---
        frame_pac = ttk.LabelFrame(self, text="Paciente / expediente asociado")
        frame_pac.pack(fill="x", padx=10, pady=(0, 5))
 
        ttk.Label(frame_pac, text="Cedula paciente:").pack(side="left", padx=(5, 0))
        self.entry_cedula_paciente = ttk.Entry(frame_pac, width=15)
        self.entry_cedula_paciente.pack(side="left", padx=5)
 
        ttk.Button(
            frame_pac, text="Buscar expediente", command=self._buscar_expediente
        ).pack(side="left", padx=5)
 
        self.label_expediente_enganchado = ttk.Label(frame_pac, text="(sin expediente seleccionado)")
        self.label_expediente_enganchado.pack(side="left", padx=10)
 
        # --- sub-frame: enganchar medico por cedula ---
        frame_med = ttk.LabelFrame(self, text="Medico asociado")
        frame_med.pack(fill="x", padx=10, pady=(0, 5))
 
        ttk.Label(frame_med, text="Cedula medico:").pack(side="left", padx=(5, 0))
        self.entry_cedula_medico = ttk.Entry(frame_med, width=15)
        self.entry_cedula_medico.pack(side="left", padx=5)
 
        ttk.Button(
            frame_med, text="Buscar medico", command=self._buscar_medico
        ).pack(side="left", padx=5)
 
        self.label_medico_enganchado = ttk.Label(frame_med, text="(sin medico seleccionado)")
        self.label_medico_enganchado.pack(side="left", padx=10)
 
        # --- sub-frame: datos propios de CONSULTA ---
        frame = ttk.LabelFrame(self, text="Datos de la consulta")
        frame.pack(fill="both", expand=True, padx=10, pady=(0, 10))
 
        self.vars = {
            "fecha": tk.StringVar(),
            "motivo": tk.StringVar(),
        }
 
        ttk.Label(frame, text="Fecha (AAAA-MM-DD HH:MM)").grid(row=0, column=0, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.vars["fecha"], width=28).grid(
            row=0, column=1, sticky="w", padx=5, pady=4
        )
 
        ttk.Label(frame, text="Motivo").grid(row=0, column=2, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.vars["motivo"], width=40).grid(
            row=0, column=3, sticky="w", padx=5, pady=4
        )
 
        self.texts = {}
        campos_largos = [
            ("Diagnostico", "diagnostico"),
            ("Tratamiento", "tratamiento"),
            ("Observaciones", "observaciones"),
        ]
        for idx, (etiqueta, clave) in enumerate(campos_largos, start=1):
            ttk.Label(frame, text=etiqueta).grid(row=idx, column=0, sticky="ne", padx=5, pady=4)
            caja = tk.Text(frame, width=70, height=3, wrap="word")
            caja.grid(row=idx, column=1, columnspan=3, sticky="w", padx=5, pady=4)
            self.texts[clave] = caja
 
    def _construir_botones(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        ttk.Button(frame, text="Nuevo", command=self._limpiar_formulario).pack(side="left", padx=5)
        ttk.Button(frame, text="Guardar", command=self._guardar).pack(side="left", padx=5)
        ttk.Button(frame, text="Eliminar", command=self._eliminar).pack(side="left", padx=5)
        ttk.Button(frame, text="Cerrar", command=self.destroy).pack(side="right", padx=5)
 
    # ---------------- Logica ----------------
    def cargar_consultas(self):
        filtro = self.entry_buscar.get().strip()
        try:
            filas = db.listar_consultas(self.conn, filtro)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo consultar CONSULTA.\n\n{e}")
            return
 
        self.tabla.delete(*self.tabla.get_children())
        for fila in filas:
            self.tabla.insert("", "end", values=list(fila))
 
    def _mostrar_todos(self):
        self.entry_buscar.delete(0, "end")
        self.cargar_consultas()
 
    def _buscar_expediente(self):
        cedula = self.entry_cedula_paciente.get().strip()
        if not cedula:
            messagebox.showwarning("Falta cedula", "Escribe una cedula para buscar.")
            return
 
        try:
            expediente = db.buscar_expediente_por_cedula(self.conn, cedula)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo buscar el expediente.\n\n{e}")
            return
 
        if expediente is None:
            messagebox.showwarning(
                "No encontrado", "Esa cedula no tiene expediente registrado."
            )
            self.id_expediente_enganchado = None
            self.label_expediente_enganchado.config(text="(sin expediente seleccionado)")
            return
 
        id_expediente, nombre, primer_apellido = expediente
        self.id_expediente_enganchado = id_expediente
        self.label_expediente_enganchado.config(
            text=f"{nombre} {primer_apellido} (ID Expediente {id_expediente})"
        )
 
    def _buscar_medico(self):
        cedula = self.entry_cedula_medico.get().strip()
        if not cedula:
            messagebox.showwarning("Falta cedula", "Escribe una cedula para buscar.")
            return
 
        try:
            medico = db.buscar_medico_por_cedula(self.conn, cedula)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo buscar el medico.\n\n{e}")
            return
 
        if medico is None:
            messagebox.showwarning(
                "No encontrado", "Esa cedula no pertenece a ningun medico registrado."
            )
            self.id_medico_enganchado = None
            self.label_medico_enganchado.config(text="(sin medico seleccionado)")
            return
 
        id_medico, nombre, primer_apellido = medico
        self.id_medico_enganchado = id_medico
        self.label_medico_enganchado.config(text=f"Dr(a). {nombre} {primer_apellido} (ID Medico {id_medico})")
 
    def _al_seleccionar_fila(self, event):
        seleccion = self.tabla.selection()
        if not seleccion:
            return
        valores = self.tabla.item(seleccion[0], "values")
 
        self.id_consulta_seleccionada = int(valores[0])
        self.id_expediente_enganchado = int(valores[1])
        self.id_medico_enganchado = int(valores[5])
 
        self.label_expediente_enganchado.config(text=f"{valores[3]} {valores[4]} (ID Expediente {valores[1]})")
        self.entry_cedula_paciente.delete(0, "end")
        self.entry_cedula_paciente.insert(0, valores[2])
 
        self.label_medico_enganchado.config(text=f"Dr(a). {valores[6]} {valores[7]} (ID Medico {valores[5]})")
        self.entry_cedula_medico.delete(0, "end")
 
        self.vars["fecha"].set(str(valores[8])[:16])
        self.vars["motivo"].set(valores[9])
 
        campos_valores = {
            "diagnostico": valores[10], "tratamiento": valores[11], "observaciones": valores[12],
        }
        for clave, valor in campos_valores.items():
            self.texts[clave].delete("1.0", "end")
            self.texts[clave].insert("1.0", valor if valor != "None" else "")
 
    def _limpiar_formulario(self):
        self.id_consulta_seleccionada = None
        self.id_expediente_enganchado = None
        self.id_medico_enganchado = None
        self.label_expediente_enganchado.config(text="(sin expediente seleccionado)")
        self.label_medico_enganchado.config(text="(sin medico seleccionado)")
        self.entry_cedula_paciente.delete(0, "end")
        self.entry_cedula_medico.delete(0, "end")
        self.vars["fecha"].set("")
        self.vars["motivo"].set("")
        for caja in self.texts.values():
            caja.delete("1.0", "end")
        self.tabla.selection_remove(self.tabla.selection())
 
    def _leer_formulario(self) -> dict:
        return {
            "id_expediente": self.id_expediente_enganchado,
            "id_medico": self.id_medico_enganchado,
            "fecha": self.vars["fecha"].get().strip(),
            "motivo": self.vars["motivo"].get().strip(),
            "diagnostico": self.texts["diagnostico"].get("1.0", "end").strip(),
            "tratamiento": self.texts["tratamiento"].get("1.0", "end").strip(),
            "observaciones": self.texts["observaciones"].get("1.0", "end").strip(),
        }
 
    def _validar(self, data: dict) -> bool:
        if self.id_consulta_seleccionada is None:
            if data["id_expediente"] is None:
                messagebox.showwarning(
                    "Falta paciente", "Busca y selecciona el expediente del paciente antes de guardar."
                )
                return False
            if data["id_medico"] is None:
                messagebox.showwarning(
                    "Falta medico", "Busca y selecciona el medico antes de guardar."
                )
                return False
 
        obligatorios = ["fecha", "motivo", "diagnostico"]
        faltantes = [c for c in obligatorios if not data[c]]
        if faltantes:
            messagebox.showwarning("Datos incompletos", f"Faltan campos: {', '.join(faltantes)}")
            return False
 
        return True
 
    def _guardar(self):
        data = self._leer_formulario()
        if not self._validar(data):
            return
 
        try:
            if self.id_consulta_seleccionada is None:
                db.crear_consulta(self.conn, data)
                messagebox.showinfo("Exito", "Consulta creada correctamente.")
            else:
                db.actualizar_consulta(self.conn, self.id_consulta_seleccionada, data)
                messagebox.showinfo("Exito", "Consulta actualizada correctamente.")
        except pyodbc.Error as e:
            messagebox.showerror("Error al guardar", str(e))
            return
 
        self._limpiar_formulario()
        self.cargar_consultas()
 
    def _eliminar(self):
        if self.id_consulta_seleccionada is None:
            messagebox.showwarning("Sin seleccion", "Selecciona una consulta de la tabla primero.")
            return
 
        confirmar = messagebox.askyesno(
            "Confirmar", "¿Seguro que deseas eliminar esta consulta? Esta accion no se puede deshacer."
        )
        if not confirmar:
            return
 
        try:
            db.eliminar_consulta(self.conn, self.id_consulta_seleccionada)
            messagebox.showinfo("Exito", "Consulta eliminada.")
        except pyodbc.Error as e:
            messagebox.showerror(
                "Error al eliminar",
                f"No se pudo eliminar (puede tener registros relacionados, ej. RECETA).\n\n{e}",
            )
            return
 
        self._limpiar_formulario()
        self.cargar_consultas()

# ==========================================================
# CRUD MEDICAMENTO
# ==========================================================

class VentanaMedicamentos(tk.Toplevel):
    def __init__(self, parent, conn):
        super().__init__(parent)
        self.conn = conn
        self.id_medicamento_seleccionado = None
 
        self.title("Gestion de Medicamentos")
        self.geometry("1000x560")
 
        self._construir_barra_busqueda()
        self._construir_tabla()
        self._construir_formulario()
        self._construir_botones()
 
        self.cargar_medicamentos()
 
    # ---------------- UI ----------------
    def _construir_barra_busqueda(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(10, 0))
 
        ttk.Label(frame, text="Buscar (nombre / fabricante):").pack(side="left")
        self.entry_buscar = ttk.Entry(frame, width=30)
        self.entry_buscar.pack(side="left", padx=5)
        self.entry_buscar.bind("<Return>", lambda e: self.cargar_medicamentos())
 
        ttk.Button(frame, text="Buscar", command=self.cargar_medicamentos).pack(side="left", padx=5)
        ttk.Button(frame, text="Mostrar todos", command=self._mostrar_todos).pack(side="left")
 
    def _construir_tabla(self):
        columnas = ("ID", "Nombre", "Descripcion", "Presentacion", "Concentracion",
                    "Precio", "Fabricante", "Req. Receta", "Activo")
 
        self.tabla = ttk.Treeview(self, columns=columnas, show="headings", height=12)
        for col in columnas:
            self.tabla.heading(col, text=col)
            self.tabla.column(col, width=95, anchor="w")
        self.tabla.column("Descripcion", width=150)
 
        self.tabla.pack(fill="both", expand=True, padx=10, pady=10)
        self.tabla.bind("<<TreeviewSelect>>", self._al_seleccionar_fila)
 
    def _construir_formulario(self):
        frame = ttk.LabelFrame(self, text="Datos del medicamento")
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        self.vars = {
            "nombre": tk.StringVar(),
            "descripcion": tk.StringVar(),
            "presentacion": tk.StringVar(),
            "concentracion": tk.StringVar(),
            "precio": tk.StringVar(),
            "fabricante": tk.StringVar(),
        }
        self.var_requiere_receta = tk.BooleanVar(value=False)
        self.var_estado = tk.BooleanVar(value=True)
 
        campos = [
            ("Nombre", "nombre"), ("Descripcion", "descripcion"),
            ("Presentacion", "presentacion"), ("Concentracion", "concentracion"),
            ("Precio", "precio"), ("Fabricante", "fabricante"),
        ]
 
        for idx, (etiqueta, clave) in enumerate(campos):
            fila, columna = divmod(idx, 2)
            ttk.Label(frame, text=etiqueta).grid(row=fila, column=columna * 2, sticky="e", padx=5, pady=4)
            ttk.Entry(frame, textvariable=self.vars[clave], width=28).grid(
                row=fila, column=columna * 2 + 1, sticky="w", padx=5, pady=4
            )
 
        fila_extra = len(campos) // 2
 
        ttk.Checkbutton(frame, text="Requiere receta", variable=self.var_requiere_receta).grid(
            row=fila_extra, column=0, columnspan=2, sticky="w", padx=5, pady=4
        )
        ttk.Checkbutton(frame, text="Activo", variable=self.var_estado).grid(
            row=fila_extra, column=2, columnspan=2, sticky="w", padx=5, pady=4
        )
 
    def _construir_botones(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        ttk.Button(frame, text="Nuevo", command=self._limpiar_formulario).pack(side="left", padx=5)
        ttk.Button(frame, text="Guardar", command=self._guardar).pack(side="left", padx=5)
        ttk.Button(frame, text="Eliminar", command=self._eliminar).pack(side="left", padx=5)
        ttk.Button(frame, text="Cerrar", command=self.destroy).pack(side="right", padx=5)
 
    # ---------------- Logica ----------------
    def cargar_medicamentos(self):
        filtro = self.entry_buscar.get().strip()
        try:
            filas = db.listar_medicamentos(self.conn, filtro)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo consultar MEDICAMENTO.\n\n{e}")
            return
 
        self.tabla.delete(*self.tabla.get_children())
        for fila in filas:
            self.tabla.insert("", "end", values=list(fila))
 
    def _mostrar_todos(self):
        self.entry_buscar.delete(0, "end")
        self.cargar_medicamentos()
 
    def _al_seleccionar_fila(self, event):
        seleccion = self.tabla.selection()
        if not seleccion:
            return
        valores = self.tabla.item(seleccion[0], "values")
 
        self.id_medicamento_seleccionado = int(valores[0])
        self.vars["nombre"].set(valores[1])
        self.vars["descripcion"].set(valores[2] if valores[2] != "None" else "")
        self.vars["presentacion"].set(valores[3])
        self.vars["concentracion"].set(valores[4])
        self.vars["precio"].set(valores[5])
        self.vars["fabricante"].set(valores[6] if valores[6] != "None" else "")
        self.var_requiere_receta.set(str(valores[7]) in ("True", "1"))
        self.var_estado.set(str(valores[8]) in ("True", "1"))
 
    def _limpiar_formulario(self):
        self.id_medicamento_seleccionado = None
        for var in self.vars.values():
            var.set("")
        self.var_requiere_receta.set(False)
        self.var_estado.set(True)
        self.tabla.selection_remove(self.tabla.selection())
 
    def _leer_formulario(self) -> dict:
        return {
            "nombre": self.vars["nombre"].get().strip(),
            "descripcion": self.vars["descripcion"].get().strip(),
            "presentacion": self.vars["presentacion"].get().strip(),
            "concentracion": self.vars["concentracion"].get().strip(),
            "precio": self.vars["precio"].get().strip(),
            "fabricante": self.vars["fabricante"].get().strip(),
            "requiere_receta": 1 if self.var_requiere_receta.get() else 0,
            "estado": 1 if self.var_estado.get() else 0,
        }
 
    def _validar(self, data: dict) -> bool:
        obligatorios = ["nombre", "presentacion", "concentracion", "precio"]
        faltantes = [c for c in obligatorios if not data[c]]
        if faltantes:
            messagebox.showwarning("Datos incompletos", f"Faltan campos: {', '.join(faltantes)}")
            return False
 
        try:
            float(data["precio"])
        except ValueError:
            messagebox.showwarning("Precio invalido", "El precio debe ser un numero (ej. 3500.00).")
            return False
 
        return True
 
    def _guardar(self):
        data = self._leer_formulario()
        if not self._validar(data):
            return
 
        try:
            if self.id_medicamento_seleccionado is None:
                db.crear_medicamento(self.conn, data)
                messagebox.showinfo("Exito", "Medicamento creado correctamente.")
            else:
                db.actualizar_medicamento(self.conn, self.id_medicamento_seleccionado, data)
                messagebox.showinfo("Exito", "Medicamento actualizado correctamente.")
        except pyodbc.Error as e:
            messagebox.showerror("Error al guardar", str(e))
            return
 
        self._limpiar_formulario()
        self.cargar_medicamentos()
 
    def _eliminar(self):
        if self.id_medicamento_seleccionado is None:
            messagebox.showwarning("Sin seleccion", "Selecciona un medicamento de la tabla primero.")
            return
 
        confirmar = messagebox.askyesno(
            "Confirmar", "¿Seguro que deseas eliminar este medicamento? Esta accion no se puede deshacer."
        )
        if not confirmar:
            return
 
        try:
            db.eliminar_medicamento(self.conn, self.id_medicamento_seleccionado)
            messagebox.showinfo("Exito", "Medicamento eliminado.")
        except pyodbc.Error as e:
            messagebox.showerror(
                "Error al eliminar",
                f"No se pudo eliminar (puede tener registros relacionados, ej. DETALLE_RECETA/INVENTARIO).\n\n{e}",
            )
            return
 
        self._limpiar_formulario()
        self.cargar_medicamentos()

# ==========================================================
# CRUD RECETA
# ==========================================================
# RECETA necesita ID_CONSULTA. Como paciente puede tener varias consultas, la busqueda por cedula llena
# un Combobox con todas sus consultas (fecha + motivo) para que el
# usuario elija la correcta
class VentanaRecetas(tk.Toplevel):
    def __init__(self, parent, conn):
        super().__init__(parent)
        self.conn = conn
        self.id_receta_seleccionada = None
        self.id_consulta_enganchada = None
        self.mapa_consultas = {}
 
        self.title("Gestion de Recetas")
        self.geometry("1000x520")
 
        self._construir_barra_busqueda()
        self._construir_tabla()
        self._construir_formulario()
        self._construir_botones()
 
        self.cargar_recetas()
 
    # ---------------- UI ----------------
    def _construir_barra_busqueda(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(10, 0))
 
        ttk.Label(frame, text="Buscar (cedula / nombre / apellido):").pack(side="left")
        self.entry_buscar = ttk.Entry(frame, width=30)
        self.entry_buscar.pack(side="left", padx=5)
        self.entry_buscar.bind("<Return>", lambda e: self.cargar_recetas())
 
        ttk.Button(frame, text="Buscar", command=self.cargar_recetas).pack(side="left", padx=5)
        ttk.Button(frame, text="Mostrar todos", command=self._mostrar_todos).pack(side="left")
 
    def _construir_tabla(self):
        columnas = ("ID Receta", "ID Consulta", "Cedula", "Nombre", "Ap. Primero", "Fecha", "Estado")
 
        self.tabla = ttk.Treeview(self, columns=columnas, show="headings", height=12)
        for col in columnas:
            self.tabla.heading(col, text=col)
            self.tabla.column(col, width=100, anchor="w")
 
        self.tabla.pack(fill="both", expand=True, padx=10, pady=10)
        self.tabla.bind("<<TreeviewSelect>>", self._al_seleccionar_fila)
 
    def _construir_formulario(self):
        # --- sub-frame: enganchar consulta por cedula ---
        frame_consulta = ttk.LabelFrame(self, text="Consulta asociada")
        frame_consulta.pack(fill="x", padx=10, pady=(0, 5))
 
        ttk.Label(frame_consulta, text="Cedula paciente:").pack(side="left", padx=(5, 0))
        self.entry_cedula_receta = ttk.Entry(frame_consulta, width=15)
        self.entry_cedula_receta.pack(side="left", padx=5)
 
        ttk.Button(
            frame_consulta, text="Buscar consultas", command=self._buscar_consultas
        ).pack(side="left", padx=5)
 
        self.combo_consultas = ttk.Combobox(frame_consulta, width=45, state="readonly")
        self.combo_consultas.pack(side="left", padx=10)
        self.combo_consultas.bind("<<ComboboxSelected>>", self._al_elegir_consulta)
 
        # --- sub-frame: datos propios de RECETA ---
        frame = ttk.LabelFrame(self, text="Datos de la receta")
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        self.var_fecha = tk.StringVar()
        self.var_estado = tk.StringVar(value=ESTADOS_RECETA[0])
 
        ttk.Label(frame, text="Fecha (AAAA-MM-DD HH:MM)").grid(row=0, column=0, sticky="e", padx=5, pady=4)
        ttk.Entry(frame, textvariable=self.var_fecha, width=28).grid(
            row=0, column=1, sticky="w", padx=5, pady=4
        )
 
        ttk.Label(frame, text="Estado").grid(row=0, column=2, sticky="e", padx=5, pady=4)
        ttk.Combobox(
            frame, textvariable=self.var_estado, values=ESTADOS_RECETA, width=25, state="readonly"
        ).grid(row=0, column=3, sticky="w", padx=5, pady=4)
 
    def _construir_botones(self):
        frame = ttk.Frame(self)
        frame.pack(fill="x", padx=10, pady=(0, 10))
 
        ttk.Button(frame, text="Nuevo", command=self._limpiar_formulario).pack(side="left", padx=5)
        ttk.Button(frame, text="Guardar", command=self._guardar).pack(side="left", padx=5)
        ttk.Button(frame, text="Eliminar", command=self._eliminar).pack(side="left", padx=5)
        ttk.Button(frame, text="Cerrar", command=self.destroy).pack(side="right", padx=5)
 
    # ---------------- Logica ----------------
    def cargar_recetas(self):
        filtro = self.entry_buscar.get().strip()
        try:
            filas = db.listar_recetas(self.conn, filtro)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo consultar RECETA.\n\n{e}")
            return
 
        self.tabla.delete(*self.tabla.get_children())
        for fila in filas:
            self.tabla.insert("", "end", values=list(fila))
 
    def _mostrar_todos(self):
        self.entry_buscar.delete(0, "end")
        self.cargar_recetas()
 
    def _buscar_consultas(self):
        cedula = self.entry_cedula_receta.get().strip()
        if not cedula:
            messagebox.showwarning("Falta cedula", "Escribe una cedula para buscar.")
            return
 
        try:
            consultas = db.buscar_consultas_por_cedula(self.conn, cedula)
        except pyodbc.Error as e:
            messagebox.showerror("Error", f"No se pudo buscar las consultas.\n\n{e}")
            return
 
        if not consultas:
            messagebox.showwarning(
                "Sin consultas", "Esa cedula no tiene consultas registradas."
            )
            self.combo_consultas.set("")
            self.combo_consultas["values"] = []
            self.mapa_consultas = {}
            self.id_consulta_enganchada = None
            return
 
        self.mapa_consultas = {}
        opciones = []
        for id_consulta, fecha, motivo in consultas:
            texto = f"ID {id_consulta} - {str(fecha)[:16]} - {motivo}"
            self.mapa_consultas[texto] = id_consulta
            opciones.append(texto)
 
        self.combo_consultas["values"] = opciones
        self.combo_consultas.current(0)
        self.id_consulta_enganchada = self.mapa_consultas[opciones[0]]
 
    def _al_elegir_consulta(self, event):
        texto = self.combo_consultas.get()
        self.id_consulta_enganchada = self.mapa_consultas.get(texto)
 
    def _al_seleccionar_fila(self, event):
        seleccion = self.tabla.selection()
        if not seleccion:
            return
        valores = self.tabla.item(seleccion[0], "values")
 
        self.id_receta_seleccionada = int(valores[0])
        self.id_consulta_enganchada = int(valores[1])
        self.entry_cedula_receta.delete(0, "end")
        self.entry_cedula_receta.insert(0, valores[2])
        self.combo_consultas.set(f"ID {valores[1]} ({valores[3]} {valores[4]})")
        self.combo_consultas["values"] = [self.combo_consultas.get()]
 
        self.var_fecha.set(str(valores[5])[:16])
        self.var_estado.set(valores[6])
 
    def _limpiar_formulario(self):
        self.id_receta_seleccionada = None
        self.id_consulta_enganchada = None
        self.mapa_consultas = {}
        self.entry_cedula_receta.delete(0, "end")
        self.combo_consultas.set("")
        self.combo_consultas["values"] = []
        self.var_fecha.set("")
        self.var_estado.set(ESTADOS_RECETA[0])
        self.tabla.selection_remove(self.tabla.selection())
 
    def _leer_formulario(self) -> dict:
        return {
            "id_consulta": self.id_consulta_enganchada,
            "fecha": self.var_fecha.get().strip(),
            "estado": self.var_estado.get(),
        }
 
    def _validar(self, data: dict) -> bool:
        if self.id_receta_seleccionada is None and data["id_consulta"] is None:
            messagebox.showwarning(
                "Falta consulta", "Busca al paciente y elige una consulta antes de guardar."
            )
            return False
 
        if not data["fecha"]:
            messagebox.showwarning("Datos incompletos", "Falta la fecha.")
            return False
 
        return True
 
    def _guardar(self):
        data = self._leer_formulario()
        if not self._validar(data):
            return
 
        try:
            if self.id_receta_seleccionada is None:
                db.crear_receta(self.conn, data)
                messagebox.showinfo("Exito", "Receta creada correctamente.")
            else:
                db.actualizar_receta(self.conn, self.id_receta_seleccionada, data)
                messagebox.showinfo("Exito", "Receta actualizada correctamente.")
        except pyodbc.Error as e:
            messagebox.showerror("Error al guardar", str(e))
            return
 
        self._limpiar_formulario()
        self.cargar_recetas()
 
    def _eliminar(self):
        if self.id_receta_seleccionada is None:
            messagebox.showwarning("Sin seleccion", "Selecciona una receta de la tabla primero.")
            return
 
        confirmar = messagebox.askyesno(
            "Confirmar", "¿Seguro que deseas eliminar esta receta? Esta accion no se puede deshacer."
        )
        if not confirmar:
            return
 
        try:
            db.eliminar_receta(self.conn, self.id_receta_seleccionada)
            messagebox.showinfo("Exito", "Receta eliminada.")
        except pyodbc.Error as e:
            messagebox.showerror(
                "Error al eliminar",
                f"No se pudo eliminar (puede tener registros relacionados, ej. DETALLE_RECETA).\n\n{e}",
            )
            return
 
        self._limpiar_formulario()
        self.cargar_recetas()


# ==========================================================
# PUNTO DE ENTRADA
# ==========================================================
def main():
    login_win = LoginWindow()
    login_win.mainloop()
 
    if login_win.conn is None:
        return  # el usuario cerro la ventana de login sin autenticarse
 
    menu = MenuPrincipal(login_win.conn, login_win.id_usuario, login_win.nombre_completo)
    menu.mainloop()
 
 
if __name__ == "__main__":
    main()