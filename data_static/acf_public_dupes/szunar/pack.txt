-- Insert pack
INSERT INTO PackData (packid, packname, author, contact)
VALUES ('szunar', 'Szunar', 'Szunar', 'Szunar');

-- Insert dupes using the string packid
INSERT INTO DupeData (path, name, cost, weight, type, mobility, packid, description) VALUES
('leopard_2a4_v5', 'Leopard 2A4 V5', 480.7, 48625.19, 'MBT', 'Tracked', 'szunar', '
R - Unlock the turret
H - Start the engines
F - FLIR
G - Launch smoke grenades
L. Alt - Fire the coax machine gun
L - Lights
L. Shift - Change cameras
1, 2 - Change ammo type')