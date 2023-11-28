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

type MessageContent record {|
    *ReservationRequest;
    string category;
|};

type RabbitMqMessage record {|
    *rabbitmq:AnydataMessage;
    MessageContent content;
|};

configurable string smsFromNumber = ?;
configurable string twillioAccSId = ?;
configurable string twillioAuthToken = ?;

final http:Client hospitalBackend = check new ("http://localhost:9090/");

final twilio:Client twilioEp = check new ({
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
        MessageContent content = message.content;

        ReservationResponse|http:ClientError appointment = 
            hospitalBackend->/[content.hospital_id]/categories/[content.category]/reserve.post({
                patient: content.patient,
                doctor: content.doctor,
                hospital: content.hospital,
                appointment_date: content.appointment_date
            });

        if appointment !is ReservationResponse {
            log:printError("Reservation request failed", appointment);
            return;
        }

        string patientPhoneNo = message.content.patient.phone;

        twilio:SmsResponse|error smsApiStatus = twilioEp->sendSms(smsFromNumber, patientPhoneNo,
            generateSmsText(message.content.patient.name, appointment.appointmentNumber, appointment.hospital));

        if smsApiStatus !is twilio:SmsResponse {
            log:printError("SMS sending failed", smsApiStatus);
            return;
        }

        check caller->basicAck();
    }
}

function generateSmsText(string name, int appointmentNo, string hospital) returns string
        => string `Dear ${name}, Your appointment has been accepted at ${hospital}. Appointment No: ${appointmentNo}`;
