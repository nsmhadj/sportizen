\set ON_ERROR_STOP on
SET search_path = public;

-- RESET
DROP TABLE IF EXISTS Reservation   CASCADE;
DROP TABLE IF EXISTS Match_termine CASCADE;
DROP TABLE IF EXISTS Match_propose CASCADE;
DROP TABLE IF EXISTS Match         CASCADE;
DROP TABLE IF EXISTS Equipe_B      CASCADE;
DROP TABLE IF EXISTS Equipe_A      CASCADE;
DROP TABLE IF EXISTS Equipe        CASCADE;
DROP TABLE IF EXISTS Creneau       CASCADE;
DROP TABLE IF EXISTS Dispo_Terrain CASCADE;
DROP TABLE IF EXISTS Terrain       CASCADE;
DROP TABLE IF EXISTS Complexe      CASCADE;
DROP TABLE IF EXISTS Organisateur  CASCADE;
DROP TABLE IF EXISTS Utilisateur   CASCADE;
DROP TABLE IF EXISTS Ville         CASCADE;

DROP SEQUENCE IF EXISTS seq_reservation CASCADE;
DROP SEQUENCE IF EXISTS seq_match       CASCADE;
DROP SEQUENCE IF EXISTS seq_equipe      CASCADE;
DROP SEQUENCE IF EXISTS seq_creneau     CASCADE;
DROP SEQUENCE IF EXISTS seq_terrain     CASCADE;
DROP SEQUENCE IF EXISTS seq_complexe    CASCADE;
DROP SEQUENCE IF EXISTS seq_utilisateur CASCADE;
DROP SEQUENCE IF EXISTS seq_ville       CASCADE;

-- SEQUENCES
CREATE SEQUENCE seq_ville START 1;
CREATE SEQUENCE seq_utilisateur START 1;
CREATE SEQUENCE seq_complexe START 1;
CREATE SEQUENCE seq_terrain START 1;
CREATE SEQUENCE seq_creneau START 1;
CREATE SEQUENCE seq_equipe START 1;
CREATE SEQUENCE seq_match START 1;
CREATE SEQUENCE seq_reservation START 1;

-- BASE
CREATE TABLE Ville (
  id_ville INT DEFAULT nextval('seq_ville') PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  code_postal VARCHAR(5),
  pays VARCHAR(50) DEFAULT 'France'
);

CREATE TABLE Utilisateur (
  id_utilisateur INT DEFAULT nextval('seq_utilisateur') PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  prenom VARCHAR(50) NOT NULL,
  mot_de_passe VARCHAR(255) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  tel VARCHAR(15),
  date_naissance DATE,
  id_ville INT REFERENCES Ville(id_ville) ON DELETE SET NULL
);

CREATE TABLE Organisateur (
  id_organisateur INT PRIMARY KEY,
  matricule VARCHAR(50) UNIQUE NOT NULL,
  FOREIGN KEY (id_organisateur) REFERENCES Utilisateur(id_utilisateur) ON DELETE CASCADE
);

CREATE TABLE Complexe (
  id_complexe INT DEFAULT nextval('seq_complexe') PRIMARY KEY,
  nom VARCHAR(50) NOT NULL,
  adresse VARCHAR(100) NOT NULL,
  capacite_totale INT,
  id_ville INT REFERENCES Ville(id_ville) ON DELETE SET NULL
);

CREATE TABLE Terrain (
  id_terrain INT DEFAULT nextval('seq_terrain') PRIMARY KEY,
  code_terrain VARCHAR(50) NOT NULL,
  indoor BOOLEAN DEFAULT FALSE,
  eclairage BOOLEAN DEFAULT FALSE,
  id_complexe INT REFERENCES Complexe(id_complexe) ON DELETE CASCADE
);

CREATE TABLE Creneau (
  id_creneau INT DEFAULT nextval('seq_creneau') PRIMARY KEY,
  debut_ts TIMESTAMP NOT NULL,
  fin_ts TIMESTAMP NOT NULL,
  CHECK (fin_ts > debut_ts)
);

CREATE TABLE Dispo_Terrain (
  id_terrain INT,
  id_creneau INT,
  PRIMARY KEY (id_terrain, id_creneau),
  FOREIGN KEY (id_terrain) REFERENCES Terrain(id_terrain) ON DELETE CASCADE,
  FOREIGN KEY (id_creneau) REFERENCES Creneau(id_creneau) ON DELETE CASCADE
);

-- EQUIPES (INHERITS)
CREATE TABLE Equipe (
  id_equipe INT DEFAULT nextval('seq_equipe') NOT NULL,
  nom VARCHAR(50) NOT NULL,
  nb_joueurs INT DEFAULT 0,
  CONSTRAINT equipe_pk PRIMARY KEY (id_equipe)
);

CREATE TABLE Equipe_A (
) INHERITS (Equipe);
ALTER TABLE ONLY Equipe_A ADD CONSTRAINT equipe_a_pk PRIMARY KEY (id_equipe);

CREATE TABLE Equipe_B (
) INHERITS (Equipe);
ALTER TABLE ONLY Equipe_B ADD CONSTRAINT equipe_b_pk PRIMARY KEY (id_equipe);

-- MATCH (INHERITS)
CREATE TABLE Match (
  id_match INT DEFAULT nextval('seq_match') NOT NULL,
  nb_places_total INT NOT NULL,
  id_equipe_A INT,
  id_equipe_B INT,
  CHECK (id_equipe_A <> id_equipe_B),
  CONSTRAINT match_pk PRIMARY KEY (id_match)
);

CREATE TABLE Match_propose (
  date_limite_reservation DATE NOT NULL
) INHERITS (Match);
ALTER TABLE ONLY Match_propose ADD CONSTRAINT match_propose_pk PRIMARY KEY (id_match);

CREATE TABLE Match_termine (
  score_equipe_A INT DEFAULT 0,
  score_equipe_B INT DEFAULT 0
) INHERITS (Match);
ALTER TABLE ONLY Match_termine ADD CONSTRAINT match_termine_pk PRIMARY KEY (id_match);

-- RESERVATION (simple, sans FK vers Match car INHERITS)
CREATE TABLE Reservation (
  id_reservation INT DEFAULT nextval('seq_reservation') PRIMARY KEY,
  id_match INT,
  id_equipe INT,
  nom_joueur VARCHAR(50),
  statut VARCHAR(20) DEFAULT 'confirmée'
);
-- =========================================================
-- 1) VILLES
-- =========================================================
INSERT INTO Ville (nom, code_postal, pays) VALUES
('Angers','49000','France'),
('Nantes','44000','France'),
('Rennes','35000','France');

-- =========================================================
-- 2) UTILISATEURS
-- =========================================================
INSERT INTO Utilisateur (nom, prenom, mot_de_passe, email, tel, date_naissance, id_ville) VALUES
('Dupont','Jean','pw','jean.dupont@mail.com','0612345678','1995-06-21', (SELECT id_ville FROM Ville WHERE nom='Angers')),
('Martin','Clara','pw','clara.martin@mail.com','0623456789','1999-10-10', (SELECT id_ville FROM Ville WHERE nom='Nantes')),
('Bernard','Paul','pw','paul.bernard@mail.com','0631111111','1998-03-12', (SELECT id_ville FROM Ville WHERE nom='Rennes')),
('Robert','Lucie','pw','lucie.robert@mail.com','0642222222','2000-07-05', (SELECT id_ville FROM Ville WHERE nom='Angers')),
('Petit','Nora','pw','nora.petit@mail.com','0653333333','1997-11-23', (SELECT id_ville FROM Ville WHERE nom='Nantes'));

-- =========================================================
-- 3) ORGANISATEURS (on “promeut” 3 utilisateurs en organisateurs)
-- =========================================================
INSERT INTO Organisateur (id_organisateur, matricule) VALUES
((SELECT id_utilisateur FROM Utilisateur WHERE email='jean.dupont@mail.com'),'ORG001'),
((SELECT id_utilisateur FROM Utilisateur WHERE email='paul.bernard@mail.com'),'ORG002'),
((SELECT id_utilisateur FROM Utilisateur WHERE email='lucie.robert@mail.com'),'ORG003');

-- =========================================================
-- 4) COMPLEXES
-- =========================================================
INSERT INTO Complexe (nom, adresse, capacite_totale, id_ville) VALUES
('Complexe Jean Bouin','12 rue du Stade',500,(SELECT id_ville FROM Ville WHERE nom='Angers')),
('Complexe La Beaujoire','99 avenue Sport',800,(SELECT id_ville FROM Ville WHERE nom='Nantes'));

-- =========================================================
-- 5) TERRAINS
-- =========================================================
INSERT INTO Terrain (code_terrain, indoor, eclairage, id_complexe) VALUES
('ANG_T1', FALSE, TRUE,  (SELECT id_complexe FROM Complexe WHERE nom='Complexe Jean Bouin')),
('ANG_T2', TRUE,  TRUE,  (SELECT id_complexe FROM Complexe WHERE nom='Complexe Jean Bouin')),
('NAN_T1', FALSE, TRUE,  (SELECT id_complexe FROM Complexe WHERE nom='Complexe La Beaujoire')),
('NAN_T2', TRUE,  TRUE,  (SELECT id_complexe FROM Complexe WHERE nom='Complexe La Beaujoire'));

-- =========================================================
-- 6) CRÉNEAUX
-- =========================================================
INSERT INTO Creneau (debut_ts, fin_ts) VALUES
('2025-10-01 18:00:00','2025-10-01 20:00:00'),
('2025-10-02 18:00:00','2025-10-02 20:00:00'),
('2025-10-03 18:00:00','2025-10-03 20:00:00'),
('2025-10-04 18:00:00','2025-10-04 20:00:00');

-- =========================================================
-- 7) DISPO_TERRAIN (liens simples terrain ↔ créneau)
-- =========================================================
INSERT INTO Dispo_Terrain (id_terrain, id_creneau) VALUES
((SELECT id_terrain FROM Terrain  WHERE code_terrain='ANG_T1'), (SELECT id_creneau FROM Creneau WHERE debut_ts='2025-10-01 18:00:00')),
((SELECT id_terrain FROM Terrain  WHERE code_terrain='ANG_T2'), (SELECT id_creneau FROM Creneau WHERE debut_ts='2025-10-02 18:00:00')),
((SELECT id_terrain FROM Terrain  WHERE code_terrain='NAN_T1'), (SELECT id_creneau FROM Creneau WHERE debut_ts='2025-10-03 18:00:00')),
((SELECT id_terrain FROM Terrain  WHERE code_terrain='NAN_T2'), (SELECT id_creneau FROM Creneau WHERE debut_ts='2025-10-04 18:00:00'));

-- =========================================================
-- 8) ÉQUIPES (INHERITS) — 4 en A, 4 en B
-- =========================================================
INSERT INTO Equipe_A (nom, nb_joueurs) VALUES
('Tigres A',5),('Loups A',6),('Requins A',6),('Panthères A',7);

INSERT INTO Equipe_B (nom, nb_joueurs) VALUES
('Lions B',6),('Aigles B',5),('Dragons B',7),('Ours B',5);

-- =========================================================
-- 9) MATCHS PROPOSÉS (INHERITS) — 3 matchs
--    (on appaire des équipes A↔B par le nom)
-- =========================================================
-- Match 1 : Tigres A vs Lions B (ORG001)
INSERT INTO Match_propose (nb_places_total, id_equipe_A, id_equipe_B, date_limite_reservation)
VALUES (
  22,
  (SELECT id_equipe FROM Equipe_A WHERE nom='Tigres A'),
  (SELECT id_equipe FROM Equipe_B WHERE nom='Lions B'),
  '2025-10-15'
);

-- Match 2 : Loups A vs Aigles B (ORG002)
INSERT INTO Match_propose (nb_places_total, id_equipe_A, id_equipe_B, date_limite_reservation)
VALUES (
  24,
  (SELECT id_equipe FROM Equipe_A WHERE nom='Loups A'),
  (SELECT id_equipe FROM Equipe_B WHERE nom='Aigles B'),
  '2025-10-16'
);

-- Match 3 : Requins A vs Dragons B (ORG003)
INSERT INTO Match_propose (nb_places_total, id_equipe_A, id_equipe_B, date_limite_reservation)
VALUES (
  20,
  (SELECT id_equipe FROM Equipe_A WHERE nom='Requins A'),
  (SELECT id_equipe FROM Equipe_B WHERE nom='Dragons B'),
  '2025-10-17'
);

-- =========================================================
-- 🔎 Vérifier les id_match créés (optionnel)
-- SELECT id_match, id_equipe_A, id_equipe_B FROM Match ORDER BY id_match;

-- =========================================================
-- 10) RÉSERVATIONS (plusieurs par match, côté A ou B)
-- =========================================================
-- Pour Match 1 (Tigres A vs Lions B)
INSERT INTO Reservation (id_match, id_equipe, nom_joueur, statut) VALUES
((SELECT id_match FROM Match_propose mp JOIN Equipe_A ea ON mp.id_equipe_A=ea.id_equipe WHERE ea.nom='Tigres A' LIMIT 1),
 (SELECT id_equipe FROM Equipe_A WHERE nom='Tigres A'),'Jean D','confirmée'),
((SELECT id_match FROM Match_propose mp JOIN Equipe_B eb ON mp.id_equipe_B=eb.id_equipe WHERE eb.nom='Lions B' LIMIT 1),
 (SELECT id_equipe FROM Equipe_B WHERE nom='Lions B'),'Clara M','confirmée');

-- Pour Match 2 (Loups A vs Aigles B)
INSERT INTO Reservation (id_match, id_equipe, nom_joueur, statut) VALUES
((SELECT id_match FROM Match_propose mp JOIN Equipe_A ea ON mp.id_equipe_A=ea.id_equipe WHERE ea.nom='Loups A' LIMIT 1),
 (SELECT id_equipe FROM Equipe_A WHERE nom='Loups A'),'Paul B','confirmée'),
((SELECT id_match FROM Match_propose mp JOIN Equipe_B eb ON mp.id_equipe_B=eb.id_equipe WHERE eb.nom='Aigles B' LIMIT 1),
 (SELECT id_equipe FROM Equipe_B WHERE nom='Aigles B'),'Nora P','annulée');

-- Pour Match 3 (Requins A vs Dragons B)
INSERT INTO Reservation (id_match, id_equipe, nom_joueur, statut) VALUES
((SELECT id_match FROM Match_propose mp JOIN Equipe_A ea ON mp.id_equipe_A=ea.id_equipe WHERE ea.nom='Requins A' LIMIT 1),
 (SELECT id_equipe FROM Equipe_A WHERE nom='Requins A'),'Sam R','confirmée'),
((SELECT id_match FROM Match_propose mp JOIN Equipe_B eb ON mp.id_equipe_B=eb.id_equipe WHERE eb.nom='Dragons B' LIMIT 1),
 (SELECT id_equipe FROM Equipe_B WHERE nom='Dragons B'),'Lila T','confirmée');

-- =========================================================
-- 11) MATCHS TERMINÉS (convertir 1 des 3 matchs en “terminé”)
--     (on réutilise le même id_match)
-- =========================================================
-- on termine le Match 1 : Tigres A 3 - 2 Lions B
INSERT INTO Match_termine (id_match, nb_places_total, id_equipe_A, id_equipe_B, score_equipe_A, score_equipe_B)
SELECT
  id_match, nb_places_total, id_equipe_A, id_equipe_B, 3, 2
FROM Match_propose mp
JOIN Equipe_A ea ON mp.id_equipe_A = ea.id_equipe
JOIN Equipe_B eb ON mp.id_equipe_B = eb.id_equipe
WHERE ea.nom='Tigres A' AND eb.nom='Lions B'
LIMIT 1;

-- (optionnel) retirer l’état “proposé” pour ce match terminé
DELETE FROM Match_propose
WHERE id_match IN (
  SELECT m.id_match
  FROM Match m
  JOIN Equipe_A ea ON m.id_equipe_A = ea.id_equipe
  JOIN Equipe_B eb ON m.id_equipe_B = eb.id_equipe
  WHERE ea.nom='Tigres A' AND eb.nom='Lions B'
);
