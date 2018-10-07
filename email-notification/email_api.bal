import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/config;

endpoint http:Listener notificationListener {
    port: 8280
};

@http:ServiceConfig {
    basePath: "/notification"
}
service<http:Service> notificationAPI bind notificationListener {

    @http:ResourceConfig {
        methods:["POST"],
        path: "/",
        body: "notification"
    }
    addNotification (endpoint outboundEp, http:Request req, Notification notification) {
        http:Response res = addNotification(req, untaint notification);
        outboundEp->respond(res) but { error e => log:printError("Error while responding", err = e) };
    }
    
}