CREATE TABLE rooms(
  room_id number(3) PRIMARY KEY,
  number varchar2(5),
  class varchar2(30), -- vip & normal
  price_per_night number(3),
  discount number(1),
  number_single_beds number(2),
  number_double_beds number(2),
  special_addition varchar2(30)
);

CREATE TABLE reservations(
  reservation_id number(3) PRIMARY KEY,
  guest_id number(2) CONSTRAINT guest_id NOT NULL,
  id_room number(2) CONSTRAINT room_id,
  status varchar2(30), -- ordered (about 200), allocated, waiting (when there is no free room), to be settled (if the room does not respond)
  start_date DATE, 
  end_date DATE,
  date_of_arrival_at_the_hotel DATE,
  room_cost number(6),
  additional_cost number(6),
  note varchar2(255)
);

CREATE TABLE guests(
  guest_id number(3) PRIMARY KEY,
  f_name varchar2(20),
  l_name varchar2(30),
  id_number varchar2(8),
  city varchar2(20),
  street_house_number varchar2(30),
  visits_number number(4)
);

INSERT into rooms values (1, '2a', 'vip', 120, 0, 0, 1, 'balcony');
INSERT into rooms values (2, '2b', 'normal', 100, 0, 4, 0, 'balcony');
INSERT into rooms values (3, '2c', 'normal', 120, 0, 5, 1, 'pool');
INSERT into rooms values (4, '2d', 'vip', 120, 0, 3, 1, 'pool');

INSERT into guests values (1, 'ibrahim', 'Alassaf', '11012345','Jeddah','Sultanah 12-123', 1);
INSERT into guests values (2, 'Yazeed', 'Saleem', '11015375','Maddinah','Azhari 12-123', 3);
INSERT into guests values (3, 'Ahmed', 'Khalid', '11019341','Riyadh','Fisalya 12-123', 1);
INSERT into guests values (4, 'Yousef', 'Ahmed', '11055345','Dammam','Azezyah 12-123', 5);

INSERT into reservations  values (1, 2, 1, 'ordered', TO_DATE('2020/07/09', 'yyyy/mm/dd'),TO_DATE('2020/07/16', 'yyyy/mm/dd'),null , 0, 0, '');
INSERT into reservations  values (2, 1, null, 'assigned', TO_DATE('2020/05/11', 'yyyy/mm/dd'),TO_DATE('2020/05/16', 'yyyy/mm/dd'),TO_DATE('2020/05/11', 'yyyy/mm/dd'), 500, 0, 'paid');

-- enter a new guest
CREATE OR REPLACE PROCEDURE add_guest(guest_id number, fname varchar2, lname varchar2, id_number varchar2, city varchar2, street_house_number varchar2)
  IS
  BEGIN
    INSERT into guests VALUES(guest_id, f_name, l_name , id_number, city, street_house_number, 1);
END add_guest;

BEGIN
    add_guest(6, 'Mohammed','Saleh','110129','Jeddah','Safa 12/3');
END;

SELECT * FROM guests;

--writing out rooms between date d1 and d2
CREATE OR REPLACE PROCEDURE write_free_rooms(d1 DATE, d2 DATE)
  IS
  room_number varchar2(5);
  BEGIN
    SELECT rooms.number INTO room_number FROM reservations, rooms WHERE reservations.id_room = rooms.room_id AND d1 <= start_date AND d2 >= end_date;
END write_free_rooms;


BEGIN 
    write_free_rooms(TO_DATE('2020/07/09', 'yyyy/mm/dd'), TO_DATE('2020/07/16', 'yyyy/mm/dd'));
END;

--support function
CREATE OR REPLACE FUNCTION find_guest_by_id(fid_number varchar2)
  Return number is 
    id_1 number(3);
  BEGIN
     SELECT guests.guest_id INTO id_1 FROM guests WHERE id_number = fid_number;
    RETURN id_1;
  END find_guest_by_id;

  --make a reservation 
CREATE OR REPLACE PROCEDURE add_reservations(fid_number varchar2, id_room number,status varchar2, start_date DATE, end_date DATE,note varchar2)
  IS
    guest_id number(3);
    visits_number number(4);
    reservation_id number(4);
  BEGIN
    SELECT COUNT(*) INTO reservation_id FROM reservations;
    fguest_id := find_guest_by_id(fid_number);
    SELECT visits_number into visits_number1 FROM guests WHERE fguest_id = guests.guest_id;
    visits_number1 := visits_number1 + 1;
    INSERT into reservations values ((reservation_id + 1), fguest_id, id_room, status, start_date, end_date,null, null, null, note);
    UPDATE guests SET visits_number = visits_number1 WHERE guests.guest_id = fguest_id;
  END add_reservations;

  -- when guest arrive
CREATE OR REPLACE PROCEDURE hotel_request(fid_number varchar2, arrival_date date) --arrival date at hotel
  is 
   guest_id number(3);
  begin
   guest_id := find_guest_by_id(fid_number);
   UPDATE reservations SET reservations.date_of_arrival_at_the_hotel = date_of_arrival_at_the_hotel WHERE guest_id = guest_id;
END hotel_request;

--delete reservations
CREATE OR REPLACE PROCEDURE cancel_reservations(id_number varchar2)
  is 
    guest_id number(3);
  begin
    guest_id := find_guest_by_id(fid_number);
    DELETE FROM reservations WHERE reservations.guest_id = guest_id;
END cancel_reservations;

-- auxiliary function date difference | ما فهمت ايش فايدتها للامانة نحاول نفهمها لو ما فهمناها نشيلها
CREATE OR REPLACE FUNCTION diff_date(guest_id1 number)
    return number is
        starting date;
        ending date;
    begin
        SELECT data_starting into starting FROM reservations WHERE reservations.guest_id = guest_id1;
        SELECT data_ending into ending FROM reservations WHERE reservations.guest_id = guest_id1;
    return ending - starting;
END;


-- prepare a bill for the guest (by giving him a discount if he is a frequent guest)
CREATE OR REPLACE PROCEDURE bill(fid_number number, additional_cost number)
    is 
    guest_id1 number(3);
    id_room1 number(3);
    number_of_days number(3);
    cost number(6);
    visits_number number(3);
    price_per_day1 number(4);
  begin
    guest_id1 := find_guest_by_id(fid_number);
    number_of_days := diff_date(guest_id1);
    SELECT id_room INTO id_room1 FROM reservations WHERE reservations.guest_id = guest_id1;
    SELECT visits_number INTO visits_number FROM guests WHERE guest_id = guest_id1;
        IF visits_number > 5 THEN additional_cost := additional_cost * 0.6; -- discount
        ELSIF visits_number > 10 THEN additional_cost := additional_cost * 0.5; -- discount
        END IF;
        SELECT price_per_night INTO price_per_day1 FROM rooms WHERE reservations.id_room = id_room1;
    cost := number_of_days * price_per_day1 + additional_cost;
    UPDATE reservations SET room_cost = cost, note = (note + ', bill created');
    DBMS_OUTPUT.PUT_LINE('The total cost of the room:  '||cost);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('there is no data to delete');
END bill;

--  people who have made reservations and have not yet arrived on that day
CREATE OR REPLACE PROCEDURE late_person
    is
        v_date date;
    begin
    SELECT SYSDATE INTO v_date FROM dual;
    SELECT guests.f_name, guests.l_name, reservations.reservation_id FROM guests, reservations WHERE guests.guest_id = reservations.guest_id AND reservations.start_date >= v_date AND reservations.date_of_arrival_at_the_hotel != null;
END late_person;

-- procedure for each hotel guest: calculates how many times and for how long he stayed at the hotel
--and inserts this information into an empty table: Summary (guest id, name, surname, how many times, how long)
    
CREATE TABLE summary(
    guest_id number(3) PRIMARY KEY,
    fname varchar2(20),
    lname varchar2(30),
    how_many_times number(3),
    how_long number(4)
);
    
CREATE OR REPLACE PROCEDURE staying_at_hotel
    is
    how_long1 number(4);
    begin
        FOR _counter IN 1..(SELECT COUNT(guest_id) FROM guests) LOOP
            INSERT INTO summary (guest_id, fname, lname, how_many_times) SELECT f_name, l_name, visits_number FROM guests WHERE guest_id = _counter;
            how_long1 := diff_date(_counter);
            INSERT INTO summary
        END LOOP;
END;

--this procedure removes all reservations for people who stays older than five years ago
CREATE OR REPLACE PROCEDURE delete_old_reservations
    is
    l_date date;
    begin
    l_date := ADD_MONTHS (SYSDATE, -5*12); -- 5 years ago
    DELETE FROM reservations WHERE reservations.end_date < l_date;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('there is no data to delete');
END;

-- trigger checking if start date is earlier than end date
CREATE OR REPLACE TRIGGER is_the_date_correct
    BEFORE INSERT OR UPDATE OR DELETE OF start_date, end_date 
    ON reservations
    FOR EACH ROW
    BEGIN
        :NEW.start_date < :NEW.end_date;
    END;

-- trigger - the trigger updates the fields how_many_times and how_long
CREATE OR REPLACE TRIGGER field_update
    BEFORE INSERT OR UPDATE OR DELETE OF how_many_times, how_long
    ON summary
    DECLARE 
    how_much number(3);
BEGIN
    CASE
        WHEN INSERTING THEN
            how_much = :NEW.end_date - :NEW.start_date;
            UPDATE summary WHERE guest_id = :NEW.guest_id SET how_long = how_long + how_much, how_many_times = how_many_times + 1;
        WHEN DELETING
            how_much = :OLD.end_date - :OLD.start_date;
            UPDATE summary WHERE guest_id = :OLD.guest_id SET how_long = how_long - how_much, how_many_times = how_many_times - 1;
    END CASE;
END;


--Make a VIP room reservation for one night. If there is no free room
--meeting the expectations of guests among people who have made a reservation for a room
--meeting the VIP specification, select one of them - not having VIP status and replace it
--reservation for a VIP reservation. Canceled reservation for a room replace with
--ordered reservation.


--listing of free rooms d1 for VIP
CREATE OR REPLACE PROCEDURE writing_out_free_vip_rooms(d1 DATE, requirement varchar2)
  IS
  room_number varchar2(5);
  room_class varchar(20);
  BEGIN
    SELECT rooms.number, rooms.class INTO room_number, room_class FROM reservations, rooms WHERE reservations.id_room = rooms.room_id AND d1 <= start_date AND d1 >= end_date AND rooms.special_addition = requirement;
    DBMS_OUTPUT.PUT_LINE(room_number || ' ' || room_class);  
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('no data available');
END writing_out_free_vip_rooms;

-- main procedure for adding vip
CREATE OR REPLACE PROCEDURE vip_reservation(day date, requirement varchar2, number_single_beds number, number_double_beds number, id_number varchar2) -- requirement: pool, bar, balcony etc.
IS 
day1 date;
number_of_beds number(1);
number_of_double_beds number(1);
room_number varchar2(5);
room_class varchar(20);
id_room number(4);
reservation_id number(4);
guest_id number(4);
BEGIN
    SELECT rooms.number, rooms.class, rooms.room_id INTO room_number, room_class, id_room FROM reservations, rooms WHERE reservations.id_room = rooms.room_id AND d1 < reservations.start_date AND d1 >= reservations.end_date AND rooms.special_addition = requirement AND ROWNUM = 1 ;
    DBMS_OUTPUT.PUT_LINE(room_number || ' ' || room_class);
    IF room_class = 'vip' THEN
        add_reservations(fid_number,id_room, 'ordered',day, day, 'vip');
    ELSIF room_class != 'vip' THEN
        room_class := 'vip';
    ELSE
        SELECT rooms.number, reservations.reservation_id, rooms.room_id, guests.guest_id INTO room_number, reservation_id, id_room, guest_id FROM rooms, reservations, guests WHERE reservations.id_room = rooms.room_id AND rooms.special_addition = requirement AND ROWNUM = 1 ;
         add_reservations(fid_number, id_room, 'ordered',day, day, 'vip');
         UPDATE reservations SET status = 'waiting' WHERE reservations.guest_id = guest_id;
    END IF;
    EXCEPTION
WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('no data available');
END vip_reservation;