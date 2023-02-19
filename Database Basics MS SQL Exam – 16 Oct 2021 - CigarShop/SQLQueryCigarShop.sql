CREATE DATABASE CigarShop

USE CigarShop
GO

CREATE TABLE Sizes
(
 Id INT IDENTITY PRIMARY KEY,
 [Length] INT NOT NULL CHECK([Length] BETWEEN 10 AND 25),
 RingRange DECIMAL (8,2) NOT NULL CHECK(RingRange BETWEEN 1.5 AND 7.5)
)

CREATE TABLE Tastes
(
 Id INT IDENTITY PRIMARY KEY,
 TasteType VARCHAR(20) NOT NULL,
 TasteStrength VARCHAR(15) NOT NULL,
 ImageURL VARCHAR(100) NOT NULL
)

CREATE TABLE Brands
(
 Id INT IDENTITY PRIMARY KEY,
 BrandName VARCHAR(30) UNIQUE NOT NULL,
 BrandDescription VARCHAR(MAX)
)

CREATE TABLE Cigars
(
 Id INT IDENTITY PRIMARY KEY,
 CigarName VARCHAR(80) NOT NULL,
 BrandId INT NOT NULL FOREIGN KEY REFERENCES Brands(Id),
 TastId INT NOT NULL FOREIGN KEY REFERENCES Tastes(Id),
 SizeId INT NOT NULL FOREIGN KEY REFERENCES Sizes(Id),
 PriceForSingleCigar DECIMAL NOT NULL,
 ImageURL VARCHAR(100) NOT NULL
)

CREATE TABLE Addresses
(
 Id INT IDENTITY PRIMARY KEY,
 Town VARCHAR(30) NOT NULL,
 Country VARCHAR(30) NOT NULL,
 Streat VARCHAR(100) NOT NULL,
 ZIP VARCHAR(20) NOT NULL
)

CREATE TABLE Clients
(
 Id INT IDENTITY PRIMARY KEY,
 FirstName VARCHAR(30) NOT NULL,
 LastName VARCHAR(30) NOT NULL,
 Email VARCHAR(50) NOT NULL,
 AddressId INT FOREIGN KEY REFERENCES Addresses(Id)
)

CREATE TABLE ClientsCigars
(
 ClientId INT NOT NULL FOREIGN KEY REFERENCES Clients(Id),
 CigarId INT NOT NULL FOREIGN KEY REFERENCES Cigars(Id),
 PRIMARY KEY (ClientId, CigarId)
)


-- Problem 02
INSERT INTO Cigars (CigarName, BrandId, TastId, SizeId, PriceForSingleCigar, ImageURL) 
VALUES	('COHIBA ROBUSTO', 9, 1, 5, 15.50,'cohiba-robusto-stick_18.jpg'),
		('COHIBA SIGLO I', 9, 1, 10, 410.00,'cohiba-siglo-i-stick_12.jpg'),
		('HOYO DE MONTERREY LE HOYO DU MAIRE', 14, 5, 11, 7.50,'hoyo-du-maire-stick_17.jpg'),
		('HOYO DE MONTERREY LE HOYO DE SAN JUAN', 14, 4, 15, 32.00,'hoyo-de-san-juan-stick_20.jpg'),
		('TRINIDAD COLONIALES', 2, 3, 8, 85.21,'trinidad-coloniales-stick_30.jpg')

INSERT INTO Addresses (Town, Country, Streat, ZIP) 
VALUES	('Sofia','Bulgaria','18 Bul. Vasil levski','1000'),
		('Athens','Greece','4342 McDonald Avenue','10435'),
		('Zagreb','Croatia','4333 Lauren Drive','10000')

-- Problem 03
UPDATE Cigars
SET PriceForSingleCigar *= 1.2
WHERE  TastId = 1
UPDATE Brands
SET BrandDescription = 'New description'
WHERE BrandDescription IS NULL


-- Problem 04

DELETE FROM ClientsCigars
DELETE FROM Clients
DELETE FROM Addresses
WHERE Country LIKE 'C%'

-- Problem 05
SELECT	 CigarName,
		 PriceForSingleCigar,
		 ImageURL
	FROM Cigars
ORDER BY PriceForSingleCigar, CigarName DESC

-- Problem 06
SELECT	c.Id, 
		c.CigarName,
		c.PriceForSingleCigar,
		t.TasteType,
		t.TasteStrength
	FROM Cigars AS c
	JOIN Tastes AS t
	ON c.TastId = t.Id
WHERE t.TasteType IN ('Earthy', 'Woody')
ORDER BY c.PriceForSingleCigar DESC

-- Problem 07
SELECT	cli.Id,
		CONCAT(cli.FirstName, ' ', cli.LastName) AS ClientName,
		cli.Email
	FROM Clients AS cli 
	LEFT JOIN ClientsCigars AS cc
	ON cc.ClientId = cli.Id
	LEFT JOIN Cigars AS cig
	ON cig.Id = cc.CigarId
WHERE cc.CigarId IS NULL
ORDER BY ClientName

-- Problem 08
SELECT	TOP(5) 
		c.CigarName,
		c.PriceForSingleCigar,
		c.ImageURL
	FROM Cigars AS c
	LEFT JOIN Sizes AS s
	ON c.SizeId = s.Id
WHERE s.Length >= 12 AND
	(c.CigarName LIKE '%ci%' OR
	c.PriceForSingleCigar > 50) AND
	s.RingRange > 2.55
ORDER BY c.CigarName, c.PriceForSingleCigar DESC

-- Problem 09
SELECT  CONCAT(c.FirstName, ' ', c.LastName) AS ClientName,
		a.Country,
		a.ZIP,
		CONCAT('$', MAX(cig.PriceForSingleCigar)) AS CigarPrice
	FROM Clients AS c
	JOIN Addresses AS a
	ON c.AddressId = a.Id
	JOIN ClientsCigars AS cc
	ON c.Id = cc.ClientId
	JOIN Cigars AS cig
	ON cc.CigarId = cig.Id
WHERE a.ZIP NOT LIKE '%[^0-9]%'
GROUP BY c.FirstName, c.LastName, a.Country, a.ZIP
ORDER BY c.FirstName

-- Problem 10
SELECT	cli.LastName,
		AVG(s.Length) AS CiagrLength,
		CEILING(AVG(s.RingRange)) AS CiagrRingRange
	FROM Clients AS cli 
	JOIN ClientsCigars AS cc
	ON cli.Id = cc.ClientId 
	JOIN Cigars AS cig
	ON cc.CigarId = cig.Id 
	JOIN Sizes AS s
	ON cig.SizeId = s.Id
WHERE cc.CigarId IS NOT NULL
GROUP BY cli.LastName
ORDER BY AVG(s.Length) DESC

-- Problem 11
GO
CREATE FUNCTION udf_ClientWithCigars (@name NVARCHAR(30))
	RETURNS INT
	AS
	BEGIN
		RETURN(
			SELECT COUNT(c.Id) 
				FROM Clients AS c
				JOIN ClientsCigars AS cc
				ON c.Id = cc.ClientId
				JOIN Cigars AS cig
				ON cc.CigarId = cig.Id
				WHERE c.FirstName LIKE @name
		)
	END
SELECT dbo.udf_ClientWithCigars('Betty')


GO
CREATE PROC usp_SearchByTaste @taste VARCHAR(20)
	AS
	BEGIN
		SELECT	c.CigarName,
				CONCAT('$',c.PriceForSingleCigar) AS Price,
				t.TasteType,
				b.BrandName,
				CONCAT(s.Length, ' cm') AS CigarLength,
				CONCAT(s.RingRange, ' cm') AS CigarRingRange
			FROM Tastes AS t
			JOIN Cigars AS c
			ON t.Id = c.TastId
			JOIN Brands AS b
			ON c.BrandId = b.Id
			JOIN Sizes AS s
			ON c.SizeId = s.Id
			WHERE t.TasteType LIKE @taste
			ORDER BY CigarLength, CigarRingRange DESC
	END

EXEC usp_SearchByTaste 'Woody'