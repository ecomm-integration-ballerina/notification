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

public function sendEmail (http:Request req, Notification notification)
                    returns http:Response {

    gmail:MessageRequest messageRequest;
    string userId = config:getAsString("gmail.userId");
    messageRequest.sender = config:getAsString("gmail.sender");
    messageRequest.recipient = notification.recipient;
    messageRequest.cc = notification.cc;
    messageRequest.subject = notification.subject;
    
    string failedParty = notification.failedParty;
    string targetParty = notification.targetResponse.party;
    string sourceParty = notification.sourceRequest.party;
    string message = notification.message;
    xml intro = xml `<div id="cause"><h4>{{message}}.</h4></div>`;

    string[] parties = notification.parties;
    xml causeHeaderTable = xml `<tr><td width="50" style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2"></td></tr>`;
    xml causeTable = xml `<tr><td style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">Failure</td></tr>`;
    foreach i, party in parties {
        xml td;
        if (party == failedParty) {
            td = xml `<td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">x</td>`;
        } else {
            td = xml `<td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2"></td>`;
        }
        causeTable.setChildren(causeTable.* + td);

        td = xml `<td style="text-align: center;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">{{party}}</td>`;
        causeHeaderTable.setChildren(causeHeaderTable.* + td);
    }

    xml targetResponseTable = xml `<div id="res">
        <h4>Response from {{targetParty}} to {{sourceParty}}</h4>
        <table style="border-collapse: collapse;width: 100%; border: 1px solid #ddd;">
            <tr> 
                <td width="50" style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">Code</td>
				<td style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">{{notification.targetResponse.sc}}</td>
            </tr>	
			<tr> 
                <td style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">Payload</td>
				<td style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">{{notification.targetResponse.payload}}</td>
            </tr>
        </table>
    </div>`;

    if (failedParty == "Network") {
        targetResponseTable = xml `<div id="res">
            <h4>Network Failure</h4>
            <table style="border-collapse: collapse;width: 100%; border: 1px solid #ddd;">
            <tr> 
                <td width="50" style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">Code</td>
                <td style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">{{notification.targetResponse.sc}}</td>
            </tr>	
            <tr> 
                <td style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">Message</td>
                <td style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">{{notification.targetResponse.payload}}</td>
            </tr>
        </table>
    </div>`;
    }   

    xml sourceRequestTable = xml `<table style="border-collapse: collapse;width: 100%; border: 1px solid #ddd;">
            <tr> 
                <td width="50" style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">Payload</td>
				<td style="text-align: left;padding: 8px;border: 1px solid #ddd;background-color: #f2f2f2">{{notification.sourceRequest.payload}}</td>
            </tr>
        </table>`;

    xml body = xml `<html>
            <head><meta http-equiv="content-type" content="text/html"/></head>
            <body>
                {{intro}}
                <table style="border-collapse: collapse;width: 100%; border: 1px solid #ddd;">
                    {{causeHeaderTable}}
                    {{causeTable}}
                </table>
                {{targetResponseTable}}
                <div id="req"><h4>Request from {{sourceParty}} to {{targetParty}} </h4>{{sourceRequestTable}}</div>
                <div id="thank-you">
                    <br/><p>Thank you</p>
                    <p>This email is automatically generated by Ballerina. Please do not reply to this email.</p>
                </div>
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