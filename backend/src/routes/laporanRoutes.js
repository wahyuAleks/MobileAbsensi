const router = require('express').Router();
const laporanController = require('../controllers/laporanController');
const { verifyToken, isAdmin } = require('../middleware/auth');
const { makeUploader } = require('../middleware/upload');

const uploadLaporan = makeUploader('laporan');

router.post('/', verifyToken, uploadLaporan.any(), laporanController.submitLaporan);
router.get('/saya', verifyToken, laporanController.laporanSaya);
router.put('/:id/admin-edit', verifyToken, isAdmin, uploadLaporan.any(), laporanController.editLaporanAdmin);
router.put('/:id', verifyToken, uploadLaporan.any(), laporanController.updateDraft);
router.put('/:id/kirim', verifyToken, uploadLaporan.any(), laporanController.kirimDraft);
router.get('/rekap', verifyToken, isAdmin, laporanController.rekapLaporan);

module.exports = router;
