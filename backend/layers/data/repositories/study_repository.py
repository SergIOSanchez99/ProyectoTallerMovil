"""
Study Repository
Repositorio para manejar operaciones de base de datos de estudios/reportes
"""

import pymysql
from pymysql import Error
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
                logger.info("✅ Conexión a MySQL establecida para estudios (PyMySQL)")
        except Error as e:
            logger.error(f"❌ Error conectando a MySQL: {e}")
            self.connection = None
    
    def _ensure_connection(self):
        """Asegura que hay una conexión activa"""
        if self.connection is None or not self.connection.open:
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
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor()
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
        """
        self._ensure_connection()
        if not self.connection:
            return None
            
        cursor = None
        try:
            cursor = self.connection.cursor()
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
        """
        self._ensure_connection()
        if not self.connection:
            return []
            
        cursor = None
        try:
            cursor = self.connection.cursor()
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
