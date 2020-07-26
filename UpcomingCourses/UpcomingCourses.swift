
import SwiftUI
import ComposableArchitecture
import TrainingApiClient

public struct UpcomingCoursesState: Equatable {
  public var upcomingCourses: [Course] = []
  public var isRefreshingCoures = false
  public var refreshError: TrainingApiClient.ApiError? = nil
}

public enum UpcomingCoursesAction {
  case refreshCourseRequest
  case refreshCourseResponse(Result<[Course], TrainingApiClient.ApiError>)
}

public struct UpcomingCoursesEnv {
  public var api: TrainingApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  
  public init(api: TrainingApiClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
    self.api = api
    self.mainQueue = mainQueue
  }
}

public let upcomingCoursesReducer = Reducer<UpcomingCoursesState, UpcomingCoursesAction, UpcomingCoursesEnv> { state, action, environment in
  switch action {
    
  case .refreshCourseRequest:
    state.isRefreshingCoures = true
    return environment.api.getUpcomingCourses()
      .receive(on: environment.mainQueue)
      .catchToEffect()
      .map(UpcomingCoursesAction.refreshCourseResponse)
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

public struct UpcomingCoursesView: View {
  let store: Store<UpcomingCoursesState, UpcomingCoursesAction>
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      List {
        ForEach(viewStore.state.upcomingCourses) { course in
          Text(course.topicName)
        }
        
      }.onAppear {
        viewStore.send(UpcomingCoursesAction.refreshCourseRequest)
      }
      .navigationBarTitle("Upcoming Courses")
    }
  }
  
  public init(store: Store<UpcomingCoursesState, UpcomingCoursesAction>) {
    self.store = store
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    UpcomingCoursesView(
      store: Store(
        initialState: UpcomingCoursesState(),
        reducer: upcomingCoursesReducer,
        environment: UpcomingCoursesEnv(
          api: .mock(),
          mainQueue: DispatchQueue.main.eraseToAnyScheduler()
        )
    ))
  }
}
