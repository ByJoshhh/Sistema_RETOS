const dbPool = require('../config/database');

const obtenerCatalogos = async (req, res) => {
    // Seguridad SaaS: Extraemos del token, ya no confiamos en req.query
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

// --- NUEVA FUNCIÓN PARA LA TABLA WEB ---
const obtenerUnidades = async (req, res) => {
    const id_empresa = req.usuarioSeguro.id_empresa;

    try {
        // Adaptado a tu BD: Solo pedimos id_unidad, placas_o_num y capacidad_m3
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

module.exports = { obtenerCatalogos, obtenerUnidades };