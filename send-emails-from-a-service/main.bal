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

const string hostUrl = "smtp.gmail.com";

configurable int port = 8290;
configurable string hospitalServicesBackend = "http://localhost:9090";
configurable string paymentBackend = "http://localhost:9090/healthcare/payments";
configurable string senderAddress = ?;
configurable string appPassword = ?;

final http:Client hospitalServicesEP = check initializeHttpClient(hospitalServicesBackend);
final http:Client paymentEP = check initializeHttpClient(paymentBackend);
final email:SmtpClient smtpClient = check initializeEmailClient(hostUrl, senderAddress, appPassword);

function initializeHttpClient(string url) returns http:Client|error => new (url);
function initializeEmailClient(string host, string username, string password) 
    returns email:SmtpClient|error => new (host, username, password);

service /healthcare on new http:Listener(port) {

    resource function post categories/[string category]/reserve(ReservationRequest payload)
            returns http:InternalServerError|http:NotFound|http:Ok {

        ReservationRequest {
            patient: {cardNo, ...patient},
            doctor,
            hospital,
            hospital_id,
            appointment_date
        } = payload;

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

        Payment|http:ClientError payment = paymentEP->/.post({
            appointmentNumber: appointmentNumber,
            doctor: appointment.doctor,
            patient: appointment.patient,
            fee: appointment.doctor.fee,
            confirmed: appointment.confirmed,
            card_number: cardNo
        });

        if payment !is Payment {
            log:printError("Payment settlement failed", payment);
            if payment is http:ClientRequestError {
                return <http:NotFound> {body: string `unknown appointment number`};
            }
            return <http:InternalServerError> {body: payment.message()};
        }

        string messageContent = string `Appointment Confirmation

        Appointment Details
            Appointment Number : ${appointmentNumber}
            Appointment Date: ${payload.appointment_date}

        Patient Details
            Name : ${payload.patient.name}
            Contact Number : ${payload.patient.phone}
            Doctor Name : ${payload.doctor}

        Doctor Details
            Name : ${appointment.doctor.name}
            Specialization : ${appointment.doctor.category}

        Payment Details
            Doctor Fee : ${payment.actualFee}
            Discount : ${payment.discount}
            Total Fee : ${payment.discounted}
            Payment Status : ${payment.status}`;

        email:Error? sendMessage = smtpClient->sendMessage({
            to: payload.patient.email,
            subject: "Appointment reservation confirmed at " + payload.hospital,
            body: messageContent
        });
        
        if sendMessage is email:Error {
            return <http:InternalServerError> {body: sendMessage.message()};
        }
        log:printDebug("Email sent successfully",
                       status = "Payment Status",
                       body = messageContent);
        return <http:Ok> {body: messageContent};
    }
}
