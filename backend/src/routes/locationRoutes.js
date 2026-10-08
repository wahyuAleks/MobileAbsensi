const router = require('express').Router();
const locationController = require('../controllers/locationController');
const { verifyToken, isAdmin } = require('../middleware/auth');

router.get('/', verifyToken, isAdmin, locationController.daftarLokasi);
router.post('/', verifyToken, isAdmin, locationController.tambahLokasi);
router.put('/:id', verifyToken, isAdmin, locationController.updateLokasi);
router.delete('/:id', verifyToken, isAdmin, locationController.hapusLokasi);
router.get('/:id/jadwal', verifyToken, isAdmin, locationController.jadwalLokasi);
router.put('/:id/jadwal', verifyToken, isAdmin, locationController.simpanJadwalLokasi);

module.exports = router;
