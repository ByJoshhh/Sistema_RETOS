const dbPool = require('../config/database');
const bcrypt = require('bcryptjs'); // <-- LA MAGIA DE LA SEGURIDAD

// --- 1. OBTENER TODOS LOS USUARIOS (GET) ---
const obtenerUsuarios = async (req, res) => {
    try {
        const id_empresa = req.usuarioSeguro.id_empresa;
        const [rows] = await dbPool.query(
            `SELECT id_usuario, nombre_completo, username, rol, estatus_activo 
             FROM cat_usuarios 
             WHERE id_empresa = ? AND estatus_activo = 1`,
            [id_empresa]
        );
        res.status(200).json({ exito: true, datos: rows });
    } catch (error) {
        console.error("Error al obtener usuarios:", error);
        res.status(500).json({ exito: false, mensaje: 'Error interno al obtener usuarios' });
    }
};

// --- 2. CREAR UN NUEVO USUARIO (POST) ---
const crearUsuario = async (req, res) => {
    try {
        const { nombre_completo, username, password, rol } = req.body;
        const id_empresa = req.usuarioSeguro.id_empresa;

        if (!nombre_completo || !username || !password || !rol) {
            return res.status(400).json({ exito: false, mensaje: 'Faltan campos obligatorios' });
        }

        const [existe] = await dbPool.query('SELECT id_usuario FROM cat_usuarios WHERE username = ?', [username]);
        if (existe.length > 0) {
            return res.status(400).json({ exito: false, mensaje: 'Ese nombre de usuario ya está en uso.' });
        }

        // 👇 HASHEAMOS LA CONTRASEÑA ANTES DE GUARDAR 👇
        const salt = await bcrypt.genSalt(10);
        const passwordHasheada = await bcrypt.hash(password, salt);

        const [resultado] = await dbPool.query(
            `INSERT INTO cat_usuarios (id_empresa, nombre_completo, username, password, rol, estatus_activo) 
             VALUES (?, ?, ?, ?, ?, 1)`,
            [id_empresa, nombre_completo, username, passwordHasheada, rol] // Pasamos el hash, no el texto plano
        );

        res.status(200).json({ exito: true, mensaje: 'Empleado registrado exitosamente', id_insertado: resultado.insertId });
    } catch (error) {
        console.error("Error al crear usuario:", error);
        res.status(500).json({ exito: false, mensaje: 'Error interno al registrar el empleado' });
    }
};

// --- 3. ACTUALIZAR USUARIO (PUT) ---
const actualizarUsuario = async (req, res) => {
    try {
        const id_usuario = req.params.id;
        const id_empresa = req.usuarioSeguro.id_empresa;
        const { nombre_completo, username, password, rol } = req.body;

        if (!nombre_completo || !username || !rol) {
            return res.status(400).json({ exito: false, mensaje: 'Faltan campos obligatorios' });
        }

        const [existe] = await dbPool.query(
            'SELECT id_usuario FROM cat_usuarios WHERE username = ? AND id_usuario != ?',
            [username, id_usuario]
        );

        if (existe.length > 0) {
            return res.status(400).json({ exito: false, mensaje: 'El nombre de usuario ya está en uso' });
        }

        let query, params;
        
        // 👇 SI MANDARON UNA CONTRASEÑA NUEVA, LA HASHEAMOS 👇
        if (password && password.trim() !== '') {
            const salt = await bcrypt.genSalt(10);
            const passwordHasheada = await bcrypt.hash(password, salt);

            query = 'UPDATE cat_usuarios SET nombre_completo=?, username=?, password=?, rol=? WHERE id_usuario=? AND id_empresa=?';
            params = [nombre_completo, username, passwordHasheada, rol, id_usuario, id_empresa]; // Usamos el hash
        } else {
            // Si la dejaron en blanco, actualizamos todo menos la contraseña
            query = 'UPDATE cat_usuarios SET nombre_completo=?, username=?, rol=? WHERE id_usuario=? AND id_empresa=?';
            params = [nombre_completo, username, rol, id_usuario, id_empresa];
        }

        await dbPool.query(query, params);
        res.status(200).json({ exito: true, mensaje: 'Usuario actualizado correctamente' });

    } catch (error) {
        console.error("Error al actualizar usuario:", error);
        res.status(500).json({ exito: false, mensaje: 'Error interno al actualizar' });
    }
};

// --- 4. BLOQUEAR USUARIO / BAJA LÓGICA (DELETE) ---
const bloquearUsuario = async (req, res) => {
    try {
        const id_usuario = req.params.id;
        const id_empresa = req.usuarioSeguro.id_empresa;

        await dbPool.query('UPDATE cat_usuarios SET estatus_activo = 0 WHERE id_usuario = ? AND id_empresa = ?', [id_usuario, id_empresa]);
        res.status(200).json({ exito: true, mensaje: 'Usuario dado de baja del sistema' });
    } catch (error) {
        console.error("Error al bloquear usuario:", error);
        res.status(500).json({ exito: false, mensaje: 'Error interno al bloquear' });
    }
};

module.exports = {
    obtenerUsuarios,
    crearUsuario,
    actualizarUsuario,
    bloquearUsuario
};