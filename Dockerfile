FROM python:3.10-slim AS builder

WORKDIR /app

COPY app/requirements.txt ./

RUN apt-get update && apt-get install -y --no-install-recommends gcc && \
    python -m venv /venv && \
    /venv/bin/pip install --no-cache-dir -r requirements.txt && \
    apt-get remove -y gcc && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*



FROM python:3.10-alpine

WORKDIR /app

RUN apk add --no-cache libstdc++ libffi

COPY --from=builder /venv /venv

COPY app/ ./

ENV PATH="/venv/bin:$PATH"

ARG SERVICE
ENV SERVICE=${SERVICE}

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

ENTRYPOINT ["sh", "-c", "if [ \"$SERVICE\" = 'celery' ]; then celery -A tasks.celery_app worker --loglevel=info; else uvicorn main:app --host 0.0.0.0 --port 8000 --reload; fi"]
