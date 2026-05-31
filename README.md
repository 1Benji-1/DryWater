<h1 align="center">💧 DryWater</h1>

<p align="center">
  <strong>El asistente inteligente definitivo para el sector agropecuario, impulsado por Inteligencia Artificial y Análisis Predictivo.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi" alt="FastAPI" />
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python" />
  <img src="https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase" />
</p>

---

## 👤 Integrantes:
- Cristopher Naid Carballo Lopez
- Yoel Bulacia Vaca
- Esther Ruth Guzman Colque
- Patricia Rodriguez Ramirez
- Jhoel Arturo Villarroel Rocha
- Robert Leonardo Yujra

## 📖 Sobre el Proyecto

**AgroPros** es una plataforma móvil y backend diseñada específicamente para empoderar a los agricultores y productores agropecuarios. A través de la recolección de datos climáticos en tiempo real y el uso de Inteligencia Artificial (Anthropic/OpenAI), la aplicación proporciona alertas tempranas, pronósticos adaptados al tipo de cultivo y recomendaciones preventivas para proteger la producción.

## ✨ Funcionalidades Principales

*   🌦️ **Monitoreo Climático Inteligente:** Pronóstico preciso del clima a 5 días con análisis cruzado según el tipo de cultivo registrado (Ej: Papa, Maíz, etc.).
*   🤖 **Recomendaciones Generadas por IA:** Alertas dinámicas y planes de acción recomendados por IA basándose en los datos climáticos.
*   🔥 **Notificaciones de Incendios y Eventos Naturales:** Integración de alertas push en tiempo real ante la detección de riesgos extremos, como incendios forestales cercanos, tormentas severas, granizadas o heladas inminentes.
*   💧 **Prevención Inteligente de Sequías:** Un sistema predictivo que detecta patrones de posibles sequías a futuro. Cuando se detecta época de sequía inminente, el asistente notifica automáticamente al agropecuario con las mejores opciones preventivas, tales como:
    *   *Almacenamiento temprano de agua en pozos y reservorios artificiales.*
    *   *Uso de técnicas de conservación de humedad en el suelo.*
    *   *Ajuste en los calendarios de siembra.*
*   🔐 **Autenticación Segura y Perfiles:** Gestión de usuarios mediante JWT y Supabase, con soporte para sincronización en la nube y persistencia de datos local para lugares con baja conexión.

## 🗂️ Estructura Completa del Proyecto

El repositorio está dividido en dos partes fundamentales: el Backend y el Frontend, cada uno con una arquitectura limpia y escalable.

```text
agro-app/
│
├── Backend/                        # Servidor API REST y Workers en Python
│   ├── app/
│   │   ├── api/v1/endpoints/       # Controladores de rutas (Auth, Alerts, Profile)
│   │   ├── core/                   # Configuraciones (Seguridad, JWT, Logging)
│   │   ├── db/                     # Conexión con Supabase/PostgreSQL
│   │   ├── models/                 # Modelos ORM de Base de Datos
│   │   ├── schemas/                # Esquemas de validación con Pydantic (Request/Response)
│   │   ├── services/               # Lógica de Negocio (IA, Clima, Riesgos)
│   │   └── workers/                # Tareas en segundo plano (Background Tasks)
│   ├── tests/                      # Pruebas unitarias e integración (pytest)
│   ├── main.py                     # Punto de entrada de FastAPI
│   ├── requirements.txt            # Dependencias de Python
│   ├── docker-compose.yml          # Orquestador de contenedores
│   └── Dockerfile                  # Receta de la imagen del Backend
│
├── Frontend/                       # Aplicación Móvil en Flutter
│   ├── lib/
│   │   ├── blocs/                  # Gestores de estado BLoC
│   │   ├── core/                   # Utilidades, configuración, interceptores
│   │   ├── models/                 # Clases de datos en Dart
│   │   ├── screens/                # Interfaz de Usuario (Dashboard, Login, Perfil)
│   │   ├── services/               # Clientes HTTP y conexión con Backend
│   │   ├── widgets/                # Componentes visuales reutilizables
│   │   └── main.dart               # Punto de entrada de la aplicación
│   ├── test/                       # Smoke tests de Flutter
│   └── pubspec.yaml                # Dependencias de Dart/Flutter
│
├── .github/workflows/              # Pipelines de Integración Continua (CI/CD)
├── QA_MANUAL_MVP.md                # Manual de Pruebas de Calidad QA
└── README.md                       # Este archivo
```

## 🛠️ Dependencias y Pre-requisitos a Instalar

Para ejecutar y modificar este proyecto en tu entorno local, asegúrate de tener instaladas las siguientes herramientas:

### Generales
*   **[Git](https://git-scm.com/):** Para el control de versiones.
*   **[Visual Studio Code](https://code.visualstudio.com/)** o **[Android Studio](https://developer.android.com/studio):** Entorno de desarrollo recomendado.
*   **[Docker Desktop](https://www.docker.com/products/docker-desktop/):** Necesario para correr el backend fácilmente sin configurar Python manualmente.

### Para el Backend (Solo si no usas Docker)
*   **[Python 3.12](https://www.python.org/downloads/):** Versión requerida para soportar las librerías asíncronas modernas.
*   **Pip y venv:** Herramientas nativas de Python para dependencias y entornos virtuales.

### Para el Frontend (App Móvil)
*   **[Flutter SDK](https://docs.flutter.dev/get-started/install):** Versión 3.22.x o superior.
*   **Android SDK / Xcode:** Para compilar y emular en dispositivos Android o iOS.
*   *Nota: Debes tener un emulador Android/iOS configurado, o un teléfono físico conectado mediante cable USB/Wi-Fi con la depuración USB habilitada.*

### Variables de Entorno y Credenciales Externas
El proyecto requiere cuentas en los siguientes servicios (tienen capa gratuita):
1.  **Supabase:** Base de datos en la nube y sistema Auth.
2.  **WeatherAPI (u otra similar):** Para los datos meteorológicos.
3.  **Anthropic / OpenAI:** Para la generación de planes de acción IA.
4.  **Firebase:** Para los certificados de notificaciones Cloud Messaging (FCM).

---

## 🚀 Cómo Usar y Ejecutar la Aplicación

Sigue este paso a paso para arrancar la aplicación en tu computadora local:

### 1. Configurar y Levantar el Backend
Abra una terminal, ve a la carpeta del Backend, y configura tus llaves secretas.

```bash
cd Backend

# 1. Renombra el archivo de variables de entorno de ejemplo
cp .env.example .env

# 2. Edita el archivo .env con tus llaves de Supabase, Anthropic, etc.

# 3. Levanta el servidor usando Docker (recomendado)
docker-compose up --build -d
```
*¡Listo! La API estará encendida.*
*   **Documentación API Interactiva (Swagger):** `http://localhost:8000/docs`
*   **Verificar que funciona (Health Check):** `http://localhost:8000/api/v1/health`

### 2. Configurar y Levantar el Frontend
Abre otra ventana de tu terminal y conecta tu celular (o inicia tu emulador de Android/iPhone).

```bash
cd Frontend

# 1. Descarga todas las dependencias necesarias de Flutter
flutter pub get

# 2. Verifica si tu dispositivo está siendo detectado
flutter devices

# 3. Ejecuta la aplicación en tu celular/emulador
flutter run
```

### 3. ¡Empieza a Usar AgroPros!
1. Una vez la app abra, si eres un usuario nuevo, verás las pantallas de introducción (Onboarding).
2. Toca en **"Crear Cuenta"** y regístrate con tu correo y seleccionando el tipo de cultivo que produces.
3. Serás dirigido al **Dashboard**, donde la aplicación mostrará automáticamente las recomendaciones de clima generadas por Inteligencia Artificial para tu cosecha.

---
*Desarrollado con pasión para transformar y proteger el futuro agrícola.* 🌱
