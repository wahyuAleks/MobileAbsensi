const router = require('express').Router();
const laporanController = require('../controllers/laporanController');
const { verifyToken, isAdmin } = require('../middleware/auth');
const { makeUploader } = require('../middleware/upload');

const uploadLaporan = makeUploader('laporan');

router.post('/', verifyToken, uploadLaporan.single('lampiran'), laporanController.submitLaporan);
router.get('/saya', verifyToken, laporanController.laporanSaya);
router.put('/:id', verifyToken, laporanController.updateDraft);
router.put('/:id/kirim', verifyToken, laporanController.kirimDraft);
router.get('/rekap', verifyToken, isAdmin, laporanController.rekapLaporan);

module.exports = router;
