"""
Presentation Layer - API Controller
Versión optimizada y robusta del endpoint /predict (mejorada)
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
import json
import base64
import io
import binascii
from datetime import datetime
import traceback
try:
    from PIL import Image
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False

from ..business.services.analysis_service import AnalysisService
from ..business.services.health_service import HealthService
from ..business.services.auth_service import AuthService
from ..business.services.patient_service import PatientService
from ..business.services.study_service import StudyService
from ..infrastructure.exceptions.api_exceptions import APIException, ValidationError


class APIController:
    """Controlador principal de la API optimizado y endurecido"""

    def __init__(self):
        self.app = Flask(__name__)
        CORS(self.app)

        # Configurar límite de tamaño de contenido (120 MB)
        self.app.config['MAX_CONTENT_LENGTH'] = 120 * 1024 * 1024  # 120 MB

        self.analysis_service = AnalysisService()
        self.health_service = HealthService()
        self.auth_service = AuthService()
        self.patient_service = PatientService()
        self.study_service = StudyService()

        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)

        self._setup_routes()
        self._setup_error_handlers()

    # ---------------------- Helpers ----------------------------------------
    def _strip_data_uri(self, s: str) -> str:
        """Remueve prefijos tipo data:<mime>;base64, si existen"""
        if not isinstance(s, str):
            return s
        s = s.strip()
        if s.startswith("data:"):
            # data:[<mediatype>][;base64],<data>
            try:
                _, b64 = s.split(",", 1)
                return b64.strip()
            except Exception:
                return s
        return s

    def _max_base64_length_chars(self) -> int:
        """
        Devuelve la longitud máxima aceptable para la cadena base64 (en caracteres),
        calculada a partir de MAX_CONTENT_LENGTH para prevenir decodificación de
        strings excesivamente grandes.
        base64 -> bytes: bytes ≈ 3/4 * len(base64)
        por lo que len(base64) ≈ bytes * 4/3
        añadimos un pequeño margen ( + 1024 chars )
        """
        max_bytes = int(self.app.config.get('MAX_CONTENT_LENGTH', 120 * 1024 * 1024))
        return int(max_bytes * 4 / 3) + 1024

    def _error_response(self, msg, code=400):
        return jsonify({"success": False, "error": msg}), code

    # ---------------------------------------------------------------------
    # ROUTES
    # ---------------------------------------------------------------------
    def _setup_routes(self):

        @self.app.route('/health', methods=['GET'])
        def health_check():
            """Endpoint de salud"""
            try:
                result = self.health_service.check_system_health()
                return jsonify({
                    "status": "OK",
                    "message": "Sistema funcionando correctamente",
                    "timestamp": datetime.now().isoformat(),
                    **result
                }), 200
            except Exception as e:
                self.logger.exception("Error en health check")
                return jsonify({
                    "status": "ERROR",
                    "message": "Error interno del servidor"
                }), 500

        # ---------------------------------------------------------------------
        # ENDPOINTS DE AUTENTICACIÓN
        # ---------------------------------------------------------------------
        @self.app.route('/auth/register', methods=['POST', 'OPTIONS'])
        def register():
            """Endpoint para registrar nuevos usuarios"""
            
            if request.method == 'OPTIONS':
                # Responder a preflight CORS
                response = jsonify({})
                response.headers.add('Access-Control-Allow-Origin', '*')
                response.headers.add('Access-Control-Allow-Headers', 'Content-Type')
                response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
                return response, 200
            
            self.logger.info("=== POST /auth/register ===")
            self.logger.info(f"Método: {request.method}")
            self.logger.info(f"Headers: {dict(request.headers)}")
            
            try:
                # Ignorar Content-Type completamente y leer el body directamente
                # Esto evita problemas con Content-Type duplicado
                data = None
                
                # Método 1: Leer el body como texto (más confiable)
                try:
                    raw_data = request.get_data(as_text=True)
                    self.logger.info(f"Body raw recibido (longitud: {len(raw_data) if raw_data else 0})")
                    if raw_data and raw_data.strip():
                        # Intentar parsear como JSON
                        data = json.loads(raw_data)
                        self.logger.info("✅ JSON parseado desde body raw")
                except (json.JSONDecodeError, ValueError) as e:
                    self.logger.warning(f"Error parseando JSON desde body raw: {e}")
                    # Si falla, intentar con get_data como bytes
                    try:
                        raw_bytes = request.get_data()
                        if raw_bytes:
                            data = json.loads(raw_bytes.decode('utf-8'))
                            self.logger.info("✅ JSON parseado desde bytes")
                    except Exception as e2:
                        self.logger.warning(f"Error parseando desde bytes: {e2}")
                
                # Método 2: Si no funcionó, intentar con get_json (ignorando Content-Type)
                if not data:
                    try:
                        # Forzar lectura de JSON ignorando Content-Type
                        data = request.get_json(force=True, silent=True)
                        if data:
                            self.logger.info("✅ JSON obtenido con get_json(force=True)")
                    except Exception as e:
                        self.logger.warning(f"get_json falló: {e}")
                
                if not data:
                    self.logger.error("El cuerpo de la petición está vacío o no es JSON válido")
                    return self._error_response("El cuerpo de la petición está vacío o no es JSON válido")
                
                self.logger.info(f"Datos recibidos: email={data.get('email')}, name={data.get('name')}, password={'***' if data.get('password') else 'vacío'}")
                
                email = data.get('email', '').strip()
                password = data.get('password', '').strip()
                name = data.get('name', '').strip()
                profile_image = data.get('profile_image', '').strip() or None
                
                if not email or not password or not name:
                    error_msg = "Email, contraseña y nombre son requeridos"
                    self.logger.warning(f"Validación fallida: {error_msg}")
                    return self._error_response(error_msg)
                
                # Registrar usuario
                self.logger.info(f"Intentando registrar usuario: {email}")
                result = self.auth_service.register(email, password, name, profile_image)
                
                self.logger.info(f"Resultado del servicio: success={result.get('success')}, error={result.get('error', 'N/A')}")
                
                if result.get('success'):
                    self.logger.info(f" Usuario registrado exitosamente: {email} (ID: {result.get('data', {}).get('id', 'N/A')})")
                    # Asegurar que la respuesta sea JSON válido
                    try:
                        # jsonify() ya establece Content-Type automáticamente, no duplicar
                        response = jsonify(result)
                        # Usar headers.set() en lugar de add() para evitar duplicados
                        response.headers['Access-Control-Allow-Origin'] = '*'
                        response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS, GET'
                        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                        self.logger.info(f"Respuesta JSON generada: {json.dumps(result, default=str)}")
                        return response, 201
                    except Exception as json_error:
                        self.logger.error(f"Error serializando JSON: {json_error}")
                        # Fallback: convertir manualmente
                        result_str = json.dumps(result, default=str)
                        response = self.app.response_class(
                            response=result_str,
                            status=201,
                            mimetype='application/json'
                        )
                        response.headers['Access-Control-Allow-Origin'] = '*'
                        response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS, GET'
                        response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                        return response
                else:
                    error_msg = result.get('error', 'Error desconocido')
                    self.logger.warning(f"❌ Registro fallido: {error_msg}")
                    response = jsonify(result)
                    # Usar headers.set() en lugar de add() para evitar duplicados
                    response.headers['Access-Control-Allow-Origin'] = '*'
                    response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS, GET'
                    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                    return response, 400
                    
            except Exception as e:
                self.logger.exception("Error en registro de usuario")
                return self._error_response(f"Error al registrar usuario: {str(e)}", 500)
        
        @self.app.route('/auth/login', methods=['POST', 'OPTIONS'])
        def login():
            """Endpoint para autenticar usuarios"""
            
            if request.method == 'OPTIONS':
                # Responder a preflight CORS
                response = jsonify({})
                response.headers.add('Access-Control-Allow-Origin', '*')
                response.headers.add('Access-Control-Allow-Headers', 'Content-Type')
                response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
                return response, 200
            
            self.logger.info("=== POST /auth/login ===")
            
            try:
                # Ignorar Content-Type y leer el body directamente
                data = None
                
                # Método 1: Leer el body como texto
                try:
                    raw_data = request.get_data(as_text=True)
                    if raw_data and raw_data.strip():
                        data = json.loads(raw_data)
                        self.logger.info("✅ JSON parseado desde body raw (login)")
                except (json.JSONDecodeError, ValueError) as e:
                    self.logger.warning(f"Error parseando JSON desde body: {e}")
                    # Intentar con bytes
                    try:
                        raw_bytes = request.get_data()
                        if raw_bytes:
                            data = json.loads(raw_bytes.decode('utf-8'))
                            self.logger.info("✅ JSON parseado desde bytes (login)")
                    except Exception as e2:
                        self.logger.warning(f"Error parseando desde bytes: {e2}")
                
                # Método 2: Si no funcionó, intentar con get_json
                if not data:
                    try:
                        data = request.get_json(force=True, silent=True)
                        if data:
                            self.logger.info("✅ JSON obtenido con get_json (login)")
                    except Exception as e:
                        self.logger.warning(f"get_json falló: {e}")
                
                if not data:
                    self.logger.error("El cuerpo de la petición está vacío (login)")
                    return self._error_response("El cuerpo de la petición está vacío")
                
                email = data.get('email', '').strip()
                password = data.get('password', '').strip()
                
                if not email or not password:
                    return self._error_response("Email y contraseña son requeridos")
                
                # Autenticar usuario
                result = self.auth_service.login(email, password)
                
                if result.get('success'):
                    return jsonify(result), 200
                else:
                    return jsonify(result), 401
                    
            except Exception as e:
                self.logger.exception("Error en login de usuario")
                return self._error_response(f"Error al autenticar usuario: {str(e)}", 500)
        
        # ---------------------------------------------------------------------
        # ENDPOINT /auth/users (Listar usuarios)
        # ---------------------------------------------------------------------
        @self.app.route('/auth/users', methods=['GET', 'OPTIONS'])
        def get_users():
            """Endpoint para obtener todos los usuarios registrados"""
            
            if request.method == 'OPTIONS':
                # Responder a preflight CORS
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                return response, 200
            
            self.logger.info("=== GET /auth/users ===")
            
            try:
                # Obtener parámetro opcional active_only
                active_only = request.args.get('active_only', 'false').lower() == 'true'
                
                self.logger.info(f"Obteniendo usuarios (active_only={active_only})")
                
                # Obtener usuarios del servicio
                result = self.auth_service.get_all_users(active_only=active_only)
                
                if result.get('success'):
                    self.logger.info(f"✅ Usuarios obtenidos exitosamente: {result.get('count', 0)} usuario(s)")
                    response = jsonify(result)
                    response.headers['Access-Control-Allow-Origin'] = '*'
                    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                    return response, 200
                else:
                    error_msg = result.get('error', 'Error desconocido')
                    self.logger.warning(f"❌ Error obteniendo usuarios: {error_msg}")
                    response = jsonify(result)
                    response.headers['Access-Control-Allow-Origin'] = '*'
                    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                    return response, 500
                    
            except Exception as e:
                self.logger.exception("Error obteniendo usuarios")
                return self._error_response(f"Error al obtener usuarios: {str(e)}", 500)
        
        # ---------------------------------------------------------------------
        # ENDPOINTS DE PACIENTES
        # ---------------------------------------------------------------------
        
        @self.app.route('/patients', methods=['GET', 'OPTIONS'])
        def get_patients():
            """Endpoint para obtener todos los pacientes"""
            
            if request.method == 'OPTIONS':
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                return response, 200
            
            self.logger.info("=== GET /patients ===")
            
            try:
                active_only = request.args.get('active_only', 'true').lower() == 'true'
                search = request.args.get('search', None)
                
                result = self.patient_service.get_all_patients(
                    active_only=active_only,
                    search=search
                )
                
                if result.get('success'):
                    response = jsonify(result)
                    response.headers['Access-Control-Allow-Origin'] = '*'
                    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                    return response, 200
                else:
                    response = jsonify(result)
                    response.headers['Access-Control-Allow-Origin'] = '*'
                    return response, 500
                    
            except Exception as e:
                self.logger.exception("Error obteniendo pacientes")
                return self._error_response(f"Error al obtener pacientes: {str(e)}", 500)
        
        @self.app.route('/patients/<int:patient_id>', methods=['GET', 'OPTIONS'])
        def get_patient(patient_id):
            """Endpoint para obtener un paciente por ID"""
            
            if request.method == 'OPTIONS':
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                return response, 200
            
            self.logger.info(f"=== GET /patients/{patient_id} ===")
            
            try:
                result = self.patient_service.get_patient_by_id(patient_id)
                
                response = jsonify(result)
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                
                status_code = 200 if result.get('success') else 404
                return response, status_code
                
            except Exception as e:
                self.logger.exception("Error obteniendo paciente")
                return self._error_response(f"Error al obtener paciente: {str(e)}", 500)
        
        @self.app.route('/patients', methods=['POST', 'OPTIONS'])
        def create_patient():
            """Endpoint para crear un nuevo paciente"""
            
            if request.method == 'OPTIONS':
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
                return response, 200
            
            self.logger.info("=== POST /patients ===")
            
            try:
                data = request.get_json()
                
                if not data:
                    return self._error_response("Datos no proporcionados", 400)
                
                # Obtener edad y convertir a int si existe
                age = None
                if 'age' in data and data['age'] is not None:
                    try:
                        age = int(data['age'])
                    except (ValueError, TypeError):
                        age = None
                elif 'edad' in data and data['edad'] is not None:
                    try:
                        age = int(data['edad'])
                    except (ValueError, TypeError):
                        age = None
                
                result = self.patient_service.create_patient(
                    full_name=data.get('full_name') or data.get('nombre_completo') or data.get('fullName'),
                    identification=data.get('identification') or data.get('identificacion'),
                    age=age
                )
                
                response = jsonify(result)
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                
                status_code = 201 if result.get('success') else 400
                return response, status_code
                
            except Exception as e:
                self.logger.exception("Error creando paciente")
                return self._error_response(f"Error al crear paciente: {str(e)}", 500)
        
        @self.app.route('/patients/<int:patient_id>', methods=['PUT', 'OPTIONS'])
        def update_patient(patient_id):
            """Endpoint para actualizar un paciente"""
            
            if request.method == 'OPTIONS':
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'PUT, OPTIONS'
                return response, 200
            
            self.logger.info(f"=== PUT /patients/{patient_id} ===")
            
            try:
                data = request.get_json()
                
                if not data:
                    return self._error_response("Datos no proporcionados", 400)
                
                result = self.patient_service.update_patient(patient_id, **data)
                
                response = jsonify(result)
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Methods'] = 'PUT, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                
                status_code = 200 if result.get('success') else 400
                return response, status_code
                
            except Exception as e:
                self.logger.exception("Error actualizando paciente")
                return self._error_response(f"Error al actualizar paciente: {str(e)}", 500)
        
        @self.app.route('/patients/<int:patient_id>', methods=['DELETE', 'OPTIONS'])
        def delete_patient(patient_id):
            """Endpoint para eliminar un paciente"""
            
            if request.method == 'OPTIONS':
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'DELETE, OPTIONS'
                return response, 200
            
            self.logger.info(f"=== DELETE /patients/{patient_id} ===")
            
            try:
                result = self.patient_service.delete_patient(patient_id)
                
                response = jsonify(result)
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Methods'] = 'DELETE, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                
                status_code = 200 if result.get('success') else 404
                return response, status_code
                
            except Exception as e:
                self.logger.exception("Error eliminando paciente")
                return self._error_response(f"Error al eliminar paciente: {str(e)}", 500)
        
        @self.app.route('/patients/search', methods=['GET', 'OPTIONS'])
        def search_patient():
            """Endpoint para buscar paciente por identificación"""
            
            if request.method == 'OPTIONS':
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                return response, 200
            
            self.logger.info("=== GET /patients/search ===")
            
            try:
                identification = request.args.get('identification') or request.args.get('identificacion')
                
                if not identification:
                    return self._error_response("Parámetro 'identification' requerido", 400)
                
                result = self.patient_service.get_patient_by_identification(identification)
                
                response = jsonify(result)
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                
                status_code = 200 if result.get('success') else 404
                return response, status_code
                
            except Exception as e:
                self.logger.exception("Error buscando paciente")
                return self._error_response(f"Error al buscar paciente: {str(e)}", 500)
        
        # ---------------------------------------------------------------------
        # ENDPOINTS DE ESTUDIOS/REPORTES
        # ---------------------------------------------------------------------
        @self.app.route('/studies', methods=['POST', 'OPTIONS'])
        def create_study():
            """Endpoint para crear un nuevo estudio/reporte"""
            
            if request.method == 'OPTIONS':
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
                return response, 200
            
            self.logger.info("=== POST /studies ===")
            
            try:
                data = request.get_json()
                
                if not data:
                    return self._error_response("Datos no proporcionados", 400)
                
                # Obtener confidence y convertir a float si existe
                confidence = None
                if 'confidence' in data and data['confidence'] is not None:
                    try:
                        confidence = float(data['confidence'])
                    except (ValueError, TypeError):
                        confidence = None
                
                # Obtener patient_id y user_id si existen
                patient_id = data.get('patient_id') or data.get('patientId')
                user_id = data.get('user_id') or data.get('userId')
                
                if patient_id:
                    try:
                        patient_id = int(patient_id)
                    except (ValueError, TypeError):
                        patient_id = None
                
                if user_id:
                    try:
                        user_id = int(user_id)
                    except (ValueError, TypeError):
                        user_id = None
                
                result = self.study_service.create_study(
                    result=data.get('result', ''),
                    stage=data.get('stage'),
                    confidence=confidence,
                    risk_level=data.get('risk_level') or data.get('riskLevel'),
                    patient_id=patient_id,
                    user_id=user_id,
                    image_path=data.get('image_path') or data.get('imagePath'),
                    study_date=data.get('study_date') or data.get('studyDate'),
                    doctor_name=data.get('doctor_name') or data.get('doctorName'),
                    observations=data.get('observations')
                )
                
                response = jsonify(result)
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                
                status_code = 201 if result.get('success') else 400
                return response, status_code
                
            except Exception as e:
                self.logger.exception("Error creando estudio")
                return self._error_response(f"Error al crear estudio: {str(e)}", 500)
        
        @self.app.route('/studies', methods=['GET', 'OPTIONS'])
        def get_all_studies():
            """Endpoint para obtener todos los estudios"""
            
            if request.method == 'OPTIONS':
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                return response, 200
            
            self.logger.info("=== GET /studies ===")
            
            try:
                user_id = request.args.get('user_id') or request.args.get('userId')
                patient_id = request.args.get('patient_id') or request.args.get('patientId')
                limit = request.args.get('limit')
                offset = request.args.get('offset')
                
                if user_id:
                    try:
                        user_id = int(user_id)
                    except (ValueError, TypeError):
                        user_id = None
                
                if patient_id:
                    try:
                        patient_id = int(patient_id)
                    except (ValueError, TypeError):
                        patient_id = None
                
                if limit:
                    try:
                        limit = int(limit)
                    except (ValueError, TypeError):
                        limit = None
                
                if offset:
                    try:
                        offset = int(offset)
                    except (ValueError, TypeError):
                        offset = None
                
                result = self.study_service.get_all_studies(
                    user_id=user_id,
                    patient_id=patient_id,
                    limit=limit,
                    offset=offset
                )
                
                response = jsonify(result)
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                
                return response, 200
                
            except Exception as e:
                self.logger.exception("Error obteniendo estudios")
                return self._error_response(f"Error al obtener estudios: {str(e)}", 500)
        
        @self.app.route('/studies/<int:study_id>', methods=['GET', 'OPTIONS'])
        def get_study(study_id):
            """Endpoint para obtener un estudio por ID"""
            
            if request.method == 'OPTIONS':
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                return response, 200
            
            self.logger.info(f"=== GET /studies/{study_id} ===")
            
            try:
                result = self.study_service.get_study(study_id)
                
                response = jsonify(result)
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                
                status_code = 200 if result.get('success') else 404
                return response, status_code
                
            except Exception as e:
                self.logger.exception("Error obteniendo estudio")
                return self._error_response(f"Error al obtener estudio: {str(e)}", 500)
        
        @self.app.route('/studies/<int:study_id>', methods=['DELETE', 'OPTIONS'])
        def delete_study(study_id):
            """Endpoint para eliminar un estudio"""
            
            if request.method == 'OPTIONS':
                response = jsonify({})
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                response.headers['Access-Control-Allow-Methods'] = 'DELETE, OPTIONS'
                return response, 200
            
            self.logger.info(f"=== DELETE /studies/{study_id} ===")
            
            try:
                result = self.study_service.delete_study(study_id)
                
                response = jsonify(result)
                response.headers['Access-Control-Allow-Origin'] = '*'
                response.headers['Access-Control-Allow-Methods'] = 'DELETE, OPTIONS'
                response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Accept'
                
                status_code = 200 if result.get('success') else 404
                return response, status_code
                
            except Exception as e:
                self.logger.exception("Error eliminando estudio")
                return self._error_response(f"Error al eliminar estudio: {str(e)}", 500)
        
        # ---------------------------------------------------------------------
        # ENDPOINT /predict (Optimizado)
        # ---------------------------------------------------------------------
        @self.app.route('/predict', methods=['POST', 'OPTIONS'])
        def predict():
            """Endpoint para análisis de imágenes (JSON base64 optimizado)"""

            if request.method == 'OPTIONS':
                return '', 200

            self.logger.info("=== POST /predict ===")

            # Diagnosticar headers recibidos (solo para logging)
            content_type = request.headers.get('Content-Type', '')
            content_length = request.headers.get('Content-Length', '0')
            all_headers = dict(request.headers)

            self.logger.info(f"Content-Type recibido: '{content_type}'")
            self.logger.info(f"Content-Length: {content_length}")
            self.logger.info(f"Headers recibidos: {list(all_headers.keys())}")

            # Intentar parsear Content-Length como int
            try:
                content_length_int = int(content_length) if content_length and content_length.isdigit() else 0
            except (ValueError, AttributeError):
                content_length_int = 0

            # -----------------------------------------------------------------
            # 1. Leer body CRUDO usando múltiples métodos para diagnóstico
            # -----------------------------------------------------------------
            raw_data = None
            data = None
            
            # Método 1: Intentar con request.get_data (recomendado)
            try:
                raw_data = request.get_data(as_text=True)
                self.logger.info(f"Método 1 (get_data): {len(raw_data) if raw_data else 0} caracteres")
            except Exception as e:
                self.logger.warning(f"Método 1 (get_data) falló: {e}")
            
            # Método 2: Si el primer método falla o está vacío, intentar con request.stream
            if not raw_data or len(raw_data) == 0:
                try:
                    # Intentar leer desde el stream directamente
                    if hasattr(request, 'stream'):
                        stream_data = request.stream.read()
                        if stream_data:
                            raw_data = stream_data.decode('utf-8', errors='ignore')
                            self.logger.info(f"Método 2 (stream): {len(raw_data)} caracteres")
                except Exception as e:
                    self.logger.warning(f"Método 2 (stream) falló: {e}")
            
            # Método 3: Intentar con request.get_json (puede funcionar si Content-Type está bien)
            if not raw_data or len(raw_data) == 0:
                try:
                    data = request.get_json(force=True, silent=True)
                    if data:
                        self.logger.info("Método 3 (get_json): JSON parseado exitosamente")
                except Exception as e:
                    self.logger.warning(f"Método 3 (get_json) falló: {e}")
            
            # Método 4: Intentar leer desde request.environ directamente
            if not raw_data or len(raw_data) == 0:
                try:
                    if 'wsgi.input' in request.environ:
                        wsgi_input = request.environ['wsgi.input']
                        # Guardar posición actual
                        pos = getattr(wsgi_input, 'tell', lambda: 0)()
                        # Intentar leer todo
                        wsgi_input.seek(0) if hasattr(wsgi_input, 'seek') else None
                        env_data = wsgi_input.read()
                        wsgi_input.seek(pos) if hasattr(wsgi_input, 'seek') else None
                        if env_data:
                            raw_data = env_data.decode('utf-8', errors='ignore')
                            self.logger.info(f"Método 4 (wsgi.input): {len(raw_data)} caracteres")
                except Exception as e:
                    self.logger.warning(f"Método 4 (wsgi.input) falló: {e}")

            raw_len = len(raw_data) if raw_data else 0
            self.logger.info(f"Body raw final (longitud: {raw_len} caracteres)")
            
            # Log detallado del body si es pequeño (para diagnóstico)
            if raw_data and raw_len > 0 and raw_len < 500:
                self.logger.info(f"Body preview completo: {repr(raw_data)}")
            elif raw_data and raw_len > 0:
                preview = raw_data[:200] if len(raw_data) > 200 else raw_data
                self.logger.info(f"Body preview (primeros 200 chars): {repr(preview)}")
                self.logger.info(f"Body preview (últimos 100 chars): {repr(raw_data[-100:])}")

            # Si Content-Length > 0 pero raw_data está vacío, hay un problema serio
            if content_length_int > 0 and raw_len == 0:
                self.logger.error(
                    f"⚠️ Content-Length dice {content_length_int} pero el body está vacío después de TODOS los métodos"
                )
                self.logger.error(f"Headers completos: {dict(request.headers)}")
                self.logger.error(f"Request method: {request.method}")
                self.logger.error(f"Request path: {request.path}")
                return self._error_response(
                    "El Content-Length indica que hay datos pero el body está vacío.\n\n"
                    "Posibles causas:\n"
                    "1. Proxy/firewall que corta la petición\n"
                    "2. El servidor ya leyó el body antes (problema de stream consumido)\n"
                    "3. Postman no está enviando el body correctamente\n\n"
                    "💡 VERIFICA EN POSTMAN:\n"
                    "- Body → raw → JSON\n"
                    "- Que hayas escrito el JSON en el área de texto\n"
                    "- Que no esté vacío\n"
                    "- Que hayas hecho clic en 'Send' después de escribir el JSON"
                )

            # Si aún no tenemos data ni raw_data, rechazar
            if not raw_data or raw_len == 0 or len(raw_data.strip()) == 0:
                if data is None:
                    error_msg = "El cuerpo de la petición está VACÍO.\n\n" \
                        "📌 PASOS EXACTOS EN POSTMAN:\n\n" \
                        "1. Ve a la pestaña 'Body' (debajo de la URL)\n" \
                        "2. Selecciona el botón de radio 'raw' (NO 'none', NO 'form-data')\n" \
                        "3. En el dropdown de la derecha (que probablemente dice 'Text'),\n" \
                        "   cámbialo a 'JSON'\n" \
                        "4. En el área de texto grande, pega este JSON:\n\n" \
                        "{\n" \
                        '    "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="\n' \
                        "}\n\n" \
                        "5. Verifica que aparezca el JSON en el área de texto\n" \
                        "6. Haz clic en 'Send'\n\n" \
                        "⚠️ IMPORTANTE: Debe haber contenido en el área de texto del Body antes de enviar"
                    self.logger.error(error_msg)
                    self.logger.error(f"Content-Length recibido: {content_length}")
                    self.logger.error(f"Content-Type recibido: {content_type}")
                    return self._error_response(error_msg)

            # Si tenemos raw_data pero no data, intentar parsear JSON
            if not data and raw_data:
                try:
                    cleaned_data = raw_data.strip()
                    if cleaned_data:
                        data = json.loads(cleaned_data)
                        self.logger.info("✅ JSON parseado exitosamente desde raw_data")
                except json.JSONDecodeError as json_err:
                    self.logger.error("Error parseando JSON", exc_info=False)
                    self.logger.error(f"JSONDecodeError: {json_err}")
                    self.logger.error(f"Body recibida (preview): {repr(raw_data[:300])}")
                    return self._error_response(
                        "El cuerpo no es JSON válido.\n"
                        f"Error: {str(json_err)}\n\n"
                        "📌 Verifica en Postman:\n"
                        "- Body → raw → JSON\n"
                        "- Que el JSON esté bien formado\n"
                        "- Que todas las comillas sean dobles (\"), no simples (')\n"
                        "- Que no haya errores de sintaxis\n\n"
                        "📝 Ejemplo de JSON válido:\n"
                        '{\n    "image": "iVBORw0KGgoAAAANSUh..."\n}'
                    )
                except Exception as e:
                    self.logger.exception("Error inesperado parseando JSON")
                    return self._error_response(f"Error procesando el JSON: {str(e)}")

            if data is None:
                return self._error_response(
                    "No se pudo parsear el JSON. Asegúrate de enviar JSON válido con el campo 'image'."
                )

            # -----------------------------------------------------------------
            # 2. Validar campo 'image'
            # -----------------------------------------------------------------
            image_b64 = data.get("image")
            if image_b64 is None:
                return self._error_response(
                    "El campo 'image' es requerido.\n\nEjemplo: { \"image\": \"BASE64\" }"
                )

            if not isinstance(image_b64, str) or len(image_b64.strip()) == 0:
                return self._error_response("El campo 'image' no puede estar vacío.")

            # Quitar prefijo data URI si existe y limpiar
            image_b64 = self._strip_data_uri(image_b64)
            # Remover saltos de línea o espacios accidentales
            image_b64 = "".join(image_b64.split())

            # Validar longitud máxima para evitar decodificaciones gigantes
            max_b64_len = self._max_base64_length_chars()
            if len(image_b64) > max_b64_len:
                self.logger.warning(f"Base64 demasiado grande: {len(image_b64)} chars (máx {max_b64_len})")
                return self._error_response(
                    f"La imagen en base64 es demasiado grande ({len(image_b64)} chars). "
                    f"Máximo permitido aproximado: {max_b64_len} chars."
                )

            # -----------------------------------------------------------------
            # 3. Decodificar Base64 (manejo explícito de errores)
            # -----------------------------------------------------------------
            try:
                img_bytes = base64.b64decode(image_b64, validate=True)
                if not img_bytes:
                    return self._error_response("La imagen en Base64 está vacía después de decodificar.")
            except (binascii.Error, ValueError) as e:
                self.logger.error("Error decodificando Base64", exc_info=False)
                return self._error_response(
                    "La imagen en Base64 es inválida o está corrupta. "
                    "Asegúrate de enviar una cadena base64 válida (sin saltos de línea ni texto extra)."
                )
            except Exception as e:
                self.logger.exception("Error inesperado decodificando Base64")
                return self._error_response(f"Error decodificando Base64: {str(e)}", 400)

            # -----------------------------------------------------------------
            # 4. Validar que sea una imagen válida (usando PIL si está disponible)
            # -----------------------------------------------------------------
            if PIL_AVAILABLE:
                try:
                    img = Image.open(io.BytesIO(img_bytes))
                    img.verify()
                    # re-open para uso posterior si se necesita
                    img = Image.open(io.BytesIO(img_bytes))
                    self.logger.info(f"Imagen válida: {img.format}, {img.size}, {img.mode}")
                except Exception as e:
                    self.logger.error("Error validando imagen con PIL", exc_info=False)
                    return self._error_response(
                        "El Base64 no corresponde a una imagen válida (PNG/JPEG/GIF/etc.). "
                        f"Detalle: {str(e)}"
                    )

            # -----------------------------------------------------------------
            # 5. Procesar análisis con IA
            # -----------------------------------------------------------------
            self.logger.info("Procesando análisis con IA...")
            try:
                result = self.analysis_service.analyze_image(image_b64)
                self.logger.info("✅ Análisis completado exitosamente")
            except APIException as e:
                self.logger.exception("APIException durante análisis IA")
                return jsonify({"success": False, "error": str(e)}), getattr(e, "status_code", 500)
            except Exception as e:
                self.logger.exception("Error en análisis IA")
                return self._error_response(f"Error procesando la imagen: {str(e)}", 500)

            # -----------------------------------------------------------------
            # 6. Respuesta final - Incluir todos los campos del servicio
            # -----------------------------------------------------------------
            response_data = {
                "success": True,
                "result": result.get("result", "Análisis completado"),
                "confidence": result.get("confidence", 0.0),
                "risk_level": result.get("risk_level", "Desconocido"),
                "recommendation": result.get("recommendation", "Consulte con un especialista")
            }
            
            # Incluir campos adicionales si existen
            if "stage" in result:
                response_data["stage"] = result.get("stage", "")
            if "confidence_score" in result:
                response_data["confidence_score"] = result.get("confidence_score", 0.0)
            if "analysis_id" in result:
                response_data["analysis_id"] = result.get("analysis_id", "")
            if "processing_time" in result:
                response_data["processing_time"] = result.get("processing_time", "")
            
            self.logger.info(f"✅ Respuesta generada con {len(response_data)} campos: {list(response_data.keys())}")
            return jsonify(response_data), 200

        # ---------------------------------------------------------------------
        # ENDPOINT /predict/upload (simplificado y optimizado)
        # ---------------------------------------------------------------------
        @self.app.route('/predict/upload', methods=['POST', 'OPTIONS'])
        def predict_upload():
            """Recibe archivo en multipart/form-data y analiza"""

            if request.method == 'OPTIONS':
                return '', 200

            self.logger.info("=== POST /predict/upload ===")

            # Validar que haya archivos
            if 'image' not in request.files:
                return self._error_response(
                    "No se encontró la key 'image'.\n\n"
                    "En Postman: Body → form-data → Key: image (Tipo: File)"
                )

            file = request.files['image']

            if not file.filename:
                return self._error_response("El archivo enviado está vacío o no tiene nombre.")

            # Validar extensión
            allowed = {'png', 'jpg', 'jpeg', 'bmp', 'gif'}
            ext = file.filename.rsplit('.', 1)[-1].lower() if '.' in file.filename else ''
            if ext not in allowed:
                return self._error_response(f"Extensión no permitida '{ext}'. Solo: {', '.join(allowed)}")

            # Leer bytes
            img_bytes = file.read()
            if not img_bytes:
                return self._error_response("El archivo está vacío.")

            # Convertir a base64
            img_b64 = base64.b64encode(img_bytes).decode("utf-8")

            # Ejecutar análisis
            try:
                result = self.analysis_service.analyze_image(img_b64)
            except Exception as e:
                self.logger.exception("Error en análisis IA (upload)")
                return self._error_response(f"Error procesando la imagen: {str(e)}", 500)

            # Construir respuesta con todos los campos
            response_data = {
                "success": True,
                "result": result.get("result", "Análisis completado"),
                "confidence": result.get("confidence", 0.0),
                "risk_level": result.get("risk_level", "Desconocido"),
                "recommendation": result.get("recommendation", "Consulte con un especialista")
            }
            
            # Incluir campos adicionales si existen
            if "stage" in result:
                response_data["stage"] = result.get("stage", "")
            if "confidence_score" in result:
                response_data["confidence_score"] = result.get("confidence_score", 0.0)
            if "analysis_id" in result:
                response_data["analysis_id"] = result.get("analysis_id", "")
            if "processing_time" in result:
                response_data["processing_time"] = result.get("processing_time", "")
            
            self.logger.info(f"✅ Respuesta generada (upload) con {len(response_data)} campos: {list(response_data.keys())}")
            return jsonify(response_data), 200

    # -------------------------------------------------------------------------
    # ERROR HANDLERS
    # -------------------------------------------------------------------------
    def _setup_error_handlers(self):

        @self.app.errorhandler(ValidationError)
        def handle_validation_error(err):
            return jsonify({"success": False, "error": str(err)}), 400

        @self.app.errorhandler(APIException)
        def handle_api_error(err):
            return jsonify({"success": False, "error": str(err)}), getattr(err, "status_code", 500)

        @self.app.errorhandler(400)
        def bad_request(e):
            return jsonify({"success": False, "error": "Petición mal formada"}), 400

        @self.app.errorhandler(404)
        def not_found(e):
            return jsonify({"success": False, "error": "Endpoint no encontrado"}), 404

        @self.app.errorhandler(405)
        def method_not_allowed(e):
            return jsonify({"success": False, "error": "Método no permitido"}), 405

        @self.app.errorhandler(Exception)
        def internal_error(err):
            logging.error(f"Error inesperado: {err}")
            logging.error(traceback.format_exc())
            return jsonify({"success": False, "error": "Error interno del servidor"}), 500

    # -------------------------------------------------------------------------
    # RUN SERVER
    # -------------------------------------------------------------------------
    def run(self, host='0.0.0.0', port=5000, debug=False):
        self.logger.info(f"🚀 API iniciada en http://{host}:{port}")
        self.app.run(host=host, port=port, debug=debug)
