const dbPool = require('../config/database');
const bcrypt = require('bcryptjs');
const transporter = require('../config/mailer');

// --- 1. FUNCIÓN PARA CREAR EMPRESA Y ENVIAR CÓDIGO ---
const solicitarRegistro = async (req, res) => {
    const { nombre_empresa, email_admin } = req.body;
    try {
       
        const [empresaRes] = await dbPool.query('INSERT INTO cat_empresas (nombre_empresa) VALUES (?)', [nombre_empresa]);
        
        // Generamos el código aleatorio
        const codigo_token = `GYBSA-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
        
        // Lo guardamos en la base de datos
        await dbPool.query('INSERT INTO tokens_activacion (id_empresa, codigo_token, usado) VALUES (?, ?, 0)', [empresaRes.insertId, codigo_token]);

        // Enviamos el correo mágico
        await transporter.sendMail({
            from: `"SyC.O.R.E. Logística" <${process.env.EMAIL_USER}>`,
            to: email_admin,
            subject: 'Tu Código de Activación - SyC.O.R.E.',
            html: `
                <div style="font-family: Arial, sans-serif; text-align: center; padding: 20px;">
                    <h2 style="color: #2B3674;">¡Bienvenido a SyC.O.R.E.!</h2>
                    <p>Tu sistema en la nube está listo. Utiliza este código mágico en la app para activar tu cuenta de Administrador:</p>
                    <h1 style="color: #4318FF; background: #f4f7fe; padding: 15px; border-radius: 10px; display: inline-block;">${codigo_token}</h1>
                </div>
            `
        });

        res.status(200).json({ exito: true, mensaje: "Código enviado a tu correo" });
    } catch (error) { 
        console.error("Error al generar registro:", error);
        res.status(500).json({ exito: false, mensaje: "Error al generar registro en la Base de Datos." }); 
    }
};

// --- 2. FUNCIÓN PARA CANJEAR EL CÓDIGO Y CREAR AL ADMIN ---
const registrarEmpresaAdmin = async (req, res) => {
    const { codigo_token, nombre_completo, username, password } = req.body;
    try {
        // Validamos si el código existe y no está usado
        const [tokenRows] = await dbPool.query('SELECT id_token, id_empresa FROM tokens_activacion WHERE codigo_token = ? AND usado = 0', [codigo_token]);
        if (tokenRows.length === 0) return res.status(400).json({ exito: false, mensaje: "Código inválido o ya utilizado" });

        const { id_empresa, id_token } = tokenRows[0];
        
        // Validamos que el nombre de usuario esté disponible
        const [userRows] = await dbPool.query('SELECT id_usuario FROM cat_usuarios WHERE username = ?', [username]);
        if (userRows.length > 0) return res.status(400).json({ exito: false, mensaje: "Ese nombre de usuario no está disponible" });

        // Encriptamos la contraseña del nuevo admin nivel Dios
        const hash = await bcrypt.hash(password, await bcrypt.genSalt(10));

        // Insertamos al administrador
        await dbPool.query(
            "INSERT INTO cat_usuarios (id_empresa, nombre_completo, username, password, rol, estatus_activo) VALUES (?, ?, ?, ?, 'admin', 1)",
            [id_empresa, nombre_completo, username, hash]
        );
        
        // Quemamos el código para que no se re-utilice
        await dbPool.query('UPDATE tokens_activacion SET usado = 1 WHERE id_token = ?', [id_token]);

        res.status(200).json({ exito: true, mensaje: "¡Cuenta de Administrador creada de forma segura!" });
    } catch (error) { 
        console.error("Error al registrar admin:", error);
        res.status(500).json({ exito: false, mensaje: "Error interno al procesar el código." }); 
    }
};

module.exports = { solicitarRegistro, registrarEmpresaAdmin };