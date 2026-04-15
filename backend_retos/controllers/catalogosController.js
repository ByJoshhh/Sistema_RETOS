// controllers/catalogosController.js
const dbPool = require('../config/database');

// --- GET: Obtener todos los catálogos para los Dropdowns (Listas desplegables) ---
const obtenerCatalogos = async (req, res) => {
    // Seguridad SaaS: Extraemos del token
    const id_empresa = req.usuarioSeguro.id_empresa;

    try {
        const [bancos] = await dbPool.query('SELECT id_banco, nombre_banco FROM cat_bancos WHERE estatus_activo = 1 AND id_empresa = ?', [id_empresa]);
        const [materiales] = await dbPool.query('SELECT id_material, nombre_material FROM cat_materiales WHERE estatus_activo = 1 AND id_empresa = ?', [id_empresa]);
        const [destinos] = await dbPool.query('SELECT id_destino, nombre_destino FROM cat_destinos WHERE estatus_activo = 1 AND id_empresa = ?', [id_empresa]);
        const [unidades] = await dbPool.query('SELECT id_unidad, placas_o_num FROM cat_unidades WHERE estatus_activo = 1 AND id_empresa = ?', [id_empresa]);
        const [residentes] = await dbPool.query("SELECT id_usuario as id_residente, nombre_completo FROM cat_usuarios WHERE rol = 'Residente' AND estatus_activo = 1 AND id_empresa = ?", [id_empresa]);
        const [sindicatos] = await dbPool.query('SELECT id_sindicato, nombre_sindicato FROM cat_sindicatos WHERE estatus_activo = 1 AND id_empresa = ?', [id_empresa]);

        res.json({
            exito: true,
            datos: { bancos, materiales, destinos, unidades, residentes, sindicatos }
        });
    } catch (error) {
        console.error('Error al obtener catálogos:', error);
        res.status(500).json({ exito: false, mensaje: 'Error al cargar las listas' });
    }
};

// --- GET: Obtener datos solo para la tabla web de unidades ---
const obtenerUnidades = async (req, res) => {
    const id_empresa = req.usuarioSeguro.id_empresa;

    try {
        const [unidades] = await dbPool.query(`
            SELECT 
                id_unidad, 
                placas_o_num AS placa, 
                capacidad_m3 
            FROM cat_unidades 
            WHERE estatus_activo = 1 AND id_empresa = ?
            ORDER BY id_unidad DESC
        `, [id_empresa]);

        res.json({
            exito: true,
            datos: unidades
        });
    } catch (error) {
        console.error('Error al obtener la tabla de unidades:', error);
        res.status(500).json({ exito: false, mensaje: 'Error al cargar las unidades' });
    }
};

// --- POST: Insertar un nuevo camión desde el Panel de Administración ---
const registrarUnidad = async (req, res) => {
    // 1. Recibimos los datos del formulario de Flutter
    const { placa, capacidad_m3 } = req.body;
    
    // 2. Identificamos a qué empresa pertenece el usuario
    const id_empresa = req.usuarioSeguro.id_empresa;

    // Validación de seguridad básica
    if (!placa || capacidad_m3 === undefined || capacidad_m3 === null) {
        return res.status(400).json({ exito: false, mensaje: 'Placa y capacidad son obligatorios' });
    }

    try {
        // 3. Insertamos en la BD. Por defecto nacen con estatus_activo = 1
        const [resultado] = await dbPool.query(`
            INSERT INTO cat_unidades (id_empresa, placas_o_num, capacidad_m3, estatus_activo) 
            VALUES (?, ?, ?, 1)
        `, [id_empresa, placa.toUpperCase(), capacidad_m3]);

        res.json({
            exito: true,
            mensaje: '¡Unidad registrada correctamente!',
            id_unidad: resultado.insertId
        });
    } catch (error) {
        console.error('Error al registrar unidad:', error);
        res.status(500).json({ exito: false, mensaje: 'Error interno del servidor al guardar la unidad' });
    }
};

// Exportamos las tres funciones
module.exports = { obtenerCatalogos, obtenerUnidades, registrarUnidad };