const express = require('express');
const router = express.Router();
const activacionController = require('../controllers/activacionController');
const rateLimit = require('express-rate-limit');

// Definimos la regla del "Cadenero"
const registroLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hora
    max: 3, // Máximo 3 intentos por IP
    // Este mensaje es el que recibirá Flutter
    message: { 
        exito: false, 
        mensaje: "Límite de intentos excedido. Por seguridad, espera 1 hora para solicitar otro código." 
    },
    standardHeaders: true, 
    legacyHeaders: false,
});

// Aplicamos el limitador SOLO a la ruta de solicitar correo
router.post('/solicitar', registroLimiter, activacionController.solicitarRegistro);
router.post('/registrar-admin', activacionController.registrarEmpresaAdmin);

module.exports = router;