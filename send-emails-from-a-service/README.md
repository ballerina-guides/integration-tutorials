# Sending emails from a service

## Overview

In this tutorial, we will develop a service that sends an email when a client makes an appointment at a hospital. The information about the appointment details is sent to the user with the email.

To implement this use case, you will develop a REST service with a single resource using Visual Studio Code with the Ballerina Swan Lake extension, and then run the service. This resource will receive the user request, retrieve details from the backend service, and send an email to the user with the appointment details.

The flow is as follows.

1. Receive a request with a JSON payload in the following form.

```json
{
    "patient": {
        "name": "John Doe",
        "dob": "1940-03-19",
        "ssn": "234-23-525",
        "address": "California",
        "phone": "8770586755",
        "email": "johndoe@gmail.com",
        "cardNo": "7844481124110331"
    },
    "doctor": "thomas collins",
    "hospital_id": "grandoaks",
    "hospital": "grand oak community hospital",
    "appointment_date": "2023-10-02"
}
```

2. Extract necessary details from the request (e.g., hospital, patient, doctor, etc.) and make a call to the hospital backend service to request an appointment. A response similar to the following will be returned from the hospital backend service on success.

```json
{
    "appointmentNumber": 1,
    "doctor": {
        "name": "thomas collins",
        "hospital": "grand oak community hospital",
        "category": "surgery",
        "availability": "9.00 a.m - 11.00 a.m",
        "fee": 7000.0
    },
    "patient": {
        "name": "John Doe",
        "dob": "1940-03-19",
        "ssn": "234-23-525",
        "address": "California",
        "phone": "8770586755",
        "email": "johndoe@gmail.com"
    },
    "hospital": "grand oak community hospital",
    "confirmed": false,
    "appointmentDate": "2023-10-02"
}
```

3. Finally, call the payment backend service to make the payment and retrieve the reservation response. Send an email to the user with the appointment details.

```json
{
    "appointmentNo": 2,
    "doctorName": "thomas collins",
    "patient": "John Doe",
    "actualFee": 7000,
    "discount": 20,
    "discounted": 5600.0,
    "paymentID": "8458c75a-c8e0-4d49-8da4-5e56043b1a20",
    "status": "settled"
}
```

### Concepts covered

- REST API
- HTTP Client
- Email Client

## Develop the application

### Step 1: Set up the workspace

Install [Ballerina Swan Lake](https://ballerina.io/downloads/) and the [Ballerina Swan Lake VS Code extension](https://marketplace.visualstudio.com/items?itemName=wso2.ballerina) on VS Code.

### Step 2: Develop the service

Follow the instructions given in this section to develop the service.

1. Create a new Ballerina project using the `bal` command and open it in VS Code.

```bash
$ bal new service-orchestration
```

2. Introduce the source code in files with the `.bal` extension (e.g., the `main.bal` file). 

Import the 
- `ballerina/email` module to send emails using the SMTP protocol
- `ballerina/http` module to develop the REST API and define the clients that can be used to send requests to the backend services
- `ballerina/log` module to log debug/error information for each client request

```ballerina
import ballerina/email;
import ballerina/http;
import ballerina/log;
```

3. Define six [configurable variables](https://ballerina.io/learn/by-example/#configurability) for the port on which the listener should listen, the URLs of the backend services and for host, username and password of the SMTP client.

```ballerina

configurable int port = 8290;
configurable string hospitalServicesBackend = "http://localhost:9090";
configurable string paymentBackend = "http://localhost:9090/healthcare/payments";
configurable string gmailHost = "smtp.gmail.com";
configurable string senderAddress = ?;
configurable string appPassword = ?;
```

4. Define two [`http:Client` clients](https://ballerina.io/learn/by-example/#http-client) and one [`email:SmtpClient` client](https://ballerina.io/learn/by-example/#email-client) to send requests to the backend services.

```ballerina
final http:Client hospitalServicesEP = check initializeHttpClient(hospitalServicesBackend);
final http:Client paymentEP = check initializeHttpClient(paymentBackend);
final email:SmtpClient smtpClient = check initializeEmailClient();

function initializeHttpClient(string url) returns http:Client|error => new (url);

function initializeEmailClient() returns email:SmtpClient|error => new (gmailHost, senderAddress, appPassword);
```

The argument to the `new` expression is the URL for the backend service. 

Alternatively, the clients can be initialized directly with `new` expressions, but a separate function is used to aid with testing.

```ballerina
final http:Client hospitalServicesEP = check new (hospitalServicesBackend);
final http:Client paymentEP = check new (paymentBackend);
```

5. Define records corresponding to the request payload and response payloads.

```ballerina
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
    string paymentID;
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
```

- The `ReservationRequest` record uses [record type inclusion](https://ballerina.io/learn/by-example/type-inclusion-for-records/) in the type of the `patient` field to include all the fields from the `Patient` record along with the `cardNo` field.

- The initial record definitions can be generated using the "Paste JSON as record" VSCode command with the relevant JSON payloads and the records can then be modified as necessary.

6. Define the [HTTP service (REST API)](https://ballerina.io/learn/by-example/#rest-service) that has the resource that accepts user requests, makes calls to the backend services to retrieve relevant details, and responds to the client. Use `/healthcare` as the service path (or the context) of the service, which is attached to the listener listening on port `port`. Define an HTTP resource that allows the `POST` operation on resource path `/categories/{category}/reserve`, where `category` (corresponding to the specialization) is a path parameter. Use `ReservationRequest` as a parameter indicating that the resource expects a JSON object corresponding to `ReservationRequest` as the payload. Use `http:InternalServerError|http:Created|http:NotFound` as the return type to indicate that the response will be "Created" when the email is sent successfully to the user or the response will be "InternalServerError" or "NotFound" on error.

```ballerina
service /healthcare on new http:Listener(port) {
    resource function post categories/[string category]/reserve(ReservationRequest payload) 
            returns http:InternalServerError|http:Created|http:NotFound {
        
    }
}
```

7. Implement the logic

```ballerina
service /healthcare on new http:Listener(port) {

    resource function post categories/[string category]/reserve(ReservationRequest payload)
            returns http:InternalServerError|http:Created|http:NotFound {

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
                return <http:NotFound>{body: string `unknown hospital, doctor, or category`};
            }
            return <http:InternalServerError>{body: appointment.message()};
        }

        int appointmentNumber = appointment.appointmentNumber;

        Payment|http:ClientError payment = paymentEP->/.post({
            appointmentNumber,
            doctor: appointment.doctor,
            patient: appointment.patient,
            fee: appointment.doctor.fee,
            confirmed: appointment.confirmed,
            card_number: cardNo
        });

        if payment !is Payment {
            log:printError("Payment settlement failed", payment);
            if payment is http:ClientRequestError {
                return <http:NotFound>{body: string `unknown appointment number`};
            }
            return <http:InternalServerError>{body: payment.message()};
        }

        email:Error? sendMessage = smtpClient->sendMessage({
            to: patient.email,
            subject: "Appointment reservation confirmed at " + hospital,
            body: getEmailContent(appointmentNumber, appointment, payment)
        });

        if sendMessage is email:Error {
            return <http:InternalServerError>{body: sendMessage.message()};
        }
        log:printDebug("Email sent successfully",
                        name = patient.name,
                        appointmentNumber = appointmentNumber);
        return <http:Created>{};
    }
}

function getEmailContent(int appointmentNumber, Appointment appointment, Payment payment)
        returns string {
    return string `Appointment Confirmation

    Appointment Details
        Appointment Number : ${appointmentNumber}
        Appointment Date: ${appointment.appointmentDate}

    Patient Details
        Name : ${appointment.patient.name}
        Contact Number : ${appointment.patient.phone}

    Doctor Details
        Name : ${appointment.doctor.name}
        Specialization : ${appointment.doctor.category}

    Payment Details
        Doctor Fee : ${payment.actualFee}
        Discount : ${payment.discount}
        Total Fee : ${payment.discounted}
        Payment Status : ${payment.status}`;
}
```

- The first backend call is a `POST` request to the hospital service to reserve the appointment. The `hospital_id` and `category` values are used as path parameters.

```ballerina
Appointment|http:ClientError appointment =
        hospitalServicesEP->/[hospital_id]/categories/[category]/reserve.post({
    patient,
    doctor,
    hospital,
    appointment_date
});
```

Use the `is` check to decide the flow based on the response to the client call. If the request failed, return a "NotFound" response. Else, if the payload could not be bound to `Appointment` as expected or if there were any other failures, respond with an "InternalServerError" response.

```ballerina
if appointment !is Appointment {
    log:printError("Appointment reservation failed", appointment);
    if appointment is http:ClientRequestError {
        return <http:NotFound>{body: string `unknown hospital, doctor, or category`};
    }
    return <http:InternalServerError>{body: appointment.message()};
}
```

If the appointment reservation was successful, we can make the payment by making a `POST` request to the payment service. The payload includes details extracted out from the original request (for `card_number`), the appointment reservation response (for `appointmentNumber`, `doctor`, `patient`, `fee` and `confirmed`)

```ballerina
Payment|http:ClientError payment = paymentEP->/.post({
    appointmentNumber,
    doctor: appointment.doctor,
    patient: appointment.patient,
    fee: appointment.doctor.fee,
    confirmed: appointment.confirmed,
    card_number: cardNo
});

if payment !is Payment {
    log:printError("Payment settlement failed", payment);
    if payment is http:ClientRequestError {
        return <http:NotFound>{body: string `unknown appointment number`};
    }
    return <http:InternalServerError>{body: payment.message()};
}
```

If the payment was successful, the next and final step is to send an email to the user containing the appointment details as the email body, namely, `Appointment Details`, `Patient Details`, `Doctor Details` and `Payment Details`. Then we create the email message with the user's email, subject and the email body.

```ballerina
email:Error? sendMessage = smtpClient->sendMessage({
    to: patient.email,
    subject: "Appointment reservation confirmed at " + hospital,
    body: getEmailContent(appointmentNumber, appointment, payment)
});
```

```ballerina
function getEmailContent(int appointmentNumber, Appointment appointment, Payment payment)
        returns string {
    return string `Appointment Confirmation

    Appointment Details
        Appointment Number : ${appointmentNumber}
        Appointment Date: ${appointment.appointmentDate}

    Patient Details
        Name : ${appointment.patient.name}
        Contact Number : ${appointment.patient.phone}

    Doctor Details
        Name : ${appointment.doctor.name}
        Specialization : ${appointment.doctor.category}

    Payment Details
        Doctor Fee : ${payment.actualFee}
        Discount : ${payment.discount}
        Total Fee : ${payment.discounted}
        Payment Status : ${payment.status}`;
}
```

Finally we send the email to the user using an SMTP client. If the sending process resulted in an error, an "InternalServerError" will be returned. If the email is sent successfully, the response will be "Created". 

```ballerina
email:Error? sendMessage = smtpClient->sendMessage({
    to: patient.email,
    subject: "Appointment reservation confirmed at " + hospital,
    body: getEmailContent(appointmentNumber, appointment, payment)
});

if sendMessage is email:Error {
    return <http:InternalServerError>{body: sendMessage.message()};
}
log:printDebug("Email sent successfully",
                name = patient.name,
                appointmentNumber = appointmentNumber);
return <http:Created>{};
```

#### Complete source

You have successfully developed the required service.

```ballerina
import ballerina/email;
import ballerina/http;
import ballerina/log;

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
    string paymentID;
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
configurable string paymentBackend = "http://localhost:9090/healthcare/payments";
configurable string gmailHost = "smtp.gmail.com";
configurable string senderAddress = ?;
configurable string appPassword = ?;

final http:Client hospitalServicesEP = check initializeHttpClient(hospitalServicesBackend);
final http:Client paymentEP = check initializeHttpClient(paymentBackend);
final email:SmtpClient smtpClient = check initializeEmailClient();

function initializeHttpClient(string url) returns http:Client|error => new (url);

function initializeEmailClient() returns email:SmtpClient|error => new (gmailHost, senderAddress, appPassword);

service /healthcare on new http:Listener(port) {

    resource function post categories/[string category]/reserve(ReservationRequest payload)
            returns http:InternalServerError|http:Created|http:NotFound {

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
                return <http:NotFound>{body: string `unknown hospital, doctor, or category`};
            }
            return <http:InternalServerError>{body: appointment.message()};
        }

        int appointmentNumber = appointment.appointmentNumber;

        Payment|http:ClientError payment = paymentEP->/.post({
            appointmentNumber,
            doctor: appointment.doctor,
            patient: appointment.patient,
            fee: appointment.doctor.fee,
            confirmed: appointment.confirmed,
            card_number: cardNo
        });

        if payment !is Payment {
            log:printError("Payment settlement failed", payment);
            if payment is http:ClientRequestError {
                return <http:NotFound>{body: string `unknown appointment number`};
            }
            return <http:InternalServerError>{body: payment.message()};
        }

        email:Error? sendMessage = smtpClient->sendMessage({
            to: patient.email,
            subject: "Appointment reservation confirmed at " + hospital,
            body: getEmailContent(appointmentNumber, appointment, payment)
        });

        if sendMessage is email:Error {
            return <http:InternalServerError>{body: sendMessage.message()};
        }
        log:printDebug("Email sent successfully",
                        name = patient.name,
                        appointmentNumber = appointmentNumber);
        return <http:Created>{};
    }
}

function getEmailContent(int appointmentNumber, Appointment appointment, Payment payment)
        returns string {
    return string `Appointment Confirmation

    Appointment Details
        Appointment Number : ${appointmentNumber}
        Appointment Date: ${appointment.appointmentDate}

    Patient Details
        Name : ${appointment.patient.name}
        Contact Number : ${appointment.patient.phone}

    Doctor Details
        Name : ${appointment.doctor.name}
        Specialization : ${appointment.doctor.category}

    Payment Details
        Doctor Fee : ${payment.actualFee}
        Discount : ${payment.discount}
        Total Fee : ${payment.discounted}
        Payment Status : ${payment.status}`;
}
```

### Step 3: Build and run the service

You can run this service by navigating to the project root and using the `bal run` command.

```bash
send-emails-from-a-service$ bal run
Compiling source
        integration_tutorials/send_emails_from_a_service:0.1.0

Running executable
```

### Step 4: Try out the use case

Let's test the use case by sending a request to the service.

#### Start the backend service

Download the JAR file for the backend service from the [backend service](https://github.com/ballerina-guides/integration-tutorials/blob/main/backends/hospital-service/) and execute the following command to start the service:

```bash
bal run hospitalservice.jar
```

#### Send a request

Let's send a request to the service using cURL as follows.

1. Install and set up [cURL](https://curl.se/) as your client.

2. Create a file named `request.json` with the request payload.

```json
{
    "patient": {
        "name": "John Doe",
        "dob": "1940-03-19",
        "ssn": "234-23-525",
        "address": "California",
        "phone": "8770586755",
        "email": "johndoe@gmail.com",
        "cardNo": "7844481124110331"
    },
    "doctor": "thomas collins",
    "hospital_id": "grandoaks",
    "hospital": "grand oak community hospital",
    "appointment_date": "2023-10-02"
}
```

3. Execute the following command.

```bash
curl -v -X POST --data @request.json http://localhost:8290/healthcare/categories/surgery/reserve --header "Content-Type:application/json"
```

#### Verify the email

You will receive an email similar to the following for a successful appointment reservation.

```
Appointment Confirmation

    Appointment Details
        Appointment Number : 1
        Appointment Date: 2023-10-02

    Patient Details
        Name : John Doe
        Contact Number : 8770586755

    Doctor Details
        Name : thomas collins
        Specialization : surgery

    Payment Details
        Doctor Fee : 7000.0
        Discount : 20
        Total Fee : 5600.0
        Payment Status : settled
```

## References

- [`ballerina/http` API docs](https://lib.ballerina.io/ballerina/http/latest)
- [`ballerina/email` API docs](https://lib.ballerina.io/ballerina/email/latest)
- [`ballerina/log` API docs](https://lib.ballerina.io/ballerina/log/latest)