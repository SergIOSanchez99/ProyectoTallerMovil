"""
Patient Repository
Repositorio para manejar operaciones de base de datos de pacientes
"""

import mysql.connector
from mysql.connector import Error
from typing import Optional, Dict, List
import os
import logging

logger = logging.getLogger(__name__)


class PatientRepository:
    """Repositorio para operaciones de pacientes en MySQL"""
    
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
                logger.info("✅ Conexión a MySQL establecida para pacientes")
        except Error as e:
            logger.error(f"❌ Error conectando a MySQL: {e}")
            self.connection = None
    
    def _ensure_connection(self):
        """Asegura que hay una conexión activa"""
        if self.connection is None or not self.connection.is_connected():
            self._get_connection()
    
    def create_patient(self, full_name: str, identification: str, age: Optional[int] = None) -> Optional[Dict]:
        """
        Crea un nuevo paciente en la base de datos
        
        Args:
            full_name: Nombre completo del paciente
            identification: Número de identificación (único)
            age: Edad del paciente (opcional)
            
        Returns:
            Diccionario con los datos del paciente creado o None si falla
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
            query = """
                INSERT INTO pacientes (full_name, identification, age)
                VALUES (%s, %s, %s)
            """
            values = (full_name, identification, age)
            
            cursor.execute(query, values)
            self.connection.commit()
            
            # Obtener el paciente recién creado
            patient_id = cursor.lastrowid
            logger.info(f"✅ Paciente creado exitosamente: ID {patient_id}")
            return self.get_patient_by_id(patient_id)
            
        except Error as e:
            logger.error(f"❌ Error creando paciente: {e}")
            if self.connection:
                self.connection.rollback()
            return None
        finally:
            if cursor:
                cursor.close()
    
    def get_patient_by_id(self, patient_id: int) -> Optional[Dict]:
        """
        Obtiene un paciente por su ID
        
        Args:
            patient_id: ID del paciente
            
        Returns:
            Diccionario con los datos del paciente o None si no existe
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
            query = "SELECT * FROM pacientes WHERE id = %s AND is_active = TRUE"
            cursor.execute(query, (patient_id,))
            result = cursor.fetchone()
            return result
        except Error as e:
            logger.error(f"❌ Error obteniendo paciente: {e}")
            return None
        finally:
            if cursor:
                cursor.close()
    
    def get_patient_by_identification(self, identification: str) -> Optional[Dict]:
        """
        Obtiene un paciente por su identificación
        
        Args:
            identification: Número de identificación
            
        Returns:
            Diccionario con los datos del paciente o None si no existe
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
            query = "SELECT * FROM pacientes WHERE identification = %s AND is_active = TRUE"
            cursor.execute(query, (identification,))
            result = cursor.fetchone()
            return result
        except Error as e:
            logger.error(f"❌ Error obteniendo paciente: {e}")
            return None
        finally:
            if cursor:
                cursor.close()
    
    def get_all_patients(self, active_only: bool = True, search: Optional[str] = None) -> List[Dict]:
        """
        Obtiene todos los pacientes
        
        Args:
            active_only: Si es True, solo devuelve pacientes activos
            search: Término de búsqueda para filtrar por nombre o identificación
            
        Returns:
            Lista de diccionarios con los datos de los pacientes
        """
        self._ensure_connection()
        if not self.connection:
            return []
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
            
            if search:
                search_term = f"%{search}%"
                if active_only:
                    query = """
                        SELECT * FROM pacientes 
                        WHERE is_active = TRUE 
                        AND (full_name LIKE %s OR identification LIKE %s)
                        ORDER BY full_name ASC
                    """
                    cursor.execute(query, (search_term, search_term))
                else:
                    query = """
                        SELECT * FROM pacientes 
                        WHERE full_name LIKE %s OR identification LIKE %s
                        ORDER BY full_name ASC
                    """
                    cursor.execute(query, (search_term, search_term))
            else:
                if active_only:
                    query = "SELECT * FROM pacientes WHERE is_active = TRUE ORDER BY full_name ASC"
                else:
                    query = "SELECT * FROM pacientes ORDER BY full_name ASC"
                cursor.execute(query)
            
            results = cursor.fetchall()
            return results
        except Error as e:
            logger.error(f"❌ Error obteniendo pacientes: {e}")
            return []
        finally:
            if cursor:
                cursor.close()
    
    def update_patient(self, patient_id: int, **kwargs) -> Optional[Dict]:
        """
        Actualiza los datos de un paciente
        
        Args:
            patient_id: ID del paciente
            **kwargs: Campos a actualizar
            
        Returns:
            Diccionario con los datos del paciente actualizado o None si falla
        """
        self._ensure_connection()
        if not self.connection:
            return None
        
        # Campos permitidos para actualizar
        allowed_fields = [
            'full_name', 'identification', 'age'
        ]
        
        # Filtrar solo campos permitidos
        update_fields = {k: v for k, v in kwargs.items() if k in allowed_fields and v is not None}
        
        if not update_fields:
            logger.warning("No hay campos válidos para actualizar")
            return None
        
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
            
            # Construir query dinámicamente
            set_clause = ", ".join([f"{field} = %s" for field in update_fields.keys()])
            query = f"UPDATE pacientes SET {set_clause} WHERE id = %s AND is_active = TRUE"
            
            values = list(update_fields.values()) + [patient_id]
            cursor.execute(query, values)
            self.connection.commit()
            
            logger.info(f"✅ Paciente actualizado exitosamente: ID {patient_id}")
            return self.get_patient_by_id(patient_id)
            
        except Error as e:
            logger.error(f"❌ Error actualizando paciente: {e}")
            if self.connection:
                self.connection.rollback()
            return None
        finally:
            if cursor:
                cursor.close()
    
    def delete_patient(self, patient_id: int) -> bool:
        """
        Elimina (desactiva) un paciente (soft delete)
        
        Args:
            patient_id: ID del paciente
            
        Returns:
            True si se eliminó correctamente, False en caso contrario
        """
        self._ensure_connection()
        if not self.connection:
            return False
        
        cursor = None
        try:
            cursor = self.connection.cursor()
            query = "UPDATE pacientes SET is_active = FALSE WHERE id = %s"
            cursor.execute(query, (patient_id,))
            self.connection.commit()
            
            logger.info(f"✅ Paciente eliminado exitosamente: ID {patient_id}")
            return cursor.rowcount > 0
            
        except Error as e:
            logger.error(f"❌ Error eliminando paciente: {e}")
            if self.connection:
                self.connection.rollback()
            return False
        finally:
            if cursor:
                cursor.close()
    
    def identification_exists(self, identification: str, exclude_id: Optional[int] = None) -> bool:
        """
        Verifica si una identificación ya está registrada
        
        Args:
            identification: Identificación a verificar
            exclude_id: ID del paciente a excluir de la verificación (útil para updates)
            
        Returns:
            True si la identificación existe, False en caso contrario
        """
        patient = self.get_patient_by_identification(identification)
        if patient is None:
            return False
        
        # Si se especifica un ID a excluir, verificar que no sea el mismo
        if exclude_id is not None:
            return patient['id'] != exclude_id
        
        return True
    
    def close(self):
        """Cierra la conexión a la base de datos"""
        if self.connection and self.connection.is_connected():
            self.connection.close()
            logger.info("✅ Conexión a MySQL cerrada (pacientes)")

