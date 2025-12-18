CREATE DATABASE Banco_CapibarasMX;
GO

USE Banco_CapibarasMX;                    
GO

CREATE SCHEMA catalogo;
GO
CREATE SCHEMA operacion;
GO
CREATE SCHEMA seguridad;
GO

CREATE TABLE catalogo.Cliente (
    IdCliente        INT IDENTITY PRIMARY KEY,
    Nombre           NVARCHAR(60)  NOT NULL,
    ApellidoPaterno  NVARCHAR(60)  NOT NULL,
    ApellidoMaterno  NVARCHAR(60)  NULL,
    RFC              CHAR(13)      NOT NULL,
    CURP_Enc         VARBINARY(256) NULL,  
    Telefono_Enc     VARBINARY(256) NULL, 
    Email            NVARCHAR(120)  NULL,
    FechaRegistro    DATETIME2       NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE operacion.Cuenta (
    IdCuenta     INT IDENTITY PRIMARY KEY,
    IdCliente    INT NOT NULL,
    Numero       CHAR(10) NOT NULL UNIQUE,
    CLABE        CHAR(18) NOT NULL UNIQUE,
    Tipo         VARCHAR(20) NOT NULL,     
    Saldo        DECIMAL(18,2) NOT NULL DEFAULT 0,
    Activa       BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Cuenta_Cliente
      FOREIGN KEY (IdCliente) REFERENCES catalogo.Cliente(IdCliente)
);
GO

CREATE TABLE operacion.Tarjeta (
    IdTarjeta     INT IDENTITY PRIMARY KEY,
    IdCuenta      INT NOT NULL,
    PAN_Enc       VARBINARY(256) NOT NULL,  
    Ultimos4      CHAR(4) NOT NULL,
    VenceMes      TINYINT NOT NULL,
    VenceAnio     SMALLINT NOT NULL,
    Estatus       VARCHAR(15) NOT NULL DEFAULT 'Activa',
    CONSTRAINT FK_Tarjeta_Cuenta
      FOREIGN KEY (IdCuenta) REFERENCES operacion.Cuenta(IdCuenta)
);
GO


CREATE TABLE operacion.Transaccion (
    IdTx         BIGINT IDENTITY PRIMARY KEY,
    IdCuenta     INT NOT NULL,
    Fecha        DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    Tipo         VARCHAR(20) NOT NULL,         
    Monto        DECIMAL(18,2) NOT NULL,
    Descripcion  NVARCHAR(200) NULL,
    CONSTRAINT FK_Tx_Cuenta
      FOREIGN KEY (IdCuenta) REFERENCES operacion.Cuenta(IdCuenta)
);
GO

CREATE TABLE seguridad.UsuarioSistema (
    IdUsuario     INT IDENTITY PRIMARY KEY,
    Usuario       NVARCHAR(50) NOT NULL UNIQUE,
    Salt          VARBINARY(16) NOT NULL,
    PwdHash       VARBINARY(64) NOT NULL,          
    Nombre        NVARCHAR(80) NULL,
    Activo        BIT NOT NULL DEFAULT 1,
    FechaAlta     DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE TABLE seguridad.RolSistema (
    IdRol   INT IDENTITY PRIMARY KEY,
    Nombre  NVARCHAR(40) NOT NULL UNIQUE  
);
GO

CREATE TABLE seguridad.UsuarioRol (
    IdUsuario INT NOT NULL,
    IdRol     INT NOT NULL,
    PRIMARY KEY (IdUsuario, IdRol),
    FOREIGN KEY (IdUsuario) REFERENCES seguridad.UsuarioSistema(IdUsuario),
    FOREIGN KEY (IdRol) REFERENCES seguridad.RolSistema(IdRol)
);
GO

USE Banco_CapibarasMX;  

CREATE LOGIN app_banco_login WITH PASSWORD = 'AppCapibaras#2025!'; 
CREATE LOGIN cajero_login    WITH PASSWORD = 'CajeroCapibara#2025!';
CREATE LOGIN auditor_login   WITH PASSWORD = 'AuditorCapibara#2025!';

                                         

CREATE USER app_banco_user FOR LOGIN app_banco_login;           
CREATE USER cajero_user    FOR LOGIN cajero_login;
CREATE USER auditor_user   FOR LOGIN auditor_login;
GO

CREATE ROLE rolAplicacion
CREATE ROLE rolCajero;                                            
CREATE ROLE rolAuditor;                                           
GO

EXEC sp_addrolemember 'rolAplicacion', 'app_banco_user';          
EXEC sp_addrolemember 'rolCajero',     'cajero_user';
EXEC sp_addrolemember 'rolAuditor',    'auditor_user';
GO

GRANT SELECT, INSERT, UPDATE ON catalogo.Cliente  TO rolAplicacion;      
GRANT SELECT, INSERT, UPDATE ON operacion.Cuenta  TO rolAplicacion;      
GRANT SELECT, INSERT         ON operacion.Tarjeta TO rolAplicacion;      
GRANT SELECT, INSERT         ON operacion.Transaccion TO rolAplicacion;  

GRANT SELECT ON catalogo.Cliente  TO rolCajero;                          
GRANT SELECT ON operacion.Cuenta  TO rolCajero;                          
GRANT SELECT, INSERT ON operacion.Transaccion TO rolCajero;              

GRANT SELECT ON catalogo.Cliente       TO rolAuditor;
GRANT SELECT ON operacion.Cuenta       TO rolAuditor;
GRANT SELECT ON operacion.Tarjeta      TO rolAuditor;
GRANT SELECT ON operacion.Transaccion  TO rolAuditor;

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Ll4v3Pru3b4$';  
GO

CREATE CERTIFICATE Certificado_Cifrado
    WITH SUBJECT = 'Cifrado de datos sensibles Banco_CapibarasMX';      
GO

CREATE SYMMETRIC KEY Llave_Certificado
    WITH ALGORITHM = AES_256                                            
    ENCRYPTION BY CERTIFICATE Certificado_Cifrado;                      
GO

CREATE OR ALTER PROCEDURE catalogo.sp_InsertarCliente
    @Nombre NVARCHAR(60),
    @ApellidoPaterno NVARCHAR(60),
    @ApellidoMaterno NVARCHAR(60) = NULL,
    @RFC CHAR(13),
    @CURP NVARCHAR(18) = NULL,
    @Telefono NVARCHAR(20) = NULL,
    @Email NVARCHAR(120) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    OPEN SYMMETRIC KEY Llave_Certificado
        DECRYPTION BY CERTIFICATE Certificado_Cifrado;

    INSERT INTO catalogo.Cliente(Nombre, ApellidoPaterno, ApellidoMaterno, RFC,
                                 CURP_Enc, Telefono_Enc, Email)
    VALUES (@Nombre, @ApellidoPaterno, @ApellidoMaterno, @RFC,
            CASE WHEN @CURP IS NULL THEN NULL
                 ELSE ENCRYPTBYKEY(KEY_GUID('Llave_Certificado'), CONVERT(VARBINARY(MAX), @CURP)) END,
            CASE WHEN @Telefono IS NULL THEN NULL
                 ELSE ENCRYPTBYKEY(KEY_GUID('Llave_Certificado'), CONVERT(VARBINARY(MAX), @Telefono)) END,
            @Email);

    CLOSE SYMMETRIC KEY Llave_Certificado;
END
GO

CREATE OR ALTER PROCEDURE operacion.sp_AltaTarjeta
    @IdCuenta INT,
    @PAN NVARCHAR(19),
    @VenceMes TINYINT,
    @VenceAnio SMALLINT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Ult4 CHAR(4) = RIGHT(REPLACE(@PAN,' ','') , 4);

    OPEN SYMMETRIC KEY Llave_Certificado
        DECRYPTION BY CERTIFICATE Certificado_Cifrado;

    INSERT INTO operacion.Tarjeta(IdCuenta, PAN_Enc, Ultimos4, VenceMes, VenceAnio)
    VALUES (
        @IdCuenta,
        ENCRYPTBYKEY(KEY_GUID('Llave_Certificado'), CONVERT(VARBINARY(MAX), @PAN)),
        @Ult4, @VenceMes, @VenceAnio
    );

    CLOSE SYMMETRIC KEY Llave_Certificado;
END
GO

CREATE OR ALTER VIEW operacion.vw_Tarjeta_Segura
AS
SELECT IdTarjeta, IdCuenta, '****-****-****-' + Ultimos4 AS PAN_Masc,    
       VenceMes, VenceAnio, Estatus
FROM operacion.Tarjeta;
GO

OPEN MASTER KEY DECRYPTION BY PASSWORD = 'Ll4v3Pru3b4$';
ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;
CLOSE MASTER KEY;
GO


CREATE OR ALTER VIEW catalogo.vw_Cliente_Seguro
AS
SELECT
  c.IdCliente,
  c.Nombre,
  c.ApellidoPaterno,
  c.ApellidoMaterno,
  c.RFC,
  c.Email,
  '****' + RIGHT(
      TRY_CONVERT(NVARCHAR(18),
        DECRYPTBYKEYAUTOCERT(CERT_ID('Certificado_Cifrado'), NULL, c.CURP_Enc)
      ), 4) AS CURP_Masc,
  '***' AS Telefono_Masc
FROM catalogo.Cliente AS c;
GO



GRANT EXECUTE ON catalogo.sp_InsertarCliente TO rolAplicacion, rolCajero;
GRANT EXECUTE ON operacion.sp_AltaTarjeta   TO rolAplicacion;

GRANT SELECT ON catalogo.vw_Cliente_Seguro  TO rolAplicacion, rolCajero, rolAuditor;
GRANT SELECT ON operacion.vw_Tarjeta_Segura TO rolAplicacion, rolCajero, rolAuditor;
GO

CREATE OR ALTER PROCEDURE seguridad.sp_CrearUsuarioSistema
    @Usuario NVARCHAR(50),
    @Password NVARCHAR(200),
    @Nombre NVARCHAR(80) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Salt VARBINARY(16) = CRYPT_GEN_RANDOM(16);
    DECLARE @PwdHash VARBINARY(64) =
        HASHBYTES('SHA2_256', @Salt + CONVERT(VARBINARY(4000), @Password));

    INSERT INTO seguridad.UsuarioSistema(Usuario, Salt, PwdHash, Nombre)
    VALUES (@Usuario, @Salt, @PwdHash, @Nombre);
END
GO


CREATE OR ALTER PROCEDURE seguridad.sp_VerificarLogin
    @Usuario NVARCHAR(50),
    @Password NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Salt VARBINARY(16), @HashGuardado VARBINARY(64);
    SELECT @Salt = Salt, @HashGuardado = PwdHash
    FROM seguridad.UsuarioSistema
    WHERE Usuario = @Usuario AND Activo = 1;

    IF @Salt IS NULL
    BEGIN
        SELECT Resultado = 0; RETURN;
    END

    DECLARE @HashCalculado VARBINARY(64) =
        HASHBYTES('SHA2_256', @Salt + CONVERT(VARBINARY(4000), @Password));

    SELECT Resultado = CASE WHEN @HashCalculado = @HashGuardado THEN 1 ELSE 0 END;
END
GO

GRANT EXECUTE ON seguridad.sp_CrearUsuarioSistema TO rolAplicacion;
GRANT EXECUTE ON seguridad.sp_VerificarLogin     TO rolAplicacion;
GO

USE master;
IF NOT EXISTS (SELECT 1 FROM sys.server_audits WHERE name = 'Audit_BancoCapibaras')
BEGIN
    CREATE SERVER AUDIT Audit_BancoCapibaras
    TO FILE (FILEPATH = 'C:\SQLAudit\BancoCapibaras\')
    WITH (ON_FAILURE = CONTINUE);
END
GO

ALTER SERVER AUDIT Audit_BancoCapibaras WITH (STATE = ON);
GO

USE Banco_CapibarasMX;
IF NOT EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = 'DbAudit_BancoCapibaras')
BEGIN
    CREATE DATABASE AUDIT SPECIFICATION DbAudit_BancoCapibaras
    FOR SERVER AUDIT Audit_BancoCapibaras
        ADD (SELECT, INSERT, UPDATE ON OBJECT::catalogo.Cliente   BY PUBLIC),
        ADD (SELECT, INSERT, UPDATE ON OBJECT::operacion.Tarjeta  BY PUBLIC),
        ADD (EXECUTE ON OBJECT::catalogo.sp_InsertarCliente BY PUBLIC),
        ADD (EXECUTE ON OBJECT::operacion.sp_AltaTarjeta    BY PUBLIC),
        ADD (EXECUTE ON OBJECT::seguridad.sp_CrearUsuarioSistema BY PUBLIC),
        ADD (EXECUTE ON OBJECT::seguridad.sp_VerificarLogin     BY PUBLIC)
    WITH (STATE = ON);
END
GO