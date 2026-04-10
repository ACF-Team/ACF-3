-- Insert pack
INSERT INTO PackData (packid, packname, author, contact)
VALUES ('ushanka', 'Ushanka', 'ThatUshankaGuy', 'ThatUshankaGuy');

-- Insert dupes using the string packid
INSERT INTO DupeData (path, name, cost, weight, type, mobility, packid, description) VALUES
('f4u', 'Vought F4U Corsair', 51.57, 3677.79, 'Fighter', 'Fin Aircraft', 'ushanka', '
REQUIRES FIN 3 ADDON

Shift/Ctrl is throttle
A/D is roll
Mouse1/2 is rudder
Mouse down/up is pitch
keep F pressed for flaps but they create more drag than lift at this point, so just use them for landing')