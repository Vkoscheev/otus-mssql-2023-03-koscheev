/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName from [Warehouse].[StockItems] i
WHERE i.StockItemName like '%urgent%' OR i.StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT s.SupplierID, s.SupplierName FROM [Purchasing].[Suppliers] s
LEFT JOIN [Purchasing].[PurchaseOrders] po 
ON s.SupplierID = po.SupplierID AND s.SupplierReference = po.SupplierReference
WHERE po.PurchaseOrderID is NULL

/*SELECT SupplierID, SupplierReference FROM [Purchasing].[Suppliers] 
EXCEPT 
SELECT SupplierID, SupplierReference FROM [Purchasing].[PurchaseOrders]
*/

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
--Вариант 1

SELECT 
	o.OrderID, 
	CONVERT(nvarchar(30) , OrderDate, 104) AS [Дата заказа], 
	DATENAME(month, ORDERDATE) AS [Месяц заказа],  
	DATEPART(qq, ORDERDATE) AS [Квартал],
	[Треть года] =
	CASE 
		when 
			(cast(cast(datepart(dy, o.orderdate) as real) / (cast(datepart(dy, DATEFROMPARTS(YEAR(o.orderdate), 12, 31) ) as real)) 
				as real))  <= 0.33 
					then 1
		when 
			((cast(cast(datepart(dy, o.orderdate) as real) / (cast(datepart(dy, DATEFROMPARTS(YEAR(o.orderdate), 12, 31) ) as real)) 
				as real))) > 0.33 
			AND 
			((cast(cast(datepart(dy, o.orderdate) as real) / (cast(datepart(dy, DATEFROMPARTS(YEAR(o.orderdate), 12, 31) ) as real)) 
				as real))) <= 0.66 
				then 2
		else 3
	END	,
	c.CustomerName
FROM [Sales].[Orders] o
JOIN [Sales].[OrderLines] l ON o.OrderID = l.OrderID
JOIN [Sales].[Customers] c ON o.customerID = c.CustomerID
WHERE (l.UnitPrice > 100 OR l.Quantity > 20) AND (l.PickingCompletedWhen IS NOT NULL)
ORDER BY [Квартал], [Треть года], o.ORDERDATE


--Вариант 2 с постраничной выборкой

SELECT 
	o.OrderID, 
	CONVERT(nvarchar(30) , OrderDate, 104) AS [Дата заказа], 
	DATENAME(month, ORDERDATE) AS [Месяц заказа],  
	DATEPART(qq, ORDERDATE) AS [Квартал],
	[Треть года] =
	CASE 
		when 
			(cast(cast(datepart(dy, o.orderdate) as real) / (cast(datepart(dy, DATEFROMPARTS(YEAR(o.orderdate), 12, 31) ) as real)) 
				as real))  <= 0.33 
					then 1
		when 
			((cast(cast(datepart(dy, o.orderdate) as real) / (cast(datepart(dy, DATEFROMPARTS(YEAR(o.orderdate), 12, 31) ) as real)) 
				as real))) > 0.33 
			AND 
			((cast(cast(datepart(dy, o.orderdate) as real) / (cast(datepart(dy, DATEFROMPARTS(YEAR(o.orderdate), 12, 31) ) as real)) 
				as real))) <= 0.66 
				then 2
		else 3
	END	,
	c.CustomerName
FROM [Sales].[Orders] o
JOIN [Sales].[OrderLines] l ON o.OrderID = l.OrderID
JOIN [Sales].[Customers] c ON o.customerID = c.CustomerID
WHERE (l.UnitPrice > 100 OR l.Quantity > 20) AND (l.PickingCompletedWhen IS NOT NULL)
ORDER BY [Квартал], [Треть года], o.ORDERDATE
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY;



/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT DeliveryMethodName, ExpectedDeliveryDate, SupplierName, p.FullName
FROM Purchasing.Suppliers s
JOIN Purchasing.PurchaseOrders po ON s.SupplierID = po.SupplierID AND s.SupplierReference = po.SupplierReference
JOIN Application.DeliveryMethods m ON s.DeliveryMethodID = po.DeliveryMethodID
JOIN Application.People p ON po.ContactPersonID = p.PersonID
WHERE po.IsOrderFinalized = 1 AND
(po.ExpectedDeliveryDate >= '20130101' AND po.ExpectedDeliveryDate >= '20130131') AND
(m.DeliveryMethodName = 'Air Freight' OR m.DeliveryMethodName = 'Refrigerated Air Freight')

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10 o.OrderID, c.CustomerName, p.FullName as 'Имя сотрудника'
FROM Sales.Orders o
JOIN [Sales].[Customers] c ON o.CustomerID = c.CustomerID
JOIN [Application].[People] p ON o.SalespersonPersonID = p.PersonID
ORDER BY o.orderdate DESC


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT c.CustomerID, CustomerName, PhoneNumber FROM
[Sales].[Invoices] i
JOIN [Sales].[InvoiceLines] l ON i.InvoiceID = l.InvoiceID
JOIN [Sales].[Customers] c ON i.CustomerID = c.CustomerID
JOIN [Warehouse].[StockItems] s ON l.StockItemID = s.StockItemID
WHERE s.StockItemName = 'Chocolate frogs 250g'
GROUP BY c.CustomerID, CustomerName, PhoneNumber
--ORDER BY c.CustomerID

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
year(i.InvoiceDate) as 'Год',
month(i.InvoiceDate) as 'Месяц',
SUM(l.Quantity * l.UnitPrice) as 'Сумма', 
AVG(l.UnitPrice) As  'Ср.цена'
FROM [Sales].[Invoices] i
JOIN [Sales].[InvoiceLines] l ON i.InvoiceID = l.InvoiceID
GROUP BY YEAR(i.InvoiceDate), month(i.InvoiceDate)


/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
year(i.InvoiceDate) as 'Год',
month(i.InvoiceDate) as 'Месяц',
SUM(l.Quantity * l.UnitPrice) as 'Сумма'
FROM [Sales].[Invoices] i
JOIN [Sales].[InvoiceLines] l ON i.InvoiceID = l.InvoiceID
GROUP BY YEAR(i.InvoiceDate), month(i.InvoiceDate)
HAVING SUM(l.Quantity * l.UnitPrice) > 10000;
--ORDER BY  YEAR(i.InvoiceDate), month(i.InvoiceDate)
/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
year(i.InvoiceDate) as 'Год',
month(i.InvoiceDate) as 'Месяц',
l.StockItemID,
SUM(l.Quantity * l.UnitPrice) as 'Сумма'
FROM [Sales].[Invoices] i
JOIN [Sales].[InvoiceLines] l ON i.InvoiceID = l.InvoiceID
GROUP BY YEAR(i.InvoiceDate), month(i.InvoiceDate), l.StockItemID
HAVING SUM(l.[Quantity]) < 50;
--ORDER BY  YEAR(i.InvoiceDate), month(i.InvoiceDate)



-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
