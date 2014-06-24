
import XCTest

class StatsHostoryTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testUpdate() {
        var history = StatsHistory()
        
        history.update()
        
        XCTAssertEqual(history.records.count, 1)

        history.update()
        
        XCTAssertEqual(history.records.count, 2)
    }
}