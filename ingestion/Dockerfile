FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    build-essential \
    libpq-dev \
    curl \
    ca-certificates \
    gdal-bin \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
 && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY src /app/src

# No fixed entrypoint; we will override per task
CMD ["bash", "-lc", "python -c \"print('ingestion image ready')\""]