const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Location = require('./Location');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  nama: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: { isEmail: true },
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  role: {
    type: DataTypes.ENUM('karyawan', 'admin'),
    allowNull: false,
    defaultValue: 'karyawan',
  },
  jabatan: DataTypes.STRING,
  no_hp: DataTypes.STRING,
  foto_profil: DataTypes.STRING,
  location_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
}, {
  tableName: 'users',
  timestamps: true,
});

User.belongsTo(Location, { foreignKey: 'location_id' });
Location.hasMany(User, { foreignKey: 'location_id' });

module.exports = User;
