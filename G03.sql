-- Script para crear las tablas del proyecto G03 basado en el modelo lógico corregido
DROP DATABASE IF EXISTS G03;
CREATE DATABASE G03;
USE G03;

-- Tabla Cliente
CREATE TABLE Cliente (
    IdCliente INT PRIMARY KEY AUTO_INCREMENT,
    Nombres VARCHAR(20) NOT NULL,
    Apellidos VARCHAR(20) NOT NULL,
    RUC_CI VARCHAR(13) UNIQUE NOT NULL,
    FechaNacimiento DATE,
    Genero ENUM('MASCULINO', 'FEMENINO') NOT NULL,
    EstadoCivil ENUM('SOLTERO', 'CASADO', 'DIVORCIADO', 'VIUDO') NOT NULL,
    Direccion VARCHAR(150),
    CorreoElectronico VARCHAR(100)
);

-- Tabla TelefonoCliente
CREATE TABLE TelefonoCliente (
    IdCliente INT,
    NumeroTelefono VARCHAR(13),
    PRIMARY KEY (IdCliente, NumeroTelefono),
    FOREIGN KEY (IdCliente) REFERENCES Cliente(IdCliente)
);

-- Tabla Encargado
CREATE TABLE Encargado (
    CodigoEncargado INT PRIMARY KEY AUTO_INCREMENT,
    Nombres VARCHAR(20),
    Apellidos VARCHAR(20),
    CorreoElectronico VARCHAR(100),
    Departamento ENUM('SISTEMAS', 'CONTABILIDAD'),
    Cargo VARCHAR(20)
);

-- Tabla Solicitud
CREATE TABLE Solicitud (
    CodigoSolicitud INT PRIMARY KEY AUTO_INCREMENT,
    FechaSolicitud DATE NOT NULL,
    FechaSuscripcion DATE,
    Descuento DECIMAL(5,2),
    Plazo INT,
    EstadoSolicitud ENUM('APROBADA', 'RECHAZADA', 'CANCELADA', 'EN REVISION'),
    CuotaInicial DECIMAL(10,2),
    IdCliente INT,
    FOREIGN KEY (IdCliente) REFERENCES Cliente(IdCliente)
);

-- Tabla ServicioGeneral
CREATE TABLE ServicioGeneral (
    CodigoServicio INT PRIMARY KEY AUTO_INCREMENT,
    Descripcion TEXT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    EstadoServicio ENUM('ACTIVO', 'INACTIVO'),
    TipoServicio ENUM('PRODUCTO', 'FUNERARIO')
);

-- Tabla ServicioFunerario
CREATE TABLE ServicioFunerario (
    CodigoServicio INT PRIMARY KEY,
    TipoServicio ENUM('CREMACION','TRASLADO','INHUMACION') NOT NULL,
    UbicacionPrestacion VARCHAR(150) NOT NULL,
    FOREIGN KEY (CodigoServicio) REFERENCES ServicioGeneral(CodigoServicio)
);

-- Tabla ProductoServicio
CREATE TABLE ProductoServicio (
    CodigoServicio INT PRIMARY KEY,
    LugarEntregaProducto VARCHAR(150) NOT NULL,
    Material VARCHAR(20) NOT NULL,
    TipoProducto ENUM('COFRE','ARREGLOS_FLORALES','CENIZARIO','LOTE','UNIDAD_FAMILIAR','BOVEDA','OSARIO') NOT NULL,
    FOREIGN KEY (CodigoServicio) REFERENCES ServicioGeneral(CodigoServicio)
);

-- Tabla AsignacionServicio
CREATE TABLE AsignacionServicio (
    IdAsignacion INT PRIMARY KEY AUTO_INCREMENT,
    CodigoSolicitud INT,
    CodigoServicio INT,
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    Subtotal DECIMAL(10,2),
    PrecioUnitario DECIMAL(10,2),
    FOREIGN KEY (CodigoSolicitud) REFERENCES Solicitud(CodigoSolicitud),
    FOREIGN KEY (CodigoServicio) REFERENCES ServicioGeneral(CodigoServicio)
);

-- Tabla ValidacionInterna
CREATE TABLE ValidacionInterna (
    IdValidacion INT PRIMARY KEY AUTO_INCREMENT,
    EstadoValidacionSistemas ENUM('APROBADO', 'RECHAZADO'),
    EstadoValidacionContabilidad ENUM('APROBADO', 'RECHAZADO'),
    FechaRevision DATE,
    NumeroIntento INT,
    Observaciones TEXT,
    CodigoEncargado INT,
    CodigoEncargadoSistemas INT,
    CodigoEncargadoContabilidad INT,
    FOREIGN KEY (CodigoEncargado) REFERENCES Encargado(CodigoEncargado),
    FOREIGN KEY (CodigoEncargadoSistemas) REFERENCES Encargado(CodigoEncargado),
    FOREIGN KEY (CodigoEncargadoContabilidad) REFERENCES Encargado(CodigoEncargado)
);

-- Tabla Factura
CREATE TABLE Factura (
    CodigoFactura INT PRIMARY KEY AUTO_INCREMENT,
    ClaveAcceso VARCHAR(50) UNIQUE,
    TipoEmision ENUM('NORMAL', 'CONTINGENCIA'),
    FechaAutorizacion DATE,
    FechaEmision DATE,
    Ambiente ENUM('PRUEBA', 'PRODUCCION'),
    EstadoAutorizacionSRI ENUM('APROBADO', 'RECHAZADO'),
    CodigoSolicitud INT,
    IdValidacion INT,
    FOREIGN KEY (CodigoSolicitud) REFERENCES Solicitud(CodigoSolicitud),
    FOREIGN KEY (IdValidacion) REFERENCES ValidacionInterna(IdValidacion)
);

-- Tabla Pago
CREATE TABLE Pago (
    CodigoFactura INT,
    IdPago INT PRIMARY KEY AUTO_INCREMENT,
    FechaPago DATE NOT NULL,
    MetodoPago ENUM('CONTADO', 'CREDITO'),
    MontoPagado DECIMAL(10,2),
    EstadoPago ENUM('PENDIENTE', 'PAGADO', 'PARCIALMENTE_PAGADO', 'VENCIDA', 'CANCELADA', 'EN_DISPUTA'),
    ValorCuota DECIMAL(10,2),
    FOREIGN KEY (CodigoFactura) REFERENCES Factura(CodigoFactura)
);

-- Tabla Insumos
CREATE TABLE Insumos (
    IdInsumo INT,
    CodigoServicio INT,
    Nombre VARCHAR(50) NOT NULL,
    PRIMARY KEY (IdInsumo, CodigoServicio),
    FOREIGN KEY (CodigoServicio) REFERENCES ServicioGeneral(CodigoServicio)
);

-- Insercion de datos 
INSERT INTO Cliente VALUES
(1, 'Daniela', 'Cedeño', '1104689201', '1990-05-01', 'FEMENINO', 'SOLTERO', 'Av. del Ejército y Av. Quito', 'daniela.cedeno@gmail.com'),
(2, 'Luis', 'Moreira', '1102938472', '1985-08-15', 'MASCULINO', 'CASADO', 'Cdla. Alborada 3ra etapa', 'luis.moreira@yahoo.com'),
(3, 'Carla', 'Maldonado', '1108573946', '1992-03-12', 'FEMENINO', 'DIVORCIADO', 'Sauces 6 mz. 25 solar 4', 'carlam92@hotmail.com'),
(4, 'José', 'Quijije', '1102748391', '1988-12-24', 'MASCULINO', 'VIUDO', 'Cdla. Miraflores, Guayaquil', 'jquijije@gmail.com'),
(5, 'Lucía', 'Macías', '1101938475', '1993-06-17', 'FEMENINO', 'SOLTERO', 'Vía a Daule km 12.5', 'lucia.macias@mail.com'),
(6, 'Pedro', 'Arias', '1105483729', '1980-11-11', 'MASCULINO', 'CASADO', 'Ciudadela Kennedy Norte', 'pedroarias@outlook.com'),
(7, 'María', 'Muñoz', '1103849205', '1991-07-30', 'FEMENINO', 'VIUDO', 'Cdla. Vernaza Norte', 'maria.munoz@gmail.com'),
(8, 'David', 'Benítez', '1102948375', '1983-09-09', 'MASCULINO', 'DIVORCIADO', 'Urdesa central, calle segunda', 'davidb@gmail.com'),
(9, 'Paula', 'Santana', '1101847362', '1994-04-04', 'FEMENINO', 'CASADO', 'Cdla. Samanes 5', 'psantana@yahoo.com'),
(10, 'Andrés', 'Navarrete', '1109483721', '1987-10-05', 'MASCULINO', 'SOLTERO', 'Av. Barcelona y calle 33', 'andres.navarrete@mail.com');

-- INSERT TelefonoCliente
INSERT INTO TelefonoCliente VALUES
(1, '0998123456'), (2, '0987234567'), (3, '0967345678'), (4, '0956456789'), (5, '0945567890'),
(6, '0934678901'), (7, '0923789012'), (8, '0912890123'), (9, '0991987654'), (10, '0987098765');

-- INSERT Solicitud
INSERT INTO Solicitud VALUES
(101, '2025-08-01', '2025-08-02', 0.00, 12, 'EN REVISION', 100.00, 1),
(102, '2025-08-01', '2025-08-02', 5.00, 10, 'APROBADA', 150.00, 2),
(103, '2025-08-01', '2025-08-03', 2.50, 6, 'CANCELADA', 120.00, 3),
(104, '2025-08-02', '2025-08-03', 0.00, 9, 'RECHAZADA', 200.00, 4),
(105, '2025-08-02', '2025-08-04', 10.00, 24, 'EN REVISION', 180.00, 5),
(106, '2025-08-03', '2025-08-05', 3.50, 18, 'APROBADA', 220.00, 6),
(107, '2025-08-03', '2025-08-06', 1.00, 6, 'CANCELADA', 90.00, 7),
(108, '2025-08-04', '2025-08-06', 0.00, 12, 'EN REVISION', 130.00, 8),
(109, '2025-08-04', '2025-08-07', 7.50, 15, 'APROBADA', 160.00, 9),
(110, '2025-08-05', '2025-08-08', 0.00, 10, 'RECHAZADA', 140.00, 10);

-- Eliminar vista si ya existe
-- DROP VIEW IF EXISTS VistaSolicitudesEnRevision;

-- VISTA: Vista para ver solicitudes con estado 'EN REVISION'
-- CREATE VIEW VistaSolicitudesEnRevision AS
-- SELECT CodigoSolicitud, FechaSolicitud, EstadoSolicitud, IdCliente
-- FROM Solicitud
-- WHERE EstadoSolicitud = 'EN REVISION';

-- Eliminar procedimiento si ya existe
-- DROP PROCEDURE IF EXISTS RegistrarPago;

-- PROCEDIMIENTO almacenado con transacción para registrar pago
-- DELIMITER //
-- CREATE PROCEDURE RegistrarPago(
    -- IN p_CodigoFactura INT,
    -- IN p_FechaPago DATE,
    -- IN p_MetodoPago ENUM('CONTADO','CREDITO'),
    -- IN p_Monto DECIMAL(10,2),
    -- IN p_EstadoPago ENUM('PENDIENTE','PAGADO','PARCIALMENTE_PAGADO','VENCIDA','CANCELADA','EN_DISPUTA'),
    -- IN p_ValorCuota DECIMAL(10,2)
-- )
-- BEGIN
    -- START TRANSACTION;
    -- INSERT INTO Pago (CodigoFactura, FechaPago, MetodoPago, MontoPagado, EstadoPago, ValorCuota)
    -- VALUES (p_CodigoFactura, p_FechaPago, p_MetodoPago, p_Monto, p_EstadoPago, p_ValorCuota);
    
    -- UPDATE Factura 
    -- SET EstadoAutorizacionSRI = 'APROBADO' 
    -- WHERE CodigoFactura = p_CodigoFactura;
    
    -- COMMIT;
-- END //
-- DELIMITER ;

-- Eliminar trigger si ya existe
-- DROP TRIGGER IF EXISTS trg_validar_descuento;

-- TRIGGER: Verificar descuento no mayor al 20%
-- DELIMITER //
-- CREATE TRIGGER trg_validar_descuento
-- BEFORE INSERT ON Solicitud
-- FOR EACH ROW
-- BEGIN
    -- IF NEW.Descuento > 20 THEN
        -- SIGNAL SQLSTATE '45000'
        -- SET MESSAGE_TEXT = 'El descuento no puede ser mayor al 20%';
    -- END IF;
-- END //
-- DELIMITER ;




