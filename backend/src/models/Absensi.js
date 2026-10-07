const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');

const Absensi = sequelize.define('Absensi', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  tanggal: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  jam_masuk: DataTypes.TIME,
  jam_masuk_target: DataTypes.TIME,
  jam_pulang: DataTypes.TIME,
  foto_masuk: DataTypes.STRING,
  foto_pulang: DataTypes.STRING,
  lat_masuk: DataTypes.DECIMAL(10, 7),
  lng_masuk: DataTypes.DECIMAL(10, 7),
  lat_pulang: DataTypes.DECIMAL(10, 7),
  lng_pulang: DataTypes.DECIMAL(10, 7),
  status: {
    // dipakai untuk menandai telat / normal / tidak absen, dsb
    type: DataTypes.ENUM('hadir', 'telat', 'alpha'),
    defaultValue: 'hadir',
  },
}, {
  tableName: 'absensi',
  timestamps: true,
});

Absensi.belongsTo(User, { foreignKey: 'user_id' });
User.hasMany(Absensi, { foreignKey: 'user_id' });

module.exports = Absensi;
