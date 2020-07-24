//
//  ContentView.swift
//  training-ios-new
//
//  Created by Moony Chen on 2020/7/22.
//  Copyright © 2020 Moony Chen. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import TrainingApiClient

struct AppState: Equatable {
  var upcomingCourses: [Course] = []
  var isRefreshingCoures = false
  var refreshError: TrainingApiClient.ApiError? = nil
}

enum AppAction {
  case refreshCourseRequest
  case refreshCourseResponse(Result<[Course], TrainingApiClient.ApiError>)
}

struct AppEnv {
  var api: TrainingApiClient
  var mainQueue: AnySchedulerOf<DispatchQueue>
}

let appReducer = Reducer<AppState, AppAction, AppEnv> { state, action, environment in
  switch action {
    
  case .refreshCourseRequest:
    state.isRefreshingCoures = true
    return environment.api.getUpcomingCourses()
      .receive(on: environment.mainQueue)
      .catchToEffect()
      .map(AppAction.refreshCourseResponse)
  case let .refreshCourseResponse(result):
    state.isRefreshingCoures = false
    switch result {
    case .success(let courses):
      state.upcomingCourses = courses
      return .none
    case .failure(let error):
      state.refreshError = error
      return .none
    }
  }
}

struct ContentView: View {
  let store: Store<AppState, AppAction>
  
  var body: some View {
    NavigationView {
      WithViewStore(self.store) { viewStore in
        List {
          ForEach(viewStore.state.upcomingCourses) { course in
            Text(course.topicName)
          }
          
        }.onAppear {
          viewStore.send(AppAction.refreshCourseRequest)
        }
        .navigationBarTitle("Upcoming Courses")
      }
      
    }
  
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(
      store: Store(
        initialState: AppState(),
        reducer: appReducer,
        environment: AppEnv(
          api: .mock,
          mainQueue: DispatchQueue.main.eraseToAnyScheduler()
        )
    ))
  }
}
