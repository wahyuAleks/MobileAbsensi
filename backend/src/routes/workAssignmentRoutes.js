const router = require('express').Router();
const controller = require('../controllers/workAssignmentController');
const { verifyToken, isAdmin } = require('../middleware/auth');

router.get('/saya/hari-ini', verifyToken, controller.jadwalSayaHariIni);
router.get('/', verifyToken, isAdmin, controller.daftarTanggal);
router.post('/bulk', verifyToken, isAdmin, controller.tambahBanyak);
router.post('/', verifyToken, isAdmin, controller.tambah);
router.put('/:id', verifyToken, isAdmin, controller.perbarui);
router.delete('/:id', verifyToken, isAdmin, controller.hapus);

module.exports = router;
