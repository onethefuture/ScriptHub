FROM python:3.9.16-alpine3.17
WORKDIR /app
COPY ./app .
COPY ./requirements.txt .
RUN pip install -r requirements.txt
CMD ["python", "main.py"]
