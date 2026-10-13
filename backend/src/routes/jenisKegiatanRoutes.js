const router = require('express').Router();
const controller = require('../controllers/jenisKegiatanController');
const { verifyToken, isAdmin } = require('../middleware/auth');

router.get('/', verifyToken, controller.daftar);
router.post('/', verifyToken, isAdmin, controller.tambah);
router.put('/:id', verifyToken, isAdmin, controller.perbarui);

module.exports = router;
