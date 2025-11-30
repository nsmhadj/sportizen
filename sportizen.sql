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
  seq_complexe,
  seq_terrain,
  seq_creneau,
  seq_match,
  seq_equipe,
  seq_reservation
CASCADE;


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


CREATE TABLE organisateur (
  id_organisateur INTEGER PRIMARY KEY,              
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



INSERT INTO ville (nom, code_postal, pays) VALUES
('Paris',         '75000', 'France'),
('Lyon',          '69000', 'France'),
('Marseille',     '13000', 'France'),
('Lille',         '59000', 'France'),
('Nantes',        '44000', 'France'),
('Toulouse',      '31000', 'France'),
('Bordeaux',      '33000', 'France'),
('Nice',          '06000', 'France'),
('Angers',        '49000', 'France'),
('Strasbourg',    '67000', 'France'),
('Nancy',         '54000', 'France'),
('Saint-Étienne', '42000', 'France'),
('Lens',          '62300', 'France'),
('Le Havre',      '76600', 'France'),
('Reims',         '51100', 'France'),
('Dijon',         '21000', 'France'),
('Brest',         '29200', 'France'),
('Orléans',       '45000', 'France'),
('Sochaux',       '25600', 'France'),
-- nouvelles villes
('Rennes',        '35000', 'France'),
('Montpellier',   '34000', 'France'),
('Grenoble',      '38000', 'France');




INSERT INTO complexe (nom, adresse, id_ville) VALUES
-- 1 : Paris
('Complexe Jean Bouin',
 '12 Rue du Stade, Paris', 1),

 -- 3 : Lyon
('Complexe Gerland',
 '5 Rue des Lions, Lyon', 2),


-- 4 : Marseille
('Complexe Vélodrome',
 '45 Boulevard du Sud, Marseille', 3),


-- 2 : Lille
('Complexe Pierre Mauroy',
 '23 Avenue du Sport, Lille', 4),



-- 5 : Nantes
('Complexe la Beaujoire',
 '78 Rue des Fleurs, Nantes', 5),

 -- 17 : Toulouse
('Complexe Stadium Toulouse',
 'Allée du Stadium, Toulouse', 6),

 -- 14 : Bordeaux
('Complexe Matmut Atlantique',
 '25 Rue Atlantique, Bordeaux', 7),

 -- 9 : Nice
('Complexe Allianz Riviera',
 '40 Chemin des Pins, Nice', 8),


-- 18 : Angers
('Complexe Raymond-Kopa',
 'Rue du Stade, Angers', 9),

-- 19 : Strasbourg
('Complexe de la Meinau',
 'Rue de la Meinau, Strasbourg', 10),


-- 6 : Nancy
('Complexe Marcel Picot',
 '33 Rue des Sports, Nancy', 11),

-- 7 : Saint-Étienne
('Complexe Geoffroy-Guichard',
 '99 Avenue Verte, Saint-Étienne', 12),

-- 8 : Lens
('Complexe Bollaert-Delelis',
 '27 Rue du Nord, Lens', 13),



-- 10 : Le Havre
('Complexe Océane',
 '3 Rue du Havre, Le Havre', 14),

-- 11 : Reims
('Complexe Auguste Delaune',
 '11 Rue du Stade, Reims', 15),

-- 12 : Dijon
('Complexe Gaston Gérard',
 '17 Rue des Vignes, Dijon', 16),

-- 13 : Brest
('Complexe Francis Le Blé',
 '8 Rue des Capucins, Brest', 17),



-- 15 : Orléans
('Complexe Stade de la Source',
 '56 Rue du Parc, Orléans', 18),

-- 16 : Sochaux
('Complexe Stade Bonal',
 '9 Avenue de la Liberté, Sochaux', 19),



-- 20 : Rennes (ville avec plusieurs complexes)
('Roazhon Park',
 '111 Rue de Lorient, Rennes', 20),

-- 21 : Rennes encore
('Complexe Sud Rennes',
 '5 Avenue du Stade, Rennes', 20),

-- 22 : Montpellier
('Complexe Mosson',
 '12 Rue des Sports, Montpellier', 21),

-- 23 : Grenoble
('Complexe des Alpes',
 '8 Avenue des Jeux Olympiques, Grenoble', 22);


/* ======================================================
   TERRAINS
   (3 terrains par complexe : T1, T2, T3)
   id_terrain vient de la séquence, on ne le met pas.
   ====================================================== */

INSERT INTO terrain (code_terrain, indoor, eclairage, id_complexe) VALUES
-- Complexe 1 : Jean Bouin (Paris)
('T1', FALSE, TRUE,  1),
('T2', FALSE, TRUE,  1),
('T3', TRUE,  TRUE,  1),

-- Complexe 2 : Pierre Mauroy (Lille)
('T1', FALSE, TRUE,  2),
('T2', FALSE, FALSE, 2),
('T3', TRUE,  TRUE,  2),

-- Complexe 3 : Gerland (Lyon)
('T1', TRUE,  TRUE,  3),
('T2', FALSE, TRUE,  3),
('T3', FALSE, FALSE, 3),

-- Complexe 4 : Vélodrome (Marseille)
('T1', TRUE,  TRUE,  4),
('T2', FALSE, TRUE,  4),
('T3', FALSE, FALSE, 4),

-- Complexe 5 : la Beaujoire (Nantes)
('T1', FALSE, TRUE,  5),
('T2', FALSE, FALSE, 5),
('T3', TRUE,  TRUE,  5),

-- Complexe 6 : Marcel Picot (Nancy)
('T1', FALSE, TRUE,  6),
('T2', TRUE,  TRUE,  6),
('T3', FALSE, FALSE, 6),

-- Complexe 7 : Geoffroy-Guichard (Saint-Étienne)
('T1', TRUE,  TRUE,  7),
('T2', FALSE, TRUE,  7),
('T3', FALSE, FALSE, 7),

-- Complexe 8 : Bollaert-Delelis (Lens)
('T1', FALSE, TRUE,  8),
('T2', FALSE, FALSE, 8),
('T3', TRUE,  TRUE,  8),

-- Complexe 9 : Allianz Riviera (Nice)
('T1', FALSE, TRUE,  9),
('T2', FALSE, TRUE,  9),
('T3', TRUE,  TRUE,  9),

-- Complexe 10 : Océane (Le Havre)
('T1', FALSE, TRUE,  10),
('T2', FALSE, FALSE, 10),
('T3', TRUE,  TRUE,  10),

-- Complexe 11 : Auguste Delaune (Reims)
('T1', FALSE, TRUE,  11),
('T2', TRUE,  TRUE,  11),
('T3', FALSE, FALSE, 11),

-- Complexe 12 : Gaston Gérard (Dijon)
('T1', FALSE, TRUE,  12),
('T2', TRUE,  TRUE,  12),
('T3', FALSE, FALSE, 12),

-- Complexe 13 : Francis Le Blé (Brest)
('T1', FALSE, TRUE,  13),
('T2', FALSE, FALSE, 13),
('T3', TRUE,  TRUE,  13),

-- Complexe 14 : Matmut Atlantique (Bordeaux)
('T1', FALSE, TRUE,  14),
('T2', FALSE, TRUE,  14),
('T3', TRUE,  TRUE,  14),

-- Complexe 15 : Stade de la Source (Orléans)
('T1', FALSE, TRUE,  15),
('T2', FALSE, FALSE, 15),
('T3', TRUE,  TRUE,  15),

-- Complexe 16 : Stade Bonal (Sochaux)
('T1', FALSE, TRUE,  16),
('T2', FALSE, FALSE, 16),
('T3', TRUE,  TRUE,  16),

-- Complexe 17 : Stadium Toulouse
('T1', FALSE, TRUE,  17),
('T2', FALSE, TRUE,  17),
('T3', TRUE,  TRUE,  17),

-- Complexe 18 : Raymond-Kopa (Angers)
('T1', FALSE, TRUE,  18),
('T2', FALSE, FALSE, 18),
('T3', TRUE,  TRUE,  18),

-- Complexe 19 : Meinau (Strasbourg)
('T1', FALSE, TRUE,  19),
('T2', FALSE, FALSE, 19),
('T3', TRUE,  TRUE,  19),

-- Complexe 20 : Roazhon Park (Rennes)
('T1', FALSE, TRUE,  20),
('T2', FALSE, TRUE,  20),
('T3', TRUE,  TRUE,  20),

-- Complexe 21 : Complexe Sud Rennes
('T1', TRUE,  TRUE,  21),
('T2', FALSE, FALSE, 21),
('T3', FALSE, TRUE,  21),

-- Complexe 22 : Mosson (Montpellier)
('T1', FALSE, TRUE,  22),
('T2', FALSE, FALSE, 22),
('T3', TRUE,  TRUE,  22),

-- Complexe 23 : des Alpes (Grenoble)
('T1', TRUE,  TRUE,  23),
('T2', FALSE, TRUE,  23),
('T3', FALSE, FALSE, 23);



INSERT INTO creneau (id_creneau, debut_ts, fin_ts) VALUES
(nextval('seq_creneau'), '2025-12-08 10:00:00', '2025-12-08 12:00:00'),
(nextval('seq_creneau'), '2025-12-08 12:00:00', '2025-12-08 14:00:00'),
(nextval('seq_creneau'), '2025-12-08 14:00:00', '2025-12-08 16:00:00'),
(nextval('seq_creneau'), '2025-12-08 16:00:00', '2025-12-08 18:00:00'),
(nextval('seq_creneau'), '2025-12-08 18:00:00', '2025-12-08 20:00:00'),
(nextval('seq_creneau'), '2025-12-09 10:00:00', '2025-12-09 12:00:00'),
(nextval('seq_creneau'), '2025-12-09 12:00:00', '2025-12-09 14:00:00'),
(nextval('seq_creneau'), '2025-12-09 14:00:00', '2025-12-09 16:00:00'),
(nextval('seq_creneau'), '2025-12-09 16:00:00', '2025-12-09 18:00:00'),
(nextval('seq_creneau'), '2025-12-09 18:00:00', '2025-12-09 20:00:00'),
(nextval('seq_creneau'), '2025-12-10 10:00:00', '2025-12-10 12:00:00'),
(nextval('seq_creneau'), '2025-12-10 12:00:00', '2025-12-10 14:00:00'),
(nextval('seq_creneau'), '2025-12-10 14:00:00', '2025-12-10 16:00:00'),
(nextval('seq_creneau'), '2025-12-10 16:00:00', '2025-12-10 18:00:00'),
(nextval('seq_creneau'), '2025-12-10 18:00:00', '2025-12-10 20:00:00'),
(nextval('seq_creneau'),'2025-12-11 10:00:00', '2025-12-11 12:00:00'),
(nextval('seq_creneau'),'2025-12-11 12:00:00', '2025-12-11 14:00:00'),
(nextval('seq_creneau'),'2025-12-11 14:00:00', '2025-12-11 16:00:00'),
(nextval('seq_creneau'),'2025-12-11 16:00:00', '2025-12-11 18:00:00'),
(nextval('seq_creneau'),'2025-12-12 10:00:00', '2025-12-12 12:00:00'),
(nextval('seq_creneau'),'2025-12-12 12:00:00', '2025-12-12 14:00:00'),
(nextval('seq_creneau'),'2025-12-12 14:00:00', '2025-12-12 16:00:00'),
(nextval('seq_creneau'),'2025-12-12 16:00:00', '2025-12-12 18:00:00'),
(nextval('seq_creneau'),'2025-12-13 10:00:00', '2025-12-13 12:00:00'),
(nextval('seq_creneau'),'2025-12-13 12:00:00', '2025-12-13 14:00:00'),
(nextval('seq_creneau'),'2025-12-13 14:00:00', '2025-12-13 16:00:00'),
(nextval('seq_creneau'),'2025-12-13 16:00:00', '2025-12-13 18:00:00'),
(nextval('seq_creneau'),'2025-12-14 10:00:00', '2025-12-14 12:00:00'),
(nextval('seq_creneau'),'2025-12-14 12:00:00', '2025-12-14 14:00:00'),
(nextval('seq_creneau'),'2025-12-14 14:00:00', '2025-12-14 16:00:00'),
(nextval('seq_creneau'),'2025-12-14 16:00:00', '2025-12-14 18:00:00'),
(nextval('seq_creneau'),'2025-12-15 10:00:00', '2025-12-15 12:00:00'),
(nextval('seq_creneau'),'2025-12-15 12:00:00', '2025-12-15 14:00:00'),
(nextval('seq_creneau'),'2025-12-15 14:00:00', '2025-12-15 16:00:00'),
(nextval('seq_creneau'),'2025-12-15 16:00:00', '2025-12-15 18:00:00'),
(nextval('seq_creneau'),'2025-12-16 10:00:00', '2025-12-16 12:00:00'),
(nextval('seq_creneau'),'2025-12-16 12:00:00', '2025-12-16 14:00:00'),
(nextval('seq_creneau'),'2025-12-16 14:00:00', '2025-12-16 16:00:00'),
(nextval('seq_creneau'),'2025-12-16 16:00:00', '2025-12-16 18:00:00'),
(nextval('seq_creneau'),'2025-12-17 10:00:00', '2025-12-17 12:00:00'),
(nextval('seq_creneau'),'2025-12-17 12:00:00', '2025-12-17 14:00:00'),
(nextval('seq_creneau'),'2025-12-17 14:00:00', '2025-12-17 16:00:00'),
(nextval('seq_creneau'),'2025-12-17 16:00:00', '2025-12-17 18:00:00'),
(nextval('seq_creneau'),'2025-12-18 10:00:00', '2025-12-18 12:00:00'),
(nextval('seq_creneau'),'2025-12-18 12:00:00', '2025-12-18 14:00:00'),
(nextval('seq_creneau'),'2025-12-18 14:00:00', '2025-12-18 16:00:00'),
(nextval('seq_creneau'),'2025-12-18 16:00:00', '2025-12-18 18:00:00'),
(nextval('seq_creneau'),'2025-12-19 10:00:00', '2025-12-19 12:00:00'),
(nextval('seq_creneau'),'2025-12-19 12:00:00', '2025-12-19 14:00:00'),
(nextval('seq_creneau'),'2025-12-19 14:00:00', '2025-12-19 16:00:00'),
(nextval('seq_creneau'),'2025-12-19 16:00:00', '2025-12-19 18:00:00'),
(nextval('seq_creneau'),'2025-12-20 10:00:00', '2025-12-20 12:00:00'),
(nextval('seq_creneau'),'2025-12-20 12:00:00', '2025-12-20 14:00:00'),
(nextval('seq_creneau'),'2025-12-20 14:00:00', '2025-12-20 16:00:00'),
(nextval('seq_creneau'),'2025-12-20 16:00:00', '2025-12-20 18:00:00'),
(nextval('seq_creneau'), '2025-12-21 10:00:00', '2025-12-21 12:00:00'),
(nextval('seq_creneau'), '2025-12-21 12:00:00', '2025-12-21 14:00:00'),
(nextval('seq_creneau'), '2025-12-21 14:00:00', '2025-12-21 16:00:00'),
(nextval('seq_creneau'), '2025-12-21 16:00:00', '2025-12-21 18:00:00'),
(nextval('seq_creneau'), '2025-12-21 18:00:00', '2025-12-21 20:00:00'),
(nextval('seq_creneau'), '2025-12-22 10:00:00', '2025-12-22 12:00:00'),
(nextval('seq_creneau'), '2025-12-22 12:00:00', '2025-12-22 14:00:00'),
(nextval('seq_creneau'), '2025-12-22 14:00:00', '2025-12-22 16:00:00'),
(nextval('seq_creneau'), '2025-12-22 16:00:00', '2025-12-22 18:00:00'),
(nextval('seq_creneau'), '2025-12-22 18:00:00', '2025-12-22 20:00:00'),
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
(nextval('seq_creneau'), '2026-01-06 18:00:00', '2026-01-06 20:00:00'),
(nextval('seq_creneau'), '2026-01-08 10:00:00', '2026-01-08 12:00:00'),
(nextval('seq_creneau'), '2026-01-08 12:00:00', '2026-01-08 14:00:00'),
(nextval('seq_creneau'), '2026-01-08 14:00:00', '2026-01-08 16:00:00'),
(nextval('seq_creneau'), '2026-01-08 16:00:00', '2026-01-08 18:00:00'),
(nextval('seq_creneau'), '2026-01-08 18:00:00', '2026-01-08 20:00:00'),
(nextval('seq_creneau'), '2026-01-10 10:00:00', '2026-01-10 12:00:00'),
(nextval('seq_creneau'), '2026-01-10 12:00:00', '2026-01-10 14:00:00'),
(nextval('seq_creneau'), '2026-01-10 14:00:00', '2026-01-10 16:00:00'),
(nextval('seq_creneau'), '2026-01-10 16:00:00', '2026-01-10 18:00:00'),
(nextval('seq_creneau'), '2026-01-10 18:00:00', '2026-01-10 20:00:00'),
(nextval('seq_creneau'), '2026-01-12 10:00:00', '2026-01-12 12:00:00'),
(nextval('seq_creneau'), '2026-01-12 12:00:00', '2026-01-12 14:00:00'),
(nextval('seq_creneau'), '2026-01-12 14:00:00', '2026-01-12 16:00:00'),
(nextval('seq_creneau'), '2026-01-12 16:00:00', '2026-01-12 18:00:00'),
(nextval('seq_creneau'), '2026-01-12 18:00:00', '2026-01-12 20:00:00'),
(nextval('seq_creneau'), '2026-01-14 10:00:00', '2026-01-14 12:00:00'),
(nextval('seq_creneau'), '2026-01-14 12:00:00', '2026-01-14 14:00:00'),
(nextval('seq_creneau'), '2026-01-14 14:00:00', '2026-01-14 16:00:00'),
(nextval('seq_creneau'), '2026-01-14 16:00:00', '2026-01-14 18:00:00'),
(nextval('seq_creneau'), '2026-01-14 18:00:00', '2026-01-14 20:00:00'),
(nextval('seq_creneau'), '2026-01-16 10:00:00', '2026-01-16 12:00:00'),
(nextval('seq_creneau'), '2026-01-16 12:00:00', '2026-01-16 14:00:00'),
(nextval('seq_creneau'), '2026-01-16 14:00:00', '2026-01-16 16:00:00'),
(nextval('seq_creneau'), '2026-01-16 16:00:00', '2026-01-16 18:00:00'),
(nextval('seq_creneau'), '2026-01-16 18:00:00', '2026-01-16 20:00:00'),
(nextval('seq_creneau'), '2026-01-18 10:00:00', '2026-01-18 12:00:00'),
(nextval('seq_creneau'), '2026-01-18 12:00:00', '2026-01-18 14:00:00'),
(nextval('seq_creneau'), '2026-01-18 14:00:00', '2026-01-18 16:00:00'),
(nextval('seq_creneau'), '2026-01-18 16:00:00', '2026-01-18 18:00:00'),
(nextval('seq_creneau'), '2026-01-18 18:00:00', '2026-01-18 20:00:00'),
(nextval('seq_creneau'), '2026-01-20 10:00:00', '2026-01-20 12:00:00'),
(nextval('seq_creneau'), '2026-01-20 12:00:00', '2026-01-20 14:00:00'),
(nextval('seq_creneau'), '2026-01-20 14:00:00', '2026-01-20 16:00:00'),
(nextval('seq_creneau'), '2026-01-20 16:00:00', '2026-01-20 18:00:00'),
(nextval('seq_creneau'), '2026-01-20 18:00:00', '2026-01-20 20:00:00'),
(nextval('seq_creneau'), '2026-01-22 10:00:00', '2026-01-22 12:00:00'),
(nextval('seq_creneau'), '2026-01-22 12:00:00', '2026-01-22 14:00:00'),
(nextval('seq_creneau'), '2026-01-22 14:00:00', '2026-01-22 16:00:00'),
(nextval('seq_creneau'), '2026-01-22 16:00:00', '2026-01-22 18:00:00'),
(nextval('seq_creneau'), '2026-01-22 18:00:00', '2026-01-22 20:00:00'),
(nextval('seq_creneau'), '2025-11-30 18:40:00', '2025-11-30 18:42:00');



INSERT INTO dispo_terrain (id_terrain, id_creneau)
SELECT t.id_terrain, c.id_creneau
FROM terrain t
CROSS JOIN creneau c;


COMMIT;
