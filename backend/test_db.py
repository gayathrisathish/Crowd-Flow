import mysql.connector
import sys

HOST = 'shinkansen.proxy.rlwy.net'
PORT = 39620
USER = 'root'
PASSWORD = 'RxNHTJUZuQPVXkfzoVAIitjWKDtypByh'
DATABASE = 'railway'

# Test 1: mysql-connector-python with C extension
print("Test 1: mysql-connector-python (C ext, ssl_disabled=False)")
try:
    conn = mysql.connector.connect(
        host=HOST, port=PORT, user=USER, password=PASSWORD,
        database=DATABASE, connection_timeout=15,
        ssl_disabled=False, use_pure=False,
    )
    print("  SUCCESS:", conn.get_server_info())
    conn.close()
    sys.exit(0)
except Exception as e:
    print("  FAILED:", e)

# Test 2: mysql-connector-python pure Python
print("Test 2: mysql-connector-python (pure Python, ssl_disabled=False)")
try:
    conn = mysql.connector.connect(
        host=HOST, port=PORT, user=USER, password=PASSWORD,
        database=DATABASE, connection_timeout=15,
        ssl_disabled=False, use_pure=True,
    )
    print("  SUCCESS:", conn.get_server_info())
    conn.close()
    sys.exit(0)
except Exception as e:
    print("  FAILED:", e)

# Test 3: pymysql with ssl
print("Test 3: pymysql with ssl dict")
try:
    import pymysql
    import ssl as ssl_mod
    ctx = ssl_mod.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl_mod.CERT_NONE
    conn = pymysql.connect(
        host=HOST, port=PORT, user=USER, passwd=PASSWORD,
        db=DATABASE, connect_timeout=15,
        ssl={"ssl": ctx},
    )
    print("  SUCCESS:", conn.get_server_info())
    conn.close()
    sys.exit(0)
except Exception as e:
    print("  FAILED:", e)

# Test 4: pymysql with ssl_context
print("Test 4: pymysql with ssl_context")
try:
    import pymysql
    import ssl as ssl_mod
    ctx = ssl_mod.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl_mod.CERT_NONE
    conn = pymysql.connect(
        host=HOST, port=PORT, user=USER, passwd=PASSWORD,
        db=DATABASE, connect_timeout=15,
        ssl=ctx,
    )
    print("  SUCCESS:", conn.get_server_info())
    conn.close()
    sys.exit(0)
except Exception as e:
    print("  FAILED:", e)

# Test 5: pymysql plain (no SSL args)
print("Test 5: pymysql plain (no SSL)")
try:
    import pymysql
    conn = pymysql.connect(
        host=HOST, port=PORT, user=USER, passwd=PASSWORD,
        db=DATABASE, connect_timeout=15,
    )
    print("  SUCCESS:", conn.get_server_info())
    conn.close()
    sys.exit(0)
except Exception as e:
    print("  FAILED:", e)

print("\nAll tests failed.")
