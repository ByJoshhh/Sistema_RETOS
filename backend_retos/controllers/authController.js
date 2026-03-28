// controllers/authController.js
const jwt = require('jsonwebtoken');
const dbPool = require('../config/database');

const login = async (req, res) => {
    const { username, password } = req.body;

    try {
        const [rows] = await dbPool.query(
            'SELECT * FROM cat_usuarios WHERE username = ? AND password = ? AND estatus_activo = 1',
            [username, password]
        );

        if (rows.length > 0) {
            const usuarioDB = rows[0];

            // 1. Crear el payload seguro con los datos clave del SaaS
            const payload = {
                id_usuario: usuarioDB.id_usuario,
                id_rol: usuarioDB.id_rol,
                id_empresa: usuarioDB.id_empresa 
            };

            // 2. Firmar el token (asegúrate de tener JWT_SECRET en tu archivo .env)
            const token = jwt.sign(
                payload, 
                process.env.JWT_SECRET || 'ClaveSecretaRetos2026SaaS', 
                { expiresIn: '8h' }
            );

            // 3. Devolver el token junto con la respuesta
            res.json({ 
                exito: true, 
                mensaje: 'Login correcto',
                token: token, // Este es el token que Flutter deberá guardar
                usuario: usuarioDB 
            });
        } else {
            res.status(401).json({ exito: false, mensaje: 'Usuario o contraseña incorrectos' });
        }
    } catch (error) {
        console.error('Error en el login:', error);
        res.status(500).json({ exito: false, mensaje: 'Error interno del servidor' });
    }
};

module.exports = {
    login
};