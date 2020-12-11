import ballerina/http;
import ballerina/test;

listener http:Listener serviceTestEP = new(9090);
FooClient stClient = new(9090);

@http:ServiceConfig {}
service /echo on serviceTestEP {

    @http:ResourceConfig {
    }
    transactional resource function get message(http:Caller caller, http:Request req) {
        http:Response res = new;
        checkpanic caller->respond(res);
    }
}

public client class FooClient {

    public http:Client httpClient;

    public function init(int port) {
        self.httpClient = new("http://localhost:9090");
    }

    transactional remote function foo() returns @tainted any|error {
        return self.httpClient->get("/echo/message");
    }

}

@test:Config {}
function testTransactionalServices() {
    transaction {
        var response = stClient->foo();
        var x = commit;
        if (response is http:Response) {
            test:assertEquals(response.statusCode, 200, msg = "Found expected output");
        } else if (response is error) {
            test:assertFail(msg = "Found unexpected output type: " + response.message());
        }
    }
}
