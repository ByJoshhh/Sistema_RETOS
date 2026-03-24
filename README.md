# Sistema RETOS (Registro de Entrega de Material por Transporte a Obra o Suministro)

Bienvenido al repositorio oficial del **Sistema RETOS**. Esta plataforma es una solución integral (Software as a Service - SaaS) diseñada para digitalizar, monitorear y asegurar el flujo de transporte de materiales de construcción desde su origen (Banco) hasta su destino final (Obra).

Este repositorio está estructurado como un **Monorepo**, conteniendo tanto el aplicativo móvil como el servidor central.

## Arquitectura Tecnológica
El proyecto está desarrollado bajo una arquitectura Cliente-Servidor robusta:
* **Frontend (Aplicación Móvil):** Desarrollado en **Flutter** (Dart), compilado nativamente para Android/iOS.
* **Backend (API REST):** Desarrollado en **Node.js** con el framework **Express**.
* **Base de Datos:** Motor relacional **MySQL**, estructurado para soportar múltiples empresas (Multi-tenant).

## Estructura del Proyecto
* `/retos_app`: Contiene todo el código fuente de la aplicación móvil en Flutter.
* `/backend_retos`: Contiene el servidor de Node.js, controladores, rutas y configuración de conexión a la base de datos.

---

## Avances Actuales (Fase 1: Core Operativo y Lógica SaaS)
Actualmente, el sistema cuenta con el flujo operativo central terminado y blindado con seguridad basada en roles.

### 1. Autenticación y Seguridad Multi-Empresa (SaaS)
* **RBAC (Role-Based Access Control):** El sistema identifica si el usuario es un *Checador de Banco*, *Checador de Obra* o *Administrador*, renderizando interfaces condicionales en tiempo real.
* **Persistencia de Sesión:** Implementación de `SharedPreferences` en el dispositivo móvil para almacenar tokens de sesión. Cada transacción (Suministro o Recepción) viaja firmada digitalmente con el `id_usuario` e `id_empresa` reales, eliminando la dependencia de datos fijos (hardcodeados).

### 2. Módulo de Suministro (Origen)
* Consumo dinámico de catálogos desde la base de datos (Bancos, Materiales, Destinos, Unidades, Residentes).
* Generación automática de folios únicos de seguimiento (Ej. `GYB-XXXX`).
* Pantalla de captura de evidencia fotográfica pre-viaje (Placas y Material).
* Generación de Ticket Digital con **Código QR** para su futura validación en campo.

### 3. Módulo de Acarreo / Recepción (Destino)
* Búsqueda en tiempo real de camiones "En tránsito" conectada al servidor Node.js.
* Interfaz de validación de datos de origen (Solo Lectura) para evitar fraudes en la entrega.
* Captura de métricas de cierre: Distancia real (km) y Volumen real recibido (m3).
* Cierre de ciclo automatizado: Al registrar la evidencia fotográfica de llegada, el backend actualiza el estatus del viaje a "Entregado" y genera un folio final de recepción.

### 4. Módulo de Auditoría (Consultas)
* Historial de viajes con indicadores de estado visuales (En tránsito / Entregado).
* Peticiones optimizadas con `JOIN`s en SQL para evitar la sobrecarga del dispositivo móvil.

---

## Próximo Roadmap (Fase de Campo y Hardware)
Las siguientes etapas del desarrollo se enfocarán en la interacción del software con el mundo físico:
1. **Lector de Código QR Nativo:** Integración del escáner de cámara en Flutter para automatizar la recepción de viajes sin teclear folios manualmente.
2. **Sistema de Archivos Centralizado:** Configuración de `Multer` en Node.js para recibir, renombrar y almacenar físicamente las evidencias fotográficas de los celulares en el servidor.
3. **Impresión Térmica:** Conexión vía Bluetooth con impresoras portátiles para la emisión de comprobantes físicos en zonas sin cobertura de red.
4. **Dashboard Administrativo:** Panel de control web para la gestión de catálogos (CRUD) e indicadores de volumen.

---
*Desarrollado y mantenido por Joshua.*
