import ballerina/http;
import ballerina/log;
import ballerinax/rabbitmq;
import ballerinax/twilio;

type MessageContent record {|
    *ReservationRequest;
    string category;
|};

type RabbitMqMessage record {|
    *rabbitmq:AnydataMessage;
    MessageContent content;
|};

configurable string fromNumber = ?;
configurable string accountSId = ?;
configurable string authToken = ?;

final http:Client hospitalBackend = check new ("http://localhost:9090/");

final twilio:Client twilioEp = check new ({
    twilioAuth: {
        accountSId: accountSId,
        authToken: authToken
    }
});

@rabbitmq:ServiceConfig {
    queueName,
    autoAck: true
}
service rabbitmq:Service on new rabbitmq:Listener(rabbitmq:DEFAULT_HOST, rabbitmq:DEFAULT_PORT) {
    remote function onMessage(RabbitMqMessage message, rabbitmq:Caller caller) returns error? {
        MessageContent content = message.content;

        ReservationResponse|http:ClientError reservationResponse = 
            hospitalBackend->/[content.hospital_id]/categories/[content.category]/reserve.post({
                patient: content.patient,
                doctor: content.doctor,
                hospital: content.hospital,
                appointment_date: content.appointment_date
            });

        if reservationResponse !is ReservationResponse {
            log:printError("Reservation request failed", reservationResponse);
            return;
        }

        twilio:SmsResponse|error smsApiStatus = twilioEp->sendSms(fromNumber, content.patient.phone,
            constructMessageBody(content.patient.name, 
                                 reservationResponse.appointmentNumber, 
                                 reservationResponse.hospital));

        if smsApiStatus !is twilio:SmsResponse {
            log:printError("SMS sending failed", smsApiStatus);
        }
    }
}

function constructMessageBody(string name, int appointmentNo, string hospital) returns string => 
    string `Dear ${name}, your appointment has been accepted at ${hospital}. Appointment No: ${appointmentNo}`;
