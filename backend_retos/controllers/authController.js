const jwt = require('jsonwebtoken');
const dbPool = require('../config/database');
const bcrypt = require('bcryptjs');

const login = async (req, res) => {
    const { username, password } = req.body;

    try {
        const [rows] = await dbPool.query('SELECT * FROM cat_usuarios WHERE username = ? AND estatus_activo = 1', [username]);
        if (rows.length === 0) return res.status(401).json({ exito: false, mensaje: 'Usuario no encontrado' });

        const usuarioDB = rows[0];
        // Comparamos lo que escribió con el Hash de la BD
        const passwordValida = await bcrypt.compare(password, usuarioDB.password);

        if (!passwordValida) return res.status(401).json({ exito: false, mensaje: 'Contraseña incorrecta' });

        const payload = { id_usuario: usuarioDB.id_usuario, id_rol: usuarioDB.rol, id_empresa: usuarioDB.id_empresa };
        const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '8h' });

        res.status(200).json({
            exito: true, token: token,
            usuario: { id_usuario: usuarioDB.id_usuario, id_empresa: usuarioDB.id_empresa, nombre_completo: usuarioDB.nombre_completo, rol: usuarioDB.rol }
        });
    } catch (error) {
        res.status(500).json({ exito: false, mensaje: 'Error interno' });
    }
};

module.exports = { login };