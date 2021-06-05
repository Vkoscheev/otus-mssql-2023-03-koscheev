use master
go

--База данных для учета личного и рабочего времени
CREATE DATABASE [TimeCatch]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'TimeCatch', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQL2019\MSSQL\DATA\TimeCatch.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 8192KB )
 LOG ON 
( NAME = N'TimeCatch_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQL2019\MSSQL\DATA\TimeCatch_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 8192KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO

use TimeCatch
go 


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--Таблица измерения - Активности (задачи)
CREATE TABLE [dbo].[DimActivity](
	[DimActivityId] [int] NOT NULL,
	[TrackerActivityID] [int] NULL,
	[ActivityName] [nvarchar](100) NOT NULL,
	[ActiveFrom] [date] NULL,
	[ActiveTo] [date] NULL,
	[Work] [bit] NULL,
	[Rest] [bit] NULL,
	[RnD] [bit] NULL,
 CONSTRAINT [PK_DimActivity] PRIMARY KEY CLUSTERED 
(
	[DimActivityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--Таблица фактов для потраченного времени
CREATE TABLE [dbo].[FactTimeSpent](
	[FactEntryId] [bigint] NOT NULL,
	[TrackerEntryId] [bigint] NULL,
	[DimActivityId] [int] NOT NULL,
	[Duration] [decimal](6, 1) NOT NULL,
 CONSTRAINT [PK_FactTimeSpent] PRIMARY KEY CLUSTERED 
(
	[FactEntryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[FactTimeSpent]  WITH CHECK ADD  CONSTRAINT [FK_FactTimeSpent_DimActivity] FOREIGN KEY([DimActivityId])
REFERENCES [dbo].[DimActivity] ([DimActivityId])
GO

ALTER TABLE [dbo].[FactTimeSpent] CHECK CONSTRAINT [FK_FactTimeSpent_DimActivity]
GO

ALTER TABLE [dbo].[FactTimeSpent]  WITH CHECK ADD  CONSTRAINT [FK_FactTimeSpent_FactTimeUpload] FOREIGN KEY([TrackerEntryId])
REFERENCES [dbo].[FactTimeUpload] ([TimeEntryID])
GO

ALTER TABLE [dbo].[FactTimeSpent] CHECK CONSTRAINT [FK_FactTimeSpent_FactTimeUpload]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Таблица для загрузки сырых данных из трекера времени
CREATE TABLE [dbo].[FactTimeUpload](
	[TimeEntryID] [bigint] NOT NULL,
	[StartDate] [datetime2](7) NULL,
	[StartTime] [time](0) NULL,
	[StartTimeOffset] [nvarchar](5) NULL,
	[EndDate] [datetime2](7) NULL,
	[EndTime] [time](0) NULL,
	[EndTimeOffset] [nvarchar](5) NULL,
	[Duration] [int] NULL,
	[ActivityID] [int] NOT NULL,
	[Activity] [nvarchar](30) NULL,
	[SpaceId] [int] NULL,
	[Space] [nvarchar](30) NULL,
	[Username] [nvarchar](50) NULL,
	[Note] [nvarchar](200) NULL,
	[Mentions] [nvarchar](200) NULL,
	[Tags] [nvarchar](200) NULL,
 CONSTRAINT [PK_FactTimeUpload] PRIMARY KEY CLUSTERED 
(
	[TimeEntryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO