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
    ("Expedientes", False),
    ("Empleados", False),
    ("Usuarios", False),
    ("Medicos", False),
    ("Consultas", False),
    ("Recetas", False),
    ("Detalle de receta", False),
    ("Medicamentos", False),
    ("Inventario", False),
    ("Auditoria", False),
]

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