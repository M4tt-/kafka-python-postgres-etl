-- Setup the PG database and table
-- Author: mrunyon

CREATE DATABASE av_telemetry;
\c av_telemetry;
CREATE TABLE diag
(id serial PRIMARY KEY,
 timestamp float,
 vin char(17),
 make varchar(20),
 model varchar(20),
 position_x float,
 position_y float,
 position_z float,
 speed float);