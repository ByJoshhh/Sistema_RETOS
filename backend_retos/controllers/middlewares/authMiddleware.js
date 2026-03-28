// middlewares/authMiddleware.js
const jwt = require('jsonwebtoken');

const verificarToken = (req, res, next) => {
    // 1. Obtenemos el token de los encabezados (Headers)
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ exito: false, mensaje: "Acceso denegado. Token no proporcionado." });
    }

    try {
        // 2. Verificamos la autenticidad del token
        const decodificado = jwt.verify(token, process.env.JWT_SECRET || 'ClaveSecretaRetos2026SaaS');
        
        // 3. Inyectamos los datos limpios y seguros en la petición
        req.usuarioSeguro = decodificado;
        
        next(); // Permitimos que avance al controlador
    } catch (error) {
        return res.status(403).json({ exito: false, mensaje: "Token inválido o expirado." });
    }
};

module.exports = verificarToken;