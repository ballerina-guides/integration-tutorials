import ballerina/http;
import ballerina/log;
import ballerinax/rabbitmq;
import ballerinax/twilio;

type Doctor record {|
    string name;
    string hospital;
    string category;
    string availability;
    decimal fee;
|};

type ReservationResponse record {|
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    string hospital;
    boolean confirmed;
    string appointmentDate;
|};

type RabbitMqMessage record {|
    *rabbitmq:AnydataMessage;
    record {|
        *ReservationRequest;
        string category;
    |} content;
|};

configurable string smsFromNumber = ?;
configurable string twillioAccSId = ?;
configurable string twillioAuthToken = ?;

final http:Client hospitalBackend = check new ("http://localhost:9090/");

final twilio:Client twilioEp = check new (config = {
    twilioAuth: {
        accountSId: twillioAccSId,
        authToken: twillioAuthToken
    }
});

@rabbitmq:ServiceConfig {
    queueName: "ReservationQueue",
    autoAck: false
}
service rabbitmq:Service on new rabbitmq:Listener(rabbitmq:DEFAULT_HOST, rabbitmq:DEFAULT_PORT) {
    remote function onMessage(RabbitMqMessage message, rabbitmq:Caller caller) returns error? {
        record {|*ReservationRequest; string category;|} {category, hospital_id, ...reservation} = message.content;

        ReservationResponse|http:ClientError resp =
                    hospitalBackend->/[hospital_id]/categories/[category]/reserve.post(reservation);

        if resp !is ReservationResponse {
            log:printError("Reservation request failed", resp);
            return;
        }

        string patientPhoneNo = message.content.patient.phone;

        twilio:SmsResponse|error smsResponse = twilioEp->sendSms(smsFromNumber, patientPhoneNo,
            generateSmsText(message.content.patient.name, resp.appointmentNumber, resp.hospital));

        if smsResponse !is twilio:SmsResponse {
            log:printError("SMS API error", smsResponse);
            return;
        }

        if smsResponse.status == "error" {
            log:printError("SMS sending failed", phoneNo = patientPhoneNo,
                                                 appointmentNo = resp.appointmentNumber);
        }
        check caller->basicAck();
    }
}

function generateSmsText(string name, int appointmentNo, string hospital) returns string
        => string `Dear ${name}, Your appintment accepted at ${hospital}. Appointment No: ${appointmentNo}`;
