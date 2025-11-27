DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS match_termine CASCADE;
DROP TABLE IF EXISTS match_propose CASCADE;
DROP TABLE IF EXISTS match CASCADE;
DROP TABLE IF EXISTS equipe CASCADE;
DROP TABLE IF EXISTS dispo_terrain CASCADE;
DROP TABLE IF EXISTS creneau CASCADE;
DROP TABLE IF EXISTS terrain CASCADE;
DROP TABLE IF EXISTS complexe CASCADE;
DROP TABLE IF EXISTS organisateur CASCADE;
DROP TABLE IF EXISTS utilisateur CASCADE;
DROP TABLE IF EXISTS ville CASCADE;

DROP SEQUENCE IF EXISTS
  seq_ville,
  seq_utilisateur,
  -- seq_organisateur -- (supprimé: organisateur réutilise l'id utilisateur)
  seq_complexe,
  seq_terrain,
  seq_creneau,
  seq_match,
  seq_equipe,
  seq_reservation
CASCADE;

-- ============================
-- SÉQUENCES
-- ============================
CREATE SEQUENCE seq_ville START 1;
CREATE SEQUENCE seq_utilisateur START 1;
-- pas de seq_organisateur : IS-A de utilisateur
CREATE SEQUENCE seq_complexe START 1;
CREATE SEQUENCE seq_terrain START 1;
CREATE SEQUENCE seq_creneau START 1;
CREATE SEQUENCE seq_match START 1;
CREATE SEQUENCE seq_equipe START 1;
CREATE SEQUENCE seq_reservation START 1;

-- ============================
-- TABLES DE RÉFÉRENCE
-- ============================
CREATE TABLE ville (
  id_ville INTEGER PRIMARY KEY DEFAULT nextval('seq_ville'),
  nom VARCHAR(50) NOT NULL,
  code_postal VARCHAR(10),
  pays VARCHAR(50) DEFAULT 'FRANCE'
);

CREATE TABLE utilisateur (
  id_utilisateur INTEGER PRIMARY KEY DEFAULT nextval('seq_utilisateur'),
  nom VARCHAR(50) NOT NULL,
  prenom VARCHAR(50) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  date_naissance DATE,
  tel VARCHAR(15),
  mot_de_passe VARCHAR(100) NOT NULL,
  id_ville INTEGER,
  CONSTRAINT fk_utilisateur_ville FOREIGN KEY (id_ville)
    REFERENCES ville(id_ville) ON DELETE SET NULL
);

-- IS-A: organisateur partage la PK de utilisateur, pas de séquence séparée
CREATE TABLE organisateur (
  id_organisateur INTEGER PRIMARY KEY,              -- pas de DEFAULT ici
  matricule VARCHAR(50) UNIQUE,
  CONSTRAINT fk_organisateur_utilisateur FOREIGN KEY (id_organisateur)
    REFERENCES utilisateur(id_utilisateur) ON DELETE CASCADE
);

CREATE TABLE complexe (
  id_complexe INTEGER PRIMARY KEY DEFAULT nextval('seq_complexe'),
  nom VARCHAR(50) NOT NULL,
  adresse VARCHAR(100),
  capacite_totale INT,
  id_ville INTEGER NOT NULL,
  CONSTRAINT fk_complexe_ville FOREIGN KEY (id_ville)
    REFERENCES ville(id_ville) ON DELETE RESTRICT
);

CREATE TABLE terrain (
  id_terrain INTEGER PRIMARY KEY DEFAULT nextval('seq_terrain'),
  code_terrain VARCHAR(10) NOT NULL,
  indoor BOOLEAN DEFAULT FALSE,
  eclairage BOOLEAN DEFAULT FALSE,
  id_complexe INTEGER NOT NULL,
  CONSTRAINT fk_terrain_complexe FOREIGN KEY (id_complexe)
    REFERENCES complexe(id_complexe) ON DELETE CASCADE
);

CREATE TABLE creneau (
  id_creneau INTEGER PRIMARY KEY DEFAULT nextval('seq_creneau'),
  debut_ts TIMESTAMP NOT NULL,
  fin_ts TIMESTAMP NOT NULL,
  CONSTRAINT ck_creneau_temps CHECK (fin_ts > debut_ts)
);

-- Manquait dans ton script
CREATE TABLE dispo_terrain (
  id_terrain INTEGER NOT NULL,
  id_creneau INTEGER NOT NULL,
  CONSTRAINT pk_dispo PRIMARY KEY (id_terrain, id_creneau),
  CONSTRAINT fk_dispo_terrain FOREIGN KEY (id_terrain)
    REFERENCES terrain(id_terrain) ON DELETE CASCADE,
  CONSTRAINT fk_dispo_creneau FOREIGN KEY (id_creneau)
    REFERENCES creneau(id_creneau) ON DELETE CASCADE
);

-- ============================
-- TABLES SPORTIVES
-- ============================
CREATE TABLE equipe (
  id_equipe INTEGER PRIMARY KEY DEFAULT nextval('seq_equipe'),
  nom VARCHAR(50) NOT NULL,
  nb_joueurs INT DEFAULT 0
);

CREATE TABLE match (
  id_match INTEGER PRIMARY KEY DEFAULT nextval('seq_match'),
  nb_places_total INTEGER NOT NULL CHECK (nb_places_total > 0),
  date_creation TIMESTAMP DEFAULT NOW(),
  id_organisateur INTEGER,
  id_terrain INTEGER,
  id_creneau INTEGER,
  id_equipe_a INTEGER,
  id_equipe_b INTEGER,
  CONSTRAINT fk_match_organisateur FOREIGN KEY (id_organisateur)
    REFERENCES organisateur(id_organisateur) ON DELETE SET NULL,
  CONSTRAINT fk_match_terrain FOREIGN KEY (id_terrain)
    REFERENCES terrain(id_terrain) ON DELETE CASCADE,
  CONSTRAINT fk_match_creneau FOREIGN KEY (id_creneau)
    REFERENCES creneau(id_creneau) ON DELETE CASCADE,
  CONSTRAINT fk_match_equipe_a FOREIGN KEY (id_equipe_a)
    REFERENCES equipe(id_equipe) ON DELETE SET NULL,
  CONSTRAINT fk_match_equipe_b FOREIGN KEY (id_equipe_b)
    REFERENCES equipe(id_equipe) ON DELETE SET NULL,
  CONSTRAINT unq_match_terrain_creneau UNIQUE (id_terrain, id_creneau)
);

CREATE TABLE match_propose (
  id_match_p INTEGER PRIMARY KEY,
  date_limite_reservation DATE NOT NULL,
  CONSTRAINT fk_match_propose FOREIGN KEY (id_match_p)
    REFERENCES match(id_match) ON DELETE CASCADE
);

CREATE TABLE match_termine (
  id_match_t INTEGER PRIMARY KEY,
  score_equipe_a INTEGER DEFAULT 0 CHECK (score_equipe_a >= 0),
  score_equipe_b INTEGER DEFAULT 0 CHECK (score_equipe_b >= 0),
  CONSTRAINT fk_match_termine FOREIGN KEY (id_match_t)
    REFERENCES match(id_match) ON DELETE CASCADE
);

CREATE TABLE reservation (
  id_reservation INTEGER PRIMARY KEY DEFAULT nextval('seq_reservation'),
  statut VARCHAR(50) DEFAULT 'confirmée',
  qr_hash VARCHAR(50),
  qr_etat VARCHAR(50) DEFAULT 'actif',
  date_reservation TIMESTAMP DEFAULT NOW(),
  id_utilisateur INTEGER,
  id_match INTEGER,
  id_equipe INTEGER,
  CONSTRAINT fk_reservation_utilisateur FOREIGN KEY (id_utilisateur)
    REFERENCES utilisateur(id_utilisateur) ON DELETE CASCADE,
  CONSTRAINT fk_reservation_match FOREIGN KEY (id_match)
    REFERENCES match(id_match) ON DELETE CASCADE,
  CONSTRAINT fk_reservation_equipe FOREIGN KEY (id_equipe)
    REFERENCES equipe(id_equipe) ON DELETE SET NULL,
  CONSTRAINT unq_reservation_joueur UNIQUE (id_utilisateur, id_match)
);


-- =========
-- VILLES
-- =========

INSERT INTO ville (id_ville, nom, code_postal, pays) VALUES
(nextval('seq_ville'), 'Paris',        '75000', 'France'),
(nextval('seq_ville'), 'Lyon',         '69000', 'France'),
(nextval('seq_ville'), 'Marseille',    '13000', 'France'),
(nextval('seq_ville'), 'Lille',        '59000', 'France'),
(nextval('seq_ville'), 'Nantes',       '44000', 'France'),
(nextval('seq_ville'), 'Toulouse',     '31000', 'France'),
(nextval('seq_ville'), 'Bordeaux',     '33000', 'France'),
(nextval('seq_ville'), 'Nice',         '06000', 'France'),
(nextval('seq_ville'), 'Angers',       '49000', 'France'),
(nextval('seq_ville'), 'Strasbourg',   '67000', 'France'),
(nextval('seq_ville'), 'Nancy',        '54000', 'France'),
(nextval('seq_ville'), 'Saint-Étienne','42000', 'France'),
(nextval('seq_ville'), 'Lens',         '62300', 'France'),
(nextval('seq_ville'), 'Le Havre',     '76600', 'France'),
(nextval('seq_ville'), 'Reims',        '51100', 'France'),
(nextval('seq_ville'), 'Dijon',        '21000', 'France'),
(nextval('seq_ville'), 'Brest',        '29200', 'France'),
(nextval('seq_ville'), 'Orléans',      '45000', 'France'),
(nextval('seq_ville'), 'Sochaux',      '25600', 'France');

-- =================
-- UTILISATEURS (200)
-- =================

-- =================
-- ORGANISATEURS (24)
-- =================

-- =================
-- COMPLEXES (16)
-- =================
-- Insertion de 16 complexes sportifs
INSERT INTO complexe (id_complexe, nom, adresse, id_ville)
VALUES
(nextval('seq_complexe'), 'Complexe Jean Bouin',         '12 Rue du Stade, Paris', 1),
(nextval('seq_complexe'), 'Complexe Pierre Mauroy',      '23 Avenue du Sport, Lille', 4),
(nextval('seq_complexe'), 'Complexe Gerland',            '5 Rue des Lions, Lyon', 2),
(nextval('seq_complexe'), 'Complexe Vélodrome',          '45 Boulevard du Sud, Marseille', 3),
(nextval('seq_complexe'), 'Complexe la Beaujoire',       '78 Rue des Fleurs, Nantes', 5),
(nextval('seq_complexe'), 'Complexe Marcel Picot',       '33 Rue des Sports, Nancy', 11),
(nextval('seq_complexe'), 'Complexe Geoffroy-Guichard',  '99 Avenue Verte, Saint-Étienne', 12),
(nextval('seq_complexe'), 'Complexe Bollaert-Delelis',   '27 Rue du Nord, Lens', 13),
(nextval('seq_complexe'), 'Complexe Allianz Riviera',    '40 Chemin des Pins, Nice', 8),
(nextval('seq_complexe'), 'Complexe Océane',             '3 Rue du Havre, Le Havre', 14),
(nextval('seq_complexe'), 'Complexe Auguste Delaune',    '11 Rue du Stade, Reims', 15),
(nextval('seq_complexe'), 'Complexe Gaston Gérard',      '17 Rue des Vignes, Dijon', 16),
(nextval('seq_complexe'), 'Complexe Francis Le Blé',     '8 Rue des Capucins, Brest', 17),
(nextval('seq_complexe'), 'Complexe Matmut Atlantique',  '25 Rue Atlantique, Bordeaux', 7),
(nextval('seq_complexe'), 'Complexe Stade de la Source', '56 Rue du Parc, Orléans', 18),
(nextval('seq_complexe'), 'Complexe Stade Bonal',        '9 Avenue de la Liberté, Sochaux', 19),
(nextval('seq_complexe'), 'Complexe Stadium Toulouse',   'Allée du Stadium, Toulouse', 6),  
(nextval('seq_complexe'), 'Complexe Raymond-Kopa',       'Rue du Stade, Angers', 9),        
(nextval('seq_complexe'), 'Complexe de la Meinau',       'Rue de la Meinau, Strasbourg', 10);



-- =================
-- TERRAINS (~48)
-- =================
INSERT INTO terrain (id_terrain, code_terrain, id_complexe) VALUES
(nextval('seq_terrain'), 'T1', 1),
(nextval('seq_terrain'), 'T2', 1),
(nextval('seq_terrain'), 'T3', 1),
(nextval('seq_terrain'), 'T1', 2),
(nextval('seq_terrain'), 'T2', 2),
(nextval('seq_terrain'), 'T3', 2),
(nextval('seq_terrain'), 'T1', 3),
(nextval('seq_terrain'), 'T2', 3),
(nextval('seq_terrain'), 'T3', 3),
(nextval('seq_terrain'), 'T1', 4),
(nextval('seq_terrain'), 'T2', 4),
(nextval('seq_terrain'), 'T3', 4),
(nextval('seq_terrain'), 'T1', 5),
(nextval('seq_terrain'), 'T2', 5),
(nextval('seq_terrain'), 'T3', 5),
(nextval('seq_terrain'), 'T1', 6),
(nextval('seq_terrain'), 'T2', 6),
(nextval('seq_terrain'), 'T3', 6),
(nextval('seq_terrain'), 'T1', 7),
(nextval('seq_terrain'), 'T2', 7),
(nextval('seq_terrain'), 'T3', 7),
(nextval('seq_terrain'), 'T1', 8),
(nextval('seq_terrain'), 'T2', 8),
(nextval('seq_terrain'), 'T3', 8),
(nextval('seq_terrain'), 'T1', 9),
(nextval('seq_terrain'), 'T2', 9),
(nextval('seq_terrain'), 'T3', 9),
(nextval('seq_terrain'), 'T1', 10),
(nextval('seq_terrain'), 'T2', 10),
(nextval('seq_terrain'), 'T3', 10),
(nextval('seq_terrain'), 'T1', 11),
(nextval('seq_terrain'), 'T2', 11),
(nextval('seq_terrain'), 'T3', 11),
(nextval('seq_terrain'), 'T1', 12),
(nextval('seq_terrain'), 'T2', 12),
(nextval('seq_terrain'), 'T3', 12),
(nextval('seq_terrain'), 'T1', 13),
(nextval('seq_terrain'), 'T2', 13),
(nextval('seq_terrain'), 'T3', 13),
(nextval('seq_terrain'), 'T1', 14),
(nextval('seq_terrain'), 'T2', 14),
(nextval('seq_terrain'), 'T3', 14),
(nextval('seq_terrain'), 'T1', 15),
(nextval('seq_terrain'), 'T2', 15),
(nextval('seq_terrain'), 'T3', 15),
(nextval('seq_terrain'), 'T1', 16),
(nextval('seq_terrain'), 'T2', 16),
(nextval('seq_terrain'), 'T3', 16),
(nextval('seq_terrain'), 'T1', 17),
(nextval('seq_terrain'), 'T2', 17),
(nextval('seq_terrain'), 'T3', 17),
(nextval('seq_terrain'), 'T1', 18),
(nextval('seq_terrain'), 'T2', 18),
(nextval('seq_terrain'), 'T3', 18),
(nextval('seq_terrain'), 'T1', 19),
(nextval('seq_terrain'), 'T2', 19),
(nextval('seq_terrain'), 'T3', 19);


-- CRENEAUX (60)
-- =================

INSERT INTO creneau (id_creneau, debut_ts, fin_ts) VALUES
(nextval('seq_creneau'), '2025-12-15 10:00:00', '2025-12-15 12:00:00'),
(nextval('seq_creneau'), '2025-12-15 12:00:00', '2025-12-15 14:00:00'),
(nextval('seq_creneau'), '2025-12-15 14:00:00', '2025-12-15 16:00:00'),
(nextval('seq_creneau'), '2025-12-15 16:00:00', '2025-12-15 18:00:00'),
(nextval('seq_creneau'), '2025-12-15 18:00:00', '2025-12-15 20:00:00'),
(nextval('seq_creneau'), '2025-12-17 10:00:00', '2025-12-17 12:00:00'),
(nextval('seq_creneau'), '2025-12-17 12:00:00', '2025-12-17 14:00:00'),
(nextval('seq_creneau'), '2025-12-17 14:00:00', '2025-12-17 16:00:00'),
(nextval('seq_creneau'), '2025-12-17 16:00:00', '2025-12-17 18:00:00'),
(nextval('seq_creneau'), '2025-12-17 18:00:00', '2025-12-17 20:00:00'),
(nextval('seq_creneau'), '2025-12-19 10:00:00', '2025-12-19 12:00:00'),
(nextval('seq_creneau'), '2025-12-19 12:00:00', '2025-12-19 14:00:00'),
(nextval('seq_creneau'), '2025-12-19 14:00:00', '2025-12-19 16:00:00'),
(nextval('seq_creneau'), '2025-12-19 16:00:00', '2025-12-19 18:00:00'),
(nextval('seq_creneau'), '2025-12-19 18:00:00', '2025-12-19 20:00:00'),
(nextval('seq_creneau'), '2025-12-21 10:00:00', '2025-12-21 12:00:00'),
(nextval('seq_creneau'), '2025-12-21 12:00:00', '2025-12-21 14:00:00'),
(nextval('seq_creneau'), '2025-12-21 14:00:00', '2025-12-21 16:00:00'),
(nextval('seq_creneau'), '2025-12-21 16:00:00', '2025-12-21 18:00:00'),
(nextval('seq_creneau'), '2025-12-21 18:00:00', '2025-12-21 20:00:00'),
(nextval('seq_creneau'), '2025-12-23 10:00:00', '2025-12-23 12:00:00'),
(nextval('seq_creneau'), '2025-12-23 12:00:00', '2025-12-23 14:00:00'),
(nextval('seq_creneau'), '2025-12-23 14:00:00', '2025-12-23 16:00:00'),
(nextval('seq_creneau'), '2025-12-23 16:00:00', '2025-12-23 18:00:00'),
(nextval('seq_creneau'), '2025-12-23 18:00:00', '2025-12-23 20:00:00'),
(nextval('seq_creneau'), '2025-12-25 10:00:00', '2025-12-25 12:00:00'),
(nextval('seq_creneau'), '2025-12-25 12:00:00', '2025-12-25 14:00:00'),
(nextval('seq_creneau'), '2025-12-25 14:00:00', '2025-12-25 16:00:00'),
(nextval('seq_creneau'), '2025-12-25 16:00:00', '2025-12-25 18:00:00'),
(nextval('seq_creneau'), '2025-12-25 18:00:00', '2025-12-25 20:00:00'),
(nextval('seq_creneau'), '2025-12-27 10:00:00', '2025-12-27 12:00:00'),
(nextval('seq_creneau'), '2025-12-27 12:00:00', '2025-12-27 14:00:00'),
(nextval('seq_creneau'), '2025-12-27 14:00:00', '2025-12-27 16:00:00'),
(nextval('seq_creneau'), '2025-12-27 16:00:00', '2025-12-27 18:00:00'),
(nextval('seq_creneau'), '2025-12-27 18:00:00', '2025-12-27 20:00:00'),
(nextval('seq_creneau'), '2025-12-29 10:00:00', '2025-12-29 12:00:00'),
(nextval('seq_creneau'), '2025-12-29 12:00:00', '2025-12-29 14:00:00'),
(nextval('seq_creneau'), '2025-12-29 14:00:00', '2025-12-29 16:00:00'),
(nextval('seq_creneau'), '2025-12-29 16:00:00', '2025-12-29 18:00:00'),
(nextval('seq_creneau'), '2025-12-29 18:00:00', '2025-12-29 20:00:00'),
(nextval('seq_creneau'), '2025-12-31 10:00:00', '2025-12-31 12:00:00'),
(nextval('seq_creneau'), '2025-12-31 12:00:00', '2025-12-31 14:00:00'),
(nextval('seq_creneau'), '2025-12-31 14:00:00', '2025-12-31 16:00:00'),
(nextval('seq_creneau'), '2025-12-31 16:00:00', '2025-12-31 18:00:00'),
(nextval('seq_creneau'), '2025-12-31 18:00:00', '2025-12-31 20:00:00'),
(nextval('seq_creneau'), '2026-01-02 10:00:00', '2026-01-02 12:00:00'),
(nextval('seq_creneau'), '2026-01-02 12:00:00', '2026-01-02 14:00:00'),
(nextval('seq_creneau'), '2026-01-02 14:00:00', '2026-01-02 16:00:00'),
(nextval('seq_creneau'), '2026-01-02 16:00:00', '2026-01-02 18:00:00'),
(nextval('seq_creneau'), '2026-01-02 18:00:00', '2026-01-02 20:00:00'),
(nextval('seq_creneau'), '2026-01-04 10:00:00', '2026-01-04 12:00:00'),
(nextval('seq_creneau'), '2026-01-04 12:00:00', '2026-01-04 14:00:00'),
(nextval('seq_creneau'), '2026-01-04 14:00:00', '2026-01-04 16:00:00'),
(nextval('seq_creneau'), '2026-01-04 16:00:00', '2026-01-04 18:00:00'),
(nextval('seq_creneau'), '2026-01-04 18:00:00', '2026-01-04 20:00:00'),
(nextval('seq_creneau'), '2026-01-06 10:00:00', '2026-01-06 12:00:00'),
(nextval('seq_creneau'), '2026-01-06 12:00:00', '2026-01-06 14:00:00'),
(nextval('seq_creneau'), '2026-01-06 14:00:00', '2026-01-06 16:00:00'),
(nextval('seq_creneau'), '2026-01-06 16:00:00', '2026-01-06 18:00:00'),
(nextval('seq_creneau'), '2026-01-06 18:00:00', '2026-01-06 20:00:00');

-- =================
-- DISPO_TERRAIN (~40% des combinaisons)
-- =================
INSERT INTO dispo_terrain (id_terrain, id_creneau) VALUES
(1,1),(1,2),(1,4),(1,6),(1,7),(1,9),(1,11),(1,12),(1,15),(1,16),(1,20),(1,22),(1,24),(1,25),(1,26),(1,27),(1,29),(1,32),(1,34),(1,35),(1,36),(1,39),(1,42),(1,45),(1,50),(1,52),(1,55),(1,57),
(2,2),(2,11),(2,16),(2,17),(2,19),(2,21),(2,22),(2,23),(2,25),(2,26),(2,27),(2,29),(2,35),(2,37),(2,40),(2,41),(2,42),(2,43),(2,46),(2,47),(2,49),(2,56),
(3,1),(3,2),(3,3),(3,5),(3,6),(3,7),(3,8),(3,9),(3,10),(3,11),(3,12),(3,13),(3,14),(3,15),(3,18),(3,19),(3,20),(3,21),(3,22),(3,27),(3,28),(3,29),(3,30),(3,32),(3,33),(3,36),(3,38),(3,43),(3,44),(3,45),(3,49),(3,50),(3,57),(3,59),(3,60),
(4,1),(4,2),(4,3),(4,10),(4,11),(4,12),(4,13),(4,14),(4,21),(4,27),(4,29),(4,32),(4,36),(4,37),(4,38),(4,41),(4,45),(4,47),(4,48),(4,56),(4,57),(4,58),(4,59),
(5,1),(5,3),(5,5),(5,14),(5,16),(5,17),(5,19),(5,23),(5,27),(5,29),(5,30),(5,48),(5,52),(5,53),(5,55),(5,56),(5,57),
(6,1),(6,4),(6,7),(6,9),(6,13),(6,16),(6,17),(6,18),(6,20),(6,23),(6,24),(6,27),(6,31),(6,32),(6,33),(6,35),(6,36),(6,40),(6,41),(6,45),(6,46),(6,49),(6,53),(6,55),(6,58),
(7,1),(7,2),(7,4),(7,5),(7,6),(7,7),(7,8),(7,9),(7,10),(7,12),(7,14),(7,15),(7,16),(7,17),(7,18),(7,21),(7,24),(7,29),(7,33),(7,38),(7,39),(7,40),(7,41),(7,43),(7,44),(7,45),(7,49),(7,50),(7,51),(7,53),(7,55),(7,59),
(8,1),(8,2),(8,3),(8,4),(8,7),(8,9),(8,10),(8,11),(8,12),(8,13),(8,14),(8,15),(8,16),(8,23),(8,24),(8,26),(8,29),(8,35),(8,45),(8,46),(8,47),(8,48),(8,49),(8,56),
(9,2),(9,4),(9,5),(9,6),(9,8),(9,12),(9,18),(9,19),(9,20),(9,22),(9,24),(9,25),(9,26),(9,30),(9,34),(9,36),(9,39),(9,44),(9,45),(9,47),(9,49),(9,52),(9,57),(9,60),
(10,1),(10,4),(10,5),(10,6),(10,7),(10,9),(10,12),(10,16),(10,17),(10,18),(10,21),(10,23),(10,24),(10,25),(10,27),(10,29),(10,30),(10,32),(10,33),(10,42),(10,47),(10,48),(10,50),(10,52),(10,53),(10,56),(10,58),(10,60),
(11,1),(11,2),(11,3),(11,6),(11,10),(11,11),(11,12),(11,13),(11,14),(11,15),(11,16),(11,23),(11,24),(11,25),(11,26),(11,28),(11,32),(11,33),(11,34),(11,35),(11,40),(11,41),(11,46),(11,47),(11,52),(11,53),(11,54),
(12,3),(12,5),(12,8),(12,9),(12,10),(12,13),(12,14),(12,17),(12,18),(12,20),(12,21),(12,27),(12,28),(12,31),(12,32),(12,36),(12,39),(12,40),(12,41),(12,44),(12,48),(12,50),(12,52),(12,53),(12,55),(12,58),(12,59),
(13,3),(13,4),(13,5),(13,7),(13,8),(13,9),(13,10),(13,16),(13,17),(13,20),(13,22),(13,23),(13,24),(13,25),(13,26),(13,27),(13,28),(13,30),(13,32),(13,33),(13,37),(13,39),(13,41),(13,42),(13,44),(13,48),(13,49),(13,50),(13,52),(13,55),(13,56),(13,59),
(14,1),(14,2),(14,3),(14,8),(14,9),(14,13),(14,14),(14,18),(14,24),(14,25),(14,26),(14,28),(14,29),(14,31),(14,32),(14,33),(14,35),(14,39),(14,40),(14,41),(14,45),(14,52),(14,54),(14,56),(14,58),(14,59),(14,60),
(15,1),(15,4),(15,5),(15,8),(15,12),(15,17),(15,18),(15,19),(15,20),(15,24),(15,27),(15,30),(15,33),(15,34),(15,35),(15,36),(15,37),(15,40),(15,41),(15,42),(15,44),(15,45),(15,46),(15,49),(15,50),(15,51),(15,54),(15,55),(15,58),(15,59),
(16,1),(16,3),(16,7),(16,8),(16,10),(16,11),(16,18),(16,19),(16,23),(16,25),(16,27),(16,28),(16,31),(16,35),(16,36),(16,40),(16,42),(16,46),(16,48),(16,52),(16,53),(16,54),(16,56),(16,57),(16,58),
(17,1),(17,4),(17,6),(17,10),(17,17),(17,20),(17,24),(17,26),(17,27),(17,29),(17,32),(17,34),(17,38),(17,40),(17,42),(17,47),(17,52),(17,55),(17,56),(17,58),(17,60),
(18,2),(18,5),(18,6),(18,8),(18,9),(18,10),(18,11),(18,15),(18,17),(18,20),(18,25),(18,28),(18,30),(18,33),(18,36),(18,38),(18,40),(18,45),(18,46),(18,47),(18,48),(18,53),(18,54),(18,56),(18,57),(18,58),(18,59),(18,60),
(19,1),(19,4),(19,7),(19,9),(19,10),(19,11),(19,16),(19,17),(19,20),(19,25),(19,27),(19,30),(19,31),(19,33),(19,36),(19,37),(19,42),(19,43),(19,44),(19,45),(19,49),(19,55),(19,56),(19,57),(19,58),(19,59),
(20,4),(20,9),(20,12),(20,14),(20,15),(20,16),(20,20),(20,22),(20,23),(20,36),(20,37),(20,39),(20,41),(20,42),(20,43),(20,45),(20,46),(20,47),(20,48),(20,53),(20,55),(20,59),
(21,3),(21,4),(21,5),(21,6),(21,12),(21,13),(21,14),(21,16),(21,17),(21,19),(21,20),(21,21),(21,23),(21,24),(21,29),(21,33),(21,36),(21,38),(21,40),(21,41),(21,42),(21,45),(21,49),(21,51),(21,53),(21,55),(21,56),(21,59),
(22,1),(22,6),(22,8),(22,10),(22,12),(22,13),(22,14),(22,17),(22,19),(22,25),(22,26),(22,27),(22,31),(22,35),(22,38),(22,39),(22,40),(22,43),(22,44),(22,45),(22,46),(22,48),(22,49),(22,50),(22,53),(22,55),(22,56),
(23,1),(23,3),(23,4),(23,5),(23,6),(23,7),(23,13),(23,22),(23,31),(23,33),(23,38),(23,45),(23,48),(23,51),(23,53),(23,57),
(24,7),(24,9),(24,11),(24,13),(24,14),(24,15),(24,16),(24,17),(24,21),(24,22),(24,23),(24,27),(24,29),(24,30),(24,31),(24,37),(24,39),(24,44),(24,46),(24,48),(24,50),(24,51),(24,52),(24,54),(24,55),(24,57),(24,58),(24,59),
(25,4),(25,7),(25,11),(25,14),(25,15),(25,18),(25,19),(25,20),(25,21),(25,23),(25,24),(25,27),(25,35),(25,42),(25,43),(25,44),(25,46),(25,48),(25,53),(25,59),
(26,2),(26,5),(26,9),(26,14),(26,17),(26,19),(26,23),(26,28),(26,32),(26,37),(26,38),(26,39),(26,43),(26,47),(26,48),(26,49),(26,50),
(27,2),(27,6),(27,7),(27,8),(27,12),(27,16),(27,17),(27,19),(27,23),(27,25),(27,26),(27,31),(27,32),(27,38),(27,40),(27,41),(27,42),(27,43),(27,45),(27,47),(27,49),(27,50),(27,52),(27,54),(27,55),(27,60),
(28,5),(28,8),(28,9),(28,12),(28,13),(28,15),(28,18),(28,19),(28,23),(28,25),(28,29),(28,34),(28,35),(28,39),(28,44),(28,47),(28,52),(28,53),(28,54),(28,59),
(29,4),(29,9),(29,10),(29,13),(29,16),(29,20),(29,21),(29,25),(29,28),(29,35),(29,36),(29,37),(29,39),(29,43),(29,44),(29,46),(29,47),(29,50),(29,52),(29,54),(29,55),(29,60),
(30,7),(30,8),(30,9),(30,10),(30,11),(30,12),(30,18),(30,20),(30,21),(30,23),(30,28),(30,30),(30,33),(30,34),(30,35),(30,36),(30,40),(30,45),(30,46),(30,50),(30,53),(30,54),(30,55),(30,56),(30,58),(30,59),(30,60),
(31,2),(31,4),(31,5),(31,7),(31,11),(31,13),(31,18),(31,22),(31,23),(31,24),(31,27),(31,29),(31,31),(31,32),(31,34),(31,35),(31,37),(31,39),(31,41),(31,44),(31,46),(31,47),(31,48),(31,49),(31,53),(31,54),(31,56),(31,58),(31,60),
(32,2),(32,3),(32,4),(32,7),(32,10),(32,12),(32,13),(32,16),(32,17),(32,18),(32,21),(32,22),(32,27),(32,28),(32,32),(32,34),(32,38),(32,42),(32,43),(32,45),(32,46),(32,47),(32,49),(32,53),(32,57),(32,59),
(33,1),(33,8),(33,10),(33,11),(33,12),(33,13),(33,15),(33,16),(33,18),(33,19),(33,24),(33,27),(33,28),(33,31),(33,32),(33,34),(33,37),(33,40),(33,43),(33,47),(33,50),(33,51),(33,52),(33,59),
(34,3),(34,6),(34,8),(34,11),(34,12),(34,20),(34,22),(34,24),(34,28),(34,32),(34,33),(34,35),(34,39),(34,42),(34,43),(34,44),(34,45),(34,47),(34,48),(34,49),(34,55),
(35,1),(35,2),(35,3),(35,5),(35,7),(35,8),(35,10),(35,13),(35,15),(35,17),(35,18),(35,21),(35,22),(35,25),(35,26),(35,29),(35,30),(35,31),(35,44),(35,46),(35,56),(35,60),
(36,1),(36,3),(36,4),(36,9),(36,10),(36,11),(36,14),(36,16),(36,20),(36,23),(36,24),(36,34),(36,35),(36,37),(36,41),(36,42),(36,52),(36,55),(36,56),(36,60),
(37,7),(37,8),(37,11),(37,12),(37,15),(37,18),(37,21),(37,23),(37,24),(37,28),(37,31),(37,37),(37,38),(37,40),(37,41),(37,42),(37,47),(37,48),(37,50),(37,52),(37,53),(37,54),(37,55),(37,58),(37,60),
(38,1),(38,7),(38,8),(38,11),(38,14),(38,19),(38,20),(38,22),(38,23),(38,27),(38,28),(38,29),(38,30),(38,32),(38,34),(38,36),(38,38),(38,39),(38,41),(38,42),(38,43),(38,44),(38,45),(38,46),(38,48),(38,49),(38,51),(38,52),(38,54),(38,58),(38,59),
(39,1),(39,3),(39,6),(39,8),(39,10),(39,13),(39,14),(39,16),(39,18),(39,21),(39,23),(39,26),(39,27),(39,28),(39,29),(39,31),(39,33),(39,35),(39,37),(39,38),(39,39),(39,40),(39,41),(39,43),(39,49),(39,50),(39,51),(39,54),(39,58),(39,60),
(40,2),(40,3),(40,7),(40,8),(40,9),(40,10),(40,11),(40,12),(40,13),(40,14),(40,16),(40,20),(40,23),(40,24),(40,27),(40,28),(40,31),(40,32),(40,33),(40,35),(40,38),(40,40),(40,43),(40,44),(40,53),(40,58),(40,60),
(41,3),(41,8),(41,9),(41,10),(41,12),(41,13),(41,14),(41,17),(41,18),(41,22),(41,23),(41,25),(41,27),(41,31),(41,37),(41,38),(41,39),(41,40),(41,41),(41,42),(41,43),(41,46),(41,47),(41,49),(41,50),(41,51),(41,52),(41,55),(41,59),
(42,2),(42,4),(42,10),(42,11),(42,12),(42,13),(42,16),(42,17),(42,21),(42,25),(42,26),(42,28),(42,29),(42,31),(42,33),(42,34),(42,43),(42,44),(42,46),(42,48),(42,51),(42,52),(42,54),(42,56),
(43,1),(43,5),(43,10),(43,11),(43,14),(43,15),(43,16),(43,17),(43,26),(43,29),(43,34),(43,35),(43,37),(43,38),(43,41),(43,43),(43,48),(43,49),(43,50),(43,53),(43,55),(43,56),(43,58),
(44,1),(44,3),(44,6),(44,8),(44,14),(44,17),(44,19),(44,20),(44,24),(44,26),(44,27),(44,28),(44,29),(44,31),(44,32),(44,41),(44,43),(44,47),(44,48),(44,52),(44,54),(44,57),(44,60),
(45,1),(45,5),(45,6),(45,7),(45,9),(45,11),(45,13),(45,14),(45,20),(45,21),(45,22),(45,26),(45,27),(45,30),(45,32),(45,34),(45,37),(45,38),(45,39),(45,42),(45,43),(45,44),(45,47),(45,48),(45,49),(45,51),(45,52),(45,55),(45,56),(45,58),(45,59),
(46,1),(46,6),(46,13),(46,14),(46,19),(46,24),(46,27),(46,28),(46,29),(46,32),(46,33),(46,34),(46,35),(46,36),(46,37),(46,42),(46,43),(46,44),(46,45),(46,46),(46,50),(46,53),(46,54),(46,57),
(47,1),(47,4),(47,5),(47,6),(47,7),(47,8),(47,10),(47,11),(47,12),(47,16),(47,20),(47,23),(47,24),(47,25),(47,30),(47,31),(47,36),(47,37),(47,39),(47,41),(47,44),(47,46),(47,50),(47,53),(47,54),(47,55),(47,56),(47,58),
(48,6),(48,8),(48,12),(48,16),(48,19),(48,20),(48,24),(48,26),(48,28),(48,29),(48,30),(48,31),(48,34),(48,36),(48,37),(48,38),(48,41),(48,42),(48,44),(48,48),(48,51),(48,53),(48,55),(48,59);

commit