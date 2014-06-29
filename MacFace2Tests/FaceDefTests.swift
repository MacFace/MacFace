
import XCTest
import Cocoa

class FaceDefTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testLoadFromFile() {
        var path = NSBundle.mainBundle().pathForResource("default", ofType:"mcface")
        var faceDef = FaceDef(path:path)

        faceDef.dumpPattern("dump.png")

        NSWorkspace.sharedWorkspace().openFile("dump.png")
    }

    func testImageOf() {
        var path = NSBundle.mainBundle().pathForResource("default", ofType:"mcface")
        var faceDef = FaceDef(path:path)
        
        for row in (0..FACE_ROWMAX) {
            for col in (0..FACE_COLMAX) {
                let marker1 = MarkerSpecifier.Pagein
                let image = faceDef.imageOf(row, col:col, marker:marker1)
                
                let marker2 = MarkerSpecifier.Pageout
                let image2 = faceDef.imageOf(row, col:col, marker:marker2)
                
                let marker3 = MarkerSpecifier.Pagein & MarkerSpecifier.Pageout
                let image3 = faceDef.imageOf(row, col:col, marker:marker1)
            }
        }
        
        NSWorkspace.sharedWorkspace().openFile("dump.png")
    }

}