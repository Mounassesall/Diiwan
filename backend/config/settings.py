"""
Django settings for config project.
"""

import os
import dj_database_url
from pathlib import Path
from dotenv import load_dotenv

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# En local, charge .env. En production (Render), les vars sont déjà dans l'env.
load_dotenv(os.path.join(BASE_DIR, '.env'))

# ---------------------------------------------------------------------------
# SÉCURITÉ
# ---------------------------------------------------------------------------

SECRET_KEY = os.environ['SECRET_KEY']  # Obligatoire — pas de valeur par défaut

DEBUG = os.getenv('DEBUG', 'False') == 'True'

# ALLOWED_HOSTS : localhost en dev, domaine Render + Vercel en prod
_raw_hosts = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1,10.0.2.2')
ALLOWED_HOSTS = [h.strip() for h in _raw_hosts.split(',') if h.strip()]

# ---------------------------------------------------------------------------
# APPLICATIONS
# ---------------------------------------------------------------------------

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.gis',
    'rest_framework',
    'corsheaders',
    'statistiques',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',   # Doit être juste après SecurityMiddleware
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# ---------------------------------------------------------------------------
# BASE DE DONNÉES
# ---------------------------------------------------------------------------
# En production : DATABASE_URL est fournie par Render (ex: postgres://...)
# En local     : on lit les vars DB_* du .env
# ---------------------------------------------------------------------------

DATABASE_URL = os.getenv('DATABASE_URL')

if DATABASE_URL:
    # Production Render — dj-database-url parse l'URL
    DATABASES = {
        'default': dj_database_url.config(
            default=DATABASE_URL,
            conn_max_age=600,
            conn_health_checks=True,
        )
    }
    # Forcer le backend PostGIS (Render supporte PostGIS sur son PostgreSQL managé)
    DATABASES['default']['ENGINE'] = 'django.contrib.gis.db.backends.postgis'
else:
    # Développement local
    DATABASES = {
        'default': {
            'ENGINE': 'django.contrib.gis.db.backends.postgis',
            'NAME': os.getenv('DB_NAME', 'diiwan_db'),
            'USER': os.getenv('DB_USER', 'postgres'),
            'PASSWORD': os.getenv('DB_PASSWORD', 'postgres'),
            'HOST': os.getenv('DB_HOST', 'localhost'),
            'PORT': os.getenv('DB_PORT', '5432'),
        }
    }

# GDAL/GEOS uniquement en développement Windows
if os.name == 'nt':
    GDAL_LIBRARY_PATH = r'C:\Program Files\PostgreSQL\15\bin\libgdal-34.dll'
    GEOS_LIBRARY_PATH = r'C:\Program Files\PostgreSQL\15\bin\libgeos_c.dll'

# ---------------------------------------------------------------------------
# CORS
# ---------------------------------------------------------------------------

CORS_ALLOW_ALL_ORIGINS = False

# CORS_ALLOWED_ORIGINS est lu depuis la variable d'env CORS_ALLOWED_ORIGINS
# (liste séparée par des virgules), avec fallback sur les URLs localhost de dev.
_raw_cors = os.getenv('CORS_ALLOWED_ORIGINS', ','.join([
    'http://localhost:3000',
    'http://127.0.0.1:3000',
    'http://localhost:5173',
    'http://127.0.0.1:5173',
    'http://localhost:5174',
    'http://127.0.0.1:5174',
    'http://localhost:8081',
    'http://127.0.0.1:8081',
]))
CORS_ALLOWED_ORIGINS = [u.strip() for u in _raw_cors.split(',') if u.strip()]

# ---------------------------------------------------------------------------
# IA GÉNÉRATIVE
# ---------------------------------------------------------------------------

GEMINI_API_KEY = os.getenv('GEMINI_API_KEY', '')
USE_GENERATIVE_AI = os.getenv('USE_GENERATIVE_AI', 'False') == 'True'

# ---------------------------------------------------------------------------
# FICHIERS STATIQUES (WhiteNoise pour production)
# ---------------------------------------------------------------------------

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# ---------------------------------------------------------------------------
# INTERNATIONALISATION
# ---------------------------------------------------------------------------

LANGUAGE_CODE = 'fr-fr'
TIME_ZONE = 'Africa/Dakar'
USE_I18N = True
USE_TZ = True

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ---------------------------------------------------------------------------
# DRF — THROTTLING
# ---------------------------------------------------------------------------

REST_FRAMEWORK = {
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle'
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '30/min',
        'user': '100/min'
    }
}

# ---------------------------------------------------------------------------
# SÉCURITÉ HTTPS (production uniquement)
# ---------------------------------------------------------------------------

if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_SSL_REDIRECT = False  # Render gère lui-même la redirection HTTPS
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
