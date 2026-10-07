const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const Location = require('./Location');

const WorkSchedule = sequelize.define('WorkSchedule', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  location_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  tanggal: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  jam_masuk: {
    type: DataTypes.TIME,
    allowNull: false,
  },
}, {
  tableName: 'work_schedules',
  timestamps: true,
  indexes: [{
    unique: true,
    fields: ['location_id', 'tanggal'],
  }],
});

WorkSchedule.belongsTo(Location, { foreignKey: 'location_id', onDelete: 'CASCADE' });
Location.hasMany(WorkSchedule, { foreignKey: 'location_id', onDelete: 'CASCADE' });

module.exports = WorkSchedule;
