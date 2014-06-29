
import XCTest
import Cocoa

class FaceDefTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testUpdate() {
        var path = NSBundle.mainBundle().pathForResource("default", ofType:"mcface")
        var faceDef = FaceDef(path:path)

        faceDef.dumpPattern("dump.png")

        NSWorkspace.sharedWorkspace().openFile("dump.png")
    }
}