import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerina/config;
import wso2/gmail;

endpoint gmail:Client gmailEP {
    clientConfig:{
        auth:{
            accessToken: config:getAsString("gmail.accessToken"),
            clientId: config:getAsString("gmail.clientId"),
            clientSecret: config:getAsString("gmail.clientSecret"),
            refreshToken: config:getAsString("gmail.refreshToken")
        }
    }
};

public function addNotification (http:Request req, Notification notification)
                    returns http:Response {

    gmail:MessageRequest messageRequest;
    string userId = config:getAsString("gmail.userId");
    messageRequest.sender = config:getAsString("gmail.sender");
    messageRequest.recipient = notification.recipient;
    messageRequest.cc = notification.cc;
    messageRequest.subject = notification.subject;
    
    string cause = notification.cause;

    xml causeTable;
    if (cause == "Network Failure") {
        causeTable = xml `<tr>
                <td style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">Failure</td>
				<td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2"></td>
				<td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2"></td>
				<td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2"></td>
				<td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">x</td>
            </tr>`;
    }

    xml body = xml `<html>
            <head>
                <meta http-equiv="content-type" content="text/html"/>
            </head>
            <body>
                <table style="border-collapse: collapse;width: 100%; border: 1px solid #ddd;">
                    <tr>
                        <td width="50" style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2"></td>
                        <td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">BQ</td>
                        <td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">EF</td>
                        <td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">WSO2</td>
                        <td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">Network</td>
                    </tr>
                    {{causeTable}}
                </table>
            </body>
        </html>`;

    string htmlBody = <string> body;
    messageRequest.messageBody = htmlBody;
    messageRequest.contentType = "text/html";

    var sendMessageResponse = gmailEP->sendMessage(userId, messageRequest);

    json resJson;
    int statusCode;
    match sendMessageResponse {
        (string, string) sendStatus => {
            statusCode = http:OK_200;
            resJson = { "Status": "Email sent" };
        }
        
        gmail:GmailError err => {
            log:printError("Error occured while sending email", err = err);
            statusCode = http:INTERNAL_SERVER_ERROR_500;
            resJson = { "Status": "Email not sent", "Error": err.message };
        }
    }

    http:Response res = new;
    res.setJsonPayload(untaint resJson);
    res.statusCode = statusCode;
    return res;
}