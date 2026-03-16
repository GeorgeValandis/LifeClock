//
//  LifeClockTests.swift
//  LifeClockTests
//
//  Created by Georgios Avenidis on 24.02.26.
//

import Testing
@testable import LifeClock

struct LifeClockTests {

    @Test func lifeUnitsUseExpectedBaseSeconds() async throws {
        #expect(LifeUnit.days.seconds == 86_400)
        #expect(LifeUnit.hours.seconds == 3_600)
        #expect(LifeUnit.minutes.seconds == 60)
    }

    @Test func unitConversionUsesConfiguredSecondValues() async throws {
        #expect(LifeUnit.hours.convert(from: 7_200) == 2)
        #expect(LifeUnit.days.convert(from: 172_800) == 2)
        #expect(LifeUnit.minutes.convert(from: 180) == 3)
    }

}
