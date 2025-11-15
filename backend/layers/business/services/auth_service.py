"""
Authentication Service
Servicio de negocio para autenticación de usuarios
"""

from typing import Optional, Dict
from datetime import datetime
from ...data.repositories.user_repository import UserRepository
import logging

logger = logging.getLogger(__name__)


class AuthService:
    """Servicio de autenticación"""
    
    def __init__(self):
        self.user_repository = UserRepository()
    
    def register(self, email: str, password: str, name: str, 
                profile_image: Optional[str] = None) -> Dict:
        """
        Registra un nuevo usuario
        
        Args:
            email: Email del usuario
            password: Contraseña
            name: Nombre completo
            profile_image: URL de imagen de perfil (opcional)
            
        Returns:
            Diccionario con success, data y message
        """
        try:
            # Validaciones
            if not email or not password or not name:
                return {
                    "success": False,
                    "error": "Todos los campos son requeridos"
                }
            
            if len(password) < 6:
                return {
                    "success": False,
                    "error": "La contraseña debe tener al menos 6 caracteres"
                }
            
            if len(name) < 2:
                return {
                    "success": False,
                    "error": "El nombre debe tener al menos 2 caracteres"
                }
            
            # Verificar si el email ya existe
            if self.user_repository.email_exists(email):
                return {
                    "success": False,
                    "error": "El email ya está registrado"
                }
            
            # Crear usuario
            user = self.user_repository.create_user(email, password, name, profile_image)
            
            if user:
                # Preparar respuesta (sin contraseña)
                # Formatear fecha de manera segura para JSON
                created_at = user['created_at']
                if isinstance(created_at, datetime):
                    created_at_str = created_at.isoformat()
                elif hasattr(created_at, 'isoformat'):
                    created_at_str = created_at.isoformat()
                else:
                    created_at_str = str(created_at)
                
                user_data = {
                    "id": str(user['id']),
                    "email": user['email'],
                    "name": user['name'],
                    "profileImage": user.get('profile_image'),
                    "createdAt": created_at_str,
                    "isActive": bool(user['is_active'])
                }
                
                return {
                    "success": True,
                    "data": user_data,
                    "message": "Usuario registrado exitosamente"
                }
            else:
                return {
                    "success": False,
                    "error": "Error al crear el usuario en la base de datos"
                }
                
        except Exception as e:
            logger.exception("Error en registro de usuario")
            return {
                "success": False,
                "error": f"Error al registrar usuario: {str(e)}"
            }
    
    def login(self, email: str, password: str) -> Dict:
        """
        Autentica un usuario
        
        Args:
            email: Email del usuario
            password: Contraseña
            
        Returns:
            Diccionario con success, data y message
        """
        try:
            if not email or not password:
                return {
                    "success": False,
                    "error": "Email y contraseña son requeridos"
                }
            
            # Verificar que el email existe primero
            email_exists = self.user_repository.email_exists(email)
            
            if not email_exists:
                logger.warning(f"Intento de login con email no registrado: {email}")
                return {
                    "success": False,
                    "error": "El email ingresado no está registrado. Verifica tu email o regístrate."
                }
            
            # Si el email existe, verificar credenciales
            if self.user_repository.verify_password(email, password):
                user = self.user_repository.get_user_by_email(email)
                
                if user:
                    # Verificar que el usuario esté activo
                    if not user.get('is_active', True):
                        logger.warning(f"Intento de login con usuario inactivo: {email}")
                        return {
                            "success": False,
                            "error": "Tu cuenta está desactivada. Contacta al administrador."
                        }
                    
                    # Preparar respuesta (sin contraseña)
                    # Formatear fecha de manera segura para JSON
                    created_at = user['created_at']
                    if isinstance(created_at, datetime):
                        created_at_str = created_at.isoformat()
                    elif hasattr(created_at, 'isoformat'):
                        created_at_str = created_at.isoformat()
                    else:
                        created_at_str = str(created_at)
                    
                    user_data = {
                        "id": str(user['id']),
                        "email": user['email'],
                        "name": user['name'],
                        "profileImage": user.get('profile_image'),
                        "createdAt": created_at_str,
                        "isActive": bool(user['is_active'])
                    }
                    
                    logger.info(f"Login exitoso para: {email}")
                    return {
                        "success": True,
                        "data": user_data,
                        "message": "Login exitoso"
                    }
            
            # Si llegamos aquí, el email existe pero la contraseña es incorrecta
            logger.warning(f"Contraseña incorrecta para: {email}")
            return {
                "success": False,
                "error": "Contraseña incorrecta. Verifica tu contraseña e intenta nuevamente."
            }
            
        except Exception as e:
            logger.exception("Error en login de usuario")
            return {
                "success": False,
                "error": f"Error al autenticar usuario: {str(e)}"
            }
    
    def get_user_by_email(self, email: str) -> Optional[Dict]:
        """
        Obtiene un usuario por su email
        
        Args:
            email: Email del usuario
            
        Returns:
            Diccionario con los datos del usuario o None
        """
        try:
            user = self.user_repository.get_user_by_email(email)
            if user:
                # Formatear fecha de manera segura para JSON
                created_at = user['created_at']
                if isinstance(created_at, datetime):
                    created_at_str = created_at.isoformat()
                elif hasattr(created_at, 'isoformat'):
                    created_at_str = created_at.isoformat()
                else:
                    created_at_str = str(created_at)
                
                return {
                    "id": str(user['id']),
                    "email": user['email'],
                    "name": user['name'],
                    "profileImage": user.get('profile_image'),
                    "createdAt": created_at_str,
                    "isActive": bool(user['is_active'])
                }
            return None
        except Exception as e:
            logger.exception("Error obteniendo usuario")
            return None
    
    def get_all_users(self, active_only: bool = False) -> Dict:
        """
        Obtiene todos los usuarios registrados (sin contraseñas)
        
        Args:
            active_only: Si es True, solo devuelve usuarios activos
            
        Returns:
            Diccionario con success, data (lista de usuarios) y message
        """
        try:
            users = self.user_repository.get_all_users(active_only=active_only)
            
            # Formatear usuarios (sin contraseñas)
            formatted_users = []
            for user in users:
                # Formatear fecha de manera segura para JSON
                created_at = user.get('created_at')
                if isinstance(created_at, datetime):
                    created_at_str = created_at.isoformat()
                elif hasattr(created_at, 'isoformat'):
                    created_at_str = created_at.isoformat()
                else:
                    created_at_str = str(created_at) if created_at else None
                
                updated_at = user.get('updated_at')
                if isinstance(updated_at, datetime):
                    updated_at_str = updated_at.isoformat()
                elif hasattr(updated_at, 'isoformat'):
                    updated_at_str = updated_at.isoformat()
                else:
                    updated_at_str = str(updated_at) if updated_at else None
                
                formatted_users.append({
                    "id": str(user['id']),
                    "email": user['email'],
                    "name": user['name'],
                    "profileImage": user.get('profile_image'),
                    "createdAt": created_at_str,
                    "updatedAt": updated_at_str,
                    "isActive": bool(user.get('is_active', True))
                })
            
            return {
                "success": True,
                "data": formatted_users,
                "count": len(formatted_users),
                "message": f"Se encontraron {len(formatted_users)} usuario(s)"
            }
        except Exception as e:
            logger.exception("Error obteniendo todos los usuarios")
            return {
                "success": False,
                "error": f"Error al obtener usuarios: {str(e)}"
            }

