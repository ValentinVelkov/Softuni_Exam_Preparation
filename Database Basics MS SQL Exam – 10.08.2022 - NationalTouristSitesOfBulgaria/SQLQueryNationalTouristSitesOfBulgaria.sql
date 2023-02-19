CREATE DATABASE NationalTouristSitesOfBulgaria

USE NationalTouristSitesOfBulgaria

GO

-- Problem 01
CREATE TABLE Categories(
	[Id] INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
);

CREATE TABLE Locations(
	[Id] INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	[Municipality] VARCHAR(50),
	[Province] VARCHAR(50),
);

CREATE TABLE Sites(
	[Id] INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(100) NOT NULL,
	[LocationId] INT NOT NULL,
	FOREIGN KEY ([LocationId]) REFERENCES [Locations]([Id]),
	[CategoryId] INT NOT NULL,
	FOREIGN KEY ([CategoryId]) REFERENCES [Categories]([Id]),
	[Establishment] VARCHAR(15)
);

CREATE TABLE Tourists(
	[Id] INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL,
	[Age] INT CHECK([Age] >= 0 AND [Age] <= 120) NOT NULL,
	[PhoneNumber] VARCHAR(20) NOT NULL,
	[Nationality] VARCHAR(30) NOT NULL,
	Reward VARCHAR(20)
);

CREATE TABLE SitesTourists(
	[TouristId] INT FOREIGN KEY REFERENCES [Tourists]([Id]),
	[SiteId] INT FOREIGN KEY REFERENCES [Sites]([Id]),
	PRIMARY KEY ([TouristId], [SiteId])
);

CREATE TABLE BonusPrizes(
	[Id] INT PRIMARY KEY IDENTITY,
	[Name] VARCHAR(50) NOT NULL
);

CREATE TABLE TouristsBonusPrizes(
	[TouristId] INT FOREIGN KEY REFERENCES [Tourists]([Id]),
	[BonusPrizeId] INT FOREIGN KEY REFERENCES [BonusPrizes]([Id]),
	PRIMARY KEY ([TouristId], [BonusPrizeId])
);

-- Problem 02
INSERT INTO Tourists(Name, Age, PhoneNumber, Nationality, Reward) VALUES
('Borislava Kazakova', 52, '+359896354244', 'Bulgaria', NULL),
('Peter Bosh', 48, '+447911844141', 'UK', NULL),
('Martin Smith', 29, '+353863818592', 'Ireland', 'Bronze badge'),
('Svilen Dobrev', 49, '+359986584786', 'Bulgaria', 'Silver badge'),
('Kremena Popova', 38, '+359893298604', 'Bulgaria', NULL)

INSERT INTO Sites(Name, LocationId, CategoryId, Establishment) VALUES
('Ustra fortress', 90, 7, 'X'),
('Karlanovo Pyramids', 65, 7, NULL),
('The Tomb of Tsar Sevt', 63, 8, 'V BC'),
('Sinite Kamani Natural Park', 17, 1, NULL),
('St. Petka of Bulgaria – Rupite', 92, 6, '1994')

-- Problem 03
UPDATE Sites
	SET Establishment = '(not defined)'
WHERE Establishment IS NULL


-- Problem 04
DELETE
  FROM [TouristsBonusPrizes]
 WHERE [BonusPrizeId] = (
                            SELECT [id]
                              FROM [BonusPrizes]
                             WHERE Name = 'Sleeping bag'
                        )
DELETE
  FROM [BonusPrizes]
 WHERE  [Name] = 'Sleeping bag'

GO
-- Problem 05
SELECT	[Name],
		[Age],
		[PhoneNumber],
		[Nationality]
	FROM [Tourists]
ORDER BY [Nationality], [Age] DESC, [Name]

-- Problem 06
SELECT	s.[Name] AS [Site],
		l.[Name],
		s.[Establishment],
		c.[Name]
	FROM [Sites] AS s
	JOIN [Locations] AS l
	ON s.[LocationId] = l.[Id]
	JOIN [Categories] AS c
	ON s.[CategoryId] = c.[Id]
ORDER BY c.[Name] DESC, l.[Name], s.[Name] 

-- Problem 07
SELECT	l.[Province],
		l.[Municipality],
		l.[Name] AS [Location],
		COUNT(s.[LocationId]) AS CountOfSites
	FROM [Locations] AS l
	JOIN [Sites] AS s
	ON l.[Id] = s.[LocationId]
WHERE [Province] = 'Sofia'
GROUP BY s.[LocationId], l.[Province], l.[Municipality], l.[Name]
ORDER BY CountOfSites DESC, l.[Name]

-- Problem 08
SELECT	s.[Name] AS [Site],
		l.[Name] AS [Location],
		l.[Municipality],
		l.[Province],
		s.[Establishment]
	FROM [Sites] AS s
	JOIN [Locations] AS l
	ON s.[LocationId] = l.[Id]
WHERE l.[Name] NOT LIKE '[B,M,D]%' AND s.[Establishment] LIKE '%BC%'
ORDER BY s.[Name]

-- Problem 09
SELECT	t.[Name],
		t.[Age],
		t.[PhoneNumber],
		t.[Nationality],
		CAST( 
					CASE 
						WHEN bp.[Name] IS NULL 
							THEN '(no bonus prize)'
						ELSE bp.[Name]
					END AS VARCHAR(50)) 
					AS Reward
	FROM [Tourists] AS t
	LEFT JOIN [TouristsBonusPrizes] AS tbp
	ON t.[Id] = tbp.[TouristId]
	LEFT JOIN [BonusPrizes] AS bp
	ON tbp.[BonusPrizeId] = bp.[Id]
ORDER BY t.[Name]

-- Problem 10
SELECT	SUBSTRING(t.[Name],
                 CHARINDEX(' ', t.[Name]) + 1,
                 LEN(t.[Name]) - CHARINDEX(' ', t.[Name])) AS LastName,
		t.[Nationality],
		t.[Age],
		t.[PhoneNumber]
	FROM [Tourists] AS t
	LEFT JOIN [SitesTourists] AS st
	ON t.[Id] = st.[TouristId]
	LEFT JOIN [Sites] AS s
	ON st.[SiteId] = s.[Id]
	LEFT JOIN [Categories] AS c
	ON s.[CategoryId] = c.[Id]
WHERE c.[Name] LIKE 'History and archaeology'
GROUP BY t.[Nationality],
		t.[Age],
		t.[PhoneNumber],t.[Name]
ORDER BY LastName

-- Problem 11
CREATE FUNCTION udf_GetTouristsCountOnATouristSite (@Site VARCHAR(100)) 
	RETURNS INT
	AS
	BEGIN
		RETURN(
			SELECT COUNT(s.Id) 
				FROM Sites AS s
				JOIN [SitesTourists] AS st
				ON s.[Id] = st.[SiteId]
				JOIN [Tourists] AS t
				ON st.[TouristId] = t.[Id]
				WHERE s.[Name] LIKE @Site
		)
	END

CREATE OR ALTER PROC usp_AnnualRewardLottery @TouristName VARCHAR(50)
	AS
	BEGIN
		SELECT t.[Name],
			CAST(
					CASE
						WHEN COUNT(t.[Id]) >= 100 
							THEN 'Gold badge'
						WHEN COUNT(t.[Id])	>= 50 
							THEN 'Silver badge'
						WHEN COUNT(t.[Id])	>= 25 
							THEN 'Bronze badge'
						END AS VARCHAR(50))
			    AS Reward
			FROM [Tourists] AS t
			JOIN [SitesTourists] AS st
			ON t.[Id] = st.[TouristId]
			JOIN [Sites] AS s
			ON st.[SiteId] = s.[Id]
			WHERE t.[Name] = @TouristName
			GROUP BY t.[Name],t.[Id]
	END
EXEC usp_AnnualRewardLottery 'Stoyan Mitev'
