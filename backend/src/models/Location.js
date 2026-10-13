const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');

const Location = sequelize.define('Location', {
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
  latitude: {
    type: DataTypes.DECIMAL(10, 7),
    allowNull: true,
  },
  longitude: {
    type: DataTypes.DECIMAL(10, 7),
    allowNull: true,
  },
  radius_meters: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 250,
  },
}, {
  tableName: 'locations',
  timestamps: true,
});

module.exports = Location;
