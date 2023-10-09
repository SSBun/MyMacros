import MyMacros
import Foundation




@errorType
struct Person {
    @getter
    var name: String
}

//class Person {
//    private var _storage: [String: Any] = [:]
//    
//    @storageBacked
//    var name: String?
//}
//
//let me = Person()
//me.name = "tom"
//print(me.name)


//
//let a = 17
//let b = 25
//
//let (result, code) = #stringify(a + b)
//
//print("The value \(result) was produced by the code \"\(code)\"")
//
//    
//let str = #stringConnect("hello", "world", #anotherStringConnect("hello", "macro"))
//print(str)
//

//@propertyWrapper
//struct Wrapper<V> {
//    var wrappedValue: V
//}

//@getterMembers
//struct Person {
//    var age: Int
//    let name: String
//    var weight: Double
//}
//
//let me = Person(age: 100, name: "Tom", weight: 99.3)
//_ = me.getAge()
//_ = me.getName()
//_ = me.getWeight()

//func test() {
//    #myError("you cannot do this")
//    struct Person {
//        func run() {
//            #myError("something error")
//        }
//    }
//}

//
//@MonitoredModel(db: "zhihu-parse-error", maintainer: "caishilin")
//struct Person {
//    
//    @KeyField(["ID", "Id", "id"])
//    let id: String
//    
//    @Field("nickName")
//    let name: String
//    
//    let age: Int
//    
//    @Field("description", default: "default description")
//    let desc: String
//}

