-- ==============================================================================
-- Module: PROG6212 Portfolio of Evidence - Part 1
-- Project: RaceDay Event Management System
-- Target: Microsoft SQL Server / SSMS
-- ==============================================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'RaceDayDb')
BEGIN
    ALTER DATABASE RaceDayDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RaceDayDb;
END
GO

CREATE DATABASE RaceDayDb;
GO

USE RaceDayDb;
GO

-- ==============================================================================
-- 1. TABLE CREATION WITH CONSTRAINTS
-- ==============================================================================

CREATE TABLE Roles (
    RoleId INT IDENTITY(1,1) NOT NULL,
    RoleName NVARCHAR(50) NOT NULL,
    CONSTRAINT PK_Roles PRIMARY KEY CLUSTERED (RoleId),
    CONSTRAINT UQ_Roles_RoleName UNIQUE (RoleName)
);
GO

CREATE TABLE Users (
    UserId INT IDENTITY(1,1) NOT NULL,
    RoleId INT NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Email NVARCHAR(256) NOT NULL,
    PasswordHash NVARCHAR(MAX) NOT NULL,
    ContactNumber NVARCHAR(20) NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId),
    CONSTRAINT UQ_Users_Email UNIQUE (Email),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES Roles(RoleId)
);
GO

CREATE TABLE Events (
    EventId INT IDENTITY(1,1) NOT NULL,
    OrganiserId INT NOT NULL,
    Title NVARCHAR(150) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    Location NVARCHAR(150) NOT NULL,
    StartDate DATETIME2 NOT NULL,
    EndDate DATETIME2 NOT NULL,
    CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_Events_CreatedAt DEFAULT GETUTCDATE(),
    CONSTRAINT PK_Events PRIMARY KEY CLUSTERED (EventId),
    CONSTRAINT FK_Events_Organiser FOREIGN KEY (OrganiserId) REFERENCES Users(UserId),
    CONSTRAINT CK_Events_Dates CHECK (EndDate >= StartDate)
);
GO

CREATE TABLE Categories (
    CategoryId INT IDENTITY(1,1) NOT NULL,
    EventId INT NOT NULL,
    CategoryName NVARCHAR(100) NOT NULL,
    DistanceKm DECIMAL(6,2) NOT NULL,
    EntryFee DECIMAL(10,2) NOT NULL CONSTRAINT DF_Categories_EntryFee DEFAULT 0.00,
    MaxParticipants INT NOT NULL,
    CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED (CategoryId),
    CONSTRAINT FK_Categories_Events FOREIGN KEY (EventId) REFERENCES Events(EventId) ON DELETE CASCADE,
    CONSTRAINT CK_Categories_Distance CHECK (DistanceKm > 0),
    CONSTRAINT CK_Categories_MaxParticipants CHECK (MaxParticipants > 0)
);
GO

CREATE TABLE Enrolments (
    EnrolmentId INT IDENTITY(1,1) NOT NULL,
    CategoryId INT NOT NULL,
    ParticipantId INT NOT NULL,
    EnrolmentDate DATETIME2 NOT NULL CONSTRAINT DF_Enrolments_Date DEFAULT GETUTCDATE(),
    PaymentStatus NVARCHAR(50) NOT NULL CONSTRAINT DF_Enrolments_PaymentStatus DEFAULT 'Confirmed',
    RaceNumber INT NULL,
    CONSTRAINT PK_Enrolments PRIMARY KEY CLUSTERED (EnrolmentId),
    CONSTRAINT FK_Enrolments_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(CategoryId),
    CONSTRAINT FK_Enrolments_Participants FOREIGN KEY (ParticipantId) REFERENCES Users(UserId),
    CONSTRAINT UQ_Enrolments_Participant_Category UNIQUE (ParticipantId, CategoryId)
);
GO

CREATE TABLE Results (
    ResultId INT IDENTITY(1,1) NOT NULL,
    EnrolmentId INT NOT NULL,
    FinishTime TIME(3) NULL,
    OverallPosition INT NULL,
    CategoryPosition INT NULL,
    Status NVARCHAR(20) NOT NULL CONSTRAINT DF_Results_Status DEFAULT 'Finished',
    CONSTRAINT PK_Results PRIMARY KEY CLUSTERED (ResultId),
    CONSTRAINT UQ_Results_EnrolmentId UNIQUE (EnrolmentId),
    CONSTRAINT FK_Results_Enrolments FOREIGN KEY (EnrolmentId) REFERENCES Enrolments(EnrolmentId) ON DELETE CASCADE,
    CONSTRAINT CK_Results_Status CHECK (Status IN ('Finished', 'DNF', 'DNS', 'Disqualified'))
);
GO

-- ==============================================================================
-- 2. SEED DATA POPULATION
-- ==============================================================================

INSERT INTO Roles (RoleName) VALUES ('Organiser'), ('Participant');
GO

INSERT INTO Users (RoleId, FullName, Email, PasswordHash, ContactNumber) VALUES
(1, 'Sipho Sithole', 'sipho@durbanrunners.co.za', 'AQAAAAEAACcQAAAAEPB4vX...SampleHash1', '0821112233'),
(1, 'Elena Van Der Merwe', 'elena@capetownsports.org', 'AQAAAAEAACcQAAAAEPB4vX...SampleHash2', '0834445566'),
(2, 'Kagiso Mokoena', 'kagiso.mokoena@gmail.com', 'AQAAAAEAACcQAAAAEPB4vX...SampleHash3', '0717778899'),
(2, 'Anathi Pillay', 'anathi.pillay@outlook.com', 'AQAAAAEAACcQAAAAEPB4vX...SampleHash4', '0790001122');
GO

INSERT INTO Events (OrganiserId, Title, Description, Location, StartDate, EndDate) VALUES
(1, 'Durban Coastal Marathon & Walk', 'Scenic coastal road run along the beachfront promenade.', 'Durban, KwaZulu-Natal', '2026-10-10 06:00:00', '2026-10-10 14:00:00'),
(1, 'Midlands Classic Cycle Tour', 'Challenging cycling loop through the rolling hills of the Natal Midlands.', 'Pietermaritzburg, KwaZulu-Natal', '2026-11-15 05:30:00', '2026-11-15 16:00:00'),
(2, 'Table Mountain Trail & Road Fest', 'Urban and road trail hybrid race surrounding Table Mountain.', 'Cape Town, Western Cape', '2026-12-05 06:30:00', '2026-12-05 13:00:00');
GO

INSERT INTO Categories (EventId, CategoryName, DistanceKm, EntryFee, MaxParticipants) VALUES
(1, 'Coastal 10km Run/Walk', 10.00, 180.00, 1200),
(1, 'Coastal Half Marathon (21.1km)', 21.10, 260.00, 800),
(2, 'Midlands 45km Open Cycle', 45.00, 320.00, 600),
(2, 'Midlands 100km Elite Challenge', 100.00, 450.00, 400),
(3, 'Foreshore 5km Fun Run', 5.00, 100.00, 1500),
(3, 'Peninsula 15km Road Race', 15.00, 210.00, 750);
GO

INSERT INTO Enrolments (CategoryId, ParticipantId, PaymentStatus, RaceNumber) VALUES
(1, 3, 'Confirmed', 1001), 
(3, 3, 'Confirmed', 2054), 
(2, 4, 'Confirmed', 5420), 
(5, 4, 'Confirmed', 3012); 
GO

INSERT INTO Results (EnrolmentId, FinishTime, OverallPosition, CategoryPosition, Status) VALUES
(1, '00:44:18.000', 14, 3, 'Finished'),
(3, '01:38:42.000', 42, 8, 'Finished');
GO