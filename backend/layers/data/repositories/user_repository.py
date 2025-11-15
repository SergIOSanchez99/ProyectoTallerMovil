"""
User Repository
Repositorio para manejar operaciones de base de datos de usuarios
"""

import mysql.connector
from mysql.connector import Error
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
            if self.connection is None or not self.connection.is_connected():
                self.connection = mysql.connector.connect(
                    host=os.getenv('DB_HOST', '127.0.0.1'),
                    port=os.getenv('DB_PORT', 3306),
                    database=os.getenv('DB_NAME', 'taller_movil_db'),
                    user=os.getenv('DB_USER', 'root'),
                    password=os.getenv('DB_PASSWORD', 'overload'),
                    autocommit=False
                )
                logger.info("✅ Conexión a MySQL establecida")
        except Error as e:
            logger.error(f"❌ Error conectando a MySQL: {e}")
            self.connection = None
    
    def _ensure_connection(self):
        """Asegura que hay una conexión activa"""
        if self.connection is None or not self.connection.is_connected():
            self._get_connection()
    
    def create_user(self, email: str, password: str, name: str, 
                   profile_image: Optional[str] = None) -> Optional[Dict]:
        """
        Crea un nuevo usuario en la base de datos
        
        Args:
            email: Email del usuario
            password: Contraseña
            name: Nombre completo
            profile_image: URL de imagen de perfil (opcional)
            
        Returns:
            Diccionario con los datos del usuario creado o None si falla
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
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
        
        Args:
            email: Email del usuario
            
        Returns:
            Diccionario con los datos del usuario o None si no existe
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
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
        
        Args:
            user_id: ID del usuario
            
        Returns:
            Diccionario con los datos del usuario o None si no existe
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
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
        
        Args:
            email: Email del usuario
            password: Contraseña a verificar
            
        Returns:
            True si la contraseña es correcta, False en caso contrario
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
        
        Args:
            email: Email a verificar
            
        Returns:
            True si el email existe, False en caso contrario
        """
        user = self.get_user_by_email(email)
        return user is not None
    
    def get_all_users(self, active_only: bool = False) -> List[Dict]:
        """
        Obtiene todos los usuarios
        
        Args:
            active_only: Si es True, solo devuelve usuarios activos
            
        Returns:
            Lista de diccionarios con los datos de los usuarios
        """
        self._ensure_connection()
        if not self.connection:
            return []
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
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
        if self.connection and self.connection.is_connected():
            self.connection.close()
            logger.info("✅ Conexión a MySQL cerrada")

