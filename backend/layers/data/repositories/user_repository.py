"""
User Repository
Repositorio para manejar operaciones de base de datos de usuarios
"""

import pymysql
from pymysql import Error
from typing import Optional, Dict, List
import os
import logging

logger = logging.getLogger(__name__)


class UserRepository:
    """Repositorio para operaciones de usuarios en MySQL"""
    
    def __init__(self):
        self.connection = None
        self._get_connection()
    
    def _get_connection(self):
        """Obtiene o crea una conexión a la base de datos"""
        try:
            if self.connection is None or not self.connection.open:
                db_host = os.getenv('DB_HOST', '127.0.0.1')
                db_config = {
                    'user': os.getenv('DB_USER', 'root'),
                    'password': os.getenv('DB_PASSWORD', 'overload'),
                    'database': os.getenv('DB_NAME', 'taller_movil_db'),
                    'autocommit': False,
                    'cursorclass': pymysql.cursors.DictCursor
                }

                if db_host.startswith('/cloudsql/'):
                    db_config['unix_socket'] = db_host
                else:
                    db_config['host'] = db_host
                    db_config['port'] = int(os.getenv('DB_PORT', 3306))

                self.connection = pymysql.connect(**db_config)
                logger.info("✅ Conexión a MySQL establecida (PyMySQL)")
        except Error as e:
            logger.error(f"❌ Error conectando a MySQL: {e}")
            self.connection = None
    
    def _ensure_connection(self):
        """Asegura que hay una conexión activa"""
        if self.connection is None or not self.connection.open:
            self._get_connection()
    
    def create_user(self, email: str, password: str, name: str, 
                   profile_image: Optional[str] = None) -> Optional[Dict]:
        """
        Crea un nuevo usuario en la base de datos
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor()
            query = """
                INSERT INTO usuarios (email, password, name, profile_image)
                VALUES (%s, %s, %s, %s)
            """
            values = (email.lower(), password, name, profile_image)
            
            cursor.execute(query, values)
            self.connection.commit()
            
            # Obtener el usuario recién creado
            user_id = cursor.lastrowid
            return self.get_user_by_id(user_id)
            
        except Error as e:
            logger.error(f"❌ Error creando usuario: {e}")
            if self.connection:
                self.connection.rollback()
            return None
        finally:
            if cursor:
                cursor.close()
    
    def get_user_by_email(self, email: str) -> Optional[Dict]:
        """
        Obtiene un usuario por su email
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor()
            query = "SELECT * FROM usuarios WHERE email = %s"
            cursor.execute(query, (email.lower(),))
            result = cursor.fetchone()
            return result
        except Error as e:
            logger.error(f"❌ Error obteniendo usuario: {e}")
            return None
        finally:
            if cursor:
                cursor.close()
    
    def get_user_by_id(self, user_id: int) -> Optional[Dict]:
        """
        Obtiene un usuario por su ID
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor()
            query = "SELECT * FROM usuarios WHERE id = %s"
            cursor.execute(query, (user_id,))
            result = cursor.fetchone()
            return result
        except Error as e:
            logger.error(f"❌ Error obteniendo usuario: {e}")
            return None
        finally:
            if cursor:
                cursor.close()
    
    def verify_password(self, email: str, password: str) -> bool:
        """
        Verifica si la contraseña es correcta para un usuario
        """
        try:
            user = self.get_user_by_email(email)
            # Verificar que el usuario existe y está activo
            if not user:
                logger.warning(f"Intento de login con email no registrado: {email}")
                return False
            
            # Verificar que el usuario esté activo
            if not user.get('is_active', True):
                logger.warning(f"Intento de login con usuario inactivo: {email}")
                return False
            
            # Verificar la contraseña
            if user['password'] == password:
                logger.info(f"Contraseña verificada correctamente para: {email}")
                return True
            else:
                logger.warning(f"Contraseña incorrecta para: {email}")
                return False
        except Exception as e:
            logger.error(f"Error verificando contraseña: {e}")
            return False
    
    def email_exists(self, email: str) -> bool:
        """
        Verifica si un email ya está registrado
        """
        user = self.get_user_by_email(email)
        return user is not None
    
    def get_all_users(self, active_only: bool = False) -> List[Dict]:
        """
        Obtiene todos los usuarios
        """
        self._ensure_connection()
        if not self.connection:
            return []
            
        cursor = None
        try:
            cursor = self.connection.cursor()
            if active_only:
                query = "SELECT * FROM usuarios WHERE is_active = TRUE ORDER BY created_at DESC"
            else:
                query = "SELECT * FROM usuarios ORDER BY created_at DESC"
            
            cursor.execute(query)
            results = cursor.fetchall()
            return results
        except Error as e:
            logger.error(f"❌ Error obteniendo usuarios: {e}")
            return []
        finally:
            if cursor:
                cursor.close()
    
    def close(self):
        """Cierra la conexión a la base de datos"""
        if self.connection and self.connection.open:
            self.connection.close()
            logger.info("✅ Conexión a MySQL cerrada")
