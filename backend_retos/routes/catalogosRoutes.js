// routes/catalogosRoutes.js
const express = require('express');
const router = express.Router();
const catalogosController = require('../controllers/catalogosController');
const verificarToken = require('../middleware/authMiddleware'); // El guardia de seguridad

// Rutas de LECTURA (GET)
router.get('/catalogos', verificarToken, catalogosController.obtenerCatalogos);
router.get('/unidades', verificarToken, catalogosController.obtenerUnidades);

// Rutas de ESCRITURA (POST)
router.post('/unidades', verificarToken, catalogosController.registrarUnidad);

module.exports = router;