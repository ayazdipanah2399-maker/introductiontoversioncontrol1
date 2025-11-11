//
//  ContentView.swift
//  copd
//
//  Created by alireza yazdipanah on 11/11/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
import SwiftUI

struct ContentView: View {
    @StateObject private var vm = XRayClassifierViewModel()
    @State private var showCamera = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.secondary, lineWidth: 1)
                        .frame(height: 280)

                    if let img = vm.image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Text("Capture a chest X-ray")
                            .foregroundStyle(.secondary)
                    }
                }

                // Result
                Group {
                    if vm.isLoading {
                        ProgressView("Analyzing…")
                    } else {
                        Text(vm.resultText)
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.vertical, 8)

                // Buttons
                HStack {
                    Button {
                        vm.clear()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button {
                        showCamera = true
                    } label: {
                        Label("Open Camera", systemImage: "camera")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                Spacer()

                // Academy-friendly footer note
                Text("Demo • On-device Core ML • Not for clinical use")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("XRayCheck")
            .sheet(isPresented: $showCamera) {
                ImagePicker { image in
                    if let image {
                        vm.image = image
                        vm.classify(image)
                    }
                }
                .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    ContentView()
}

