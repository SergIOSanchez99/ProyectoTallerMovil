"""
Study Service
Servicio de negocio para manejar la lógica de estudios/reportes
"""

from typing import Optional, Dict, List
from ...data.repositories.study_repository import StudyRepository
import logging

logger = logging.getLogger(__name__)


class StudyService:
    """Servicio para operaciones de estudios"""
    
    def __init__(self):
        self.repository = StudyRepository()
    
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
    ) -> Dict:
        """
        Crea un nuevo estudio
        
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
            Diccionario con success, data y message
        """
        try:
            # Validar datos requeridos
            if not result or not result.strip():
                return {
                    "success": False,
                    "error": "El resultado del análisis es requerido",
                    "data": None
                }
            
            # Validar confidence si se proporciona
            if confidence is not None:
                if not (0.0 <= confidence <= 1.0):
                    return {
                        "success": False,
                        "error": "El nivel de confianza debe estar entre 0.0 y 1.0",
                        "data": None
                    }
            
            # Crear el estudio
            study = self.repository.create_study(
                result=result.strip(),
                stage=stage.strip() if stage else None,
                confidence=confidence,
                risk_level=risk_level.strip() if risk_level else None,
                patient_id=patient_id,
                user_id=user_id,
                image_path=image_path,
                study_date=study_date,
                doctor_name=doctor_name.strip() if doctor_name else None,
                observations=observations.strip() if observations else None
            )
            
            if study:
                logger.info(f"✅ Estudio creado exitosamente: ID {study.get('id')}")
                return {
                    "success": True,
                    "data": study,
                    "message": "Estudio creado exitosamente"
                }
            else:
                return {
                    "success": False,
                    "error": "Error al crear el estudio en la base de datos",
                    "data": None
                }
                
        except Exception as e:
            logger.error(f"❌ Error en create_study: {e}")
            return {
                "success": False,
                "error": f"Error interno: {str(e)}",
                "data": None
            }
    
    def get_study(self, study_id: int) -> Dict:
        """
        Obtiene un estudio por ID
        
        Args:
            study_id: ID del estudio
            
        Returns:
            Diccionario con success, data y message
        """
        try:
            study = self.repository.get_study_by_id(study_id)
            
            if study:
                return {
                    "success": True,
                    "data": study,
                    "message": "Estudio obtenido exitosamente"
                }
            else:
                return {
                    "success": False,
                    "error": "Estudio no encontrado",
                    "data": None
                }
        except Exception as e:
            logger.error(f"❌ Error en get_study: {e}")
            return {
                "success": False,
                "error": f"Error interno: {str(e)}",
                "data": None
            }
    
    def get_all_studies(
        self,
        user_id: Optional[int] = None,
        patient_id: Optional[int] = None,
        limit: Optional[int] = None,
        offset: Optional[int] = None
    ) -> Dict:
        """
        Obtiene todos los estudios
        
        Args:
            user_id: Filtrar por usuario (opcional)
            patient_id: Filtrar por paciente (opcional)
            limit: Límite de resultados (opcional)
            offset: Offset para paginación (opcional)
            
        Returns:
            Diccionario con success, data y message
        """
        try:
            studies = self.repository.get_all_studies(
                user_id=user_id,
                patient_id=patient_id,
                limit=limit,
                offset=offset
            )
            
            return {
                "success": True,
                "data": studies,
                "message": f"Se encontraron {len(studies)} estudios"
            }
        except Exception as e:
            logger.error(f"❌ Error en get_all_studies: {e}")
            return {
                "success": False,
                "error": f"Error interno: {str(e)}",
                "data": []
            }
    
    def update_study(
        self,
        study_id: int,
        result: Optional[str] = None,
        stage: Optional[str] = None,
        confidence: Optional[float] = None,
        risk_level: Optional[str] = None,
        observations: Optional[str] = None
    ) -> Dict:
        """
        Actualiza un estudio
        
        Args:
            study_id: ID del estudio a actualizar
            result: Nuevo resultado (opcional)
            stage: Nueva etapa (opcional)
            confidence: Nueva confianza (opcional)
            risk_level: Nuevo nivel de riesgo (opcional)
            observations: Nuevas observaciones (opcional)
            
        Returns:
            Diccionario con success, data y message
        """
        try:
            study = self.repository.update_study(
                study_id=study_id,
                result=result.strip() if result else None,
                stage=stage.strip() if stage else None,
                confidence=confidence,
                risk_level=risk_level.strip() if risk_level else None,
                observations=observations.strip() if observations else None
            )
            
            if study:
                return {
                    "success": True,
                    "data": study,
                    "message": "Estudio actualizado exitosamente"
                }
            else:
                return {
                    "success": False,
                    "error": "Estudio no encontrado o error al actualizar",
                    "data": None
                }
        except Exception as e:
            logger.error(f"❌ Error en update_study: {e}")
            return {
                "success": False,
                "error": f"Error interno: {str(e)}",
                "data": None
            }
    
    def delete_study(self, study_id: int) -> Dict:
        """
        Elimina un estudio
        
        Args:
            study_id: ID del estudio a eliminar
            
        Returns:
            Diccionario con success y message
        """
        try:
            success = self.repository.delete_study(study_id)
            
            if success:
                return {
                    "success": True,
                    "message": "Estudio eliminado exitosamente"
                }
            else:
                return {
                    "success": False,
                    "error": "Estudio no encontrado o error al eliminar"
                }
        except Exception as e:
            logger.error(f"❌ Error en delete_study: {e}")
            return {
                "success": False,
                "error": f"Error interno: {str(e)}"
            }

