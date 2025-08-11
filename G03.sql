-- SCRIPT DE IMPLEMENTACIÓN DE BASE DE DATOS G03

DROP DATABASE IF EXISTS G03;
CREATE DATABASE G03;
USE G03;

SET NAMES utf8mb4;
SET sql_mode = 'STRICT_ALL_TABLES';

-- Creacion de Tablas 

-- Tabla Cliente
CREATE TABLE Cliente (
    IdCliente INT PRIMARY KEY AUTO_INCREMENT,
    Nombres VARCHAR(20) NOT NULL,
    Apellidos VARCHAR(20) NOT NULL,
    RUC_CI VARCHAR(13) UNIQUE NOT NULL CHECK (CHAR_LENGTH(RUC_CI) = 10 OR CHAR_LENGTH(RUC_CI) = 13),
    FechaNacimiento DATE,
    Genero ENUM('MASCULINO', 'FEMENINO') NOT NULL,
    EstadoCivil ENUM('SOLTERO', 'CASADO', 'DIVORCIADO', 'VIUDO'),
    Direccion VARCHAR(150),
    CorreoElectronico VARCHAR(100) NOT NULL
);

-- Tabla TelefonoCliente
CREATE TABLE TelefonoCliente (
    IdCliente INT,
    NumeroTelefono VARCHAR(13) CHECK (CHAR_LENGTH(NumeroTelefono) = 10),
    PRIMARY KEY (IdCliente, NumeroTelefono),
    CONSTRAINT fk_IdCliente FOREIGN KEY (IdCliente) REFERENCES Cliente(IdCliente)
);

-- Tabla Encargado
CREATE TABLE Encargado (
    CodigoEncargado INT PRIMARY KEY AUTO_INCREMENT,
    Nombres VARCHAR(20) NOT NULL,
    Apellidos VARCHAR(20) NOT NULL,
    CorreoElectronico VARCHAR(100) UNIQUE NOT NULL,
    Departamento ENUM('SISTEMAS', 'CONTABILIDAD') NOT NULL,
    Cargo VARCHAR(20) NOT NULL
);

-- Tabla Solicitud
CREATE TABLE Solicitud (
    CodigoSolicitud INT PRIMARY KEY AUTO_INCREMENT,
    FechaSolicitud DATE NOT NULL,
    FechaSuscripcion DATE,
    Descuento DECIMAL(5,2),
    Plazo INT,
    EstadoSolicitud ENUM('APROBADA', 'RECHAZADA', 'CANCELADA', 'EN REVISION') DEFAULT 'EN REVISION',
    CuotaInicial DECIMAL(10,2) CHECK (CuotaInicial >= 0),
    IdCliente INT NOT NULL,
    CONSTRAINT fk_IdClienteSolicitud FOREIGN KEY (IdCliente) REFERENCES Cliente(IdCliente)
    -- estado de solicitud debe ser aprobado para que la cuota inicial sea not null
);

-- Tabla ServicioGeneral
CREATE TABLE ServicioGeneral (
    CodigoServicio INT PRIMARY KEY AUTO_INCREMENT,
    Descripcion TEXT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL CHECK (PrecioUnitario> 0),
    EstadoServicio ENUM('ACTIVO', 'INACTIVO') NOT NULL,
    TipoServicio ENUM('PRODUCTO', 'FUNERARIO') NOT NULL
);

-- Tabla ServicioFunerario
CREATE TABLE ServicioFunerario (
    CodigoServicio INT PRIMARY KEY,
    TipoServicio ENUM('CREMACION','TRASLADO','INHUMACION') NOT NULL,
    UbicacionPrestacion VARCHAR(150) NOT NULL,
    CONSTRAINT fk_CodigoServicio_Funerario FOREIGN KEY (CodigoServicio) REFERENCES ServicioGeneral(CodigoServicio),
);

-- Tabla ProductoServicio
CREATE TABLE ProductoServicio (
    CodigoServicio INT PRIMARY KEY,
    LugarEntregaProducto VARCHAR(150) NOT NULL,
    Material VARCHAR(20) NOT NULL,
    TipoProducto ENUM('COFRE','ARREGLOS_FLORALES','CENIZARIO','LOTE','UNIDAD_FAMILIAR','BOVEDA','OSARIO') NOT NULL,
    CONSTRAINT fk_CodigoServicio_Producto FOREIGN KEY (CodigoServicio) REFERENCES ServicioGeneral(CodigoServicio)
);

-- Tabla AsignacionServicio
CREATE TABLE AsignacionServicio (
    IdAsignacion INT PRIMARY KEY AUTO_INCREMENT,
    CodigoSolicitud INT NOT NULL,
    CodigoServicio INT NOT NULL,
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    Subtotal DECIMAL(10,2) NOT NULL CHECK (Subtotal> 0), -- derivado de cantidad*preciounitario
    PrecioUnitario DECIMAL(10,2) NOT NULL CHECK (PrecioUnitario> 0),
    CONSTRAINT fk_CodigoSolicitudAsociada FOREIGN KEY (CodigoSolicitud) REFERENCES Solicitud(CodigoSolicitud),
    CONSTRAINT fk_CodigoServicioAsignado FOREIGN KEY (CodigoServicio) REFERENCES ServicioGeneral(CodigoServicio)
);

-- Tabla ValidacionInterna
CREATE TABLE ValidacionInterna (
    IdValidacion INT PRIMARY KEY AUTO_INCREMENT,
    EstadoValidacionSistemas ENUM('APROBADO', 'RECHAZADO'),
    EstadoValidacionContabilidad ENUM('APROBADO', 'RECHAZADO'),
    FechaRevision DATE NOT NULL,
    NumeroIntento INT,
    Observaciones TEXT,
    CodigoEncargadoSistemas INT,
    CodigoEncargadoContabilidad INT,
    CONSTRAINT fk_CodigoEncargadoSistemas FOREIGN KEY (CodigoEncargadoSistemas) REFERENCES Encargado(CodigoEncargado),
    CONSTRAINT fk_CodigoEncargadoContabilidad FOREIGN KEY (CodigoEncargadoContabilidad) REFERENCES Encargado(CodigoEncargado)

    -- verificar con trigger que estos codigos correspondan a los tipos en Encargado
    -- los datos para una misma validacion pueden ser actualizados
);

-- Tabla Factura
CREATE TABLE Factura (
    CodigoFactura INT PRIMARY KEY AUTO_INCREMENT,
    ClaveAcceso VARCHAR(50) UNIQUE NOT NULL,
    TipoEmision ENUM('NORMAL', 'CONTINGENCIA') DEFAULT 'NORMAL',
    FechaAutorizacion DATE,
    FechaEmision DATE, -- se establece luego de ser aprobada por sri
    Ambiente ENUM('PRUEBA', 'PRODUCCION') DEFAULT "PRUEBA",
    EstadoAutorizacionSRI ENUM('APROBADO', 'RECHAZADO'),
    CodigoSolicitud INT NOT NULL,
    IdValidacion INT NOT NULL,
    CONSTRAINT fk_CodigoSolicitud FOREIGN KEY (CodigoSolicitud) REFERENCES Solicitud(CodigoSolicitud),
    CONSTRAINT fk_IdValidacion FOREIGN KEY (IdValidacion) REFERENCES ValidacionInterna(IdValidacion)
    -- emision de facturas en ambiente de produccion se realiza luego de ser aprobada en ambiente de prueba
);

-- Tabla Pago
CREATE TABLE Pago (
    CodigoFactura INT NOT NULL,
    IdPago INT PRIMARY KEY AUTO_INCREMENT,
    FechaPago DATE NOT NULL,
    MetodoPago ENUM('CONTADO', 'CREDITO'),
    MontoPagado DECIMAL(10,2) CHECK (MontoPagado> 0),
    EstadoPago ENUM('PENDIENTE', 'PAGADO', 'PARCIALMENTE_PAGADO', 'VENCIDA', 'CANCELADA', 'EN_DISPUTA') DEFAULT "PENDIENTE",
    ValorCuota DECIMAL(10,2) CHECK (ValorCuota> 0),
    CONSTRAINT fk_CodigoFactura FOREIGN KEY (CodigoFactura) REFERENCES Factura(CodigoFactura)
    -- la fecha de pago se refiere al plazo y cambia cuando el cliente paga igual que el monto pagado
    -- el cliente puede hacer un solo pago o pagar por cuotas
);

-- Tabla Insumos
CREATE TABLE Insumos (
    IdInsumo INT,
    CodigoServicio INT,
    Nombre VARCHAR(50) NOT NULL CHECK (Nombre <> ''),
    PRIMARY KEY (IdInsumo, CodigoServicio),
    CONSTRAINT fk_CodigoServicioFunerario FOREIGN KEY (CodigoServicio) REFERENCES ServicioFunerario(CodigoServicio)
);

-- Creacion de indices para mejorar el rendimiento
CREATE INDEX idx_telcliente_cliente ON TelefonoCliente (IdCliente);
CREATE INDEX idx_solicitud_cliente ON Solicitud (IdCliente);
CREATE INDEX idx_asignacion_sol ON AsignacionServicio (CodigoSolicitud);
CREATE INDEX idx_asignacion_srv ON AsignacionServicio (CodigoServicio);
CREATE INDEX idx_factura_sol ON Factura (CodigoSolicitud);
CREATE INDEX idx_factura_val ON Factura (IdValidacion);
CREATE INDEX idx_pago_factura ON Pago (CodigoFactura);

-- Insercion de datos

-- Inserción de Clientes
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

-- INSERT TeléfonoCliente
INSERT INTO TelefonoCliente VALUES
(1, '0998123456'), (2, '0987234567'), (3, '0967345678'), (4, '0956456789'), (5, '0945567890'),
(6, '0934678901'), (7, '0923789012'), (8, '0912890123'), (9, '0991987654'), (10, '0987098765');

-- INSERT Encargados
INSERT INTO Encargado (CodigoEncargado, Nombres, Apellidos, CorreoElectronico, Departamento, Cargo) VALUES
(1, 'Andrea', 'Villacreses', 'andrea.villacreses@empresa.com', 'SISTEMAS', 'Analista'),
(2, 'Marco', 'Saltos',       'marco.saltos@empresa.com',       'SISTEMAS', 'Líder'),
(3, 'Carolina', 'Pico',      'carolina.pico@empresa.com',      'CONTABILIDAD', 'Contadora'),
(4, 'Pablo', 'Terán',        'pablo.teran@empresa.com',        'CONTABILIDAD', 'Auditor'),
(5, 'Sofía', 'Reyes',        'sofia.reyes@empresa.com',        'SISTEMAS', 'Soporte');

-- INSERT Solicitud (agosto 2025)
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

-- INSERT ServicioGeneral
INSERT INTO ServicioGeneral (CodigoServicio, Descripcion, PrecioUnitario, EstadoServicio, TipoServicio) VALUES
(201, 'Cofre de pino', 300.00, 'ACTIVO', 'PRODUCTO'),
(202, 'Arreglo floral estándar', 50.00, 'ACTIVO', 'PRODUCTO'),
(203, 'Cenizario cerámico', 120.00, 'ACTIVO', 'PRODUCTO'),
(204, 'Lote cementerio simple', 800.00, 'ACTIVO', 'PRODUCTO'),
(205, 'Osario con nicho', 400.00, 'ACTIVO', 'PRODUCTO'),
(206, 'Servicio de cremación básica', 700.00, 'ACTIVO', 'FUNERARIO'),
(207, 'Traslado urbano', 150.00, 'ACTIVO', 'FUNERARIO'),
(208, 'Inhumación estándar', 500.00, 'ACTIVO', 'FUNERARIO'),
(209, 'Velatorio sala A', 200.00, 'ACTIVO', 'FUNERARIO'),
(210, 'Traslado interprovincial', 350.00, 'ACTIVO', 'FUNERARIO');

-- INSERT ProductoServicio
INSERT INTO ProductoServicio (CodigoServicio, LugarEntregaProducto, Material, TipoProducto) VALUES
(201, 'Sala de exposición', 'Madera', 'COFRE'),
(202, 'Capilla ardiente',   'Mixto',  'ARREGLOS_FLORALES'),
(203, 'Oficina comercial',  'Cerámica','CENIZARIO'),
(204, 'Cementerio Norte',   'Concreto','LOTE'),
(205, 'Cementerio Central', 'Concreto','OSARIO');

-- INSERT ServicioFunerario
INSERT INTO ServicioFunerario (CodigoServicio, TipoServicio, UbicacionPrestacion) VALUES
(206, 'CREMACION',   'Crematorio Central'),
(207, 'TRASLADO',    'Área urbana Guayaquil'),
(208, 'INHUMACION',  'Cementerio General'),
(209, 'INHUMACION',  'Sala de velación A'),
(210, 'TRASLADO',    'Guayas–Manabí');

-- INSERT ValidacionInterna
INSERT INTO ValidacionInterna
(IdValidacion, EstadoValidacionSistemas, EstadoValidacionContabilidad, FechaRevision, NumeroIntento,
 Observaciones, CodigoEncargado, CodigoEncargadoSistemas, CodigoEncargadoContabilidad)
VALUES
(301, 'APROBADO',  'APROBADO',  '2025-08-05', 1, 'OK',                 1, 2, 3),
(302, 'APROBADO',  'APROBADO',  '2025-08-06', 1, 'OK',                 1, 2, 3),
(303, 'RECHAZADO', 'APROBADO',  '2025-08-06', 2, 'Error XML',          1, 5, 3),
(304, 'APROBADO',  'RECHAZADO', '2025-08-07', 1, 'Glosa contable',     1, 2, 4),
(305, 'RECHAZADO', 'RECHAZADO', '2025-08-07', 2, 'Fallas múltiples',   1, 5, 4),
(306, 'APROBADO',  'APROBADO',  '2025-08-08', 1, 'OK',                 1, 2, 3),
(307, NULL,        'APROBADO',  '2025-08-08', 1, 'Pend. por sistemas', 1, 2, 3),
(308, 'APROBADO',  NULL,        '2025-08-09', 1, 'Pend. contab.',      1, 2, 4),
(309, 'RECHAZADO', 'APROBADO',  '2025-08-09', 3, 'Timeout SRI',        1, 5, 3),
(310, 'APROBADO',  'APROBADO',  '2025-08-10', 1, 'OK',                 1, 2, 3);

-- INSERT Factura
INSERT INTO Factura
(CodigoFactura, ClaveAcceso, TipoEmision, FechaAutorizacion, FechaEmision, Ambiente, EstadoAutorizacionSRI, CodigoSolicitud, IdValidacion) VALUES
(1001, 'AC-101-1', 'NORMAL',       '2025-08-05', '2025-08-05', 'PRODUCCION', 'APROBADO', 101, 301),
(1002, 'AC-102-1', 'NORMAL',       '2025-08-06', '2025-08-06', 'PRODUCCION', 'APROBADO', 102, 302),
(1003, 'AC-103-1', 'NORMAL',            NULL,    '2025-08-06', 'PRODUCCION', NULL,        103, 303),
(1004, 'AC-104-1', 'NORMAL',            NULL,    '2025-08-07', 'PRODUCCION', 'RECHAZADO',104, 304),
(1005, 'AC-105-1', 'CONTINGENCIA',      NULL,    '2025-08-07', 'PRUEBA',     'RECHAZADO',105, 305),
(1006, 'AC-106-1', 'NORMAL',       '2025-08-08', '2025-08-08', 'PRODUCCION', 'APROBADO', 106, 306),
(1007, 'AC-107-1', 'NORMAL',            NULL,    '2025-08-08', 'PRODUCCION', NULL,        107, 307),
(1008, 'AC-108-1', 'NORMAL',            NULL,    '2025-08-09', 'PRODUCCION', 'RECHAZADO',108, 308),
(1009, 'AC-109-1', 'NORMAL',       '2025-08-09', '2025-08-09', 'PRODUCCION', 'APROBADO', 109, 309),
(1010, 'AC-110-1', 'NORMAL',       '2025-08-10', '2025-08-10', 'PRODUCCION', 'APROBADO', 110, 310);

-- INSERT AsignacionServicio
INSERT INTO AsignacionServicio (IdAsignacion, CodigoSolicitud, CodigoServicio, Cantidad, Subtotal, PrecioUnitario) VALUES
(1, 101, 201, 1, 300.00, 300.00),
(2, 101, 207, 1, 150.00, 150.00),
(3, 102, 206, 1, 700.00, 700.00),
(4, 102, 202, 2, 100.00, 50.00),
(5, 103, 203, 1, 120.00, 120.00),
(6, 103, 209, 1, 200.00, 200.00),
(7, 104, 204, 1, 800.00, 800.00),
(8, 105, 205, 1, 400.00, 400.00),
(9, 105, 210, 1, 350.00, 350.00),
(10, 106, 206, 1, 700.00, 700.00),
(11, 106, 202, 3, 150.00, 50.00),
(12, 107, 207, 2, 300.00, 150.00),
(13, 108, 208, 1, 500.00, 500.00),
(14, 109, 201, 1, 300.00, 300.00),
(15, 109, 209, 1, 200.00, 200.00),
(16, 110, 203, 2, 240.00, 120.00),
(17, 110, 207, 1, 150.00, 150.00);

-- INSERT Pagos
INSERT INTO Pago (CodigoFactura, IdPago, FechaPago, MetodoPago, MontoPagado, EstadoPago, ValorCuota) VALUES
(1001, 1, '2025-08-06', 'CONTADO', 450.00, 'PAGADO', NULL),
(1002, 2, '2025-08-07', 'CREDITO', 200.00, 'PARCIALMENTE_PAGADO', 200.00),
(1006, 3, '2025-08-09', 'CONTADO', 850.00, 'PAGADO', NULL),
(1009, 4, '2025-08-10', 'CREDITO', 300.00, 'PARCIALMENTE_PAGADO', 300.00),
(1010, 5, '2025-08-10', 'CONTADO', 390.00, 'PAGADO', NULL);

-- INSERT Insumos
INSERT INTO Insumos (IdInsumo, CodigoServicio, Nombre) VALUES
(1, 201, 'Tela interior'),
(2, 201, 'Bisagras metálicas'),
(1, 206, 'Urna ecológica'),
(2, 206, 'Gas crema'),
(1, 207, 'Combustible'),
(1, 208, 'Herramienta manual'),
(1, 202, 'Flores variadas'),
(2, 202, 'Espuma floral');

-- Consultas relevantes

-- 1) ¿Cuántos comprobantes fueron emitidos y autorizados este mes?
SELECT
  SUM(FechaEmision IS NOT NULL
      AND YEAR(FechaEmision)=YEAR(CURDATE())
      AND MONTH(FechaEmision)=MONTH(CURDATE()))        AS emitidos_mes,
  SUM(EstadoAutorizacionSRI='APROBADO'
      AND FechaAutorizacion IS NOT NULL
      AND YEAR(FechaAutorizacion)=YEAR(CURDATE())
      AND MONTH(FechaAutorizacion)=MONTH(CURDATE()))   AS autorizados_mes
FROM Factura;

-- 2) ¿Qué comprobantes están pendientes de autorización por el SRI (este mes)?
SELECT
  CodigoFactura,
  ClaveAcceso,
  FechaEmision,
  EstadoAutorizacionSRI,
  FechaAutorizacion
FROM Factura
WHERE FechaEmision IS NOT NULL
  AND YEAR(FechaEmision)=YEAR(CURDATE())
  AND MONTH(FechaEmision)=MONTH(CURDATE())
  AND (EstadoAutorizacionSRI IS NULL OR FechaAutorizacion IS NULL)
ORDER BY FechaEmision DESC, CodigoFactura DESC;

-- 3) ¿Cuál es el monto total facturado por cliente en el mes?
SELECT
  c.IdCliente,
  CONCAT(c.Nombres,' ',c.Apellidos) AS Cliente,
  SUM(COALESCE(a.Subtotal, a.Cantidad * a.PrecioUnitario)) AS TotalFacturadoMes
FROM Cliente c
JOIN Solicitud s          ON s.IdCliente = c.IdCliente
JOIN Factura f            ON f.CodigoSolicitud = s.CodigoSolicitud
JOIN AsignacionServicio a ON a.CodigoSolicitud = s.CodigoSolicitud
WHERE YEAR(f.FechaEmision)=YEAR(CURDATE())
  AND MONTH(f.FechaEmision)=MONTH(CURDATE())
GROUP BY c.IdCliente, Cliente
ORDER BY TotalFacturadoMes DESC;

-- 4) ¿Qué servicios se facturaron y quién fue el responsable de gestionarlos (este mes)?
SELECT
  f.CodigoFactura,
  f.FechaEmision,
  sg.CodigoServicio,
  sg.Descripcion AS Servicio,
  sg.TipoServicio,
  a.Cantidad,
  COALESCE(a.Subtotal, a.Cantidad * a.PrecioUnitario) AS ImporteItem,
  CONCAT(eGen.Nombres,' ',eGen.Apellidos) AS ResponsableGeneral,
  CONCAT(eSis.Nombres,' ',eSis.Apellidos) AS ResponsableSistemas,
  CONCAT(eCon.Nombres,' ',eCon.Apellidos) AS ResponsableContabilidad
FROM Factura f
JOIN Solicitud s            ON s.CodigoSolicitud = f.CodigoSolicitud
JOIN AsignacionServicio a   ON a.CodigoSolicitud = s.CodigoSolicitud
JOIN ServicioGeneral sg     ON sg.CodigoServicio = a.CodigoServicio
LEFT JOIN ValidacionInterna v ON v.IdValidacion = f.IdValidacion
LEFT JOIN Encargado eGen       ON eGen.CodigoEncargado = v.CodigoEncargado
LEFT JOIN Encargado eSis       ON eSis.CodigoEncargado = v.CodigoEncargadoSistemas
LEFT JOIN Encargado eCon       ON eCon.CodigoEncargado = v.CodigoEncargadoContabilidad
WHERE YEAR(f.FechaEmision)=YEAR(CURDATE())
  AND MONTH(f.FechaEmision)=MONTH(CURDATE())
ORDER BY f.FechaEmision, f.CodigoFactura, sg.CodigoServicio;

-- 5) ¿Qué comprobantes necesitan ser reenviados al departamento de sistemas (este mes)?
SELECT
  f.CodigoFactura,
  f.ClaveAcceso,
  f.FechaEmision,
  f.EstadoAutorizacionSRI,
  v.EstadoValidacionSistemas,
  v.NumeroIntento,
  CONCAT(eSis.Nombres,' ',eSis.Apellidos) AS EncargadoSistemas,
  eSis.CorreoElectronico AS CorreoSistemas
FROM Factura f
LEFT JOIN ValidacionInterna v ON v.IdValidacion = f.IdValidacion
LEFT JOIN Encargado eSis       ON eSis.CodigoEncargado = v.CodigoEncargadoSistemas
WHERE YEAR(f.FechaEmision)=YEAR(CURDATE())
  AND MONTH(f.FechaEmision)=MONTH(CURDATE())
  AND (
        f.EstadoAutorizacionSRI = 'RECHAZADO'
     OR v.EstadoValidacionSistemas = 'RECHAZADO'
     OR v.EstadoValidacionSistemas IS NULL
  )
ORDER BY f.FechaEmision DESC, f.CodigoFactura DESC;
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




