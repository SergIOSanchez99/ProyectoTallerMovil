"""
Study Repository
Repositorio para manejar operaciones de base de datos de estudios/reportes
"""

import mysql.connector
from mysql.connector import Error
from typing import Optional, Dict, List
import os
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class StudyRepository:
    """Repositorio para operaciones de estudios en MySQL"""
    
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
                logger.info("✅ Conexión a MySQL establecida para estudios")
        except Error as e:
            logger.error(f"❌ Error conectando a MySQL: {e}")
            self.connection = None
    
    def _ensure_connection(self):
        """Asegura que hay una conexión activa"""
        if self.connection is None or not self.connection.is_connected():
            self._get_connection()
    
    def create_study(
        self,
        result: str,
        stage: Optional[str] = None,
        confidence: Optional[float] = None,
        risk_level: Optional[str] = None,
        patient_id: Optional[int] = None,
        user_id: Optional[int] = None,
        image_path: Optional[str] = None,
        study_date: Optional[str] = None,
        doctor_name: Optional[str] = None,
        observations: Optional[str] = None
    ) -> Optional[Dict]:
        """
        Crea un nuevo estudio en la base de datos
        
        Args:
            result: Resultado del análisis
            stage: Etapa del análisis (opcional)
            confidence: Nivel de confianza (opcional)
            risk_level: Nivel de riesgo (opcional)
            patient_id: ID del paciente (opcional)
            user_id: ID del usuario (opcional)
            image_path: Ruta de la imagen (opcional)
            study_date: Fecha del estudio (opcional)
            doctor_name: Nombre del médico (opcional)
            observations: Observaciones (opcional)
            
        Returns:
            Diccionario con los datos del estudio creado o None si falla
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
            query = """
                INSERT INTO estudios (
                    result, stage, confidence, risk_level, patient_id, user_id,
                    image_path, study_date, doctor_name, observations
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            values = (
                result,
                stage,
                confidence,
                risk_level,
                patient_id,
                user_id,
                image_path,
                study_date,
                doctor_name,
                observations
            )
            
            cursor.execute(query, values)
            self.connection.commit()
            
            # Obtener el estudio recién creado
            study_id = cursor.lastrowid
            logger.info(f"✅ Estudio creado exitosamente: ID {study_id}")
            return self.get_study_by_id(study_id)
            
        except Error as e:
            logger.error(f"❌ Error creando estudio: {e}")
            if self.connection:
                self.connection.rollback()
            return None
        finally:
            if cursor:
                cursor.close()
    
    def get_study_by_id(self, study_id: int) -> Optional[Dict]:
        """
        Obtiene un estudio por su ID
        
        Args:
            study_id: ID del estudio
            
        Returns:
            Diccionario con los datos del estudio o None si no existe
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
            query = """
                SELECT 
                    e.*,
                    p.full_name as patient_name,
                    p.identification as patient_identification
                FROM estudios e
                LEFT JOIN pacientes p ON e.patient_id = p.id
                WHERE e.id = %s AND e.is_active = TRUE
            """
            cursor.execute(query, (study_id,))
            result = cursor.fetchone()
            return result
        except Error as e:
            logger.error(f"❌ Error obteniendo estudio: {e}")
            return None
        finally:
            if cursor:
                cursor.close()
    
    def get_all_studies(
        self,
        user_id: Optional[int] = None,
        patient_id: Optional[int] = None,
        limit: Optional[int] = None,
        offset: Optional[int] = None
    ) -> List[Dict]:
        """
        Obtiene todos los estudios activos
        
        Args:
            user_id: Filtrar por usuario (opcional)
            patient_id: Filtrar por paciente (opcional)
            limit: Límite de resultados (opcional)
            offset: Offset para paginación (opcional)
            
        Returns:
            Lista de diccionarios con los datos de los estudios
        """
        self._ensure_connection()
        if not self.connection:
            return []
            
        cursor = None
        try:
            cursor = self.connection.cursor(dictionary=True)
            query = """
                SELECT 
                    e.*,
                    p.full_name as patient_name,
                    p.identification as patient_identification
                FROM estudios e
                LEFT JOIN pacientes p ON e.patient_id = p.id
                WHERE e.is_active = TRUE
            """
            params = []
            
            if user_id:
                query += " AND e.user_id = %s"
                params.append(user_id)
            
            if patient_id:
                query += " AND e.patient_id = %s"
                params.append(patient_id)
            
            query += " ORDER BY e.created_at DESC"
            
            if limit:
                query += " LIMIT %s"
                params.append(limit)
                if offset:
                    query += " OFFSET %s"
                    params.append(offset)
            
            cursor.execute(query, tuple(params) if params else None)
            results = cursor.fetchall()
            return results
        except Error as e:
            logger.error(f"❌ Error obteniendo estudios: {e}")
            return []
        finally:
            if cursor:
                cursor.close()
    
    def update_study(
        self,
        study_id: int,
        result: Optional[str] = None,
        stage: Optional[str] = None,
        confidence: Optional[float] = None,
        risk_level: Optional[str] = None,
        observations: Optional[str] = None
    ) -> Optional[Dict]:
        """
        Actualiza un estudio existente
        
        Args:
            study_id: ID del estudio a actualizar
            result: Nuevo resultado (opcional)
            stage: Nueva etapa (opcional)
            confidence: Nueva confianza (opcional)
            risk_level: Nuevo nivel de riesgo (opcional)
            observations: Nuevas observaciones (opcional)
            
        Returns:
            Diccionario con los datos del estudio actualizado o None si falla
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            updates = []
            params = []
            
            if result is not None:
                updates.append("result = %s")
                params.append(result)
            if stage is not None:
                updates.append("stage = %s")
                params.append(stage)
            if confidence is not None:
                updates.append("confidence = %s")
                params.append(confidence)
            if risk_level is not None:
                updates.append("risk_level = %s")
                params.append(risk_level)
            if observations is not None:
                updates.append("observations = %s")
                params.append(observations)
            
            if not updates:
                return self.get_study_by_id(study_id)
            
            query = f"UPDATE estudios SET {', '.join(updates)} WHERE id = %s AND is_active = TRUE"
            params.append(study_id)
            
            cursor = self.connection.cursor()
            cursor.execute(query, tuple(params))
            self.connection.commit()
            
            return self.get_study_by_id(study_id)
        except Error as e:
            logger.error(f"❌ Error actualizando estudio: {e}")
            if self.connection:
                self.connection.rollback()
            return None
        finally:
            if cursor:
                cursor.close()
    
    def delete_study(self, study_id: int) -> bool:
        """
        Elimina (desactiva) un estudio
        
        Args:
            study_id: ID del estudio a eliminar
            
        Returns:
            True si se eliminó correctamente, False en caso contrario
        """
        self._ensure_connection()
        if not self.connection:
            return False
            
        cursor = None
        try:
            cursor = self.connection.cursor()
            query = "UPDATE estudios SET is_active = FALSE WHERE id = %s"
            cursor.execute(query, (study_id,))
            self.connection.commit()
            return cursor.rowcount > 0
        except Error as e:
            logger.error(f"❌ Error eliminando estudio: {e}")
            if self.connection:
                self.connection.rollback()
            return False
        finally:
            if cursor:
                cursor.close()

