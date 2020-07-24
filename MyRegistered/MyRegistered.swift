
import SwiftUI
import ComposableArchitecture
import TrainingApiClient

public struct MyRegisteredCoursesState: Equatable {
  public var myRegisteredCourses: [Course] = []
  public var isRefreshingCoures = false
  public var refreshError: TrainingApiClient.ApiError? = nil
  public let emid: String
}

public enum MyRegisteredCoursesAction {
  case refreshCourseRequest
  case refreshCourseResponse(Result<[Course], TrainingApiClient.ApiError>)
}

public struct MyRegisteredCoursesEnv {
  public var api: TrainingApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  
  public init(api: TrainingApiClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
    self.api = api
    self.mainQueue = mainQueue
  }
}

public let myRegisteredCoursesReducer = Reducer<MyRegisteredCoursesState, MyRegisteredCoursesAction, MyRegisteredCoursesEnv> { state, action, environment in
  switch action {
    
  case .refreshCourseRequest:
    state.isRefreshingCoures = true
    return environment.api.getMyRegisteredCourses(state.emid)
      .receive(on: environment.mainQueue)
      .catchToEffect()
      .map(MyRegisteredCoursesAction.refreshCourseResponse)
  case let .refreshCourseResponse(result):
    state.isRefreshingCoures = false
    switch result {
    case .success(let courses):
      state.myRegisteredCourses = courses
      return .none
    case .failure(let error):
      state.refreshError = error
      return .none
    }
  }
}

public struct MyRegisteredCoursesView: View {
  public let store: Store<MyRegisteredCoursesState, MyRegisteredCoursesAction>
  
  public var body: some View {
    NavigationView {
      WithViewStore(self.store) { viewStore in
        List {
          ForEach(viewStore.myRegisteredCourses) { course in
            Text(course.topicName)
          }
          
        }.onAppear {
          viewStore.send(MyRegisteredCoursesAction.refreshCourseRequest)
        }
        .navigationBarTitle("Registered Courses")
      }
      
    }
  
  }
  
  public init(store: Store<MyRegisteredCoursesState, MyRegisteredCoursesAction>) {
    self.store = store
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    MyRegisteredCoursesView(
      store: Store(
        initialState: MyRegisteredCoursesState(emid: "0"),
        reducer: myRegisteredCoursesReducer,
        environment: MyRegisteredCoursesEnv(
          api: .mock(),
          mainQueue: DispatchQueue.main.eraseToAnyScheduler()
        )
    ))
  }
}
