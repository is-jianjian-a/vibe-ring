import Testing
@testable import VibeRingApp

struct IslandDebugScenarioTests {
    @Test
    func allDebugScenarioSessionsAreDemoSessions() {
        for scenario in IslandDebugScenario.allCases {
            let snapshot = scenario.snapshot()
            #expect(snapshot.sessions.allSatisfy { $0.origin == .demo })
        }
    }
}
