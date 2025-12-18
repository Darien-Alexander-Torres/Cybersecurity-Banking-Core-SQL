🏦 Banco Capibaras_MX: Security & Banking Infrastructure

Este proyecto representa una solución integral de Ciberseguridad en Bases de Datos para una institución financiera. Se enfoca en la protección de activos críticos, el cumplimiento de normativas bancarias y la implementación de defensas técnicas avanzadas en SQL Server.
🛡️ Pilares de Seguridad Implementados
1. Criptografía Avanzada (At-Rest)

    Cifrado de Columnas: Implementación de llaves simétricas con algoritmo AES_256 para proteger datos de identidad (CURP, Teléfono) y financieros (PAN de tarjetas).sql].

    Hashing con Salting: Almacenamiento de credenciales mediante SHA2_256 combinado con un Salt de 16 bytes generado aleatoriamente para cada usuario.sql].

    Enmascaramiento de Datos: Uso de vistas seguras que aplican máscaras de texto (ej. ****-****-****-1234) para limitar la visibilidad de datos sensibles según el rol del usuario.sql].

2. Control de Acceso y Gestión de Roles

    Principio de Privilegios Mínimos: Definición de roles segregados (rolAplicacion, rolCajero, rolAuditor) con permisos estrictos de GRANT y DENY sobre esquemas y procedimientos.sql].

    Segregación de Funciones: Separación de la lógica de negocio en esquemas dedicados: catalogo, operacion y seguridad.sql].

3. Auditoría y Monitoreo (Logging)

    Server Audit: Configuración de auditoría a nivel de servidor y base de datos para rastrear ejecuciones de procedimientos sensibles y acceso a tablas críticas.sql].

    Trazabilidad: Monitoreo activo de intentos de inicio de sesión y modificaciones transaccionales.

4. Gobernanza y Resiliencia (Compliance)

    Políticas de Seguridad: Documentación de reglamentos internos alineados con normativas financieras, incluyendo gestión de contraseñas y backups.

Plan de Respuesta a Incidentes (PRI): Protocolos detallados para la contención y recuperación ante ataques de Inyección SQL o escalada de privilegios.

📂 Estructura del Repositorio

    /sql: Script principal de despliegue con toda la lógica de seguridad y objetos de base de datos.sql].

    /docs: Documentación técnica (PIA) y manual de políticas de seguridad corporativa.
