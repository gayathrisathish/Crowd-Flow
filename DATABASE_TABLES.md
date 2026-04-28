# Crowd-Flow Database Tables

## Complete Table List

Output of: `SHOW TABLES;` from `crowd_flow` database
+----------------------+ 
| Tables_in_crowd_flow |
+----------------------+
| alerts               |
| audit_logs           |
| crowd_points         |
| crowd_verification   |
| events               |
| tickets              |
| users                |
+----------------------+
## Table Summary

**Total Tables: 7**

### Table Descriptions

1. **users** - Stores user account information (admin/attendee roles)
2. **events** - Stores event details (name, location, date)
3. **tickets** - Stores ticket information linked to users and events
4. **alerts** - Stores system alerts related to events
5. **crowd_verification** - Stores ticket verification data for crowd monitoring
6. **audit_logs** - Stores audit trail of user actions
7. **crowd_points** - Stores crowd density data points for events

## Table Schemas

### alerts

```
+------------+---------------------+------+-----+-------------------+-------+
| Field      | Type                | Null | Key | Default           | Extra |
+------------+---------------------+------+-----+-------------------+-------+
| alert_id   | int                 | NO   | PRI | NULL              | auto_increment |
| event_id   | int                 | NO   | MUL | NULL              | |
| message    | text                | NO   |     | NULL              | |
| level      | enum('alert','safe')| NO   |     | alert             | |
| created_at | datetime            | NO   |     | CURRENT_TIMESTAMP | |
+------------+---------------------+------+-----+-------------------+-------+
```

---

### audit_logs

```
+-----------+---------------+------+-----+-------------------+-------+
| Field     | Type          | Null | Key | Default           | Extra |
+-----------+---------------+------+-----+-------------------+-------+
| audit_id  | int           | NO   | PRI | NULL              | auto_increment |
| action    | varchar(255)  | NO   |     | NULL              | |
| user_id   | int           | YES  | MUL | NULL              | |
| timestamp | datetime      | NO   |     | CURRENT_TIMESTAMP | |
| details   | text          | YES  |     | NULL              | |
+-----------+---------------+------+-----+-------------------+-------+
```

