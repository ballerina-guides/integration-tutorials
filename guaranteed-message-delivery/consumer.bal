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

final http:Client hospitalBackend = check initializeHttpClient();

final twilio:Client twilioEp = check initializeTwilioClient();

function initializeHttpClient() returns http:Client|error => new ("http://localhost:9090");

function initializeTwilioClient() returns twilio:Client|error => new ({
    twilioAuth: {
        accountSId,
        authToken
    }
});

@rabbitmq:ServiceConfig {
    queueName
}
service rabbitmq:Service on new rabbitmq:Listener(rabbitmq:DEFAULT_HOST, rabbitmq:DEFAULT_PORT) {
    remote function onMessage(RabbitMqMessage message) {
        MessageContent content = message.content;

        ReservationResponse|http:ClientError reservationResponse = 
            hospitalBackend->/[content.hospital_id]/categories/[content.category]/reserve.post({
                patient: content.patient,
                doctor: content.doctor,
                hospital: content.hospital,
                appointment_date: content.appointment_date
            });

        string smsBody;
        if reservationResponse is http:ClientError {
            log:printError("Reservation request failed", reservationResponse);
            smsBody = string `Dear ${content.patient.name}, 
                                your appointment has been failed at ${content.hospital}.`;
        } else {
            smsBody = string `Dear ${content.patient.name}, 
                                your appointment has been accepted at ${content.hospital}. 
                                Appointment No: ${reservationResponse.appointmentNumber}`;
        }

        twilio:SmsResponse|error smsApiStatus = twilioEp->sendSms(fromNumber, content.patient.phone, smsBody);

        if smsApiStatus !is twilio:SmsResponse {
            log:printError("Failed to send an SMS message", phoneNo = content.patient.phone,
                                                            smsBody = smsBody);
        }
    }
}
