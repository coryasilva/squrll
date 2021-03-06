DROP DATABASE IF EXISTS squrll_test;
CREATE DATABASE squrll_test TEMPLATE template0;

\c squrll_test

CREATE TABLE tenant (
   id BIGSERIAL PRIMARY KEY
  ,display_name TEXT
  ,active BOOLEAN DEFAULT TRUE
  ,created_date TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO tenant ( id, display_name ) VALUES
   ( 1, 'Company A' )
  ,( 2, 'Company B' )
  ,( 3, 'Company C' )
;

CREATE TABLE enduser (
   id BIGSERIAL PRIMARY KEY
  ,display_name TEXT NOT NULL
  ,active BOOLEAN DEFAULT TRUE
  ,created_date TIMESTAMPTZ DEFAULT NOW()
  ,tenant_id BIGSERIAL REFERENCES tenant ( id )
);

INSERT INTO enduser ( id, display_name, active, tenant_id ) VALUES
   ( 1, 'Bob', TRUE, 1 )
  ,( 2, 'Janet', TRUE, 1 )
  ,( 3, 'Maria', TRUE, 1 )
  ,( 4, 'Rachael', TRUE, 2 )
  ,( 5, 'Mattew', FALSE, 2 )
  ,( 6, 'William', TRUE,  2 )
  ,( 7, 'Michelle', TRUE,  3 )
  ,( 8, 'Keith', TRUE, 3 )
  ,( 9, 'Sharron', FALSE, 3 )
;

CREATE TABLE category (
   id TEXT PRIMARY KEY UNIQUE
  ,display_name TEXT NOT NULL
);

INSERT INTO category ( id, display_name ) VALUES
   ( 'quote', 'Estimate' )
  ,( 'purchase_order', 'Purchase Order' )
  ,( 'sales_order', 'Sales Order' )
  ,( 'invoice', 'Invoice' )
  ,( 'receipt', 'Receipt' )
  ,( 'work_order', 'Work Order' )
  ,( 'other', 'Other' )
;

CREATE TABLE document (
   id BIGSERIAL PRIMARY KEY
  ,likes BIGINT DEFAULT 0
  ,title TEXT NOT NULL
  ,summary TEXT
  ,date TIMESTAMPTZ
  ,document JSONB
  ,created_date TIMESTAMPTZ DEFAULT NOW()
  ,category_id TEXT NOT NULL REFERENCES category ( id )
  ,enduser_id BIGSERIAL NOT NULL REFERENCES enduser ( id )
  ,tenant_id BIGSERIAL NOT NULL REFERENCES tenant ( id )
);

INSERT INTO document (
   id
  ,likes
  ,title
  ,summary
  ,date
  ,category_id
  ,enduser_id
  ,tenant_id
) VALUES
   ( 1, 27, 'Xerox Quote 001', '50 multi-function machines', '2018-01-01T00:00:00', 'quote', 1, 1 )
  ,( 2, 0, 'Xerox Purchase Order 001', 'We converted them!', '2018-01-02T06:00:00', 'purchase_order', 1, 1 )
  ,( 3, 1, 'Xerox Sales Order 001', '50 multi-function machines', '2018-01-03T12:00:00', 'sales_order', 2, 1 )
  ,( 4, 46, 'Xerox Invoice 001', 'Get dat money', '2018-01-04T00:00:00', 'invoice', 2, 1 )
  ,( 5, 35, 'Receipt', 'personal expense, don''t tell the IRS', '2018-01-05T06:00:00', 'receipt', 3, 1 )
  ,( 6, 17, 'RMA', '15 defective units', '2018-01-06T12:00:00', 'work_order', 3, 1 )
  ,( 7, 99, 'Damaged Shipment', '5 crushed pallets', '2018-01-07T00:00:00', 'other', 4, 2 )
  ,( 8, 56, 'Ricoh Quote', '100 copiers', '2018-01-08T06:00:00', 'quote', 4, 2 )
  ,( 9, 55, 'Ricoh Purchase Order', '100 copiers', '2018-01-09T12:00:00', 'purchase_order', 5, 2 )
  ,( 10, 21, 'Ricoh Sales Order', '100 copiers', '2018-01-10T00:00:00', 'sales_order', 5, 2 )
  ,( 11, 68, 'Invoice 2018-01-01-0001', NULL, '2018-01-11T06:00:00', 'invoice', 6, 2 )
  ,( 12, 77, 'Draft Receipt', 'Draft receipt, do not use me', '2018-01-12T12:00:00', 'receipt', 6, 2 )
  ,( 13, 73, 'WO 2100', '50 multi-function machines', '2018-01-13T00:00:00', 'work_order', 7, 3 )
  ,( 14, 44, 'Family Photo', NULL, '2018-01-14T06:00:00', 'other', 7, 3 )
  ,( 15, 51, 'HP EST-001', '150 laser printers', '2018-01-15T12:00:00', 'quote', 8, 3 )
  ,( 16, 20, 'HP PO-001', '150 laser printers', '2018-01-16T00:00:00', 'purchase_order', 8, 3 )
  ,( 17, 80, 'HP SO-001', '150 laser printers', '2018-01-17T06:00:00', 'sales_order', 9, 3 )
  ,( 18, 90, 'HP INV-0001', '150 laser printers', '2018-01-18T12:00:00', 'invoice', 9, 3 )
;

CREATE VIEW enduser_document AS
  SELECT
     doc.*
    ,usr.display_name AS "enduser_display_name"
    ,cat.display_name AS "category_display_name"
    ,ten.display_name AS "tenant_display_name"
  FROM
     document doc
    ,enduser usr
    ,category cat
    ,tenant ten
  WHERE doc.enduser_id = usr.id
    AND doc.category_id = cat.id
    AND doc.tenant_id = ten.id
;