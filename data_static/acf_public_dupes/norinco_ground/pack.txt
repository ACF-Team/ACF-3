-- Insert pack
INSERT INTO PackData (packid, packname, author, contact)
VALUES ('norinco_ground', 'Norinco Ground', 'Len', 'lengthened_gradient');

-- Insert dupes using the string packid
INSERT INTO DupeData (path, name, cost, weight, type, mobility, packid, description) VALUES
('aa20', 'AA20', 71.53, 9062, 'AA', 'Tracked', 'norinco_ground', 'Uses AIO Controls'),
('apc12', 'APC12', 41.29, 6970.96, 'APC', 'Tracked', 'norinco_ground', 'Uses AIO Controls'),
('atm152', 'ATM152', 61.86, 7951.07, 'ATGM', 'Tracked', 'norinco_ground', 'Uses AIO Controls'),
('ifv10030', 'IFV-10030', 269.83, 24273.29, 'IFV', 'Tracked', 'norinco_ground', 'Uses AIO Controls'),
('lt85', 'LT-85', 91.78, 9163.5, 'Light Tank', 'Tracked', 'norinco_ground', 'Uses AIO Controls'),
('spg152', 'SPG-152', 204.89, 13454.17, 'SPG', 'Tracked', 'norinco_ground', 'Uses AIO Controls'),
('wcv105', 'WCV-105', 187.58, 18354.13, 'Light Tank', 'Tracked', 'norinco_ground', 'Uses AIO Controls'),
('wfv25', 'WFV-25', 136.55, 13145.43, 'IFV', 'Wheeled', 'norinco_ground', 'Uses AIO Controls'),
('wpv12', 'WPV-12', 22.48, 3066.14, 'Transport', 'Wheeled', 'norinco_ground', 'Uses AIO Controls'),
('wtv12', 'WTV-12', 46.52, 9397.84, 'Transport', 'Wheeled', 'norinco_ground', 'Uses AIO Controls');