create table gus_xml (xml_ID number , xml_data xmltype);

insert into gus_xml VALUES (10000, '<?xml version="1.0" encoding="UTF-8"?> 
<guests>
<guest_id>1</guest_id>
<f_name>ibrahim</f_name>
<l_name>Alassaf</l_name>
<id_number>11012345</id_number>
<city>Jeddah</city>
<street_house_number>Sultanah 12-123</street_house_number>
<visits_number>1</visits_number>
</guests> 
');

insert into gus_xml VALUES (20000, '<?xml version="1.0" encoding="UTF-8"?> 
<guests>
<guest_id>2</guest_id>
<f_name>Yazeed</f_name>
<l_name>Saleem</l_name>
<id_number>11015375</id_number>
<city>Maddinah</city>
<street_house_number>Azhari 12-123</street_house_number>
<visits_number>3</visits_number>
</guests> ');

insert into gus_xml VALUES (30000, '<?xml version="1.0" encoding="UTF-8"?> 
<guests>
<guest_id>3</guest_id>
<f_name>Ahmed</f_name>
<l_name>Khalid</l_name>
<id_number>11019341</id_number>
<city>Riyadh</city>
<street_house_number>Fisalya 12-123</street_house_number>
<visits_number>1</visits_number>
</guests> ');

insert into gus_xml VALUES (40000, '<?xml version="1.0" encoding="UTF-8"?> 
<guests>
<guest_id>4</guest_id>
<f_name>Yousef</f_name>
<l_name>Ahmed</l_name>
<id_number>11055345</id_number>
<city>Dammam</city>
<street_house_number>Azezyah 12-123</street_house_number>
<visits_number>5</visits_number>
</guests> ');

create table gus (guest_id number(3) ,f_name varchar2(20) ,l_name varchar2(30),id_number varchar2(8),city varchar2(20),street_house_number varchar2(30),visits_number number(4)); 

insert into gus(guest_id ,f_name,l_name,id_number,city,street_house_number,visits_number);
SELECT gus.* FROM gus_xml x,
XMLTABLE(
            '/guests' 
            PASSING X.xml_data
            COLUMNS 
            "guest_id" NUMBER(3) PATH 'guest_id', 
            "f_name" varchar2(20) PATH 'f_name',
			"l_name" varchar2(30) PATH 'l_name',
			"id_number" varchar2(8) PATH 'id_number',
			"city" varchar2(20) PATH 'city',
            "street_house_number" varchar2(30) PATH 'street_house_number',
            "visits_number" number(4) PATH 'visits_number',)gus; 
            SELECT * FROM gus;
			



