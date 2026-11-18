-- ============================================================
--  Base de données DepotExpress (MySQL 8.4)
--  Attention : sous Linux (Docker), les noms de tables sont
--  sensibles à la casse. Respecter exactement les noms ci-dessous.
-- ============================================================

CREATE DATABASE IF NOT EXISTS bdd_depotexpress
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bdd_depotexpress;

-- ------------------------------------------------------------
--  Utilisateurs et rôles (spécialisation)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Utilisateur (
  idUser     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nomUser    VARCHAR(50)  NOT NULL,
  prenomUser VARCHAR(50)  NOT NULL,
  mailUser   VARCHAR(100) NOT NULL,
  telUser    VARCHAR(15)  NOT NULL,
  mdpUser    VARCHAR(255) NOT NULL COMMENT 'Hash du mot de passe (bcrypt/argon2), jamais en clair',
  estActif   BOOLEAN      NOT NULL DEFAULT TRUE,
  CONSTRAINT PK_Utilisateur PRIMARY KEY (idUser),
  CONSTRAINT UQ_Utilisateur_mail UNIQUE (mailUser)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Client (
  idClient INT UNSIGNED NOT NULL,
  CONSTRAINT PK_Client PRIMARY KEY (idClient),
  CONSTRAINT FK_Client_Utilisateur FOREIGN KEY (idClient)
    REFERENCES Utilisateur (idUser) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Gestionnaire (
  idGest INT UNSIGNED NOT NULL,
  CONSTRAINT PK_Gestionnaire PRIMARY KEY (idGest),
  CONSTRAINT FK_Gestionnaire_Utilisateur FOREIGN KEY (idGest)
    REFERENCES Utilisateur (idUser) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Preparateur (
  idPrep     INT UNSIGNED NOT NULL,
  estPresent BOOLEAN      NOT NULL DEFAULT FALSE,
  CONSTRAINT PK_Preparateur PRIMARY KEY (idPrep),
  CONSTRAINT FK_Preparateur_Utilisateur FOREIGN KEY (idPrep)
    REFERENCES Utilisateur (idUser) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
--  Adresses des clients
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Adresse (
  idAdress        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  libelleAdresse  VARCHAR(200) NOT NULL,
  idClientAdress  INT UNSIGNED NOT NULL,
  CONSTRAINT PK_Adresse PRIMARY KEY (idAdress),
  CONSTRAINT FK_Adresse_Client FOREIGN KEY (idClientAdress)
    REFERENCES Client (idClient)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
--  Référentiels
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Categorie (
  idCateg      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  libelleCateg VARCHAR(50)  NOT NULL,
  CONSTRAINT PK_Categorie PRIMARY KEY (idCateg),
  CONSTRAINT UQ_Categorie_libelle UNIQUE (libelleCateg)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Statut (
  idStatut      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  libelleStatut VARCHAR(50)  NOT NULL,
  CONSTRAINT PK_Statut PRIMARY KEY (idStatut),
  CONSTRAINT UQ_Statut_libelle UNIQUE (libelleStatut)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
--  Produits
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Produit (
  ean13       CHAR(13)       NOT NULL COMMENT 'Code EAN-13 (texte pour conserver les zéros initiaux)',
  libelleProd VARCHAR(100)   NOT NULL,
  imageProd   VARCHAR(200)   NULL,
  prixTTCProd DECIMAL(10,2)  NOT NULL,
  rayonProd   VARCHAR(20)    NULL,
  seuilAlerte INT UNSIGNED   NOT NULL DEFAULT 0,
  stock       INT            NOT NULL DEFAULT 0,
  estActif    BOOLEAN        NOT NULL DEFAULT TRUE,
  idCategProd INT UNSIGNED   NULL,
  CONSTRAINT PK_Produit PRIMARY KEY (ean13),
  CONSTRAINT FK_Produit_Categorie FOREIGN KEY (idCategProd)
    REFERENCES Categorie (idCateg)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
--  Commandes
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Commande (
  numCMD      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  idAdressCMD INT UNSIGNED NOT NULL,
  idClientCMD INT UNSIGNED NOT NULL,
  idPrepCMD   INT UNSIGNED NOT NULL,
  CONSTRAINT PK_Commande PRIMARY KEY (numCMD),
  CONSTRAINT FK_Commande_Adresse FOREIGN KEY (idAdressCMD)
    REFERENCES Adresse (idAdress),
  CONSTRAINT FK_Commande_Client FOREIGN KEY (idClientCMD)
    REFERENCES Client (idClient),
  CONSTRAINT FK_Commande_Preparateur FOREIGN KEY (idPrepCMD)
    REFERENCES Preparateur (idPrep)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Associer (
  numCMD       INT UNSIGNED  NOT NULL,
  ean13        CHAR(13)      NOT NULL,
  quantite     INT UNSIGNED  NOT NULL,
  prixUnitaire DECIMAL(10,2) NOT NULL COMMENT 'Prix au moment de la commande',
  nbScan       INT UNSIGNED  NOT NULL DEFAULT 0,
  estRetire    BOOLEAN       NOT NULL DEFAULT FALSE,
  CONSTRAINT PK_Associer PRIMARY KEY (numCMD, ean13),
  CONSTRAINT FK_Associer_Commande FOREIGN KEY (numCMD)
    REFERENCES Commande (numCMD) ON DELETE CASCADE,
  CONSTRAINT FK_Associer_Produit FOREIGN KEY (ean13)
    REFERENCES Produit (ean13)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
--  Historiques
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS histStock (
  dateHeure DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  idUser    INT UNSIGNED  NOT NULL,
  ean13     CHAR(13)      NOT NULL,
  motif     VARCHAR(200)  NOT NULL,
  quantite  INT           NOT NULL COMMENT 'Positif = entrée, négatif = sortie',
  CONSTRAINT PK_histStock PRIMARY KEY (idUser, ean13, dateHeure),
  CONSTRAINT FK_histStock_Utilisateur FOREIGN KEY (idUser)
    REFERENCES Utilisateur (idUser),
  CONSTRAINT FK_histStock_Produit FOREIGN KEY (ean13)
    REFERENCES Produit (ean13)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS histImpression (
  dateHeure DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  numCMD    INT UNSIGNED NOT NULL,
  CONSTRAINT PK_histImpression PRIMARY KEY (numCMD, dateHeure),
  CONSTRAINT FK_histImpression_Commande FOREIGN KEY (numCMD)
    REFERENCES Commande (numCMD) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS histAnnulScan (
  dateHeure DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  numCMD    INT UNSIGNED NOT NULL,
  ean13     CHAR(13)     NOT NULL,
  CONSTRAINT PK_histAnnulScan PRIMARY KEY (numCMD, ean13, dateHeure),
  CONSTRAINT FK_histAnnulScan_Commande FOREIGN KEY (numCMD)
    REFERENCES Commande (numCMD) ON DELETE CASCADE,
  CONSTRAINT FK_histAnnulScan_Produit FOREIGN KEY (ean13)
    REFERENCES Produit (ean13)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS histStatut (
  dateHeure DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  numCMD    INT UNSIGNED NOT NULL,
  idUser    INT UNSIGNED NOT NULL COMMENT 'Utilisateur qui a changé le statut',
  idStatut  INT UNSIGNED NOT NULL,
  CONSTRAINT PK_histStatut PRIMARY KEY (numCMD, idUser, idStatut, dateHeure),
  CONSTRAINT FK_histStatut_Commande FOREIGN KEY (numCMD)
    REFERENCES Commande (numCMD) ON DELETE CASCADE,
  CONSTRAINT FK_histStatut_Utilisateur FOREIGN KEY (idUser)
    REFERENCES Utilisateur (idUser),
  CONSTRAINT FK_histStatut_Statut FOREIGN KEY (idStatut)
    REFERENCES Statut (idStatut)
) ENGINE=InnoDB;
