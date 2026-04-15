const express = require('express');
const router = express.Router();
const catalogosController = require('../controllers/catalogosController');
const verificarToken = require('../middleware/authMiddleware'); // <-- Importamos al guardia de seguridad

// Protegemos todas las rutas del catálogo
router.get('/catalogos', verificarToken, catalogosController.obtenerCatalogos);
router.get('/unidades', verificarToken, catalogosController.obtenerUnidades); // <-- La nueva ruta que consume Flutter

module.exports = router;