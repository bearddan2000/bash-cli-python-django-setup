FROM python:latest

ENV PYTHONUNBUFFERED=1

WORKDIR /usr/local

COPY bin/requirements.txt ./

RUN pip install -r requirements.txt

COPY bin/ ./

RUN ./setup.sh
