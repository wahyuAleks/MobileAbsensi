const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const JenisKegiatan = sequelize.define('JenisKegiatan', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  nama: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: true,
  },
}, {
  tableName: 'jenis_kegiatan',
  timestamps: true,
});

module.exports = JenisKegiatan;
