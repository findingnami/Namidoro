//
//  CountdownView.swift
//  Namidoro
//
//  Created by Maria Rachel on 9/24/25.
//

import SwiftUI

/* struct CountdownView: View {
    @State private var timeRemaining = 1500
    @State private var isRunning = false
    
    var timeDisplay: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack {
            Text(timeDisplay)
                .font(.largeTitle)
            Button(isRunning ? "Pause" : "Start")  {
                isRunning.toggle()
            }
            Button("Reset") {
                isRunning = false
                timeRemaining = 1500
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if isRunning && timeRemaining > 0 {
                    DispatchQueue.main.async {
                        timeRemaining -= 1
                    }
                }
            }
        }
        
    }
        
}


#Preview {
    CountdownView()
}
*/
