// routes/acarreosRoutes.js
const express = require('express');
const router = express.Router();
const acarreosController = require('../controllers/acarreosController');
const verificarToken = require('../middlewares/authMiddleware'); // Importamos el middleware

// Ruta POST protegida: primero pasa por verificarToken, luego va a registrarAcarreo
router.post('/acarreos', verificarToken, acarreosController.registrarAcarreo);

module.exports = router;