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
}

public struct User: Decodable, Identifiable, Equatable {
  public var id: Int
  public var screenName = ""
  public var emid: String? = ""
  public var firstName = ""
  public var lastName = ""
  public var active = true
}

fileprivate struct Courses: Decodable, Equatable {
  var courses: [Course]
}

public struct TrainingApiClient {
  public var getUpcomingCourses: () -> Effect<[Course], ApiError>

  public struct ApiError: Error, Equatable {}
}

extension TrainingApiClient {
  public static var mock = TrainingApiClient(
    getUpcomingCourses: {
      Effect(value: [
        Course(id: 1, topicName: "Swift"),
        Course(id: 2, topicName: "Objc"),
        Course(id: 3, topicName: "Objc++")
        ]).eraseToEffect()
  }
  )
}

extension TrainingApiClient {
  public static var live = TrainingApiClient(
    getUpcomingCourses: { recentCourses() }
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
