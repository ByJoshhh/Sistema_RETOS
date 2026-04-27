const express = require('express');
const router = express.Router();
const usuariosController = require('../controllers/usuariosController');
const verificarToken = require('../middleware/authMiddleware');

// RUTAS PROTEGIDAS CON TOKEN
router.get('/', verificarToken, usuariosController.obtenerUsuarios);
router.post('/', verificarToken, usuariosController.crearUsuario);

// NUEVAS RUTAS PARA EDITAR Y BLOQUEAR
router.put('/:id', verificarToken, usuariosController.actualizarUsuario);
router.delete('/:id', verificarToken, usuariosController.bloquearUsuario);

module.exports = router;