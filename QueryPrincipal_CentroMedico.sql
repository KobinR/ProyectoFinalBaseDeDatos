



----------------------Este es el query para la base de datos--------------------------

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