//
//  TrainingApiClient.swift
//  TrainingApiClient
//
//  Created by Moony Chen on 2020/7/24.
//  Copyright © 2020 Moony Chen. All rights reserved.
//


import Foundation
import ComposableArchitecture

public struct Course: Decodable, Identifiable, Equatable {
  public var id: Int
  public var topicName: String = ""
  public var programName: String = ""
  public var externalTrainer: String = ""
  public var deliveryDate: Date = Date()
  public var lastUpdate: Date = Date()
  public var startTime: String = ""
  public var endTime: String = ""
  public var description: String = ""
  public var meetingRoom: String = ""
  
  public var trainers: [User] = []
  public var attendees: [User] = []
  

  public init(
    id: Int = 0,
    topicName: String = "",
    programName: String = "",
    externalTrainer: String = "",
    deliveryDate: Date = Date(),
    lastUpdate: Date = Date(),
    startTime: String = "",
    endTime: String = "",
    description: String = "",
    meetingRoom: String = "",
    trainers: [User] = [],
    attendees: [User] = []
  ) {
    self.id = id
    self.topicName = topicName
    self.programName = programName
    self.externalTrainer = externalTrainer
    self.deliveryDate = deliveryDate
    self.lastUpdate = lastUpdate
    self.startTime = startTime
    self.endTime = endTime
    self.description = description
    self.meetingRoom = meetingRoom
    self.trainers = trainers
    self.attendees = attendees
  }
}

public struct User: Decodable, Identifiable, Equatable {
  public var id: Int
  public var screenName = ""
  public var emid: String? = ""
  public var firstName = ""
  public var lastName = ""
  public var active = true
  
  public init(
    id: Int = 0,
    screenName: String = "unknown.user",
    emid: String = "0",
    firstName: String = "N",
    lastName: String = "A",
    active: Bool = false
  ) {
    self.id = id
    self.screenName = screenName
    self.emid = emid
    self.firstName = firstName
    self.lastName = lastName
    self.active = active
  }
  
}

fileprivate struct Courses: Decodable, Equatable {
  var courses: [Course]
}

public struct TrainingApiClient {
  public var getUpcomingCourses: () -> Effect<[Course], ApiError>
  public var getMyRegisteredCourses: (_ emid: String) -> Effect<[Course], ApiError>

  public struct ApiError: Error, Equatable {}
  
  public init(
    getUpcomingCourses: @escaping () -> Effect<[Course], ApiError>,
    getMyRegisteredCourses: @escaping (_ emid: String) -> Effect<[Course], ApiError>
  ) {
    self.getUpcomingCourses = getUpcomingCourses
    self.getMyRegisteredCourses = getMyRegisteredCourses
  }
}

extension TrainingApiClient {
  public static func mock(
    getUpcomingCourses: @escaping () -> Effect<[Course], ApiError> = {
      Effect(value: [
        Course(id: 1, topicName: "Swift"),
        Course(id: 2, topicName: "Objc"),
        Course(id: 3, topicName: "Objc++")
        ]).eraseToEffect()
    },
    getMyRegisteredCourses: @escaping (_ emid: String) -> Effect<[Course], ApiError> = { _ in
      Effect(value: [
        Course(id: 1, topicName: "Swift"),
        Course(id: 4, topicName: "English"),
        Course(id: 5, topicName: "CI&CD")
        ]).eraseToEffect()
    }
    
  ) -> TrainingApiClient {
    .init(getUpcomingCourses: getUpcomingCourses, getMyRegisteredCourses: getMyRegisteredCourses)
  }
}

extension TrainingApiClient {
  public static var live = TrainingApiClient(
    getUpcomingCourses: { recentCourses() },
    getMyRegisteredCourses: myRegisteredCourses
  )
}

private func recentCourses(from: Date = Date(), to: Date = Date() + 60 * 3600, emid: String = "0") -> Effect<[Course], TrainingApiClient.ApiError> {
  let url = URL(string: "http://gdctools:8090/training/resteasy/training/course/recentcourses/\(df.string(from: from))/\(df.string(from: to))/\(emid)")!

  return URLSession.shared.dataTaskPublisher(for: url)
    .map { data, _ in data }
    .decode(type: Courses.self, decoder: jsonDecoder)
    .map { $0.courses }
    .mapError { err in
      print(err)
      return .init()
  }
    .eraseToEffect()
}

private func myRegisteredCourses(emid: String = "0") -> Effect<[Course], TrainingApiClient.ApiError> {
  let url = URL(string: "http://gdctools:8090/training/resteasy/training/course/myRegistered/\(emid)")!

  return URLSession.shared.dataTaskPublisher(for: url)
    .map { data, _ in data }
    .decode(type: Courses.self, decoder: jsonDecoder)
    .map { $0.courses }
    .mapError { err in
      print(err)
      return .init()
  }
    .eraseToEffect()
}

private let jsonDecoder: JSONDecoder = {
  let d = JSONDecoder()
  d.dateDecodingStrategy = .millisecondsSince1970
  return d
}()

private let df: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  return formatter
}()
