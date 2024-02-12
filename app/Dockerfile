FROM python:3.7.4-slim-buster

WORKDIR /app

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt

COPY . .

CMD [ "gunicorn", "-b", "0.0.0.0", "--log-level" , "debug", "api:app"]