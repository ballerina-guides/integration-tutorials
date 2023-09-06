import ballerina/email;
import ballerina/http;
import ballerina/log;
import ballerina/uuid;

type Patient record {|
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
|};

type Doctor record {|
    string name;
    string hospital;
    string category;
    string availability;
    decimal fee;
|};

type Appointment record {|
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    boolean confirmed;
    string hospital;
    string appointmentDate;
|};

type PaymentSettlement record {|
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    decimal fee;
    boolean confirmed;
    string card_number;
|};

type Payment record {|
    int appointmentNo;
    string doctorName;
    string patient;
    decimal actualFee;
    int discount;
    decimal discounted;
    string paymentID = uuid:createType4AsString();
    string status;
|};

type ReservationRequest record {|
    record {|
        *Patient;
        string cardNo;
    |} patient;
    string doctor;
    string hospital_id;
    string hospital;
    string appointment_date;
|};

type ReservationResponse record {|
    int appointmentNo;
    string doctorName;
    string patient;
    decimal actualFee;
    int discount;
    decimal discounted;
    string paymentID;
    string status;
|};

configurable int port = 8290;
configurable string hospitalServicesBackend = "http://localhost:9090";
final http:Client hospitalServicesEP = check initializeHttpClient(hospitalServicesBackend);

configurable string host = "smtp.gmail.com";
configurable string senderAddress = "rominxd97@gmail.com";
configurable string appPassword = "ztqmiijrbiiosrrw";

function initializeHttpClient(string url) returns http:Client|error => new (url);

service /healthcare on new http:Listener(port) {

    resource function post categories/[string category]/reserve(ReservationRequest reservationRequest)
            returns http:InternalServerError|http:NotFound|http:Ok {

        email:SmtpClient|email:Error smtpClient = new (host, senderAddress, appPassword);
        
        if smtpClient is email:Error {
            return <http:InternalServerError> {body: smtpClient.message()};
        } 

        ReservationRequest {
            patient: {cardNo, ...patient},
            doctor,
            hospital,
            hospital_id,
            appointment_date
        } = reservationRequest;

        Appointment|http:ClientError appointment =
                hospitalServicesEP->/[hospital_id]/categories/[category]/reserve.post({
            patient,
            doctor,
            hospital,
            appointment_date
        });

        if appointment !is Appointment {
            log:printError("Appointment reservation failed", appointment);
            if appointment is http:ClientRequestError {
                return <http:NotFound> {body: string `unknown hospital, doctor, or category`};
            }
            return <http:InternalServerError> {body: appointment.message()};
        }

        int appointmentNumber = appointment.appointmentNumber;

        PaymentSettlement paymentSettlement = {
            appointmentNumber: appointmentNumber,
            doctor: appointment.doctor,
            patient: appointment.patient,
            fee: appointment.doctor.fee,
            confirmed: appointment.confirmed,
            card_number: cardNo
        };

        Payment|http:ClientError payment =
                hospitalServicesEP->/healthcare/payments.post(paymentSettlement);

        if payment !is Payment {
            log:printError("Payment settlement failed", payment);
            if payment is http:ClientRequestError {
                return <http:NotFound> {body: string `unknown hospital, patient, or category`};
            }
            return <http:InternalServerError> {body: payment.message()};
        }

        ReservationResponse reservationResponse = {
            appointmentNo: appointmentNumber,
            doctorName: reservationRequest.doctor,
            patient: reservationRequest.patient.name,
            actualFee: payment.actualFee,
            discount: payment.discount,
            discounted: payment.discounted,
            paymentID: payment.paymentID,
            status: payment.status
        };

        string[] messageContent = from var [key, value] in reservationResponse.entries()
            let string str = key + ": " + value.toString()
            select str;

        string emailBody = string:'join("\n", ...messageContent);

        email:Message email = {
            to: reservationRequest.patient.email,
            subject: "Payment Status",
            body: emailBody
        };

        email:Error? sendMessage = smtpClient->sendMessage(email);
        if sendMessage is email:Error {
            return <http:InternalServerError> {body: sendMessage.message()};
        }
        log:printDebug("Email sent successfully",
                       status = "Payment Status",
                       body = emailBody);
        return <http:Ok> {body: reservationResponse};
    }
}
