const mongoose = require('mongoose');

const SetSchema = new mongoose.Schema({
  reps: Number,
  weight: Number,
  duration: String
}, { _id: false });

const ExerciseSchema = new mongoose.Schema({
  part: String,
  name: String,
  key: String,
  restTime: String,
  sets: [SetSchema]
}, { _id: false });

const TemplateSchema = new mongoose.Schema({
  templateId: {
    type: String,
    required: true,
    unique: true
  },
  name: {
    type: String,
    required: true
  },
  isRoutine: {
    type: Boolean,
    default: true
  },
  scheduledDays: [String],
  exercises: [ExerciseSchema],
  notes: String,
  isPremium: {
    type: Boolean,
    default: false
  },
  level: String,
  duration: String,
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Template', TemplateSchema); 