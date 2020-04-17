
CREATE TABLE rooms(
  room_id number(3) PRIMARY KEY,
  rnumber varchar2(5),
  class varchar2(30), -- vip & normal يكون ضيف عادي او مهم
  price_per_night number(3),
  discount number(1),
  number_single_beds number(2),
  number_double_beds number(2),
  special_addition varchar2(30)
);

CREATE TABLE reservations(
  reservation_id number(3) PRIMARY KEY,
  guest_id number(2) CONSTRAINT guest_id NOT NULL,
  id_room number(2) ,
  status varchar2(30), --like ordered , ordered, waiting (when there is no free room) حالة الحجز 
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

-- يضيف عميل جديد
CREATE OR REPLACE PROCEDURE add_guest(guest_id number, fname varchar2, lname varchar2, id_number varchar2, city varchar2, street_house_number varchar2)
  IS
  BEGIN
    INSERT into
    guests VALUES(guest_id, fname, lname , id_number, city, street_house_number, 1);
END add_guest;

BEGIN
    add_guest(6, 'Mohammed','Saleh','110129','Jeddah','Safa 12/3');
END;

SELECT * FROM guests;

--حجز غرف فارغة من التاريخ
-- D1 الى D2
CREATE OR REPLACE PROCEDURE write_free_rooms(d1 DATE, d2 DATE)
  IS
  room_number varchar2(5);
  BEGIN
    SELECT rooms.rnumber INTO room_number FROM reservations, rooms WHERE reservations.id_room = rooms.room_id AND d1 <= start_date AND d2 >= end_date;
END write_free_rooms;


BEGIN 
    write_free_rooms(TO_DATE('2020/07/09', 'yyyy/mm/dd'), TO_DATE('2020/07/16', 'yyyy/mm/dd'));
END;

--البحث عن العميل عن طريق الاي دي نمبر ويرجعه لنا العميل
CREATE OR REPLACE FUNCTION find_guest_by_id(fid_number varchar2)
  Return number is 
    id_1 number(3);
  BEGIN
     SELECT guests.guest_id INTO id_1 FROM guests WHERE id_number = fid_number;
    RETURN id_1;
  END find_guest_by_id;
  

  --عمل حجز في الداتابيز 
CREATE OR REPLACE PROCEDURE add_reservations(fid_number varchar2, id_room number,status varchar2, start_date DATE, end_date DATE,note varchar2)
  IS
    guest_id number(3);
    fguest_id number(3);
    visits_number number(4);
    reservation_id number(4);
  BEGIN
    SELECT COUNT(*) INTO reservation_id FROM reservations;
    fguest_id := find_guest_by_id(fid_number);
    SELECT visits_number into visits_number FROM guests WHERE fguest_id = guests.guest_id;
    visits_number := visits_number + 1;
    INSERT into reservations values ((reservation_id + 1), fguest_id, id_room, status, start_date, end_date,null, null, null, note);
    UPDATE guests SET visits_number = visits_number WHERE guests.guest_id = fguest_id;
  END add_reservations;


-- اذا العميل وصل نسوي ريكويست
CREATE OR REPLACE PROCEDURE hotel_request(fid_number varchar2, arrival_date date) --تاريخ الوصول للهوتيل
  is 
   guest_id number(3);
  begin
   guest_id := find_guest_by_id(fid_number);
   UPDATE reservations SET reservations.date_of_arrival_at_the_hotel = date_of_arrival_at_the_hotel WHERE guest_id = guest_id;
END hotel_request;

--حذف الحجز
CREATE OR REPLACE PROCEDURE cancel_reservations(fid_number varchar2)
  is 
    guest_id number(3);
  begin
    guest_id := find_guest_by_id(fid_number);
    DELETE FROM reservations WHERE reservations.guest_id = guest_id;
END cancel_reservations;

-- يرجع لنا عدد الايام اللي قعد فيها العميل في الفندق 
CREATE OR REPLACE FUNCTION diff_date(guest_id1 number)
    return number is
        starting date;
        ending date;
    begin
        SELECT start_date into starting FROM reservations WHERE reservations.guest_id = guest_id1;
        SELECT end_date into ending FROM reservations WHERE reservations.guest_id = guest_id1;
    return ending - starting;
END;


-- يجهز الفاتورة للعميل (ولو كان عميل دائم يعطيه ديسكاونت) ا
CREATE OR REPLACE PROCEDURE bill(fid_number number, fadditional_cost number)
    is 
    guest_id1 number(3);
    id_room1 number(3);
    number_of_days number(3);
    cost number(6);
    visits_number number(3);
    price_per_day1 number(4);
    additional_cost number(5);
  begin
    guest_id1 := find_guest_by_id(fid_number);
    number_of_days := diff_date(guest_id1);
    SELECT id_room INTO id_room1 FROM reservations WHERE reservations.guest_id = guest_id1;
    SELECT visits_number INTO visits_number FROM guests WHERE guest_id = guest_id1;
        IF visits_number > 5 THEN additional_cost := fadditional_cost * 0.6; -- خصم
        ELSIF visits_number > 10 THEN additional_cost := fadditional_cost * 0.5; -- خصم
        END IF;
        SELECT price_per_night INTO price_per_day1 FROM rooms,reservations WHERE reservations.id_room = id_room1;
    cost := number_of_days * price_per_day1 + fadditional_cost;
    UPDATE reservations SET room_cost = cost, note = (note + ', bill created');
    DBMS_OUTPUT.PUT_LINE('The total cost of the room:  '||cost);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('there is no data to delete');
END bill;

--  الناس اللي عملت حجز وما وصلت المتأخرين بشكل  عام
CREATE OR REPLACE PROCEDURE late_person
    is
        v_date date;
    begin
    SELECT SYSDATE INTO v_date FROM dual;
    SELECT guests.f_name, guests.l_name, reservations.reservation_id FROM guests, reservations WHERE guests.guest_id = reservations.guest_id AND reservations.start_date >= v_date AND reservations.date_of_arrival_at_the_hotel != null;
END late_person;

-- بروسيجر لكل عميل في الهوتيل: يحسب كم مره جا وكم يوم قاعد لكن حاليا مو راضيه تشتغل 
--ويحط المعلومات ذي كلها في تيبل فارغ اللي هوا
-- Summary (guest id, name, surname, how many times, how long)
    
CREATE TABLE summary(
    guest_id number(3) PRIMARY KEY,
    f_name varchar2(20),
    l_name varchar2(30),
    how_many_times number(3),
    how_long number(4)
);
--مو راضي يشتغل   
CREATE OR REPLACE PROCEDURE staying_at_hotel
    is
    how_long1 number(4);
    begin
        FOR guest_id1 IN ((select COUNT(guest_id) FROM guests)) loop
            INSERT INTO summary (guest_id, f_name, l_name, how_many_times)
            SELECT f_name, l_name, visits_number FROM guests WHERE guest_id = guest_id1;
            how_long1 := diff_date(guest_id1);
        END loop;
END;

-- هذا البروسيجر يشيل كل الحجوزات اللي اكثر من 5 سنين
CREATE OR REPLACE PROCEDURE delete_old_reservations
    is
    l_date date;
    begin
    l_date := ADD_MONTHS (SYSDATE, -5*12); -- قبل 5 سنين
    DELETE FROM reservations WHERE reservations.end_date < l_date;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('there is no data to delete');
END;


-- في مشكلة في التريقر ذا مو عارف ليش مع انه المفروض صح
-- التريقر - التريقر ذا يحدث الخانتين
-- how_many_times and how_long
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


--جدول يوزر ريمايندر للتريقير.
 
CREATE TABLE USER_REMINDERS
(
	GUEST_ID number(10),
	REMINDER_TEXT varchar2(200),
	REMINDER_DATE date,
	STATUS varchar2(10)
);

-- تريقر لاضافه الاي دي حق القيست  وايضا الهوية حقته 

CREATE OR REPLACE TRIGGER trg_after_insert
AFTER INSERT
  on guests
  FOR EACH ROW 

DECLARE
counter number(2);
reminder_text varchar2(200);

BEGIN
counter := 0;
reminder_text := '';

  IF(:NEW.guest_id = '' OR :NEW.guest_id is null) THEN
  reminder_text := 'Please insert guest id into system. ';
  counter := counter+1;
  END IF;  
  
  IF(:NEW.id_number = '' OR :NEW.id_number is null) THEN
  reminder_text := reminder_text || 'Please insert your id number into system.';
  counter := counter+1;
  END IF;  

  -- اذا واحد منهم غير موجود الكاونتر راح يكون اكبر من صفر وراح يضيف هالشيء للتيبل حق الريمايندر
  IF(counter>0) THEN
  INSERT INTO USER_REMINDERS VALUES (:NEW.GUEST_ID,reminder_text,sysdate+3,'PENDING');
  END IF;
    
END;
/


---- باكج لاضافه العميل ويتأكد من الغرف الفاضية ويعمل له حجز
---- The package Specification
CREATE OR REPLACE PACKAGE gus_rev AS  
--هنا يضيف العميل
   PROCEDURE add_guest(guest_id number, fname varchar2, lname varchar2, id_number varchar2, city varchar2, street_house_number varchar2)
--يتأكد اذا فيه غرف فاضية
PROCEDURE write_free_rooms(d1 DATE, d2 DATE)
--يحجز للعميل
 PROCEDURE add_reservations(fid_number varchar2, id_room number,status varchar2, start_date DATE, end_date DATE,note varchar2)

END gus_rev; 
/

---- The package Body
CREATE OR REPLACE PACKAGE BODY gus_rev AS  
--
  PROCEDURE add_guest(guest_id number, fname varchar2, lname varchar2, id_number varchar2, city varchar2, street_house_number varchar2)
  IS
  BEGIN
    INSERT into
    guests VALUES(guest_id, fname, lname , id_number, city, street_house_number, 1);
END add_guest;
--
 PROCEDURE write_free_rooms(d1 DATE, d2 DATE)
  IS
  room_number varchar2(5);
  BEGIN
    SELECT rooms.rnumber INTO room_number FROM reservations, rooms WHERE reservations.id_room = rooms.room_id AND d1 <= start_date AND d2 >= end_date;
END write_free_rooms;
--
PROCEDURE add_reservations(fid_number varchar2, id_room number,status varchar2, start_date DATE, end_date DATE,note varchar2)
  IS
    guest_id number(3);
    fguest_id number(3);
    visits_number number(4);
    reservation_id number(4);
  BEGIN
    SELECT COUNT(*) INTO reservation_id FROM reservations;
    fguest_id := find_guest_by_id(fid_number);
    SELECT visits_number into visits_number FROM guests WHERE fguest_id = guests.guest_id;
    visits_number := visits_number + 1;
    INSERT into reservations values ((reservation_id + 1), fguest_id, id_room, status, start_date, end_date,null, null, null, note);
    UPDATE guests SET visits_number = visits_number WHERE guests.guest_id = fguest_id;
  END add_reservations;

END gus_rev; 
/