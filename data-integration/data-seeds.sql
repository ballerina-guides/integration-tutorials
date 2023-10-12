-- Description: This file contains the data seeds for the database

-- Add Employee data to the database
INSERT INTO `Employee` (id, name, age, phone, email, department) VALUES (1, 'John Doe', 22, '8770586755', 'johndoe@gmail.com', 'IT');
INSERT INTO `Employee` (id, name, age, phone, email, department) VALUES (2, 'Thomas Collins', 25, '8878965467', 'thomascollins@gmail.com', 'IT');
INSERT INTO `Employee` (id, name, age, phone, email, department) VALUES (3, 'Mary Taylor', 24, '9876543210', 'marytaylor@gmail.com', 'IT');

-- Add Employee task data to the database
INSERT INTO `EmployeeTask` (taskId, taskName, description, status, employeeId) VALUES (1001, 'Update Server Security', 'Implement the latest security patches and configurations', 'IN_PROGRESS', 1);
INSERT INTO `EmployeeTask` (taskId, taskName, description, status, employeeId) VALUES (1002, 'Network Optimization', 'Analyze network performance', 'NOT_STARTED', 1);
INSERT INTO `EmployeeTask` (taskId, taskName, description, status, employeeId) VALUES (1003, 'Database Migration', 'Migrate database from MySQL to PostgreSQL', 'COMPLETED', 1);
INSERT INTO `EmployeeTask` (taskId, taskName, description, status, employeeId) VALUES (1004, 'Update Server Security', 'Conduct a comprehensive audit of software licenses', 'COMPLETED', 2);
INSERT INTO `EmployeeTask` (taskId, taskName, description, status, employeeId) VALUES (1005, 'Firewall Configuration Review', 'Review and update firewall rules to enhance security', 'NOT_STARTED', 2);
INSERT INTO `EmployeeTask` (taskId, taskName, description, status, employeeId) VALUES (1006, 'Network Optimization', 'Analyze network performance', 'IN_PROGRESS', 3);
INSERT INTO `EmployeeTask` (taskId, taskName, description, status, employeeId) VALUES (1007, 'Mobile App Testing', 'Perform thorough testing and quality assurance checks', 'NOT_STARTED', 3);
