const db = require('../config/database'); 

const registrarAcarreo = async (req, res) => {
  console.log("Iniciando registro de acarreo...");
  
  // 1. Extraemos solo los datos de la operación física que vienen de la app
  const { folio_suministro, distancia_km, cantidad_m3_recibida } = req.body;

  // 2. Extraemos los datos de identidad y empresa directamente de la firma criptográfica (SaaS)
  const id_empresa = req.usuarioSeguro.id_empresa;
  const id_checador_obra = req.usuarioSeguro.id_usuario; 

  console.log(`Seguridad SaaS -> Empresa: ${id_empresa} | Checador logueado: ${id_checador_obra}`);

  // Validación básica
  if (!folio_suministro || !id_checador_obra || !id_empresa) {
    console.log("Error: Faltan datos obligatorios.");
    return res.status(400).json({ exito: false, mensaje: 'Faltan datos obligatorios' });
  }

  try {
    // PASO 1: Buscar el folio asegurando que pertenezca a la MISMA empresa
    console.log("Ejecutando busqueda de folio:", folio_suministro);
    const sqlBuscar = 'SELECT folio_suministro FROM registro_suministros WHERE folio_suministro = ? AND id_empresa = ?';
    const [results] = await db.query(sqlBuscar, [folio_suministro, id_empresa]);

    if (results.length === 0) {
      console.log("Bloqueo de seguridad: Folio no encontrado o pertenece a otra empresa.");
      return res.status(404).json({ exito: false, mensaje: 'Suministro no encontrado o acceso denegado' });
    }

    console.log("Folio verificado. Procediendo a generar acarreo...");

    // PASO 2: Generar folio de recepcion
    const folio_acarreo = 'REC-' + Date.now().toString().slice(-6);

    // PASO 3: Insertar en registro_acarreos
    console.log("Insertando nuevo registro en registro_acarreos...");
    const sqlInsertar = `
      INSERT INTO registro_acarreos 
      (folio_acarreo, id_empresa, folio_suministro, fecha_hora_llegada, id_checador_obra, distancia_km, cantidad_m3_recibida) 
      VALUES (?, ?, ?, NOW(), ?, ?, ?)
    `;
    await db.query(sqlInsertar, [folio_acarreo, id_empresa, folio_suministro, id_checador_obra, distancia_km, cantidad_m3_recibida]);

    console.log("Acarreo insertado correctamente. Actualizando estatus del suministro...");

    // PASO 4: Actualizar estatus a 'Entregado', asegurando nuevamente el filtro de empresa
    const sqlActualizar = `UPDATE registro_suministros SET estatus = 'Entregado' WHERE folio_suministro = ? AND id_empresa = ?`;
    await db.query(sqlActualizar, [folio_suministro, id_empresa]);


    console.log(`EXITO: Viaje ${folio_suministro} cerrado con exito. Folio: ${folio_acarreo}`);
    return res.status(200).json({ 
      exito: true, 
      folio_acarreo: folio_acarreo, 
      mensaje: 'Viaje recibido y cerrado con exito' 
    });

  } catch (error) {
    console.error("ERROR FATAL DETECTADO:", error);
    return res.status(500).json({ exito: false, mensaje: 'Error interno del servidor al procesar el acarreo' });
  }
};

module.exports = {
  registrarAcarreo
};