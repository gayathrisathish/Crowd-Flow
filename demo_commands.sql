Last login: Sat Apr 25 20:27:45 on ttys001
gayathrisathish@192 ~ % brew services start mysql@8.4
Service `mysql@8.4` already started, use `brew services restart mysql@8.4` to restart.
gayathrisathish@192 ~ % brew services stop mysql@8.4
Stopping `mysql@8.4`... (might take a while)
==> Successfully stopped `mysql@8.4` (label: homebrew.mxcl.mysql@8.4)
gayathrisathish@192 ~ % brew services start mysql@8.4
==> Successfully started `mysql@8.4` (label: homebrew.mxcl.mysql@8.4)
gayathrisathish@192 ~ % brew services list | grep mysql
mysql     none                            
mysql@8.4 stopped         gayathrisathish ~/Library/LaunchAgents/homebrew.mxcl.mysql@8.4.plist
gayathrisathish@192 ~ % mysql -u root -proot
mysql: [Warning] Using a password on the command line interface can be insecure.
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: YES)
gayathrisathish@192 ~ % ps -p 573 -f
  UID   PID  PPID   C STIME   TTY           TIME CMD
   74   573     1   0  8:27PM ??         0:02.14 /usr/local/mysql/bin/mysqld --user=_mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --plugin-dir=/usr/local/mysql/lib/plugin --log-error=/usr/local/mysql/data/mysqld.local.err --pid-file=/usr/local/mysql/data/mysqld.local.pid
gayathrisathish@192 ~ % sudo kill 573
Password:
gayathrisathish@192 ~ % lsof -nP -iTCP:3306 -sTCP:LISTEN
gayathrisathish@192 ~ % brew services start mysql@8.4
==> Successfully started `mysql@8.4` (label: homebrew.mxcl.mysql@8.4)
gayathrisathish@192 ~ % brew services list | grep mysql
mysql     none                            
mysql@8.4 started         gayathrisathish ~/Library/LaunchAgents/homebrew.mxcl.mysql@8.4.plist
gayathrisathish@192 ~ % mysql -u root -proot
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 8
Server version: 8.4.9 Homebrew

Copyright (c) 2000, 2026, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> mysql -u root -proot crowd_flow
    -> 
    -> ^C

^C
mysql> CREATE DATABASE IF NOT EXISTS crowd_flow;
Query OK, 1 row affected, 1 warning (0.00 sec)

mysql> USE crowd_flow;
Database changed
mysql> SELECT DATABASE();
+------------+
| DATABASE() |
+------------+
| crowd_flow |
+------------+
1 row in set (0.00 sec)

mysql> -- 1. Users Table
Query OK, 0 rows affected (0.00 sec)

mysql> USE railway;
ERROR 1049 (42000): Unknown database 'railway'
mysql> 
mysql> CREATE TABLE users (
    ->     user_id       INT AUTO_INCREMENT PRIMARY KEY,
    ->     username      VARCHAR(100) NOT NULL UNIQUE,
    ->     password_hash VARCHAR(255) NOT NULL,
    ->     role          ENUM('admin', 'attendee') NOT NULL DEFAULT 'attendee',
    ->     registered_at DATETIME DEFAULT CURRENT_TIMESTAMP
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> -- 2. Events Table
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE events (
    ->     event_id INT AUTO_INCREMENT PRIMARY KEY,
    ->     name     VARCHAR(255) NOT NULL,
    ->     location VARCHAR(255) NOT NULL,
    ->     date     DATETIME NOT NULL
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> -- 3. Tickets Table
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE tickets (
    ->     ticket_pk_id INT AUTO_INCREMENT PRIMARY KEY,
    ->     ticket_id    VARCHAR(100) NOT NULL UNIQUE,
    ->     user_id      INT NOT NULL,
    ->     event_id     INT NOT NULL,
    ->     status       ENUM('active','used','cancelled') NOT NULL DEFAULT 'active',
    ->     FOREIGN KEY (user_id)  REFERENCES users(user_id)   ON DELETE CASCADE ON UPDATE CASCADE,
    ->     FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE ON UPDATE CASCADE
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> -- 4. Crowd Verifications Table
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE crowd_verifications (
    ->     verification_id INT AUTO_INCREMENT PRIMARY KEY,
    ->     ticket_pk_id    INT NOT NULL,
    ->     verified_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    ->     verifier_id     INT NOT NULL,
    ->     FOREIGN KEY (ticket_pk_id) REFERENCES tickets(ticket_pk_id) ON DELETE CASCADE,
    ->     FOREIGN KEY (verifier_id)  REFERENCES users(user_id)        ON DELETE CASCADE
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> -- 5. Alerts Table
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE alerts (
    ->     alert_id   INT AUTO_INCREMENT PRIMARY KEY,
    ->     event_id   INT NOT NULL,
    ->     message    TEXT NOT NULL,
    ->     level      ENUM('alert','safe') NOT NULL DEFAULT 'alert',
    ->     created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    ->     FOREIGN KEY (event_id) REFERENCES events(event_id) ON DELETE CASCADE
    -> );
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> -- 6. Audit Logs Table
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE audit_logs (
    ->     audit_id  INT AUTO_INCREMENT PRIMARY KEY,
    ->     action    VARCHAR(255) NOT NULL,
    ->     user_id   INT NULL,
    ->     timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    ->     details   TEXT NULL,
    ->     CONSTRAINT fk_audit_user_id FOREIGN KEY (user_id) REFERENCES users(user_id)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> -- 7. Crowd Points Table
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE crowd_points (
    ->     crowd_point_id INT AUTO_INCREMENT PRIMARY KEY,
    ->     event_id       INT NOT NULL,
    ->     lat            FLOAT NOT NULL,
    ->     lng            FLOAT NOT NULL,
    ->     created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    ->     CONSTRAINT fk_cp_event_id FOREIGN KEY (event_id) REFERENCES events(event_id)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> -- 1. Insert Users
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO users (username, password_hash, role, registered_at) VALUES
    ->     ('admin', 'hashed_admin123', 'admin',    '2026-03-20 09:00:00'),
    ->     ('user1', 'hashed_user123',  'attendee', '2026-03-20 09:05:00'),
    ->     ('user2', 'hashed_user123',  'attendee', '2026-03-20 09:10:00'),
    ->     ('user3', 'hashed_user123',  'attendee', '2026-03-20 09:15:00'),
    ->     ('user4', 'hashed_user123',  'attendee', '2026-03-20 09:20:00'),
    ->     ('user5', 'hashed_user123',  'attendee', '2026-03-20 09:25:00'),
    ->     ('user6', 'hashed_user123',  'attendee', '2026-03-20 09:30:00'),
    ->     ('user7', 'hashed_user123',  'attendee', '2026-03-20 09:35:00'),
    ->     ('user8', 'hashed_user123',  'attendee', '2026-03-20 09:40:00'),
    ->     ('user9', 'hashed_user123',  'attendee', '2026-03-20 09:45:00');
Query OK, 10 rows affected (0.00 sec)
Records: 10  Duplicates: 0  Warnings: 0

mysql> 
mysql> -- 2. Insert Events
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO events (name, location, date) VALUES
    ->     ('Rock Concert',    'Stadium A',   '2026-05-20 19:00:00'),
    ->     ('Tech Conference', 'Expo Center', '2026-06-15 09:00:00'),
    ->     ('Football Match',  'Arena B',     '2026-07-10 18:00:00'),
    ->     ('Jazz Festival',   'Park C',      '2026-08-05 17:00:00'),
    ->     ('Startup Meetup',  'Hotel D',     '2026-09-01 10:00:00');
Query OK, 5 rows affected (0.00 sec)
Records: 5  Duplicates: 0  Warnings: 0

mysql> 
mysql> -- 3. Insert Tickets
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO tickets (ticket_id, user_id, event_id, status) VALUES
    ->     ('TKT0001', 1,  1, 'active'),
    ->     ('TKT0002', 2,  1, 'used'),
    ->     ('TKT0003', 3,  1, 'cancelled'),
    ->     ('TKT0004', 4,  1, 'active'),
    ->     ('TKT0005', 5,  1, 'active'),
    ->     ('TKT0006', 6,  2, 'used'),
    ->     ('TKT0007', 7,  2, 'active'),
    ->     ('TKT0008', 8,  2, 'cancelled'),
    ->     ('TKT0009', 9,  2, 'active'),
    ->     ('TKT0010', 10, 3, 'used'),
    ->     ('TKT0011', 1,  3, 'active'),
    ->     ('TKT0012', 2,  3, 'cancelled'),
    ->     ('TKT0013', 3,  3, 'active'),
    ->     ('TKT0014', 4,  4, 'used'),
    ->     ('TKT0015', 5,  4, 'active'),
    ->     ('TKT0016', 6,  4, 'cancelled'),
    ->     ('TKT0017', 7,  5, 'used'),
    ->     ('TKT0018', 8,  5, 'active'),
    ->     ('TKT0019', 9,  5, 'cancelled'),
    ->     ('TKT0020', 10, 5, 'active');
Query OK, 20 rows affected (0.00 sec)
Records: 20  Duplicates: 0  Warnings: 0

mysql> 
mysql> -- 4. Insert Crowd Verifications
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO crowd_verifications (ticket_pk_id, verified_at, verifier_id) VALUES
    ->     (1,  '2026-03-20 13:00:00', 2),
    ->     (2,  '2026-03-20 13:07:00', 3),
    ->     (4,  '2026-03-20 13:14:00', 4),
    ->     (6,  '2026-03-20 13:21:00', 5),
    ->     (8,  '2026-03-20 13:28:00', 6),
    ->     (10, '2026-03-20 13:35:00', 7),
    ->     (12, '2026-03-20 13:42:00', 8),
    ->     (14, '2026-03-20 13:49:00', 9);
Query OK, 8 rows affected (0.00 sec)
Records: 8  Duplicates: 0  Warnings: 0

mysql> 
mysql> -- 5. Insert Alerts
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO alerts (event_id, message, level, created_at) VALUES
    ->     (1, 'Crowd density high near entrance.', 'alert', '2026-03-20 10:00:00'),
    ->     (1, 'Situation under control.',          'safe',  '2026-03-20 11:30:00'),
    ->     (2, 'Capacity at 90%.',                  'alert', '2026-03-20 10:05:00'),
    ->     (2, 'Flow normalized.',                  'safe',  '2026-03-20 12:00:00'),
    ->     (3, 'Gate B congestion reported.',       'alert', '2026-03-20 11:00:00'),
    ->     (3, 'Gate B cleared.',                   'safe',  '2026-03-20 12:15:00'),
    ->     (4, 'Medical team on standby.',          'alert', '2026-03-20 11:15:00'),
    ->     (4, 'No incidents reported.',            'safe',  '2026-03-20 12:30:00'),
    ->     (5, 'Overflow at registration desk.',    'alert', '2026-03-20 10:30:00'),
    ->     (5, 'Registration queue cleared.',       'safe',  '2026-03-20 11:45:00');
Query OK, 10 rows affected (0.00 sec)
Records: 10  Duplicates: 0  Warnings: 0

mysql> 
mysql> -- 6. Insert Audit Logs
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO audit_logs (action, user_id, timestamp, details) VALUES
    ->     ('login',       1, '2026-03-20 09:30:00', 'Administrator login'),
    ->     ('ticket_scan', 2, '2026-03-20 10:16:00', 'Ticket TKT0002 scanned at gate A');
Query OK, 2 rows affected (0.00 sec)
Records: 2  Duplicates: 0  Warnings: 0

mysql> 
mysql> -- 7. Insert Crowd Points
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO crowd_points (event_id, lat, lng, created_at) VALUES
    ->     (1, 37.7700, -122.4100, '2026-03-20 10:00:00'),
    ->     (1, 37.7750, -122.4050, '2026-03-20 10:05:00');
Query OK, 2 rows affected (0.00 sec)
Records: 2  Duplicates: 0  Warnings: 0

mysql> -- 2nf
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE ORDERS_2NF (
    ->     OrderID      VARCHAR(20) PRIMARY KEY,
    ->     OrderDate    DATE,
    ->     CustomerID   VARCHAR(20),
    ->     CustomerName VARCHAR(100)
    -> );
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> CREATE TABLE PRODUCT_2NF (
    ->     ProductID   VARCHAR(20) PRIMARY KEY,
    ->     ProductName VARCHAR(100)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> CREATE TABLE SUPPLIER_2NF (
    ->     SupplierID   VARCHAR(20) PRIMARY KEY,
    ->     SupplierName VARCHAR(100)
    -> );
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> CREATE TABLE ORDER_LINE_2NF (
    ->     OrderID   VARCHAR(20),
    ->     ProductID VARCHAR(20),
    ->     Qty       INT,
    ->     PRIMARY KEY (OrderID, ProductID)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> CREATE TABLE ORDER_LINE_SUPPLIER_2NF (
    ->     OrderID   VARCHAR(20),
    ->     ProductID VARCHAR(20),
    ->     SupplierID VARCHAR(20),
    ->     PRIMARY KEY (OrderID, ProductID, SupplierID)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> CREATE TABLE ORDER_SHIPMENT_MODE_2NF (
    ->     OrderID      VARCHAR(20),
    ->     ShipmentMode VARCHAR(30),
    ->     PRIMARY KEY (OrderID, ShipmentMode)
    -> );
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> CREATE TABLE ORDER_COUPON_2NF (
    ->     OrderID    VARCHAR(20),
    ->     CouponCode VARCHAR(30),
    ->     PRIMARY KEY (OrderID, CouponCode)
    -> );
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> CREATE TABLE CUSTOMER_PHONE_2NF (
    ->     CustomerID    VARCHAR(20),
    ->     CustomerPhone VARCHAR(20),
    ->     PRIMARY KEY (CustomerID, CustomerPhone)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> -- 3NF
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE CUSTOMER (
    ->     CustomerID   VARCHAR(20) PRIMARY KEY,
    ->     CustomerName VARCHAR(100)
    -> );
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> CREATE TABLE ORDERS (
    ->     OrderID    VARCHAR(20) PRIMARY KEY,
    ->     OrderDate  DATE,
    ->     CustomerID VARCHAR(20),
    ->     FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> -- Q1
Query OK, 0 rows affected (0.00 sec)

mysql> ALTER TABLE tickets MODIFY status ENUM('active', 'used', 'cancelled') NOT NULL DEFAULT 'active';
Query OK, 0 rows affected (0.01 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> ALTER TABLE tickets DROP CHECK ck_tickets_valid_status;
ERROR 3821 (HY000): Check constraint 'ck_tickets_valid_status' is not found in the table.
mysql> ALTER TABLE tickets ADD CONSTRAINT ck_tickets_valid_status
    ->     CHECK (status IN ('active', 'used', 'cancelled'));
Query OK, 20 rows affected (0.02 sec)
Records: 20  Duplicates: 0  Warnings: 0

mysql> 
mysql> -- Q2: constraint already exists from previous run, just verify it works
Query OK, 0 rows affected (0.00 sec)

mysql> -- This INSERT should FAIL with a duplicate error — that IS the expected output
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO tickets (ticket_id, user_id, event_id, status)
    -> VALUES ('TKT_TEST', 1, 1, 'active');
Query OK, 1 row affected (0.00 sec)

mysql> -- Expected: Error Code 1062 - Duplicate entry for key 'uq_tickets_user_event'
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> -- Q3
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT
    ->     t.ticket_pk_id, t.ticket_id, t.status,
    ->     u.user_id, u.username,
    ->     e.event_id, e.name AS event_name
    -> FROM tickets t
    -> JOIN users  u ON u.user_id  = t.user_id
    -> JOIN events e ON e.event_id = t.event_id
    -> WHERE t.status IN ('active', 'used', 'cancelled');
+--------------+-----------+-----------+---------+----------+----------+-----------------+
| ticket_pk_id | ticket_id | status    | user_id | username | event_id | event_name      |
+--------------+-----------+-----------+---------+----------+----------+-----------------+
|            1 | TKT0001   | active    |       1 | admin    |        1 | Rock Concert    |
|            2 | TKT0002   | used      |       2 | user1    |        1 | Rock Concert    |
|            3 | TKT0003   | cancelled |       3 | user2    |        1 | Rock Concert    |
|            4 | TKT0004   | active    |       4 | user3    |        1 | Rock Concert    |
|            5 | TKT0005   | active    |       5 | user4    |        1 | Rock Concert    |
|           21 | TKT_TEST  | active    |       1 | admin    |        1 | Rock Concert    |
|            6 | TKT0006   | used      |       6 | user5    |        2 | Tech Conference |
|            7 | TKT0007   | active    |       7 | user6    |        2 | Tech Conference |
|            8 | TKT0008   | cancelled |       8 | user7    |        2 | Tech Conference |
|            9 | TKT0009   | active    |       9 | user8    |        2 | Tech Conference |
|           10 | TKT0010   | used      |      10 | user9    |        3 | Football Match  |
|           11 | TKT0011   | active    |       1 | admin    |        3 | Football Match  |
|           12 | TKT0012   | cancelled |       2 | user1    |        3 | Football Match  |
|           13 | TKT0013   | active    |       3 | user2    |        3 | Football Match  |
|           14 | TKT0014   | used      |       4 | user3    |        4 | Jazz Festival   |
|           15 | TKT0015   | active    |       5 | user4    |        4 | Jazz Festival   |
|           16 | TKT0016   | cancelled |       6 | user5    |        4 | Jazz Festival   |
|           17 | TKT0017   | used      |       7 | user6    |        5 | Startup Meetup  |
|           18 | TKT0018   | active    |       8 | user7    |        5 | Startup Meetup  |
|           19 | TKT0019   | cancelled |       9 | user8    |        5 | Startup Meetup  |
|           20 | TKT0020   | active    |      10 | user9    |        5 | Startup Meetup  |
+--------------+-----------+-----------+---------+----------+----------+-----------------+
21 rows in set (0.00 sec)

mysql> 
mysql> 
mysql> -- Q1: Total tickets per event
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT
    ->     e.event_id,
    ->     e.name AS event_name,
    ->     COUNT(t.ticket_pk_id) AS total_tickets
    -> FROM events e
    -> LEFT JOIN tickets t ON t.event_id = e.event_id
    -> GROUP BY e.event_id, e.name
    -> ORDER BY e.event_id;
+----------+-----------------+---------------+
| event_id | event_name      | total_tickets |
+----------+-----------------+---------------+
|        1 | Rock Concert    |             6 |
|        2 | Tech Conference |             4 |
|        3 | Football Match  |             4 |
|        4 | Jazz Festival   |             3 |
|        5 | Startup Meetup  |             4 |
+----------+-----------------+---------------+
5 rows in set (0.00 sec)

mysql> 
mysql> -- Q2: Count of active, used, and cancelled tickets
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT
    ->     status,
    ->     COUNT(*) AS ticket_count
    -> FROM tickets
    -> GROUP BY status
    -> ORDER BY FIELD(status, 'active', 'used', 'cancelled');
+-----------+--------------+
| status    | ticket_count |
+-----------+--------------+
| active    |           11 |
| used      |            5 |
| cancelled |            5 |
+-----------+--------------+
3 rows in set (0.00 sec)

mysql> 
mysql> -- Q3: Alert count and latest alert time per event
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT
    ->     e.event_id,
    ->     e.name AS event_name,
    ->     COUNT(a.alert_id) AS alert_count,
    ->     MAX(a.created_at) AS latest_alert_time
    -> FROM events e
    -> LEFT JOIN alerts a ON a.event_id = e.event_id
    -> GROUP BY e.event_id, e.name
    -> ORDER BY e.event_id;
+----------+-----------------+-------------+---------------------+
| event_id | event_name      | alert_count | latest_alert_time   |
+----------+-----------------+-------------+---------------------+
|        1 | Rock Concert    |           3 | 2026-04-25 15:43:16 |
|        2 | Tech Conference |           5 | 2026-04-25 15:43:56 |
|        3 | Football Match  |           2 | 2026-03-20 12:15:00 |
|        4 | Jazz Festival   |           2 | 2026-03-20 12:30:00 |
|        5 | Startup Meetup  |           2 | 2026-03-20 11:45:00 |
+----------+-----------------+-------------+---------------------+
5 rows in set (0.01 sec)

mysql> -- Q1: Users who booked a ticket OR performed a verification (UNION)
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT u.user_id, u.username FROM users u
    -> JOIN tickets t ON t.user_id = u.user_id
    -> UNION
    -> SELECT u.user_id, u.username FROM users u
    -> JOIN crowd_verifications cv ON cv.verifier_id = u.user_id
    -> ORDER BY user_id;
+---------+----------+
| user_id | username |
+---------+----------+
|       1 | admin    |
|       2 | user1    |
|       3 | user2    |
|       4 | user3    |
|       5 | user4    |
|       6 | user5    |
|       7 | user6    |
|       8 | user7    |
|       9 | user8    |
|      10 | user9    |
+---------+----------+
10 rows in set (0.00 sec)

mysql> 
mysql> -- Q2: Users who booked tickets but NEVER verified any ticket
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT DISTINCT u.user_id, u.username
    -> FROM users u
    -> JOIN tickets t ON t.user_id = u.user_id
    -> WHERE NOT EXISTS (
    ->     SELECT 1 FROM crowd_verifications cv WHERE cv.verifier_id = u.user_id
    -> )
    -> ORDER BY u.user_id;
+---------+----------+
| user_id | username |
+---------+----------+
|       1 | admin    |
|      10 | user9    |
+---------+----------+
2 rows in set (0.00 sec)

mysql> 
mysql> -- Q3: Users who BOTH booked and verified tickets
Query OK, 0 rows affected (0.00 sec)

mysql> -- NOTE: MySQL does not support INTERSECT — using JOIN equivalent
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT DISTINCT u.user_id, u.username
    -> FROM users u
    -> JOIN tickets t              ON t.user_id      = u.user_id
    -> JOIN crowd_verifications cv ON cv.verifier_id = u.user_id
    -> ORDER BY u.user_id;
+---------+----------+
| user_id | username |
+---------+----------+
|       2 | user1    |
|       3 | user2    |
|       4 | user3    |
|       5 | user4    |
|       6 | user5    |
|       7 | user6    |
|       8 | user7    |
|       9 | user8    |
+---------+----------+
8 rows in set (0.00 sec)

mysql> -- Q1: Events with ticket counts above the average
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT event_id, event_name, ticket_count
    -> FROM (
    ->     SELECT
    ->         e.event_id,
    ->         e.name AS event_name,
    ->         COUNT(t.ticket_pk_id) AS ticket_count
    ->     FROM events e
    ->     LEFT JOIN tickets t ON t.event_id = e.event_id
    ->     GROUP BY e.event_id, e.name
    -> ) AS event_ticket_counts
    -> WHERE ticket_count > (
    ->     SELECT AVG(ticket_total)
    ->     FROM (
    ->         SELECT COUNT(t2.ticket_pk_id) AS ticket_total
    ->         FROM events e2
    ->         LEFT JOIN tickets t2 ON t2.event_id = e2.event_id
    ->         GROUP BY e2.event_id
    ->     ) AS avg_source
    -> )
    -> ORDER BY ticket_count DESC, event_id;
+----------+--------------+--------------+
| event_id | event_name   | ticket_count |
+----------+--------------+--------------+
|        1 | Rock Concert |            6 |
+----------+--------------+--------------+
1 row in set (0.00 sec)

mysql> 
mysql> -- Q2: Users who own at least one active ticket
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT u.user_id, u.username
    -> FROM users u
    -> WHERE EXISTS (
    ->     SELECT 1 FROM tickets t
    ->     WHERE t.user_id = u.user_id AND t.status = 'active'
    -> )
    -> ORDER BY u.user_id;
+---------+----------+
| user_id | username |
+---------+----------+
|       1 | admin    |
|       3 | user2    |
|       4 | user3    |
|       5 | user4    |
|       7 | user6    |
|       8 | user7    |
|       9 | user8    |
|      10 | user9    |
+---------+----------+
8 rows in set (0.00 sec)

mysql> 
mysql> -- Q3: Tickets for events scheduled after the earliest event date
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT
    ->     t.ticket_pk_id, t.ticket_id, t.status,
    ->     e.event_id, e.name AS event_name, e.date AS event_date
    -> FROM tickets t
    -> JOIN events e ON e.event_id = t.event_id
    -> WHERE e.date > (SELECT MIN(date) FROM events)
    -> ORDER BY e.date, t.ticket_pk_id;
+--------------+-----------+-----------+----------+-----------------+---------------------+
| ticket_pk_id | ticket_id | status    | event_id | event_name      | event_date          |
+--------------+-----------+-----------+----------+-----------------+---------------------+
|            6 | TKT0006   | used      |        2 | Tech Conference | 2026-06-15 09:00:00 |
|            7 | TKT0007   | active    |        2 | Tech Conference | 2026-06-15 09:00:00 |
|            8 | TKT0008   | cancelled |        2 | Tech Conference | 2026-06-15 09:00:00 |
|            9 | TKT0009   | active    |        2 | Tech Conference | 2026-06-15 09:00:00 |
|           10 | TKT0010   | used      |        3 | Football Match  | 2026-07-10 18:00:00 |
|           11 | TKT0011   | active    |        3 | Football Match  | 2026-07-10 18:00:00 |
|           12 | TKT0012   | cancelled |        3 | Football Match  | 2026-07-10 18:00:00 |
|           13 | TKT0013   | active    |        3 | Football Match  | 2026-07-10 18:00:00 |
|           14 | TKT0014   | used      |        4 | Jazz Festival   | 2026-08-05 17:00:00 |
|           15 | TKT0015   | active    |        4 | Jazz Festival   | 2026-08-05 17:00:00 |
|           16 | TKT0016   | cancelled |        4 | Jazz Festival   | 2026-08-05 17:00:00 |
|           17 | TKT0017   | used      |        5 | Startup Meetup  | 2026-09-01 10:00:00 |
|           18 | TKT0018   | active    |        5 | Startup Meetup  | 2026-09-01 10:00:00 |
|           19 | TKT0019   | cancelled |        5 | Startup Meetup  | 2026-09-01 10:00:00 |
|           20 | TKT0020   | active    |        5 | Startup Meetup  | 2026-09-01 10:00:00 |
+--------------+-----------+-----------+----------+-----------------+---------------------+
15 rows in set (0.00 sec)

mysql> -- Q1: Ticket, user, and event details together
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT
    ->     t.ticket_pk_id, t.ticket_id, t.status,
    ->     u.user_id, u.username,
    ->     e.event_id, e.name AS event_name, e.location, e.date AS event_date
    -> FROM tickets t
    -> JOIN users  u ON u.user_id  = t.user_id
    -> JOIN events e ON e.event_id = t.event_id
    -> ORDER BY t.ticket_pk_id;
+--------------+-----------+-----------+---------+----------+----------+-----------------+-------------+---------------------+
| ticket_pk_id | ticket_id | status    | user_id | username | event_id | event_name      | location    | event_date          |
+--------------+-----------+-----------+---------+----------+----------+-----------------+-------------+---------------------+
|            1 | TKT0001   | active    |       1 | admin    |        1 | Rock Concert    | Stadium A   | 2026-05-20 19:00:00 |
|            2 | TKT0002   | used      |       2 | user1    |        1 | Rock Concert    | Stadium A   | 2026-05-20 19:00:00 |
|            3 | TKT0003   | cancelled |       3 | user2    |        1 | Rock Concert    | Stadium A   | 2026-05-20 19:00:00 |
|            4 | TKT0004   | active    |       4 | user3    |        1 | Rock Concert    | Stadium A   | 2026-05-20 19:00:00 |
|            5 | TKT0005   | active    |       5 | user4    |        1 | Rock Concert    | Stadium A   | 2026-05-20 19:00:00 |
|            6 | TKT0006   | used      |       6 | user5    |        2 | Tech Conference | Expo Center | 2026-06-15 09:00:00 |
|            7 | TKT0007   | active    |       7 | user6    |        2 | Tech Conference | Expo Center | 2026-06-15 09:00:00 |
|            8 | TKT0008   | cancelled |       8 | user7    |        2 | Tech Conference | Expo Center | 2026-06-15 09:00:00 |
|            9 | TKT0009   | active    |       9 | user8    |        2 | Tech Conference | Expo Center | 2026-06-15 09:00:00 |
|           10 | TKT0010   | used      |      10 | user9    |        3 | Football Match  | Arena B     | 2026-07-10 18:00:00 |
|           11 | TKT0011   | active    |       1 | admin    |        3 | Football Match  | Arena B     | 2026-07-10 18:00:00 |
|           12 | TKT0012   | cancelled |       2 | user1    |        3 | Football Match  | Arena B     | 2026-07-10 18:00:00 |
|           13 | TKT0013   | active    |       3 | user2    |        3 | Football Match  | Arena B     | 2026-07-10 18:00:00 |
|           14 | TKT0014   | used      |       4 | user3    |        4 | Jazz Festival   | Park C      | 2026-08-05 17:00:00 |
|           15 | TKT0015   | active    |       5 | user4    |        4 | Jazz Festival   | Park C      | 2026-08-05 17:00:00 |
|           16 | TKT0016   | cancelled |       6 | user5    |        4 | Jazz Festival   | Park C      | 2026-08-05 17:00:00 |
|           17 | TKT0017   | used      |       7 | user6    |        5 | Startup Meetup  | Hotel D     | 2026-09-01 10:00:00 |
|           18 | TKT0018   | active    |       8 | user7    |        5 | Startup Meetup  | Hotel D     | 2026-09-01 10:00:00 |
|           19 | TKT0019   | cancelled |       9 | user8    |        5 | Startup Meetup  | Hotel D     | 2026-09-01 10:00:00 |
|           20 | TKT0020   | active    |      10 | user9    |        5 | Startup Meetup  | Hotel D     | 2026-09-01 10:00:00 |
|           21 | TKT_TEST  | active    |       1 | admin    |        1 | Rock Concert    | Stadium A   | 2026-05-20 19:00:00 |
+--------------+-----------+-----------+---------+----------+----------+-----------------+-------------+---------------------+
21 rows in set (0.01 sec)

mysql> 
mysql> -- Q2: All events and alert count including events with no alerts
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT
    ->     e.event_id,
    ->     e.name AS event_name,
    ->     COUNT(a.alert_id) AS alert_count
    -> FROM events e
    -> LEFT JOIN alerts a ON a.event_id = e.event_id
    -> GROUP BY e.event_id, e.name
    -> ORDER BY e.event_id;
+----------+-----------------+-------------+
| event_id | event_name      | alert_count |
+----------+-----------------+-------------+
|        1 | Rock Concert    |           3 |
|        2 | Tech Conference |           5 |
|        3 | Football Match  |           2 |
|        4 | Jazz Festival   |           2 |
|        5 | Startup Meetup  |           2 |
+----------+-----------------+-------------+
5 rows in set (0.00 sec)

mysql> 
mysql> -- Q3: Verifications with verifier usernames and ticket IDs
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT
    ->     cv.verification_id, cv.ticket_pk_id, t.ticket_id,
    ->     cv.verified_at,
    ->     u.user_id AS verifier_id, u.username AS verifier_username
    -> FROM crowd_verifications cv
    -> JOIN users   u ON u.user_id       = cv.verifier_id
    -> JOIN tickets t ON t.ticket_pk_id = cv.ticket_pk_id
    -> ORDER BY cv.verification_id;
+-----------------+--------------+-----------+---------------------+-------------+-------------------+
| verification_id | ticket_pk_id | ticket_id | verified_at         | verifier_id | verifier_username |
+-----------------+--------------+-----------+---------------------+-------------+-------------------+
|               1 |            1 | TKT0001   | 2026-03-20 13:00:00 |           2 | user1             |
|               2 |            2 | TKT0002   | 2026-03-20 13:07:00 |           3 | user2             |
|               3 |            4 | TKT0004   | 2026-03-20 13:14:00 |           4 | user3             |
|               4 |            6 | TKT0006   | 2026-03-20 13:21:00 |           5 | user4             |
|               5 |            8 | TKT0008   | 2026-03-20 13:28:00 |           6 | user5             |
|               6 |           10 | TKT0010   | 2026-03-20 13:35:00 |           7 | user6             |
|               7 |           12 | TKT0012   | 2026-03-20 13:42:00 |           8 | user7             |
|               8 |           14 | TKT0014   | 2026-03-20 13:49:00 |           9 | user8             |
+-----------------+--------------+-----------+---------------------+-------------+-------------------+
8 rows in set (0.00 sec)

mysql> -- Q1: Create view for active ticket details
Query OK, 0 rows affected (0.00 sec)

mysql> DROP VIEW IF EXISTS active_ticket_details;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> CREATE VIEW active_ticket_details AS
    -> SELECT
    ->     t.ticket_pk_id, t.ticket_id, t.status,
    ->     u.user_id, u.username,
    ->     e.event_id, e.name AS event_name, e.location, e.date AS event_date
    -> FROM tickets t
    -> JOIN users  u ON u.user_id  = t.user_id
    -> JOIN events e ON e.event_id = t.event_id
    -> WHERE t.status = 'active';
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> -- Q2: Query the active ticket view
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT * FROM active_ticket_details ORDER BY ticket_pk_id;
+--------------+-----------+--------+---------+----------+----------+-----------------+-------------+---------------------+
| ticket_pk_id | ticket_id | status | user_id | username | event_id | event_name      | location    | event_date          |
+--------------+-----------+--------+---------+----------+----------+-----------------+-------------+---------------------+
|            1 | TKT0001   | active |       1 | admin    |        1 | Rock Concert    | Stadium A   | 2026-05-20 19:00:00 |
|            4 | TKT0004   | active |       4 | user3    |        1 | Rock Concert    | Stadium A   | 2026-05-20 19:00:00 |
|            5 | TKT0005   | active |       5 | user4    |        1 | Rock Concert    | Stadium A   | 2026-05-20 19:00:00 |
|            7 | TKT0007   | active |       7 | user6    |        2 | Tech Conference | Expo Center | 2026-06-15 09:00:00 |
|            9 | TKT0009   | active |       9 | user8    |        2 | Tech Conference | Expo Center | 2026-06-15 09:00:00 |
|           11 | TKT0011   | active |       1 | admin    |        3 | Football Match  | Arena B     | 2026-07-10 18:00:00 |
|           13 | TKT0013   | active |       3 | user2    |        3 | Football Match  | Arena B     | 2026-07-10 18:00:00 |
|           15 | TKT0015   | active |       5 | user4    |        4 | Jazz Festival   | Park C      | 2026-08-05 17:00:00 |
|           18 | TKT0018   | active |       8 | user7    |        5 | Startup Meetup  | Hotel D     | 2026-09-01 10:00:00 |
|           20 | TKT0020   | active |      10 | user9    |        5 | Startup Meetup  | Hotel D     | 2026-09-01 10:00:00 |
|           21 | TKT_TEST  | active |       1 | admin    |        1 | Rock Concert    | Stadium A   | 2026-05-20 19:00:00 |
+--------------+-----------+--------+---------+----------+----------+-----------------+-------------+---------------------+
11 rows in set (0.00 sec)

mysql> 
mysql> -- Q3: Create summary view for tickets per event
Query OK, 0 rows affected (0.00 sec)

mysql> DROP VIEW IF EXISTS ticket_summary_per_event;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> CREATE VIEW ticket_summary_per_event AS
    -> SELECT
    ->     e.event_id,
    ->     e.name AS event_name,
    ->     COUNT(t.ticket_pk_id) AS ticket_count
    -> FROM events e
    -> LEFT JOIN tickets t ON t.event_id = e.event_id
    -> GROUP BY e.event_id, e.name;
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> -- Query events with more than 3 tickets (test data has 20 tickets across 5 events)
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT * FROM ticket_summary_per_event
    -> WHERE ticket_count > 3
    -> ORDER BY ticket_count DESC, event_id;
+----------+-----------------+--------------+
| event_id | event_name      | ticket_count |
+----------+-----------------+--------------+
|        1 | Rock Concert    |            6 |
|        2 | Tech Conference |            4 |
|        3 | Football Match  |            4 |
|        5 | Startup Meetup  |            4 |
+----------+-----------------+--------------+
4 rows in set (0.00 sec)

mysql> -- Q1: Trigger to log every new alert into audit_logs
Query OK, 0 rows affected (0.00 sec)

mysql> DROP TRIGGER IF EXISTS trg_alert_insert_audit;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> DELIMITER $$
mysql> CREATE TRIGGER trg_alert_insert_audit
    -> AFTER INSERT ON alerts
    -> FOR EACH ROW
    -> BEGIN
    ->     INSERT INTO audit_logs (action, user_id, timestamp, details)
    ->     VALUES (
    ->         'alert_created', NULL, NOW(),
    ->         CONCAT('Alert ', NEW.alert_id, ' created for event ', NEW.event_id, ' with level ', NEW.level)
    ->     );
    -> END$$
Query OK, 0 rows affected (0.00 sec)

mysql> DELIMITER ;
mysql> 
mysql> -- Q2: Insert a test alert and verify trigger-generated audit record
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO alerts (event_id, message, level, created_at)
    -> VALUES (1, 'Test alert inserted for trigger verification.', 'alert', NOW());
Query OK, 1 row affected (0.00 sec)

mysql> 
mysql> SELECT * FROM audit_logs
    -> WHERE action = 'alert_created'
    -> ORDER BY audit_id DESC LIMIT 1;
+----------+---------------+---------+---------------------+-----------------------------------------------+
| audit_id | action        | user_id | timestamp           | details                                       |
+----------+---------------+---------+---------------------+-----------------------------------------------+
|        3 | alert_created |    NULL | 2026-04-25 21:26:50 | Alert 15 created for event 1 with level alert |
+----------+---------------+---------+---------------------+-----------------------------------------------+
1 row in set (0.00 sec)

mysql> 
mysql> -- Q3: Trigger to block deletion of used tickets
Query OK, 0 rows affected (0.00 sec)

mysql> DROP TRIGGER IF EXISTS trg_prevent_used_ticket_delete;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> DELIMITER $$
mysql> CREATE TRIGGER trg_prevent_used_ticket_delete
    -> BEFORE DELETE ON tickets
    -> FOR EACH ROW
    -> BEGIN
    ->     IF OLD.status = 'used' THEN
    ->         SIGNAL SQLSTATE '45000'
    ->         SET MESSAGE_TEXT = 'Used tickets cannot be deleted';
    ->     END IF;
    -> END$$
Query OK, 0 rows affected (0.01 sec)

mysql> DELIMITER ;
mysql> 
mysql> -- Test the trigger — this should raise the error as expected output
Query OK, 0 rows affected (0.00 sec)

mysql> DELETE FROM tickets WHERE ticket_id = 'TKT0002';
ERROR 1644 (45000): Used tickets cannot be deleted
mysql> -- Q1: Cursor to count active tickets per event
Query OK, 0 rows affected (0.00 sec)

mysql> DROP TABLE IF EXISTS active_ticket_event_counts;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> CREATE TABLE active_ticket_event_counts (
    ->     event_id            INT PRIMARY KEY,
    ->     active_ticket_count INT NOT NULL
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> DROP PROCEDURE IF EXISTS build_active_ticket_counts;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> DELIMITER $$
mysql> CREATE PROCEDURE build_active_ticket_counts()
    -> BEGIN
    ->     DECLARE done       INT DEFAULT FALSE;
    ->     DECLARE v_event_id INT;
    ->     DECLARE v_count    INT;
    ->     DECLARE cur CURSOR FOR
    ->         SELECT event_id, COUNT(*) AS active_ticket_count
    ->         FROM tickets WHERE status = 'active'
    ->         GROUP BY event_id;
    ->     DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    ->     TRUNCATE TABLE active_ticket_event_counts;
    ->     OPEN cur;
    ->     read_loop: LOOP
    ->         FETCH cur INTO v_event_id, v_count;
    ->         IF done THEN LEAVE read_loop; END IF;
    ->         INSERT INTO active_ticket_event_counts (event_id, active_ticket_count)
    ->         VALUES (v_event_id, v_count);
    ->     END LOOP;
    ->     CLOSE cur;
    -> END$$
Query OK, 0 rows affected (0.00 sec)

mysql> DELIMITER ;
mysql> 
mysql> CALL build_active_ticket_counts();
Query OK, 0 rows affected (0.01 sec)

mysql> SELECT * FROM active_ticket_event_counts ORDER BY event_id;
+----------+---------------------+
| event_id | active_ticket_count |
+----------+---------------------+
|        1 |                   4 |
|        2 |                   2 |
|        3 |                   2 |
|        4 |                   1 |
|        5 |                   2 |
+----------+---------------------+
5 rows in set (0.00 sec)

mysql> 
mysql> -- Q2: Cursor to generate audit logs for all cancelled tickets
Query OK, 0 rows affected (0.00 sec)

mysql> DROP PROCEDURE IF EXISTS sp_log_cancelled_tickets;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> DELIMITER $$
mysql> CREATE PROCEDURE sp_log_cancelled_tickets()
    -> BEGIN
    ->     DECLARE done        INT DEFAULT FALSE;
    ->     DECLARE v_ticket_id VARCHAR(100);
    ->     DECLARE cur CURSOR FOR
    ->         SELECT ticket_id FROM tickets WHERE status = 'cancelled';
    ->     DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    ->     OPEN cur;
    ->     read_loop: LOOP
    ->         FETCH cur INTO v_ticket_id;
    ->         IF done THEN LEAVE read_loop; END IF;
    ->         INSERT INTO audit_logs (action, user_id, timestamp, details)
    ->         VALUES (
    ->             'CANCELLED_TICKET_AUDIT', NULL, NOW(),
    ->             CONCAT('Cancelled ticket reviewed: ', v_ticket_id)
    ->         );
    ->     END LOOP;
    ->     CLOSE cur;
    -> END$$
Query OK, 0 rows affected (0.00 sec)

mysql> DELIMITER ;
mysql> 
mysql> CALL sp_log_cancelled_tickets();
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT action, user_id, details FROM audit_logs
    -> WHERE action = 'CANCELLED_TICKET_AUDIT' ORDER BY audit_id;
+------------------------+---------+------------------------------------+
| action                 | user_id | details                            |
+------------------------+---------+------------------------------------+
| CANCELLED_TICKET_AUDIT |    NULL | Cancelled ticket reviewed: TKT0003 |
| CANCELLED_TICKET_AUDIT |    NULL | Cancelled ticket reviewed: TKT0008 |
| CANCELLED_TICKET_AUDIT |    NULL | Cancelled ticket reviewed: TKT0012 |
| CANCELLED_TICKET_AUDIT |    NULL | Cancelled ticket reviewed: TKT0016 |
| CANCELLED_TICKET_AUDIT |    NULL | Cancelled ticket reviewed: TKT0019 |
+------------------------+---------+------------------------------------+
5 rows in set (0.01 sec)

mysql> 
mysql> -- Q3: Cursor to build cancelled-ticket report with user reference
Query OK, 0 rows affected (0.00 sec)

mysql> DROP PROCEDURE IF EXISTS audit_cancelled_tickets;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> DELIMITER $$
mysql> CREATE PROCEDURE audit_cancelled_tickets()
    -> BEGIN
    ->     DECLARE done           INT DEFAULT FALSE;
    ->     DECLARE v_ticket_pk_id INT;
    ->     DECLARE v_user_id      INT;
    ->     DECLARE cur CURSOR FOR
    ->         SELECT ticket_pk_id, user_id FROM tickets WHERE status = 'cancelled';
    ->     DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    ->     OPEN cur;
    ->     read_loop: LOOP
    ->         FETCH cur INTO v_ticket_pk_id, v_user_id;
    ->         IF done THEN LEAVE read_loop; END IF;
    ->         INSERT INTO audit_logs (action, user_id, timestamp, details)
    ->         VALUES (
    ->             'cancelled_ticket_audit', v_user_id, NOW(),
    ->             CONCAT('Cancelled ticket reviewed: ticket_pk_id=', v_ticket_pk_id)
    ->         );
    ->     END LOOP;
    ->     CLOSE cur;
    -> END$$
Query OK, 0 rows affected (0.00 sec)

mysql> DELIMITER ;
mysql> 
mysql> CALL audit_cancelled_tickets();
Query OK, 0 rows affected (0.01 sec)

mysql> SELECT action, user_id, details FROM audit_logs
    -> WHERE action = 'cancelled_ticket_audit' ORDER BY audit_id;
+------------------------+---------+--------------------------------------------+
| action                 | user_id | details                                    |
+------------------------+---------+--------------------------------------------+
| CANCELLED_TICKET_AUDIT |    NULL | Cancelled ticket reviewed: TKT0003         |
| CANCELLED_TICKET_AUDIT |    NULL | Cancelled ticket reviewed: TKT0008         |
| CANCELLED_TICKET_AUDIT |    NULL | Cancelled ticket reviewed: TKT0012         |
| CANCELLED_TICKET_AUDIT |    NULL | Cancelled ticket reviewed: TKT0016         |
| CANCELLED_TICKET_AUDIT |    NULL | Cancelled ticket reviewed: TKT0019         |
| cancelled_ticket_audit |       3 | Cancelled ticket reviewed: ticket_pk_id=3  |
| cancelled_ticket_audit |       8 | Cancelled ticket reviewed: ticket_pk_id=8  |
| cancelled_ticket_audit |       2 | Cancelled ticket reviewed: ticket_pk_id=12 |
| cancelled_ticket_audit |       6 | Cancelled ticket reviewed: ticket_pk_id=16 |
| cancelled_ticket_audit |       9 | Cancelled ticket reviewed: ticket_pk_id=19 |
+------------------------+---------+--------------------------------------------+
10 rows in set (0.00 sec)

mysql> -- UNF
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE ORDER_RECORD_UNF (
    ->     OrderID         VARCHAR(20) PRIMARY KEY,
    ->     OrderDate       DATE,
    ->     CustomerID      VARCHAR(20),
    ->     CustomerName    VARCHAR(100),
    ->     CustomerPhones  TEXT,   -- comma-separated (UNF style)
    ->     ProductList     TEXT,   -- embedded tuples (UNF style)
    ->     SupplierList    TEXT,   -- embedded tuples (UNF style)
    ->     ShipmentModes   TEXT,   -- comma-separated (UNF style)
    ->     CouponCodes     TEXT    -- comma-separated (UNF style)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> INSERT INTO ORDER_RECORD_UNF (
    ->     OrderID, OrderDate, CustomerID, CustomerName,
    ->     CustomerPhones, ProductList, SupplierList, ShipmentModes, CouponCodes
    -> ) VALUES (
    ->     'O1001', '2026-01-04', 'C01', 'Alex Kim',
    ->     '555-1001,555-1002',
    ->     '(P10,Keyboard,2),(P20,Mouse,1)',
    ->     '(P10,S01),(P10,S03),(P20,S02)',
    ->     'Air,Ground',
    ->     'NEW10,FREESHIP'
    -> );
Query OK, 1 row affected (0.00 sec)

mysql> 
mysql> -- 1NF
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE ORDER_LINE_1NF (
    ->     OrderID       VARCHAR(20),
    ->     OrderDate     DATE,
    ->     CustomerID    VARCHAR(20),
    ->     CustomerName  VARCHAR(100),
    ->     CustomerPhone VARCHAR(20),
    ->     ProductID     VARCHAR(20),
    ->     ProductName   VARCHAR(100),
    ->     Qty           INT,
    ->     SupplierID    VARCHAR(20),
    ->     SupplierName  VARCHAR(100),
    ->     ShipmentMode  VARCHAR(30),
    ->     CouponCode    VARCHAR(30)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> INSERT INTO ORDER_LINE_1NF VALUES
    -> ('O1001','2026-01-04','C01','Alex Kim','555-1001','P10','Keyboard',2,'S01','TechSource','Air','NEW10'),
    -> ('O1001','2026-01-04','C01','Alex Kim','555-1002','P10','Keyboard',2,'S03','KeyMakers','Ground','FREESHIP'),
    -> ('O1001','2026-01-04','C01','Alex Kim','555-1001','P20','Mouse',1,'S02','GadgetHub','Air','NEW10');
Query OK, 3 rows affected (0.00 sec)
Records: 3  Duplicates: 0  Warnings: 0

mysql> -- 2nf
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE ORDERS_2NF (
    ->     OrderID      VARCHAR(20) PRIMARY KEY,
    ->     OrderDate    DATE,
    ->     CustomerID   VARCHAR(20),
    ->     CustomerName VARCHAR(100)
    -> );
ERROR 1050 (42S01): Table 'orders_2nf' already exists
mysql> 
mysql> CREATE TABLE PRODUCT_2NF (
    ->     ProductID   VARCHAR(20) PRIMARY KEY,
    ->     ProductName VARCHAR(100)
    -> );
ERROR 1050 (42S01): Table 'product_2nf' already exists
mysql> 
mysql> CREATE TABLE SUPPLIER_2NF (
    ->     SupplierID   VARCHAR(20) PRIMARY KEY,
    ->     SupplierName VARCHAR(100)
    -> );
ERROR 1050 (42S01): Table 'supplier_2nf' already exists
mysql> 
mysql> CREATE TABLE ORDER_LINE_2NF (
    ->     OrderID   VARCHAR(20),
    ->     ProductID VARCHAR(20),
    ->     Qty       INT,
    ->     PRIMARY KEY (OrderID, ProductID)
    -> );
ERROR 1050 (42S01): Table 'order_line_2nf' already exists
mysql> 
mysql> CREATE TABLE ORDER_LINE_SUPPLIER_2NF (
    ->     OrderID   VARCHAR(20),
    ->     ProductID VARCHAR(20),
    ->     SupplierID VARCHAR(20),
    ->     PRIMARY KEY (OrderID, ProductID, SupplierID)
    -> );
ERROR 1050 (42S01): Table 'order_line_supplier_2nf' already exists
mysql> 
mysql> CREATE TABLE ORDER_SHIPMENT_MODE_2NF (
    ->     OrderID      VARCHAR(20),
    ->     ShipmentMode VARCHAR(30),
    ->     PRIMARY KEY (OrderID, ShipmentMode)
    -> );
ERROR 1050 (42S01): Table 'order_shipment_mode_2nf' already exists
mysql> 
mysql> CREATE TABLE ORDER_COUPON_2NF (
    ->     OrderID    VARCHAR(20),
    ->     CouponCode VARCHAR(30),
    ->     PRIMARY KEY (OrderID, CouponCode)
    -> );
ERROR 1050 (42S01): Table 'order_coupon_2nf' already exists
mysql> 
mysql> CREATE TABLE CUSTOMER_PHONE_2NF (
    ->     CustomerID    VARCHAR(20),
    ->     CustomerPhone VARCHAR(20),
    ->     PRIMARY KEY (CustomerID, CustomerPhone)
    -> );
ERROR 1050 (42S01): Table 'customer_phone_2nf' already exists
mysql> 
mysql> -- 3NF
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE CUSTOMER (
    ->     CustomerID   VARCHAR(20) PRIMARY KEY,
    ->     CustomerName VARCHAR(100)
    -> );
ERROR 1050 (42S01): Table 'customer' already exists
mysql> 
mysql> CREATE TABLE ORDERS (
    ->     OrderID    VARCHAR(20) PRIMARY KEY,
    ->     OrderDate  DATE,
    ->     CustomerID VARCHAR(20),
    ->     FOREIGN KEY (CustomerID) REFERENCES CUSTOMER(CustomerID)
    -> );
ERROR 1050 (42S01): Table 'orders' already exists
mysql> -- BCNF
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE PRODUCT_SUPPLIER (
    ->     ProductID  VARCHAR(20) PRIMARY KEY,
    ->     SupplierID VARCHAR(20)
    -> );
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> CREATE TABLE ORDER_LINE (
    ->     OrderID   VARCHAR(20),
    ->     ProductID VARCHAR(20),
    ->     Qty       INT,
    ->     PRIMARY KEY (OrderID, ProductID)
    -> );
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> --  4NF
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE ORDER_SHIPMENT_MODE (
    ->     OrderID      VARCHAR(20),
    ->     ShipmentMode VARCHAR(30),
    ->     PRIMARY KEY (OrderID, ShipmentMode)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> CREATE TABLE ORDER_COUPON (
    ->     OrderID    VARCHAR(20),
    ->     CouponCode VARCHAR(30),
    ->     PRIMARY KEY (OrderID, CouponCode)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> -- 5NF
Query OK, 0 rows affected (0.00 sec)

mysql> CREATE TABLE CUSTOMER_PRODUCT (
    ->     CustomerID VARCHAR(20),
    ->     ProductID  VARCHAR(20),
    ->     PRIMARY KEY (CustomerID, ProductID)
    -> );
Query OK, 0 rows affected (0.00 sec)

mysql> 
mysql> CREATE TABLE CUSTOMER_SUPPLIER (
    ->     CustomerID VARCHAR(20),
    ->     SupplierID VARCHAR(20),
    ->     PRIMARY KEY (CustomerID, SupplierID)
    -> );
Query OK, 0 rows affected (0.01 sec)

mysql> 
mysql> -- PRODUCT_SUPPLIER already exists from BCNF stage and is reused in 5NF analysis.
Query OK, 0 rows affected (0.00 sec)

mysql> mysql -u root -p crowd_flow < /absolute/path/to/demo_commands.sql
    -> 
    -> 
    -> 

^C
mysql> mysql -u root -p crowd_flow < "/Users/gayathrisathish/Library/Mobile Documents/comappleCloudDocs/Desktop/Projects/Crowd-Flow/demo_commands.sql"
    -> 
    -> ;
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'mysql -u root -p crowd_flow < "/Users/gayathrisathish/Library/Mobile Documents/c' at line 1
mysql> EXIT;
Bye
gayathrisathish@192 ~ % mysql -u root -p crowd_flow < "/Users/gayathrisathish/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Projects/Crowd-Flow/demo_commands.sql"
zsh: no such file or directory: /Users/gayathrisathish/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Projects/Crowd-Flow/demo_commands.sql
gayathrisathish@192 ~ % mysql -u root -p crowd_flow < "/Users/gayathrisathish/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Projects/Crowd-Flow/demo_commands.sql"
zsh: no such file or directory: /Users/gayathrisathish/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Projects/Crowd-Flow/demo_commands.sql
gayathrisathish@192 ~ % mysql -u root -p crowd_flow < "/Users/gayathrisathish/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Projects/Crowd-Flow/demo_commands.sql"
Enter password: 
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: YES)
gayathrisathish@192 ~ % /Users/gayathrisathish/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Projects/Crowd-Flow/demo_commands.sql
zsh: no such file or directory: /Users/gayathrisathish/Library/Mobile
gayathrisathish@192 ~ % mysql -u root -p crowd_flow < "/Users/gayathrisathish/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Projects/Crowd-Flow/demo_commands.sql"
Enter password: 
ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: YES)
gayathrisathish@192 ~ % mysql -u root -p crowd_flow < "/Users/gayathrisathish/Library/Mobile Documents/com~apple~CloudDocs/Desktop/Projects/Crowd-Flow/demo_commands.sql"
Enter password: 
gayathrisathish@192 ~ % mysql -u root -p crowd_flow
Enter password: 
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 40
Server version: 8.4.9 Homebrew

Copyright (c) 2000, 2026, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> SHOW TABLES;
+----------------------------+
| Tables_in_crowd_flow       |
+----------------------------+
| active_ticket_details      |
| active_ticket_event_counts |
| alerts                     |
| audit_logs                 |
| crowd_points               |
| crowd_verification         |
| crowd_verifications        |
| CUSTOMER                   |
| CUSTOMER_PHONE_2NF         |
| CUSTOMER_PRODUCT           |
| CUSTOMER_SUPPLIER          |
| events                     |
| ORDER_COUPON               |
| ORDER_COUPON_2NF           |
| ORDER_LINE                 |
| ORDER_LINE_1NF             |
| ORDER_LINE_2NF             |
| ORDER_LINE_SUPPLIER_2NF    |
| ORDER_RECORD_UNF           |
| ORDER_SHIPMENT_MODE        |
| ORDER_SHIPMENT_MODE_2NF    |
| ORDERS                     |
| ORDERS_2NF                 |
| PRODUCT_2NF                |
| PRODUCT_SUPPLIER           |
| SUPPLIER_2NF               |
| ticket_summary_per_event   |
| tickets                    |
| users                      |
+----------------------------+
29 rows in set (0.00 sec)

mysql> SELECT COUNT(*) FROM events;
