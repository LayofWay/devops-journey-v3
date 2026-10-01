import os
from flask import Flask
import psycopg2

app = Flask(__name__)

# Читаем настройки из переменных окружения (или берём значения по умолчанию)
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_NAME = os.getenv('DB_NAME', 'appdb')
DB_USER = os.getenv('DB_USER', 'appuser')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'SecurePass123!')

@app.route('/')
def hello():
    return "🚀 Hello, DevOps Journey v3! Приложение работает в контейнере!"

@app.route('/db-check')
def db_check():
    try:
        # Пытаемся подключиться к PostgreSQL
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        conn.close()
        return "✅ Соединение с PostgreSQL успешно установлено!"
    except Exception as e:
        return f"❌ Ошибка подключения к БД: {str(e)}"

if __name__ == '__main__':
    # Запускаем сервер на всех интерфейсах (0.0.0.0), чтобы он был доступен извне контейнера
    app.run(host='0.0.0.0', port=5000)
# CI/CD Trigger Test
