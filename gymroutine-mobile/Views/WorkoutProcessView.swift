import SwiftUI

struct WorkoutProcessView: View {
    @StateObject private var viewModel: WorkoutProcessViewModel
    @State private var currentIndex = 0

    init(exercises: [[String: Any]]) {
        _viewModel = StateObject(wrappedValue: WorkoutProcessViewModel(exercises: exercises))
    }

    var body: some View {
        VStack {
            if let currentExercise = viewModel.getExercise(at: currentIndex) {
                Text("Exercise: \(currentExercise["ExerciseName"] as? String ?? "Unknown")")
                    .font(.headline)
                Text("Body Part: \(currentExercise["BodyPart"] as? String ?? "Unknown")")

                if let sets = currentExercise["Sets"] as? [[String: Any]] {
                    List(sets.indices, id: \.self) { index in
                        let set = sets[index]
                        HStack {
                            Text("Set \(index + 1)")
                                .frame(width: 50, alignment: .leading)
                            
                            Text("Reps")
                            TextField("Reps", text: Binding(
                                get: { "\(set["Reps"] as? Int ?? 0)" },
                                set: { newValue in
                                    if let intValue = Int(newValue) {
                                        viewModel.updateSetValue(exerciseIndex: currentIndex, setIndex: index, key: "Reps", newValue: intValue)
                                    }
                                }
                            ))
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)

                            Text("Weight")
                            TextField("Weight", text: Binding(
                                get: { "\(set["Weight"] as? Int ?? 0)" },
                                set: { newValue in
                                    if let intValue = Int(newValue) {
                                        viewModel.updateSetValue(exerciseIndex: currentIndex, setIndex: index, key: "Weight", newValue: intValue)
                                    }
                                }
                            ))
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 60)

                            Toggle("Done", isOn: Binding(
                                get: { set["isDone"] as? Bool ?? false },
                                set: { newValue in
                                    viewModel.updateSetValue(exerciseIndex: currentIndex, setIndex: index, key: "isDone", newValue: newValue)
                                }
                            ))
                            .labelsHidden()
                        }
                    }
                }
            } else {
                Text("No exercise at index \(currentIndex)")
            }

            Spacer()

            HStack {
                Button(action: {
                    if currentIndex > 0 {
                        currentIndex -= 1
                    }
                }) {
                    Text("Previous")
                }
                Spacer()
                Button(action: {
                    if currentIndex < viewModel.getTotalExerciseCount() - 1 {
                        currentIndex += 1
                    }
                }) {
                    Text("Next")
                }
            }
            .padding()
        }
        .padding()
    }
}
