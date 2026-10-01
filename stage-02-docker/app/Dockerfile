# === 1. БАЗОВЫЙ ОБРАЗ ===
# Используем лёгкий официальный образ Python (slim = обрезанный, без лишнего мусора)
FROM python:3.12-slim

# === 2. МЕТАДАННЫЕ ===
LABEL maintainer="layway@example.com"
LABEL description="Flask app for DevOps Journey v3"

# === 3. РАБОЧАЯ ПАПКА ===
# Все следующие команды выполняются внутри этой папки в капсуле
WORKDIR /app

# === 4. ЗАВИСИМОСТИ (Слой кэширования) ===
# Копируем ТОЛЬКО файл зависимостей. 
# Если код изменится, но requirements.txt нет, Docker использует кэш и не будет заново качать библиотеки!
COPY requirements.txt .

# Устанавливаем библиотеки. --no-cache-dir экономит место в капсуле.
RUN pip install --no-cache-dir -r requirements.txt

# === 5. КОД ПРИЛОЖЕНИЯ ===
# Теперь копируем сам код
COPY app.py .

# === 6. ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ (Безопасные дефолты) ===
# Мы помним: пароли в Dockerfile — это заглушки. Реальные значения придут из .env при запуске!
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV DB_HOST=postgres
ENV DB_NAME=appdb
ENV DB_USER=appuser
ENV DB_PASSWORD=CHANGEME_IN_PRODUCTION

# === 7. СЕТЬ ===
# Открываем порт, чтобы капсула могла общаться с внешним миром
EXPOSE 5000

# === 8. КОМАНДА ЗАПУСКА ===
# Что выполнить, когда капсула активируется
CMD ["python", "app.py"]
