CREATE OR REPLACE PACKAGE vehicle_service
AS
	PROCEDURE AddNewTechnician(i_name IN technicians.technician_name%TYPE, i_field IN technicians.technician_field%TYPE, i_phone_number IN technicians.technician_phone_number%TYPE);
	PROCEDURE AddNewVehicle(i_license_plate IN vehicles.vehicle_license_plate%TYPE, i_make IN vehicles.vehicle_make%TYPE, i_model IN vehicles.vehicle_model%TYPE);
	PROCEDURE AddNewCustomer(i_name IN customers.customer_name%TYPE, i_address IN customers.customer_address%TYPE, i_phone_number IN customers.customer_phone_number%TYPE, i_vehicle_license_plate IN customers.vehicle_license_plate%TYPE);
	PROCEDURE AddNewAppointment(i_phone_number IN appointments.technician_phone_number%TYPE, i_vehicle_license_plate IN appointments.vehicle_license_plate%TYPE, i_timestamp IN appointments.appointment_timestamp%TYPE);
	FUNCTION getAllTechnicians RETURN SYS_REFCURSOR;
	FUNCTION getAllVehicles RETURN SYS_REFCURSOR;
	FUNCTION getAllCustomers RETURN SYS_REFCURSOR;
	FUNCTION getTechnicianNameFromNumber(i_phone_number IN technicians.technician_phone_number%TYPE) RETURN technicians.technician_name%TYPE;
	FUNCTION getCustomerNameFromVehicleLicensePlate(i_license_plate IN vehicles.vehicle_license_plate%TYPE) RETURN customers.customer_name%TYPE;
	FUNCTION getCustomerPhoneNumberFromVehicleLicensePlate(i_license_plate IN vehicles.vehicle_license_plate%TYPE) RETURN customers.customer_phone_number%TYPE;
	FUNCTION getAllAppointments RETURN SYS_REFCURSOR;
	FUNCTION getTechnicianFieldFromNumber(i_phone_number IN technicians.technician_phone_number%TYPE) RETURN technicians.technician_field%TYPE;
	FUNCTION getVehicleMakeFromVehicleLicensePlate(i_license_plate IN vehicles.vehicle_license_plate%TYPE) RETURN vehicles.vehicle_make%TYPE;
	FUNCTION getAllTechniciansSignedToVehicle(i_vehicle_license_plate vehicles.vehicle_license_plate%TYPE) RETURN SYS_REFCURSOR;
	FUNCTION getVehicleModelFromVehicleLicensePlate(i_license_plate IN vehicles.vehicle_license_plate%TYPE) RETURN vehicles.vehicle_model%TYPE;
	FUNCTION getCustomerAddressFromVehicleLicensePlate(i_license_plate IN vehicles.vehicle_license_plate%TYPE) RETURN customers.customer_address%TYPE;
	FUNCTION getAllVehiclesWithOwnersSignedToTechnician(i_phone_number IN technicians.technician_phone_number%TYPE) RETURN SYS_REFCURSOR;
	FUNCTION checkTimestampExistsFromDate(i_date IN VARCHAR2) RETURN NUMBER;
	FUNCTION getAllVehiclesWithOwnersOnSpecificDate(i_date IN VARCHAR2) RETURN SYS_REFCURSOR;
	PROCEDURE RemoveExistingAppointment(i_vehicle_license_plate appointments.vehicle_license_plate%TYPE);
	PROCEDURE RemoveExistingCustomer(i_phone_number IN customers.customer_phone_number%TYPE DEFAULT NULL, i_vehicle_license_plate customers.vehicle_license_plate%TYPE DEFAULT NULL);
	PROCEDURE RemoveExistingTechnician(i_phone_number IN technicians.technician_phone_number%TYPE);
	PROCEDURE RemoveExistingVehicle(i_vehicle_license_plate IN vehicles.vehicle_license_plate%TYPE);
END vehicle_service;
/
CREATE OR REPLACE PACKAGE BODY vehicle_service
AS
	--AddNewTechnician
	PROCEDURE AddNewTechnician(i_name IN technicians.technician_name%TYPE, i_field IN technicians.technician_field%TYPE, i_phone_number IN technicians.technician_phone_number%TYPE)
	AS
		v_technician_exists NUMBER;
		v_phone_number_taken_by_customer NUMBER;
	BEGIN 
		SELECT COUNT(*) INTO v_technician_exists FROM technicians WHERE i_phone_number = technician_phone_number;
		SELECT COUNT(*) INTO v_phone_number_taken_by_customer FROM customers WHERE i_phone_number = customer_phone_number;
		IF v_technician_exists > 0 THEN
			DBMS_OUTPUT.PUT_LINE('This phone number is already used by an existing technician.');
		ELSIF v_phone_number_taken_by_customer > 0 THEN
			DBMS_OUTPUT.PUT_LINE('This phone number is already used by an existing customer.');
		ELSE
			INSERT INTO technicians(technician_name, technician_field, technician_phone_number) VALUES (i_name, i_field, i_phone_number);
			DBMS_OUTPUT.PUT_LINE('Technician successfully added to the database.');
		END IF;
	END AddNewTechnician;
	
	--AddNewVehicle
	PROCEDURE AddNewVehicle(i_license_plate IN vehicles.vehicle_license_plate%TYPE, i_make IN vehicles.vehicle_make%TYPE, i_model IN vehicles.vehicle_model%TYPE)
	AS
		v_vehicle_exists NUMBER;
	BEGIN 
		SELECT COUNT(*) INTO v_vehicle_exists FROM vehicles WHERE i_license_plate = vehicle_license_plate;
		IF v_vehicle_exists > 0 THEN
			DBMS_OUTPUT.PUT_LINE('A vehicle with this license plate already exists in the database.');
		ELSE
			INSERT INTO vehicles(vehicle_license_plate, vehicle_make, vehicle_model) VALUES (i_license_plate, i_make, i_model);
			DBMS_OUTPUT.PUT_LINE('Vehicle successfully added to the database.');
		END IF;
	END AddNewVehicle;
	
	--AddNewCustomer
	PROCEDURE AddNewCustomer(i_name IN customers.customer_name%TYPE, i_address IN customers.customer_address%TYPE, i_phone_number IN customers.customer_phone_number%TYPE, i_vehicle_license_plate IN customers.vehicle_license_plate%TYPE)
	AS
		v_customer_exists NUMBER;
		v_phone_number_taken_by_technician NUMBER;
		v_license_plate_exists NUMBER;
		CHECK_CONSTRAINT_VIOLATED EXCEPTION;
		PRAGMA EXCEPTION_INIT(CHECK_CONSTRAINT_VIOLATED, -2291);
	BEGIN 
		SELECT COUNT(*) INTO v_customer_exists FROM customers WHERE i_phone_number = customer_phone_number;
		SELECT COUNT(*) INTO v_phone_number_taken_by_technician FROM technicians WHERE i_phone_number = technician_phone_number;
		IF v_customer_exists > 0 THEN
			DBMS_OUTPUT.PUT_LINE('This phone number is already used by an existing customer.');
		ELSIF v_phone_number_taken_by_technician > 0 THEN
			DBMS_OUTPUT.PUT_LINE('This phone number is already used by an existing technician.');
		ELSE
			SELECT COUNT(*) INTO v_license_plate_exists FROM customers WHERE vehicle_license_plate = i_vehicle_license_plate;
			IF v_license_plate_exists > 0 THEN
				DBMS_OUTPUT.PUT_LINE('This license plate is already used by another customer''s vehicle.');
			ELSE
				INSERT INTO customers(customer_name, customer_address, customer_phone_number, vehicle_license_plate) VALUES (i_name, i_address, i_phone_number, i_vehicle_license_plate);
				DBMS_OUTPUT.PUT_LINE('Customer successfully added to the database.');
			END IF;
		END IF;
		EXCEPTION
			WHEN CHECK_CONSTRAINT_VIOLATED THEN
				DBMS_OUTPUT.PUT_LINE('No vehicle with the given license plate exists in the database.');
	END AddNewCustomer;
	
	--AddNewAppointment
	PROCEDURE AddNewAppointment(i_phone_number IN appointments.technician_phone_number%TYPE, i_vehicle_license_plate IN appointments.vehicle_license_plate%TYPE, i_timestamp IN appointments.appointment_timestamp%TYPE)
	AS
		v_appointment_exists NUMBER;
		v_technician_exists NUMBER;
		v_vehicle_exists NUMBER;
		v_vehicle_has_owner NUMBER;
		NOT_TECHNICIAN_EXISTS EXCEPTION;
		NOT_VEHICLE_EXISTS EXCEPTION;
		NOT_VEHICLE_OWNER EXCEPTION;
	BEGIN 
		SELECT COUNT(*) INTO v_appointment_exists FROM appointments WHERE (i_phone_number = technician_phone_number AND i_vehicle_license_plate = vehicle_license_plate) OR i_timestamp = appointment_timestamp;
		SELECT COUNT(*) INTO v_technician_exists FROM technicians WHERE i_phone_number = technician_phone_number;
		SELECT COUNT(*) INTO v_vehicle_exists FROM vehicles WHERE i_vehicle_license_plate = vehicle_license_plate;
		SELECT COUNT(*) INTO v_vehicle_has_owner FROM customers WHERE i_vehicle_license_plate = vehicle_license_plate;
		IF v_technician_exists = 0 THEN
			RAISE NOT_TECHNICIAN_EXISTS;
		END IF;
		IF v_vehicle_exists = 0 THEN
			RAISE NOT_VEHICLE_EXISTS;
		END IF;
		IF v_vehicle_has_owner = 0 THEN
			RAISE NOT_VEHICLE_OWNER;
		END IF;
		IF v_appointment_exists > 0 THEN
			DBMS_OUTPUT.PUT_LINE('This appointment already exists in the database.');
		ELSE
			INSERT INTO appointments(technician_phone_number, vehicle_license_plate, appointment_timestamp) VALUES (i_phone_number, i_vehicle_license_plate, i_timestamp);
			DBMS_OUTPUT.PUT_LINE('Appointment successfully added to the database.');
		END IF;
		EXCEPTION
			WHEN NOT_TECHNICIAN_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Technician with this phone number does not exist in the database.');
			WHEN NOT_VEHICLE_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Vehicle with this license plate does not exist in the database.');
			WHEN NOT_VEHICLE_OWNER THEN
				DBMS_OUTPUT.PUT_LINE('This vehicle does not have an owner assigned to it.');
	END AddNewAppointment;
	
	--getAllTechnicians
	FUNCTION getAllTechnicians RETURN SYS_REFCURSOR AS cur SYS_REFCURSOR; 
	BEGIN 
		OPEN cur FOR SELECT * FROM technicians;
		RETURN cur; 
	END getAllTechnicians;
	
	--getAllVehicles
	FUNCTION getAllVehicles RETURN SYS_REFCURSOR AS cur SYS_REFCURSOR;
	BEGIN 
		OPEN cur FOR SELECT * FROM vehicles;
		RETURN cur; 
	END getAllVehicles;
	
	--getAllCustomers
	FUNCTION getAllCustomers RETURN SYS_REFCURSOR AS cur SYS_REFCURSOR;
	BEGIN 
		OPEN cur FOR SELECT * FROM customers;
		RETURN cur; 
	END getAllCustomers;
	
	--getTechnicianNameFromNumber
	FUNCTION getTechnicianNameFromNumber(i_phone_number IN technicians.technician_phone_number%TYPE) RETURN technicians.technician_name%TYPE AS tech_name technicians.technician_name%TYPE;
	BEGIN 
		SELECT technician_name INTO tech_name FROM technicians WHERE technician_phone_number = i_phone_number;
		RETURN tech_name;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN '';
	END getTechnicianNameFromNumber;
	
	--getCustomerNameFromVehicleLicensePlate
	FUNCTION getCustomerNameFromVehicleLicensePlate(i_license_plate IN vehicles.vehicle_license_plate%TYPE) RETURN customers.customer_name%TYPE AS owner_name customers.customer_name%TYPE;
	BEGIN 
		SELECT customer_name INTO owner_name FROM customers WHERE vehicle_license_plate = i_license_plate;
		RETURN owner_name;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN '';
	END getCustomerNameFromVehicleLicensePlate;
	
	--getCustomerPhoneNumberFromVehicleLicensePlate
	FUNCTION getCustomerPhoneNumberFromVehicleLicensePlate(i_license_plate IN vehicles.vehicle_license_plate%TYPE) RETURN customers.customer_phone_number%TYPE AS owner_phone_number customers.customer_phone_number%TYPE;
	BEGIN 
		SELECT customer_phone_number INTO owner_phone_number FROM customers WHERE vehicle_license_plate = i_license_plate;
		RETURN owner_phone_number;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN '';
	END getCustomerPhoneNumberFromVehicleLicensePlate;
	
	--getAllAppointments
	FUNCTION getAllAppointments RETURN SYS_REFCURSOR AS cur SYS_REFCURSOR;
	BEGIN 
		OPEN cur FOR SELECT * FROM appointments;
		RETURN cur; 
	END getAllAppointments;
	
	--getTechnicianFieldFromNumber
	FUNCTION getTechnicianFieldFromNumber(i_phone_number IN technicians.technician_phone_number%TYPE) RETURN technicians.technician_field%TYPE AS tech_field technicians.technician_field%TYPE;
	BEGIN 
		SELECT technician_field INTO tech_field FROM technicians WHERE technician_phone_number = i_phone_number;
		RETURN tech_field;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN '';
	END getTechnicianFieldFromNumber;
	
	--getVehicleMakeFromVehicleLicensePlate
	FUNCTION getVehicleMakeFromVehicleLicensePlate(i_license_plate IN vehicles.vehicle_license_plate%TYPE) RETURN vehicles.vehicle_make%TYPE AS veh_make vehicles.vehicle_make%TYPE;
	BEGIN 
		SELECT vehicle_make INTO veh_make FROM vehicles WHERE vehicle_license_plate = i_license_plate;
		RETURN veh_make;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN '';
	END getVehicleMakeFromVehicleLicensePlate;
	
	--getAllTechniciansSignedToVehicle
	FUNCTION getAllTechniciansSignedToVehicle(i_vehicle_license_plate vehicles.vehicle_license_plate%TYPE) RETURN SYS_REFCURSOR AS cur SYS_REFCURSOR;
	BEGIN
		OPEN cur FOR SELECT * FROM appointments WHERE vehicle_license_plate = i_vehicle_license_plate;
		RETURN cur; 
	END getAllTechniciansSignedToVehicle;
	
	--getVehicleModelFromVehicleLicensePlate
	FUNCTION getVehicleModelFromVehicleLicensePlate(i_license_plate IN vehicles.vehicle_license_plate%TYPE) RETURN vehicles.vehicle_model%TYPE AS veh_model vehicles.vehicle_model%TYPE;
	BEGIN 
		SELECT vehicle_model INTO veh_model FROM vehicles WHERE vehicle_license_plate = i_license_plate;
		RETURN veh_model;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN '';
	END getVehicleModelFromVehicleLicensePlate;
	
	--getCustomerAddressFromVehicleLicensePlate
	FUNCTION getCustomerAddressFromVehicleLicensePlate(i_license_plate IN vehicles.vehicle_license_plate%TYPE) RETURN customers.customer_address%TYPE AS owner_address customers.customer_address%TYPE;
	BEGIN 
		SELECT customer_address INTO owner_address FROM customers WHERE vehicle_license_plate = i_license_plate;
		RETURN owner_address;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN '';
	END getCustomerAddressFromVehicleLicensePlate;
	
	--getAllVehiclesWithOwnersSignedToTechnician
	FUNCTION getAllVehiclesWithOwnersSignedToTechnician(i_phone_number IN technicians.technician_phone_number%TYPE) RETURN SYS_REFCURSOR AS cur SYS_REFCURSOR;
	BEGIN 
		OPEN cur FOR SELECT * FROM appointments WHERE technician_phone_number = i_phone_number;
		RETURN cur;
	END getAllVehiclesWithOwnersSignedToTechnician;
	
	--checkTimestampExistsFromDate
	FUNCTION checkTimestampExistsFromDate(i_date IN VARCHAR2) RETURN NUMBER AS appointment_exists NUMBER;
	BEGIN 
		SELECT COUNT(*) INTO appointment_exists FROM appointments WHERE SUBSTR(appointment_timestamp, 0, 9) = SUBSTR(TO_TIMESTAMP(i_date, 'DD.MM.YYYY'), 0, 9);
		RETURN appointment_exists;
	END checkTimestampExistsFromDate;
	
	--getAllVehiclesWithOwnersOnSpecificDate
	FUNCTION getAllVehiclesWithOwnersOnSpecificDate(i_date IN VARCHAR2) RETURN SYS_REFCURSOR AS cur SYS_REFCURSOR;
	BEGIN 
		OPEN cur FOR SELECT * FROM appointments WHERE SUBSTR(appointment_timestamp, 0, 9) = SUBSTR(TO_TIMESTAMP(i_date, 'DD.MM.YYYY'), 0, 9);
		RETURN cur;
	END getAllVehiclesWithOwnersOnSpecificDate;
	
	--RemoveExistingAppointment
	PROCEDURE RemoveExistingAppointment(i_vehicle_license_plate appointments.vehicle_license_plate%TYPE)
	AS
		v_appointment_exists NUMBER;
		v_vehicle_exists NUMBER;
		NOT_VEHICLE_EXISTS EXCEPTION;
	BEGIN 
		SELECT COUNT(*) INTO v_appointment_exists FROM appointments WHERE vehicle_license_plate = i_vehicle_license_plate;
		SELECT COUNT(*) INTO v_vehicle_exists FROM vehicles WHERE i_vehicle_license_plate = vehicle_license_plate;
		IF v_vehicle_exists = 0 THEN
			RAISE NOT_VEHICLE_EXISTS;
		END IF;
		IF v_appointment_exists > 0 THEN
			DELETE FROM appointments WHERE vehicle_license_plate = i_vehicle_license_plate;
			DBMS_OUTPUT.PUT_LINE('Appointment successfully removed from the database.');
		ELSE
			DBMS_OUTPUT.PUT_LINE('No such appointment exists in the database.');
		END IF;
		EXCEPTION
			WHEN NOT_VEHICLE_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('No vehicle with the given license plate exists in the database.');
	END RemoveExistingAppointment;
	
	--RemoveExistingCustomer
	PROCEDURE RemoveExistingCustomer(i_phone_number IN customers.customer_phone_number%TYPE DEFAULT NULL, i_vehicle_license_plate customers.vehicle_license_plate%TYPE DEFAULT NULL)
	AS
		v_customer_exists NUMBER;
		v_vehicle_license_plate customers.vehicle_license_plate%TYPE;
	BEGIN 
		IF (i_phone_number IS NULL AND i_vehicle_license_plate IS NULL) OR (i_phone_number IS NOT NULL AND i_vehicle_license_plate IS NOT NULL) THEN
			DBMS_OUTPUT.PUT_LINE('Please input either customer phone number or vehicle license plate.');
			RETURN;
		END IF;
		IF i_phone_number IS NOT NULL THEN
			SELECT COUNT(*) INTO v_customer_exists FROM customers WHERE customer_phone_number = i_phone_number;
		ELSIF i_vehicle_license_plate IS NOT NULL THEN
			SELECT COUNT(*) INTO v_customer_exists FROM customers WHERE vehicle_license_plate = i_vehicle_license_plate;
		END IF;
		IF v_customer_exists > 0 THEN
			IF i_phone_number IS NOT NULL THEN
				SELECT vehicle_license_plate INTO v_vehicle_license_plate FROM customers WHERE customer_phone_number = i_phone_number;
			ELSIF i_vehicle_license_plate IS NOT NULL THEN
				SELECT vehicle_license_plate INTO v_vehicle_license_plate FROM customers WHERE vehicle_license_plate = i_vehicle_license_plate;
			END IF;
			DELETE FROM customers WHERE vehicle_license_plate = v_vehicle_license_plate;
			DELETE FROM appointments WHERE vehicle_license_plate = v_vehicle_license_plate;
			DELETE FROM vehicles WHERE vehicle_license_plate = v_vehicle_license_plate;
			DBMS_OUTPUT.PUT_LINE('Customer successfully removed from the database.');
		ELSE
			IF i_phone_number IS NOT NULL THEN
				DBMS_OUTPUT.PUT_LINE('Customer with this phone number does not exist in the database.');
			ELSIF i_vehicle_license_plate IS NOT NULL THEN
				DBMS_OUTPUT.PUT_LINE('Customer with this license plate does not exist in the database.');
			END IF;
		END IF;
	END RemoveExistingCustomer;
	
	--RemoveExistingTechnician
	PROCEDURE RemoveExistingTechnician(i_phone_number IN technicians.technician_phone_number%TYPE)
	AS
		v_technician_exists NUMBER;
		v_appointments_exist NUMBER;
		v_extra_text VARCHAR2(22) := '';
	BEGIN 
		SELECT COUNT(*) INTO v_technician_exists FROM technicians WHERE technician_phone_number = i_phone_number;
		IF v_technician_exists > 0 THEN
			SELECT COUNT(*) INTO v_appointments_exist FROM appointments WHERE technician_phone_number = i_phone_number;
			IF v_appointments_exist > 0 THEN
				DELETE FROM appointments WHERE technician_phone_number = i_phone_number;
				v_extra_text := 'and their appointments ';
			END IF;
			DELETE FROM technicians WHERE technician_phone_number = i_phone_number;
			DBMS_OUTPUT.PUT_LINE('Technician ' || v_extra_text || 'successfully removed from the database.');
		ELSE
			DBMS_OUTPUT.PUT_LINE('Technician with this phone number does not exist in the database.');
		END IF;
	END RemoveExistingTechnician;
	
	--RemoveExistingVehicle
	PROCEDURE RemoveExistingVehicle(i_vehicle_license_plate IN vehicles.vehicle_license_plate%TYPE)
	AS
		v_vehicle_exists NUMBER;
		v_customer_exists NUMBER;
	BEGIN 
		SELECT COUNT(*) INTO v_vehicle_exists FROM vehicles WHERE vehicle_license_plate = i_vehicle_license_plate;
		IF v_vehicle_exists > 0 THEN
			SELECT COUNT(*) INTO v_customer_exists FROM customers WHERE vehicle_license_plate = i_vehicle_license_plate;
			IF v_customer_exists > 0 THEN
				DBMS_OUTPUT.PUT_LINE('Cannot remove vehicle as it is linked to an existing customer.');
			ELSE
				DELETE FROM vehicles WHERE vehicle_license_plate = i_vehicle_license_plate;
				DBMS_OUTPUT.PUT_LINE('Vehicle successfully removed from the database.');
			END IF;
		ELSE
			DBMS_OUTPUT.PUT_LINE('No vehicle with the given license plate exists in the database.');
		END IF;
	END RemoveExistingVehicle;
END vehicle_service;