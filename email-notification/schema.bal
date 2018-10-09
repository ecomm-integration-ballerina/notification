public type Notification record {
    string[] parties,
    string recipient,
    string cc,
    string failedParty,
    string subject,
    string message,
    record {
        string party,
        string sc,
        string payload,
    } targetResponse,
    record {
        string party,
        string payload,
    } sourceRequest,
};