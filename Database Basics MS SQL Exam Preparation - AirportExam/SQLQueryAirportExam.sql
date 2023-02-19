-- Problem 1
CREATE DATABASE Airport

USE Airport

CREATE TABLE Passengers(
	[Id] INT PRIMARY KEY IDENTITY,
	[FullName] VARCHAR(100) UNIQUE NOT NULL,
	[Email]	VARCHAR(50) UNIQUE NOT NULL,
);

CREATE TABLE Pilots(
	[Id] INT PRIMARY KEY IDENTITY,
	[FirstName] VARCHAR(30) UNIQUE NOT NULL,
	[LastName] VARCHAR(30) UNIQUE NOT NULL,
	[Age] TINYINT CHECK ([Age] >= 21 AND [Age] <=62) NOT NULL,
	[Rating] FLOAT CHECK([Rating] >= 0.0 AND [Rating] <= 10.0)
);

CREATE TABLE AircraftTypes(
	[Id] INT PRIMARY KEY IDENTITY,
	[TypeName] VARCHAR(30) UNIQUE NOT NULL
);

CREATE TABLE Aircraft(
	[Id] INT PRIMARY KEY IDENTITY,
	[Manufacturer] VARCHAR(25) NOT NULL,
	[Model]	VARCHAR(30) NOT NULL,
	[Year] INT NOT NULL,
	[FlightHours] INT,
	[Condition] CHAR(1) NOT NULL,
	[TypeId] INT NOT NULL, 
	FOREIGN KEY ([TypeId]) REFERENCES AircraftTypes([Id])
);

CREATE TABLE PilotsAircraft(
	[AircraftId] INT FOREIGN KEY REFERENCES [Aircraft]([Id]),
	[PilotId] INT FOREIGN KEY REFERENCES [Pilots]([Id]),
	PRIMARY KEY ([AircraftId], [PilotId])
);

CREATE TABLE Airports(
	[Id] INT PRIMARY KEY IDENTITY,
	[AirportName] VARCHAR(70) UNIQUE NOT NULL,
	[Country] VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE FlightDestinations(
	[Id] INT PRIMARY KEY IDENTITY,
	[AirportId] INT NOT NULL,
	FOREIGN KEY ([AirportId]) REFERENCES Airports([Id]),
	[Start] DATETIME NOT NULL,
	[AircraftId] INT NOT NULL,
	FOREIGN KEY ([AircraftId]) REFERENCES Aircraft([Id]),
	[PassengerId] INT NOT NULL,
	FOREIGN KEY ([PassengerId]) REFERENCES Passengers([Id]),
	[TicketPrice] DECIMAL(18,2) NOT NULL DEFAULT 15 
);

-- Problem 2
INSERT INTO Passengers  ([FullName], [Email])
SELECT CONCAT(p.[FirstName], ' ',p.[LastName]),
	   CONCAT(p.[FirstName], p.[LastName],'@gmail.com')
FROM [Pilots] AS p
WhERE p.[Id]  BETWEEN 5 AND 15;

INSERT INTO Passengers (FullName, Email)
SELECT
	CONCAT(FirstName, ' ', LastName),
	CONCAT(FirstName, LastName, '@gmail.com')
FROM Pilots WHERE Id >=5 AND Id <= 15;

-- Problem 3
UPDATE	Aircraft
SET [Condition] = 'A'
WHERE [Condition] IN ('C', 'B') AND 
([FlightHours] IS NULL OR [FlightHours] <= 100) AND
[Year] >= 2013

-- Problem 4 Delete every passenger whose FullName is up to 10 characters (inclusive) long.
DELETE
	FROM [Passengers]
	WHERE LEN([FullName]) <= 10

-- Problem 05
SELECT  [Manufacturer],
		[Model],
		[FlightHours],
		[Condition]
   FROM [Aircraft]
ORDER BY [FlightHours] DESC

-- Problem 06
SELECT p.[FirstName],
	   p.[LastName],
	   a.[Manufacturer],
	   a.[Model],
	   a.[FlightHours]
  FROM [Aircraft] AS a
INNER JOIN [PilotsAircraft] AS pa
ON a.[Id] = pa.[AircraftId]
LEFT JOIN [Pilots] AS p
ON pa.[PilotId] = p.[Id]
WHERE a.[FlightHours] IS NOT NULL AND a.[FlightHours] <= 304
ORDER BY a.[FlightHours] DESC, p.[FirstName]

-- Problem 07
SELECT  TOP(20)
		fd.[Id] AS DestinationId,
		fd.[Start],
		p.[FullName],
		a.[AirportName],
		fd.[TicketPrice]
  FROM [FlightDestinations] AS fd
LEFT JOIN [Passengers] AS p
ON fd.[PassengerId] = p.[Id]
LEFT JOIN [Airports] AS a
ON fd.[AirportId] = a.[Id]
WHERE DAY(fd.[Start])%2 = 0
ORDER BY fd.[TicketPrice] DESC, a.[AirportName] 

-- Problem 08
SELECT	fd.[AircraftId],
		a.[Manufacturer],
		a.[FlightHours],
		COUNT(fd.[AircraftId]) AS [FlightDestinationsCount],
		ROUND(AVG(fd.[TicketPrice]) , 2) AS [AvgPrice]
	FROM	[Aircraft] AS a
JOIN [FlightDestinations] AS fd
ON a.[Id] = fd.[AircraftId]
GROUP BY fd.[AircraftId], a.[Manufacturer], a.[FlightHours]
HAVING COUNT(fd.[AircraftId]) > 1
ORDER BY COUNT(fd.[AircraftId]) DESC, fd.[AircraftId]

-- Problem 09
SELECT	p.FullName,
		COUNT(p.Id) AS [CountOfAircraft],
		SUM(fd.[TicketPrice]) AS [TotalPayed]
FROM [Passengers] AS p
	JOIN [FlightDestinations] AS fd
	ON p.[Id] = fd.[PassengerId]
	JOIN [Aircraft] AS a
	ON fd.[AircraftId] = a.[Id] 
WHERE LEFT(p.[FullName], 2) LIKE '%a'
GROUP BY p.Id, p.[FullName]
HAVING COUNT(p.Id) > 1
ORDER BY p.[FullName]

-- Problem 10
SELECT a.[AirportName],
	   fd.[Start] AS [DayTime],
	   fd.[TicketPrice],
	   p.[FullName],
	   air.[Manufacturer],
	   air.[Model]
	FROM [FlightDestinations] AS fd
	LEFT JOIN [Airports] AS a
	ON fd.[AirportId] = a.[Id]
	LEFT JOIN [Passengers] AS p
	ON fd.[PassengerId] = p.[Id]
	LEFT JOIN [Aircraft] AS air
	ON fd.[AircraftId] = air.[Id]
WHERE DATEPART(HOUR, fd.Start) BETWEEN 6 AND 20 AND fd.[TicketPrice] > 2500
ORDER BY air.[Model]

-- Problem 11
GO
CREATE OR ALTER FUNCTION udf_FlightDestinationsByEmail (@email VARCHAR(50))
	RETURNS INT
	AS
	BEGIN
		RETURN(
			SELECT COUNT(fd.[PassengerId])
				FROM Passengers AS p
			LEFT JOIN [FlightDestinations] AS fd
			ON p.[Id] = fd.[PassengerId]
			WHERE p.[Email] = @email
		)	
	END

SELECT dbo.udf_FlightDestinationsByEmail ('Montacute@gmail.com')
GO

-- Problem 12
GO
CREATE OR ALTER PROC usp_SearchByAirportName @airportName VARCHAR(70)
	AS
	BEGIN
		SELECT a.[AirportName],
				p.[FullName],
				CAST( 
					CASE 
						WHEN TicketPrice <= 400 
							THEN 'Low' 
						WHEN TicketPrice BETWEEN 401 AND 1500 
							THEN 'Medium'
						WHEN TicketPrice > 1500 
							THEN 'High' 
						END AS VARCHAR(50)) 
					AS LevelOfTickerPrice,
				air.[Manufacturer],
				air.[Condition],
				airT.[TypeName]
			FROM [Airports] AS a
			LEFT JOIN [FlightDestinations] AS fd
			ON a.[Id] = fd.[AirportId]
			LEFT JOIN [Passengers] AS p
			ON fd.[PassengerId] = p.[Id]
			LEFT JOIN [Aircraft] AS air
			ON fd.[AircraftId] = air.[Id]
			LEFT JOIN [AircraftTypes] AS airT
			ON air.[TypeId] = airT.[Id]
		WHERE a.[AirportName] = @airportName
		ORDER BY air.[Manufacturer], p.[FullName]
	END

EXEC usp_SearchByAirportName 'Sir Seretse Khama International Airport'

