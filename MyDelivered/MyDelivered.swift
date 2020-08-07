
import SwiftUI
import ComposableArchitecture
import TrainingApiClient
import Common

public struct MyDeliveredCoursesState: Equatable {
  public var myDeliveredCourses: [Course]?
  public var isRefreshingCoures = false
  public var refreshError: TrainingApiClient.ApiError? = nil
  public var emid: String?
  
  public init(
  myDeliveredCourses: [Course]? = nil,
  isRefreshingCoures: Bool = false,
  refreshError: TrainingApiClient.ApiError? = nil,
  emid: String? = nil
  ) {
    self.myDeliveredCourses = myDeliveredCourses
    self.isRefreshingCoures = isRefreshingCoures
    self.refreshError = refreshError
    self.emid = emid
  }
  
}

public enum MyDeliveredCoursesAction {
  case course(id: Int, action: Void)
  case refreshCourseRequest
  case refreshCourseResponse(Result<[Course], TrainingApiClient.ApiError>)
}

public struct MyDeliveredCoursesEnv {
  public var api: TrainingApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  
  public init(api: TrainingApiClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
    self.api = api
    self.mainQueue = mainQueue
  }
}

public let myDeliveredCoursesReducer =
  
  Reducer<Course, Void, MyDeliveredCoursesEnv>.empty
    .forEach(
      state: \.self,
      action: /.self,
      environment: { $0 })
    .optional
    .pullback(
      state: \MyDeliveredCoursesState.myDeliveredCourses,
      action: /MyDeliveredCoursesAction.course(id:action:),
      environment: { $0 }
  )
    .combined(with:
      
      Reducer<MyDeliveredCoursesState, MyDeliveredCoursesAction, MyDeliveredCoursesEnv> { state, action, environment in
        switch action {
          
        case .refreshCourseRequest:
          state.isRefreshingCoures = true
          return environment.api.getMyDeliveredCourses(state.emid!)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(MyDeliveredCoursesAction.refreshCourseResponse)
        case let .refreshCourseResponse(result):
          state.isRefreshingCoures = false
          switch result {
          case .success(let courses):
            state.myDeliveredCourses = courses
            return .none
          case .failure(let error):
            state.refreshError = error
            return .none
          }
        case .course(id: let id, action: let action):
          return .none
        }
      }
)


public struct MyDeliveredCourseView: View {
  let store: Store<Course, Void>
  
  public var body: some View {
    WithViewStore(self.store) { course in
      Text(course.topicName)
    }
  }
}


public struct MyDeliveredCoursesView: View {
  public let store: Store<MyDeliveredCoursesState, MyDeliveredCoursesAction>
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      
      IfLetStore(
        self.store.scope(
          state: { $0.myDeliveredCourses }),
        then: { store in
          List {
            ForEachStore(
              self.store.scope(state: { $0.myDeliveredCourses! }, action: MyDeliveredCoursesAction.course(id:action:)),
              content: MyDeliveredCourseView.init(store:)
            )
          }
      },
        else: ActivityIndicator()
          .frame(maxHeight: .infinity)
          .onAppear {
          viewStore.send(MyDeliveredCoursesAction.refreshCourseRequest)
        }
      )
      
      
    }.navigationBarTitle("Delivered Courses")
  }
  
  public init(store: Store<MyDeliveredCoursesState, MyDeliveredCoursesAction>) {
    self.store = store
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    MyDeliveredCoursesView(
      store: Store(
        initialState: MyDeliveredCoursesState(emid: "0"),
        reducer: myDeliveredCoursesReducer,
        environment: MyDeliveredCoursesEnv(
          api: .mock(),
          mainQueue: DispatchQueue.main.eraseToAnyScheduler()
        )
    ))
  }
}

