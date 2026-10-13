const { DataTypes } = require('sequelize');
const sequelize = require('../config/db');
const User = require('./User');
const Location = require('./Location');

const WorkAssignment = sequelize.define('WorkAssignment', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  location_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  tanggal: {
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  jam_mulai: {
    type: DataTypes.TIME,
    allowNull: false,
  },
  jam_selesai: {
    type: DataTypes.TIME,
    allowNull: false,
  },
}, {
  tableName: 'work_assignments',
  timestamps: true,
  indexes: [
    { fields: ['user_id', 'tanggal'] },
    { fields: ['location_id', 'tanggal'] },
  ],
});

WorkAssignment.belongsTo(User, { foreignKey: 'user_id', onDelete: 'CASCADE' });
User.hasMany(WorkAssignment, { foreignKey: 'user_id', onDelete: 'CASCADE' });
WorkAssignment.belongsTo(Location, { foreignKey: 'location_id', onDelete: 'CASCADE' });
Location.hasMany(WorkAssignment, { foreignKey: 'location_id', onDelete: 'CASCADE' });

module.exports = WorkAssignment;
