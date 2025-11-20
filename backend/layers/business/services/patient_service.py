"""
Patient Service
Servicio de negocio para gestión de pacientes
"""

from typing import Optional, Dict, List
from datetime import datetime
from ...data.repositories.patient_repository import PatientRepository
import logging

logger = logging.getLogger(__name__)


class PatientService:
    """Servicio de gestión de pacientes"""
    
    def __init__(self):
        self.patient_repository = PatientRepository()
    
    def _format_patient_data(self, patient: Dict) -> Dict:
        """
        Formatea los datos del paciente a camelCase para la respuesta JSON
        
        Args:
            patient: Diccionario con datos del paciente desde la BD
            
        Returns:
            Diccionario formateado en camelCase
        """
        from datetime import datetime
        
        created_at = patient.get('created_at')
        if isinstance(created_at, datetime):
            created_at_str = created_at.isoformat()
        elif hasattr(created_at, 'isoformat'):
            created_at_str = created_at.isoformat()
        else:
            created_at_str = str(created_at) if created_at else None
        
        return {
            "id": patient.get('id'),
            "fullName": patient.get('full_name'),
            "identification": patient.get('identification'),
            "age": patient.get('age'),
            "createdAt": created_at_str,
            "isActive": bool(patient.get('is_active', True))
        }
    
    def create_patient(self, full_name: str, identification: str, age: Optional[int] = None) -> Dict:
        """
        Crea un nuevo paciente
        
        Args:
            full_name: Nombre completo del paciente
            identification: Número de identificación (único)
            age: Edad del paciente (opcional)
            
        Returns:
            Diccionario con success, data y message
        """
        try:
            # Validaciones
            if not full_name or not identification:
                return {
                    "success": False,
                    "error": "Nombre completo e identificación son requeridos"
                }
            
            if len(full_name) < 2:
                return {
                    "success": False,
                    "error": "El nombre completo debe tener al menos 2 caracteres"
                }
            
            if len(identification) < 3:
                return {
                    "success": False,
                    "error": "La identificación debe tener al menos 3 caracteres"
                }
            
            # Validar edad si se proporciona
            if age is not None and (age < 0 or age > 150):
                return {
                    "success": False,
                    "error": "La edad debe estar entre 0 y 150 años"
                }
            
            # Verificar si la identificación ya existe
            if self.patient_repository.identification_exists(identification):
                return {
                    "success": False,
                    "error": f"Ya existe un paciente con la identificación {identification}"
                }
            
            # Crear el paciente
            patient = self.patient_repository.create_patient(
                full_name=full_name,
                identification=identification,
                age=age
            )
            
            if patient:
                logger.info(f"✅ Paciente creado exitosamente: {full_name}")
                
                # Formatear respuesta en camelCase como usuarios
                patient_data = self._format_patient_data(patient)
                
                return {
                    "success": True,
                    "data": patient_data,
                    "message": "Paciente creado exitosamente"
                }
            else:
                return {
                    "success": False,
                    "error": "Error al crear el paciente"
                }
                
        except Exception as e:
            logger.error(f"❌ Error creando paciente: {e}")
            return {
                "success": False,
                "error": f"Error al crear paciente: {str(e)}"
            }
    
    def get_patient_by_id(self, patient_id: int) -> Dict:
        """
        Obtiene un paciente por su ID
        
        Args:
            patient_id: ID del paciente
            
        Returns:
            Diccionario con success, data y message
        """
        try:
            patient = self.patient_repository.get_patient_by_id(patient_id)
            
            if patient:
                patient_data = self._format_patient_data(patient)
                return {
                    "success": True,
                    "data": patient_data,
                    "message": "Paciente encontrado"
                }
            else:
                return {
                    "success": False,
                    "error": "Paciente no encontrado"
                }
                
        except Exception as e:
            logger.error(f"❌ Error obteniendo paciente: {e}")
            return {
                "success": False,
                "error": f"Error al obtener paciente: {str(e)}"
            }
    
    def get_patient_by_identification(self, identification: str) -> Dict:
        """
        Obtiene un paciente por su identificación
        
        Args:
            identification: Número de identificación
            
        Returns:
            Diccionario con success, data y message
        """
        try:
            patient = self.patient_repository.get_patient_by_identification(identification)
            
            if patient:
                patient_data = self._format_patient_data(patient)
                return {
                    "success": True,
                    "data": patient_data,
                    "message": "Paciente encontrado"
                }
            else:
                return {
                    "success": False,
                    "error": "Paciente no encontrado"
                }
                
        except Exception as e:
            logger.error(f"❌ Error obteniendo paciente: {e}")
            return {
                "success": False,
                "error": f"Error al obtener paciente: {str(e)}"
            }
    
    def get_all_patients(self, active_only: bool = True, search: Optional[str] = None) -> Dict:
        """
        Obtiene todos los pacientes
        
        Args:
            active_only: Si es True, solo devuelve pacientes activos
            search: Término de búsqueda para filtrar
            
        Returns:
            Diccionario con success, data y count
        """
        try:
            patients = self.patient_repository.get_all_patients(
                active_only=active_only,
                search=search
            )
            
            # Formatear todos los pacientes a camelCase
            formatted_patients = [self._format_patient_data(p) for p in patients]
            
            return {
                "success": True,
                "data": formatted_patients,
                "count": len(formatted_patients),
                "message": f"Se encontraron {len(formatted_patients)} paciente(s)"
            }
                
        except Exception as e:
            logger.error(f"❌ Error obteniendo pacientes: {e}")
            return {
                "success": False,
                "error": f"Error al obtener pacientes: {str(e)}",
                "data": [],
                "count": 0
            }
    
    def update_patient(self, patient_id: int, **kwargs) -> Dict:
        """
        Actualiza los datos de un paciente
        
        Args:
            patient_id: ID del paciente
            **kwargs: Campos a actualizar
            
        Returns:
            Diccionario con success, data y message
        """
        try:
            # Verificar que el paciente existe
            existing_patient = self.patient_repository.get_patient_by_id(patient_id)
            if not existing_patient:
                return {
                    "success": False,
                    "error": "Paciente no encontrado"
                }
            
            # Si se está actualizando la identificación, verificar que no exista
            if 'identification' in kwargs:
                new_identification = kwargs['identification']
                if self.patient_repository.identification_exists(new_identification, exclude_id=patient_id):
                    return {
                        "success": False,
                        "error": f"Ya existe otro paciente con la identificación {new_identification}"
                    }
            
            # Actualizar el paciente
            updated_patient = self.patient_repository.update_patient(patient_id, **kwargs)
            
            if updated_patient:
                logger.info(f"✅ Paciente actualizado exitosamente: ID {patient_id}")
                patient_data = self._format_patient_data(updated_patient)
                return {
                    "success": True,
                    "data": patient_data,
                    "message": "Paciente actualizado exitosamente"
                }
            else:
                return {
                    "success": False,
                    "error": "Error al actualizar el paciente"
                }
                
        except Exception as e:
            logger.error(f"❌ Error actualizando paciente: {e}")
            return {
                "success": False,
                "error": f"Error al actualizar paciente: {str(e)}"
            }
    
    def delete_patient(self, patient_id: int) -> Dict:
        """
        Elimina (desactiva) un paciente
        
        Args:
            patient_id: ID del paciente
            
        Returns:
            Diccionario con success y message
        """
        try:
            # Verificar que el paciente existe
            existing_patient = self.patient_repository.get_patient_by_id(patient_id)
            if not existing_patient:
                return {
                    "success": False,
                    "error": "Paciente no encontrado"
                }
            
            # Eliminar el paciente (soft delete)
            success = self.patient_repository.delete_patient(patient_id)
            
            if success:
                logger.info(f"✅ Paciente eliminado exitosamente: ID {patient_id}")
                return {
                    "success": True,
                    "message": "Paciente eliminado exitosamente"
                }
            else:
                return {
                    "success": False,
                    "error": "Error al eliminar el paciente"
                }
                
        except Exception as e:
            logger.error(f"❌ Error eliminando paciente: {e}")
            return {
                "success": False,
                "error": f"Error al eliminar paciente: {str(e)}"
            }

