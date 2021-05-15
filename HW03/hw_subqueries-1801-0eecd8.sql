/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT p.PersonID, p.FullName
FROM Application.People p
WHERE p.IsSalesperson = 1 AND p.PersonID NOT IN 
	(SELECT i.SalespersonPersonID FROM [Sales].[Invoices] i
		WHERE i.InvoiceDate = '20150704')


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT s.StockItemID, s.StockItemName, s.UnitPrice
FROM [Warehouse].[StockItems] s
WHERE s.UnitPrice = 
(SELECT min(st.UnitPrice) from [Warehouse].[StockItems] st)

SELECT s.StockItemID, s.StockItemName, s.UnitPrice
FROM [Warehouse].[StockItems] s
WHERE s.UnitPrice = ANY 
(SELECT min(st.UnitPrice) from [Warehouse].[StockItems] st)

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT top 5 t.CustomerID from Sales.CustomerTransactions t
order by t.TransactionAmount desc;

SELECT c.CustomerID, c.CustomerName
from [Sales].[Customers] c
WHERE c.CustomerID IN 
	(SELECT top 5 CustomerID from Sales.CustomerTransactions t
	 order by t.TransactionAmount desc );

WITH client_max_paym (CustomerID)
AS
( SELECT top 5 t.CustomerID from Sales.CustomerTransactions t
order by t.TransactionAmount desc )
select client_max_paym.CustomerID, ct.CustomerName 
from client_max_paym 
	JOIN [Sales].[Customers] ct ON client_max_paym.CustomerID = ct.CustomerID
group by client_max_paym.CustomerID, ct.CustomerName;

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

; 
WITH CityName (CityId, CityName)
AS 	(SELECT CityId, CityName from [Application].[Cities]), 
PersonName (PersonID, FullName)
AS 	(SELECT PersonID, FullName FROM [Application].[People])
select c.DeliveryCityID, CityName.CityName, PersonName.FullName
from [Sales].[Invoices] inv
join [Sales].[Customers] c ON inv.CustomerID = c.CustomerID
join [Sales].[InvoiceLines] li ON inv.InvoiceID = li.InvoiceID
join CityName ON c.DeliveryCityID = CityName.CityId
JOIN PersonName ON inv.PackedByPersonID = PersonName.PersonID
where li.StockItemID IN 
	(
		SELECT top 3 StockItemID 
				from [Warehouse].[StockItems] 
				order by UnitPrice desc
	)
group by c.DeliveryCityID, CityName.CityName, PersonName.FullName
--join maxprice_item ON li.StockItemID = maxprice_item.StockItemID


select top 5 * from [Sales].[Invoices]


select top 5 * from [Sales].orders
select top 5 * from [Sales].Customers




-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
