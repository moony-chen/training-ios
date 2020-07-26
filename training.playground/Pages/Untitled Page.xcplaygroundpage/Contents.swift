import UIKit
import SwiftUI
import PlaygroundSupport

Date()
Date() + 3600

enum FavColor: Int {
  case red, green, blue
}

struct ContentView: View {
  @State private var favoriteColor: FavColor = .red

    var body: some View {
        VStack {
            Picker(selection: $favoriteColor, label: Text("What is your favorite color?")) {
              Text("Red").tag(FavColor.red)
                Text("Green").tag(FavColor.green)
                Text("Blue").tag(FavColor.blue)
            }.pickerStyle(SegmentedPickerStyle())

          Text("Value: \(favoriteColor.rawValue)")
        }
    }
}

PlaygroundPage.current.setLiveView(ContentView())


