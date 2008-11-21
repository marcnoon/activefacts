CREATE TABLE Bin (
	BinID	int NOT NULL,
	ProductID	int NULL,
	Quantity	int NOT NULL,
	WarehouseID	int NULL,
	UNIQUE(BinID)
)
GO

CREATE TABLE DirectOrderMatch (
	PurchaseOrderItemProductID	int NOT NULL,
	PurchaseOrderItemPurchaseOrderID	int NOT NULL,
	SalesOrderItemProductID	int NOT NULL,
	SalesOrderItemSalesOrderID	int NOT NULL,
	UNIQUE(PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID, SalesOrderItemSalesOrderID, SalesOrderItemProductID)
)
GO

CREATE TABLE DispatchItem (
	DispatchItemID	int NOT NULL,
	DispatchID	int NULL,
	ProductID	int NOT NULL,
	Quantity	int NOT NULL,
	SalesOrderItemProductID	int NULL,
	SalesOrderItemSalesOrderID	int NULL,
	TransferRequestID	int NULL,
	UNIQUE(DispatchItemID)
)
GO

CREATE TABLE Party (
	PartyID	int NOT NULL,
	UNIQUE(PartyID)
)
GO

CREATE TABLE Product (
	ProductID	int NOT NULL,
	UNIQUE(ProductID)
)
GO

CREATE TABLE PurchaseOrder (
	PurchaseOrderID	int NOT NULL,
	SupplierID	int NOT NULL,
	WarehouseID	int NOT NULL,
	UNIQUE(PurchaseOrderID)
)
GO

CREATE TABLE PurchaseOrderItem (
	ProductID	int NOT NULL,
	PurchaseOrderID	int NOT NULL,
	Quantity	int NOT NULL,
	UNIQUE(PurchaseOrderID, ProductID),
	FOREIGN KEY(ProductID)
	REFERENCES Product(ProductID),
	FOREIGN KEY(PurchaseOrderID)
	REFERENCES PurchaseOrder(PurchaseOrderID)
)
GO

CREATE TABLE ReceivedItem (
	ReceivedItemID	int NOT NULL,
	ProductID	int NOT NULL,
	PurchaseOrderItemProductID	int NULL,
	PurchaseOrderItemPurchaseOrderID	int NULL,
	Quantity	int NOT NULL,
	ReceiptID	int NULL,
	TransferRequestID	int NULL,
	UNIQUE(ReceivedItemID),
	FOREIGN KEY(ProductID)
	REFERENCES Product(ProductID),
	FOREIGN KEY(PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID)
	REFERENCES PurchaseOrderItem(PurchaseOrderID, ProductID)
)
GO

CREATE TABLE SalesOrder (
	SalesOrderID	int NOT NULL,
	CustomerID	int NOT NULL,
	WarehouseID	int NOT NULL,
	UNIQUE(SalesOrderID)
)
GO

CREATE TABLE SalesOrderItem (
	ProductID	int NOT NULL,
	SalesOrderID	int NOT NULL,
	Quantity	int NOT NULL,
	UNIQUE(SalesOrderID, ProductID),
	FOREIGN KEY(ProductID)
	REFERENCES Product(ProductID),
	FOREIGN KEY(SalesOrderID)
	REFERENCES SalesOrder(SalesOrderID)
)
GO

CREATE TABLE TransferRequest (
	TransferRequestID	int NOT NULL,
	FromWarehouseID	int NULL,
	ToWarehouseID	int NULL,
	UNIQUE(TransferRequestID)
)
GO

CREATE TABLE Warehouse (
	WarehouseID	int NOT NULL,
	UNIQUE(WarehouseID)
)
GO

ALTER TABLE Bin
	ADD FOREIGN KEY(ProductID)
	REFERENCES Product(ProductID)
GO

ALTER TABLE Bin
	ADD FOREIGN KEY(WarehouseID)
	REFERENCES Warehouse(WarehouseID)
GO

ALTER TABLE DirectOrderMatch
	ADD FOREIGN KEY(PurchaseOrderItemPurchaseOrderID, PurchaseOrderItemProductID)
	REFERENCES PurchaseOrderItem(PurchaseOrderID, ProductID)
GO

ALTER TABLE DirectOrderMatch
	ADD FOREIGN KEY(SalesOrderItemSalesOrderID, SalesOrderItemProductID)
	REFERENCES SalesOrderItem(SalesOrderID, ProductID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY(ProductID)
	REFERENCES Product(ProductID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY(SalesOrderItemSalesOrderID, SalesOrderItemProductID)
	REFERENCES SalesOrderItem(SalesOrderID, ProductID)
GO

ALTER TABLE DispatchItem
	ADD FOREIGN KEY(TransferRequestID)
	REFERENCES TransferRequest(TransferRequestID)
GO

ALTER TABLE PurchaseOrder
	ADD FOREIGN KEY(SupplierID)
	REFERENCES Supplier(PartyID)
GO

ALTER TABLE PurchaseOrder
	ADD FOREIGN KEY(WarehouseID)
	REFERENCES Warehouse(WarehouseID)
GO

ALTER TABLE ReceivedItem
	ADD FOREIGN KEY(TransferRequestID)
	REFERENCES TransferRequest(TransferRequestID)
GO

ALTER TABLE SalesOrder
	ADD FOREIGN KEY(CustomerID)
	REFERENCES Customer(PartyID)
GO

ALTER TABLE SalesOrder
	ADD FOREIGN KEY(WarehouseID)
	REFERENCES Warehouse(WarehouseID)
GO

ALTER TABLE TransferRequest
	ADD FOREIGN KEY(FromWarehouseID)
	REFERENCES Warehouse(WarehouseID)
GO

ALTER TABLE TransferRequest
	ADD FOREIGN KEY(ToWarehouseID)
	REFERENCES Warehouse(WarehouseID)
GO

