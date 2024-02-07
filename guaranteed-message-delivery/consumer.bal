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
service on new rabbitmq:Listener(rabbitmq:DEFAULT_HOST, rabbitmq:DEFAULT_PORT) {
    remote function onMessage(RabbitMqMessage message) {
        MessageContent content = message.content;
        string hospital = content.hospital;
        string patientName = content.patient.name;
        string doctor = content.doctor;

        ReservationResponse|http:ClientError reservationResponse = 
            hospitalBackend->/[content.hospital_id]/categories/[content.category]/reserve.post({
                patient: content.patient,
                doctor,
                hospital,
                appointment_date: content.appointment_date
            });

        string smsBody;
        if reservationResponse is http:ClientError {
            log:printError("Reservation request failed", patient = patientName,
                                                         doctor = doctor,
                                                         hospital = hospital);
            smsBody = string `Dear ${patientName
                        }, your appointment request at ${hospital
                        } failed. Please try again.`;
        } else {
            smsBody = string `Dear ${patientName
                        }, your appointment has been accepted at ${hospital
                        }. Appointment No: ${reservationResponse.appointmentNumber}`;
        }

        twilio:SmsResponse|error smsApiStatus = twilioEp->sendSms(fromNumber, content.patient.phone, smsBody);

        if smsApiStatus !is twilio:SmsResponse {
            log:printError("Failed to send an SMS message", smsApiStatus, phoneNo = content.patient.phone);
        }
    }
}
